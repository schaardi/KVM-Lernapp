# -*- coding: utf-8 -*-
"""Inventar eines Ordners voller IHK-Prüfungs-PDFs.

Liest je PDF Seitenzahl, Textlayer, Kopfdaten (Prüfungsfach, Datum, Anzahl
Aufgaben), zählt Punkte-Badges und Lösungshinweise und ordnet die Datei einer
Verarbeitungsklasse zu. Scans (kein Textlayer) werden für den Kopf auf den
ersten Seiten per Tesseract gelesen (deutsch), das OCR-Ergebnis wird im
Cache-Ordner abgelegt.

Aufruf:
    python3 scripts/pruefungen/inventar.py <pdf-ordner> [--ocr-cache DIR]
                                            [--md AUSGABE.md] [--json AUSGABE.json]

Benötigt poppler-utils (pdfinfo, pdftotext, pdftoppm) und für Scans
tesseract-ocr + tesseract-ocr-deu.
"""
import argparse, json, os, re, subprocess, sys, tempfile

# Prüfungsfächer der Basisqualifikationen (Kürzel wie in parse_imbq.py) und
# Handlungsbereiche des Meisters für Kraftverkehr (wie in build_amtlich.py).
BEREICHE = [
    ('RE', 'Rechtsbewusstes Handeln', r'Rechtsbewusstes\s+Handeln'),
    ('BW', 'Betriebswirtschaftliches Handeln', r'Betriebswirtschaftliches\s+Handeln'),
    ('MI', 'Methoden der Information, Kommunikation und Planung',
     r'Methoden\s+der\s+Information,?\s+Kommunikation\s+und\s+Planung'),
    ('ZI', 'Zusammenarbeit im Betrieb', r'Zusammenarbeit\s+im\s+Betrieb'),
    ('NT', 'Naturwissenschaftliche und technische Gesetzmäßigkeiten',
     r'naturwissenschaftlicher?\s+und\s+technischer?\s+Gesetzm'),
    ('FT', 'Fuhrparktechnik und Fuhrparkmanagement', r'Fuhrparktechnik'),
    ('OK', 'Organisation und Kommunikation', r'Organisation\s+und\s+Kommunikation'),
]
# Kürzel im Dateinamen des Archivs ("BWH 2019 Mai.pdf")
DATEINAME_KUERZEL = {'RBH': 'RE', 'BWH': 'BW', 'MIKP': 'MI', 'ZIB': 'ZI', 'NTG': 'NT'}
MONATE = {'januar': 1, 'februar': 2, 'märz': 3, 'april': 4, 'mai': 5, 'juni': 6,
          'juli': 7, 'august': 8, 'september': 9, 'oktober': 10,
          'november': 11, 'dezember': 12}
# Neuere Hefte: "Datum: 3. Mai 2024" – ältere (bis 2018): "Prüfungstag 13. November 2014"
DATUM = re.compile(r'(?:Datum|Pr[üu]fungstag):?\s*(\d{1,2})\.?\s*([A-Za-zäöüÄÖÜ]+)\s*(\d{4})')
ANZAHL = re.compile(r'Anzahl\s+(?:der\s+)?Aufgaben:?\s*(\d+)')
BADGE = re.compile(r'M[öo]gliche\s+Punktzahl')
LOESUNG = re.compile(r'L[öo]sungshinweise?\s+(?:zu\s+)?Aufgabe\s+\d+')
DECKBLATT_L = re.compile(r'^\s*L[öo]sungshinweise\s*$', re.M)
HEFT = re.compile(r'\b([PL])\s?(\d{3}-\d{2}-\d{4}(?:-\d)?)\b')
AUFGABE = re.compile(r'^\s*Aufgabe\s+(\d+)\s*$', re.M)

# Weniger als so viele Zeichen je Seite: kein brauchbarer Textlayer.
SCAN_SCHWELLE = 200


def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def seiten(pdf):
    out = run(['pdfinfo', pdf]).stdout
    m = re.search(r'^Pages:\s+(\d+)', out, re.M)
    return int(m.group(1)) if m else 0


def erzeuger(pdf):
    """Producer/Creator aus den PDF-Metadaten – verrät Scans (PDF24, Kopierer)
    und nachträglich per Fremd-OCR unterlegte Textlayer."""
    out = run(['pdfinfo', pdf]).stdout
    m = re.search(r'^Producer:\s+(.+)$', out, re.M)
    c = re.search(r'^Creator:\s+(.+)$', out, re.M)
    teile = [x.group(1).strip() for x in (c, m) if x]
    return ' / '.join(dict.fromkeys(teile))


def bildanzahl(pdf):
    """Eingebettete Bilder (ohne Seitenscans): Hinweis auf Abbildungen/Anlagen."""
    out = run(['pdfimages', '-list', pdf]).stdout.splitlines()
    return max(0, len(out) - 2)


def textlayer(pdf):
    """Kompletter Textlayer, Seiten getrennt durch \\f."""
    return run(['pdftotext', '-layout', pdf, '-']).stdout


def ocr_seiten(pdf, erste, letzte, cache):
    """OCR der Seiten erste..letzte (1-basiert), Ergebnis aus dem Cache.

    Tesseract läuft mit ``--psm 3`` (automatische Seitenaufteilung) und einem
    Thread: ``--psm 4`` verbeißt sich minutenlang in die grafischen Deckblätter
    der IHK-Hefte, und mehrere OpenMP-Threads bringen bei Einzelseiten nichts.
    """
    os.makedirs(cache, exist_ok=True)
    stamm = re.sub(r'[^A-Za-z0-9]+', '_', os.path.basename(pdf))
    umgebung = dict(os.environ, OMP_THREAD_LIMIT='1')
    texte = []
    for s in range(erste, letzte + 1):
        ziel = os.path.join(cache, '%s-p%02d.txt' % (stamm, s))
        if not os.path.exists(ziel) or os.path.getsize(ziel) == 0:
            with tempfile.TemporaryDirectory() as tmp:
                png = os.path.join(tmp, 'seite')
                run(['pdftoppm', '-f', str(s), '-l', str(s), '-r', '200', '-gray',
                     '-png', pdf, png])
                bilder = sorted(f for f in os.listdir(tmp) if f.endswith('.png'))
                if not bilder:
                    open(ziel, 'w').close()
                else:
                    try:
                        run(['tesseract', os.path.join(tmp, bilder[0]), ziel[:-4],
                             '-l', 'deu', '--psm', '3'], env=umgebung, timeout=120)
                    except subprocess.TimeoutExpired:
                        print('OCR-Zeitlimit: %s Seite %d' % (pdf, s), file=sys.stderr)
                        open(ziel, 'w').close()
        texte.append(open(ziel, encoding='utf-8', errors='replace').read())
    return '\f'.join(texte)


def bereich_von(text):
    for kz, name, muster in BEREICHE:
        if re.search(muster, text, re.I):
            return kz, name
    return None, None


def datum_von(text):
    m = DATUM.search(text)
    if not m:
        return None, None
    tag, monat, jahr = int(m.group(1)), m.group(2).lower(), int(m.group(3))
    mon = MONATE.get(monat)
    iso = '%04d%02d%02d' % (jahr, mon, tag) if mon else None
    return '%d. %s %d' % (tag, m.group(2), jahr), iso


LOESUNG_ALT = re.compile(r'L[öo]sungshinweise?\s+(?:zu\s+)?Aufgabe\s+\d+\s*\(\d+\s*Punkte?\)')


def heftformat(text, hefte):
    """Aufbau des Hefts – bestimmt den Parser.

    PL    Prüfungsheft (P-Nummer) und Lösungsheft (L-Nummer) hintereinander,
          Lösungsteil beginnt mit einer Zeile "Lösungshinweise" (Format H2024/H2025,
          parse_imbq.py).
    L-I   Nur Lösungsheft, Aufgabe N und "Lösungshinweise Aufgabe N" wechseln
          sich ab; Punkte-Badges "a Mögliche Punktzahl: n" in beiden Teilen.
    L-ALT Nur Lösungsheft, Überschrift "Lösungshinweise Aufgabe N (n Punkte)",
          Teilpunkte im Text (Hefte bis etwa 2018).
    """
    codes = {h[0] for h in hefte}
    if LOESUNG_ALT.search(text):
        return 'L-ALT'
    if 'P' in codes and 'L' in codes:
        return 'PL'
    if LOESUNG.search(text) and BADGE.search(text):
        return 'L-I'
    if BADGE.search(text):
        return 'P'
    return '?'


def klassifiziere(e):
    """Verarbeitungsklasse, siehe docs/PLAN-altklausuren-und-aufgabenblatt.md (A1)."""
    if e['sammelband']:
        return 'S', 'Sammelband (mehrere Prüfungen in einer Datei)'
    if e['scan']:
        if e['loesungen_deckblatt']:
            return 'K3-L', 'Scan der Lösungshinweise – OCR nötig'
        return 'K3', 'Scan – OCR nötig'
    if e['loesungen'] >= max(1, e['aufgaben_max'] - 1):
        return 'K1', 'Textlayer mit Lösungshinweisen'
    if e['loesungen'] == 0:
        return 'K4', 'Textlayer ohne Lösungshinweise'
    return 'K1?', 'Textlayer, Lösungshinweise unvollständig (%d von %d Aufgaben)' % (
        e['loesungen'], e['aufgaben_max'])


def inventar_datei(pdf, wurzel, cache):
    rel = os.path.relpath(pdf, wurzel)
    n = seiten(pdf)
    text = textlayer(pdf)
    zeichen = len(text.strip())
    scan = n > 0 and zeichen / n < SCAN_SCHWELLE
    kopf = text
    if scan:
        kopf = ocr_seiten(pdf, 1, min(2, n), cache)
    kz, bereich = bereich_von(kopf)
    datum, iso = datum_von(kopf)
    anz = ANZAHL.search(kopf)
    hefte = sorted(set(HEFT.findall(text if not scan else kopf)))
    e = {
        'datei': rel,
        'bytes': os.path.getsize(pdf),
        'seiten': n,
        'zeichen_je_seite': round(zeichen / n) if n else 0,
        'scan': scan,
        'kuerzel': kz, 'bereich': bereich,
        'datum': datum, 'iso': iso,
        'anzahl_aufgaben': int(anz.group(1)) if anz else None,
        'badges': len(BADGE.findall(text)) if not scan else None,
        'loesungen': len(LOESUNG.findall(text)) if not scan else None,
        'loesungen_deckblatt': bool(DECKBLATT_L.search(kopf)),
        'aufgaben_max': max([int(x) for x in AUFGABE.findall(text)] or [0]) if not scan else 0,
        'hefte': ['%s %s' % h for h in hefte],
        'format': heftformat(text, hefte) if not scan else heftformat(kopf, hefte),
        'erzeuger': erzeuger(pdf),
        'bilder': bildanzahl(pdf),
        # Sammelband: viele Seiten und mehrere Prüfungsfächer bzw. mehrere Datum-Zeilen
        'sammelband': False,
    }
    if not scan:
        faecher = {k for k, _, m in BEREICHE if re.search(m, text, re.I)}
        e['sammelband'] = len(faecher) >= 3 or len(DATUM.findall(text)) >= 4
    else:
        e['sammelband'] = n >= 40
    if e['scan']:
        e['loesungen'] = None
    e['klasse'], e['klasse_text'] = klassifiziere(e)
    if e['kuerzel'] and e['iso']:
        e['fall_id'] = 'P-%s-%s' % (e['kuerzel'], e['iso'])
    else:
        e['fall_id'] = None
    # Dateiname gegen Inhalt: "MIKP 2023 November.pdf" enthielt tatsächlich die
    # ZiB-Prüfung – so etwas soll auffallen, bevor es als falsches Fach eingespielt wird.
    dn = os.path.basename(pdf).split()[0].upper()
    dn_kz = DATEINAME_KUERZEL.get(dn)
    e['dateiname_kuerzel'] = dn_kz
    e['hinweis'] = ''
    if dn_kz and e['kuerzel'] and dn_kz != e['kuerzel']:
        e['hinweis'] = 'Dateiname %s, Inhalt %s' % (dn, e['kuerzel'])
    return e


def markdown(eintraege, wurzel):
    z = ['# Inventar `%s`' % os.path.basename(os.path.abspath(wurzel)), '',
         'Erzeugt mit `scripts/pruefungen/inventar.py`. Klassen: **K1** Textlayer '
         'mit Lösungshinweisen · **K1?** Lösungshinweise unvollständig · **K4** ohne '
         'Lösungshinweise · **K3** Scan (OCR nötig) · **K3-L** Scan der '
         'Lösungshinweise · **S** Sammelband.', '',
         '| Datei | Seiten | Zeichen/Seite | Bilder | Fach | Datum | Aufg. | Badges | Lös. | Heft | Format | Klasse | Fall-ID | Erzeuger | Hinweis |',
         '|---|---:|---:|---:|---|---|---:|---:|---:|---|---|---|---|---|---|']
    for e in eintraege:
        z.append('| %s | %d | %s | %d | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |' % (
            e['datei'].replace('|', '\\|'), e['seiten'],
            'Scan' if e['scan'] else e['zeichen_je_seite'], e['bilder'],
            e['kuerzel'] or '?', e['datum'] or '?',
            e['anzahl_aufgaben'] if e['anzahl_aufgaben'] is not None else '?',
            e['badges'] if e['badges'] is not None else '–',
            e['loesungen'] if e['loesungen'] is not None else '–',
            ', '.join(e['hefte']) or '–', e['format'],
            e['klasse'], e['fall_id'] or '?', e['erzeuger'].replace('|', '/'), e['hinweis']))
    klassen = {}
    for e in eintraege:
        klassen[e['klasse']] = klassen.get(e['klasse'], 0) + 1
    z += ['', '## Summen', '']
    for k in sorted(klassen):
        z.append('- **%s**: %d' % (k, klassen[k]))
    return '\n'.join(z) + '\n'


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('ordner')
    ap.add_argument('--ocr-cache', default=None,
                    help='Ordner für OCR-Zwischenergebnisse (Standard: <ordner>/../ocr-cache)')
    ap.add_argument('--md', default=None, help='Markdown-Ausgabe')
    ap.add_argument('--json', default=None, help='JSON-Ausgabe')
    a = ap.parse_args(argv)
    cache = a.ocr_cache or os.path.join(os.path.dirname(os.path.abspath(a.ordner)), 'ocr-cache')
    pdfs = []
    for d, _, fs in os.walk(a.ordner):
        pdfs += [os.path.join(d, f) for f in fs if f.lower().endswith('.pdf')]
    pdfs.sort()
    eintraege = []
    for i, p in enumerate(pdfs, 1):
        e = inventar_datei(p, a.ordner, cache)
        eintraege.append(e)
        print('%3d/%d %-6s %-22s %-12s %s' % (i, len(pdfs), e['klasse'], e['fall_id'] or '?',
                                             e['kuerzel'] or '?', e['datei']), file=sys.stderr)
    if a.json:
        with open(a.json, 'w', encoding='utf-8') as f:
            json.dump(eintraege, f, ensure_ascii=False, indent=1)
    md = markdown(eintraege, a.ordner)
    if a.md:
        with open(a.md, 'w', encoding='utf-8') as f:
            f.write(md)
    else:
        sys.stdout.write(md)
    return 0


if __name__ == '__main__':
    sys.exit(main())
