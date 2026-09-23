# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2024.

Nur Punktzahlen: Zwei Lösungshefte nennen an drei Stellen eine andere Zahl als
der Aufgabenteil. Maßgeblich ist der Aufgabenteil – er ergibt in beiden Heften
genau 100 Punkte, das Lösungsheft bliebe sonst bei 103 bzw. 102.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # Verschachtelte Brüche und Einheitenbrüche aus dem Layout von Hand
    # ausgeschrieben (linear: „Zähler ÷ Nenner“) und nachgerechnet.
    ('BW', 2, 'a'):
     "Kapazitätsbedarf = TA + TB + TC + TD\n"
     "TA = 8 · 180 min + 4.000 St. · 25 min = 101.440 min\n"
     "+ TB = 5 · 152 min + 2.500 St. · 44 min = 110.760 min\n"
     "+ TC = 3 · 75 min + 900 St. · 30 min = 27.225 min\n"
     "+ TD = 1 · 275 min + 500 St. · 75 min = 37.775 min\n"
     "= Kapazitätsbedarf 277.200 min/Monat\n"
     "= 4.620 h/Monat (8 Punkte)\n"
     "Kapazitätsbestand pro Mitarbeiter = 8 h/Tag · 20 Tage/Monat · 0,802\n"
     "= 128,32 h/Monat (3 Punkte)\n"
     "Personalbedarf = 4.620 h/Monat ÷ 128,32 h/(MA · Monat) = 36,00 Mitarbeiter (3 Punkte)",
    ('NT', 2, 'b'):
     "tan α = 10 % ÷ 100 %\n"
     "α = tan⁻¹(10 % ÷ 100 %)\n"
     "= 5,71°\n"
     "Die kinetische Energie wurde vollständig in die potenzielle Energie umgewandelt, somit gilt der Ansatz:\n"
     "Epot = Ekin\n"
     "Epot = m · g · h\n"
     "h = Epot ÷ (m · g)\n"
     "= 468.750 J ÷ (1.500 kg · 9,81 m/s²)\n"
     "h = 31,86 m\n"
     "Berechnung der Strecke s:\n"
     "sin α = h ÷ s\n"
     "s = h ÷ sin α\n"
     "= 31,86 m ÷ sin 5,71°\n"
     "s = 320,22 m",
    ('NT', 4, 'a'):
     "– Berechnung der Gewichtskraft der Lampe\n"
     "Fg = m · g\n"
     "Fg = 10 kg · 9,81 m/s²\n"
     "Fg = 98,1 N\n"
     "– Winkelberechnung\n"
     "tan α = a ÷ b\n"
     "α = tan⁻¹(a ÷ b)\n"
     "α = tan⁻¹(2 m ÷ 10 m)\n"
     "α = 11,31°\n"
     "– Seilkraft\n"
     "FSeil = a ÷ sin α\n"
     "FSeil = 49,05 N ÷ sin 11,31°\n"
     "FSeil = 250,11 N",
    ('NT', 6, 'b'):
     "RBetrieb = U ÷ I = 230 V ÷ 8,696 A = 26,45 Ω",
}
FRAGE = {}

PUNKTE = {
    # BWL, Aufgabe 1 c): "Beschreiben Sie jeweils zwei Aufgaben der Organe
    # einer AG" – drei Organe zu je zwei Aufgaben = 6 Punkte. Das Lösungsheft
    # druckt 9.
    ('BW', 1, 'c'): 6,
    # NTG, Aufgabe 4: Zugkräfte im Stahlseil (10) und Seilverlängerung (6).
    # Das Lösungsheft zählt bei beiden Teilen einen Punkt zu viel.
    ('NT', 4, 'a'): 10,
    ('NT', 4, 'b'): 6,
}

LABEL = {}


INTRO = {
    # Methoden, Aufgabe 4: Punkte und absolute Häufigkeit der Kundenbefragung
    # stehen im Heft als Tabelle.
    ('MI', 4): (
        'In einer Kundenbefragung konnten die Befragten die Kundenfreundlichkeit mit '
        'Punkten bewerten. Die Ergebnisse stehen in der Tabelle zu dieser Aufgabe.'),
    # BWL, Aufgabe 2: Die Auftragstabelle (Produkt, Produktionsmenge, Losgröße,
    # Rüstzeit, Zeit je Einheit) lief als Fließtext in die Ausgangslage. Die
    # Werte hängen jetzt als Tabellenanlage an der Aufgabe.
    ('BW', 2):
     "Der Fertigungsplanung der Industrie GmbH liegen für den Juni die in der "
     "Tabelle genannten Auftragsdaten vor. Der Juni hat 20 Arbeitstage, die "
     "tägliche Arbeitszeit beträgt 8 Stunden. Kalkuliert wird mit "
     "urlaubsbedingter Abwesenheit von 14 % sowie krankheitsbedingten "
     "Fehlzeiten in Höhe von 5,8 %.",
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, {}, INTRO)
