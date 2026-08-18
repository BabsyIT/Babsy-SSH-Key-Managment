# Einrichtung

Diese Anleitung deckt die einmalige Einrichtung ab. Der laufende Betrieb —
Personen und Server pflegen, ausrollen — steht in der [README](README.md).

## 1. Secrets im Repository

Settings → Secrets and variables → Actions:

| Secret | Inhalt | Woher |
|---|---|---|
| `ANSIBLE_SSH_PRIVATE_KEY` | Privater Schlüssel des `ansible`-Benutzers | Beim Aufsetzen erzeugt, siehe unten |
| `SSH_API_TOKEN` | Token für `/api/ssh/*` | Identisch mit `SSH_API_TOKEN` in der `.env` des Cockpits |
| `ANSIBLE_INVENTORY` | Rückfall-Inventar | Schreibt das Cockpit automatisch |
| `USER_MAPPING_JSON` | Rückfall-Benutzerliste | Schreibt das Cockpit automatisch |

Dazu die Variable (nicht Secret) `COCKPIT_URL`, falls das Cockpit nicht unter
`https://cockpit.test.babsy.ch` läuft.

Die beiden Rückfall-Secrets muss niemand von Hand pflegen: Das Cockpit schreibt
sie bei jeder Änderung an Hosts oder Benutzern neu. Nötig ist dafür ein
GitHub-Token mit `repo`-Rechten in den Cockpit-Einstellungen.

## 2. Deploy-Schlüsselpaar

```bash
ssh-keygen -t ed25519 -C "ansible@babsy" -f ~/.ssh/babsy_ansible_key
```

- **Privaten** Teil (`babsy_ansible_key`) als Secret `ANSIBLE_SSH_PRIVATE_KEY`
  hinterlegen — vollständig, inklusive der BEGIN/END-Zeilen.
- **Öffentlichen** Teil (`babsy_ansible_key.pub`) braucht jeder Host im
  `authorized_keys` des Benutzers `ansible`. Bei neuen Servern erledigt das die
  Cloud-Config aus dem Cockpit; bei bestehenden `scripts/setup-host.sh`.

Der öffentliche Teil gehört zusätzlich als SSH-Key ins Hetzner-Projekt, damit
neu erstellte Server ihn direkt mitbekommen.

## 3. Host vorbereiten

Auf jedem Server, der noch nicht verwaltet wird:

```bash
sudo ./scripts/setup-host.sh
```

Das Skript legt den Benutzer `ansible` an, hinterlegt den Deploy-Schlüssel und
richtet passwortloses Sudo für ihn ein — mehr nicht. Alles Weitere macht der
Ansible-Lauf.

## 4. Host im Cockpit eintragen

Cockpit → Admin → Infrastruktur listet alle Server aus der Hetzner-API und
markiert die, die hier noch nicht verwaltet sind. „Übernehmen" trägt sie in die
Hostliste ein und schreibt das Inventar neu.

## 5. Erster Lauf

Actions → *Deploy Users to Hosts* → *Run workflow*, zuerst mit
`dry_run: true`. Die Ausgabe zeigt, was sich ändern würde. Sieht das plausibel
aus, denselben Lauf ohne Dry-Run wiederholen.

---

## Zwei authorized_keys-Dateien

Die Rolle schreibt importierte Schlüssel nach `~/.ssh/authorized_keys_github`
und lässt `~/.ssh/authorized_keys` unberührt. Damit bleiben manuell
hinterlegte Schlüssel als Notzugang erhalten, wenn GitHub nicht erreichbar ist
oder ein Import fehlschlägt. Details in
[SEPARATE-AUTHORIZED-KEYS.md](SEPARATE-AUTHORIZED-KEYS.md).

## Fehlersuche

**Workflow läuft nicht mehr von selbst.** GitHub deaktiviert geplante
Workflows nach 60 Tagen ohne Repository-Aktivität — genau das ist zwischen
April und August 2026 passiert. Actions → Workflow auswählen → *Enable*.

**„Cockpit nicht erreichbar — aus Secret".** Der Lauf funktioniert trotzdem,
arbeitet aber mit dem zuletzt gespiegelten Stand. Prüfen: Ist `SSH_API_TOKEN`
gesetzt und identisch mit dem Wert in der `.env` des Cockpits? Antwortet
`GET /api/ssh/inventory` mit dem Token?

**Ansible kommt nicht auf einen Host.** Fast immer fehlt dort der Benutzer
`ansible` oder der Deploy-Schlüssel — Schritt 3 nachholen. Prüfen mit:

```bash
ansible -i inventory/hosts.yml debian_hosts -m ping
```

**Ein Benutzer entsteht ohne Zugang.** Dann liefert GitHub für sein Konto keine
öffentlichen Schlüssel. Sichtbar im Cockpit unter Einstellungen →
Server-Zugang, das genau davor warnt.
