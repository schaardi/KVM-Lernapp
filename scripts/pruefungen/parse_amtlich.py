# -*- coding: utf-8 -*-
"""Zerlegt den OCR-Volltext der IHK-Prüfungssammlung (mit Seitenmarkern) in
Prüfungen samt amtlichen Lösungshinweisen.

Zwei Layout-Epochen:
  * 2021–2022: Lösungshinweise stehen direkt hinter jeder Aufgabe (interleaved).
  * ab 2023:  erst die Aufgabenteile (mit Datum), danach je Saison ein
              Lösungs-Booklet (ohne Datum), das über (Bereich, Monat, Jahr)
              der passenden Prüfung zugeordnet wird.

Ausgabe: exams.json – je Teilaufgabe zusätzlich loesung/vo/bewertung.
"""
import re, json, sys, os

# ── Regexe ────────────────────────────────────────────────────────────────
PAGE   = re.compile(r'^=== Seite (\d+) ===\s*$')
HEADER = re.compile(r'Handlungsspezifische Qualifikation.*?(?:Aufgabenstellung|Situationsaufgabe)\s*(\d+)', re.I)
SAISON = re.compile(r'^\s*(Frühjahr|Herbst)\s+(\d{4})', re.I)
DATUM  = re.compile(r'^\s*Datum:\s*(\d{1,2}\.\s*\w+\s*\d{4})')
DATUM_ANY = re.compile(r'Datum:\s*(\d{1,2}\.\s*\w+\s*\d{4})')
BEREICH= re.compile(r'Hand-?\s*lungsbereich:?\s*(Fuhrparktechnik[^\n]*|Organisation[^\n]*)', re.I)
BEREICH_BARE = re.compile(r'^\s*(Fuhrparktechnik und Fuhrparkmanagement|Organisation und Kommunikation)\s*$', re.I)
ANZAHL = re.compile(r'Anzahl Aufgaben:\s*(\d+)')
AUFG   = re.compile(r'^\s*Aufgabe\s+(\d+)\s*$')
LOES   = re.compile(r'^\s*L[öo]sungshinweise\s+Aufgabe\s+(\d+)', re.I)
PUNKTE = re.compile(r'^\s*.{0,8}?M[öo]glich\w*\s*Punktzahl:\s*(\d+)\s*$', re.I)
VO     = re.compile(r'^\s*\[?\s*VO:\s*(.+?)\s*\]?\s*$')
TEILP  = re.compile(r'\((\d+)\s*Punkte?\)\s*$')     # "(4 Punkte)" am Zeilenende

MON = {'januar':1,'februar':2,'märz':3,'maerz':3,'april':4,'mai':5,'juni':6,
       'juli':7,'august':8,'september':9,'oktober':10,'november':11,'dezember':12}
SAISON_MON = {'frühjahr':5,'fruehjahr':5,'herbst':11}

def clean(line):
    l = line.rstrip()
    # §-Verwechslungen der OCR
    l = re.sub(r'\[VO:\s*[8$]\s*5', '[VO: § 5', l)
    l = re.sub(r'\(\s*[8$]\s*(\d+\s+[A-ZÄÖÜ])', r'(§ \1', l)
    l = re.sub(r'\b8\s*(\d+\s+(?:ArbSchG|ArbZG|StVO|StVZO|BetrVG|EFZG|BGB|HGB|GGVSEB|BKrFQG|Entgeltfortzahlungsgesetz))', r'§ \1', l)
    # OCR-Aufzählungszeichen → Gedankenstrich
    l = re.sub(r'^\s*[=■]\s*_?\s*(?=[A-ZÄÖÜa-zäöü0-9])', '– ', l)
    l = re.sub(r'^\s*m\s+(?=[A-ZÄÖÜ])', '– ', l)
    l = re.sub(r'\s{2,}', ' ', l)
    return l.strip()

def load(path):
    """→ Liste (seite, zeile), Seitenmarker und reine Seitenzahlen entfernt."""
    out, page = [], 0
    for raw in open(path, encoding='utf-8').read().split('\n'):
        m = PAGE.match(raw)
        if m: page = int(m.group(1)); continue
        if raw.startswith('#'):  # Kopfkommentar der Quelle
            continue
        l = clean(raw)
        if re.fullmatch(r'\d{1,3}', l or ''):   # Seitenzahl-Zeile
            continue
        out.append((page, l))
    return out

def join_para(lines):
    """Zeilen zu Absätzen; Silbentrennung am Zeilenende auflösen; Bullets trennen."""
    out, buf = [], ''
    for l in lines:
        if not l:
            if buf: out.append(buf.strip()); buf = ''
            continue
        if l.startswith('– '):
            if buf: out.append(buf.strip()); buf = ''
            out.append(l); continue
        if buf.endswith('-') and not buf.endswith('--'):
            buf = buf[:-1] + l
        else:
            buf = (buf + ' ' + l).strip() if buf else l
    if buf: out.append(buf.strip())
    return [p for p in out if p]

def extract_vo(intro):
    """Findet die [VO: …]-Bezüge im Kopf eines Lösungsblocks. Die OCR liest das
    Paragrafenzeichen § je nach Seite als 8, $, & oder S; mehrere Bezüge stehen
    teils in getrennten [ ]-Klammern."""
    refs = []
    for para in intro:
        # §-Varianten vor "<Zahl> Absatz" vereinheitlichen
        p = re.sub(r'(?:§|&|8|\$|S)\s+(\d+\s+Absatz)', r'§ \1', para)
        for m in re.finditer(r'VO:\s*(?:§\s*)?(\d+\s+Absatz[^\[\]]*?)(?=\s*(?:\]|VO:|$))', p):
            r = '§ ' + re.sub(r'\s{2,}', ' ', m.group(1)).strip(' ;.,')
            if r not in refs:
                refs.append(r)
    return ' · '.join(refs)

def split_teile(block, want_solution):
    """Zerlegt einen Aufgaben- oder Lösungsblock an 'Mögliche Punktzahl'-Zeilen.
    block: Liste roher (bereits gereinigter) Textzeilen ohne die Marker-Zeile.
    """
    txt = [l for _, l in block]
    pidx = [i for i, l in enumerate(txt) if PUNKTE.match(l)]
    intro = join_para(txt[:pidx[0]]) if pidx else join_para(txt)
    teile = []
    for j, pi in enumerate(pidx):
        pe = pidx[j+1] if j+1 < len(pidx) else len(txt)
        pts = int(PUNKTE.match(txt[pi]).group(1))
        seg = txt[pi+1:pe]
        eintrag = {'label': chr(ord('a')+j), 'punkte': pts}
        if want_solution:
            vo = ''
            body = []
            teilp = []
            for l in seg:
                mv = VO.match(l)
                if mv and not body:      # VO steht direkt unter der Punktzahl
                    vo = (vo + ' ' + mv.group(1)).strip() if vo else mv.group(1)
                    continue
                mt = TEILP.search(l)
                if mt:
                    teilp.append(int(mt.group(1)))
                body.append(l)
            eintrag['loesung'] = join_para(body)
            eintrag['vo'] = re.sub(r'\s*VO:\s*', '; ', ('§ '+vo).replace('§ §','§')) if vo else ''
            eintrag['bewertung'] = teilp
        else:
            eintrag['text'] = join_para(seg)
        teile.append(eintrag)
    return intro, teile

def _bnorm(x):
    x = (x or '').lower()
    return 'FT' if x.startswith('fuhr') else ('OK' if x.startswith('org') else None)

def parse_region(region):
    """Region-Slice → Liste Bereichs-Segmente mit Aufgaben und/oder Lösungen.
    Segmente werden an HEADER-Zeilen (Aufgabenstellung 1=FT, 2=OK) getrennt;
    der Bereich stammt aus 'Handlungsbereich:'-, blanken Bereichs- oder – als
    Rückfall – aus der Aufgabenstellungsnummer."""
    marks = []
    for i, (p, l) in enumerate(region):
        if AUFG.match(l):        marks.append((i, 'A', int(AUFG.match(l).group(1))))
        elif LOES.match(l):      marks.append((i, 'L', int(LOES.match(l).group(1))))
        elif HEADER.search(l):   marks.append((i, 'H', int(HEADER.search(l).group(1))))
        elif BEREICH.search(l):  marks.append((i, 'B', _bnorm(BEREICH.search(l).group(1))))
        elif BEREICH_BARE.match(l): marks.append((i, 'B', _bnorm(BEREICH_BARE.match(l).group(1))))
    segs = []
    cur = {'bereich': None, 'stellung': None, 'aufg': {}, 'loes': {}, 'seiten': set()}
    def push():
        nonlocal cur
        if cur['aufg'] or cur['loes']:
            if not cur['bereich'] and cur['stellung']:
                cur['bereich'] = 'FT' if cur['stellung'] == 1 else 'OK'
            segs.append(cur)
            cur = {'bereich': None, 'stellung': None, 'aufg': {}, 'loes': {}, 'seiten': set()}
    for k, (i, typ, val) in enumerate(marks):
        j = marks[k+1][0] if k+1 < len(marks) else len(region)
        body = region[i+1:j]
        if typ == 'H':
            push(); cur['stellung'] = val
        elif typ == 'B':
            if cur['aufg'] or cur['loes']:
                push()
            cur['bereich'] = val or cur['bereich']
        elif typ == 'A':
            intro, teile = split_teile(body, False)
            cur['aufg'][val] = {'nr': val, 'intro': intro, 'teile': teile}
            cur['seiten'].update(p for p,_ in body)
        elif typ == 'L':
            intro, teile = split_teile(body, True)
            vo = extract_vo(intro)
            for t in teile:
                if not t.get('vo'):
                    t['vo'] = vo
            cur['loes'][val] = {'nr': val, 'teile': teile, 'vo': vo}
            cur['seiten'].update(p for p,_ in body)
    push()
    return segs

def parse(path):
    lines = load(path)
    # Top-Level-Grenzen: Frage-Header (HEADER + Datum in Nähe) und SAISON.
    bounds = []
    for i, (p, l) in enumerate(lines):
        if HEADER.search(l):
            near = ' '.join(x for _, x in lines[i:i+12])
            if DATUM_ANY.search(near):
                bounds.append((i, 'Q'))
        if SAISON.match(l):
            bounds.append((i, 'S'))
    bounds.sort()
    # Doppelte an gleicher Zeile: SAISON gewinnt (Booklet-Start)
    seen = {}
    for i, t in bounds:
        seen[i] = 'S' if seen.get(i) == 'S' or t == 'S' else t
    bounds = sorted((i, t) for i, t in seen.items())

    q_exams, s_books = [], []
    for n, (s, typ) in enumerate(bounds):
        e = bounds[n+1][0] if n+1 < len(bounds) else len(lines)
        region = lines[s:e]
        head = ' '.join(x for _, x in region[:14])
        if typ == 'Q':
            ex = {'datum': None, 'bereich': None, 'anzahl': None,
                  'context': [], 'aufgaben': [], 'seiten': (region[0][0], region[-1][0])}
            m = DATUM_ANY.search(head);  ex['datum']  = m.group(1) if m else None
            m = BEREICH.search(head); ex['bereich'] = m.group(1) if m else None
            m = ANZAHL.search(head); ex['anzahl']  = int(m.group(1)) if m else None
            # Ausgangssituation: von "Ausgangssituation" bis erste Aufgabe
            first = next((i for i,(_,l) in enumerate(region) if AUFG.match(l)), len(region))
            cstart = next((i for i,(_,l) in enumerate(region) if re.search(r'Ausgangssituation', l)), None)
            if cstart is not None:
                ex['context'] = join_para([l for _,l in region[cstart+1:first]])
            segs = parse_region(region)
            # In Q-Regionen gibt es genau ein Bereichs-Segment
            seg = segs[0]
            for nr in sorted(seg['aufg']):
                a = seg['aufg'][nr]
                # interleaved Lösung (Epoche 2021–22)
                a['loes'] = seg['loes'].get(nr, {}).get('teile', [])
                ex['aufgaben'].append(a)
            q_exams.append(ex)
        else:  # SAISON-Booklet
            m = SAISON.match(region[0][1])
            saison, jahr = m.group(1).lower(), int(m.group(2))
            for seg in parse_region(region):
                if seg['loes']:
                    s_books.append({'saison': saison, 'jahr': jahr,
                                    'bereich': seg['bereich'], 'loes': seg['loes'],
                                    'seiten': sorted(seg['seiten'])})
    return q_exams, s_books

def bereich_kuerzel(bereich):
    if not bereich: return None
    return 'FT' if bereich.lower().startswith('fuhr') else 'OK'

def datum_teile(datum):
    m = re.match(r'(\d{1,2})\.\s*(\w+)\s*(\d{4})', datum or '')
    if not m: return None
    return int(m.group(3)), MON.get(m.group(2).lower(), 0), int(m.group(1))

def pair(q_exams, s_books):
    """Lösungs-Booklets den Frage-Prüfungen zuordnen (Epoche ab 2023)."""
    for ex in q_exams:
        kb = bereich_kuerzel(ex['bereich'])
        dt = datum_teile(ex['datum'])
        if not dt: continue
        jahr, monat, _ = dt
        # schon interleaved gelöst?
        if all(a.get('loes') for a in ex['aufgaben']):
            continue
        for b in s_books:
            if b['bereich'] != kb: continue
            if b['jahr'] != jahr: continue
            if SAISON_MON.get(b['saison']) != monat: continue
            for a in ex['aufgaben']:
                if not a.get('loes') and a['nr'] in b['loes']:
                    a['loes'] = b['loes'][a['nr']]['teile']
            b['_used'] = True
    return q_exams

def validate(q_exams):
    print(f"{'Datum':<20} {'B':<3} {'Aufg':>4} {'Teile':>5} {'Pkt':>4} {'Lös':>4} {'LösPkt':>6}  Status")
    komplett = 0
    for ex in sorted(q_exams, key=lambda e:(datum_teile(e['datum']) or (0,0,0))):
        kb = bereich_kuerzel(ex['bereich']) or '??'
        teile = [t for a in ex['aufgaben'] for t in a['teile']]
        pkt = sum(t['punkte'] for t in teile)
        loes = [t for a in ex['aufgaben'] for t in (a.get('loes') or [])]
        lpkt = sum(t['punkte'] for t in loes)
        flags = []
        if pkt != 100: flags.append(f'Pkt={pkt}')
        if ex['anzahl'] and len(ex['aufgaben']) != ex['anzahl']: flags.append(f'Aufg {len(ex["aufgaben"])}/{ex["anzahl"]}')
        if len(loes) != len(teile): flags.append(f'Lös {len(loes)}/{len(teile)}')
        elif lpkt != pkt: flags.append(f'LösPkt={lpkt}')
        ok = not flags
        if ok: komplett += 1
        print(f"{str(ex['datum']):<20} {kb:<3} {len(ex['aufgaben']):>4} {len(teile):>5} {pkt:>4} {len(loes):>4} {lpkt:>6}  " + ('✓ KOMPLETT' if ok else '; '.join(flags)))
    print(f"\nPrüfungen: {len(q_exams)}  ·  komplett (100 P, alle Lösungen): {komplett}")

if __name__ == '__main__':
    src = sys.argv[1] if len(sys.argv) > 1 else 'scripts/pruefungen/quellen/ihk-pruefungen-2021-2026-mit-loesungshinweisen.ocr.txt'
    q, s = parse(src)
    pair(q, s)
    validate(q)
    out = sys.argv[2] if len(sys.argv) > 2 else '/tmp/claude-0/-home-user-KVM-Lernapp/18c82506-7a2e-5120-be94-e46076986fc4/scratchpad/exams_amtlich.json'
    json.dump(q, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('geschrieben:', out)
