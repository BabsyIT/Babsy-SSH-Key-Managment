#!/bin/bash
# GitHub SSH Key Manager - Simple Mode
# Only updates SSH keys for existing users (no user creation)

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}[KEY-MGR]${NC} $1" | tee -a "$LOG_FILE"; }
log_success() { echo -e "${GREEN}[KEY-MGR]${NC} $1" | tee -a "$LOG_FILE"; }
log_warning() { echo -e "${YELLOW}[KEY-MGR]${NC} $1" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[KEY-MGR]${NC} $1" | tee -a "$LOG_FILE"; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${GITHUB_REPO_DIR:-/root/Babsy-SSH-Key-Managment}"
USERS_FILE="${REPO_DIR}/config/users.txt"
LOG_FILE="/var/log/ssh-key-manager.log"
LOCK_FILE="/var/lock/ssh-key-manager.lock"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Load environment variables
if [[ -f /etc/ssh-key-manager/ssh-key-manager.env ]]; then
    source /etc/ssh-key-manager/ssh-key-manager.env
fi

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

# Import SSH keys from GitHub for a specific user
import_keys_for_user() {
    local github_user="$1"
    local local_user="${2:-$github_user}"

    # Check if local user exists
    if ! id "$local_user" &>/dev/null; then
        log_warning "User ${local_user} does not exist, skipping..."
        return 1
    fi

    log_info "Updating SSH keys for ${local_user} from GitHub user ${github_user}..."

    # Get user's home directory
    local user_home=$(getent passwd "$local_user" | cut -d: -f6)

    if [[ ! -d "$user_home" ]]; then
        log_error "Home directory not found for ${local_user}: ${user_home}"
        return 1
    fi

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

            log_success "Updated ${key_count} SSH key(s) for ${local_user}"
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

# Push logs to GitHub (if configured)
push_logs() {
    if [[ -d "$REPO_DIR/.git" ]] && [[ -n "${GITHUB_TOKEN:-}" ]] && [[ -n "${GITHUB_REPO:-}" ]]; then
        log_info "Pushing logs to GitHub..."

        local hostname=$(hostname)
        local log_dir="${REPO_DIR}/logs/${hostname}"
        mkdir -p "$log_dir"

        # Copy current log
        cp "$LOG_FILE" "${log_dir}/ssh-key-manager_$(date +%Y%m%d).log" 2>/dev/null || true

        cd "$REPO_DIR"

        # Configure git if needed
        git config user.email "ssh-manager@${hostname}" 2>/dev/null || true
        git config user.name "SSH Key Manager ${hostname}" 2>/dev/null || true

        # Add and commit logs
        git add logs/ 2>/dev/null || true
        git commit -m "Update key manager logs from ${hostname} - ${TIMESTAMP}" 2>/dev/null || true
        git push origin main 2>/dev/null || log_warning "Failed to push logs to GitHub"
    fi
}

# Main function
main() {
    log_info "=========================================="
    log_info "SSH Key Manager Started - ${TIMESTAMP}"
    log_info "=========================================="

    acquire_lock

    # Update repository
    update_repo

    # Check if users file exists
    if [[ ! -f "$USERS_FILE" ]]; then
        log_error "Users file not found: ${USERS_FILE}"
        log_error "Please create it with GitHub usernames (one per line)"
        exit 1
    fi

    # Read users from file
    log_info "Reading users from ${USERS_FILE}"

    local success_count=0
    local error_count=0
    local skip_count=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Trim whitespace
        github_user=$(echo "$line" | xargs)

        # Skip if empty after trimming
        [[ -z "$github_user" ]] && continue

        # Import keys
        if import_keys_for_user "$github_user"; then
            ((success_count++))
        else
            if id "$github_user" &>/dev/null; then
                ((error_count++))
            else
                ((skip_count++))
            fi
        fi

    done < "$USERS_FILE"

    log_info "=========================================="
    log_success "Processing completed:"
    log_info "  - Successful: ${success_count}"
    log_info "  - Errors: ${error_count}"
    log_info "  - Skipped (user not found): ${skip_count}"
    log_info "=========================================="

    # Push logs to GitHub
    push_logs

    exit 0
}

# Run main function
main "$@"
