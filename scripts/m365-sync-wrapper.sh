#!/bin/bash
# M365 User Sync Wrapper Script
# Syncs users from Microsoft 365 to user-mapping.json

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}[M365-SYNC]${NC} $1"; }
log_success() { echo -e "${GREEN}[M365-SYNC]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[M365-SYNC]${NC} $1"; }
log_error() { echo -e "${RED}[M365-SYNC]${NC} $1"; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
M365_SYNC_SCRIPT="${SCRIPT_DIR}/m365-user-sync.py"
M365_CONFIG="/etc/ssh-key-manager/m365-config.json"
LOCK_FILE="/var/lock/m365-sync.lock"
LOG_FILE="/var/log/m365-sync.log"

# Load environment variables if available
if [[ -f /etc/ssh-key-manager/ssh-key-manager.env ]]; then
    source /etc/ssh-key-manager/ssh-key-manager.env
fi

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

# Lock mechanism to prevent concurrent runs
acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
            log_warning "Another instance is already running (PID: $PID)"
            exit 0
        else
            log_info "Removing stale lock file"
            rm -f "$LOCK_FILE"
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

release_lock() {
    rm -f "$LOCK_FILE"
}

trap release_lock EXIT

# Main function
main() {
    log_info "Starting M365 user synchronization..."

    # Acquire lock
    acquire_lock

    # Check if Python script exists
    if [[ ! -f "$M365_SYNC_SCRIPT" ]]; then
        log_error "M365 sync script not found: $M365_SYNC_SCRIPT"
        exit 1
    fi

    # Check if config exists
    if [[ ! -f "$M365_CONFIG" ]]; then
        log_error "M365 configuration not found: $M365_CONFIG"
        log_error "Please create configuration from example:"
        log_error "  cp config/examples/m365-config.json.example /etc/ssh-key-manager/m365-config.json"
        log_error "  nano /etc/ssh-key-manager/m365-config.json"
        exit 1
    fi

    # Check Python and required modules
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 is not installed"
        exit 1
    fi

    # Check if requests module is available
    if ! python3 -c "import requests" 2>/dev/null; then
        log_warning "Python requests module not found, installing..."
        pip3 install requests || {
            log_error "Failed to install requests module"
            exit 1
        }
    fi

    # Run the Python sync script
    log_info "Executing M365 user sync..."

    if python3 "$M365_SYNC_SCRIPT" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "M365 user synchronization completed successfully"

        # After successful sync, trigger user manager to apply changes
        if [[ -f /usr/local/bin/github-ssh-user-manager.sh ]]; then
            log_info "Triggering SSH user manager to apply changes..."
            /usr/local/bin/github-ssh-user-manager.sh
        fi

        exit 0
    else
        log_error "M365 user synchronization failed"
        exit 1
    fi
}

# Run main function
main "$@"
