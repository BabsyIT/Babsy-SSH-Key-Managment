#!/usr/bin/env python3
"""PLAY RECAP einer Ansible-Ausgabe als JSON fuer das Cockpit.

Aufruf:  ansible_recap.py <ansible-log> <run-url>  > deploy-result.json

Lag zuerst als Heredoc im Workflow. Dort liess er sich nicht pruefen — und ein
Parser, der still nichts findet, faellt erst auf, wenn im Cockpit alle Server
auf "ausstehend" stehen bleiben. Deshalb eigene Datei mit Tests daneben
(test_ansible_recap.py).
"""

import json
import re
import sys

ZEILE = re.compile(
    r'^(?P<host>\S+)\s*:\s*ok=(?P<ok>\d+)\s+changed=(?P<changed>\d+)\s+'
    r'unreachable=(?P<unreachable>\d+)\s+failed=(?P<failed>\d+)'
)


def parse_recap(zeilen):
    """Hosts mit ihren Zaehlern aus den Zeilen nach "PLAY RECAP"."""
    hosts = {}
    im_recap = False
    for roh in zeilen:
        text = roh.rstrip('\n')
        if text.startswith('PLAY RECAP'):
            im_recap = True
            continue
        if not im_recap:
            continue
        m = ZEILE.match(text)
        if m:
            # Mehrere Plays: der letzte Stand je Host zaehlt.
            hosts[m['host']] = {
                'hostname': m['host'],
                'ok': int(m['ok']),
                'changed': int(m['changed']),
                'unreachable': int(m['unreachable']),
                'failed': int(m['failed']),
            }
    return list(hosts.values())


def main(argv):
    if len(argv) != 3:
        print('Aufruf: ansible_recap.py <ansible-log> <run-url>', file=sys.stderr)
        return 2
    log_path, run_url = argv[1], argv[2]
    with open(log_path, encoding='utf-8', errors='replace') as f:
        hosts = parse_recap(f)
    json.dump({'runUrl': run_url, 'dryRun': False, 'hosts': hosts}, sys.stdout)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
