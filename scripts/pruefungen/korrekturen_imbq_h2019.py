# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Herbst 2019.

Eine Lösung steht im Heft nur als Zeichnung; der Text hier beschreibt sie, die
Zeichnung selbst hängt als Lösungsanlage daran (``anlagen_imbq.BILDER_L``).
Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # MIKP, Aufgabe 4 b): "Stellen Sie in einem Kombinationsdiagramm
    # (Verbunddiagramm) mit zwei Größenachsen …"
    ('MI', 4, 'b'):
     "Verbunddiagramm „Auswertung der Teilequalität“ (Zeichnung): waagerecht "
     "die Kalenderwoche 1 bis 5, links die Anzahl der gelieferten Teile "
     "(0 bis 3.500), rechts der Anteil der nicht verwendbaren Teile in Prozent "
     "(0,00 % bis 4,00 %).\n"
     "– Säulen (linke Achse) für die gelieferten Teile: 2.166 · 3.129 · 3.050 · "
     "3.300 · 2.837\n"
     "– Linie mit Datenpunkten (rechte Achse) für den Anteil der nicht "
     "verwendbaren Teile: 3,51 % · 3,32 % · 2,46 % · 2,27 % · 3,07 %\n"
     "Beide Achsen sind zu beschriften, die Säulen zu legendieren.",
}
FRAGE = {}
PUNKTE = {}
LABEL = {}
DATUM = {}
INTRO = {
    ('MI', 4): (
        'Im Wareneingang werden alle Zukaufteile geprüft. Dabei wird zwischen '
        'verwendbaren und nicht verwendbaren Teilen unterschieden. Die Zahl der '
        'verwendbaren Teile wird für jede Kalenderwoche statistisch erhoben (siehe '
        'Tabelle zu dieser Aufgabe).'),
    # NTG, Aufgabe 4: "Flugrichtung Windrichtung" sind die Beschriftungen der
    # beiden Kompassrosen, nicht Fließtext.
    ('NT', 4):
     "Quadrocopter (Drohnen) sollen für Testzwecke in der Paketzustellung "
     "eingesetzt werden. Eine Drohne wird mit einer Geschwindigkeit von "
     "v = 12 m/s genau in Richtung Süden gestartet.\n"
     "Zugleich weht ein Wind aus südöstlicher Richtung (45°) mit einer "
     "Geschwindigkeit von 10 m/s.",
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
