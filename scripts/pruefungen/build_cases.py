# -*- coding: utf-8 -*-
"""Baut aus den geparsten IHK-Prüfungen + Musterlösungen Fallaufgaben
im Format der App (cases.json)."""
import json, re, sys, unicodedata

sys.path.insert(0, __file__.rsplit('/', 1)[0])
from loesungen import LOESUNGEN

BEREICH_KUERZEL = {
    'Organisation und Kommunikation': ('OK', 4),
    'Fuhrparktechnik und Fuhrparkmanagement': ('FT', 5),
}

# Wiederkehrende OCR-Verwechslungen in den eingescannten Datenlisten.
OCR_FIXES = [
    (r'\bm\s+_', '– '),                      # "m _Nutzungszeit"
    (r'^\s*=\s+_?', '– '),                   # "= _Jahresfahrleistung"
    (r'^\s*[ms]\s+(?=[A-ZÄÖÜ0-9])', '– '),   # "m 20 Sattelkraftfahrzeuge"
    (r'(\d)\s*1/100\s*km', r'\1 l/100 km'),  # "30 1/100 km"
    (r'€\s*/\s*\|', '€/l'),                  # "1,30 €/|"
    (r'€\s*/\s*1(?![.,]?\d)', '€/l'),   # nur die Einheit Liter, nicht "€/1.000 km"
    (r'\bz6M\b', 'zGM'),
    (r'\bzGm\b', 'zGM'),
    (r'(\d)\s*tzGM', r'\1 t zGM'),
    (r'\bBAG\b(?=.*20(2[2-9]))', 'BALM'),    # Behörde wurde 2023 umbenannt
]
# Kopfzeilen, die durch den Seitenumbruch in den Text gerutscht sind.
TRAILING_JUNK = re.compile(
    r'\s*Gepr[üu]ft(?:er|e)?\s*/?-?r?\s*Meister.*$|\s*Handlungsspezifische Qualifikation.*$'
    r'|\s*Handlungsbereich:.*$|\s*Datum:\s*\d.*$', re.I)

def fix(text):
    t = text
    for pat, rep in OCR_FIXES[:3]:
        t = re.sub(pat, rep, t)
    for pat, rep in OCR_FIXES[3:]:
        t = re.sub(pat, rep, t)
    t = TRAILING_JUNK.sub('', t)
    t = re.sub(r'\s{2,}', ' ', t).strip()
    return t

def para(lines):
    return '\n'.join(fix(l) for l in lines if fix(l))

def build(exams_path, out_path):
    exams = json.load(open(exams_path, encoding='utf-8'))
    cases, fehlend = [], []
    for e in exams:
        kuerzel, fach = BEREICH_KUERZEL[e['bereich']]
        # Datum -> ID (z. B. "12. November 2025" -> 20251112)
        MON = {'Januar':1,'Februar':2,'März':3,'April':4,'Mai':5,'Juni':6,'Juli':7,
               'August':8,'September':9,'Oktober':10,'November':11,'Dezember':12}
        m = re.match(r'(\d{1,2})\.\s*(\w+)\s*(\d{4})', e['datum'])
        dat_id = '%s%02d%02d' % (m.group(3), MON[m.group(2)], int(m.group(1))) if m else 'x'
        cid = 'P-%s-%s' % (kuerzel, dat_id)

        steps, alle_da = [], True
        for a in e['aufgaben']:
            intro = para(a['intro'])
            for t in a['teile']:
                key = '%s|%s|%d|%s' % (kuerzel, e['datum'], a['nr'], t['label'])
                sol = LOESUNGEN.get(key)
                if not sol:
                    alle_da = False
                    fehlend.append(key)
                    continue
                frage = para(t['text'])
                kopf = 'Aufgabe %d %s) · %d %s' % (
                    a['nr'], t['label'], t['punkte'],
                    'Punkt' if t['punkte'] == 1 else 'Punkte')
                q = kopf + '\n\n' + (intro + '\n\n' if intro else '') + frage
                steps.append({
                    'id': '%s-s%d' % (cid, len(steps)),
                    'f': fach,
                    'sub': 'IHK-Prüfung: ' + e['bereich'],
                    't': 'open',
                    'q': q,
                    'a': sol['a'],
                    **({'e': sol['e']} if sol.get('e') else {}),
                })
        if not steps or not alle_da:
            continue
        punkte = sum(t['punkte'] for a in e['aufgaben'] for t in a['teile'])
        ctx = para(e['context'])
        ctx += ('\n\nOriginal-Prüfungsaufgabe der IHK vom %s · Handlungsbereich %s · '
                'Bearbeitungszeit 180 Minuten · %d Punkte insgesamt. '
                'Die Musterlösungen sind fachlich erarbeitet und nicht amtlich.'
                % (e['datum'], e['bereich'], punkte))
        cases.append({
            'id': cid, 'f': fach,
            'sub': 'IHK-Prüfung: ' + e['bereich'],
            'title': 'IHK-Prüfung %s – %s' % (e['bereich'], e['datum']),
            'context': ctx,
            'steps': steps,
        })
    json.dump(cases, open(out_path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('  Fallaufgaben erzeugt: %d' % len(cases))
    for c in cases:
        print('    %-16s %2d Teilaufgaben  %s' % (c['id'], len(c['steps']), c['title'][:58]))
    print('  Noch ohne Musterlösung: %d Teilaufgaben' % len(fehlend))
    return cases

if __name__ == '__main__':
    build(sys.argv[1], sys.argv[2])
