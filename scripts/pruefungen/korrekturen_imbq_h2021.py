# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Herbst 2021.

Nur der Prüfungstag von „Zusammenarbeit im Betrieb“. Aufbau und Regeln:
``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {}
FRAGE = {}
PUNKTE = {}
LABEL = {}

DATUM = {
    # Das ZiB-Heft dieses Termins liegt nur als Scan der Innenseiten vor – das
    # Deckblatt mit dem Datum fehlt. Die Basisqualifikationen werden an zwei
    # Tagen geprüft: RBH, MIKP und NTG am ersten (3. November 2021), BWH und
    # ZiB am zweiten. Das BWH-Heft desselben Termins nennt den 4. November 2021.
    'ZI': '4. November 2021',
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM)
