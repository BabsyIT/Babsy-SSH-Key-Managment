# Ansible SSH User Management

Ansible Playbooks und Roles für automatisiertes User-Management auf Debian/Ubuntu Hosts.

## 📁 Struktur

```
ansible/
├── ansible.cfg              # Ansible Konfiguration
├── inventory/
│   └── hosts.yml           # Inventory-Definition (Hosts & Gruppen)
├── group_vars/
│   └── all.yml             # Globale Variablen
├── playbooks/
│   └── deploy-users.yml    # Main Deployment Playbook
└── roles/
    └── ssh_user_management/
        ├── defaults/       # Default-Variablen
        ├── tasks/          # Task-Definitionen
        ├── templates/      # Jinja2 Templates (sudoers)
        ├── handlers/       # Event Handlers
        └── vars/           # Role-Variablen
```

## 🚀 Verwendung

### Via GitHub Actions (Empfohlen)

```bash
# Automatisch via Workflow
# Wird getriggert bei user-mapping.json Änderungen
```

### Manuell (Lokal)

```bash
# Alle Hosts
cd ansible
ansible-playbook -i inventory/hosts.yml playbooks/deploy-users.yml

# Specific Environment
ansible-playbook -i inventory/hosts.yml --limit production playbooks/deploy-users.yml

# Dry Run (Check Mode)
ansible-playbook -i inventory/hosts.yml --check playbooks/deploy-users.yml

# Verbose Output
ansible-playbook -i inventory/hosts.yml -vvv playbooks/deploy-users.yml
```

## ⚙️ Konfiguration

### Inventory anpassen

Editiere `inventory/hosts.yml`:

```yaml
all:
  children:
    debian_hosts:
      hosts:
        host1.example.com:
          ansible_host: 10.0.1.10
          ansible_user: root
          ansible_ssh_private_key_file: ~/.ssh/deploy_key

        host2.example.com:
          ansible_host: 10.0.1.11
          ansible_user: root
```

### Globale Variablen

Editiere `group_vars/all.yml`:

```yaml
default_shell: /bin/bash
default_group: users
user_home_base: /home
log_directory: /var/log/ssh-user-management
backup_enabled: true
```

## 🧪 Testing

### Connectivity Test

```bash
# Ping alle Hosts
ansible -i inventory/hosts.yml debian_hosts -m ping

# Check Ansible Facts
ansible -i inventory/hosts.yml debian_hosts -m setup
```

### Playbook Syntax Check

```bash
ansible-playbook --syntax-check playbooks/deploy-users.yml
```

### Lint Check

```bash
ansible-lint playbooks/deploy-users.yml
```

## 📦 Role: ssh_user_management

### Tasks

- **main.yml** - Entry Point, orchestriert alle Tasks
- **manage_user.yml** - User-Erstellung und -Verwaltung
- **import_github_keys.yml** - SSH Key Import von GitHub
- **configure_sudo.yml** - Sudo-Rechte konfigurieren

### Templates

- **sudoers_full.j2** - Full sudo access (NOPASSWD: ALL)
- **sudoers_limited.j2** - Limited sudo (nur spezifische Commands)

### Variables

```yaml
# Defaults (roles/ssh_user_management/defaults/main.yml)
user_mapping_file: "{{ playbook_dir }}/../../config/user-mapping.json"
default_shell: /bin/bash
github_keys_base_url: "https://github.com"
enable_logging: true
```

## 🔧 Anpassungen

### Eigene Tasks hinzufügen

```yaml
# roles/ssh_user_management/tasks/main.yml
- name: Custom task
  include_tasks: custom_task.yml
```

### Eigene Templates

```jinja2
# roles/ssh_user_management/templates/custom.j2
{{ user_item.local_user }} custom configuration
```

## 📊 Logs & Backups

### Auf Ziel-Hosts

```bash
# Deployment Logs
/var/log/ssh-user-management/deployment.log
/var/log/ssh-user-management/ssh_keys.log
/var/log/ssh-user-management/sudo.log

# Backups
/var/backups/ssh-user-management/
├── authorized_keys_username_<timestamp>
└── sudoers_username_<timestamp>
```

## 🚨 Troubleshooting

### SSH Connection Failed

```bash
# Test SSH
ssh -i ~/.ssh/deploy_key root@host1.example.com

# Check SSH Key Permissions
chmod 600 ~/.ssh/deploy_key
ssh-add ~/.ssh/deploy_key
```

### Playbook Fails

```bash
# Verbose mode
ansible-playbook -i inventory/hosts.yml -vvv playbooks/deploy-users.yml

# Check einzelne Host
ansible -i inventory/hosts.yml host1.example.com -m ping

# Syntax check
ansible-playbook --syntax-check playbooks/deploy-users.yml
```

### Sudoers Validation Failed

```bash
# Check sudoers file syntax locally
visudo -c -f /etc/sudoers.d/username

# Template debugging
ansible-playbook -i inventory/hosts.yml playbooks/deploy-users.yml --check --diff
```

## 🔒 Best Practices

1. **Immer mit `--check` testen** vor Production-Deployment
2. **Keine Handarbeit in `~/.ssh/authorized_keys_github`** — die Datei wird bei jedem Lauf vollständig überschrieben; eigene Schlüssel gehören in `~/.ssh/authorized_keys`
3. **Verbose Logging** bei Problemen (`-vvv`)
4. **Inventory im Git** - Versionierung der Host-Konfiguration
5. **SSH Keys rotieren** - Regelmäßig neue Deploy-Keys

## 📚 Ansible Dokumentation

- [Ansible Docs](https://docs.ansible.com/)
- [Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html)
