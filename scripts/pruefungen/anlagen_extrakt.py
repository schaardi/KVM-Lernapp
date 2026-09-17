# -*- coding: utf-8 -*-
"""Abbildungen aus einem Prüfungsheft holen – ohne Zuschneiden.

Die Hefte der Basisqualifikationen setzen ihre Abbildungen als **eingebettete
Bilder**. Die lassen sich direkt herausziehen (``pdfimages``), statt eine
gerenderte Seite auf Verdacht zuzuschneiden wie in ``anlagen_bau.py``: keine
Koordinaten, keine Ränder, volle Auflösung.

Weggefiltert werden:

* Seitendeko – dasselbe Bild auf drei oder mehr Seiten (Wasserzeichen, Logo),
* Winzlinge unter ``MIN_KANTE`` Pixeln (Aufzählungszeichen, Formelfragmente),
* Transparenzmasken (``smask``), die ``pdfimages`` gesondert listet.

    python3 scripts/pruefungen/anlagen_extrakt.py <heft.pdf> [-o ausgabe/]

Die Ausgabe nennt je Bild Seite, Maße und Dateiname. Welche Abbildung zu
welcher Aufgabe gehört, entscheidet ein Blick auf die Bilder und den Textlayer
(die Seitenmarker dort passen zu den Seitenzahlen hier); die Zuordnung landet
in ``anlagen_imbq.py``.
"""
import argparse
import html
import os
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

MIN_KANTE = 140      # Pixel – darunter ist es Deko, kein Schaubild
DEKO_SEITEN = 3      # ab so vielen Seiten mit gleichem Bild: Wasserzeichen
MASS_TOLERANZ = 3    # Pixel; dasselbe Wasserzeichen wird mal 594, mal 595 breit


def liste(pdf):
    """Zeilen von ``pdfimages -list`` als dicts."""
    out = subprocess.run(['pdfimages', '-list', pdf],
                         capture_output=True, text=True).stdout.splitlines()
    bilder = []
    for z in out[2:]:
        t = z.split()
        if len(t) < 5 or not t[0].isdigit():
            continue
        bilder.append({'seite': int(t[0]), 'num': int(t[1]), 'typ': t[2],
                       'breite': int(t[3]), 'hoehe': int(t[4])})
    return bilder


def _aehnlich(a, b):
    return (abs(a[0] - b[0]) <= MASS_TOLERANZ and abs(a[1] - b[1]) <= MASS_TOLERANZ)


def auswaehlen(bilder):
    """Seitendeko, Masken und Winzlinge aussortieren."""
    echte = [b for b in bilder if b['typ'] == 'image']
    seiten = {}
    for b in echte:
        mass = (b['breite'], b['hoehe'])
        passend = next((k for k in seiten if _aehnlich(k, mass)), mass)
        seiten.setdefault(passend, set()).add(b['seite'])
    gewollt = []
    for b in echte:
        if min(b['breite'], b['hoehe']) < MIN_KANTE:
            continue
        mass = (b['breite'], b['hoehe'])
        passend = next((k for k in seiten if _aehnlich(k, mass)), mass)
        if len(seiten[passend]) >= DEKO_SEITEN:
            continue
        gewollt.append(b)
    return gewollt


def holen(pdf, ziel, praefix):
    os.makedirs(ziel, exist_ok=True)
    gewollt = auswaehlen(liste(pdf))
    ergebnis = []
    with tempfile.TemporaryDirectory() as tmp:
        for b in gewollt:
            stamm = os.path.join(tmp, 's%02d' % b['seite'])
            subprocess.run(['pdfimages', '-png', '-p',
                            '-f', str(b['seite']), '-l', str(b['seite']), pdf, stamm],
                           capture_output=True)
        from PIL import Image
        gesehen = set()
        for name in sorted(os.listdir(tmp)):
            if not name.endswith('.png'):
                continue
            pfad = os.path.join(tmp, name)
            with Image.open(pfad) as img:
                breite, hoehe = img.width, img.height
                # Transparenzmasken kommen als eigene Graustufendatei derselben
                # Größe. Sie dürfen das echte Bild nicht überschreiben, also
                # bekommt jede Datei ihren eigenen Namen.
                graustufen = img.mode in ('L', '1')
            if not any(b['breite'] == breite and b['hoehe'] == hoehe for b in gewollt):
                continue
            inhalt = open(pfad, 'rb').read()
            if inhalt in gesehen:
                continue
            gesehen.add(inhalt)
            seite, lauf = (int(x) for x in re.search(r's(\d+)-(\d+)', name).groups())
            ziel_name = '%s-s%02d-%02d-%dx%d%s.png' % (
                praefix, seite, lauf, breite, hoehe, '-maske' if graustufen else '')
            shutil.copyfile(pfad, os.path.join(ziel, ziel_name))
            ergebnis.append((seite, breite, hoehe, ziel_name))
    # je Seite in Lesereihenfolge
    ergebnis.sort()
    return ergebnis


# ---------------------------------------------------------------------------
# Gezeichnete Abbildungen: über der Bildunterschrift ausschneiden
# ---------------------------------------------------------------------------
BESCHRIFTUNG = re.compile(r'^\s*(Abbildung|Anlage)\s+\d+', re.I)
# "Anlage 1 zu Aufgabe 7" ist eine Überschrift: das Formular steht **darunter**.
# "Abbildung 3: Schaltbild" ist eine Bildunterschrift: die Grafik steht darüber.
UEBERSCHRIFT = re.compile(r'^\s*Anlage\s+\d+\s+zu\s+Aufgabe', re.I)
FUSS = re.compile(r'^\s*(Seite\s+\d+|[LP]\s*\d{3}-\d{2}-\d{4}.*)$', re.I)
RENDER_DPI = 220
RAND = 6            # Punkte Luft um den Ausschnitt
MAX_ZEILENHOEHE = 40  # Punkte; darüber ist die Zeile gedreht (Randwasserzeichen)


def zeilen_mit_kasten(pdf, seite):
    """Textzeilen einer Seite mit ihrem Rahmen (in PDF-Punkten)."""
    roh = subprocess.run(['pdftotext', '-bbox-layout', '-f', str(seite), '-l', str(seite),
                          pdf, '-'], capture_output=True, text=True).stdout
    try:
        baum = ET.fromstring(roh)
    except ET.ParseError:
        return [], (595.0, 842.0)
    ns = {'x': baum.tag.split('}')[0].strip('{')} if '}' in baum.tag else {}
    def finde(el, name):
        return el.iter('{%s}%s' % (ns['x'], name)) if ns else el.iter(name)
    seiten = list(finde(baum, 'page'))
    if not seiten:
        return [], (595.0, 842.0)
    p = seiten[0]
    masse = (float(p.get('width')), float(p.get('height')))
    zeilen = []
    for z in finde(p, 'line'):
        text = ' '.join((w.text or '') for w in finde(z, 'word')).strip()
        if not text:
            continue
        zeilen.append({'text': html.unescape(text),
                       'y0': float(z.get('yMin')), 'y1': float(z.get('yMax')),
                       'x0': float(z.get('xMin')), 'x1': float(z.get('xMax'))})
    zeilen.sort(key=lambda z: z['y0'])
    return zeilen, masse


def _fliesstext(z, links):
    """Zeile gehört zum Fließtext – nicht zur Beschriftung einer Grafik.

    Achsenbeschriftungen ("400", "Temperatur in °C") und Bemaßungen stehen als
    Textzeilen **im** Bild. Nähme man sie als obere Grenze, bliebe vom Diagramm
    nur ein Streifen. Fließtext erkennt man daran, dass er am linken Satzspiegel
    beginnt und eine gewisse Länge hat.
    """
    return z['x0'] <= links + 4 and len(z['text']) >= 25


def bereiche(pdf, seite):
    """Je Bildunterschrift den Bereich darüber – (Titel, Kasten in Punkten)."""
    alle, (bw, bh) = zeilen_mit_kasten(pdf, seite)
    # Das Wasserzeichen "Im Fall der Zuwiderhandlung …" steht gedreht im
    # Seitenrand und erstreckt sich über die halbe Seitenhöhe. Als Textzeile
    # gezählt, verschiebt es den Satzspiegel und schneidet jedes Bild ab.
    zeilen = [z for z in alle if z['y1'] - z['y0'] <= MAX_ZEILENHOEHE]
    if not zeilen:
        return []
    # Satzspiegel = häufigster linker Rand, nicht der kleinste: Kopfzeilen und
    # eingerückte Beschriftungen beginnen woanders.
    haeufig = {}
    for z in zeilen:
        haeufig[round(z['x0'])] = haeufig.get(round(z['x0']), 0) + 1
    links = max(haeufig, key=lambda k: (haeufig[k], -k))
    gefunden = []
    for i, z in enumerate(zeilen):
        if not BESCHRIFTUNG.match(z['text']) or UEBERSCHRIFT.match(z['text']):
            continue
        # nach oben bis zur letzten Zeile Fließtext; Beschriftungen im Bild
        # werden übersprungen.
        oben = 60.0
        for vor in reversed(zeilen[:i]):
            if vor['y1'] >= z['y0'] - 4:
                continue
            if BESCHRIFTUNG.match(vor['text']) or not _fliesstext(vor, links):
                continue
            oben = vor['y1']
            break
        if z['y0'] - oben < 40:      # kein Platz für ein Bild
            continue
        gefunden.append((z['text'], (40.0, oben + RAND, bw - 40.0, z['y0'] - 2)))

    for i, z in enumerate(zeilen):
        if not UEBERSCHRIFT.match(z['text']):
            continue
        # nach unten bis zur Fußzeile bzw. zur nächsten Zeile Fließtext
        unten = bh - 40.0
        for nach in zeilen[i + 1:]:
            if nach['y0'] <= z['y1'] + 2:
                continue
            if FUSS.match(nach['text']) or _fliesstext(nach, links):
                unten = nach['y0'] - 2
                break
        if unten - z['y1'] < 40:
            continue
        gefunden.append((z['text'], (40.0, z['y1'] + RAND, bw - 40.0, unten)))
    return gefunden


def schneiden(pdf, seite, kasten, ziel):
    """Seite rendern und den Bereich ausschneiden (Punkte -> Pixel)."""
    from PIL import Image
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from anlagen_bau import trimmen
    with tempfile.TemporaryDirectory() as tmp:
        stamm = os.path.join(tmp, 'seite')
        subprocess.run(['pdftoppm', '-png', '-r', str(RENDER_DPI),
                        '-f', str(seite), '-l', str(seite), pdf, stamm],
                       capture_output=True)
        bilder = [f for f in os.listdir(tmp) if f.endswith('.png')]
        if not bilder:
            return None
        f = RENDER_DPI / 72.0
        with Image.open(os.path.join(tmp, bilder[0])) as img:
            x0, y0, x1, y1 = (int(v * f) for v in kasten)
            aus = trimmen(img.crop((x0, y0, min(x1, img.width), min(y1, img.height))))
            if aus.width < 60 or aus.height < 40:
                return None
            aus.save(ziel)
    return ziel


def gezeichnete(pdf, ziel, praefix, seiten=None):
    """Alle Abbildungen mit Bildunterschrift ausschneiden."""
    os.makedirs(ziel, exist_ok=True)
    anzahl = int(subprocess.run(['pdfinfo', pdf], capture_output=True, text=True)
                 .stdout.split('Pages:')[1].split()[0])
    raus = []
    for seite in (seiten or range(1, anzahl + 1)):
        for titel, kasten in bereiche(pdf, seite):
            name = '%s-s%02d-%s.png' % (praefix, seite,
                                        re.sub(r'[^a-z0-9]+', '-', titel.lower())[:40].strip('-'))
            pfad = schneiden(pdf, seite, kasten, os.path.join(ziel, name))
            if pfad:
                raus.append((seite, titel, os.path.basename(pfad)))
    return raus


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('pdf')
    ap.add_argument('-o', '--out', default='anlagen-roh')
    ap.add_argument('-p', '--praefix', default=None,
                    help='Namenspräfix (Standard: aus dem Dateinamen)')
    ap.add_argument('--gezeichnet', action='store_true',
                    help='statt eingebetteter Bilder den Bereich über jeder '
                         'Bildunterschrift ausschneiden (für Zeichnungen)')
    a = ap.parse_args(argv)
    praefix = a.praefix or re.sub(r'[^a-z0-9]+', '-',
                                  os.path.splitext(os.path.basename(a.pdf))[0].lower()).strip('-')
    if a.gezeichnet:
        raus = gezeichnete(a.pdf, a.out, praefix)
        if not raus:
            print('Keine Bildunterschriften mit Platz darüber gefunden.')
            return 1
        print('%d Ausschnitte aus %s:' % (len(raus), os.path.basename(a.pdf)))
        for seite, titel, name in raus:
            print('  Seite %2d  %-46s %s' % (seite, titel[:46], name))
        return 0

    gefunden = holen(a.pdf, a.out, praefix)
    if not gefunden:
        print('Keine eingebetteten Abbildungen gefunden – mit --gezeichnet erneut versuchen.')
        return 1
    print('%d Abbildungen aus %s:' % (len(gefunden), os.path.basename(a.pdf)))
    for seite, b, h, name in gefunden:
        print('  Seite %2d  %4dx%-4d  %s' % (seite, b, h, name))
    return 0


if __name__ == '__main__':
    sys.exit(main())
