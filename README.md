# SSH Key Management System

🔑 Automatisierte SSH-Key und Benutzer-Verwaltung für Debian/Ubuntu-Systeme über GitHub Actions und Microsoft 365.

## 🎯 Production Deployment (Empfohlen)

**Verwenden Sie GitHub Actions + Ansible für Production:**

📖 **[PRODUCTION-DEPLOYMENT.md](PRODUCTION-DEPLOYMENT.md)** - Complete Production Setup Guide (30 minutes)

```
Microsoft 365 → GitHub Actions (M365 Sync) → user-mapping.json
                             ↓
            GitHub Actions (Ansible) → All Debian Hosts
```

## ✨ Features

- ✅ **Microsoft 365 Integration** - Automatischer User-Sync aus IT-Team Gruppe
- ✅ **GitHub Actions Orchestration** - Zentrale Verwaltung (99.9% verfügbar)
- ✅ **Ansible Deployment** - Simultane Verwaltung aller Hosts
- ✅ **Automatische GitHub Issues** - Bei Fehlern werden Issues erstellt
- ✅ **SSH Key Import** - Von GitHub pro User
- ✅ **Sudo Management** - Full/Limited/None per User
- ✅ **Stündliche M365 Sync** - Immer aktuell
- ✅ **Täglich Backup-Deployment** - Fehlertoleranz

## 🚀 Quick Start (30 Minuten)

```bash
# 1. Azure AD App erstellen
# Siehe: PRODUCTION-DEPLOYMENT.md → Step 1

# 2. GitHub Secrets konfigurieren
# Repository → Settings → Secrets → Actions
# Siehe: SETUP-GITHUB-SECRETS.md

# 3. Extension Attributes in M365 setzen
# PowerShell: Set-AzureADUser -ObjectId "user@babsy.chh" -ExtensionAttribute1 "github-username"

# 4. Ansible Inventory konfigurieren
# Editiere: ansible/inventory/hosts.yml

# 5. SSH Keys deployen
ssh-keygen -t ed25519 -C "ansible@babsy" -f ~/.ssh/babsy_ansible_key
ssh-copy-id -i ~/.ssh/babsy_ansible_key.pub root@host1.babsy.local

# 6. Testen
gh workflow run m365-sync.yml
gh workflow run deploy-users.yml -f dry_run=true
```

## 📚 Dokumentation

### 📖 GitHub Wiki
- **[Wiki Home](https://github.com/BabsyIT/Babsy-SSH-Key-Managment/wiki)** - Umfassende Dokumentation
- **[Production Deployment Guide](https://github.com/BabsyIT/Babsy-SSH-Key-Managment/wiki/Production-Deployment)** - 30-Min Setup
- **[Troubleshooting](https://github.com/BabsyIT/Babsy-SSH-Key-Managment/wiki/Troubleshooting)** - Problemlösung

**Wiki Setup:** Führe `./scripts/populate-wiki.sh` aus, um das Wiki zu befüllen (siehe [docs/wiki/SETUP-INSTRUCTIONS.md](docs/wiki/SETUP-INSTRUCTIONS.md))

### Production Setup
- **[PRODUCTION-DEPLOYMENT.md](PRODUCTION-DEPLOYMENT.md)** ⭐ - **START HERE** für Production
- **[GITHUB-ACTIONS-SETUP.md](GITHUB-ACTIONS-SETUP.md)** - Detaillierte GitHub Actions Anleitung
- **[SETUP-GITHUB-SECRETS.md](SETUP-GITHUB-SECRETS.md)** - GitHub Secrets Konfiguration
- **[ansible/README.md](ansible/README.md)** - Ansible Playbooks & Roles

### Reference Only (NOT for Production)
- **[scripts/README.md](scripts/README.md)** - ⚠️ Referenz-Scripts (nicht für Production!)
- **[install.sh.legacy](install.sh.legacy)** - ⚠️ Legacy Installer (nicht für Production!)

## 🏗️ Architektur

### Production Architecture (GitHub Actions + Ansible)

```
┌─────────────────────────────────────────┐
│     Microsoft 365 (babsy.chh)           │
│           IT-Team Group                 │
│    (extensionAttribute1 = GitHub)       │
└─────────────────────────────────────────┘
                  │
                  │ Microsoft Graph API
                  ▼
┌─────────────────────────────────────────┐
│   GitHub Actions: M365 Sync (Hourly)    │
│   .github/workflows/m365-sync.yml       │
└─────────────────────────────────────────┘
                  │
                  │ Updates user-mapping.json
                  ▼
┌─────────────────────────────────────────┐
│  GitHub Actions: Ansible Deploy         │
│  .github/workflows/deploy-users.yml     │
└─────────────────────────────────────────┘
                  │
                  │ SSH (Ansible)
                  ▼
┌─────────────────────────────────────────┐
│      All Debian/Ubuntu Hosts            │
│  • User Creation                        │
│  • SSH Keys from GitHub                 │
│  • Sudo Configuration                   │
│  • Group Management                     │
└─────────────────────────────────────────┘
```

## 🔧 Workflows

### M365 User Sync
- **File:** `.github/workflows/m365-sync.yml`
- **Schedule:** Every hour at :00
- **Triggers:** Schedule, Manual, Push
- **Function:** Syncs IT-Team from M365 → Creates/updates user-mapping.json

### Ansible Deployment
- **File:** `.github/workflows/deploy-users.yml`
- **Schedule:** Daily at 6:00 UTC (backup)
- **Triggers:** user-mapping.json change, Schedule, Manual
- **Function:** Deploys users to all Debian hosts via Ansible

## 📊 Monitoring

### GitHub Actions

```bash
# View workflow runs
gh run list

# Watch M365 sync
gh run watch --workflow=m365-sync.yml

# Watch deployment
gh run watch --workflow=deploy-users.yml

# View issues (auto-created on failures)
gh issue list --label "automation"
```

### Automatic Error Handling

Bei Fehlern werden automatisch Issues erstellt:
- 🚨 **M365 User Sync Failed** - M365 connection/sync issues
- ⚠️ **Ansible User Deployment Failed** - Deployment errors

Issues enthalten:
- Detaillierte Fehleranalyse
- Mögliche Ursachen
- Troubleshooting Steps
- Quick-Fix Commands
- Links zu Logs

## 🎯 Warum GitHub Actions + Ansible?

| Kriterium | GitHub Actions + Ansible | Lokale Scripts |
|-----------|-------------------------|----------------|
| **Hochverfügbarkeit** | ✅ 99.9% (GitHub) | ❌ Host-abhängig |
| **Zentrale Orchestrierung** | ✅ Ja | ❌ Nein |
| **Alle Hosts gleichzeitig** | ✅ Ja | ❌ Einzeln |
| **Fehler-Monitoring** | ✅ Auto-Issues | ❌ Logs nur lokal |
| **Rollback** | ✅ Git-basiert | ❌ Manuell |
| **Audit Trail** | ✅ Vollständig | ❌ Begrenzt |
| **Setup-Komplexität** | ⚠️ Mittel | ✅ Einfach |
| **Skalierbarkeit** | ✅ Exzellent | ❌ Begrenzt |

## 🔒 Sicherheit

- ✅ **GitHub Secrets** für alle sensiblen Daten (M365 credentials, SSH keys)
- ✅ **Least Privilege** API Permissions (nur notwendige Rechte)
- ✅ **SSH Key Authentication** (keine Passwörter)
- ✅ **Sudoers Validation** (visudo syntax check vor Deployment)
- ✅ **Automatische Backups** vor jeder Änderung
- ✅ **Complete Audit Trail** (alle Actions geloggt)

## 🚨 Troubleshooting

### M365 Sync schlägt fehl

```bash
# Check GitHub Secrets
Settings → Secrets and variables → Actions
# Verify: M365_TENANT_ID, M365_CLIENT_ID, M365_CLIENT_SECRET

# Check Azure AD Permissions
Azure Portal → App registrations → API permissions
# Verify admin consent granted for User.Read.All, Group.Read.All, Directory.Read.All

# Test connection
# See SETUP-GITHUB-SECRETS.md for test script

# View workflow logs
gh run view --workflow=m365-sync.yml --log
```

### Ansible Deployment schlägt fehl

```bash
# Test SSH connectivity
ssh -i ~/.ssh/babsy_ansible_key root@host1.babsy.local "hostname"

# Test Ansible ping
cd ansible
ansible -i inventory/hosts.yml debian_hosts -m ping

# Check inventory
cat ansible/inventory/hosts.yml

# Validate user-mapping.json
jq '.' config/user-mapping.json

# View workflow logs
gh run view --workflow=deploy-users.yml --log
```

## 🤝 Support

- **Production Setup:** [PRODUCTION-DEPLOYMENT.md](PRODUCTION-DEPLOYMENT.md)
- **Issues:** [GitHub Issues](../../issues)
- **Workflow Logs:** [GitHub Actions](../../actions)
- **Discussions:** [Community Forum](../../discussions)

## 📄 Lizenz

MIT License - siehe [LICENSE](LICENSE) für Details.

---

## ⚠️ Important Notes

### Scripts Directory

Die Scripts in `scripts/` sind **NICHT für Production** gedacht. Sie dienen nur als Referenz.

**Für Production verwenden Sie:**
- ✅ GitHub Actions + Ansible (siehe [PRODUCTION-DEPLOYMENT.md](PRODUCTION-DEPLOYMENT.md))

**NICHT verwenden:**
- ❌ Lokale Scripts aus `scripts/`
- ❌ `install.sh.legacy`

---

**→ [START HERE: PRODUCTION-DEPLOYMENT.md](PRODUCTION-DEPLOYMENT.md) für Production Setup**
