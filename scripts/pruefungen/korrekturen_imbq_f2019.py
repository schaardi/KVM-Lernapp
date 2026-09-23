# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2019.

Eine Lösung steht im Heft nur als Zeichnung; der Text hier beschreibt sie, die
Zeichnung selbst hängt als Lösungsanlage daran (``anlagen_imbq.BILDER_L``).
Aufbau und Regeln: ``korrekturen_basis.py``.
"""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # Verschachtelte Brüche und Einheitenbrüche aus dem Layout von Hand
    # ausgeschrieben (linear: „Zähler ÷ Nenner“) und nachgerechnet.
    ('NT', 3, 'a'):
     "ΔV1 = V0 · αV · ΔT\n"
     "ΔV2 = π · (D² − d²) ÷ 4 · Δh\n"
     "ΔV1 = ΔV2\n"
     "V0 · αV · ΔT = π · (D² − d²) ÷ 4 · Δh\n"
     "Δh = V0 · αV · ΔT ÷ (π · (D² − d²) ÷ 4)\n"
     "Δh = 1.500 dm³ · 0,00021 1/K · 75 K ÷ (π · ((10 dm)² − (3 dm)²) ÷ 4)\n"
     "Δh = 0,33 dm = 33 mm",
    ('NT', 3, 'b'):
     "Q1 = mWasser · c · ΔT\n"
     "Q2 = VErdgas · Hi\n"
     "Q1 = η · Q2\n"
     "mWasser · c · ΔT = η · VErdgas · Hi\n"
     "VErdgas = m · c · ΔT ÷ (η · Hi)\n"
     "VErdgas = 1.500 kg · 4,18 kJ/(kg · K) · 75 K ÷ (0,6 · 35.000 kJ/m³)\n"
     "VErdgas = 22,4 m³",
    ('NT', 5, 'b'):
     "Verbraucher 1:\n"
     "R = U ÷ I = 10 V ÷ 0,5 A = 20 Ω\n"
     "P = U² ÷ R = (12 V)² ÷ 20 Ω = 7,2 W\n"
     "Verbraucher 2:\n"
     "R = U ÷ I = 14 V ÷ 0,5 A = 28 Ω\n"
     "P = U² ÷ R = (12 V)² ÷ 28 Ω = 5,1 W",
    ('NT', 6, 'b'):
     "P = W ÷ t\n"
     "P · t = W\n"
     "P · t = m · g · h\n"
     "m = P · t ÷ (g · h)\n"
     "m = 5.035 W · 10 s ÷ (9,81 m/s² · 5,45 m)\n"
     "m = 50.350 Ws ÷ 53,4645 m²/s² = 941,75 kg\n"
     "ρ = m ÷ V → V = m ÷ ρ = 941,75 kg ÷ 1,15 kg/dm³ = 818,9 dm³",
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
    ('MI', 4): (
        'In einem Unternehmen werden für jedes Jahr die durchschnittlich gezahlten '
        'Energiepreise pro kWh und der Energieverbrauch erfasst (siehe Tabelle zu '
        'dieser Aufgabe).'),
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
