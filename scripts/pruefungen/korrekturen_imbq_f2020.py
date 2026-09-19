# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2020.

Eine Lösung steht im Heft nur als Zeichnung; der Text hier beschreibt sie, die
Zeichnung selbst hängt als Lösungsanlage daran (``anlagen_imbq.BILDER_L``).
Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # NTG, Aufgabe 7 c): "Skizzieren Sie qualitativ die Normalverteilung nach
    # Gauß. Tragen Sie den arithmetischen Mittelwert und die Werte der
    # Standardabweichung im Bereich von 99,73 % der Messwerte ein."
    ('NT', 7, 'c'):
     "Glockenkurve (Zeichnung): waagerecht die Masse m in kg, senkrecht die "
     "Häufigkeit H in %.\n"
     "Der Gipfel liegt beim arithmetischen Mittelwert x̄ = 73 kg.\n"
     "Mit s = 15,3 kg ergeben sich die einzutragenden Grenzen:\n"
     "– x̄ ± 1s: 57,7 kg und 88,3 kg (68,27 % der Messwerte)\n"
     "– x̄ ± 2s: 42,4 kg und 103,6 kg (95,45 %)\n"
     "– x̄ ± 3s: 27,1 kg und 118,9 kg (99,73 %)\n"
     "Die Kurve ist symmetrisch zu x̄ und nähert sich außerhalb von x̄ ± 3s der "
     "waagerechten Achse.",
}
FRAGE = {}
PUNKTE = {}
LABEL = {}
DATUM = {}
INTRO = {
    # NTG, Aufgabe 6: "R1 UEIN R2 ϑ UAUS" sind die Beschriftungen der Schaltung
    # neben der Kennlinie.
    ('NT', 6):
     "In einem Wasserbehälter ist ein NTC-Widerstand eingebaut. Es wird eine "
     "Temperatur von 60 °C gemessen. Der NTC-Widerstand (R2) hat die "
     "abgebildete Kennlinie und ist in Reihe mit einem Widerstand R1 eingebaut. "
     "Die Spannung UEIN beträgt 12 V, abgegriffen wird UAUS über dem "
     "NTC-Widerstand.",
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
