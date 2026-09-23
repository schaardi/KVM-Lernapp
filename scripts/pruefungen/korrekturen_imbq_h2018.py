# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Herbst 2018.

Eine Stelle: Im MIKP-Heft ist die Kopfzeile jeder Seite zweimal leicht
versetzt gesetzt. ``pdftotext`` liest daraus Bruchstücke; die letzten davon
("IN,", "Kommunikation und") sind so gewöhnliche Wörter, dass sie kein
Filtermuster fassen kann, ohne echten Text mitzunehmen. Aufbau und Regeln:
``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # Verschachtelte Brüche und Einheitenbrüche aus dem Layout von Hand
    # ausgeschrieben (linear: „Zähler ÷ Nenner“) und nachgerechnet.
    ('NT', 5, 'a'):
     "S = U · t\n"
     "t = 2 mm\n"
     "U = 2 · 15 mm + √((15 mm)² + (20 mm)²) + 5 mm + 2 · π · 15 mm · 110° ÷ 360°\n"
     "U = 88,80 mm\n"
     "S = U · t\n"
     "S = 88,80 mm · 2 mm\n"
     "S = 177,60 mm²",
    ('NT', 5, 'b'):
     "τaB max = 210 N/mm²\n"
     "F = S · τaB max\n"
     "F = 177,60 mm² · 210 N/mm² = 37.296 N\n"
     "F = 37,296 kN",
    ('NT', 6, 'd'):
     "P = UK² ÷ R\n"
     "P = (226,06 V)² ÷ 20,91 V/A = 2.443,96 W",
}
FRAGE = {
    # BWL, Aufgabe 4 a): Die Auftragstabelle (Produkt, Menge, Losgröße,
    # Rüstzeit, Zeit je Einheit) lief als Fließtext in die Aufgabe. Die Werte
    # hängen jetzt als Tabellenanlage daran (anlagen_imbq._AUFTRAGSDATEN_H2018).
    ('BW', 4, 'a'):
     "Der Fertigungsplanung der Industrie AG liegen für Oktober die in der "
     "Tabelle genannten Auftragsdaten vor. Der Oktober hat 20 Arbeitstage; die "
     "tägliche Arbeitszeit beträgt acht Stunden. Kalkuliert wird mit "
     "urlaubsbedingter Abwesenheit von 13 % sowie krankheitsbedingten "
     "Fehlzeiten in Höhe von 4,5 %. Ermitteln Sie rechnerisch\n"
     "– den Kapazitätsbedarf und\n"
     "– den Personalbedarf\n"
     "im Oktober.",
    ('MI', 4, 'b'):
     "Stellen Sie die Anzahl der meldepflichtigen Arbeitsunfälle pro "
     "1 Million Arbeitsstunden im zeitlichen Verlauf in einem Diagramm dar.",
}
PUNKTE = {}
LABEL = {}
DATUM = {}
INTRO = {
    ('BW', 6): (
        'Die Betriebsabrechnung der Industrie AG stellt für den Berichtszeitraum die '
        'Daten in der Tabelle zu dieser Aufgabe zur Verfügung.'),
    ('MI', 4): (
        'In einem großen Unternehmen wurden die Mitarbeiterzahlen, die '
        'meldepflichtigen Arbeitsunfälle und die Arbeitsstunden erfasst (siehe '
        'Tabelle zu dieser Aufgabe).\n'
        'Aus diesen Angaben werden in der Arbeitsschutzstatistik die Kennzahlen\n'
        '– meldepflichtige Arbeitsunfälle pro 1 Million Arbeitsstunden\n'
        '– meldepflichtige Arbeitsunfälle pro 1000 Vollbeschäftigte berechnet.'),
}
def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
