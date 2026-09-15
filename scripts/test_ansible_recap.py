import unittest

from ansible_recap import parse_recap

RECAP = """PLAY [Deploy users] ************************************************************
TASK [Gathering Facts] *********************************************************
fatal: [dashboard.dev.babsy.ch]: UNREACHABLE! => {"changed": false, "unreachable": true}
ok: [docker2.infra.babsy.ch]

PLAY RECAP *********************************************************************
docker2.infra.babsy.ch     : ok=47   changed=13   unreachable=0    failed=0    skipped=10   rescued=0    ignored=1
dashboard.dev.babsy.ch     : ok=0    changed=0    unreachable=1    failed=0    skipped=0    rescued=0    ignored=0
"""


class ParseRecapTest(unittest.TestCase):
    def test_liest_alle_hosts_mit_zaehlern(self):
        hosts = {h['hostname']: h for h in parse_recap(RECAP.splitlines(True))}
        self.assertEqual(set(hosts), {'docker2.infra.babsy.ch', 'dashboard.dev.babsy.ch'})
        self.assertEqual(hosts['docker2.infra.babsy.ch']['ok'], 47)
        self.assertEqual(hosts['docker2.infra.babsy.ch']['changed'], 13)
        self.assertEqual(hosts['dashboard.dev.babsy.ch']['unreachable'], 1)

    def test_ignoriert_zeilen_vor_dem_recap(self):
        # "ok: [host]" aus den Tasks darf nicht als Recap-Zeile gelten.
        vorher = 'host.example.ch : ok=1 changed=0 unreachable=0 failed=0\n'
        self.assertEqual(parse_recap([vorher]), [])

    def test_ohne_recap_leer(self):
        self.assertEqual(parse_recap(['ERROR! the playbook could not be found\n']), [])

    def test_mehrere_plays_letzter_stand_zaehlt(self):
        zeilen = [
            'PLAY RECAP ***\n',
            'a.babsy.ch : ok=1 changed=0 unreachable=1 failed=0\n',
            'PLAY RECAP ***\n',
            'a.babsy.ch : ok=5 changed=1 unreachable=0 failed=0\n',
        ]
        [host] = parse_recap(zeilen)
        self.assertEqual(host['unreachable'], 0)
        self.assertEqual(host['ok'], 5)

    def test_fehlgeschlagene_aufgabe(self):
        zeilen = ['PLAY RECAP ***\n', 'b.babsy.ch : ok=3 changed=0 unreachable=0 failed=2 skipped=0\n']
        self.assertEqual(parse_recap(zeilen)[0]['failed'], 2)


if __name__ == '__main__':
    unittest.main()
