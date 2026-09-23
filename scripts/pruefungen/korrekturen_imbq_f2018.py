# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2018.

Drei Lösungen kommen nicht heil aus dem Textlayer: eine ist eine Zeichnung,
bei zweien steht die Formel im Heft **über** dem Buchstaben der Teilaufgabe und
landet dadurch beim Teil davor. Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # Verschachtelte Brüche und Einheitenbrüche aus dem Layout von Hand
    # ausgeschrieben (linear: „Zähler ÷ Nenner“) und nachgerechnet.
    ('BW', 4, 'a'):
     "– Stückgeld = Bruttolohn ÷ Leistungsmenge\n"
     "Stückgeld = 23,40 €/h ÷ 13 Stück/h = 1,80 €/Stück (2 Punkte)\n"
     "– Akkordgrundlohn\n"
     "Akkordrichtsatz = Stückgeld · Normalleistung = 1,80 €/Stück · 10 Stück/h = 18,00 €/h\n"
     "Akkordgrundlohn pro Stunde = Akkordrichtsatz − Akkordzuschlag\n"
     "Akkordgrundlohn pro Stunde = 18,00 €/h − 18,00 €/h ÷ 112,5 % · 12,5 % = 16 €/h (4 Punkte)\n"
     "– Stundenverdienst bei acht Stück:\n"
     "Stundenverdienst (Bruttolohn) = Leistungsmenge · Stückgeld\n"
     "= 8 Stück/h · 1,80 €/Stück = 14,40 €/h\n"
     "Da der Verdienst unterhalb des garantierten Akkordgrundlohnes liegt, ist diese Rechnung irrelevant. Der Facharbeiter erhält in diesem Fall 16,00 € pro Stunde. (3 Punkte)",
    ('NT', 5, 'c'):
     "P = I² · R\n"
     "R = P ÷ I² = 480 mV · A ÷ (20 mA)² = 1200 V/A = 1200 Ω\n"
     "IMagnetspule = PMagnetspule ÷ U = 480 mV · A ÷ 24 V = 20 mA",
    ('NT', 7, 'a'):
     "Beispielrechnung für 2013:\n"
     "x̄ = (0 + 18 + 18 + 32 + 0 + 12) ÷ 25 = 80 ÷ 25 = 3,20\n"
     "Gesamtmittelwert:\n"
     "x̄ = (3,20 + 3,17 + 2,90 + 2,83 + 3,17) ÷ 5 = 3,05\n"
     "zuzüglich der anderen Tabellenwerte\n"
     "Jahrgang | Note 1 | Note 2 | Note 3 | Note 4 | Note 5 | Note 6 | Anzahl der Einzelwerte | Σ xi | x̄\n"
     "2013 | 0 | 9 | 6 | 8 | 0 | 2 | 25 | 80 | 3,20\n"
     "2014 | 2 | 5 | 7 | 7 | 3 | 0 | 24 | 76 | 3,17\n"
     "2015 | 1 | 8 | 3 | 8 | 0 | 0 | 20 | 58 | 2,90\n"
     "2016 | 3 | 6 | 6 | 8 | 0 | 0 | 23 | 65 | 2,83\n"
     "2017 | 1 | 6 | 8 | 6 | 3 | 0 | 24 | 76 | 3,17\n"
     "Summen | 7 | 34 | 30 | 37 | 6 | 2 | 116 | XXX | 3,05",
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
    ('MI', 4): (
        'In Ihrem Meisterbereich werden Werkstoffprüfungen durchgeführt. Für die '
        'wöchentliche Arbeitsberatung werden Sie gebeten, die in der Tabelle zu '
        'dieser Aufgabe angegebenen Werte grafisch darzustellen.'),
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
