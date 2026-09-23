# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Herbst 2022.

Der Prüfungstag von NTG (Druckfehler im Deckblatt) und eine Lösung, die im Heft
nur als Zeichnung steht. Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # Verschachtelte Brüche und Einheitenbrüche aus dem Layout von Hand
    # ausgeschrieben (linear: „Zähler ÷ Nenner“) und nachgerechnet.
    ('NT', 4, 'a'):
     "a1 = v ÷ t1 → t1 = v ÷ a1 = 0,8 m/s ÷ 0,2 m/s² = 4 s\n"
     "v = s ÷ t2 → t2 = s ÷ v = 30 m ÷ 0,8 m/s = 37,5 s\n"
     "a2 = v ÷ t3 → t3 = v ÷ a2 = 0,8 m/s ÷ 0,1 m/s² = 8 s (alternativ: t3 = 2 · t1)\n"
     "tges = t1 + t2 + t3 = 4 s + 37,5 s + 8 s = 49,5 s",
    ('NT', 7, 'a'):
     "x̄ = (200 N + 205 N + 205 N + 195 N + 210 N + 190 N + 190 N + 210 N + 200 N + 195 N) ÷ 10 = 200 N",
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

INTRO = {
    ('MI', 4): (
        'Die beiden Lieferanten A und B beliefern Sie mit Einzelteilen. Der Lieferant B '
        'wird wegen einer gestiegenen Zahl an fehlerhaften Teilen kritisiert; die '
        'Lieferungen stehen in der Tabelle zu dieser Aufgabe.'),
    # NTG, Aufgabe 6: "R1 R2 UEIN R3 UAUS 1 kΩ" sind die Beschriftungen des
    # Schaltbilds, das jetzt als Abbildung an der Aufgabe hängt.
    ('NT', 6):
     "Die Abbildung zeigt eine Widerstandsschaltung. Die Eingangsspannung UEIN "
     "beträgt 24 V, die Ausgangsspannung UAUS beträgt 8 Volt. R1 und R2 haben "
     "die gleichen Widerstandswerte, R3 beträgt 1 kΩ.",
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
