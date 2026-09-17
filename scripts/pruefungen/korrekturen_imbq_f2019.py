# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2019.

Eine Lösung steht im Heft nur als Zeichnung; der Text hier beschreibt sie, die
Zeichnung selbst hängt als Lösungsanlage daran (``anlagen_imbq.BILDER_L``).
Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # MIKP, Aufgabe 2 a): "Stellen Sie den im folgenden Text beschriebenen
    # Vorgang in einem Flussdiagramm dar."
    ('MI', 2, 'a'):
     "Flussdiagramm (Zeichnung) mit folgendem Ablauf:\n"
     "Start → „Anmeldung“ → „Prüfung der Zulassung“ → Verzweigung "
     "„Nutzer ist zugelassen?“\n"
     "– nein: → „Information Nichtzulassung“ → Ende\n"
     "– ja: → „Nutzer erstellt Passwort“ → „Passwort wird geprüft“ → "
     "Verzweigung „Passwort ist gültig?“\n"
     "   – nein: zurück zu „Nutzer erstellt Passwort“\n"
     "   – ja: → „Bestätigung für Nutzer“ → „Nutzer arbeitet im System“ → Ende\n"
     "Start und Ende als abgerundete Rechtecke, Tätigkeiten als Rechtecke, "
     "Entscheidungen als Rauten mit beschrifteten Ausgängen (ja/nein).",
}
FRAGE = {}
PUNKTE = {}
LABEL = {}
DATUM = {}
INTRO = {
    # NTG, Aufgabe 4: Die letzte Zeile ist eine aus dem Satz gefallene Formel –
    # "sinα" stand über dem Bruchstrich, "cosα" darunter.
    ('NT', 4):
     "In einem Produktionsbetrieb werden Kartonagen in 12er-Verpackungs\u00adeinheiten "
     "(VE) gebündelt. Über einen Schwerkraft-Rollenförderer werden die VE zum "
     "Palettieren gefördert (siehe Abbildung). Die Geschwindigkeit an der "
     "Aufgabestelle A beträgt vA = 2,5 m/s. Am Ende E soll die Geschwindigkeit "
     "vE = vA betragen. Die Kartons werden also nicht beschleunigt.\n"
     "– Rollreibungswert: µ = 0,035\n"
     "– Masse einer Kartonage: m = 1,06 kg\n"
     "Es gilt: tan α = sin α ÷ cos α",

    # NTG, Aufgabe 6: Die Beschriftungen der Schaltskizze (U, I, L1–L3, M 3~,
    # Solebecken) stehen im Textlayer als Fließtext. Die Skizze selbst hängt
    # jetzt als Abbildung an der Aufgabe; die Kennwerte stehen hier lesbar.
    ('NT', 6):
     "Eine Kreiselpumpe fördert aus einem Solebecken 10 Sekunden lang eine "
     "Salzlösung.\n"
     "– Die Förderhöhe beträgt 5,45 m.\n"
     "– Der Pumpenantrieb erfolgt über einen Drehstrommotor, der an 400 V "
     "Drehstrom angeschlossen ist.\n"
     "– Die Stromaufnahme des Drehstrommotors beträgt 13 A.\n"
     "– Die Dichte der Salzlösung beträgt 1,15 kg/dm³.\n"
     "– Motorverluste = 16 %, Wirkleistungsfaktor cos φ = 0,86, ηPumpe = 0,77\n"
     "Berechnen Sie rechnerisch nachvollziehbar:",
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, DATUM, INTRO)
