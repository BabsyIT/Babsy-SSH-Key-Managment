# 🔒 Security Policy

## ⚠️ IMPORTANT: This Repository is PUBLIC

**NEVER commit secrets or credentials to this repository!**

## ❌ What NOT to Commit

### Forbidden Files (Already in .gitignore)
- `*.env` files - Environment files with secrets
- `*.key`, `*.pem` - Private keys
- Any file containing passwords, tokens, or secrets

### How Secrets Are Handled

✅ **Correct:** Use GitHub Secrets
```yaml
# In GitHub Actions Workflow
env:
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
   # SSH Deploy-Schlüssel erneuern
   ssh-keygen -t ed25519 -f ~/.ssh/new_key
   # Auf die Hosts ausrollen, dann ANSIBLE_SSH_PRIVATE_KEY aktualisieren

   # API-Token des Cockpits erneuern
   openssl rand -hex 32
   # In der .env des Cockpits und als Secret SSH_API_TOKEN eintragen
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
