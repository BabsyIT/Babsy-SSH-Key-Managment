#\!/bin/bash
# =============================================================
# Babsy SSH Key Management - Host Setup Script
# =============================================================
# Prepares a new Debian/Ubuntu host for Ansible management.
# Creates the ansible user, configures SSH and sudo access.
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/BabsyIT/Babsy-SSH-Key-Managment/main/scripts/setup-host.sh | bash
#
# Or with a custom ansible user name:
#   curl -sSL https://raw.githubusercontent.com/BabsyIT/Babsy-SSH-Key-Managment/main/scripts/setup-host.sh | bash -s -- --user myuser
# =============================================================

set -euo pipefail

# --- Configuration ---
ANSIBLE_USER="ansible"
SSH_PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIARiYsjar4XeZcdHsigPUPrd9uUtqrgUfXruf96m/6Vg ansible-deploy@github-actions"

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) ANSIBLE_USER="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Checks ---
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: This script must be run as root."
  exit 1
fi

echo "=== Babsy SSH Host Setup ==="
echo "Ansible user: ${ANSIBLE_USER}"
echo ""

# 1. Create ansible user
if id "${ANSIBLE_USER}" &>/dev/null; then
  echo "[OK] User ${ANSIBLE_USER} already exists"
else
  useradd -m -s /bin/bash -G sudo "${ANSIBLE_USER}"
  echo "[OK] User ${ANSIBLE_USER} created"
fi

# 2. Passwordless sudo
SUDOERS_FILE="/etc/sudoers.d/${ANSIBLE_USER}"
if [ -f "${SUDOERS_FILE}" ]; then
  echo "[OK] Sudoers file already exists"
else
  echo "${ANSIBLE_USER} ALL=(ALL) NOPASSWD:ALL" > "${SUDOERS_FILE}"
  chmod 440 "${SUDOERS_FILE}"
  echo "[OK] Passwordless sudo configured"
fi

# 3. SSH authorized_keys
SSH_DIR="/home/${ANSIBLE_USER}/.ssh"
AUTH_KEYS="${SSH_DIR}/authorized_keys"

mkdir -p "${SSH_DIR}"
chmod 700 "${SSH_DIR}"

if grep -qF "${SSH_PUBLIC_KEY}" "${AUTH_KEYS}" 2>/dev/null; then
  echo "[OK] SSH public key already present"
else
  echo "${SSH_PUBLIC_KEY}" >> "${AUTH_KEYS}"
  echo "[OK] SSH public key added"
fi

chmod 600 "${AUTH_KEYS}"
chown -R "${ANSIBLE_USER}:${ANSIBLE_USER}" "${SSH_DIR}"

# 4. Python3 (required by Ansible)
if command -v python3 &>/dev/null; then
  echo "[OK] Python3 installed ($(python3 --version 2>&1))"
else
  echo "[..] Installing Python3..."
  apt-get update -qq && apt-get install -y -qq python3 python3-apt
  echo "[OK] Python3 installed"
fi

echo ""
echo "=== Setup Complete ==="
echo "Host is ready for Ansible management."
echo "Next: Add this host in the Management Cockpit (SSH-Hosts)."
