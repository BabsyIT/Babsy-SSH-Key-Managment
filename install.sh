#!/bin/bash
# install.sh - SSH Key Management System Installation
set -euo pipefail

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging-Funktionen
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Prüfung ob root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

# Banner
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║               SSH Key Management System Installer                ║"
echo "║                                                                  ║"
echo "║  Automatisierte SSH-Key und Benutzer-Verwaltung über GitHub     ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Variablen
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/usr/local/bin"
SYSTEMD_DIR="/etc/systemd/system"
CONFIG_DIR="/etc/ssh-key-manager"

# Schritt 1: Abhängigkeiten installieren
log_info "Installing dependencies..."
apt update -qq
apt install -y ssh-import-id jq curl systemd python3 python3-pip git
pip3 install requests

# Schritt 2: Scripts installieren
log_info "Installing SSH key management scripts..."
cp "$SCRIPT_DIR/scripts/github-ssh-key-manager.sh" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/scripts/github-ssh-user-manager.sh" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/scripts/m365-sync-wrapper.sh" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/scripts/m365-user-sync.py" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/github-ssh-"*.sh
chmod +x "$INSTALL_DIR/m365-"*.sh
chmod +x "$INSTALL_DIR/m365-"*.py
log_success "Scripts installed to $INSTALL_DIR"

# Schritt 3: Systemd Services installieren
log_info "Installing systemd services..."
cp "$SCRIPT_DIR/systemd/"*.service "$SYSTEMD_DIR/"
cp "$SCRIPT_DIR/systemd/"*.timer "$SYSTEMD_DIR/"
systemctl daemon-reload
log_success "Systemd services installed"

# Schritt 4: Konfigurationsverzeichnis erstellen
log_info "Setting up configuration..."
mkdir -p "$CONFIG_DIR"

# Beispiel-Konfigurationsdatei erstellen
if [[ ! -f "$CONFIG_DIR/ssh-key-manager.env" ]]; then
    cat > "$CONFIG_DIR/ssh-key-manager.env" <<EOF
# SSH Key Manager Configuration
# Set your GitHub token and repository here

GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
GITHUB_REPO=your-org/ssh-key-management
DEFAULT_SHELL=/bin/bash
DEFAULT_GROUP=users
USER_HOME_BASE=/home
EOF
    chmod 600 "$CONFIG_DIR/ssh-key-manager.env"
    log_warning "Created $CONFIG_DIR/ssh-key-manager.env - PLEASE EDIT WITH YOUR SETTINGS!"
fi

# Schritt 5: M365 Integration (optional)
echo
log_info "Do you want to enable Microsoft 365 integration?"
echo "This will sync users from M365 IT-Team group automatically."
echo
read -p "Enable M365 integration? (y/n): " M365_CHOICE

if [[ $M365_CHOICE =~ ^[Yy]$ ]]; then
    log_info "Setting up M365 integration..."

    # Create M365 config from example
    if [[ ! -f "$CONFIG_DIR/m365-config.json" ]]; then
        cp "$SCRIPT_DIR/config/examples/m365-config.json.example" "$CONFIG_DIR/m365-config.json"
        chmod 600 "$CONFIG_DIR/m365-config.json"
        log_warning "Created $CONFIG_DIR/m365-config.json - PLEASE EDIT WITH YOUR M365 SETTINGS!"
    fi

    # Enable M365 sync timer
    systemctl enable m365-user-sync.timer
    log_success "M365 integration enabled"
    log_warning "Configure Azure AD app and edit: $CONFIG_DIR/m365-config.json"
fi

# Schritt 6: Auswahl des Modus
echo
log_info "Choose your management mode:"
echo "1) Simple Key Management - Update keys for existing users"
echo "2) Full User Management - Create users + manage keys + sudo rights"
echo "3) Both modes (run separately)"
echo
read -p "Enter choice (1-3): " MODE_CHOICE

case $MODE_CHOICE in
    1)
        log_info "Configuring Simple Key Management mode..."
        systemctl enable ssh-key-manager.timer
        log_success "Enabled ssh-key-manager.timer"
        log_warning "Configure users in: config/users.txt"
        ;;
    2)
        log_info "Configuring Full User Management mode..."
        systemctl enable ssh-user-manager.timer  
        log_success "Enabled ssh-user-manager.timer"
        log_warning "Configure users in: config/user-mapping.json"
        ;;
    3)
        log_info "Configuring both modes..."
        systemctl enable ssh-key-manager.timer
        systemctl enable ssh-user-manager.timer
        log_success "Enabled both timers"
        log_warning "Configure: config/users.txt AND config/user-mapping.json"
        ;;
    *)
        log_warning "Invalid choice. You can enable services manually later."
        ;;
esac

# Schritt 7: Services starten (optional)
echo
read -p "Start the services now? (y/n): " START_NOW
if [[ $START_NOW =~ ^[Yy]$ ]]; then
    # Start M365 sync if enabled
    if [[ $M365_CHOICE =~ ^[Yy]$ ]]; then
        systemctl start m365-user-sync.timer
        log_success "Started m365-user-sync.timer"
    fi

    case $MODE_CHOICE in
        1)
            systemctl start ssh-key-manager.timer
            log_success "Started ssh-key-manager.timer"
            ;;
        2)
            systemctl start ssh-user-manager.timer
            log_success "Started ssh-user-manager.timer"
            ;;
        3)
            systemctl start ssh-key-manager.timer
            systemctl start ssh-user-manager.timer
            log_success "Started both timers"
            ;;
    esac
fi

# Schritt 8: Status anzeigen
echo
log_info "Installation completed! Next steps:"
echo
echo "1. Edit configuration files:"
echo "   - $CONFIG_DIR/ssh-key-manager.env"
if [[ $M365_CHOICE =~ ^[Yy]$ ]]; then
echo "   - $CONFIG_DIR/m365-config.json (IMPORTANT: Configure Azure AD app!)"
fi
echo "   - $SCRIPT_DIR/config/users.txt (for simple mode)"
echo "   - $SCRIPT_DIR/config/user-mapping.json (for full mode)"
echo
echo "2. Test the installation:"
if [[ $M365_CHOICE =~ ^[Yy]$ ]]; then
echo "   sudo $INSTALL_DIR/m365-sync-wrapper.sh (sync from M365)"
fi
echo "   sudo $INSTALL_DIR/github-ssh-key-manager.sh"
echo "   sudo $INSTALL_DIR/github-ssh-user-manager.sh"
echo
echo "3. Check service status:"
if [[ $M365_CHOICE =~ ^[Yy]$ ]]; then
echo "   sudo systemctl status m365-user-sync.timer"
fi
echo "   sudo systemctl status ssh-key-manager.timer"
echo "   sudo systemctl status ssh-user-manager.timer"
echo
echo "4. View logs:"
if [[ $M365_CHOICE =~ ^[Yy]$ ]]; then
echo "   sudo journalctl -u m365-user-sync.service -f"
fi
echo "   sudo journalctl -u ssh-key-manager.service -f"
echo "   sudo journalctl -u ssh-user-manager.service -f"
echo
log_success "Installation finished! 🎉"

# Hinweis auf Wiki
echo
log_info "📖 Full documentation: https://github.com/your-org/ssh-key-management/wiki"
