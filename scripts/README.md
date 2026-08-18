# Scripts

## `setup-host.sh`

Richtet auf einem bestehenden Server den Benutzer `ansible` samt Deploy-Key
ein, damit die Automatik ihn übernehmen kann. Einmal pro Host nötig — und nur
dort, wo die Maschine nicht ohnehin mit einer Cloud-Config aus dem Cockpit
erstellt wurde.

```bash
sudo ./setup-host.sh
```

## `populate-wiki.sh`

Befüllt das Wiki mit der Dokumentation dieses Repositories. Unabhängig vom
Ausrollen.

---

Die früheren Skripte für M365-Sync und lokale Benutzerverwaltung wurden im
August 2026 entfernt: Sie waren als „Reference Only" markiert, wurden von
nichts mehr aufgerufen und beschrieben einen Ablauf, den es nicht mehr gibt.
Benutzer und Hosts werden im Management Cockpit gepflegt, das Ausrollen
übernimmt `.github/workflows/deploy-users.yml` mit Ansible. Die alten Stände
bleiben in der Git-Historie.
