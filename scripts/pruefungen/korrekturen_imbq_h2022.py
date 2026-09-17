# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Herbst 2022.

Der Prüfungstag von NTG (Druckfehler im Deckblatt) und eine Lösung, die im Heft
nur als Zeichnung steht. Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # NTG, Aufgabe 6 d): "Skizzieren Sie die erforderliche Schaltung." Die
    # amtliche Lösung ist allein das Schaltbild auf Seite 13; der Text hier
    # beschreibt es, das Bild selbst hängt als Lösungsanlage daran
    # (anlagen_imbq.BILDER_L).
    ('NT', 6, 'd'):
     "Reihenschaltung aus den drei gleichen Widerständen an UEIN:\n"
     "R1NEU = 1 kΩ, R2NEU = 1 kΩ und R3 = 1 kΩ liegen hintereinander, UAUS "
     "wird über R3 abgegriffen.\n"
     "Drei gleich große Widerstände in Reihe teilen die Eingangsspannung zu "
     "gleichen Teilen:\n"
     "UAUS = UEIN ÷ 3 = 24 V ÷ 3 = 8 V",
}

FRAGE = {}
PUNKTE = {}
LABEL = {}

DATUM = {
    # Das NTG-Deckblatt nennt "3. November 2023" – ein Jahr zu spät. Die
    # Heftnummer L 050-05-1122-5 steht für 11/22, und die vier übrigen Hefte
    # dieses Termins nennen den 3./4. November 2022.
    'NT': '3. November 2022',
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM)
