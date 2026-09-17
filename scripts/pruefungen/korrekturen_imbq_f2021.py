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


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM)
