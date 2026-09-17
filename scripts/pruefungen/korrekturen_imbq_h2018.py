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
