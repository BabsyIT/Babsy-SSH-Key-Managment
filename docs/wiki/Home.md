# SSH Key Management System - Wiki Home

🔑 Zentrale SSH-Key und Benutzer-Verwaltung für Debian/Ubuntu über GitHub Actions und Microsoft 365

## 🚀 Quick Navigation

### Getting Started
- **[Production Deployment](Production-Deployment)** ⭐ **START HERE** - 30-Minuten Setup
- [Installation Overview](Installation-Overview) - Übersicht über alle Modi
- [Prerequisites](Prerequisites) - Was Sie brauchen

### Setup Guides
- **[GitHub Actions Setup](GitHub-Actions-Setup)** - Zentrale Orchestrierung (Empfohlen)
- [GitHub Secrets Configuration](GitHub-Secrets-Configuration) - Secrets einrichten
- [M365 Integration](M365-Integration) - Microsoft 365 anbinden
- [Ansible Configuration](Ansible-Configuration) - Ansible Playbooks konfigurieren

### Configuration
- [User Management](User-Management) - User-Konfiguration
- [Sudo Configuration](Sudo-Configuration) - Sudo-Rechte verwalten
- [SSH Keys Configuration](SSH-Keys-Configuration) - SSH-Keys einrichten
- [Separate Authorized Keys](Separate-Authorized-Keys) - Manuelle vs automatische Keys

### Operations
- [Monitoring & Logging](Monitoring-Logging) - System überwachen
- [Troubleshooting](Troubleshooting) - Problemlösung
- [Backup & Recovery](Backup-Recovery) - Backups und Wiederherstellung
- [Security Best Practices](Security-Best-Practices) - Sicherheit

### Advanced Topics
- [Multi Environment Setup](Multi-Environment-Setup) - Dev/Stage/Prod
- [Custom Workflows](Custom-Workflows) - Workflows anpassen
- [API Integration](API-Integration) - Weitere Integrationen
- [Migration Guide](Migration-Guide) - Von lokalen Scripts migrieren

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────┐
│  Microsoft 365 (babsy.chh)             │
│  IT-Team Gruppe                         │
│  (extensionAttribute1 = GitHub User)    │
└─────────────────────────────────────────┘
                 │
                 │ Microsoft Graph API
                 ▼
┌─────────────────────────────────────────┐
│  GitHub Actions: M365 Sync (Hourly)     │
│  - Fetches IT-Team members              │
│  - Gets GitHub usernames                │
│  - Updates user-mapping.json            │
└─────────────────────────────────────────┘
                 │
                 │ Git Commit
                 ▼
┌─────────────────────────────────────────┐
│  GitHub Actions: Ansible Deploy         │
│  - Reads user-mapping.json              │
│  - Deploys to all hosts                 │
│  - Creates users                        │
│  - Imports SSH keys from GitHub         │
│  - Configures sudo                      │
└─────────────────────────────────────────┘
                 │
                 │ SSH (Ansible)
                 ▼
┌─────────────────────────────────────────┐
│  All Debian/Ubuntu Hosts                │
│  ✅ Users created                       │
│  ✅ SSH keys imported                   │
│  ✅ Sudo configured                     │
│  ✅ Groups assigned                     │
└─────────────────────────────────────────┘
```

## ✨ Features

- ✅ **Microsoft 365 Integration** - Sync IT-Team automatisch
- ✅ **GitHub Actions Orchestrierung** - 99.9% Verfügbarkeit
- ✅ **Ansible Deployment** - Alle Hosts gleichzeitig
- ✅ **Automatische Issue-Erstellung** - Bei Fehlern
- ✅ **Separate authorized_keys** - Manuelle + automatische Keys
- ✅ **Sudo Management** - Full/Limited/None per User
- ✅ **Stündliche M365 Sync** - Immer aktuell
- ✅ **GDPR/DSGVO konform** - Keine User-Daten im Public Repo

## 🚀 Quick Start (30 Minuten)

```bash
# 1. Azure AD App erstellen
Azure Portal → App registrations → New
API Permissions: User.Read.All, Group.Read.All, Directory.Read.All
Admin Consent erteilen

# 2. GitHub Secrets konfigurieren
Repository → Settings → Secrets → Actions
M365_TENANT_ID, M365_CLIENT_ID, M365_CLIENT_SECRET, etc.

# 3. Extension Attributes in M365 setzen
Set-AzureADUser -ObjectId "user@babsy.chh" -ExtensionAttribute1 "github-username"

# 4. Ansible Inventory anpassen
cp ansible/inventory/hosts.yml.example ansible/inventory/hosts.yml
nano ansible/inventory/hosts.yml

# 5. SSH Keys deployen
ssh-keygen -t ed25519 -f ~/.ssh/babsy_ansible_key
ssh-copy-id -i ~/.ssh/babsy_ansible_key.pub root@host

# 6. Testen
gh workflow run m365-sync.yml
gh workflow run deploy-users.yml -f dry_run=true
```

**→ Detaillierte Anleitung: [Production Deployment](Production-Deployment)**

## 📊 Workflows

### M365 User Sync
- **Schedule:** Jede Stunde um :00
- **Trigger:** Schedule, Manual, Push
- **Function:** Syncs IT-Team → user-mapping.json

### Ansible Deployment
- **Schedule:** Täglich 6:00 UTC (Backup)
- **Trigger:** user-mapping.json change, Schedule, Manual
- **Function:** Deploys users → All hosts

## 🔒 Security

### GitHub Secrets (Nie im Repo!)
- ✅ M365 Credentials → GitHub Secrets
- ✅ SSH Private Keys → GitHub Secrets
- ✅ No secrets in code or config files
- ✅ Public repository safe

### GDPR/DSGVO
- ✅ Keine echten User-Daten im Repository
- ✅ user-mapping.json git-ignored
- ✅ Logs git-ignored
- ✅ Inventory git-ignored

**→ Details: [Security Best Practices](Security-Best-Practices)**

## 🆘 Support

### Documentation
- 📖 [Complete Guide](Production-Deployment)
- 🔧 [Troubleshooting](Troubleshooting)
- 🔐 [Security Policy](../SECURITY.md)

### Getting Help
- 🐛 [GitHub Issues](https://github.com/BabsyIT/Babsy-SSH-Key-Managment/issues)
- 💬 [Discussions](https://github.com/BabsyIT/Babsy-SSH-Key-Managment/discussions)
- 📧 Email: support@babsy.chh

## 📚 Additional Resources

### Files in Repository
- [PRODUCTION-DEPLOYMENT.md](../PRODUCTION-DEPLOYMENT.md) - Production Setup
- [GITHUB-ACTIONS-SETUP.md](../GITHUB-ACTIONS-SETUP.md) - GitHub Actions Details
- [SETUP-GITHUB-SECRETS.md](../SETUP-GITHUB-SECRETS.md) - Secrets Configuration
- [SEPARATE-AUTHORIZED-KEYS.md](../SEPARATE-AUTHORIZED-KEYS.md) - Dual Keys Setup
- [SECURITY.md](../SECURITY.md) - Security Policy
- [ansible/README.md](../ansible/README.md) - Ansible Documentation

### External Links
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Ansible Documentation](https://docs.ansible.com/)
- [Microsoft Graph API](https://docs.microsoft.com/en-us/graph/overview)

---

**Version:** 2.0
**Last Updated:** 2024-11-07
**License:** MIT
