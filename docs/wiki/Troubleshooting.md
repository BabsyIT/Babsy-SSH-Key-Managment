# Troubleshooting Guide

🔧 Lösungen für häufige Probleme

## 📋 Quick Diagnostic

### System Status prüfen

```bash
# GitHub Actions Status
gh run list --limit 5

# Latest Workflow Status
gh run view --workflow=m365-sync.yml
gh run view --workflow=deploy-users.yml

# Issues prüfen (automatisch erstellt bei Fehlern)
gh issue list --label "automation"
```

---

## 🚨 M365 Sync Fails

### Symptome

- Workflow `m365-sync.yml` schlägt fehl
- Error: "Authentication failed"
- Error: "Group not found"
- Error: "Insufficient privileges"

### Diagnostic

```bash
# Logs ansehen
gh run view --workflow=m365-sync.yml --log

# Häufige Errors:
# - "failed to acquire token"
# - "403 Forbidden"
# - "Group 'IT-Team' not found"
# - "No access token received"
```

### Lösungen

#### Error: Authentication Failed

**Ursache:** Ungültige M365 Credentials

**Fix:**
```bash
# 1. Secrets prüfen
Repository → Settings → Secrets and variables → Actions

# Verify:
# - M365_TENANT_ID korrekt?
# - M365_CLIENT_ID korrekt?
# - M365_CLIENT_SECRET korrekt und nicht abgelaufen?

# 2. Secret testen (PowerShell)
$TenantId = "babsy.onmicrosoft.com"
$ClientId = "<your-client-id>"
$ClientSecret = "<your-client-secret>"

$Body = @{
    grant_type    = "client_credentials"
    client_id     = $ClientId
    client_secret = $ClientSecret
    scope         = "https://graph.microsoft.com/.default"
}

$Token = Invoke-RestMethod -Method Post `
    -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
    -Body $Body

if ($Token.access_token) {
    Write-Host "✅ Authentication successful"
} else {
    Write-Host "❌ Authentication failed"
}
```

#### Error: Insufficient Privileges / 403 Forbidden

**Ursache:** Admin Consent nicht erteilt oder falsche Permissions

**Fix:**
```bash
# 1. Azure Portal prüfen
Azure Portal → Azure Active Directory
→ App registrations → SSH-User-Management-babsy
→ API permissions

# 2. Verify Permissions:
# ✅ User.Read.All (Application)
# ✅ Group.Read.All (Application)
# ✅ Directory.Read.All (Application)

# 3. Admin Consent Status prüfen:
# Alle Permissions sollten "Granted for [Tenant]" zeigen (grüner Haken)

# 4. Falls nicht: Admin Consent erneut erteilen
# → Klick "Grant admin consent for [Tenant]"
# → Confirm
```

#### Error: Group 'IT-Team' not found

**Ursache:** Group existiert nicht oder falscher Name

**Fix:**
```powershell
# 1. Group in M365 prüfen
Connect-AzureAD
Get-AzureADGroup -Filter "DisplayName eq 'IT-Team'"

# Output sollte die Gruppe zeigen
# Wenn nicht: Gruppe existiert nicht!

# 2. Gruppe erstellen
New-AzureADGroup -DisplayName "IT-Team" `
    -MailEnabled $false `
    -SecurityEnabled $true `
    -MailNickName "IT-Team"

# 3. Members hinzufügen
Add-AzureADGroupMember -ObjectId <group-id> `
    -RefObjectId <user-id>

# 4. GitHub Secret prüfen/aktualisieren
# Repository → Settings → Secrets
# M365_IT_GROUP_NAME = "IT-Team"  (exakter Name!)
```

#### Error: No extension attribute found

**Ursache:** Extension Attributes nicht gesetzt

**Fix:**
```powershell
# 1. Extension Attribute prüfen
Get-AzureADUser -ObjectId "max.mustermann@babsy.chh" |
    Select-Object UserPrincipalName, ExtensionAttribute1

# 2. Falls leer: GitHub Username setzen
Set-AzureADUser -ObjectId "max.mustermann@babsy.chh" `
    -ExtensionAttribute1 "max-github"

# 3. Für alle IT-Team User setzen
$Group = Get-AzureADGroup -Filter "DisplayName eq 'IT-Team'"
$Members = Get-AzureADGroupMember -ObjectId $Group.ObjectId

foreach ($member in $Members) {
    $github = Read-Host "GitHub username für $($member.UserPrincipalName)"
    Set-AzureADUser -ObjectId $member.ObjectId `
        -ExtensionAttribute1 $github
    Write-Host "✅ Set for $($member.UserPrincipalName)"
}
```

---

## 🔧 Ansible Deployment Fails

### Symptome

- Workflow `deploy-users.yml` schlägt fehl
- Error: "SSH connection failed"
- Error: "Host unreachable"
- Error: "Permission denied"

### Diagnostic

```bash
# Logs ansehen
gh run view --workflow=deploy-users.yml --log

# Häufige Errors:
# - "Failed to connect to the host via ssh"
# - "Permission denied (publickey)"
# - "Host key verification failed"
# - "Timeout connecting to host"
```

### Lösungen

#### Error: SSH Connection Failed / Permission Denied

**Ursache:** SSH Key nicht authorized oder falsch

**Fix:**
```bash
# 1. SSH Key lokal testen
ssh -i ~/.ssh/babsy_ansible_key root@host1.babsy.local "hostname"

# Sollte ohne Passwort funktionieren
# Falls "Permission denied":

# 2. Public Key erneut deployen
ssh-copy-id -i ~/.ssh/babsy_ansible_key.pub root@host1.babsy.local

# Falls das nicht funktioniert, manuell:
cat ~/.ssh/babsy_ansible_key.pub | \
    ssh root@host1.babsy.local \
    "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# 3. Permissions auf Host prüfen
ssh root@host1.babsy.local
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown -R root:root ~/.ssh

# 4. GitHub Secret aktualisieren
# Repository → Settings → Secrets
# ANSIBLE_SSH_PRIVATE_KEY = <private-key-content>
cat ~/.ssh/babsy_ansible_key  # Komplett kopieren
```

#### Error: Host unreachable / Timeout

**Ursache:** Host offline oder Firewall blockiert

**Fix:**
```bash
# 1. Host erreichbar?
ping host1.babsy.local

# 2. SSH Port offen?
telnet host1.babsy.local 22
# oder
nc -zv host1.babsy.local 22

# 3. Von GitHub Actions aus?
# GitHub Actions IPs müssen zugelassen sein
# Siehe: https://api.github.com/meta
# → "actions" IP ranges

# 4. Firewall-Regel prüfen/erstellen
# Auf dem Host:
sudo ufw status
sudo ufw allow from <github-actions-ip> to any port 22
```

#### Error: Inventory file not found

**Ursache:** Inventory file fehlt oder falsch konfiguriert

**Fix:**
```bash
# 1. Inventory existiert?
ls -la ansible/inventory/hosts.yml

# 2. Falls nicht: Von Template erstellen
cp ansible/inventory/hosts.yml.example ansible/inventory/hosts.yml

# 3. Editieren und committen (nur für Private Repos!)
nano ansible/inventory/hosts.yml
git add ansible/inventory/hosts.yml
git commit -m "Add inventory"
git push

# Für Public Repos: Inventory lokal halten (git-ignored)
```

#### Error: Invalid user-mapping.json

**Ursache:** JSON Syntax-Fehler oder leere Datei

**Fix:**
```bash
# 1. Validate JSON
jq '.' config/user-mapping.json

# Sollte valid JSON ausgeben
# Bei Error: Syntax-Fehler im JSON

# 2. M365 Sync erneut laufen lassen
gh workflow run m365-sync.yml

# 3. Manuell erstellen (Fallback)
cat > config/user-mapping.json <<'EOF'
{
  "users": [
    {
      "github_user": "max-github",
      "local_user": "maxmustermann",
      "full_name": "Max Mustermann",
      "sudo_access": "limited",
      "groups": ["users", "sudo", "docker"]
    }
  ],
  "config": {
    "default_shell": "/bin/bash",
    "default_group": "users",
    "user_home_base": "/home"
  }
}
EOF

# 4. Committen und pushen
git add config/user-mapping.json
git commit -m "Add user mapping"
git push
```

#### Error: Sudoers validation failed

**Ursache:** Ungültige sudo_commands in user-mapping.json

**Fix:**
```bash
# 1. user-mapping.json prüfen
jq '.users[] | select(.sudo_access == "limited") | .sudo_commands' \
    config/user-mapping.json

# 2. Sudo commands müssen absolute Pfade sein:
# ✅ Korrekt: "/usr/bin/systemctl restart *"
# ❌ Falsch:  "systemctl restart *"

# 3. Korrigieren
nano config/user-mapping.json

# Beispiel korrektes Format:
"sudo_commands": [
    "/usr/bin/systemctl restart nginx",
    "/usr/bin/systemctl reload nginx",
    "/usr/bin/systemctl status *",
    "/usr/bin/docker ps",
    "/usr/bin/journalctl *"
]

# 4. Erneut deployen
gh workflow run deploy-users.yml
```

---

## 🔑 SSH Keys Issues

### User kann sich nicht einloggen

**Symptome:**
- `ssh user@host` fragt nach Passwort
- "Permission denied (publickey)"

**Diagnostic:**
```bash
# 1. Auf Host prüfen
ssh root@host1.babsy.local

# 2. User existiert?
id maxmustermann

# 3. .ssh Verzeichnis vorhanden?
ls -la /home/maxmustermann/.ssh/

# 4. authorized_keys_github vorhanden und nicht leer?
cat /home/maxmustermann/.ssh/authorized_keys_github

# 5. Permissions korrekt?
ls -la /home/maxmustermann/.ssh/
# Sollte sein:
# drwx------ (700) .ssh/
# -rw------- (600) authorized_keys*
```

**Fix:**
```bash
# 1. Permissions korrigieren
chown -R maxmustermann:maxmustermann /home/maxmustermann/.ssh
chmod 700 /home/maxmustermann/.ssh
chmod 600 /home/maxmustermann/.ssh/authorized_keys*

# 2. SSH Config prüfen
sudo sshd -T | grep authorizedkeysfile
# Sollte sein:
# authorizedkeysfile .ssh/authorized_keys .ssh/authorized_keys_github

# 3. Falls nicht: Deployment erneut ausführen
gh workflow run deploy-users.yml

# 4. SSHD Logs prüfen
sudo tail -f /var/log/auth.log
# Während User versucht sich einzuloggen

# 5. GitHub Keys prüfen
# Sind Keys auf GitHub vorhanden?
curl https://github.com/max-github.keys
```

### GitHub Keys werden nicht importiert

**Symptome:**
- `authorized_keys_github` leer oder existiert nicht
- Deployment erfolgreich aber keine Keys

**Fix:**
```bash
# 1. GitHub User hat Public Keys?
curl https://github.com/max-github.keys

# Sollte Keys zeigen
# Wenn leer: User hat keine Public Keys auf GitHub!

# 2. Keys auf GitHub hinzufügen
# GitHub → Settings → SSH and GPG keys → New SSH key

# 3. Extension Attribute korrekt?
# PowerShell:
Get-AzureADUser -ObjectId "max.mustermann@babsy.chh" |
    Select ExtensionAttribute1

# Sollte GitHub Username zeigen

# 4. user-mapping.json prüfen
cat config/user-mapping.json | jq '.users[] | {github_user, local_user}'

# github_user sollte dem GitHub Username entsprechen

# 5. Erneut deployen
gh workflow run deploy-users.yml -f dry_run=false
```

---

## ⚙️ Workflow Issues

### Workflow wird nicht getriggert

**Symptome:**
- M365 Sync läuft nicht stündlich
- Deployment wird nicht automatisch ausgeführt
- Workflows erscheinen nicht in Actions Tab

**Fix:**
```bash
# 1. Workflows enabled?
Repository → Settings → Actions → General
# "Allow all actions and reusable workflows" sollte gewählt sein

# 2. Workflow files committed?
git ls-files .github/workflows/
# Sollte zeigen:
# .github/workflows/m365-sync.yml
# .github/workflows/deploy-users.yml

# 3. YAML Syntax korrekt?
# GitHub Actions Tab prüfen auf Fehler

# 4. Manuell triggern zum Testen
gh workflow run m365-sync.yml
gh workflow run deploy-users.yml
```

### Automatic Issues werden nicht erstellt

**Symptome:**
- Workflow schlägt fehl aber kein Issue
- Fehler nicht sichtbar

**Fix:**
```bash
# 1. Permissions prüfen
# .github/workflows/*.yml
# jobs → steps → uses: actions/github-script@v7
# Diese Action braucht GITHUB_TOKEN mit Issues-Permission

# 2. Issue manually erstellen zum Testen
gh issue create --title "Test" --body "Test issue"

# 3. Workflow Logs prüfen
gh run view --workflow=m365-sync.yml --log | grep -i "issue"
```

---

## 🗂️ Common Quick Fixes

### M365 Sync komplett neu aufsetzen

```bash
# 1. Secrets löschen und neu erstellen
Repository → Settings → Secrets → Delete old ones

# 2. Azure AD App neu erstellen
Azure Portal → App registrations → New

# 3. Secrets neu setzen
# Siehe: Production Deployment Guide Step 3

# 4. M365 Sync triggern
gh workflow run m365-sync.yml
```

### Ansible Deployment zurücksetzen

```bash
# 1. Alte User-Mapping löschen (nur lokal)
rm config/user-mapping.json

# 2. M365 Sync neu laufen lassen
gh workflow run m365-sync.yml

# 3. Deployment neu
gh workflow run deploy-users.yml -f dry_run=true
# Wenn OK:
gh workflow run deploy-users.yml -f dry_run=false
```

### SSH Keys komplett neu deployen

```bash
# 1. Neue Keys generieren
ssh-keygen -t ed25519 -f ~/.ssh/new_ansible_key

# 2. Auf alle Hosts deployen
for host in $(cat ansible/inventory/hosts.yml | grep ansible_host | awk '{print $1}'); do
    ssh-copy-id -i ~/.ssh/new_ansible_key.pub root@$host
done

# 3. GitHub Secret aktualisieren
cat ~/.ssh/new_ansible_key | gh secret set ANSIBLE_SSH_PRIVATE_KEY

# 4. Deployment testen
gh workflow run deploy-users.yml -f dry_run=true
```

---

## 📞 Weitere Hilfe

### Logs sammeln für Support

```bash
# M365 Sync Logs
gh run view --workflow=m365-sync.yml --log > m365-sync.log

# Deployment Logs
gh run view --workflow=deploy-users.yml --log > deploy-users.log

# Host Logs (auf Host)
ssh root@host1.babsy.local
sudo tar czf /tmp/logs.tar.gz \
    /var/log/ssh-user-management/ \
    /var/log/auth.log \
    /var/log/syslog
scp root@host1.babsy.local:/tmp/logs.tar.gz ./

# Issue erstellen mit Logs
gh issue create --title "Deployment Error" \
    --body "See attached logs" \
    --label "bug,automation"
```

### Support kontaktieren

1. [GitHub Issues](https://github.com/BabsyIT/Babsy-SSH-Key-Managment/issues) durchsuchen
2. Neues Issue mit Details erstellen:
   - Fehlermeldung (komplett)
   - Workflow Logs
   - Was wurde bereits versucht
   - Environment (Debian Version, etc.)
3. [Discussions](https://github.com/BabsyIT/Babsy-SSH-Key-Managment/discussions) für Fragen

---

**Siehe auch:**
- [Production Deployment](Production-Deployment)
- [Monitoring & Logging](Monitoring-Logging)
- [Security Best Practices](Security-Best-Practices)
