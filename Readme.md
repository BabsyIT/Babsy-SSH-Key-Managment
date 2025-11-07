# SSH Key Management System

🔑 Automatisierte SSH-Key und Benutzer-Verwaltung für Debian/Ubuntu-Systeme über GitHub und Microsoft 365.

## 🚀 Quick Links

- **[📖 Vollständige Dokumentation](../../wiki)** - Komplette Anleitung im Wiki
- **[⚡ Schnellstart](../../wiki/Home#-schnellstart)** - 1-Minuten Setup
- **[🔧 Installation](../../wiki/Home#-detaillierte-installation)** - Schritt für Schritt
- **[❓ Troubleshooting](../../wiki/Home#-troubleshooting)** - Problemlösung

## ✨ Features

✅ **Automatische SSH-Key-Synchronisation** von GitHub
✅ **Microsoft 365 Integration** - User aus M365 IT-Team automatisch synchronisieren
✅ **Zentrale Benutzerverwaltung** über GitHub Repository oder M365
✅ **Automatische Benutzeranlage** mit konfigurierbaren Rechten
✅ **GitHub Username Mapping** via M365 Extension Attributes
✅ **Sudo-Rechte-Management** (full/limited/none)
✅ **Gruppen-Management** für Systemzugriff
✅ **Zentrale Logs** in GitHub für alle Hosts
✅ **Automatische Updates** (M365: stündlich, SSH-Keys: alle 5 Minuten)
✅ **Lock-Mechanismus** gegen parallele Ausführung  

## 🎯 Drei Modi verfügbar

### Modus 1: Einfache Key-Verwaltung
Für existierende Benutzer - Keys automatisch aktualisieren.

**Datei:** `config/users.txt`
```
stefan-ffr
alice-dev
bob-admin
```

### Modus 2: Vollständige Benutzerverwaltung
Benutzer automatisch anlegen + Keys + Sudo-Rechte verwalten.

**Datei:** `config/user-mapping.json`
```json
{
  "users": [
    {
      "github_user": "stefan-ffr",
      "local_user": "stefan",
      "sudo_access": "full",
      "groups": ["sudo", "docker"]
    }
  ]
}
```

### Modus 3: Microsoft 365 Integration (NEU!) 🆕
Automatische Synchronisation von IT-Team Usern aus Microsoft 365.

**Features:**
- Liest User aus M365 IT-Team Gruppe
- GitHub Username aus Extension Attribute
- Automatische User-Erstellung auf allen Debian Hosts
- SSH-Keys von GitHub importieren
- Stündliche Synchronisation

**Setup:**
1. Azure AD App Registration erstellen
2. Microsoft Graph API Permissions konfigurieren
3. M365 Config erstellen: `/etc/ssh-key-manager/m365-config.json`
4. Extension Attribute mit GitHub Usernames füllen

```json
{
  "tenant_id": "your-tenant.onmicrosoft.com",
  "client_id": "your-app-id",
  "client_secret": "your-secret",
  "it_group_name": "IT-Team",
  "github_username_field": "extensionAttribute1"
}
```

## 🚀 Schnellstart

### Standard Installation (ohne M365)

```bash
# 1. Repository klonen
git clone https://github.com/your-org/ssh-key-management.git
cd ssh-key-management

# 2. Automatische Installation
sudo ./install.sh

# 3. Konfiguration anpassen
cp config/examples/user-mapping.json.example config/user-mapping.json
nano config/user-mapping.json

# 4. GitHub Token setzen (optional für private Repos)
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
export GITHUB_REPO="your-org/ssh-key-management"

# 5. Service aktivieren
sudo systemctl enable ssh-user-manager.timer
sudo systemctl start ssh-user-manager.timer
```

### Microsoft 365 Integration

```bash
# 1. Repository klonen und installieren (wie oben)
sudo ./install.sh
# → Bei Installation "y" für M365 Integration wählen

# 2. Azure AD App erstellen
# - Azure Portal → App registrations → New registration
# - API Permissions: User.Read.All, Group.Read.All, Directory.Read.All
# - Admin Consent erteilen
# - Client Secret erstellen

# 3. M365 Config erstellen
sudo cp config/examples/m365-config.json.example /etc/ssh-key-manager/m365-config.json
sudo nano /etc/ssh-key-manager/m365-config.json

# 4. GitHub Usernames in M365 setzen
# PowerShell/Azure AD:
# Set-AzureADUser -ObjectId "user@domain.com" -ExtensionAttribute1 "github-username"

# 5. M365 Sync starten
sudo systemctl enable m365-user-sync.timer
sudo systemctl start m365-user-sync.timer

# 6. Manuell testen
sudo /usr/local/bin/m365-sync-wrapper.sh
```

## 📋 Voraussetzungen

### Basis-System
- Debian/Ubuntu System mit root-Zugriff
- Python 3.6+ (für M365 Integration)
- Git, curl, jq

### Für GitHub Integration (optional)
- GitHub Repository für Konfiguration
- GitHub Personal Access Token (für private Repos)

### Für M365 Integration (optional)
- Microsoft 365 Tenant (z.B. babsy.chh)
- Azure AD App Registration mit Permissions:
  - User.Read.All
  - Group.Read.All
  - Directory.Read.All
- IT-Team Gruppe in Microsoft 365
- Extension Attributes für GitHub Usernames

## 🔒 Sicherheit

- Token sicher in `/etc/ssh-key-manager.env` gespeichert
- Sudoers-Validierung mit `visudo -c`
- Separate sudoers-Dateien pro Benutzer
- Umfassende Audit-Logs

## 📊 Monitoring

### Logs anzeigen
```bash
# Live-Logs
sudo journalctl -u ssh-user-manager.service -f

# Timer-Status
sudo systemctl status ssh-user-manager.timer

# GitHub-Logs
# Siehe: logs/ Verzeichnis in diesem Repository
```

### Test-Lauf
```bash
sudo /usr/local/bin/github-ssh-user-manager.sh
```

## 🤝 Support

- **Issues:** [GitHub Issues](../../issues)
- **Wiki:** [Vollständige Dokumentation](../../wiki)
- **Discussions:** [Community Forum](../../discussions)

## 📄 Lizenz

MIT License - siehe [LICENSE](LICENSE) für Details.

---

**→ [Vollständige Anleitung im Wiki](../../wiki) für detaillierte Installation und Konfiguration.**
