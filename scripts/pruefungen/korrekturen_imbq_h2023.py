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


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL)
