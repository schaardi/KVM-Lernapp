# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2018.

Drei Lösungen kommen nicht heil aus dem Textlayer: eine ist eine Zeichnung,
bei zweien steht die Formel im Heft **über** dem Buchstaben der Teilaufgabe und
landet dadurch beim Teil davor. Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # MIKP, Aufgabe 4 a): "Stellen Sie die Daten in einem Diagramm dar und
    # zeichnen Sie eine Ausgleichsgerade ein." Die amtliche Lösung ist allein
    # das Diagramm; das Bild hängt als Lösungsanlage daran.
    ('MI', 4, 'a'):
     "Punktdiagramm „Temperatur – Druckfestigkeit“ (Zeichnung): waagerecht die "
     "Temperatur in °C von 0 bis 600, senkrecht die Druckfestigkeit in N/mm² "
     "von 0 bis 800.\n"
     "Neun Messpunkte: 100/800 · 150/600 · 200/520 · 250/440 · 300/320 · "
     "350/280 · 400/190 · 450/140 · 500/100.\n"
     "Durch die Punkte wird eine fallende Ausgleichsgerade gelegt; sie beginnt "
     "links oben bei rund 700 N/mm² und endet rechts unten bei rund "
     "100 N/mm².",

    # NTG, Aufgabe 1 b): Die Potenzialdifferenz aus c) steht im Heft über dem
    # "c)" und hängt sonst am Ende der Aufzählung von b).
    ('NT', 1, 'b'):
     "Folgen, z. B.:\n"
     "– Zersetzung eines der Werkstoffe\n"
     "– Undichtigkeiten in der Leitung im Bereich der Metallübergänge\n"
     "– Wasserfolgeschaden\n"
     "– Folgekosten",
    ('NT', 1, 'c'):
     "ΔU = UCu − (−UFe) = 0,34 V + 0,44 V = 0,78 V",

    # NTG, Aufgabe 5: Die Leistung des Vorwiderstandes (b) steht im Heft über
    # dem "b)" und hängt sonst am Ende von a).
    ('NT', 5, 'a'):
     "In der Reihenschaltung ist die Stromstärke konstant: I = 20 mA\n"
     "Teilspannung am Vorwiderstand:\n"
     "UV = U − UMeldeleuchte = 24 V − 2 V = 22 V\n"
     "Widerstandswert des Vorwiderstandes:\n"
     "RV = UV ÷ I = 22 V ÷ 20 mA = 1.100 Ω",
    ('NT', 5, 'b'):
     "PV = UV · I = 22 V · 20 mA = 440 mW",
}
FRAGE = {
    # NTG, Aufgabe 2: "Maße in mm (Abbildung nicht maßstäblich)" ist die
    # Unterschrift der Abbildung und stand mitten im Satz. Die Abbildung hängt
    # jetzt an der Aufgabe und trägt die Unterschrift selbst.
    ('NT', 2, 'a'):
     "Die Rahmenprofile bei Fahrrädern werden aus Stabilitätsgründen oft aus "
     "elliptischen Rohrprofilen hergestellt. Diese werden sowohl auf Zug als "
     "auch auf Druck beansprucht.\n"
     "Berechnen Sie die im Rahmenprofil zulässige Zugkraft, wenn aus "
     "Sicherheitsgründen die zulässige Zugspannung von 180 N/mm² nicht "
     "überschritten werden darf.",
}
PUNKTE = {}
LABEL = {}
DATUM = {}
INTRO = {
    # NTG, Aufgabe 5: "+24 V Vorwiderstand Magnetspule Meldeleuchte 0V" sind
    # die Beschriftungen des Schaltbilds, das jetzt an der Aufgabe hängt.
    ('NT', 5):
     "Der Spannungszustand der Magnetspule eines Pneumatikventils wird durch "
     "eine Meldeleuchte überwacht.\n"
     "– Anschlusswerte der Meldeleuchte: U = 2 V, I = 20 mA\n"
     "– Magnetspule: P = 480 mW an der anliegenden Spannung U = 24 V",
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
