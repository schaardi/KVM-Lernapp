# -*- coding: utf-8 -*-
"""Textlayer mit Seitenmarkern aus dem Archiv „Altklausuren" erzeugen.

Erwartet den entpackten Ordner (``Altklausuren/BQ <Jahr>/<Mai|November|Herbst>/
<Fach> <Jahr> <Monat>.pdf``) und schreibt je Termin einen Quellordner
``scripts/pruefungen/quellen/imbq-<f|h><jahr>/0N-<fach>.txt`` im Format, das
``parse_imbq.py`` liest (``=== Seite N ===`` vor jeder Seite).

- PDFs mit Textlayer: ``pdftotext -layout``.
- Scans und Fremd-OCR (Erzeuger PDF24/Kopierer, unter 200 Zeichen je Seite
  oder ``--ocr-alle``): ``pdftoppm -r 300 -gray`` + ``tesseract -l deu --psm 3``
  je Seite, ein Thread je Prozess, Zeitlimit je Seite.
- Sammelbände (mehr als 40 Seiten) werden übersprungen – sie enthalten nur die
  fünf Fachhefte desselben Termins noch einmal.

Aufruf:
    python3 scripts/pruefungen/quellen_bau.py <Altklausuren-Ordner> [--nur f2024,h2023]
                                              [--ocr-alle] [--jobs 2]
"""
import argparse, os, re, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
QUELLEN = os.path.join(HERE, 'quellen')
NAMEN = {'RBH': '01-recht.txt', 'BWH': '02-bwl.txt', 'MIKP': '03-methoden.txt',
         'ZIB': '04-zusammenarbeit.txt', 'NTG': '05-ntg.txt'}
SAISON = {'mai': 'f', 'november': 'h', 'herbst': 'h', 'frühjahr': 'f'}
SCAN_SCHWELLE = 200
# Erzeuger, deren Textlayer eine nachträgliche Fremd-OCR ist (Struktur unbrauchbar:
# die RBH-Hefte 2014–2017 wurden mit „PDF24 Tools - OCR" unterlegt). „PDF24" und
# „PDF24 Creator" allein sind dagegen nur umgewandelte Word-PDFs mit sauberem Text.
FREMD_OCR = re.compile(r'PDF24 Tools - OCR', re.I)


def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def pdfinfo(pdf):
    out = run(['pdfinfo', pdf]).stdout
    n = re.search(r'^Pages:\s+(\d+)', out, re.M)
    p = re.search(r'^(?:Producer|Creator):\s+(.+)$', out, re.M)
    return (int(n.group(1)) if n else 0), (p.group(1) if p else '')


def seiten_text(pdf):
    txt = run(['pdftotext', '-layout', pdf, '-']).stdout
    return txt.split('\f')


def ocr_seite(pdf, nr):
    umgebung = dict(os.environ, OMP_THREAD_LIMIT='1')
    with tempfile.TemporaryDirectory() as tmp:
        run(['pdftoppm', '-f', str(nr), '-l', str(nr), '-r', '300', '-gray', '-png',
             pdf, os.path.join(tmp, 's')])
        bilder = [f for f in os.listdir(tmp) if f.endswith('.png')]
        if not bilder:
            return ''
        try:
            r = run(['tesseract', os.path.join(tmp, bilder[0]), 'stdout', '-l', 'deu',
                     '--psm', '3'], env=umgebung, timeout=180)
            return r.stdout
        except subprocess.TimeoutExpired:
            print('  OCR-Zeitlimit: %s Seite %d' % (pdf, nr), file=sys.stderr)
            return ''


def termin_von(pfad):
    """'BQ 2019/November' -> 'h2019'."""
    m = re.search(r'BQ\s+(\d{4})[/\\]([A-Za-zäöüÄÖÜ]+)', pfad)
    if not m:
        return None
    s = SAISON.get(m.group(2).lower())
    return (s + m.group(1)) if s else None


# Prüfungsfach laut Heftkopf – der Dateiname des Archivs stimmt nicht immer
# ("MIKP 2023 November.pdf" enthält die ZiB-Prüfung).
FACH_IM_TEXT = [
    ('RBH', r'Rechtsbewusstes\s+Handeln'), ('BWH', r'Betriebswirtschaftliches\s+Handeln'),
    ('MIKP', r'Methoden\s+der\s+Information,?\s+Kommunikation\s+und\s+Planung'),
    ('ZIB', r'Zusammenarbeit\s+im\s+Betrieb'),
    ('NTG', r'naturwissenschaftlicher?\s+und\s+technischer?\s+Gesetzm'),
]


def fach_im_text(text):
    for kz, muster in FACH_IM_TEXT:
        if re.search(muster, text, re.I):
            return kz
    return None


def baue(pdf, ziel, ocr_alle, jobs, kz):
    n, erzeuger = pdfinfo(pdf)
    seiten = seiten_text(pdf)
    zeichen = sum(len(s.strip()) for s in seiten)
    scan = n and zeichen / n < SCAN_SCHWELLE
    fremd = bool(FREMD_OCR.search(erzeuger))
    art = 'Textlayer'
    if scan or ocr_alle or fremd:
        art = 'OCR (%s)' % ('Scan' if scan else 'Fremd-OCR' if fremd else 'erzwungen')
        with ThreadPoolExecutor(max_workers=jobs) as ex:
            seiten = list(ex.map(lambda i: ocr_seite(pdf, i), range(1, n + 1)))
    out = ''.join('=== Seite %d ===\n%s\n' % (i + 1, s) for i, s in enumerate(seiten) if s.strip())
    gefunden = fach_im_text(out[:6000])
    if gefunden and gefunden != kz:
        return 'ÜBERSPRUNGEN: Dateiname %s, Inhalt %s' % (kz, gefunden), n, 0
    os.makedirs(os.path.dirname(ziel), exist_ok=True)
    with open(ziel, 'w', encoding='utf-8') as f:
        f.write(out)
    return art, n, len(out)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('ordner')
    ap.add_argument('--nur', default='', help='Termine, kommagetrennt (z. B. f2024,h2023)')
    ap.add_argument('--ocr-alle', action='store_true', help='auch Textlayer-PDFs per OCR lesen')
    ap.add_argument('--jobs', type=int, default=2, help='parallele OCR-Seiten')
    ap.add_argument('--ziel', default=QUELLEN, help='Zielordner (Standard: scripts/pruefungen/quellen)')
    a = ap.parse_args(argv)
    nur = {t.strip() for t in a.nur.split(',') if t.strip()}
    auftraege = []
    for d, _, fs in os.walk(a.ordner):
        for f in sorted(fs):
            if not f.lower().endswith('.pdf'):
                continue
            kz = f.split()[0]
            if kz not in NAMEN:
                continue                      # Sammelband o. Ä.
            termin = termin_von(os.path.join(d, f))
            if not termin or (nur and termin not in nur):
                continue
            auftraege.append((termin, kz, os.path.join(d, f)))
    auftraege.sort(reverse=True)              # neueste zuerst
    for termin, kz, pdf in auftraege:
        ziel = os.path.join(a.ziel, 'imbq-' + termin, NAMEN[kz])
        art, n, groesse = baue(pdf, ziel, a.ocr_alle, a.jobs, kz)
        print('%-6s %-5s %-10s %3d Seiten %7d Zeichen  %s' % (termin, kz, art, n, groesse,
                                                            os.path.relpath(ziel, a.ziel)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
