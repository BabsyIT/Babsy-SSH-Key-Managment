# GitHub Actions + Ansible Setup

🚀 Zentrale, hochverfügbare SSH User Management Lösung mit Microsoft 365 Integration

## 🏗️ Architektur-Übersicht

```
┌─────────────────────────────────────────────────────────────────┐
│                     Microsoft 365 Tenant                         │
│                         (babsy.chh)                              │
│                                                                  │
│  ┌──────────────┐        ┌─────────────────────────────────┐   │
│  │   IT-Team    │        │  Extension Attributes           │   │
│  │   Gruppe     │───────▶│  extensionAttribute1 =          │   │
│  │              │        │  "github-username"              │   │
│  └──────────────┘        └─────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Microsoft Graph API
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Actions Workflow                      │
│                  (.github/workflows/m365-sync.yml)              │
│                                                                  │
│  1. Fetch users from M365 IT-Team                               │
│  2. Get GitHub usernames from Extension Attributes             │
│  3. Generate user-mapping.json                                  │
│  4. Commit to repository                                        │
│  5. Trigger Ansible deployment                                  │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Repository Dispatch
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│               GitHub Actions Ansible Deployment                  │
│              (.github/workflows/deploy-users.yml)               │
│                                                                  │
│  1. Read user-mapping.json                                      │
│  2. Run Ansible playbook                                        │
│  3. Deploy to all Debian hosts                                  │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    │ SSH (via Ansible)
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Debian/Ubuntu Hosts                         │
│                                                                  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                │
│  │  Host 1    │  │  Host 2    │  │  Host 3    │                │
│  │            │  │            │  │            │                │
│  │ ✓ Users    │  │ ✓ Users    │  │ ✓ Users    │                │
│  │ ✓ SSH Keys │  │ ✓ SSH Keys │  │ ✓ SSH Keys │                │
│  │ ✓ Sudo     │  │ ✓ Sudo     │  │ ✓ Sudo     │                │
│  └────────────┘  └────────────┘  └────────────┘                │
└─────────────────────────────────────────────────────────────────┘
```

## ⚡ Workflow-Ablauf

### 1. M365 User Synchronisation (Stündlich)

```yaml
Schedule: Jede Stunde um :00
Trigger: Cron, Manual, Push
```

**Schritte:**
1. ✅ Authentifizierung mit Microsoft Graph API
2. ✅ Lesen der IT-Team Gruppe aus M365
3. ✅ Extrahieren der GitHub Usernames aus Extension Attributes
4. ✅ Generieren/Aktualisieren von `config/user-mapping.json`
5. ✅ Commit & Push zu Repository
6. ✅ Trigger Ansible Deployment (bei Änderungen)

### 2. Ansible User Deployment (Bei Änderungen)

```yaml
Trigger: user-mapping.json Update, Schedule (täglich 6:00), Manual
```

**Schritte:**
1. ✅ Checkout Repository
2. ✅ Setup Ansible & Dependencies
3. ✅ SSH Key Configuration
4. ✅ Run Ansible Playbook auf allen Hosts:
   - User erstellen (falls nicht existiert)
   - Gruppen zuweisen
   - SSH Keys von GitHub importieren
   - Sudo-Rechte konfigurieren
5. ✅ Verification & Reporting

## 🔧 Initiales Setup

### Schritt 1: Azure AD App Registration

```bash
# Azure Portal
1. https://portal.azure.com
2. Azure Active Directory → App registrations → New registration
3. Name: "SSH-User-Management-babsy"
4. Register

# Permissions hinzufügen
5. API permissions → Add permission → Microsoft Graph
6. Application permissions:
   - User.Read.All
   - Group.Read.All
   - Directory.Read.All
7. Grant admin consent ✓

# Client Secret erstellen
8. Certificates & secrets → New client secret
9. Description: "GitHub Actions"
10. Kopiere Client Secret (wird nur einmal angezeigt!)
```

### Schritt 2: Extension Attributes in M365 setzen

```powershell
# PowerShell - Für jeden IT-Team User
Connect-AzureAD

# Beispiel für einen User
Set-AzureADUser -ObjectId "max.mustermann@babsy.chh" `
    -ExtensionAttribute1 "max-github-username"

# Bulk Update
$ITTeamUsers = @(
    @{UPN="max.mustermann@babsy.chh"; GitHub="max-github"},
    @{UPN="anna.mueller@babsy.chh"; GitHub="anna-mueller"},
    @{UPN="tom.schmidt@babsy.chh"; GitHub="tom-schmidt"}
)

foreach ($user in $ITTeamUsers) {
    Set-AzureADUser -ObjectId $user.UPN -ExtensionAttribute1 $user.GitHub
    Write-Host "✓ Set GitHub username for $($user.UPN)"
}
```

### Schritt 3: GitHub Secrets konfigurieren

```bash
# Im GitHub Repository: Settings → Secrets and variables → Actions

# M365 Secrets
M365_TENANT_ID          = "babsy.onmicrosoft.com"
M365_CLIENT_ID          = "<deine-app-client-id>"
M365_CLIENT_SECRET      = "<dein-client-secret>"
M365_IT_GROUP_NAME      = "IT-Team"
M365_GITHUB_USERNAME_FIELD = "extensionAttribute1"

# Ansible Secrets
ANSIBLE_SSH_PRIVATE_KEY = "<ssh-private-key-inhalt>"
ANSIBLE_TARGET_HOSTS    = "host1.babsy.local,host2.babsy.local,host3.babsy.local"
```

**Siehe [SETUP-GITHUB-SECRETS.md](SETUP-GITHUB-SECRETS.md) für Details!**

### Schritt 4: Ansible Inventory konfigurieren

```yaml
# ansible/inventory/hosts.yml bearbeiten

all:
  children:
    debian_hosts:
      hosts:
        host1.babsy.local:
          ansible_host: 10.0.1.10
          ansible_user: root

        host2.babsy.local:
          ansible_host: 10.0.1.11
          ansible_user: root

        host3.babsy.local:
          ansible_host: 10.0.1.12
          ansible_user: root
```

### Schritt 5: SSH Key Deployment

```bash
# SSH Key generieren (auf deinem PC)
ssh-keygen -t ed25519 -C "ansible@github-actions" -f ~/.ssh/babsy_ansible_key

# Public Key auf alle Ziel-Hosts kopieren
for host in host1.babsy.local host2.babsy.local host3.babsy.local; do
    ssh-copy-id -i ~/.ssh/babsy_ansible_key.pub root@$host
    echo "✓ Deployed to $host"
done

# Private Key als GitHub Secret speichern
cat ~/.ssh/babsy_ansible_key
# → Kopiere kompletten Inhalt in GitHub Secret: ANSIBLE_SSH_PRIVATE_KEY
```

### Schritt 6: Test & Verify

```bash
# 1. M365 Sync manuell triggern
GitHub → Actions → "M365 User Sync" → Run workflow

# 2. Logs prüfen
GitHub → Actions → Workflow run → Logs ansehen

# 3. user-mapping.json prüfen
GitHub → config/user-mapping.json → Sollte IT-Team User enthalten

# 4. Deployment manuell triggern (Dry Run)
GitHub → Actions → "Deploy Users to Hosts" → Run workflow
  → target_environment: all
  → dry_run: true

# 5. Produktiv deployment
GitHub → Actions → "Deploy Users to Hosts" → Run workflow
  → dry_run: false

# 6. Auf Ziel-Host prüfen
ssh root@host1.babsy.local
id maxmustermann   # User sollte existieren
sudo -l -U maxmustermann   # Sudo-Rechte prüfen
cat /home/maxmustermann/.ssh/authorized_keys  # SSH Keys prüfen
```

## 📊 Monitoring & Logs

### GitHub Actions Logs

```bash
# Via GitHub UI
Repository → Actions → Workflows → Logs

# Via GitHub CLI
gh run list --workflow=m365-sync.yml
gh run view <run-id> --log
```

### Ansible Deployment Reports

```bash
# Automatische Summary in GitHub Actions
Actions → Deploy Users to Hosts → Run → Summary

# Zeigt:
- Deployment Status
- Anzahl deployter Users
- User-Details (Name, GitHub, Sudo)
- Errors/Warnings
```

### Host-Level Logs

```bash
# Auf Ziel-Hosts
ssh root@host1.babsy.local

# Ansible Logs
tail -f /var/log/ssh-user-management/deployment.log
tail -f /var/log/ssh-user-management/ssh_keys.log
tail -f /var/log/ssh-user-management/sudo.log
```

## 🔄 Automatische Synchronisation

### Schedules

| Workflow | Schedule | Beschreibung |
|----------|----------|--------------|
| M365 Sync | Jede Stunde um :00 | Synchronisiert User aus M365 |
| Deploy Users | Täglich um 6:00 UTC | Backup-Deployment (falls Trigger fehlt) |

### Trigger

| Event | Workflow | Aktion |
|-------|----------|--------|
| M365 User geändert | M365 Sync → Deploy | Automatische Synchronisation |
| user-mapping.json Push | Deploy Users | Sofortiges Deployment |
| Manual Trigger | Beide | On-Demand Ausführung |

## 🛡️ Sicherheit

### Best Practices

✅ **GitHub Secrets** - Alle sensiblen Daten in Secrets
✅ **Least Privilege** - Minimale API Permissions
✅ **SSH Key Authentication** - Keine Passwörter
✅ **Sudoers Validation** - Visudo Syntax Check
✅ **Backups** - Automatische Backups vor Änderungen
✅ **Audit Logs** - Komplette Logging-Chain

### Secret Rotation

```bash
# Client Secret alle 6 Monate erneuern
Azure Portal → App registrations → Certificates & secrets → New secret

# SSH Keys jährlich erneuern
ssh-keygen -t ed25519 -C "ansible@github-actions-$(date +%Y)" -f ~/.ssh/babsy_ansible_key_new
# Deploy auf Hosts
# Update GitHub Secret
```

## 🚨 Troubleshooting

### M365 Sync schlägt fehl

```bash
# Prüfen:
1. Secrets korrekt? (Settings → Secrets)
2. Admin Consent erteilt? (Azure Portal → API Permissions)
3. IT-Team Gruppe existiert?
4. Extension Attributes gesetzt?

# Debug:
GitHub → Actions → M365 User Sync → Failed run → Logs
```

### Ansible Deployment schlägt fehl

```bash
# Prüfen:
1. SSH Key korrekt? (Test: ssh -i key root@host)
2. Inventory korrekt? (ansible/inventory/hosts.yml)
3. Hosts erreichbar? (ping, ssh)
4. user-mapping.json valid? (jq '.' config/user-mapping.json)

# Debug:
GitHub → Actions → Deploy Users → Failed run → Logs
```

## 📚 Weitere Dokumentation

- **[SETUP-GITHUB-SECRETS.md](SETUP-GITHUB-SECRETS.md)** - Detaillierte Secret-Konfiguration
- **[Readme.md](Readme.md)** - Projekt-Übersicht
- **[Ansible Docs](ansible/README.md)** - Ansible Playbook Details

## 💡 Erweiterte Nutzung

### Multi-Environment Deployment

```yaml
# Nur Production Hosts
gh workflow run deploy-users.yml -f target_environment=production

# Nur Staging Hosts
gh workflow run deploy-users.yml -f target_environment=staging

# Dry Run Test
gh workflow run deploy-users.yml -f dry_run=true
```

### Custom User Groups

```yaml
# In M365: Mehrere IT-Gruppen
- IT-Team-Admins
- IT-Team-Developers
- IT-Team-Support

# Separate Workflows für verschiedene Gruppen
# Anpassung in .github/workflows/m365-sync.yml möglich
```
