# -*- coding: utf-8 -*-
"""Baut das Formelbuch neu: Rechenwege, fehlende Formeln und Kalkulationsschemas.

Quelle der Wahrheit bleibt ``flutter_app/assets/data/formulas.json``. Dieses
Skript reichert die Datei an und ist idempotent – ein zweiter Lauf ändert
nichts mehr. Anschließend ``scripts/build_formulas.py`` laufen lassen, das die
Web-Fassung in ``index.html`` daraus erzeugt.

    python3 scripts/formeln/build_formelbuch.py
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)

from rechenbar import RECHNEN            # noqa: E402
from neu import ERGAENZUNGEN, NEUE_GRUPPEN, SCHEMAS  # noqa: E402

JSON_PFAD = os.path.join(ROOT, 'flutter_app', 'assets', 'data', 'formulas.json')
SCHEMA_GRUPPE = 'Kalkulationsschema (zum Ausfüllen)'


def gruppe(daten, name):
    for g in daten:
        if g['g'] == name:
            return g
    raise SystemExit('Gruppe %r nicht gefunden.' % name)


def rechenwege_eintragen(daten):
    """Trägt Variablen/Ausdruck/Ergebnis in die passenden Formeln ein."""
    offen = set(RECHNEN)
    n = 0
    for g in daten:
        for it in g['items']:
            spec = RECHNEN.get((g['g'], it['n']))
            if not spec:
                continue
            offen.discard((g['g'], it['n']))
            it.update(json.loads(json.dumps(spec)))  # eigene Kopie je Formel
            n += 1
    if offen:
        raise SystemExit('Rechenweg ohne passende Formel: %s'
                         % ', '.join('%s / %s' % k for k in sorted(offen)))
    return n


def ergaenzen(daten):
    """Hängt fehlende Formeln an ihre Gruppe an (ohne Dubletten)."""
    n = 0
    for gname, items in ERGAENZUNGEN.items():
        g = gruppe(daten, gname)
        vorhanden = {it['n'] for it in g['items']}
        for it in items:
            if it['n'] in vorhanden:
                continue
            g['items'].append(json.loads(json.dumps(it)))
            n += 1
    return n


def neue_gruppen(daten):
    """Fügt neue Gruppen direkt hinter ihrer Bezugsgruppe ein."""
    n = 0
    for davor, grp in NEUE_GRUPPEN:
        if any(g['g'] == grp['g'] for g in daten):
            continue
        idx = next(i for i, g in enumerate(daten) if g['g'] == davor)
        daten.insert(idx + 1, json.loads(json.dumps(grp)))
        n += 1
    return n


def schemas(daten):
    """Legt die Schema-Gruppe ganz oben ab (bzw. aktualisiert sie)."""
    grp = {'g': SCHEMA_GRUPPE, 'items': [], 's': json.loads(json.dumps(SCHEMAS))}
    for i, g in enumerate(daten):
        if g['g'] == SCHEMA_GRUPPE:
            daten[i] = grp
            return 0
    daten.insert(0, grp)
    return 1


def pruefe(daten):
    """Datenvertrag: Rechenwege müssen vollständig und auswertbar sein."""
    import rechner
    schluessel = set()
    for g in daten:
        for it in g['items']:
            if 'f' not in it:
                continue
            keys = [x['k'] for x in it['v']]
            if len(keys) != len(set(keys)):
                raise SystemExit('%s: doppelte Variable' % it['n'])
            # Probelauf mit paarweise verschiedenen Werten, damit kein Ausdruck
            # kaputt ist und Differenzen im Nenner nicht zufällig null werden.
            probe = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
            werte = {x['k']: float(probe[i % len(probe)])
                     for i, x in enumerate(it['v'])}
            try:
                rechner.auswerten(it['f'], werte)
            except Exception as e:
                raise SystemExit('%s: Ausdruck %r nicht auswertbar (%s)'
                                 % (it['n'], it['f'], e))
            schluessel.add(it['n'])
    for g in daten:
        for s in g.get('s', []):
            ks = [r['k'] for r in s['rows']]
            if len(ks) != len(set(ks)):
                raise SystemExit('Schema %s: doppelte Zeilenkennung' % s['id'])
            for r in s['rows']:
                for ref in ([r['base']] if r.get('base') else []) + \
                           [x.lstrip('-') for x in r.get('of', [])] + r.get('ih', []):
                    if ref not in ks:
                        raise SystemExit('Schema %s: Zeile %s verweist auf %s'
                                         % (s['id'], r['k'], ref))


def main():
    daten = json.load(open(JSON_PFAD, encoding='utf-8'))
    a = rechenwege_eintragen(daten)
    b = ergaenzen(daten)
    c = neue_gruppen(daten)
    d = schemas(daten)
    pruefe(daten)
    with open(JSON_PFAD, 'w', encoding='utf-8') as fh:
        json.dump(daten, fh, ensure_ascii=False, indent=1)
        fh.write('\n')
    gesamt = sum(len(g['items']) for g in daten)
    rechenbar = sum(1 for g in daten for it in g['items'] if 'f' in it)
    print('  Rechenwege eingetragen: %d' % a)
    print('  Formeln ergänzt:        %d (neue Gruppen: %d)' % (b, c))
    print('  Schema-Gruppe:          %s' % ('neu angelegt' if d else 'aktualisiert'))
    print('  Formelbuch gesamt:      %d Formeln in %d Gruppen, davon %d rechenbar'
          % (gesamt, len(daten), rechenbar))


if __name__ == '__main__':
    main()
