# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Herbst 2016.

Aufbau und Regeln: korrekturen_basis.py.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {}
FRAGE = {}
PUNKTE = {}
LABEL = {}
DATUM = {}
INTRO = {}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
