# -*- coding: utf-8 -*-
"""Schneidet die Abbildungen der Prüfungen aus den PDFs und legt sie als JPEG ab.

Die Prüfungs-PDFs liegen bewusst nicht im Repository (DIHK-Hinweis auf dem
Deckblatt). Dieses Skript bekommt das Verzeichnis der PDFs übergeben und
erzeugt daraus die Bildanlagen unter ``anlagen/``; eingecheckt werden nur die
fertigen Ausschnitte.

Die Ausschnitte sind in Punkten einer bei 100 dpi gerenderten Seite angegeben
(x, y, Breite, Höhe) – so, wie man sie an einer Seitenvorschau abliest.

    python3 scripts/pruefungen/anlagen_bau.py <pdf-verzeichnis> [schlüssel …]
"""
import os
import subprocess
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ZIEL = os.path.join(HERE, 'anlagen')
RENDER_DPI = 220          # gerendert wird fein, gespeichert wird kleiner
MAX_BREITE = 780          # Pixel; darüber wird herunterskaliert
QUALITAET = 74            # JPEG-Qualität; Strichzeichnungen gehen oft als PNG

# Prüfungsheft -> Dateiname im PDF-Verzeichnis
HEFTE = {
    'nt24': '77289933-05_IMBQ_NTG_H2024_L_G.pdf',
    'mi24': 'd335d95e-03_IMBQ_MIKP_H2024_L_G.pdf',
    'bw24': '11141db5-02_IMBQ_BwHa_H2024_L_G.pdf',
    'nt25': 'e9e8406f-05_IMBQ_NTG_H2025_L_G.pdf',
    'bw25': 'fd579f69-02_IMBQ_BwHa_H2025_L_G.pdf',
}

# Schlüssel -> Heft, Seite, Ausschnitt(e), Bildunterschrift.
# Mehrere Ausschnitte derselben Seite werden untereinander gesetzt – so lässt
# sich z. B. Schaltbild und Kennlinie ohne den Fragetext dazwischen abbilden.
FIGUREN = {
    # ---- Naturwissenschaft und Technik, Herbst 2024
    'nt24-stuetzbock': ('nt24', 3, (250, 302, 440, 728), 'Abbildung 1: Stützbock'),
    'nt24-flug-wind':  ('nt24', 5, (110, 340, 680, 350), 'Abbildung 2: Flug- und Windrichtung'),
    'nt24-ntc':        ('nt24', 6, [(578, 200, 205, 196), (82, 448, 690, 458)],
                        'Aufgabe 5: Schaltung und Kennlinie des NTC-Widerstands'),
    'nt24-wnetz':      ('nt24', 9, (60, 235, 720, 860),  'Anlage 1 zu Aufgabe 7: Wahrscheinlichkeitsnetz'),
    # ---- Naturwissenschaft und Technik, Herbst 2025
    'nt25-rampe':      ('nt25', 3, (170, 290, 500, 350), 'Abbildung 1: Transportfahrzeug auf Rampe'),
    'nt25-typenschild':('nt25', 5, (180, 240, 470, 335), 'Abbildung 2: Motortypenschild'),
    'nt25-schaltung':  ('nt25', 6, (230, 295, 370, 200), 'Abbildung 3: gemischte Schaltung'),
    # ---- Lösungsskizzen: bei diesen Aufgaben ist die Zeichnung die Lösung
    'nt24-l-kraefte':   ('nt24', 14, (250, 245, 350, 350),
                         'Lösung 4 a): Kräfteparallelogramm der Geschwindigkeiten'),
    'nt24-l-schaltbild':('nt24', 18, (95, 268, 215, 215),
                         'Lösung 6 c): Parallelschaltung mit Spannungs- und Strompfeil'),
    'nt24-l-wnetz':     ('nt24', 20, (105, 195, 640, 890),
                         'Lösung 7 a): Verteilungsgerade im Wahrscheinlichkeitsnetz'),
    'mi24-l-fluss':     ('mi24', 9,  (75, 275, 470, 775),
                         'Lösung 2 a): Flussdiagramm der Schichtübernahme'),
    'mi24-l-diagramm':  ('mi24', 11, (70, 560, 690, 410),
                         'Lösung 4 b): prozentuale Veränderungen der Kosten'),
    'bw25-l-akkord':    ('bw25', 13, (70, 470, 420, 290),
                         'Lösung 4 b): Lohnkosten je Stück über dem Leistungsgrad'),
}


def rendern(pdf, seite, dpi, ziel_prefix):
    subprocess.run(['pdftoppm', '-jpeg', '-r', str(dpi), '-f', str(seite),
                    '-l', str(seite), pdf, ziel_prefix], check=True)
    for kandidat in ('%s-%02d.jpg' % (ziel_prefix, seite),
                     '%s-%d.jpg' % (ziel_prefix, seite),
                     '%s-%03d.jpg' % (ziel_prefix, seite)):
        if os.path.exists(kandidat):
            return kandidat
    raise SystemExit('Seitenbild nicht gefunden für %s Seite %d' % (pdf, seite))


def stapeln(bilder, abstand=18):
    """Ausschnitte untereinander setzen, zentriert, auf weißem Grund."""
    if len(bilder) == 1:
        return bilder[0]
    breite = max(b.width for b in bilder)
    hoehe = sum(b.height for b in bilder) + abstand * (len(bilder) - 1)
    blatt = Image.new('RGB', (breite, hoehe), 'white')
    y = 0
    for b in bilder:
        blatt.paste(b, ((breite - b.width) // 2, y))
        y += b.height + abstand
    return blatt


def speichern(img, basis):
    """Als JPEG und als Palette-PNG sichern, die kleinere Fassung behalten.
    Strichzeichnungen sind als PNG oft deutlich kleiner und schärfer."""
    jpg, png = basis + '.jpg', basis + '.png'
    img.convert('RGB').save(jpg, 'JPEG', quality=QUALITAET, optimize=True)
    img.convert('RGB').quantize(colors=32, method=Image.MEDIANCUT).save(
        png, 'PNG', optimize=True)
    if os.path.getsize(png) <= os.path.getsize(jpg):
        os.remove(jpg)
        return png
    os.remove(png)
    return jpg


def trimmen(img, rand=8):
    """Weiße Ränder abschneiden, danach einen kleinen Rand stehen lassen."""
    grau = img.convert('L')
    maske = grau.point(lambda p: 255 if p < 245 else 0)
    box = maske.getbbox()
    if not box:
        return img
    x0, y0, x1, y1 = box
    return img.crop((max(0, x0 - rand), max(0, y0 - rand),
                     min(img.width, x1 + rand), min(img.height, y1 + rand)))


def baue(pdf_dir, schluessel=None):
    os.makedirs(ZIEL, exist_ok=True)
    tmp = os.path.join(ZIEL, '_tmp')
    faktor = RENDER_DPI / 100.0
    gebaut = []
    for key, (heft, seite, box, titel) in sorted(FIGUREN.items()):
        if schluessel and key not in schluessel:
            continue
        pdf = os.path.join(pdf_dir, HEFTE[heft])
        if not os.path.exists(pdf):
            print('  übersprungen (PDF fehlt): %s' % key)
            continue
        seitenbild = rendern(pdf, seite, RENDER_DPI, tmp)
        seitenimg = Image.open(seitenbild)
        kaesten = box if isinstance(box, list) else [box]
        teile = []
        for x, y, b, h in kaesten:
            x, y, b, h = (int(v * faktor) for v in (x, y, b, h))
            teile.append(trimmen(seitenimg.crop((x, y, x + b, y + h))))
        img = stapeln(teile)
        if img.width > MAX_BREITE:
            hoehe = round(img.height * MAX_BREITE / img.width)
            img = img.resize((MAX_BREITE, hoehe), Image.LANCZOS)
        pfad = speichern(img, os.path.join(ZIEL, key))
        os.remove(seitenbild)
        gebaut.append((os.path.basename(pfad), img.width, img.height,
                       os.path.getsize(pfad), titel))
    for name, w, h, groesse, titel in gebaut:
        print('  %-24s %4d×%-4d %6.1f KB  %s' % (name, w, h, groesse / 1024, titel))
    print('  %d Abbildungen erzeugt' % len(gebaut))


if __name__ == '__main__':
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    baue(sys.argv[1], set(sys.argv[2:]) or None)
