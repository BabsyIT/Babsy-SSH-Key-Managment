# Separate authorized_keys Files

## 🎯 Konzept: Trennung von manuellen und automatisch verwalteten Keys

Das System verwendet **zwei separate authorized_keys Dateien**:

```
~/.ssh/authorized_keys         # Manuelle Keys (bleiben unberührt)
~/.ssh/authorized_keys_github  # Von GitHub importiert (automatisch verwaltet)
```

## ✅ Vorteile

### Sicherheit
- ✅ **Manuelle Keys bleiben erhalten** - Werden nie überschrieben
- ✅ **Fallback-Zugang** - Falls GitHub down ist, funktionieren manuelle Keys
- ✅ **Klare Trennung** - Sofort erkennbar welche Keys woher kommen
- ✅ **Audit Trail** - Separate Dateien = bessere Nachvollziehbarkeit

### Flexibilität
- ✅ **Emergency Access Keys** - Admin kann manuell Keys hinzufügen
- ✅ **Temporäre Keys** - Für Contractors/Support ohne M365-Integration
- ✅ **Backup Keys** - Falls M365 Sync fehlschlägt
- ✅ **Migration** - Bestehende Keys bleiben erhalten

## 🏗️ Implementierung

### SSH Daemon Konfiguration

**Option A: sshd_config.d (Debian 11+, Ubuntu 20.04+)**
```bash
# /etc/ssh/sshd_config.d/90-ssh-user-management.conf
AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys_github
```

**Option B: sshd_config (Ältere Systeme)**
```bash
# /etc/ssh/sshd_config
AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys_github
```

**Ansible macht das automatisch!** ✅

### Dateistruktur pro User

```
/home/username/
├── .ssh/
│   ├── authorized_keys          # Manuelle Keys (von Admin gepflegt)
│   │   # Manual SSH Keys - Add your keys below
│   │   # GitHub-managed keys are in: ~/.ssh/authorized_keys_github
│   │   ssh-rsa AAAA... admin-laptop
│   │   ssh-ed25519 AAAA... emergency-key
│   │
│   └── authorized_keys_github   # GitHub Keys (automatisch verwaltet)
│       # Automatically managed keys from GitHub
│       # User: username-github
│       # Last updated: 2024-11-07T10:30:00Z
│       # DO NOT manually edit this file
│       ssh-ed25519 AAAA... username@github
│       ssh-rsa AAAA... username@github
```

## 📋 Verwendung

### Als Admin: Manuelle Keys hinzufügen

```bash
# Manuellen Key hinzufügen (wird NICHT überschrieben)
ssh username@host

# Auf dem Host:
echo "ssh-ed25519 AAAA... my-laptop" >> ~/.ssh/authorized_keys

# ODER von außen:
ssh-copy-id -i ~/.ssh/my_key.pub username@host
```

**Diese Keys bleiben permanent!** ✅

### Als System: GitHub Keys automatisch verwalten

```bash
# Via GitHub Actions + Ansible (automatisch)
# Updates nur ~/.ssh/authorized_keys_github

# Via M365 Sync:
M365 IT-Team → GitHub Actions → Ansible → authorized_keys_github
```

**Diese Keys werden automatisch aktualisiert!** ✅

## 🔍 Verifizierung

### Prüfen welche Dateien verwendet werden

```bash
# SSH Konfiguration anzeigen
sudo sshd -T | grep authorizedkeysfile

# Output:
# authorizedkeysfile .ssh/authorized_keys .ssh/authorized_keys_github
```

### Prüfen welche Keys ein User hat

```bash
# Als Root auf dem Host
sudo su - username

# Manuelle Keys
cat ~/.ssh/authorized_keys

# GitHub Keys
cat ~/.ssh/authorized_keys_github

# Beide kombiniert
cat ~/.ssh/authorized_keys ~/.ssh/authorized_keys_github
```

### Test: Beide Key-Typen funktionieren

```bash
# Mit manuellem Key
ssh -i ~/.ssh/manual_key username@host

# Mit GitHub Key
ssh -i ~/.ssh/github_key username@host

# Beide sollten funktionieren! ✅
```

## 🛡️ Sicherheit

### Permissions

```bash
# Automatisch von Ansible gesetzt
~/.ssh/                         # 700 (drwx------)
~/.ssh/authorized_keys          # 600 (-rw-------)
~/.ssh/authorized_keys_github   # 600 (-rw-------)
```

### Best Practices

**Manuelle Keys (`authorized_keys`):**
- ✅ Für Emergency Access
- ✅ Für temporären Support
- ✅ Für Admin-Zugang ohne M365
- ✅ Als Fallback wenn GitHub down ist

**GitHub Keys (`authorized_keys_github`):**
- ✅ Automatisch von M365 synchronisiert
- ✅ Automatisch aktualisiert bei Änderungen
- ✅ User aus IT-Team in M365
- ❌ **NIE manuell bearbeiten** - wird überschrieben!

## 📊 Monitoring

### Log-Einträge

```bash
# Ansible Logs auf Host
tail -f /var/log/ssh-user-management/ssh_keys.log

# Beispiel-Output:
# 2024-11-07T10:30:00Z - Imported 2 keys for username from GitHub user username-github
# 2024-11-07T10:30:01Z - Preserved manual keys in authorized_keys
```

### GitHub Actions Logs

```bash
# Via GitHub Actions Summary
Actions → Deploy Users → Latest run
# Shows: "Updated SSH keys for 5 users"
```

## 🔧 Troubleshooting

### Problem: Manuelle Keys werden überschrieben

**Ursache:** Falsche Konfiguration - authorized_keys statt authorized_keys_github

**Lösung:**
```bash
# Prüfen SSH Config
sudo sshd -T | grep authorizedkeysfile

# Sollte sein:
# authorizedkeysfile .ssh/authorized_keys .ssh/authorized_keys_github

# Falls nicht, neu deployen:
gh workflow run deploy-users.yml
```

### Problem: Nur GitHub Keys funktionieren

**Ursache:** authorized_keys hat falsche Permissions

**Lösung:**
```bash
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

### Problem: Key-Änderungen in GitHub werden nicht übernommen

**Ursache:** M365 Sync oder Deployment fehlgeschlagen

**Lösung:**
```bash
# M365 Sync manuell triggern
gh workflow run m365-sync.yml

# Dann Deployment
gh workflow run deploy-users.yml

# Logs prüfen
gh run view --workflow=m365-sync.yml --log
```

## 🎯 Migration von existing Setup

### Schritt 1: Backup

```bash
# Auf jedem Host
sudo find /home -name "authorized_keys" -exec cp {} {}.backup-$(date +%Y%m%d) \;
```

### Schritt 2: Deploy

```bash
# Via GitHub Actions
gh workflow run deploy-users.yml

# Das System:
# 1. Erstellt authorized_keys_github mit GitHub Keys
# 2. Lässt authorized_keys unberührt (mit existing Keys)
# 3. Konfiguriert sshd für beide Dateien
```

### Schritt 3: Verify

```bash
# Auf Host prüfen
ssh username@host

# Test 1: GitHub Key
ssh -i ~/.ssh/github_key username@host

# Test 2: Manueller Key (falls vorhanden)
ssh -i ~/.ssh/manual_key username@host

# Beide sollten funktionieren! ✅
```

### Schritt 4: Cleanup (optional)

```bash
# Falls authorized_keys nur GitHub Keys enthielt:
# Diese können entfernt werden (sind jetzt in authorized_keys_github)

# Auf Host:
# Backup erstellen
cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.old

# Datei leeren (oder manuelle Keys behalten)
> ~/.ssh/authorized_keys

# Test
ssh username@host  # Sollte mit authorized_keys_github noch funktionieren
```

## 📚 Technical Details

### SSH Authentication Flow

```
1. SSH Client verbindet zu Host
2. sshd liest AuthorizedKeysFile Directive
3. sshd prüft BEIDE Dateien in Reihenfolge:
   a) ~/.ssh/authorized_keys (manuelle Keys)
   b) ~/.ssh/authorized_keys_github (GitHub Keys)
4. Wenn Key in EINER der Dateien matcht → Access granted ✅
```

### Ansible Implementation

```yaml
# tasks/import_github_keys.yml
- name: Write keys to authorized_keys_github
  copy:
    content: "{{ github_keys }}"
    dest: ~/.ssh/authorized_keys_github  # Separate Datei!

- name: Preserve authorized_keys
  file:
    path: ~/.ssh/authorized_keys
    state: touch
    modification_time: preserve  # Nicht überschreiben!

# tasks/configure_sshd.yml
- name: Configure dual authorized_keys files
  lineinfile:
    path: /etc/ssh/sshd_config
    line: 'AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys_github'
```

## ✅ Zusammenfassung

| Datei | Zweck | Verwaltet von | Überschrieben? |
|-------|-------|---------------|----------------|
| `authorized_keys` | Manuelle Keys | Admin | ❌ Nie |
| `authorized_keys_github` | GitHub Keys | Ansible | ✅ Bei jedem Deploy |

**Beide Dateien werden von SSH gelesen → Beide Key-Typen funktionieren!** ✅

---

**Siehe auch:**
- [PRODUCTION-DEPLOYMENT.md](PRODUCTION-DEPLOYMENT.md) - Production Setup
- [ansible/README.md](ansible/README.md) - Ansible Dokumentation
- [SECURITY.md](SECURITY.md) - Security Policy
