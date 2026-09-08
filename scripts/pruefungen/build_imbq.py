# -*- coding: utf-8 -*-
"""Baut aus den IHK-Basisqualifikations-Prüfungen (parse_imbq.py) startbare
Prüfungsfälle und spielt sie in Web und App ein.

Die vier Prüfungen bekommen IDs mit dem Präfix ``P-`` (wie die Kraftverkehr-
Prüfungen) und erscheinen damit im Prüfungs-Picker, gruppiert nach Termin.
Alle übrigen Fälle bleiben unangetastet.

    python3 scripts/pruefungen/build_imbq.py
"""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
import parse_imbq as P
import build_amtlich as BA   # _find_array, dump_compact

MON = {'januar':1,'februar':2,'märz':3,'april':4,'mai':5,'juni':6,'juli':7,
       'august':8,'september':9,'oktober':10,'november':11,'dezember':12}

def datum_teile(d):
    m = re.match(r'(\d{1,2})\.\s*(\w+)\s*(\d{4})', d or '')
    return (int(m.group(3)), MON[m.group(2).lower()], int(m.group(1))) if m else None

def baue(exams):
    cases = []
    for ex in exams:
        j, mo, tg = datum_teile(ex['datum'])
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
    exams = P.parse_alle()
    fehler = [f'{e["kuerzel"]}: {P.pruefe(e)}' for e in exams if P.pruefe(e)]
    assert not fehler, fehler
    neu = baue(exams)
    neu_ids = {c['id'] for c in neu}
    for c in neu:
        tot = sum(int(re.search(r'·\s*(\d+)\s*Punkte?', s['q'].split('\n\n')[0]).group(1))
                  for s in c['steps'])
        assert tot == 100, (c['id'], tot)
        assert all(s.get('a') for s in c['steps']), c['id']

    # App
    ap = os.path.join(ROOT, 'flutter_app', 'assets', 'data', 'cases.json')
    alle = json.load(open(ap, encoding='utf-8'))
    rest = [c for c in alle if c.get('id') not in neu_ids]
    open(ap, 'w', encoding='utf-8').write(BA.dump_compact(rest + neu))

    # Web
    wp = os.path.join(ROOT, 'index.html')
    html = open(wp, encoding='utf-8').read()
    m = re.search(r'window\.KVM_CASES\s*=\s*', html)
    i0, i1 = BA._find_array(html, m.end())
    weballe = json.loads(html[i0:i1])
    webrest = [c for c in weballe if c.get('id') not in neu_ids]
    open(wp, 'w', encoding='utf-8').write(
        html[:i0] + BA.dump_compact(webrest + neu) + html[i1:])

    print('  BQ-Prüfungen gebaut: %d' % len(neu))
    for c in neu:
        print('    %-16s %2d Schritte  %-12s Fach %d  %s'
              % (c['id'], len(c['steps']), c['termin'], c['f'], c['sub'][14:44]))
    print('  App  cases.json: %d Fälle (%d andere + %d neu)' % (len(rest) + len(neu), len(rest), len(neu)))
    print('  Web  KVM_CASES : %d Fälle (%d andere + %d neu)' % (len(webrest) + len(neu), len(webrest), len(neu)))

if __name__ == '__main__':
    main()
