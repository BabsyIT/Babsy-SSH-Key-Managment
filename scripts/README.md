# ⚠️ Scripts Directory - Reference Only

Diese Scripts sind **NICHT für Production** gedacht. Sie dienen nur als Referenz und für lokale Tests.

## 🚨 Production Deployment

**Verwenden Sie für Production:**
- ✅ **GitHub Actions + Ansible** (siehe [PRODUCTION-DEPLOYMENT.md](../PRODUCTION-DEPLOYMENT.md))

**NICHT verwenden:**
- ❌ Diese lokalen Scripts für Production

## 📁 Inhalt (Reference Only)

- `m365-user-sync.py` - M365 User Synchronisation (Referenz)
- `m365-sync-wrapper.sh` - Wrapper für M365 Sync (Referenz)
- `github-ssh-user-manager.sh` - User Management Script (Referenz)
- `github-ssh-key-manager.sh` - SSH Key Management Script (Referenz)

## 🧪 Verwendungszweck

Diese Scripts können verwendet werden für:
- 📚 **Lernzwecke** - Verstehen wie M365 Integration funktioniert
- 🧪 **Lokale Tests** - Testen von M365 Verbindungen
- 🔧 **Debugging** - Troubleshooting bei Problemen
- 📝 **Referenz** - Beispielimplementierung

## ❌ Warum NICHT für Production?

| Faktor | Lokale Scripts | GitHub Actions + Ansible |
|--------|---------------|-------------------------|
| **Hochverfügbarkeit** | ❌ Host-abhängig | ✅ 99.9% (GitHub) |
| **Zentrale Verwaltung** | ❌ Auf jedem Host einzeln | ✅ Zentral orchestriert |
| **Fehlerbehandlung** | ❌ Logs nur lokal | ✅ Auto-Issues in GitHub |
| **Audit Trail** | ❌ Schwer nachvollziehbar | ✅ Komplette Historie |
| **Rollback** | ❌ Manuell | ✅ Git-basiert |
| **Skalierung** | ❌ Manuell auf jedem Host | ✅ Automatisch auf allen Hosts |

## 🚀 Production Setup

Für Production-Deployment siehe:
- **[PRODUCTION-DEPLOYMENT.md](../PRODUCTION-DEPLOYMENT.md)** - Komplette Setup-Anleitung
- **[GITHUB-ACTIONS-SETUP.md](../GITHUB-ACTIONS-SETUP.md)** - GitHub Actions Details
- **[ansible/README.md](../ansible/README.md)** - Ansible Dokumentation

---

**⚠️ Warnung:** Diese Scripts sollten NICHT in Production-Umgebungen verwendet werden!
