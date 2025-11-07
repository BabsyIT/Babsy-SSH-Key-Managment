# SSH Key Management System - Production Deployment Guide

🎯 **Production Approach:** GitHub Actions + Ansible (Centralized, High-Availability)

## 🏗️ Production Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                  Microsoft 365 Tenant (babsy.chh)                │
│                           IT-Team Group                          │
│                   (Extension Attributes = GitHub Username)       │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 │ Microsoft Graph API
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│              GitHub Actions: M365 User Sync (Hourly)             │
│                    .github/workflows/m365-sync.yml               │
│                                                                  │
│  • Authenticates with M365                                       │
│  • Fetches IT-Team members                                       │
│  • Extracts GitHub usernames                                     │
│  • Updates config/user-mapping.json                              │
│  • Commits to repository                                         │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 │ Git Push (triggers next workflow)
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│         GitHub Actions: Ansible Deployment (On Change)           │
│                .github/workflows/deploy-users.yml                │
│                                                                  │
│  • Reads user-mapping.json                                       │
│  • Sets up Ansible environment                                   │
│  • Connects to all hosts via SSH                                 │
│  • Runs ansible/playbooks/deploy-users.yml                       │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 │ SSH (Ansible)
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    All Debian/Ubuntu Hosts                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Host 1     │  │   Host 2     │  │   Host N     │          │
│  │              │  │              │  │              │          │
│  │ ✓ Users      │  │ ✓ Users      │  │ ✓ Users      │          │
│  │ ✓ SSH Keys   │  │ ✓ SSH Keys   │  │ ✓ SSH Keys   │          │
│  │ ✓ Sudo       │  │ ✓ Sudo       │  │ ✓ Sudo       │          │
│  │ ✓ Groups     │  │ ✓ Groups     │  │ ✓ Groups     │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Production Setup (30 Minutes)

### Prerequisites

- ✅ Microsoft 365 Tenant (babsy.chh) mit Admin-Zugriff
- ✅ GitHub Repository (dieses Repository)
- ✅ SSH-Zugriff zu allen Debian Hosts
- ✅ Azure AD App Registration Permissions

### Step 1: Azure AD App Registration (10 min)

```bash
# Via Azure Portal
1. https://portal.azure.com
2. Azure Active Directory → App registrations → New registration
3. Name: "SSH-User-Management-babsy"
4. Register

# Configure API Permissions
5. API permissions → Add permission → Microsoft Graph
6. Application permissions:
   - User.Read.All
   - Group.Read.All
   - Directory.Read.All
7. Grant admin consent ✓ (IMPORTANT!)

# Create Client Secret
8. Certificates & secrets → New client secret
9. Description: "GitHub Actions Production"
10. Expiration: 24 months
11. Copy secret value immediately (shown only once!)
```

### Step 2: M365 Extension Attributes Setup (5 min)

```powershell
# Connect to Azure AD
Connect-AzureAD

# Set GitHub usernames for each IT team member
$ITTeamUsers = @(
    @{UPN="max.mustermann@babsy.chh"; GitHub="max-github"},
    @{UPN="anna.mueller@babsy.chh"; GitHub="anna-github"},
    @{UPN="tom.schmidt@babsy.chh"; GitHub="tom-github"}
)

foreach ($user in $ITTeamUsers) {
    Set-AzureADUser -ObjectId $user.UPN -ExtensionAttribute1 $user.GitHub
    Write-Host "✓ Set GitHub username for $($user.UPN): $($user.GitHub)"
}

# Verify
Get-AzureADUser -ObjectId "max.mustermann@babsy.chh" |
    Select-Object UserPrincipalName, @{Name="GitHubUser";Expression={$_.ExtensionAttribute1}}
```

### Step 3: GitHub Secrets Configuration (5 min)

```bash
# Navigate to: Repository → Settings → Secrets and variables → Actions

# M365 Integration Secrets
Name: M365_TENANT_ID
Value: babsy.onmicrosoft.com (or your actual tenant ID)

Name: M365_CLIENT_ID
Value: <your-azure-app-client-id>

Name: M365_CLIENT_SECRET
Value: <your-azure-app-client-secret>

Name: M365_IT_GROUP_NAME
Value: IT-Team

Name: M365_GITHUB_USERNAME_FIELD
Value: extensionAttribute1

# Ansible Deployment Secrets
Name: ANSIBLE_SSH_PRIVATE_KEY
Value: <paste-your-ssh-private-key-here>

Name: ANSIBLE_TARGET_HOSTS
Value: host1.babsy.local,host2.babsy.local,host3.babsy.local
```

**Detailed guide:** [SETUP-GITHUB-SECRETS.md](SETUP-GITHUB-SECRETS.md)

### Step 4: SSH Key Setup for Ansible (5 min)

```bash
# Generate SSH key for Ansible
ssh-keygen -t ed25519 -C "ansible@github-actions-babsy" -f ~/.ssh/babsy_ansible_key -N ""

# Deploy public key to all target hosts
for host in host1.babsy.local host2.babsy.local host3.babsy.local; do
    ssh-copy-id -i ~/.ssh/babsy_ansible_key.pub root@$host
    echo "✓ Deployed SSH key to $host"
done

# Verify connectivity
for host in host1.babsy.local host2.babsy.local host3.babsy.local; do
    ssh -i ~/.ssh/babsy_ansible_key root@$host "hostname && echo 'SSH OK'"
done

# Copy private key to GitHub Secret
cat ~/.ssh/babsy_ansible_key
# → Copy entire content (including BEGIN/END lines) to GitHub Secret: ANSIBLE_SSH_PRIVATE_KEY
```

### Step 5: Ansible Inventory Configuration (5 min)

Edit `ansible/inventory/hosts.yml`:

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

Commit and push changes:

```bash
git add ansible/inventory/hosts.yml
git commit -m "Configure production Ansible inventory"
git push
```

## 🧪 Testing & Validation

### Test 1: M365 Sync

```bash
# Trigger M365 sync manually
gh workflow run m365-sync.yml

# Wait 1-2 minutes, then check status
gh run list --workflow=m365-sync.yml

# View logs
gh run view --workflow=m365-sync.yml --log

# Verify user-mapping.json was updated
git pull
cat config/user-mapping.json | jq '.users[] | {local_user, github_user}'
```

Expected output in `config/user-mapping.json`:
```json
{
  "users": [
    {
      "github_user": "max-github",
      "local_user": "maxmustermann",
      "full_name": "Max Mustermann",
      "sudo_access": "limited",
      "groups": ["users", "sudo", "docker", "adm"],
      "m365_upn": "max.mustermann@babsy.chh",
      "m365_sync": true
    }
  ]
}
```

### Test 2: Ansible Deployment (Dry Run)

```bash
# Test deployment without making changes
gh workflow run deploy-users.yml \
  -f target_environment=all \
  -f dry_run=true

# Check status
gh run list --workflow=deploy-users.yml

# View logs
gh run view --workflow=deploy-users.yml --log
```

### Test 3: Production Deployment

```bash
# Deploy to staging first
gh workflow run deploy-users.yml \
  -f target_environment=staging \
  -f dry_run=false

# Verify on staging host
ssh root@host3.babsy.local "id maxmustermann && sudo -l -U maxmustermann"

# If successful, deploy to production
gh workflow run deploy-users.yml \
  -f target_environment=production \
  -f dry_run=false

# Verify on production hosts
for host in host1.babsy.local host2.babsy.local; do
    echo "=== Checking $host ==="
    ssh root@$host "id maxmustermann && cat /home/maxmustermann/.ssh/authorized_keys | wc -l"
done
```

## 📊 Production Monitoring

### GitHub Actions Dashboard

```bash
# View all workflow runs
gh run list

# Watch latest M365 sync
gh run watch --workflow=m365-sync.yml

# Watch latest deployment
gh run watch --workflow=deploy-users.yml
```

### Automatic Issue Creation

Bei Fehlern werden automatisch Issues erstellt:
- 🚨 **M365 User Sync Failed** - M365 Synchronisationsfehler
- ⚠️ **Ansible User Deployment Failed** - Deployment-Fehler

```bash
# View open issues
gh issue list --label "automation"

# View specific issue
gh issue view <issue-number>
```

### Host-Level Verification

```bash
# Check logs on hosts (created by Ansible)
ssh root@host1.babsy.local "tail -f /var/log/ssh-user-management/deployment.log"
ssh root@host1.babsy.local "tail -f /var/log/ssh-user-management/ssh_keys.log"

# Verify users exist
ssh root@host1.babsy.local "getent passwd | grep -E 'maxmustermann|annamueller|tomschmidt'"

# Check SSH keys
ssh root@host1.babsy.local "ls -la /home/*/. ssh/authorized_keys"

# Verify sudo configuration
ssh root@host1.babsy.local "ls -la /etc/sudoers.d/"
```

## 🔄 Production Operation

### Automatic Workflows

| Workflow | Schedule | Trigger | Description |
|----------|----------|---------|-------------|
| M365 Sync | Hourly (at :00) | Schedule, Manual, Push | Syncs users from M365 IT-Team |
| Ansible Deploy | Daily (6:00 UTC) | user-mapping.json change, Schedule, Manual | Deploys users to all hosts |

### Manual Operations

```bash
# Force M365 sync
gh workflow run m365-sync.yml

# Deploy to specific environment
gh workflow run deploy-users.yml -f target_environment=production

# Dry run before deployment
gh workflow run deploy-users.yml -f dry_run=true

# View workflow status
gh run list

# Cancel running workflow
gh run cancel <run-id>

# Re-run failed workflow
gh run rerun <run-id>
```

## 🚨 Troubleshooting

### M365 Sync Fails

**Check:**
1. GitHub Secrets korrekt? `Settings → Secrets`
2. Azure AD Permissions? Admin Consent erteilt?
3. IT-Team Gruppe existiert in M365?
4. Extension Attributes gesetzt?

**Fix:**
```bash
# Test M365 connection manually (PowerShell)
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

Write-Host "Token acquired: $($Token.access_token.Substring(0,20))..."
```

### Ansible Deployment Fails

**Check:**
1. SSH Key valid? Test: `ssh -i ~/.ssh/babsy_ansible_key root@host1.babsy.local`
2. Hosts reachable? `ping host1.babsy.local`
3. Inventory correct? `cat ansible/inventory/hosts.yml`
4. user-mapping.json valid? `jq '.' config/user-mapping.json`

**Fix:**
```bash
# Test Ansible connectivity
cd ansible
ansible -i inventory/hosts.yml debian_hosts -m ping

# Test playbook syntax
ansible-playbook --syntax-check playbooks/deploy-users.yml

# Dry run locally
ansible-playbook -i inventory/hosts.yml --check playbooks/deploy-users.yml
```

## 🔒 Security Best Practices

### Secret Rotation

```bash
# Rotate M365 Client Secret (every 6-12 months)
Azure Portal → App registrations → Certificates & secrets → New secret
# Update GitHub Secret: M365_CLIENT_SECRET

# Rotate Ansible SSH Key (annually)
ssh-keygen -t ed25519 -C "ansible@$(date +%Y)" -f ~/.ssh/babsy_ansible_key_new
# Deploy to hosts
# Update GitHub Secret: ANSIBLE_SSH_PRIVATE_KEY
```

### Audit & Compliance

```bash
# Review workflow runs
gh run list --limit 100

# Export logs for audit
gh run view <run-id> --log > audit_log_$(date +%Y%m%d).txt

# Check who triggered workflows
gh api repos/:owner/:repo/actions/runs | jq '.workflow_runs[] | {id, actor: .actor.login, created_at}'
```

## 📚 Documentation

- **[GITHUB-ACTIONS-SETUP.md](GITHUB-ACTIONS-SETUP.md)** - Detailed setup guide with diagrams
- **[SETUP-GITHUB-SECRETS.md](SETUP-GITHUB-SECRETS.md)** - Complete secret configuration
- **[ansible/README.md](ansible/README.md)** - Ansible playbooks & roles documentation
- **[Readme.md](Readme.md)** - Project overview

## 📞 Support

**Issues:** [GitHub Issues](../../issues)
**Workflow Logs:** [GitHub Actions](../../actions)
**Documentation:** [Wiki](../../wiki)

---

## ⚠️ Important Notes

### ❌ DO NOT Use Local Scripts for Production

The `scripts/` directory contains reference implementations but **should NOT be used for production deployment**. Always use GitHub Actions + Ansible for production.

Local scripts are:
- ❌ Not centrally managed
- ❌ Require manual execution on each host
- ❌ No automatic error handling
- ❌ No audit trail
- ❌ Single point of failure

GitHub Actions + Ansible provides:
- ✅ 99.9% availability (GitHub)
- ✅ Central orchestration
- ✅ Automatic error handling with Issues
- ✅ Complete audit trail
- ✅ Git-based rollback
- ✅ Idempotent operations

---

**Production Setup Complete!** 🎉

Next: Monitor GitHub Actions for automatic M365 sync and deployment.
