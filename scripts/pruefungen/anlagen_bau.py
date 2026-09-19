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
    # Frühjahr 2018 – das MIKP-Heft heißt im Archiv "MIKP 2018 Mi.pdf".
    'bwf18': 'BQ 2018/Mai/BWH 2018 Mai.pdf',
    'mif18': 'BQ 2018/Mai/MIKP 2018 Mi.pdf',
    'ntf18': 'BQ 2018/Mai/NTG 2018 Mai.pdf',
    'mih18': 'BQ 2018/November/MIKP 2018 November.pdf',
    'nth18': 'BQ 2018/November/NTG 2018 November.pdf',
    'bwf19': 'BQ 2019/Mai/BWH 2019 Mai.pdf',
    # Tranche T4 (Scans 2014–2017)
    'mih17': 'BQ 2017/November/MIKP 2017 November.pdf',
    'nth17': 'BQ 2017/November/NTG 2017 November.pdf',
    'mif17': 'BQ 2017/Mai/MIKP 2017 Mai.pdf',
    'ntf17': 'BQ 2017/Mai/NTG 2017 Mai.pdf',
    'mih16': 'BQ 2016/November/MIKP 2016 November.pdf',
    'nth16': 'BQ 2016/November/NTG 2016 November.pdf',
    'bwf16': 'BQ 2016/Mai/BWH 2016 Mai.pdf',
    'mif16': 'BQ 2016/Mai/MIKP 2016 Mai.pdf',
    'ntf16': 'BQ 2016/Mai/NTG 2016 Mai.pdf',
    'mih15': 'BQ 2015/November/MIKP 2015 November.pdf',
    'nth15': 'BQ 2015/November/NTG 2015 November.pdf',
    'bwf15': 'BQ 2015/Mai/BWH 2015 Mai.pdf',
    'mih14': 'BQ 2014/November/MIKP 2014 November.pdf',
    'nth14': 'BQ 2014/November/NTG 2014 November.pdf',
    'mif15': 'BQ 2015/Mai/MIKP 2015 Mai.pdf',
    'ntf15': 'BQ 2015/Mai/NTG 2015 Mai.pdf',
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
    'mih19-l-ishikawa': ('mih19', 4, (66, 268, 625, 272),
                         'Lösung 2 a): Ursache-Wirkungs-Diagramm zu Fehlern und '
                         'Ausfällen des Servers'),
    'mif19-l-energie':  ('mif19', 9, (212, 310, 405, 415),
                         'Lösung 4 b): Entwicklung der Energiekosten als Linien- '
                         'und als Säulendiagramm'),
    'mif20-l-netzplan': ('mif20', 14, (130, 220, 915, 525),
                         'Lösung 2 a) und b): Netzplan mit kritischem Pfad und '
                         'Balkenplan ab dem 9. September 2020'),
    'mif20-l-fremd':    ('mif20', 9, (70, 470, 692, 295),
                         'Lösung 4 b): Anteil der fremdgefertigten Teile 2015 bis 2019'),
    'mih20-l-kosten':   ('mih20', 8, (70, 200, 692, 450),
                         'Lösung 4 b): Kostenentwicklung zum Vorjahr je Arbeitsstunde'),
    'mih21-l-lieferant':('mih21', 8, (70, 585, 630, 405),
                         'Lösung 4 b): Anteil der vertragsgemäßen Lieferungen je Lieferant'),
    'mih22-l-fehler':   ('mih22', 7, (70, 638, 505, 292),
                         'Lösung 4 b): Vergleich der Fehlerquoten von Lieferant A und B'),
    # ---- Tranche T4: Scans. Die Zeichnungen liegen als Rasterbild vor, die
    # Beschriftung ist entsprechend grob.
    'mih17-l-netzplan': ('mih17', 4, (40, 190, 590, 285),
                         'Lösung 2 b): Netzplan mit kritischem Pfad Start – B – E – G – I – Ziel'),
    'mih17-l-sollist':  ('mih17', 6, (40, 175, 540, 475),
                         'Lösung 4 b): Soll-Ist-Vergleich der geprüften Werkzeuge (kumuliert)'),
    'nth17-heizstufe2': ('nth17', 3, (85, 720, 240, 220),
                         'Abbildung: Heizstufe II – R1 parallel zur Reihenschaltung aus R2 und R3'),
    'nth17-heizstufe1': ('nth17', 4, (75, 190, 350, 115),
                         'Abbildung: Heizstufe I – Reihenschaltung der drei Heizspiralen'),
    'nth17-leuchte':    ('nth17', 6, (45, 228, 300, 280),
                         'Abbildung: Aufhängung der Leuchte (Zugseil 1,0 m über der Stange, Stange 2,0 m)'),
    'nth17-zylinder':   ('nth17', 7, (225, 255, 250, 195),
                         'Abbildung: doppelt wirkender Arbeitszylinder mit einseitiger Kolbenstange'),
    'nth17-l-histogramm': ('nth17', 8, (60, 635, 320, 285),
                         'Lösung 7 a): Relative Häufigkeit der Schichtdicken'),
    'mif17-l-ishikawa': ('mif17', 3, (75, 590, 520, 225),
                         'Lösung 2 a): Ursache-Wirkungs-Diagramm mit den fünf Hauptachsen'),
    'mif17-l-netz':     ('mif17', 5, (65, 235, 585, 430),
                         'Lösung 4 a): Netzdiagramm der Leistungsbewertung von Fahrzeug A und B'),
    'mif17-l-balken':   ('mif17', 6, (45, 615, 590, 290),
                         'Lösung 5 a): Balkenplan der Vorgänge A bis I'),
    'ntf17-gleitbahn':  ('ntf17', 4, (50, 328, 430, 135),
                         'Abbildung: Gleitbahn von der Packstation (Position A) zur Position B'),
    'ntf17-strompfade': ('ntf17', 5, (50, 315, 490, 165),
                         'Abbildung: Strompfade durch den Körper (RA = 500 Ω, RB = 800 Ω, RR = 20 Ω)'),
    'ntf17-wnetz':      ('ntf17', 9, (110, 285, 530, 770),
                         'Anlage 1 zu Aufgabe 7: Wahrscheinlichkeitsnetz der Lebensdauer der Lampen'),
    'ntf17-l-wnetz':    ('ntf17', 10, (100, 222, 545, 780),
                         'Lösung 7: Wahrscheinlichkeitsnetz mit den abgelesenen Werten'),
    'mih16-l-nutzwert': ('mih16', 7, (85, 295, 625, 205),
                         'Lösung 4 a): Nutzwertanalyse der drei Fahrzeuge'),
    'mih16-l-erzeugnis':('mih16', 8, (70, 245, 500, 265),
                         'Lösung 5 a): Erzeugnisstruktur des Erzeugnisses E'),
    'nth16-schaltung':  ('nth16', 3, (120, 778, 520, 135),
                         'Abbildung: gemischte Schaltung aus R1 bis R4 an U = 200 V'),
    'nth16-l-vtdiagramm':('nth16', 5, (100, 660, 530, 335),
                         'Lösung 3 a): v-t-Diagramm des Pkw'),
    'bwf16-kosten':     ('bwf16', 10, (60, 270, 560, 300),
                         'Abbildung: Kosten-Umsatz-Diagramm der Sonderanfertigung'),
    'bwf16-l-kosten':   ('bwf16', 11, (100, 235, 430, 325),
                         'Lösung 6 a): Break-even-Punkt im Kosten-Umsatz-Diagramm'),
    'mif16-l-kosten':   ('mif16', 6, (80, 248, 530, 400),
                         'Lösung 4 a): Entwicklung der Projektkosten'),
    'mif16-balkenplan': ('mif16', 7, (85, 300, 560, 212),
                         'Abbildung: Balkenplan des Projekts (6. März bis 7. April)'),
    'ntf16-ventil':     ('ntf16', 6, (150, 360, 400, 220),
                         'Abbildung: Sicherheitsventil mit Hebel und verschiebbarer Masse (Maße in mm)'),
    'ntf16-urwertkarte':('ntf16', 9, (170, 265, 480, 475),
                         'Anlage 1 zu Aufgabe 7 a): Urwertkarte der zwölf Stichproben'),
    'ntf16-l-urwertkarte':('ntf16', 10, (130, 290, 500, 470),
                         'Lösung 7 a): Urwertkarte mit den Toleranzgrenzen OGW und UGW'),
    'mih15-l-histogramm':('mih15', 6, (75, 528, 555, 435),
                         'Lösung 4: Säulendiagramm der relativen Häufigkeiten der Füllmengen'),
    'nth15-seil':       ('nth15', 4, (195, 525, 320, 180),
                         'Abbildung: Lampe am Stahlseil über der 30 m breiten Straße (Durchhang 0,66 m)'),
    'nth15-zylinder':   ('nth15', 5, (240, 555, 240, 190),
                         'Abbildung: doppelt wirkender Arbeitszylinder mit einseitiger Kolbenstange (v1 aus, v2 ein)'),
    'nth15-ebene':      ('nth15', 7, (185, 472, 365, 110),
                         'Abbildung: Wagen mit Last auf der schiefen Ebene, gezogen über Umlenkrolle und Seilwinde'),
    # Die Anlagenseite steht im Render auf dem Kopf – der Zuschnitt wird
    # gedreht (5. Eintrag: Grad gegen den Uhrzeigersinn).
    'nth15-wnetz':      ('nth15', 10, (58, 183, 577, 800),
                         'Anlage 1 zu Aufgabe 7 d): Wahrscheinlichkeitsnetz für Rmax in µm', 180),
    'nth15-l-wnetz':    ('nth15', 11, (200, 208, 525, 760),
                         'Lösung 7 d): Gerade der Summenhäufigkeit durch x̄ – 3s = 3,17 µm und x̄ + 3s = 4,38 µm'),
    'bwf15-l-organigramm':('bwf15', 5, (95, 362, 535, 215),
                         'Lösung 2 b): Matrixorganisation mit vier funktionalen Abteilungen und zwei Querschnittseinheiten'),
    'bwf15-l-bab':      ('bwf15', 13, (215, 45, 545, 1035),
                         'Anlage 1 zu Lösung 5: Betriebsabrechnungsbogen mit innerbetrieblicher Leistungsverrechnung', -90),
    'mif15-l-kreis':    ('mif15', 7, (78, 498, 565, 380),
                         'Lösung 3 b): Anteile an den Fehlerkosten als Kreisdiagramm'),
    'ntf15-schaltung':  ('ntf15', 4, (185, 243, 290, 105),
                         'Abbildung: Schaltung aus R1, R2 und R3 (U = 24 V, I = 2 A, U2 = 18 V, R3 = 36 Ω)'),
    'ntf15-zugstange':  ('ntf15', 6, (243, 264, 215, 145),
                         'Abbildung: Querschnitt der Zugstange – Quadrat b × b mit zwei angesetzten Halbkreisen'),
    'ntf15-rampe':      ('ntf15', 7, (200, 268, 300, 112),
                         'Abbildung: Stahlkörper auf der Stahlrampe (8 m lang, 0,5 m hoch) mit der Kraft F'),
    'ntf15-winde':      ('ntf15', 8, (258, 258, 152, 270),
                         'Abbildung: Bauwinde mit Seiltrommel (Durchmesser d, Drehzahl n) und Last m in h = 25 m'),
    'ntf15-saeulen':    ('ntf15', 11, (118, 635, 490, 385),
                         'Anlage 1 zu Aufgabe 7 f): Schema für das Säulendiagramm der Einzelhäufigkeiten'),
    'ntf15-l-saeulen':  ('ntf15', 10, (78, 592, 462, 375),
                         'Lösung 7 f): Säulendiagramm der prozentualen Einzelhäufigkeiten'),
    'mih14-l-minmax':   ('mih14', 5, (75, 250, 560, 470),
                         'Lösung 2: Min-Max-Diagramm der Lagertemperaturen der Hilfsstoffe A bis I'),
    # Netz- und Balkenplan quer gedruckt: Seite 9 und 11 im Uhrzeigersinn,
    # Seite 12 gegen den Uhrzeigersinn zurückdrehen
    'mih14-netzplan':   ('mih14', 9, (265, 180, 330, 905),
                         'Anlage 1 zu Aufgabe 4 a): Netzplan mit den Vorgängen A bis I (Dauer in Tagen)', -90),
    'mih14-l-netzplan': ('mih14', 11, (268, 180, 395, 910),
                         'Lösung 4 a): berechneter Netzplan (FAZ, FEZ, SAZ, SEZ, Puffer) mit kritischem Pfad', -90),
    'mih14-l-balkenplan':('mih14', 12, (325, 50, 215, 890),
                         'Lösung 4 b): Balkenplan der Vorgänge A bis I (Zeit in Tagen)', 90),
    'nth14-wnetz':      ('nth14', 10, (60, 268, 555, 780),
                         'Anlage 1 zu Aufgabe 7 a) bis c): Wahrscheinlichkeitsnetz für die Füllmenge in ml'),
    'nth14-l-wnetz':    ('nth14', 12, (60, 260, 600, 795),
                         'Lösung 7 a): Wahrscheinlichkeitsgerade mit UGW, OGW und der Geraden zu e)'),
    # ---- Heftform L-ALT (2018). Die Hefte setzen alles als Vektorgrafik und
    # beschriften ihre Abbildungen nicht – deshalb durchweg Zuschnitt.
    'ntf18-rohrprofil': ('ntf18', 3, (248, 233, 205, 210),
                         'Abbildung: Querschnitt des elliptischen Rohrprofils (Maße in mm)'),
    'ntf18-schaltung':  ('ntf18', 6, (64, 634, 290, 208),
                         'Abbildung: Magnetspule mit Vorwiderstand und Meldeleuchte'),
    'nth18-bremsanlage':('nth18', 3, (64, 248, 625, 155),
                         'Skizze: hydraulische Bremsanlage (Maße in mm)'),
    'nth18-formteil':   ('nth18', 6, (188, 224, 365, 248),
                         'Abbildung: gestanztes Formteil (Angaben in mm)'),
    'mif18-l-diagramm': ('mif18', 5, (158, 198, 445, 292),
                         'Lösung 4 a): Temperatur und Druckfestigkeit mit Ausgleichsgerade'),
    'bwf18-l-breakeven':('bwf18', 8, (108, 638, 625, 296),
                         'Lösung 7 b): Gesamtkosten- und Umsatzfunktion mit Break-even-Punkt'),
    'mih18-l-unfaelle': ('mih18', 6, (141, 445, 430, 322),
                         'Lösung 4 b): Arbeitsunfälle pro 1 Million Arbeitsstunden'),
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
    for key, spec in sorted(FIGUREN.items()):
        heft, seite, box, titel = spec[:4]
        drehung = spec[4] if len(spec) > 4 else 0
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
        if drehung:
            img = img.rotate(drehung, expand=True, fillcolor='white')
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
