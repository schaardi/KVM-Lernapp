# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2024.

Nur Punktzahlen: Zwei Lösungshefte nennen an drei Stellen eine andere Zahl als
der Aufgabenteil. Maßgeblich ist der Aufgabenteil – er ergibt in beiden Heften
genau 100 Punkte, das Lösungsheft bliebe sonst bei 103 bzw. 102.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {}
FRAGE = {}

PUNKTE = {
    # BWL, Aufgabe 1 c): "Beschreiben Sie jeweils zwei Aufgaben der Organe
    # einer AG" – drei Organe zu je zwei Aufgaben = 6 Punkte. Das Lösungsheft
    # druckt 9.
    ('BW', 1, 'c'): 6,
    # NTG, Aufgabe 4: Zugkräfte im Stahlseil (10) und Seilverlängerung (6).
    # Das Lösungsheft zählt bei beiden Teilen einen Punkt zu viel.
    ('NT', 4, 'a'): 10,
    ('NT', 4, 'b'): 6,
}

LABEL = {}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL)
