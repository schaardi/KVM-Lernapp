# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2021.

Zwei Lösungen stehen im Heft nur als Zeichnung; der Text hier beschreibt sie,
die Zeichnung selbst hängt als Lösungsanlage daran (``anlagen_imbq.BILDER_L``).
Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # MIKP, Aufgabe 2 a): "Stellen Sie diese Einordnung grafisch dar."
    ('MI', 2, 'a'):
     "Eisenhower-Matrix (Zeichnung): ein Quadrat, senkrechte Achse "
     "„Wichtigkeit“, waagerechte Achse „Dringlichkeit“, beide von links unten "
     "steigend. Daraus vier Felder:\n"
     "– A (oben rechts): wichtig und dringlich – sofort selbst erledigen\n"
     "– B (oben links): wichtig, nicht dringlich – terminieren und selbst "
     "erledigen\n"
     "– C (unten rechts): dringlich, nicht wichtig – delegieren\n"
     "– D (unten links): weder wichtig noch dringlich – nicht bearbeiten",

    # MIKP, Aufgabe 4 c): "Stellen Sie den prozentualen Anteil der Teile ohne
    # Nacharbeit in einem Diagramm dar und tragen Sie dort auch die Zielgröße
    # von 90 % ein."
    ('MI', 4, 'c'):
     "Säulendiagramm „Anteil der Teile ohne Nacharbeit für die Kalenderwochen "
     "1 bis 6“ (Zeichnung): waagerecht die Kalenderwoche 1 bis 6, senkrecht "
     "der Anteil in Prozent von 0 % bis 100 %.\n"
     "– KW 1: 90,0 % · KW 2: 83,3 % · KW 3: 90,9 % · KW 4: 85,7 % · "
     "KW 5: 100,0 % · KW 6: 93,3 %\n"
     "Zusätzlich eine waagerechte Linie bei 90 %, beschriftet mit "
     "„Zielvorgabe“. Sichtbar wird: nur die Kalenderwochen 2 und 4 liegen "
     "darunter.",

    # NTG, Aufgabe 3 a): "Vervollständigen Sie das v-t Diagramm nach diesem
    # Muster auf Ihrem Lösungsblatt."
    ('NT', 3, 'a'):
     "v-t-Diagramm (Zeichnung): waagerecht die Zeit t in s von 0 bis 3,5, "
     "senkrecht die Geschwindigkeit v in km/h von 0 bis 60.\n"
     "– 0 s bis 0,7 s: waagerechte Linie bei 40 km/h (Reaktionszeit, "
     "gleichförmige Fahrt)\n"
     "– 0,7 s bis 1,7 s: gerade ansteigende Linie von 40 km/h auf 50 km/h "
     "(gleichmäßige Beschleunigung, eine Sekunde lang)\n"
     "– 1,7 s bis 3 s: waagerechte Linie bei 50 km/h bis zum Ende der "
     "Gelbphase\n"
     "Die Flächen unter den drei Abschnitten sind die Teilwege s1, s2 und s3 "
     "aus Teilaufgabe b).",
}

FRAGE = {}
PUNKTE = {}
LABEL = {}
DATUM = {}
INTRO = {
    ('MI', 4): (
        'In Ihrer Produktionslinie wird wöchentlich das Teil T1 in unterschiedlichen '
        'Stückzahlen hergestellt. Die Geschäftsleitung hat Ihnen für die ersten '
        'sechs Kalenderwochen zwei messbare Ziele gesetzt:\n'
        '1. Der Anteil der Teile ohne Nacharbeit soll größer als 90 % sein.\n'
        '2. Die durchschnittliche Arbeitszeit je Teil soll 2 Stunden nicht '
        'überschreiten.\n'
        'Aus der Betriebsdatenerfassung haben Sie die Zahlen in der Tabelle zu '
        'dieser Aufgabe erhalten.'),
}
def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
