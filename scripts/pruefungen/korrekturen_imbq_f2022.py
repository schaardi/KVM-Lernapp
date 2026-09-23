# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2022.

Noch keine nötig – die Hefte dieses Termins gehen unverändert auf 100 Punkte
mit voller Label-Deckung auf. Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
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
