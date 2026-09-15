# GitHub Secrets Setup Guide

Diese Anleitung erklärt, wie Sie die erforderlichen GitHub Secrets für die M365 Integration und Ansible Deployment einrichten.

## 📋 Erforderliche Secrets

### Microsoft 365 Integration

| Secret Name | Beschreibung | Beispiel |
|------------|--------------|----------|
| `M365_TENANT_ID` | Microsoft 365 Tenant ID | `babsy.onmicrosoft.com` |
| `M365_CLIENT_ID` | Azure AD App Client ID | `12345678-1234-1234-1234-123456789abc` |
| `M365_CLIENT_SECRET` | Azure AD App Client Secret | `abc...xyz` |
| `M365_IT_GROUP_NAME` | Name der IT-Team Gruppe in M365 | `IT-Team` |
| `M365_GITHUB_USERNAME_FIELD` | Extension Attribute für GitHub Username | `extensionAttribute1` |

### Ansible Deployment

| Secret Name | Beschreibung | Beispiel |
|------------|--------------|----------|
| `ANSIBLE_SSH_PRIVATE_KEY` | SSH Private Key für Ansible | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `ANSIBLE_TARGET_HOSTS` | Komma-separierte Liste der Ziel-Hosts | `host1.example.com,host2.example.com` |

### Rückmeldung an das Management Cockpit

Nach jedem echten Lauf meldet der Workflow das `PLAY RECAP` je Host an
`POST /api/ssh/deploy-result`. Erst damit zeigt die Infrastrukturseite einen
Server als „Verwaltet“ — vorher steht er als „Ausstehend“, nach einem
Fehlschlag als „Fehlerhaft“. Fehlen die Secrets, läuft der Deploy trotzdem,
es erscheint nur eine Warnung.

| Secret Name | Beschreibung | Beispiel |
|------------|--------------|----------|
| `COCKPIT_API_URL` | Basis-URL des produktiven Cockpits | `https://cockpit.babsy.ch` |
| `COCKPIT_SSH_API_TOKEN` | Derselbe Wert wie `SSH_API_TOKEN` im produktiven Cockpit | — |
| `COCKPIT_API_URL_TEST` | Basis-URL des Test-Cockpits (für `target_environment=development`) | `https://cockpit.test.babsy.ch` |
| `COCKPIT_SSH_API_TOKEN_TEST` | `SSH_API_TOKEN` des Test-Cockpits | — |

## 🔧 Schritt-für-Schritt Anleitung

### 1. Azure AD App Registration erstellen

```bash
# Option A: Via Azure Portal
1. Gehe zu https://portal.azure.com
2. Azure Active Directory → App registrations → New registration
3. Name: "SSH-User-Management"
4. Supported account types: "Accounts in this organizational directory only"
5. Redirect URI: Leer lassen
6. Klicke "Register"

# Option B: Via Azure CLI
az ad app create --display-name "SSH-User-Management"
```

### 2. API Permissions konfigurieren

```bash
# Im Azure Portal:
1. App registrations → SSH-User-Management → API permissions
2. Add a permission → Microsoft Graph → Application permissions
3. Füge folgende Permissions hinzu:
   - User.Read.All
   - Group.Read.All
   - Directory.Read.All
4. Klicke "Grant admin consent" (wichtig!)

# Via Azure CLI:
az ad app permission add --id <APP_ID> --api 00000003-0000-0000-c000-000000000000 \
  --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Role  # User.Read.All

az ad app permission add --id <APP_ID> --api 00000003-0000-0000-c000-000000000000 \
  --api-permissions 5b567255-7703-4780-807c-7be8301ae99b=Role  # Group.Read.All
```

### 3. Client Secret erstellen

```bash
# Im Azure Portal:
1. App registrations → SSH-User-Management → Certificates & secrets
2. New client secret
3. Description: "GitHub Actions"
4. Expires: 24 months (oder länger)
5. Add
6. Kopiere den Secret Value SOFORT (wird nur einmal angezeigt!)

# Via Azure CLI:
az ad app credential reset --id <APP_ID> --years 2
```

### 4. Tenant ID und Client ID finden

```bash
# Im Azure Portal:
App registrations → SSH-User-Management → Overview
- Application (client) ID: Dies ist die CLIENT_ID
- Directory (tenant) ID: Dies ist die TENANT_ID

# Via Azure CLI:
az ad app show --id <APP_ID>
```

### 5. GitHub Secrets einrichten

```bash
# Im GitHub Repository:
1. Gehe zu Settings → Secrets and variables → Actions
2. Klicke "New repository secret"
3. Füge alle Secrets einzeln hinzu:

   Name: M365_TENANT_ID
   Value: <deine-tenant-id>

   Name: M365_CLIENT_ID
   Value: <deine-client-id>

   Name: M365_CLIENT_SECRET
   Value: <dein-client-secret>

   Name: M365_IT_GROUP_NAME
   Value: IT-Team

   Name: M365_GITHUB_USERNAME_FIELD
   Value: extensionAttribute1
```

### 6. SSH Key für Ansible erstellen

```bash
# SSH Key generieren
ssh-keygen -t ed25519 -C "ansible-deploy@github-actions" -f ~/.ssh/ansible_deploy_key -N ""

# Public Key auf Ziel-Hosts verteilen
ssh-copy-id -i ~/.ssh/ansible_deploy_key.pub root@host1.example.com
ssh-copy-id -i ~/.ssh/ansible_deploy_key.pub root@host2.example.com

# Private Key als GitHub Secret speichern
cat ~/.ssh/ansible_deploy_key
# Kopiere den kompletten Inhalt (inkl. BEGIN/END Zeilen)

# Im GitHub Repository:
Name: ANSIBLE_SSH_PRIVATE_KEY
Value: <private-key-inhalt>

Name: ANSIBLE_TARGET_HOSTS
Value: host1.example.com,host2.example.com
```

## 🔒 Sicherheits-Best-Practices

### Secret Rotation

```bash
# Client Secret alle 6-12 Monate rotieren
az ad app credential reset --id <APP_ID> --years 1

# SSH Keys regelmäßig neu generieren
ssh-keygen -t ed25519 -C "ansible-deploy-$(date +%Y%m%d)" -f ~/.ssh/ansible_deploy_key
```

### Least Privilege Prinzip

- Verwende nur die minimal notwendigen Permissions
- Erstelle separate Service Accounts für verschiedene Aufgaben
- Nutze Environment-spezifische Secrets für Production/Staging

### Audit Logging

```bash
# Azure AD Sign-in Logs überwachen
az monitor activity-log list --resource-group <RG> --start-time 2024-01-01

# GitHub Actions Logs regelmäßig überprüfen
Settings → Actions → Workflow runs
```

## 🧪 Secrets testen

### M365 Connection Test

```bash
# PowerShell Test
$TenantId = "your-tenant-id"
$ClientId = "your-client-id"
$ClientSecret = "your-client-secret"

$Body = @{
    grant_type    = "client_credentials"
    client_id     = $ClientId
    client_secret = $ClientSecret
    scope         = "https://graph.microsoft.com/.default"
}

$Response = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $Body
$Response.access_token
```

### Ansible SSH Test

```bash
# SSH Connection Test
ssh -i ~/.ssh/ansible_deploy_key root@host1.example.com "hostname && whoami"

# Ansible Ping Test
cd ansible
ansible -i inventory/hosts.yml debian_hosts -m ping
```

## ❓ Troubleshooting

### "Insufficient privileges" Error

```bash
# Lösung: Admin Consent erneut erteilen
Azure Portal → App registrations → API permissions → Grant admin consent
```

### "Permission denied (publickey)" Error

```bash
# Lösung: SSH Key Permissions prüfen
chmod 600 ~/.ssh/ansible_deploy_key
ssh-add ~/.ssh/ansible_deploy_key

# Authorized Keys auf Ziel-Host prüfen
ssh root@host1 "cat ~/.ssh/authorized_keys"
```

### Secret wird nicht erkannt

```bash
# Secrets sind erst nach einem Push verfügbar
# Warte 5-10 Sekunden nach dem Speichern
# Triggere Workflow manuell: Actions → Workflow → Run workflow
```

## 📚 Weitere Ressourcen

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Microsoft Graph API Permissions](https://docs.microsoft.com/en-us/graph/permissions-reference)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
