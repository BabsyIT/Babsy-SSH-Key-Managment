#!/usr/bin/env bash
# Rollentest: legt Konten an, prüft einen zweiten Lauf ohne Änderung, eine
# Freigabe für einen anderen Host und den Entzug. Läuft auf einem frischen
# CI-Runner (Ubuntu oder macOS) mit passwortlosem sudo — nie auf echten Servern.
set -euo pipefail

cd "$(dirname "$0")/../../ansible"
MAPPING=../config/user-mapping.json
mkdir -p ../config
if [ "$(uname)" = Darwin ]; then
  HOME_BASIS=/Users
else
  HOME_BASIS=/home
  # Auf dem frischen Runner lief sshd nie; ohne dieses Verzeichnis scheitert
  # `sshd -t`. Ein Server mit laufendem sshd hat es immer.
  sudo mkdir -p /run/sshd
fi

lauf() {
  cp "../tests/rolle/$1" "$MAPPING"
  ANSIBLE_STDOUT_CALLBACK=default ansible-playbook -i ../tests/rolle/hosts.yml \
    -e user_mapping_file="$PWD/$MAPPING" playbooks/deploy-users.yml | tee "/tmp/lauf-$1.log"
}
changed() { grep -oE 'testhost +: ok=[0-9]+ +changed=[0-9]+' "/tmp/lauf-$1.log" | grep -oE '[0-9]+$'; }
fehler() { echo "::error::$*"; exit 1; }

echo "== Lauf 1: anlegen"
lauf mapping-1.json
id sshtest-a >/dev/null || fehler "sshtest-a wurde nicht angelegt"
id sshtest-b >/dev/null 2>&1 && fehler "sshtest-b ist nur für einen anderen Host freigegeben und darf hier nicht entstehen"
# Mit sudo: Das Home eines neuen Kontos ist für andere nicht lesbar.
sudo test -s "$HOME_BASIS/sshtest-a/.ssh/authorized_keys_github" || fehler "Schlüsseldatei fehlt"
sudo grep -q "ssh-" "$HOME_BASIS/sshtest-a/.ssh/authorized_keys_github" || fehler "keine Schlüssel von GitHub in der Datei"
sudo test -f /etc/sudoers.d/sshtest-a || fehler "sudoers-Datei fehlt"
# Nur die Datei der Rolle: `visudo -c` prüft alles, auch was der Runner mitbringt.
sudo visudo -cf /etc/sudoers.d/sshtest-a || fehler "sudoers-Datei der Rolle ungültig"
sudo visudo -c || echo "::warning::visudo -c meldet Probleme ausserhalb der Rolle (Runner)"
sudo grep -qx sshtest-a /var/lib/ssh-user-management/managed-users || fehler "nicht in managed-users"

echo "== Lauf 2: nichts ausser der Schlüsseldatei darf sich ändern"
lauf mapping-1.json
[ "$(changed mapping-1.json)" -le 1 ] || fehler "zweiter Lauf änderte $(changed mapping-1.json) Dinge, erwartet höchstens 1"
grep -q "RUNNING HANDLER" /tmp/lauf-mapping-1.json.log && fehler "zweiter Lauf hat einen Handler (sshd-Neustart) ausgelöst"

echo "== Lauf 3: sshtest-a fällt aus der Liste und wird entfernt"
lauf mapping-2.json
id sshtest-a >/dev/null 2>&1 && fehler "sshtest-a wurde nicht gelöscht"
sudo test -f /etc/sudoers.d/sshtest-a && fehler "sudoers-Datei von sshtest-a blieb stehen"
sudo test -d "$HOME_BASIS/sshtest-a" && fehler "Home von sshtest-a blieb stehen"
id sshtest-c >/dev/null || fehler "sshtest-c wurde nicht angelegt"

echo "✓ Rollentest bestanden ($(uname))"
