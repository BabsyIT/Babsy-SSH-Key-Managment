# config/

## `user-mapping.json` — nicht im Repository

Die Datei enthält die Benutzer samt Sudo-Stufen und wird **zur Laufzeit
erzeugt**: Der Workflow holt sie vom Cockpit (`GET /api/ssh/user-mapping`) und
fällt auf das Secret `USER_MAPPING_JSON` zurück, falls das Cockpit gerade nicht
erreichbar ist. Sie ist git-ignoriert und darf es bleiben — sie enthält
Benutzernamen und Rechte.

Gepflegt werden die Daten im Cockpit unter **Admin → SSH-Keys**. Wer hier eine
Datei anlegt, ändert damit nichts am Ausrollen: Sie wird zu Beginn jedes Laufs
überschrieben.

Aufbau siehe [`examples/user-mapping.json.example`](examples/user-mapping.json.example).

```json
{
  "users": [
    {
      "github_user": "beispiel-user",
      "local_user": "beispiel",
      "full_name": "Beispiel Person",
      "sudo_access": "full",
      "groups": ["sudo", "docker"]
    }
  ],
  "config": {
    "default_shell": "/bin/bash",
    "default_group": "users",
    "user_home_base": "/home"
  }
}
```

`sudo_access` kennt `full` (passwortloses Sudo für alles), `limited`
(nur die unter `sudo_commands` genannten Befehle) und `none`.
