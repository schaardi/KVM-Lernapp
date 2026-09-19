# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Herbst 2018.

Eine Stelle: Im MIKP-Heft ist die Kopfzeile jeder Seite zweimal leicht
versetzt gesetzt. ``pdftotext`` liest daraus Bruchstücke; die letzten davon
("IN,", "Kommunikation und") sind so gewöhnliche Wörter, dass sie kein
Filtermuster fassen kann, ohne echten Text mitzunehmen. Aufbau und Regeln:
``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {}
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
INTRO = {}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
