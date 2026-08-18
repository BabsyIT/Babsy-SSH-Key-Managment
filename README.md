# SSH Key Management

Zentrale Benutzer- und Schlüsselverwaltung für alle Babsy-Server: Konten
anlegen, SSH-Keys von GitHub importieren, Sudo-Rechte setzen — und beim
Austritt überall wieder entfernen. Der Entzug ist der eigentliche Zweck.

## Wie es funktioniert

Gepflegt wird alles im **Management Cockpit**, nicht in diesem Repository.

```
Cockpit (Admin → SSH-Keys / SSH-Hosts)
   │   Personen kommen aus Entra ID, GitHub-Konto und Sudo-Stufe je Person
   │
   ├─→ GET /api/ssh/inventory      ─┐  primär: direkt abgefragt
   ├─→ GET /api/ssh/user-mapping   ─┤
   │                                │
   └─→ Secrets ANSIBLE_INVENTORY /  ┘  Rückfallebene, vom Cockpit geschrieben
       USER_MAPPING_JSON
                    │
                    ↓
     GitHub Actions „Deploy Users to Hosts"
                    │
                    ↓
     Ansible-Rolle ssh_user_management (je Host)
       • Konto, Gruppen, Shell
       • Keys von github.com/<user>.keys
       • /etc/sudoers.d/<user>
       • sshd-Härtung
```

Beide Wege stammen aus derselben Datenbank; die Secrets sind ein Abbild, das
das Cockpit bei jeder Änderung neu schreibt. Sie können nicht inhaltlich
auseinanderlaufen, nur im Alter — deshalb wird zuerst das Cockpit gefragt.

## Etwas ändern

| Ziel | Wo |
|---|---|
| Person hinzufügen/entfernen, Sudo-Stufe ändern | Cockpit → Admin → SSH-Keys |
| Server hinzufügen/entfernen | Cockpit → Admin → SSH-Hosts |
| Eigenen GitHub-Benutzernamen ändern | Cockpit → Einstellungen → Server-Zugang |
| Ausrollen | Cockpit stösst den Workflow an, oder hier „Run workflow" |

**Nicht** in diesem Repository bearbeitet werden: `ansible/inventory/hosts.yml`
(wird zur Laufzeit erzeugt) und `config/user-mapping.json` (dito). Beide sind
git-ignoriert.

## Manuell ausrollen

Actions → **Deploy Users to Hosts** → *Run workflow*:

- `target_environment`: `all`, `production`, `staging` oder `development`
- `dry_run`: `true` zeigt nur an, was sich ändern würde — ohne etwas zu tun

Ein Probelauf ist der richtige erste Schritt, wenn länger nicht ausgerollt
wurde: Er zeigt die Differenz zwischen Soll und Ist, bevor sie angewandt wird.

## Neuen Host aufnehmen

1. Cockpit → Admin → Infrastruktur zeigt alle Server aus der Hetzner-API und
   markiert die, die hier noch nicht verwaltet werden. „Übernehmen" trägt sie
   in die Hostliste ein.
2. Auf dem Host muss der Benutzer `ansible` samt Deploy-Key bestehen. Bei einem
   neuen Server erledigt das die Cloud-Config aus dem Cockpit; bei einem
   bestehenden `scripts/setup-host.sh`.
3. Workflow laufen lassen.

## Erforderliche Secrets

| Secret | Zweck |
|---|---|
| `ANSIBLE_SSH_PRIVATE_KEY` | Privater Schlüssel des `ansible`-Benutzers |
| `SSH_API_TOKEN` | Zugriff auf `/api/ssh/*` im Cockpit |
| `ANSIBLE_INVENTORY` | Rückfall-Inventar (schreibt das Cockpit) |
| `USER_MAPPING_JSON` | Rückfall-Benutzerliste (schreibt das Cockpit) |

Variable `COCKPIT_URL` setzen, falls das Cockpit nicht unter
`https://cockpit.test.babsy.ch` erreichbar ist.

## Was hier nicht mehr steht

Bis August 2026 enthielt dieses Repository zwei ältere Generationen: einen
M365-Sync, der Benutzer selbst aus Entra holte und in eine Datei im Repo
schrieb, sowie einen Satz lokaler Skripte mit systemd-Timern. Beide waren
stillgelegt, wurden aber weiterhin als Hauptweg dokumentiert — der M365-Sync
hätte seine Ergebnisse beim nächsten Deploy sogar stillschweigend überschrieben
bekommen. Sie sind entfernt; die Historie bleibt in Git erhalten.

Die Personen kommen weiterhin aus Entra ID — nur eben über das Cockpit, das
diese Synchronisation ohnehin betreibt.
