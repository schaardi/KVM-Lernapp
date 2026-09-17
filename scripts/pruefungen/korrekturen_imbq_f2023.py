# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2023."""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {}
FRAGE = {}

PUNKTE = {
    # BWL, Aufgabe 6 a): Fixkosten, Break-Even-Umsatz und Betriebsergebnis –
    # der Aufgabenteil weist dafür 10 Punkte aus, das Lösungsheft druckt 3.
    ('BW', 6, 'a'): 10,
}

LABEL = {
    # Recht, Aufgabe 8: Das Lösungsheft druckt beide Teile als "a"; der zweite
    # (4 Punkte, Haftung nach ProdHaftG) ist Teil b.
    ('RE', 8, 1): 'b',
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL)
