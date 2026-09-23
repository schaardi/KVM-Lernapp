# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2020.

Eine Lösung steht im Heft nur als Zeichnung; der Text hier beschreibt sie, die
Zeichnung selbst hängt als Lösungsanlage daran (``anlagen_imbq.BILDER_L``).
Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # Verschachtelte Brüche und Einheitenbrüche aus dem Layout von Hand
    # ausgeschrieben (linear: „Zähler ÷ Nenner“) und nachgerechnet.
    ('NT', 2, 'a'):
     "p1 · V1 ÷ T1 = p2 · V2 ÷ T2 = pn · Vn ÷ Tn = const.\n"
     "mit: V1 = m1 ÷ ρ1 und V2 = m2 ÷ ρ2\n"
     "p1 · m1 ÷ (ρ1 · T1) = p2 · m2 ÷ (ρ2 · T2)\n"
     "mit: m1 = m2 = m = const.\n"
     "p1 ÷ (ρ1 · T1) = p2 ÷ (ρ2 · T2)\n"
     "ρ2 = p2 · T1 · ρ1 ÷ (p1 · T2)\n"
     "ρ2 = 1.050 mbar · 273,15 K · 0,80 kg/m³ ÷ (1.013 mbar · 288,15 K)\n"
     "ρ2 = 0,786 kg/m³",
    ('NT', 3, 'b'):
     "Summe aller Momente am Träger ergibt jeweils 0.\n"
     "(FBlechrolle + FLaufkatze) · l2 + FG Brücke · l1 ÷ 2 − FB · l1 = 0\n"
     "FB = ((FBlechrolle + FLaufkatze) · l2 + FG Brücke · l1 ÷ 2) ÷ l1\n"
     "FB = ((37.860,7 N + 5.000 N) · 3 m + 50.000 N · 5 m) ÷ 10 m\n"
     "FB = (128.582,1 N m + 250.000 N m) ÷ 10 m\n"
     "FB = 37.858,2 N\n"
     "FG Brücke · l1 ÷ 2 + (FBlechrolle + FLaufkatze) · (l1 − l2) − FA · l1 = 0\n"
     "FA = (FG Brücke · l1 ÷ 2 + (FBlechrolle + FLaufkatze) · (l1 − l2)) ÷ l1\n"
     "FA = (50.000 N · 5 m + (37.860,7 N + 5.000 N) · 7 m) ÷ 10 m\n"
     "FA = (250.000 N m + 300.024,9 N m) ÷ 10 m\n"
     "FA = 55.002,5 N\n"
     "Hinweis für den Korrektor: Bei 4.000 kg ist das Ergebnis FA = 55.968 N.",
    ('NT', 5, 'a'):
     "geg.: 75 U/kWh (Anzeige Stromzähler)\n"
     "ges.: P\n"
     "Lös.: P = W ÷ t\n"
     "W = 1.000 Wh · 15 Umdrehungen ÷ 75 Umdrehungen\n"
     "W = 200 Wh\n"
     "P = 200 Wh · 60 min/h ÷ 6 min\n"
     "P = 2.000 W",
    ('NT', 7, 'a'):
     "x̄ = (68 + 74 + 88 + 78 + 52 + 64 + 90 + 58 + 60 + 98) kg ÷ 10 Personen = 73 kg",
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
    ('MI', 4): (
        'Ihre Produkte werden aus selbst gefertigten und fremdgefertigten Teilen '
        'zusammengesetzt. In den Tabellen zu dieser Aufgabe ist die Anzahl der '
        'selbst gefertigten und der fremdgefertigten Teile dargestellt.'),
    ('NT', 7): (
        'Für eine statistische Erhebung über die Belastbarkeit von Aufzügen wurde das '
        'Gewicht von zehn Personen ermittelt (siehe Tabelle zu dieser Aufgabe).'),
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
