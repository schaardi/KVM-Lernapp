# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Herbst 2020.

Noch keine nötig – die Hefte dieses Termins gehen unverändert auf 100 Punkte
mit voller Label-Deckung auf. Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {}
FRAGE = {}
PUNKTE = {}
LABEL = {}
DATUM = {}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM)
