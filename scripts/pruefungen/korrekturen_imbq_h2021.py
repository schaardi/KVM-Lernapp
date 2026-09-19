# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Herbst 2021.

Der Prüfungstag von „Zusammenarbeit im Betrieb“ und eine Lösung, die im Heft
nur als Zeichnung steht. Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # NTG, Aufgabe 7 c): "Tragen Sie aufgrund des Mittelwertes und der
    # Standardabweichung die Gerade der Summenhäufigkeit in das
    # Wahrscheinlichkeitsnetz (Anlage 1) ein."
    ('NT', 7, 'c'):
     "Wahrscheinlichkeitsnetz (Zeichnung): waagerecht Rmax in µm von 3,0 bis "
     "4,4, senkrecht die Summe der relativen Häufigkeiten in Prozent.\n"
     "Die Verteilungsgerade wird über drei Punkte gelegt:\n"
     "– x̄ − s = 3,574 µm bei 15,87 %\n"
     "– x̄ = 3,775 µm bei 50 %\n"
     "– x̄ + s = 3,976 µm bei 84,13 %\n"
     "Weil die Messwerte auf dieser Geraden liegen, ist der Prozess "
     "normalverteilt.",
}
FRAGE = {}
PUNKTE = {}
LABEL = {}

DATUM = {
    # Das ZiB-Heft dieses Termins liegt nur als Scan der Innenseiten vor – das
    # Deckblatt mit dem Datum fehlt. Die Basisqualifikationen werden an zwei
    # Tagen geprüft: RBH, MIKP und NTG am ersten (3. November 2021), BWH und
    # ZiB am zweiten. Das BWH-Heft desselben Termins nennt den 4. November 2021.
    'ZI': '4. November 2021',
}

INTRO = {
    # NTG, Aufgabe 3: "Leiterspannung R1 = R2 = R3 = 60 Ω 400 V/50 Hz" ist die
    # Beschriftung der Abbildung, die Bildunterschrift steht ohnehin am Bild.
    ('NT', 3):
     "In einem Warmwasserspeicher sind drei gleiche Heizelemente eingebaut. Ein "
     "Heizelement hat einen Widerstand von 60 Ω und ist für einen Strom von "
     "maximal 4 A ausgelegt. Der Warmwasserspeicher soll an 3-Phasen-Wechsel\u00ad"
     "spannung (Drehstrom) angeschlossen werden. (Wirkungsgrad und "
     "Wirkleistungsfaktor betragen jeweils 1.)\n"
     "– Leiterspannung: 400 V / 50 Hz\n"
     "– R1 = R2 = R3 = 60 Ω",

    # NTG, Aufgabe 4: "Stopper Gliederkette Zugkraft FZ" beschriftet die
    # Abbildung.
    ('NT', 4):
     "In Abfüllanlagen von Getränkeflaschen werden Gliederkettenförderbänder "
     "eingesetzt. Bei einem Flaschenstau in der Förderanlage werden die Flaschen "
     "gestoppt, während die Gliederkette unter den Flaschen durchgezogen wird. "
     "Zur Verringerung der Reibung wird die Gliederkette geschmiert "
     "(z. B. mit Schmierseife).\n"
     "Technische Daten der Förderanlage:\n"
     "– Staulänge: L = 4,9 m\n"
     "– Masse einer leeren Flasche: mFl = 365 g\n"
     "– Durchmesser der Flasche: d = 70 mm\n"
     "– Reibwert: µ = 0,05",
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
