#!/bin/bash
# GitHub SSH User Manager - Full User Management with GitHub Keys
# Creates/manages users and imports their SSH keys from GitHub

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}[USER-MGR]${NC} $1" | tee -a "$LOG_FILE"; }
log_success() { echo -e "${GREEN}[USER-MGR]${NC} $1" | tee -a "$LOG_FILE"; }
log_warning() { echo -e "${YELLOW}[USER-MGR]${NC} $1" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[USER-MGR]${NC} $1" | tee -a "$LOG_FILE"; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${GITHUB_REPO_DIR:-/root/Babsy-SSH-Key-Managment}"
USER_MAPPING_FILE="${REPO_DIR}/config/user-mapping.json"
LOG_FILE="/var/log/ssh-user-manager.log"
LOCK_FILE="/var/lock/ssh-user-manager.lock"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Load environment variables
if [[ -f /etc/ssh-key-manager/ssh-key-manager.env ]]; then
    source /etc/ssh-key-manager/ssh-key-manager.env
fi

# Default configuration
DEFAULT_SHELL="${DEFAULT_SHELL:-/bin/bash}"
DEFAULT_GROUP="${DEFAULT_GROUP:-users}"
USER_HOME_BASE="${USER_HOME_BASE:-/home}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

# Lock mechanism
acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
            log_warning "Another instance is already running (PID: $PID)"
            exit 0
        else
            rm -f "$LOCK_FILE"
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

release_lock() {
    rm -f "$LOCK_FILE"
}

trap release_lock EXIT

# Update GitHub repository if configured
update_repo() {
    if [[ -d "$REPO_DIR/.git" ]] && [[ -n "${GITHUB_TOKEN:-}" ]]; then
        log_info "Updating configuration from GitHub..."
        cd "$REPO_DIR"
        git pull origin main 2>&1 | tee -a "$LOG_FILE" || {
            log_warning "Failed to update from GitHub, using local configuration"
        }
    fi
}

# Import SSH keys from GitHub
import_github_keys() {
    local github_user="$1"
    local local_user="$2"
    local user_home="$3"

    log_info "Importing SSH keys for ${local_user} from GitHub user ${github_user}..."

    # Create .ssh directory if it doesn't exist
    local ssh_dir="${user_home}/.ssh"
    mkdir -p "$ssh_dir"

    # Fetch keys from GitHub
    local github_keys_url="https://github.com/${github_user}.keys"
    local temp_keys="/tmp/github_keys_${local_user}.tmp"

    if curl -sf "$github_keys_url" -o "$temp_keys"; then
        local key_count=$(wc -l < "$temp_keys")

        if [[ $key_count -gt 0 ]]; then
            # Backup existing authorized_keys
            if [[ -f "${ssh_dir}/authorized_keys" ]]; then
                cp "${ssh_dir}/authorized_keys" "${ssh_dir}/authorized_keys.backup.$(date +%Y%m%d_%H%M%S)"
            fi

            # Write new keys
            cp "$temp_keys" "${ssh_dir}/authorized_keys"

            # Set correct permissions
            chown -R "${local_user}:${local_user}" "$ssh_dir"
            chmod 700 "$ssh_dir"
            chmod 600 "${ssh_dir}/authorized_keys"

            log_success "Imported ${key_count} SSH key(s) for ${local_user}"
            rm -f "$temp_keys"
            return 0
        else
            log_warning "No SSH keys found for GitHub user ${github_user}"
            rm -f "$temp_keys"
            return 1
        fi
    else
        log_error "Failed to fetch SSH keys from ${github_keys_url}"
        rm -f "$temp_keys"
        return 1
    fi
}

# Create or update user
manage_user() {
    local user_data="$1"

    # Parse user data
    local github_user=$(echo "$user_data" | jq -r '.github_user')
    local local_user=$(echo "$user_data" | jq -r '.local_user')
    local full_name=$(echo "$user_data" | jq -r '.full_name // ""')
    local sudo_access=$(echo "$user_data" | jq -r '.sudo_access // "none"')
    local groups=$(echo "$user_data" | jq -r '.groups // [] | join(",")')

    log_info "Processing user: ${local_user} (GitHub: ${github_user})"

    # Create user if doesn't exist
    if ! id "$local_user" &>/dev/null; then
        log_info "Creating user: ${local_user}"

        useradd -m -s "$DEFAULT_SHELL" -d "${USER_HOME_BASE}/${local_user}" "$local_user"

        if [[ -n "$full_name" ]]; then
            usermod -c "$full_name" "$local_user"
        fi

        log_success "User ${local_user} created"
    else
        log_info "User ${local_user} already exists, updating..."
    fi

    # Add user to groups
    if [[ -n "$groups" ]]; then
        log_info "Adding ${local_user} to groups: ${groups}"
        usermod -a -G "$groups" "$local_user" || log_warning "Failed to add some groups"
    fi

    # Configure sudo access
    configure_sudo "$local_user" "$sudo_access" "$user_data"

    # Import SSH keys from GitHub
    local user_home=$(getent passwd "$local_user" | cut -d: -f6)
    import_github_keys "$github_user" "$local_user" "$user_home"
}

# Configure sudo access
configure_sudo() {
    local local_user="$1"
    local sudo_access="$2"
    local user_data="$3"

    local sudoers_file="/etc/sudoers.d/${local_user}"

    case "$sudo_access" in
        full)
            log_info "Granting full sudo access to ${local_user}"
            echo "${local_user} ALL=(ALL:ALL) NOPASSWD: ALL" > "$sudoers_file"
            chmod 440 "$sudoers_file"

            # Validate sudoers file
            if ! visudo -c -f "$sudoers_file" &>/dev/null; then
                log_error "Invalid sudoers file for ${local_user}, removing..."
                rm -f "$sudoers_file"
                return 1
            fi

            log_success "Full sudo access granted to ${local_user}"
            ;;

        limited)
            log_info "Granting limited sudo access to ${local_user}"

            # Get allowed commands from user data
            local commands=$(echo "$user_data" | jq -r '.sudo_commands // [] | join(", ")')

            if [[ -n "$commands" && "$commands" != "" ]]; then
                # Create sudoers file with limited commands
                {
                    echo "# Limited sudo access for ${local_user}"
                    echo "# Created: $(date)"
                    echo "$local_user ALL=(ALL:ALL) NOPASSWD:"

                    echo "$user_data" | jq -r '.sudo_commands[]' | while read -r cmd; do
                        echo "    ${cmd},"
                    done | sed '$ s/,$//'
                } > "$sudoers_file"

                chmod 440 "$sudoers_file"

                # Validate sudoers file
                if ! visudo -c -f "$sudoers_file" &>/dev/null; then
                    log_error "Invalid sudoers file for ${local_user}, removing..."
                    rm -f "$sudoers_file"
                    return 1
                fi

                log_success "Limited sudo access granted to ${local_user}"
            else
                log_warning "No sudo commands specified for ${local_user}, skipping sudo config"
            fi
            ;;

        none)
            log_info "No sudo access for ${local_user}"
            if [[ -f "$sudoers_file" ]]; then
                rm -f "$sudoers_file"
                log_info "Removed existing sudo access for ${local_user}"
            fi
            ;;

        *)
            log_warning "Unknown sudo access level '${sudo_access}' for ${local_user}"
            ;;
    esac
}

# Push logs to GitHub (if configured)
push_logs() {
    if [[ -d "$REPO_DIR/.git" ]] && [[ -n "${GITHUB_TOKEN:-}" ]] && [[ -n "${GITHUB_REPO:-}" ]]; then
        log_info "Pushing logs to GitHub..."

        local hostname=$(hostname)
        local log_dir="${REPO_DIR}/logs/${hostname}"
        mkdir -p "$log_dir"

        # Copy current log
        cp "$LOG_FILE" "${log_dir}/ssh-user-manager_$(date +%Y%m%d).log" 2>/dev/null || true

        cd "$REPO_DIR"

        # Configure git if needed
        git config user.email "ssh-manager@${hostname}" 2>/dev/null || true
        git config user.name "SSH Manager ${hostname}" 2>/dev/null || true

        # Add and commit logs
        git add logs/ 2>/dev/null || true
        git commit -m "Update logs from ${hostname} - ${TIMESTAMP}" 2>/dev/null || true
        git push origin main 2>/dev/null || log_warning "Failed to push logs to GitHub"
    fi
}

# Main function
main() {
    log_info "=========================================="
    log_info "SSH User Manager Started - ${TIMESTAMP}"
    log_info "=========================================="

    acquire_lock

    # Check if jq is installed
    if ! command -v jq &>/dev/null; then
        log_error "jq is not installed. Please install it: apt install jq"
        exit 1
    fi

    # Update repository
    update_repo

    # Check if user mapping file exists
    if [[ ! -f "$USER_MAPPING_FILE" ]]; then
        log_error "User mapping file not found: ${USER_MAPPING_FILE}"
        log_error "Please create it from the example or run M365 sync first"
        exit 1
    fi

    # Read and parse user configuration
    log_info "Reading user configuration from ${USER_MAPPING_FILE}"

    local user_count=$(jq -r '.users | length' "$USER_MAPPING_FILE")
    log_info "Found ${user_count} user(s) to manage"

    # Process each user
    local success_count=0
    local error_count=0

    for i in $(seq 0 $((user_count - 1))); do
        user_data=$(jq -c ".users[$i]" "$USER_MAPPING_FILE")

        if manage_user "$user_data"; then
            ((success_count++))
        else
            ((error_count++))
        fi
    done

    log_info "=========================================="
    log_success "Processing completed: ${success_count} successful, ${error_count} errors"
    log_info "=========================================="

    # Push logs to GitHub
    push_logs

    exit 0
}

# Run main function
main "$@"
