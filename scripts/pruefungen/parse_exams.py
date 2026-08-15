# -*- coding: utf-8 -*-
"""Zerlegt die OCR-Texte der IHK-Prüfungen in strukturierte Prüfungen."""
import re, json, sys

BULLET = re.compile(r'^\s*[=mw■□\-•*]\s+|^\s*[a-z]\s{2,}(?=[A-ZÄÖÜ])')
# OCR verstümmelt das Buchstaben-Badge vor dem Punktetext ("6 |", "|da|", "ba "),
# deshalb wird ein kurzes beliebiges Präfix zugelassen.
PUNKTE = re.compile(r'^\s*.{0,8}?M[öo]glich\w*\s*Punktzahl:\s*(\d+)\s*$', re.I)
AUFGABE = re.compile(r'^\s*Aufgabe\s+(\d+)\s*$')
# Die Prüfungen heißen je nach Jahrgang "Aufgabenstellung N" oder "Situationsaufgabe N".
HEADER  = re.compile(r'Handlungsspezifische Qualifikation.*?(?:Aufgabenstellung|Situationsaufgabe)\s*(\d+)', re.I)
DATUM   = re.compile(r'^\s*Datum:\s*(.+?)\s*$')
BEREICH = re.compile(r'^\s*Handlungsbereich:\s*(.+?)\s*$')
ANZAHL  = re.compile(r'^\s*Anzahl Aufgaben:\s*(\d+)')

def clean(line):
    l = line.rstrip()
    l = re.sub(r'^\s*[=mw]\s+(?=[A-ZÄÖÜa-zäöü])', '– ', l)   # OCR-Aufzählungszeichen
    l = re.sub(r'^\s*■\s*', '– ', l)
    l = re.sub(r'\s{2,}', ' ', l)
    return l.strip()

def join_para(lines):
    """Zeilen zu Absätzen verbinden, Silbentrennung am Zeilenende auflösen."""
    out, buf = [], ''
    for l in lines:
        if not l:
            if buf: out.append(buf.strip()); buf = ''
            continue
        if l.startswith('– '):
            if buf: out.append(buf.strip()); buf = ''
            out.append(l); continue
        if buf.endswith('-') and not buf.endswith('--'):
            buf = buf[:-1] + l          # Trennstrich auflösen
        else:
            buf = (buf + ' ' + l).strip() if buf else l
    if buf: out.append(buf.strip())
    return [p for p in out if p]

def parse(path, bereich_default):
    raw = open(path, encoding='utf-8').read()
    lines = [clean(l) for l in raw.split('\n')]
    # Seitenzahlen und Wiederholungen entfernen
    lines = [l for l in lines if not re.fullmatch(r'\d{1,3}', l or '')]

    # Prüfungen anhand der Kopfzeile trennen
    starts = [i for i, l in enumerate(lines) if HEADER.search(l)]
    if not starts: starts = [0]
    exams = []
    for n, s in enumerate(starts):
        e = starts[n+1] if n+1 < len(starts) else len(lines)
        block = lines[s:e]
        ex = {'stellung': None, 'datum': None, 'bereich': bereich_default,
              'anzahl': None, 'context': [], 'aufgaben': []}
        m = HEADER.search(block[0]);  ex['stellung'] = m.group(1) if m else str(n+1)
        for l in block[:12]:
            if DATUM.match(l):   ex['datum']   = DATUM.match(l).group(1)
            if BEREICH.match(l): ex['bereich'] = BEREICH.match(l).group(1)
            if ANZAHL.match(l):  ex['anzahl']  = int(ANZAHL.match(l).group(1))
        # Ausgangssituation: bis zur ersten "Aufgabe N"
        first_task = next((i for i, l in enumerate(block) if AUFGABE.match(l)), len(block))
        ctx_start = next((i for i, l in enumerate(block)
                          if re.search(r'Ausgangssituation', l)), 0) + 1
        ex['context'] = join_para(block[ctx_start:first_task])
        # Aufgaben
        tstarts = [i for i, l in enumerate(block) if AUFGABE.match(l)]
        for k, ts in enumerate(tstarts):
            te = tstarts[k+1] if k+1 < len(tstarts) else len(block)
            tb = block[ts:te]
            nr = int(AUFGABE.match(tb[0]).group(1))
            # Teilaufgaben anhand "Mögliche Punktzahl"
            pidx = [i for i, l in enumerate(tb) if PUNKTE.match(l)]
            intro = join_para(tb[1:pidx[0]]) if pidx else join_para(tb[1:])
            teile = []
            for j, pi in enumerate(pidx):
                pe = pidx[j+1] if j+1 < len(pidx) else len(tb)
                pts = int(PUNKTE.match(tb[pi]).group(1))
                txt = join_para(tb[pi+1:pe])
                teile.append({'label': chr(ord('a')+j), 'punkte': pts, 'text': txt})
            ex['aufgaben'].append({'nr': nr, 'intro': intro, 'teile': teile})
        exams.append(ex)
    return exams

if __name__ == '__main__':
    base = sys.argv[1]
    ok = parse(base + '/OK_full.txt', 'Organisation und Kommunikation')
    ft = parse(base + '/FT_full.txt', 'Fuhrparktechnik und Fuhrparkmanagement')
    all_ex = [('OK', e) for e in ok] + [('FT', e) for e in ft]
    json.dump([{'src': s, **e} for s, e in all_ex],
              open(base + '/exams.json', 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    na = sum(len(e['aufgaben']) for _, e in all_ex)
    nt = sum(len(a['teile']) for _, e in all_ex for a in e['aufgaben'])
    print('  Prüfungen:  %d  (OK %d / FT %d)' % (len(all_ex), len(ok), len(ft)))
    print('  Aufgaben:   %d' % na)
    print('  Teilaufgaben: %d' % nt)
    leer_ctx = [f"{s} {e['datum']}" for s, e in all_ex if len(' '.join(e['context'])) < 200]
    leer_txt = sum(1 for _, e in all_ex for a in e['aufgaben'] for t in a['teile'] if len(t['text']) < 25)
    print('  Prüfungen ohne brauchbare Ausgangssituation:', leer_ctx or 'keine')
    print('  Teilaufgaben mit verdächtig kurzem Text:', leer_txt)
