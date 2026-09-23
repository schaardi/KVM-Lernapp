# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Herbst 2023.

Keine nötig: Alle vier vorliegenden Hefte ergeben im Aufgaben- wie im
Lösungsteil genau 100 Punkte. Das fünfte Fach (Methoden der Information,
Kommunikation und Planung) fehlt im Archiv – die dort abgelegte Datei
"MIKP 2023 November.pdf" ist ein Doppel der ZiB-Prüfung desselben Termins.

Die Datei bleibt bestehen, damit jeder Termin seine Korrekturstelle hat.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # Verschachtelte Brüche und Einheitenbrüche aus dem Layout von Hand
    # ausgeschrieben (linear: „Zähler ÷ Nenner“) und nachgerechnet.
    ('BW', 4, 'a'):
     "Stückgeld = Akkordrichtsatz ÷ Normalleistung = 20 €/h · 1,125 ÷ 5 Stück/h = 4,50 €/Stück\n"
     "Normalleistung = 60 min/h ÷ 12 min/Stück = 5 Stück/h\n"
     "Istleistung (Istmenge) = 27 €/h ÷ 4,50 €/Stück = 6 Stück/h\n"
     "Stückzahl pro Woche = 6 Stück/h · 40 h/Woche = 240 Stück/Woche",
    ('NT', 4, 'a'):
     "R34 = R3 + R4\n"
     "= 100 Ω + 200 Ω\n"
     "R34 = 300 Ω\n"
     "I34 = U ÷ R34\n"
     "= 24 V ÷ 300 Ω\n"
     "= 0,08 A\n"
     "U3 = I34 · R3\n"
     "= 0,08 A · 100 Ω\n"
     "= 8 V\n"
     "U3 = U1 = 8 V\n"
     "R1 = U1 · R2 ÷ U2\n"
     "= 8 V · 300 Ω ÷ 16 V\n"
     "R1 = 150 Ω",
    ('NT', 5, 'a'):
     "A = d² · π ÷ 4\n"
     "A = (0,3 mm)² · π ÷ 4\n"
     "A = 0,071 mm²\n"
     "R20 = ρ · L ÷ A\n"
     "R20 = 0,0179 Ω · mm²/m · 100 m ÷ 0,071 mm²\n"
     "R20 = 25,21 Ω\n"
     "R90 = R20 · (1 + αR · ΔT) = 25,21 Ω · (1 + 0,0039 1/K · 70 K) = 32,1 Ω\n"
     "I20 = U ÷ R20 = 24 V ÷ 25,21 Ω = 0,95 A\n"
     "I90 = U ÷ R90 = 24 V ÷ 32,1 Ω = 0,75 A\n"
     "ΔI = I20 − I90 = 0,95 A − 0,75 A = 0,2 A",
    # BWL, Aufgabe 5: Das Heft verweist für beide Teile nur auf die
    # "Lösungshinweise zu Anlage 1" – den ausgefüllten Betriebsabrechnungsbogen
    # auf einer eigenen Seite. Ohne ihn steht in der App keine Lösung.
    ('BW', 5, 'a'):
     "Verteilung der drei noch offenen Gemeinkostenarten:\n"
     "– Heizungskosten 4.800 € nach Fläche (1.200 + 3.000 + 1.400 + 400 = "
     "6.000 m², also 0,80 €/m²): Material 960 €, Fertigung 2.400 €, "
     "Verwaltung 1.120 €, Vertrieb 320 €\n"
     "– Betriebliche Steuern 6.500 € im Verhältnis 4:14:6:2 (26 Anteile zu je "
     "250 €): Material 1.000 €, Fertigung 3.500 €, Verwaltung 1.500 €, "
     "Vertrieb 500 €\n"
     "– Abschreibung 14.400 € im Verhältnis 14:80:20:6 (120 Anteile zu je "
     "120 €): Material 1.680 €, Fertigung 9.600 €, Verwaltung 2.400 €, "
     "Vertrieb 720 €\n"
     "Damit ergeben sich als Summe der Gemeinkosten 123.380 €, davon "
     "Material 15.800 €, Fertigung 50.000 €, Verwaltung 39.000 € und "
     "Vertrieb 18.580 €.",
    ('BW', 5, 'b'):
     "Zuschlagsgrundlagen: Fertigungsmaterial 79.000 €, Fertigungslöhne "
     "40.000 €; für Verwaltung und Vertrieb die Herstellkosten des Umsatzes "
     "von 79.000 € + 15.800 € + 40.000 € + 50.000 € = 184.800 €.\n"
     "– Materialgemeinkosten: 15.800 € ÷ 79.000 € · 100 = 20,00 %\n"
     "– Fertigungsgemeinkosten: 50.000 € ÷ 40.000 € · 100 = 125,00 %\n"
     "– Verwaltungsgemeinkosten: 39.000 € ÷ 184.800 € · 100 = 21,10 %\n"
     "– Vertriebsgemeinkosten: 18.580 € ÷ 184.800 € · 100 = 10,05 %",
}

FRAGE = {
    # BWL, Aufgabe 5 a): Die Flächentabelle lief als Fließtext in die Frage
    # ("Kostenstelle Fläche Material 1.200 m² Fertigung 3.000 m² …").
    ('BW', 5, 'a'):
     "Verteilen Sie die Gemeinkosten für den Monat Mai auf die Kostenstellen im "
     "Betriebsabrechnungsbogen. Hierfür liegen Ihnen folgende Informationen vor:\n"
     "– Die betrieblichen Steuern sollen im Verhältnis 4:14:6:2 auf die "
     "Kostenstellen verteilt werden.\n"
     "– Die Abschreibungen sollen im Verhältnis 14:80:20:6 auf die Kostenstellen "
     "verteilt werden.\n"
     "– Die Heizungskosten werden im Verhältnis der Fläche auf die Kostenstellen "
     "verteilt. Gehen Sie dabei von folgenden Flächen aus: Material 1.200 m², "
     "Fertigung 3.000 m², Verwaltung 1.400 m², Vertrieb 400 m².",
}
PUNKTE = {}
LABEL = {}


INTRO = {
    # NTG, Aufgabe 7: Die Massen der zehn Personen stehen im Heft als Tabelle
    # und landen sonst als Zahlenkette in der Ausgangslage.
    ('NT', 7): (
        'Um die Belastbarkeit von Aufzügen zu überprüfen, wurde mittels einer '
        'Stichprobe die Masse von zehn Personen erfasst und statistisch ausgewertet '
        '(siehe Tabelle zu dieser Aufgabe).'),
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, intro=INTRO)
