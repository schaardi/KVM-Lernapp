# -*- coding: utf-8 -*-
"""Baut aus den IHK-Basisqualifikations-Prüfungen (parse_imbq.py) startbare
Prüfungsfälle und spielt sie in Web und App ein.

Gebaut werden alle Jahrgänge aus ``parse_imbq.JAHRGAENGE``. Die Prüfungen
bekommen IDs mit dem Präfix ``P-`` (wie die Kraftverkehr-Prüfungen) und
erscheinen damit im Prüfungs-Picker, gruppiert nach Termin. Da die ID das
Prüfungsdatum trägt, unterscheiden sich die Jahrgänge von selbst. Alle übrigen
Fälle bleiben unangetastet.

    python3 scripts/pruefungen/build_imbq.py
"""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
import parse_imbq as P
import anlagen_imbq as AN
import build_amtlich as BA   # dump_compact, webdaten
import aufgaben_modell as AM  # Aufgabenblatt-Format

def baue(exams):
    cases = []
    for ex in exams:
        j, mo, tg = P.datum_teile(ex['datum'])
        cid = 'P-%s-%04d%02d%02d' % (ex['kuerzel'], j, mo, tg)
        sub = 'IHK-Prüfung: ' + ex['bezeichnung']
        termin = ('%s %d' % ('Frühjahr' if mo <= 6 else 'Herbst', j))
        steps = []
        for nr in sorted(ex['aufgaben']):
            a = ex['aufgaben'][nr]
            lo = {t['label']: t for t in ex['loesungen'][nr]['teile']}
            vo = ex['loesungen'][nr].get('vo', '')
            intro = a['intro'].strip()
            for t in a['teile']:
                sol = lo[t['label']]
                kopf = 'Aufgabe %d %s) · %d %s' % (
                    nr, t['label'], t['punkte'],
                    'Punkt' if t['punkte'] == 1 else 'Punkte')
                q = kopf + '\n\n' + (intro + '\n\n' if intro else '') + t['text'].strip()
                step = {'id': '%s-s%d' % (cid, len(steps)),
                        'f': ex['fach'], 'sub': sub, 't': 'open', 'q': q,
                        'a': sol['loesung'].strip(), 'amtlich': True}
                if vo:
                    step['vo'] = vo
                AN.anwenden(step, ex['kuerzel'], ex['jahrgang'], nr, t['label'])
                steps.append(step)
        ctx = ex['kontext'].strip()
        if not ctx:
            ctx = ('In dieser Prüfung hat jede Aufgabe ihre eigene Ausgangssituation; '
                   'sie steht jeweils über der Aufgabe.')
        ctx += ('\n\nOriginal-Prüfungsaufgabe der IHK vom %s · Bundeseinheitliche '
                'Fortbildungsprüfung, fachrichtungsübergreifende Basisqualifikationen · '
                'Handlungsbereich %s · 100 Punkte insgesamt. '
                'Die Lösungshinweise sind die amtlichen Lösungshinweise der IHK.'
                % (ex['datum'], ex['bezeichnung']))
        cases.append({'id': cid, 'f': ex['fach'], 'sub': sub,
                      'title': 'IHK-Prüfung %s – %s' % (ex['bezeichnung'], ex['datum']),
                      'termin': termin, 'amtlich': True,
                      'context': ctx, 'steps': steps})
    return cases

def main():
    exams = []
    for jahrgang in sorted(P.JAHRGAENGE):
        exams += P.parse_alle(jahrgang=jahrgang)
    fehler = [f'{e["kuerzel"]}: {P.pruefe(e)}' for e in exams if P.pruefe(e)]
    assert not fehler, fehler
    import os as _os
    AN.pruefe({_os.path.splitext(f)[0]
               for f in _os.listdir(_os.path.join(HERE, 'anlagen'))})
    roh = baue(exams)
    neu_ids = {c['id'] for c in roh}
    for c in roh:
        tot = sum(int(re.search(r'·\s*(\d+)\s*Punkte?', s['q'].split('\n\n')[0]).group(1))
                  for s in c['steps'])
        assert tot == 100, (c['id'], tot)
        assert all(s.get('a') for s in c['steps']), c['id']

    # In das Aufgabenblatt-Format überführen (Aufgabe mit Teilen a–x) und den
    # Umbau gegen das Original prüfen – der alte Fragetext muss sich exakt
    # rekonstruieren lassen.
    neu = []
    for c in roh:
        n = AM.zerlegen(c)
        fehler_um = AM.pruefen(c, n)
        assert not fehler_um, fehler_um
        assert sum(a['pts'] for a in n['aufgaben']) == 100, (c['id'], 'Aufgabenpunkte')
        neu.append(n)

    # App
    ap = os.path.join(ROOT, 'flutter_app', 'assets', 'data', 'cases.json')
    alle = json.load(open(ap, encoding='utf-8'))
    rest = [c for c in alle if c.get('id') not in neu_ids]
    open(ap, 'w', encoding='utf-8').write(BA.dump_compact(rest + neu))

    # Web
    weballe = BA.W.lesen('KVM_CASES')
    webrest = [c for c in weballe if c.get('id') not in neu_ids]
    BA.W.schreiben('KVM_CASES', webrest + neu)

    mb = sum(1 for c in neu for s in c['steps'] if s.get('bild')) \
        + sum(1 for c in neu for a in c['aufgaben'] if a.get('bild'))
    ml = sum(1 for c in neu for s in c['steps'] if s.get('bildL'))
    mt = sum(1 for c in neu for s in c['steps'] if s.get('tab')) \
        + sum(1 for c in neu for a in c['aufgaben'] if a.get('tab'))
    print('  BQ-Prüfungen gebaut: %d  ·  Anlagen: %d Bilder zur Aufgabe, '
          '%d zur Lösung, %d Tabellen' % (len(neu), mb, ml, mt))
    for c in neu:
        print('    %-16s %2d Aufgaben / %2d Teile  %-12s Fach %d  %s'
              % (c['id'], len(c['aufgaben']), len(c['steps']), c['termin'], c['f'],
                 c['sub'][14:44]))
    print('  App  cases.json: %d Fälle (%d andere + %d neu)' % (len(rest) + len(neu), len(rest), len(neu)))
    print('  Web  KVM_CASES : %d Fälle (%d andere + %d neu)' % (len(webrest) + len(neu), len(webrest), len(neu)))

if __name__ == '__main__':
    main()
