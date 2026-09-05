# -*- coding: utf-8 -*-
"""Baut aus den geparsten IHK-Prüfungen (parse_amtlich.py) Fallaufgaben mit
amtlichen Lösungshinweisen im App-Format und schreibt sie in
``flutter_app/assets/data/cases.json`` sowie in ``window.KVM_CASES`` von
``index.html`` – jeweils nur die Prüfungsfälle (IDs mit Präfix ``P-``); alle
übrigen Fälle bleiben unangetastet.

Nur vollständige Prüfungen (genau 100 Punkte, jede Teilaufgabe mit amtlicher
Lösung) werden aufgenommen.
"""
import json, os, re, sys, io

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
import parse_amtlich as pa
try:
    from korrekturen import BILDER, TABELLEN, _ANLAGEN
except Exception:
    BILDER, TABELLEN, _ANLAGEN = {}, {}, os.path.join(HERE, 'anlagen')
import base64

BEREICH_FACH = {'FT': 5, 'OK': 4}
BEREICH_LANG = {'FT': 'Fuhrparktechnik und Fuhrparkmanagement',
                'OK': 'Organisation und Kommunikation'}
SAISON_NAME = {5: 'Frühjahr', 11: 'Herbst'}

def _txt(x):
    return x if isinstance(x, str) else '\n'.join(x)

def cid_of(ex):
    kb = pa.bereich_kuerzel(ex['bereich'])
    dt = pa.datum_teile(ex['datum'])
    if not (kb and dt): return None
    j, m, t = dt
    return 'P-%s-%04d%02d%02d' % (kb, j, m, t)

def komplett(ex):
    """Vollständig = 100 Punkte und zu JEDER Teilaufgabe (je Aufgabe, je Label)
    eine amtliche Lösung. Rein zahlenmäßige Gleichheit reicht nicht: die OCR
    kann Lösungsteile anders splitten als die Aufgabe."""
    teile = [t for a in ex['aufgaben'] for t in a['teile']]
    if not teile or sum(t['punkte'] for t in teile) != 100:
        return False
    for a in ex['aufgaben']:
        by = {t['label']: t for t in (a.get('loes') or [])}
        for t in a['teile']:
            ml = by.get(t['label'])
            if not ml or not _txt(ml.get('loesung', '')).strip():
                return False
    return True

def build_cases(exams):
    cases = []
    for ex in exams:
        if not komplett(ex): continue
        cid = cid_of(ex)
        kb = pa.bereich_kuerzel(ex['bereich'])
        fach = BEREICH_FACH[kb]
        sub = 'IHK-Prüfung: ' + BEREICH_LANG[kb]
        j, m, t = pa.datum_teile(ex['datum'])
        termin = '%s %d' % (SAISON_NAME.get(m, ''), j)
        steps = []
        for a in ex['aufgaben']:
            intro = _txt(a['intro'])
            loes_by_label = {tl['label']: tl for tl in a['loes']}
            for tteil in a['teile']:
                lab = tteil['label']
                sol = loes_by_label.get(lab, {})
                kopf = 'Aufgabe %d %s) · %d %s' % (
                    a['nr'], lab, tteil['punkte'],
                    'Punkt' if tteil['punkte'] == 1 else 'Punkte')
                frage = _txt(tteil['text'])
                q = kopf + '\n\n' + (intro + '\n\n' if intro else '') + frage
                step = {
                    'id': '%s-s%d' % (cid, len(steps)),
                    'f': fach, 'sub': sub, 't': 'open', 'q': q,
                    'a': _txt(sol.get('loesung', '')),
                    'amtlich': True,
                }
                if sol.get('vo'):
                    step['vo'] = sol['vo']
                bew = sol.get('bewertung') or []
                # nur zeigen, wenn die Teilpunkte vollständig aufgehen
                if len(bew) >= 2 and sum(bew) == tteil['punkte']:
                    step['bewertung'] = bew
                steps.append(step)
        ctx = _txt(ex['context'])
        ctx += ('\n\nOriginal-Prüfungsaufgabe der IHK vom %s · Handlungsbereich %s · '
                'Bearbeitungszeit 180 Minuten · 100 Punkte insgesamt. '
                'Die Lösungshinweise sind die amtlichen Lösungshinweise der IHK.'
                % (ex['datum'], BEREICH_LANG[kb]))
        cases.append({
            'id': cid, 'f': fach, 'sub': sub,
            'title': 'IHK-Prüfung %s – %s' % (BEREICH_LANG[kb], ex['datum']),
            'termin': termin, 'amtlich': True,
            'context': ctx, 'steps': steps,
        })
    return cases

def apply_media(cases):
    """Bilder und Tabellen aus korrekturen.py per Schritt-ID einspielen (weich)."""
    n = 0
    for c in cases:
        for s in c['steps']:
            if s['id'] in TABELLEN:
                s['tab'] = TABELLEN[s['id']]; n += 1
            if s['id'] in BILDER:
                pfad = os.path.join(_ANLAGEN, BILDER[s['id']])
                if os.path.exists(pfad):
                    with open(pfad, 'rb') as f:
                        s['bild'] = 'data:image/jpeg;base64,' + base64.b64encode(f.read()).decode('ascii')
                    n += 1
    return n

def dump_compact(data):
    return json.dumps(data, ensure_ascii=False, separators=(',', ':'))

def inject_app(cases):
    path = os.path.join(ROOT, 'flutter_app', 'assets', 'data', 'cases.json')
    alle = json.load(open(path, encoding='utf-8'))
    andere = [c for c in alle if not str(c.get('id', '')).startswith('P-')]
    neu = andere + cases
    open(path, 'w', encoding='utf-8').write(dump_compact(neu))
    return len(andere), len(cases)

def _find_array(html, start):
    """Klammer- und stringbewusst das JSON-Array ab Position des '[' finden.
    Gibt (i0, i1) mit html[i0:i1] == komplettes Array zurück."""
    i0 = html.index('[', start)
    depth, i, instr, esc = 0, i0, False, False
    while i < len(html):
        ch = html[i]
        if instr:
            if esc: esc = False
            elif ch == '\\': esc = True
            elif ch == '"': instr = False
        else:
            if ch == '"': instr = True
            elif ch == '[': depth += 1
            elif ch == ']':
                depth -= 1
                if depth == 0:
                    return i0, i + 1
        i += 1
    raise SystemExit('KVM_CASES-Array nicht geschlossen.')

def inject_web(cases):
    path = os.path.join(ROOT, 'index.html')
    html = open(path, encoding='utf-8').read()
    m = re.search(r'window\.KVM_CASES\s*=\s*', html)
    if not m:
        raise SystemExit('window.KVM_CASES=… nicht in index.html gefunden.')
    i0, i1 = _find_array(html, m.end())
    alle = json.loads(html[i0:i1])
    andere = [c for c in alle if not str(c.get('id', '')).startswith('P-')]
    neu = andere + cases
    open(path, 'w', encoding='utf-8').write(html[:i0] + dump_compact(neu) + html[i1:])
    return len(andere), len(cases)

def main():
    src = os.path.join(HERE, 'quellen', 'ihk-pruefungen-2021-2026-mit-loesungshinweisen.ocr.txt')
    q, s = pa.parse(src)
    pa.pair(q, s)
    cases = build_cases(q)
    med = apply_media(cases)
    # Punkte-Invariante hart prüfen
    import re as _re
    for c in cases:
        tot = 0
        for st in c['steps']:
            mm = _re.search(r'·\s*(\d+)\s*Punkte?', st['q'].split('\n\n')[0])
            tot += int(mm.group(1)) if mm else 0
        assert tot == 100, 'Prüfung %s hat %d Punkte' % (c['id'], tot)
        assert all(st.get('a') for st in c['steps']), 'Prüfung %s: Schritt ohne Lösung' % c['id']
    a_o, a_n = inject_app(cases)
    w_o, w_n = inject_web(cases)
    print('  Prüfungen (amtlich, komplett): %d' % len(cases))
    for c in sorted(cases, key=lambda c: c['id']):
        print('    %-16s %2d Schritte  %s' % (c['id'], len(c['steps']), c['termin']))
    print('  Medien eingespielt: %d' % med)
    print('  App  cases.json: %d andere + %d Prüfungen' % (a_o, a_n))
    print('  Web  KVM_CASES : %d andere + %d Prüfungen' % (w_o, w_n))

if __name__ == '__main__':
    main()
