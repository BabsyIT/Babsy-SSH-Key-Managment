# SSH Key Management System

🔑 Automatisierte SSH-Key und Benutzer-Verwaltung für Debian/Ubuntu-Systeme über GitHub.

## 🚀 Quick Links

- **[📖 Vollständige Dokumentation](../../wiki)** - Komplette Anleitung im Wiki
- **[⚡ Schnellstart](../../wiki/Home#-schnellstart)** - 1-Minuten Setup
- **[🔧 Installation](../../wiki/Home#-detaillierte-installation)** - Schritt für Schritt
- **[❓ Troubleshooting](../../wiki/Home#-troubleshooting)** - Problemlösung

## ✨ Features

✅ **Automatische SSH-Key-Synchronisation** von GitHub  
✅ **Zentrale Benutzerverwaltung** über GitHub Repository  
✅ **Automatische Benutzeranlage** mit konfigurierbaren Rechten  
✅ **Sudo-Rechte-Management** (full/limited/none)  
✅ **Gruppen-Management** für Systemzugriff  
✅ **Zentrale Logs** in GitHub für alle Hosts  
✅ **Alle 5 Minuten automatische Updates**  
✅ **Lock-Mechanismus** gegen parallele Ausführung  

## 🎯 Zwei Modi verfügbar

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

## 🚀 Schnellstart

```bash
# 1. Repository klonen
git clone https://github.com/your-org/ssh-key-management.git
cd ssh-key-management

# 2. Automatische Installation
sudo ./install.sh

# 3. Konfiguration anpassen
cp config/examples/user-mapping.json.example config/user-mapping.json
nano config/user-mapping.json

# 4. GitHub Token setzen
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
export GITHUB_REPO="your-org/ssh-key-management"

# 5. Service aktivieren
sudo systemctl enable ssh-user-manager.timer
sudo systemctl start ssh-user-manager.timer
```

## 📋 Voraussetzungen

- Debian/Ubuntu System mit root-Zugriff
- GitHub Repository für Konfiguration  
- GitHub Personal Access Token (für private Repos)

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
