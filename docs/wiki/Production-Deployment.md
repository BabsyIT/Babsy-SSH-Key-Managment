# Production Deployment Guide

⚡ **30-Minuten Setup für Production-Umgebung**

## 📋 Übersicht

Diese Anleitung führt Sie durch das komplette Setup der SSH Key Management Lösung mit GitHub Actions und Microsoft 365 Integration.

**Geschätzte Dauer:** 30 Minuten
**Voraussetzungen:** Admin-Zugriff auf M365, GitHub und Debian Hosts

## ✅ Prerequisites

Bevor Sie beginnen, stellen Sie sicher dass Sie haben:

- [ ] Microsoft 365 Tenant mit Admin-Zugriff
- [ ] GitHub Repository (dieses Repository)
- [ ] Root/Admin SSH-Zugriff zu allen Debian/Ubuntu Hosts
- [ ] Azure AD App Registration Permissions
- [ ] PowerShell (für M365 Extension Attributes)

## 🚀 Step 1: Azure AD App Registration (10 min)

### Via Azure Portal

```bash
1. https://portal.azure.com öffnen
2. Azure Active Directory → App registrations → New registration
3. Name: "SSH-User-Management-babsy"
4. Supported account types: "Accounts in this organizational directory only"
5. Redirect URI: Leer lassen
6. Klick "Register"
```

### API Permissions konfigurieren

```bash
7. App registrations → SSH-User-Management-babsy → API permissions
8. Add a permission → Microsoft Graph → Application permissions
9. Folgende Permissions hinzufügen:
   ✅ User.Read.All
   ✅ Group.Read.All
   ✅ Directory.Read.All
10. Klick "Grant admin consent for [Tenant]" ⚠️ WICHTIG!
11. Verify: Status sollte "Granted" sein (grüner Haken)
```

### Client Secret erstellen

```bash
12. Certificates & secrets → New client secret
13. Description: "GitHub Actions Production"
14. Expires: 24 months (oder länger)
15. Add
16. ⚠️ WICHTIG: Kopiere den Secret Value SOFORT
    (wird nur einmal angezeigt!)
```

### IDs notieren

```bash
17. App registrations → SSH-User-Management-babsy → Overview
18. Notiere:
    - Application (client) ID
    - Directory (tenant) ID
```

**→ Details: [M365 Integration](M365-Integration)**

## 🔧 Step 2: M365 Extension Attributes (5 min)

### PowerShell Setup

```powershell
# Azure AD Modul installieren (falls noch nicht vorhanden)
Install-Module AzureAD

# Mit Azure AD verbinden
Connect-AzureAD
```

### GitHub Usernames setzen

```powershell
# Für jeden IT-Team User
Set-AzureADUser -ObjectId "max.mustermann@babsy.chh" `
    -ExtensionAttribute1 "max-github-username"

# Bulk Update (empfohlen)
$ITTeamUsers = @(
    @{UPN="max.mustermann@babsy.chh"; GitHub="max-github"},
    @{UPN="anna.mueller@babsy.chh"; GitHub="anna-github"},
    @{UPN="tom.schmidt@babsy.chh"; GitHub="tom-schmidt"}
)

foreach ($user in $ITTeamUsers) {
    Set-AzureADUser -ObjectId $user.UPN `
        -ExtensionAttribute1 $user.GitHub
    Write-Host "✅ Set GitHub username for $($user.UPN): $($user.GitHub)"
}
```

### Verification

```powershell
# Prüfen ob Extension Attribute gesetzt wurde
Get-AzureADUser -ObjectId "max.mustermann@babsy.chh" |
    Select-Object UserPrincipalName,
        @{Name="GitHubUser";Expression={$_.ExtensionAttribute1}}
```

**→ Details: [M365 Integration](M365-Integration)**

## 🔐 Step 3: GitHub Secrets (5 min)

### Secrets konfigurieren

```bash
# Im GitHub Repository
Repository → Settings → Secrets and variables → Actions
→ New repository secret
```

### Required Secrets

| Secret Name | Value | Beschreibung |
|------------|-------|--------------|
| `M365_TENANT_ID` | `babsy.onmicrosoft.com` | Your tenant ID |
| `M365_CLIENT_ID` | `<app-client-id>` | Azure AD App ID |
| `M365_CLIENT_SECRET` | `<client-secret>` | ⚠️ Client Secret (Step 1) |
| `M365_IT_GROUP_NAME` | `IT-Team` | M365 Group name |
| `M365_GITHUB_USERNAME_FIELD` | `extensionAttribute1` | Attribute field |
| `ANSIBLE_SSH_PRIVATE_KEY` | `<private-key>` | SSH key (Step 4) |
| `ANSIBLE_TARGET_HOSTS` | `host1.babsy.local,...` | Comma-separated hosts |

**→ Details: [GitHub Secrets Configuration](GitHub-Secrets-Configuration)**

## 🔑 Step 4: SSH Keys für Ansible (5 min)

### SSH Key generieren

```bash
# Neuen SSH Key generieren
ssh-keygen -t ed25519 \
    -C "ansible@github-actions-babsy" \
    -f ~/.ssh/babsy_ansible_key \
    -N ""

# Output:
# ~/.ssh/babsy_ansible_key      (private key - für GitHub Secret)
# ~/.ssh/babsy_ansible_key.pub  (public key - für Hosts)
```

### Public Key auf Hosts deployen

```bash
# Auf alle Ziel-Hosts kopieren
for host in host1.babsy.local host2.babsy.local host3.babsy.local; do
    ssh-copy-id -i ~/.ssh/babsy_ansible_key.pub root@$host
    echo "✅ Deployed to $host"
done
```

### Connectivity testen

```bash
# Test: SSH Verbindung ohne Passwort
ssh -i ~/.ssh/babsy_ansible_key root@host1.babsy.local "hostname && echo 'SSH OK'"

# Sollte funktionieren ohne nach Passwort zu fragen ✅
```

### Private Key als GitHub Secret

```bash
# Private Key anzeigen
cat ~/.ssh/babsy_ansible_key

# Output komplett kopieren (inkl. BEGIN/END Zeilen)
# -----BEGIN OPENSSH PRIVATE KEY-----
# ...
# -----END OPENSSH PRIVATE KEY-----

# In GitHub einfügen:
# Repository → Settings → Secrets → New secret
# Name: ANSIBLE_SSH_PRIVATE_KEY
# Value: <kompletten-key-inhalt-einfügen>
```

**→ Details: [SSH Keys Configuration](SSH-Keys-Configuration)**

## 📝 Step 5: Ansible Inventory (5 min)

### Inventory File erstellen

```bash
# Template kopieren
cp ansible/inventory/hosts.yml.example ansible/inventory/hosts.yml

# Editieren
nano ansible/inventory/hosts.yml
```

### Beispiel-Konfiguration

```yaml
all:
  children:
    debian_hosts:
      hosts:
        host1.babsy.local:
          ansible_host: 192.168.1.10
          ansible_user: root

        host2.babsy.local:
          ansible_host: 192.168.1.11
          ansible_user: root

        host3.babsy.local:
          ansible_host: 192.168.1.12
          ansible_user: root

      vars:
        ansible_python_interpreter: /usr/bin/python3

    production:
      hosts:
        host1.babsy.local:
        host2.babsy.local:
      vars:
        environment: production

    staging:
      hosts:
        host3.babsy.local:
      vars:
        environment: staging
```

### Inventory committen (optional)

```bash
# ACHTUNG: Enthält interne IPs - nur in Private Repos!
# Für Public Repos: Inventory NICHT committen (bereits in .gitignore)

# Für Private Repos:
git add ansible/inventory/hosts.yml
git commit -m "Add production inventory"
git push
```

**→ Details: [Ansible Configuration](Ansible-Configuration)**

## 🧪 Step 6: Testing (5 min)

### Test 1: M365 Sync

```bash
# M365 Sync manuell triggern
gh workflow run m365-sync.yml

# Warten (ca. 1-2 Minuten)
sleep 120

# Status prüfen
gh run list --workflow=m365-sync.yml

# Logs ansehen
gh run view --workflow=m365-sync.yml --log

# Verify: user-mapping.json sollte aktualisiert sein
git pull
cat config/user-mapping.json | jq '.users[] | {local_user, github_user}'
```

**Expected Output:**
```json
{
  "local_user": "maxmustermann",
  "github_user": "max-github"
}
{
  "local_user": "annamueller",
  "github_user": "anna-github"
}
```

### Test 2: Ansible Deployment (Dry Run)

```bash
# Test deployment OHNE Änderungen
gh workflow run deploy-users.yml \
    -f target_environment=all \
    -f dry_run=true

# Status prüfen
gh run watch --workflow=deploy-users.yml

# Logs ansehen
gh run view --workflow=deploy-users.yml --log
```

**Expected:** Zeigt was geändert werden würde, macht aber keine Änderungen

### Test 3: Staging Deployment

```bash
# Deployment auf Staging Host
gh workflow run deploy-users.yml \
    -f target_environment=staging \
    -f dry_run=false

# Verify auf Staging Host
ssh root@host3.babsy.local "id maxmustermann"
ssh root@host3.babsy.local "cat /home/maxmustermann/.ssh/authorized_keys_github | wc -l"
ssh root@host3.babsy.local "sudo -l -U maxmustermann"
```

**Expected:**
```
uid=1001(maxmustermann) gid=1001(maxmustermann) groups=...
2  (Anzahl SSH Keys)
User maxmustermann may run the following commands on host3:
    (ALL : ALL) NOPASSWD: /usr/bin/systemctl restart *
    ...
```

### Test 4: Production Deployment

```bash
# NUR wenn Staging erfolgreich war!
gh workflow run deploy-users.yml \
    -f target_environment=production \
    -f dry_run=false

# Verify auf allen Production Hosts
for host in host1.babsy.local host2.babsy.local; do
    echo "=== Checking $host ==="
    ssh root@$host "id maxmustermann && \
        cat /home/maxmustermann/.ssh/authorized_keys_github | wc -l"
done
```

### Test 5: User Login

```bash
# Als User einloggen (mit GitHub Key)
ssh maxmustermann@host1.babsy.local

# Auf dem Host:
hostname
whoami
sudo systemctl status ssh  # Sollte mit sudo funktionieren
```

**✅ Wenn alle Tests erfolgreich: Deployment komplett!**

## 📊 Step 7: Monitoring Setup

### GitHub Actions überwachen

```bash
# Workflow Runs ansehen
gh run list

# Latest M365 Sync
gh run view --workflow=m365-sync.yml

# Latest Deployment
gh run view --workflow=deploy-users.yml

# Issues (automatisch erstellt bei Fehlern)
gh issue list --label "automation"
```

### Host-Level Logs

```bash
# Auf Host prüfen
ssh root@host1.babsy.local

# Logs ansehen
tail -f /var/log/ssh-user-management/deployment.log
tail -f /var/log/ssh-user-management/ssh_keys.log
tail -f /var/log/ssh-user-management/sudo.log
```

**→ Details: [Monitoring & Logging](Monitoring-Logging)**

## 🎯 Production Betrieb

### Automatische Workflows

| Workflow | Schedule | Beschreibung |
|----------|----------|--------------|
| M365 Sync | Jede Stunde um :00 | Synced IT-Team aus M365 |
| Ansible Deploy | Täglich 6:00 UTC | Backup-Deployment |
| Deploy | Bei user-mapping.json Änderung | Sofortiges Deployment |

### Manuelles Deployment

```bash
# M365 Sync forcieren
gh workflow run m365-sync.yml

# Deployment auf alle Hosts
gh workflow run deploy-users.yml

# Deployment auf bestimmte Environment
gh workflow run deploy-users.yml -f target_environment=production

# Dry Run (Test ohne Änderungen)
gh workflow run deploy-users.yml -f dry_run=true
```

## 🚨 Troubleshooting

### M365 Sync schlägt fehl

**Prüfen:**
1. GitHub Secrets korrekt?
2. Azure AD Admin Consent erteilt?
3. IT-Team Gruppe existiert?
4. Extension Attributes gesetzt?

**Fix:**
```bash
# Logs prüfen
gh run view --workflow=m365-sync.yml --log

# Secrets prüfen
Repository → Settings → Secrets

# Azure AD Permissions prüfen
Azure Portal → App registrations → API permissions
```

**→ Details: [Troubleshooting](Troubleshooting#m365-sync-fails)**

### Ansible Deployment schlägt fehl

**Prüfen:**
1. SSH Key gültig?
2. Hosts erreichbar?
3. Inventory korrekt?
4. user-mapping.json valid?

**Fix:**
```bash
# SSH Connection testen
ssh -i ~/.ssh/babsy_ansible_key root@host1.babsy.local

# Logs prüfen
gh run view --workflow=deploy-users.yml --log

# Inventory prüfen
cat ansible/inventory/hosts.yml
```

**→ Details: [Troubleshooting](Troubleshooting#ansible-deployment-fails)**

## ✅ Deployment Checklist

### Vor Go-Live

- [ ] Azure AD App erstellt und Permissions erteilt
- [ ] GitHub Secrets konfiguriert
- [ ] M365 Extension Attributes gesetzt
- [ ] SSH Keys auf Hosts deployed
- [ ] Ansible Inventory konfiguriert
- [ ] M365 Sync erfolgreich getestet
- [ ] Deployment auf Staging erfolgreich
- [ ] User Login funktioniert
- [ ] Sudo-Rechte getestet

### Nach Go-Live

- [ ] Monitoring aktiv
- [ ] Automatische Workflows laufen
- [ ] Issues-Überwachung eingerichtet
- [ ] Backup-Prozess etabliert
- [ ] Secret-Rotation geplant
- [ ] Dokumentation aktualisiert

## 📚 Weitere Dokumentation

- [GitHub Actions Setup](GitHub-Actions-Setup) - Workflow Details
- [M365 Integration](M365-Integration) - Microsoft 365 Details
- [Ansible Configuration](Ansible-Configuration) - Ansible Details
- [Security Best Practices](Security-Best-Practices) - Sicherheit
- [Troubleshooting](Troubleshooting) - Problemlösung

## 🆘 Support

Bei Problemen:
1. [Troubleshooting Guide](Troubleshooting) prüfen
2. [GitHub Issues](https://github.com/BabsyIT/Babsy-SSH-Key-Managment/issues) durchsuchen
3. Neues Issue erstellen mit Details

---

**Nächster Schritt:** [Monitoring & Logging Setup](Monitoring-Logging)
