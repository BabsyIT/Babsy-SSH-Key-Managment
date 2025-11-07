# 🔒 Security Policy

## ⚠️ IMPORTANT: This Repository is PUBLIC

**NEVER commit secrets or credentials to this repository!**

## ❌ What NOT to Commit

### Forbidden Files (Already in .gitignore)
- `config/m365-config.json` - M365 credentials
- `*.env` files - Environment files with secrets
- `*.key`, `*.pem` - Private keys
- Any file containing passwords, tokens, or secrets

### How Secrets Are Handled

✅ **Correct:** Use GitHub Secrets
```yaml
# In GitHub Actions Workflow
env:
  M365_CLIENT_SECRET: ${{ secrets.M365_CLIENT_SECRET }}
```

❌ **WRONG:** Commit secrets to repository
```json
{
  "client_secret": "abc123..."  # NEVER DO THIS!
}
```

## ✅ Secure Configuration

### GitHub Secrets (Production)

All sensitive data is stored in **GitHub Secrets** (Repository → Settings → Secrets):

**Required Secrets:**
- `M365_TENANT_ID` - Microsoft 365 Tenant ID
- `M365_CLIENT_ID` - Azure AD App Client ID
- `M365_CLIENT_SECRET` - Azure AD App Client Secret ⚠️
- `M365_IT_GROUP_NAME` - IT-Team group name
- `M365_GITHUB_USERNAME_FIELD` - Extension attribute field
- `ANSIBLE_SSH_PRIVATE_KEY` - SSH private key for Ansible ⚠️
- `ANSIBLE_TARGET_HOSTS` - Target hosts list

**These secrets are:**
- ✅ Never visible in repository
- ✅ Only accessible by GitHub Actions
- ✅ Encrypted at rest
- ✅ Not visible in logs (masked automatically)

### Example Files

Example files (`*.example`) are safe to commit:
- ✅ `config/examples/m365-config.json.example` - Template only
- ✅ `config/examples/user-mapping.json.example` - Template only

**But NEVER commit actual config files:**
- ❌ `config/m365-config.json` - Contains real secrets
- ❌ `/etc/ssh-key-manager/m365-config.json` - Contains real secrets

## 🚨 If Secrets Are Accidentally Committed

### Immediate Actions:

1. **Rotate ALL compromised secrets immediately**
   ```bash
   # Azure AD App Secret
   Azure Portal → App registrations → Certificates & secrets → New secret

   # Update GitHub Secret
   Repository → Settings → Secrets → Update M365_CLIENT_SECRET

   # SSH Keys
   ssh-keygen -t ed25519 -f ~/.ssh/new_key
   # Deploy to hosts and update ANSIBLE_SSH_PRIVATE_KEY
   ```

2. **Remove secret from Git history**
   ```bash
   # Use BFG Repo-Cleaner or git-filter-branch
   # See: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository
   ```

3. **Notify team and audit access logs**
   ```bash
   # Check Azure AD sign-in logs
   # Check GitHub Actions logs
   # Monitor for unauthorized access
   ```

## 🔐 Best Practices

### Secret Management

1. **Use GitHub Secrets for CI/CD**
   - All production secrets in GitHub Secrets
   - Never in code or config files
   - Use environment variables in workflows

2. **Rotate Secrets Regularly**
   - Client Secrets: Every 6-12 months
   - SSH Keys: Annually
   - Document rotation dates

3. **Least Privilege Principle**
   - Only grant necessary API permissions
   - Separate secrets for dev/staging/prod
   - Different service accounts per environment

4. **Audit Trail**
   - All GitHub Actions runs are logged
   - Azure AD tracks API access
   - Regular security audits

### Development & Testing

**For local development:**
```bash
# Create .env file (git-ignored)
cat > .env <<EOF
M365_TENANT_ID=your-test-tenant
M365_CLIENT_ID=your-test-client-id
M365_CLIENT_SECRET=your-test-secret
EOF

# Load environment variables
export $(cat .env | xargs)

# Run tests
python3 scripts/m365-user-sync.py
```

**NEVER commit `.env` files!**

### SSH Key Security

```bash
# Generate secure SSH key
ssh-keygen -t ed25519 -C "ansible@$(date +%Y)" -f ~/.ssh/ansible_key

# Secure permissions
chmod 600 ~/.ssh/ansible_key
chmod 644 ~/.ssh/ansible_key.pub

# Store private key in GitHub Secret
cat ~/.ssh/ansible_key | gh secret set ANSIBLE_SSH_PRIVATE_KEY

# Deploy public key to hosts
ssh-copy-id -i ~/.ssh/ansible_key.pub root@host
```

## 📋 Security Checklist

### Before Committing:

- [ ] No secrets in code or config files
- [ ] No `.env` files included
- [ ] No private keys (`.key`, `.pem`)
- [ ] No credentials files
- [ ] Check with `git diff` before `git push`
- [ ] All sensitive data in GitHub Secrets

### Regular Audits:

- [ ] Review GitHub Secrets monthly
- [ ] Check Azure AD sign-in logs
- [ ] Rotate client secrets every 6 months
- [ ] Update SSH keys annually
- [ ] Review GitHub Actions logs for anomalies

## 🚨 Reporting Security Issues

If you discover a security vulnerability:

1. **DO NOT** create a public issue
2. **DO NOT** commit fixes to public branches
3. **DO** email security contact directly
4. **DO** follow responsible disclosure

## 📚 Resources

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Azure AD Security Best Practices](https://docs.microsoft.com/en-us/azure/active-directory/develop/security-best-practices-for-app-registration)
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

---

**Remember: This repository is PUBLIC. NEVER commit secrets!**

Use GitHub Secrets for all sensitive data. ✅
