# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Herbst 2020.

Die Hefte gehen unverändert auf 100 Punkte mit voller Label-Deckung auf. Zwei
Stellen im BWL-Heft mussten trotzdem nachgezogen werden, weil ``pdftotext``
**Tabellen** spaltenweise ausliest und als Fließtext in Frage und Ausgangslage
hängt. Beide Tabellen stehen jetzt als Anlage an ihrer Aufgabe
(``anlagen_imbq.py``), der Text verweist nur noch darauf. Aufbau und Regeln:
``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # Im Aufgabenheft steht als Lösung nur der Verweis „siehe Lösungshinweis zu
    # Aufgabe 5“ – die eigentliche Lösung ist der ausgefüllte
    # Betriebsabrechnungsbogen auf der Lösungsseite. Er steht als
    # Lösungstabelle an der Teilaufgabe; hier der Rechenweg dazu.
    ('BW', 5, 'a'): (
        'Umlage der Kostenstelle „Gebäude“ (2.760 Tsd. €) nach der Fläche:\n'
        'Gesamtfläche = 460 m² + 60 m² + 840 m² + 420 m² + 620 m² = 2.400 m²\n'
        'Verrechnungssatz = 2.760 Tsd. € / 2.400 m² = 1,15 Tsd. €/m²\n'
        '– Material: 460 m² · 1,15 Tsd. €/m² = 529 Tsd. €\n'
        '– Arbeitsvorbereitung: 60 m² · 1,15 Tsd. €/m² = 69 Tsd. €\n'
        '– Fertigung 1: 840 m² · 1,15 Tsd. €/m² = 966 Tsd. €\n'
        '– Fertigung 2: 420 m² · 1,15 Tsd. €/m² = 483 Tsd. €\n'
        '– Verwaltung und Vertrieb: 620 m² · 1,15 Tsd. €/m² = 713 Tsd. €\n'
        '\n'
        'Umlage der Kostenstelle „Arbeitsvorbereitung“ nach der Anzahl der '
        'Mitarbeiter. Sie trägt nach der Gebäudeumlage 282 Tsd. € + 69 Tsd. € = '
        '351 Tsd. €:\n'
        'Verrechnungssatz = 351 Tsd. € / 21 Mitarbeiter = 16,714… Tsd. €/Mitarbeiter\n'
        '– Fertigung 1: 351 Tsd. € · 14/21 = 234 Tsd. €\n'
        '– Fertigung 2: 351 Tsd. € · 7/21 = 117 Tsd. €\n'
        '\n'
        'Gemeinkosten der Hauptkostenstellen nach der Umlage:\n'
        '– Material: 596 Tsd. € + 529 Tsd. € = 1.125 Tsd. €\n'
        '– Fertigung 1: 2.115 Tsd. € + 966 Tsd. € + 234 Tsd. € = 3.315 Tsd. €\n'
        '– Fertigung 2: 1.378 Tsd. € + 483 Tsd. € + 117 Tsd. € = 1.978 Tsd. €\n'
        '– Verwaltung und Vertrieb: 4.319 Tsd. € + 713 Tsd. € = 5.032 Tsd. €\n'
        '(Summe unverändert 11.450 Tsd. €)\n'
        '\n'
        'Zuschlagsbasis der Verwaltung und des Vertriebs sind die Herstellkosten '
        'des Umsatzes:\n'
        '12.500 Tsd. € + 1.125 Tsd. € + 780 Tsd. € + 3.315 Tsd. € + 430 Tsd. € + '
        '1.978 Tsd. € = 20.128 Tsd. €\n'
        '\n'
        'Gemeinkostenzuschlagssätze:\n'
        '– Materialgemeinkosten = 1.125 Tsd. € · 100 % / 12.500 Tsd. € = 9 %\n'
        '– Fertigungsgemeinkosten 1 = 3.315 Tsd. € · 100 % / 780 Tsd. € = 425 %\n'
        '– Fertigungsgemeinkosten 2 = 1.978 Tsd. € · 100 % / 430 Tsd. € = 460 %\n'
        '– Verwaltungs- und Vertriebsgemeinkosten = 5.032 Tsd. € · 100 % / '
        '20.128 Tsd. € = 25 %'
    ),
    # Die Brüche der Musterrechnung zerfallen beim Textauszug in Zeilen
    # („5.000 h kalkulatorische Abschreibung = 35,00 €/h· = 50,00 €/h 3.500 h“).
    ('BW', 6, 'a'): (
        'Die zeitabhängigen Kosten verteilen sich auf weniger Einsatzstunden und '
        'steigen deshalb im Verhältnis 5.000 h : 3.500 h:\n'
        '– kalkulatorische Abschreibung = 35,00 €/h · 5.000 h / 3.500 h = 50,00 €/h '
        '(1 Punkt)\n'
        '– kalkulatorische Zinsen = 9,80 €/h · 5.000 h / 3.500 h = 14,00 €/h '
        '(1 Punkt)\n'
        '– Raumkosten = 1,75 €/h · 5.000 h / 3.500 h = 2,50 €/h (1 Punkt)\n'
        '– Der Energieverbrauch fällt je Einsatzstunde an und bleibt unverändert '
        'bei 6,00 €/h (1 Punkt)\n'
        '– Instandhaltungskosten = 28,00 €/h · (5.000 h · 8 %) / (3.500 h · 10 %) = '
        '32,00 €/h (2 Punkte)\n'
        '\n'
        'Maschinenstundensatz im Zweischichtbetrieb = 50,00 €/h + 14,00 €/h + '
        '2,50 €/h + 6,00 €/h + 32,00 €/h = 104,50 €/h (1 Punkt)'
    ),
}

FRAGE = {
    # Der Verteilungsschlüssel ist im Heft eine Tabelle; spaltenweise ausgelesen
    # wird daraus „ArbeitsVerteilung Fertigung Fertigung Verwaltung Gebäude
    # Material vorbereisschlüssel 1 2 und Vertrieb tung Flächenbe 460 60 840
    # 420 620 darf in m² Mitarbeiter 14 7“.
    ('BW', 5, 'a'): (
        'Aus der Betriebsabrechnung der Industrie GmbH liegt in der Anlage 1 der '
        'noch unvollständige Betriebsabrechnungsbogen vor.\n'
        'Dabei wird die Kostenstelle „Gebäude“ über die benötigte Fläche der '
        'einzelnen Kostenstellen und die Kostenstelle „Arbeitsvorbereitung“ auf '
        'die Fertigungshauptkostenstellen nach der Anzahl der Mitarbeiter '
        'verteilt (siehe Verteilungsschlüssel).\n'
        'Weiterhin liegen folgende Einzelkosten vor:\n'
        '– Fertigungslohnkosten 1: 780 Tsd. €\n'
        '– Fertigungslohnkosten 2: 430 Tsd. €\n'
        '– Fertigungsmaterial: 12.500 Tsd. €\n'
        'Führen Sie die innerbetriebliche Leistungsverrechnung durch und ermitteln '
        'Sie die Gemeinkostenzuschlagssätze.'
    ),
}

PUNKTE = {}
LABEL = {}
DATUM = {}

INTRO = {
    ('BW', 2): (
        'Neben der Fertigungsorganisation plant die Geschäftsführung der Industrie '
        'GmbH, auch die Materiallager auf Verbesserungspotenziale zu untersuchen.\n'
        'Es wurde festgestellt, dass vor allem die Lagerung von Feinblechen aus '
        'Edelstahl durch eine hohe Anzahl an verschiedenen Formaten in '
        'unterschiedlichen Blechstärken sowie hohe und stark schwankende '
        'Lagerbestände gekennzeichnet ist. Die Bestandsführung und Bedarfsermittlung '
        'erfolgt auf Basis von Sichtprüfungen in den Blechtafelregalen durch den '
        'Lagermeister.\n'
        'In einem ersten Schritt soll im Lager exemplarisch anhand einer Materialart '
        'eine Kennzahlenanalyse durchgeführt werden; die Lagerbestände stehen in der '
        'Tabelle zu dieser Aufgabe.'),
    ('NT', 7): (
        'Die Bewertungsübersicht einer internen Schulungsmaßnahme mit anschließender '
        'Erfolgskontrolle ergab einen arithmetischen Mittelwert von 3,0. Bei der '
        'Übermittlung der Daten ist ein Fehler unterlaufen, deshalb ist die Anzahl '
        'bei der Note 4 leer (siehe Tabelle zu dieser Aufgabe).'),
    # Die Maschinenstundensatzrechnung ist im Heft eine zweispaltige Tabelle und
    # steht sonst als Zahlenkette in der Ausgangslage.
    ('BW', 6): (
        'Für eine CNC-Fräsmaschine der Industrie GmbH liegt für den bisherigen '
        'Dreischichtbetrieb die Maschinenstundensatzrechnung in der Tabelle zu '
        'dieser Aufgabe vor.\n'
        'Die Produktion soll aufgrund der schlechten Auftragssituation vom '
        'Dreischichtbetrieb auf Zweischichtbetrieb umgestellt werden. Bei einem '
        'Zweischichtbetrieb würde sich die jährliche Einsatzzeit auf 3.500 Stunden '
        'reduzieren. Aufgrund von Erfahrungswerten kann davon ausgegangen werden, '
        'dass sich der Instandhaltungskostensatz bei dieser Maßnahme von 10 % auf '
        '8 % reduziert.'
    ),
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
