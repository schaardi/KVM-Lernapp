# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2022.

Noch keine nötig – die Hefte dieses Termins gehen unverändert auf 100 Punkte
mit voller Label-Deckung auf. Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # Verschachtelte Brüche und Einheitenbrüche aus dem Layout von Hand
    # ausgeschrieben (linear: „Zähler ÷ Nenner“) und nachgerechnet.
    ('NT', 3, 'a'):
     "A1 · v1 = A2 · v2\n"
     "(1,2 m · 1,2 m) · 18 km/h = (1,2 m · b) · 2,0 m/s\n"
     "b = (1,2 m · 1,2 m) · 18 km/h ÷ (1,2 m · 2,0 m/s · 3,6 (km · s)/(m · h))\n"
     "b = 3,0 m",
# Das Fischgrätdiagramm las der Textlayer zeilenweise über alle Achsen hinweg.
('MI', 2, 'b'):
 'Ursache-Wirkungs-Diagramm „Zu hohe Abfallkosten“, z. B.:\nHauptursache (Achse) | Ursache | Ursache\nMensch | fehlende Motivation | fehlende Kompetenz\nManagement | fehlende Kontrolle | fehlende Investitionen in umweltgerechte Technik\nMaschine / Technik | veraltete Technik | schlecht gewartete Technik\nMaterial | zu viel Verschnitt | zu geringer Recyclinganteil\nMethode | keine systematischen Kontrollen | veraltete Technologie\nHinweis für den Korrektor: Die Achsenbezeichnungen müssen einem Ursache-Wirkungs-Diagramm gerecht werden. Auch andere problembezogene Ursachen sollen entsprechend gewertet werden.',
}
FRAGE = {}
PUNKTE = {}
LABEL = {}
DATUM = {}
INTRO = {}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
