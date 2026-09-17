# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Herbst 2023.

Keine nötig: Alle vier vorliegenden Hefte ergeben im Aufgaben- wie im
Lösungsteil genau 100 Punkte. Das fünfte Fach (Methoden der Information,
Kommunikation und Planung) fehlt im Archiv – die dort abgelegte Datei
"MIKP 2023 November.pdf" ist ein Doppel der ZiB-Prüfung desselben Termins.

Die Datei bleibt bestehen, damit jeder Termin seine Korrekturstelle hat.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {}
FRAGE = {}
PUNKTE = {}
LABEL = {}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL)
