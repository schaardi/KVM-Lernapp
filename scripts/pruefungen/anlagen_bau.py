# -*- coding: utf-8 -*-
"""Schneidet die Abbildungen der Prüfungen aus den PDFs und legt sie als JPEG ab.

Die Prüfungs-PDFs liegen bewusst nicht im Repository (DIHK-Hinweis auf dem
Deckblatt). Dieses Skript bekommt das Verzeichnis der PDFs übergeben und
erzeugt daraus die Bildanlagen unter ``anlagen/``; eingecheckt werden nur die
fertigen Ausschnitte.

Die Ausschnitte sind in Punkten einer bei 100 dpi gerenderten Seite angegeben
(x, y, Breite, Höhe) – so, wie man sie an einer Seitenvorschau abliest.

Zwei Wege führen zum Bild:

* ``FIGUREN`` – Zuschnitt einer gerenderten Seite, für gezeichnete Abbildungen,
  die im PDF nur aus Linien bestehen.
* ``AUSZUEGE`` – das eingebettete Bild direkt herausholen (``anlagen_extrakt``),
  ohne Koordinaten und in voller Auflösung. Das ist der Regelfall bei den
  Basisqualifikations-Heften.

    python3 scripts/pruefungen/anlagen_bau.py <pdf-verzeichnis> [schlüssel …]
"""
import os
import subprocess
import sys
import tempfile

# Pillow wird erst beim Zuschneiden gebraucht. Der Import steht deshalb in den
# Funktionen: so lässt sich FIGUREN (die Bildunterschriften) auch dort lesen,
# wo Pillow fehlt – build_anlagen.py braucht nur die Titel.

HERE = os.path.dirname(os.path.abspath(__file__))
ZIEL = os.path.join(HERE, 'anlagen')
RENDER_DPI = 220          # gerendert wird fein, gespeichert wird kleiner
MAX_BREITE = 780          # Pixel; darüber wird herunterskaliert
QUALITAET = 74            # JPEG-Qualität; Strichzeichnungen gehen oft als PNG

# Prüfungsheft -> Pfad im PDF-Verzeichnis (Unterordner erlaubt)
HEFTE = {
    'nt24': '77289933-05_IMBQ_NTG_H2024_L_G.pdf',
    'mi24': 'd335d95e-03_IMBQ_MIKP_H2024_L_G.pdf',
    'bw24': '11141db5-02_IMBQ_BwHa_H2024_L_G.pdf',
    'nt25': 'e9e8406f-05_IMBQ_NTG_H2025_L_G.pdf',
    'bw25': 'fd579f69-02_IMBQ_BwHa_H2025_L_G.pdf',
    # Archiv „Altklausuren“: ein Ordner je Termin
    'ntf19': 'BQ 2019/Mai/NTG 2019 Mai.pdf',
    'nth19': 'BQ 2019/November/NTG 2019 November.pdf',
    'ntf20': 'BQ 2020/Mai/NTG 2020 Mai.pdf',
    'nth20': 'BQ 2020/November/NTG 2020 November.pdf',
    'ntf21': 'BQ 2021/Mai/NTG 2021 Mai.pdf',
    'nth21': 'BQ 2021/November/NTG 2021 November.pdf',
    'ntf22': 'BQ 2022/Mai/NTG 2022 Mai.pdf',
    'nth22': 'BQ 2022/November/NTG 2022 November.pdf',
    'mif19': 'BQ 2019/Mai/MIKP 2019 Mai.pdf',
    'mih19': 'BQ 2019/November/MIKP 2019 November.pdf',
    'mif20': 'BQ 2020/Mai/MIKP 2020 Mai.pdf',
    'mih20': 'BQ 2020/November/MIKP 2020 November.pdf',
    'mif21': 'BQ 2021/Mai/MIKP 2021 Mai.pdf',
    'mih21': 'BQ 2021/November/MIKP 2021 November.pdf',
    'mif22': 'BQ 2022/Mai/MIKP 2022 Mai.pdf',
    'mih22': 'BQ 2022/November/MIKP 2022 November.pdf',
    'bwf19': 'BQ 2019/Mai/BWH 2019 Mai.pdf',
    'bwh20': 'BQ 2020/November/BWH 2020 November.pdf',
    'reh22': 'BQ 2022/November/RBH 2022 November.pdf',
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
    # ---- Lösungszeichnungen der Methoden-Hefte. Die Diagramme stecken im PDF
    # als mehrere Teilbilder oder ungleichmäßig skaliert – nur der Zuschnitt
    # der gerenderten Seite gibt sie richtig wieder.
    'mif19-l-fluss':    ('mif19', 5, (66, 275, 460, 720),
                         'Lösung 2 a): Flussdiagramm der Nutzeranmeldung'),
    'mih19-l-verbund':  ('mih19', 7, (66, 495, 700, 515),
                         'Lösung 4 b): Verbunddiagramm der Teilequalität'),
    'mif21-l-diagramm': ('mif21', 10, (66, 203, 650, 450),
                         'Lösung 4 c): Anteil der Teile ohne Nacharbeit'),
    # ---- Zeichnungen ohne Bildunterschrift: hier hilft nur der Zuschnitt
    'ntf19-pumpe':      ('ntf19', 11, (68, 420, 570, 365),
                         'Abbildung: Kreiselpumpe mit Drehstromantrieb'),
    'ntf20-ntc':        ('ntf20', 10, (68, 560, 700, 320),
                         'Abbildung: Kennlinie des NTC-Widerstands und Schaltung'),
    'nth22-schaltung':  ('nth22', 11, (262, 286, 290, 196),
                         'Abbildung: Widerstandsschaltung'),
    # ---- Wahrscheinlichkeitsnetze der Termine 2021: das eingebettete Bild ist
    # im PDF ungleichmäßig skaliert (1.507 × 488 Pixel für ein fast
    # quadratisches Diagramm) und käme verzerrt heraus – deshalb Zuschnitt.
    'ntf21-l-wnetz':    ('ntf21', 15, (64, 238, 706, 794),
                         'Lösung 7 b) und c): Wahrscheinlichkeitsnetz mit Verteilungsgerade'),
    'nth21-l-wnetz':    ('nth21', 15, (125, 330, 545, 650),
                         'Lösung 7 c): Summenhäufigkeit im Wahrscheinlichkeitsnetz'),
}


# Schlüssel -> Heft, Fundstelle(n), Bildunterschrift.
#
# Anders als FIGUREN kommt diese Tabelle ohne Koordinaten aus. Eine Fundstelle
# ist entweder
#
# * ``(Seite, Nummer)`` – ein **eingebettetes Bild**; die Nummer zählt die
#   Abbildungen einer Seite ab 0 in der Reihenfolge, die
#   ``anlagen_extrakt.holen()`` liefert (Seite, Breite, Höhe), oder
# * ``(Seite, "Bildunterschrift")`` – eine **gezeichnete** Abbildung; geholt
#   wird der Bereich über dieser Bildunterschrift
#   (``anlagen_extrakt.bereiche()``).
#
# Mehrere Fundstellen werden untereinander gesetzt, wie bei FIGUREN.
#
# Bildunterschriften sind die des Hefts. Wo das Heft keine druckt (die Termine
# bis 2020 beschriften ihre Abbildungen meist nicht), steht hier eine
# beschreibende – sie erscheint in App und Web über der Abbildung.
AUSZUEGE = {
    # ---- Naturwissenschaft und Technik, Frühjahr 2019
    'ntf19-tank':       ('ntf19', (5, 0),  'Abbildung: Brauchwassertank mit Rohr'),
    'ntf19-rollen':     ('ntf19', (7, 0),  'Abbildung: Schwerkraft-Rollenförderer'),
    'ntf19-l-schaltung':('ntf19', (10, 0), 'Lösung 5 c): Schaltung mit Parallelwiderstand'),
    # ---- … Herbst 2019
    'nth19-winkelprofil':('nth19', (3, 0), 'Abbildung: Querschnittsfläche des Winkelprofils'),
    'nth19-drohne':     ('nth19', (6, 0),  'Abbildung: Flugrichtung und Windrichtung'),
    'nth19-seilwinde':  ('nth19', (9, 0),  'Abbildung: Seilwinde'),
    # ---- … Frühjahr 2020
    'ntf20-kran':       ('ntf20', (4, 0),  'Abbildung 1: Kran'),
    'ntf20-zaehler':    ('ntf20', (8, 0),  'Abbildung: Drehstromzähler'),
    'ntf20-l-gauss':    ('ntf20', (12, 0), 'Lösung 7 c): Normalverteilung nach Gauß'),
    # ---- … Herbst 2020
    'nth20-korrosion':  ('nth20', (2, 0),
                         'Abbildung 1: Schutzschicht mit Zink · Abbildung 2: Schutzschicht mit Zinn'),
    'nth20-zugmaschine':('nth20', (4, 0),  'Abb. 3: Zugmaschine'),
    'nth20-l-kraefte':  ('nth20', (5, 0),  'Lösung 2: Kräfte an der Zugmaschine'),
    'nth20-halbzeug':   ('nth20', (6, 0),  'Abb. 4: Halbzeug'),
    'nth20-l-heizplatte':('nth20', (13, 0), 'Lösung 6 a): Schaltung der Heizplatte'),
    # ---- Methoden der Information, Kommunikation und Planung, Frühjahr 2021
    'mif21-l-eisenhower':('mif21', (5, 0), 'Lösung 2 a): Eisenhower-Matrix'),
    # ---- … Frühjahr 2021
    'ntf21-vt-muster':  ('ntf21', (4, 0),  'Abbildung: v-t-Diagramm (Muster zum Vervollständigen)'),
    'ntf21-l-vt':       ('ntf21', (5, 0),  'Lösung 3 a): vervollständigtes v-t-Diagramm'),
    'ntf21-heizung':    ('ntf21', [(9, 0), (9, 1)], 'Abbildung: Heizwiderstände mit Stufenschalter'),
    # ---- … Herbst 2021
    'nth21-wechselspannung': ('nth21', (5, 'Abbildung 1: Wechselspannung'),
                         'Abbildung 1: Wechselspannung'),
    'nth21-foerderanlage':('nth21', (8, 'Abbildung 2: Förderanlage'),
                         'Abbildung 2: Förderanlage'),
    'nth21-zugstange':  ('nth21', (10, 0), 'Abbildung 3: Zugstangenquerschnitt'),
    'nth21-lastenaufzug':('nth21', [(11, 0), (12, 0)],
                         'Abbildung 4: Lastenaufzug · Abbildung 5: Typenschild'),
    # ---- … Frühjahr 2022
    'ntf22-bremspedal': ('ntf22', (3, 0),  'Abbildung 1: Bremspedalsystem'),
    'ntf22-filter':     ('ntf22', (5, 0),  'Abbildung 2: Filtersystem'),
    'ntf22-foerderband':('ntf22', (6, 0),  'Abbildung 3: Förderband'),
    # ---- … Herbst 2022
    'nth22-ebene':      ('nth22', (3, 0),  'Abbildung 1: schiefe Ebene'),
    'nth22-antrieb':    ('nth22', [(5, 1), (5, 0)],
                         'Abbildung: Antriebseinheit des Förderbands · Typenschild des Motors'),
    'nth22-l-schaltung':('nth22', (13, 0), 'Lösung 6 d): drei 1-kΩ-Widerstände in Reihe'),
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
    from PIL import Image
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
    from PIL import Image
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
    from PIL import Image
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


def baue_auszuege(pdf_dir, schluessel=None):
    """Eingebettete Abbildungen holen und unter ihrem Schlüssel ablegen."""
    from PIL import Image
    import anlagen_extrakt as AE
    os.makedirs(ZIEL, exist_ok=True)
    gebaut = []
    # je Heft nur einmal auspacken – pdfimages läuft sonst mehrfach über
    # dasselbe PDF.
    ausgepackt = {}
    with tempfile.TemporaryDirectory() as tmp:
        for key, (heft, stellen, titel) in sorted(AUSZUEGE.items()):
            if schluessel and key not in schluessel:
                continue
            pdf = os.path.join(pdf_dir, HEFTE[heft])
            if not os.path.exists(pdf):
                print('  übersprungen (PDF fehlt): %s' % key)
                continue
            braucht_eingebettet = any(
                not isinstance(n, str)
                for _s, n in (stellen if isinstance(stellen, list) else [stellen]))
            if braucht_eingebettet and heft not in ausgepackt:
                ordner = os.path.join(tmp, heft)
                treffer = {}
                for seite, _b, _h, name in AE.holen(pdf, ordner, heft):
                    treffer.setdefault(seite, []).append(os.path.join(ordner, name))
                ausgepackt[heft] = treffer
            treffer = ausgepackt.get(heft, {})
            teile = []
            for seite, num in (stellen if isinstance(stellen, list) else [stellen]):
                if isinstance(num, str):
                    kasten = next((k for t, k in AE.bereiche(pdf, seite)
                                   if t.strip() == num), None)
                    assert kasten, ('Abbildung %s: Bildunterschrift "%s" steht '
                                    'nicht auf Seite %d von %s' % (key, num, seite, heft))
                    ziel = os.path.join(tmp, '%s-%d.png' % (key, seite))
                    assert AE.schneiden(pdf, seite, kasten, ziel), (
                        'Abbildung %s: über "%s" ist kein Platz für ein Bild' % (key, num))
                    teile.append(Image.open(ziel).convert('RGB'))
                    continue
                auf_seite = treffer.get(seite, [])
                assert num < len(auf_seite), (
                    'Abbildung %s: auf Seite %d von %s gibt es nur %d Bilder'
                    % (key, seite, heft, len(auf_seite)))
                teile.append(trimmen(Image.open(auf_seite[num]).convert('RGB')))
            img = stapeln(teile)
            if img.width > MAX_BREITE:
                hoehe = round(img.height * MAX_BREITE / img.width)
                img = img.resize((MAX_BREITE, hoehe), Image.LANCZOS)
            pfad = speichern(img, os.path.join(ZIEL, key))
            gebaut.append((os.path.basename(pfad), img.width, img.height,
                           os.path.getsize(pfad), titel))
    for name, w, h, groesse, titel in gebaut:
        print('  %-24s %4d×%-4d %6.1f KB  %s' % (name, w, h, groesse / 1024, titel))
    print('  %d Abbildungen ausgelesen' % len(gebaut))


if __name__ == '__main__':
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    ausgewaehlt = set(sys.argv[2:]) or None
    baue(sys.argv[1], ausgewaehlt)
    baue_auszuege(sys.argv[1], ausgewaehlt)
