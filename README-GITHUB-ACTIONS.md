# SSH Key Management - GitHub Actions + Ansible

🎯 **Empfohlener Ansatz:** Zentrale, hochverfügbare Lösung mit Microsoft 365 Integration

## 🚀 Quick Start

### Architektur im Überblick

```
M365 IT-Team → GitHub Actions (M365 Sync) → user-mapping.json
                                                    ↓
GitHub Actions (Ansible) → Alle Debian Hosts (User + SSH Keys)
```

### 1. Setup (15 Minuten)

```bash
# 1. Repository klonen
git clone https://github.com/your-org/Babsy-SSH-Key-Managment.git
cd Babsy-SSH-Key-Managment

# 2. Azure AD App erstellen (siehe SETUP-GITHUB-SECRETS.md)
# 3. GitHub Secrets konfigurieren
# 4. Ansible Inventory anpassen: ansible/inventory/hosts.yml
# 5. SSH Keys deployment

# 6. Test
gh workflow run m365-sync.yml  # M365 Sync testen
gh workflow run deploy-users.yml -f dry_run=true  # Deployment testen
```

## ✨ Features

- ✅ **M365 Integration** - Automatischer User-Sync aus IT-Team Gruppe
- ✅ **GitHub Actions** - Zentrale Orchestrierung (hochverfügbar 99.9%)
- ✅ **Ansible Deployment** - Simultane Verwaltung aller Hosts
- ✅ **Automatische GitHub Issues** - Bei Fehlern werden Issues erstellt
- ✅ **SSH Key Import** - Von GitHub pro User
- ✅ **Sudo Management** - Full/Limited/None per User
- ✅ **Stündliche M365 Sync** - Immer aktuell
- ✅ **Täglich Backup-Deployment** - Fehlertoleranz

## 📋 Workflows

### M365 User Sync
- **Datei**: `.github/workflows/m365-sync.yml`
- **Schedule**: Jede Stunde um :00
- **Trigger**: Schedule, Manual, Push
- **Funktion**: Liest IT-Team aus M365, erstellt user-mapping.json

### Ansible Deployment
- **Datei**: `.github/workflows/deploy-users.yml`
- **Schedule**: Täglich 6:00 UTC
- **Trigger**: user-mapping.json Änderung, Schedule, Manual
- **Funktion**: Deployed Users auf alle Debian Hosts

## 🔧 Detaillierte Setup-Anleitungen

- **[GITHUB-ACTIONS-SETUP.md](GITHUB-ACTIONS-SETUP.md)** - Vollständige GitHub Actions Setup-Anleitung
- **[SETUP-GITHUB-SECRETS.md](SETUP-GITHUB-SECRETS.md)** - GitHub Secrets Konfiguration
- **[Ansible Dokumentation](ansible/README.md)** - Ansible Playbooks & Roles

## 🚨 Automatische Fehlerbehandlung

Bei Fehlern werden automatisch GitHub Issues erstellt mit:
- 🚨 M365 User Sync Failed - Wenn M365 Synchronisation fehlschlägt
- ⚠️ Ansible User Deployment Failed - Wenn Ansible Deployment fehlschlägt

**Issues enthalten:**
- Detaillierte Fehlerinformationen
- Mögliche Ursachen
- Troubleshooting-Schritte
- Quick-Fix-Anweisungen
- Links zu Logs

## 📊 Monitoring

```bash
# Workflow Status
gh run list

# Neueste M365 Sync
gh run view --workflow=m365-sync.yml

# Neuestes Deployment
gh run view --workflow=deploy-users.yml

# Issues anzeigen
gh issue list --label "automation"
```

## 🛡️ Sicherheit

- **GitHub Secrets** für alle sensiblen Daten
- **Least Privilege** API Permissions
- **SSH Key Authentication** (keine Passwörter)
- **Sudoers Validation** (visudo check)
- **Automatische Backups** vor Änderungen

## 🎯 Warum GitHub Actions + Ansible?

| Kriterium | GitHub Actions + Ansible | Lokale Scripts |
|-----------|-------------------------|----------------|
| Hochverfügbarkeit | ✅ 99.9% (GitHub) | ❌ Host-abhängig |
| Zentrale Orchestrierung | ✅ Ja | ❌ Nein |
| Alle Hosts gleichzeitig | ✅ Ja | ❌ Nein (einzeln) |
| Fehler-Monitoring | ✅ Auto-Issues | ❌ Logs nur lokal |
| Rollback | ✅ Git-basiert | ❌ Manuell |
| Setup-Komplexität | ⚠️ Mittel | ✅ Einfach |

## 📚 Weitere Dokumentation

- **[Readme.md](Readme.md)** - Projekt-Übersicht
- **[GITHUB-ACTIONS-SETUP.md](GITHUB-ACTIONS-SETUP.md)** - Detailliertes Setup
- **[SETUP-GITHUB-SECRETS.md](SETUP-GITHUB-SECRETS.md)** - Secret-Konfiguration

---

**Hauptdokumentation:** [GITHUB-ACTIONS-SETUP.md](GITHUB-ACTIONS-SETUP.md)
