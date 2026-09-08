# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen H2024.

Wie beim Jahrgang H2025 setzen die PDFs Formeln als Word-Formelobjekte.
``pdftotext`` zerlegt sie in Zeichenfolgen, in denen Brüche verlorengehen und
Zähler und Nenner hintereinander stehen ("Bestellhäufigkeit = Bestellmenge
840 t/Jahr = = 28 Bestellungen/Jahr 30 t/Bestellung"). Diese Stellen sind hier
aus den Originalseiten übertragen. Vier Lösungen sind reine Zeichnungen und
werden in Worten beschrieben; die Originalskizze hängt zusätzlich als Bild an
der Teilaufgabe (siehe ``anlagen_imbq.py``):

* ``NT 4 a`` – Kräfteparallelogramm der Drohnen- und Windgeschwindigkeit.
* ``NT 6 c`` – Schaltbild der Parallelschaltung mit Spannungs- und Strompfeil.
* ``MI 2 a`` – Flussdiagramm der Schichtübernahme.
* ``MI 4 b`` – Balkendiagramm der prozentualen Kostenveränderungen.

Schlüssel: (Kürzel, Aufgabennummer, Teil-Label).
"""

# ── Lösungshinweise ────────────────────────────────────────────────────────
LOESUNG = {
# ---------------------------------------------------------------- BWL H2024
('BW', 3, 'a'):
 "Sicherheitsbestand = Ø Verbrauch pro Tag · Sicherheitszeit in Tagen\n"
 "Sicherheitsbestand = 3 t/Tag · 5 Tage = 15 t\n"
 "Meldebestand = Verbrauch pro Zeiteinheit · Wiederbeschaffungszeit + Sicherheitsbestand\n"
 "= 3 t/Tag · 5 Tage + 15 t\n"
 "= 30 t",

('BW', 3, 'b'):
 "Bestellmenge = max. Lagerkapazität − Sicherheitsbestand\n"
 "= 45 t − 15 t\n"
 "= 30 t\n"
 "Jahresverbrauch = 280 Tage · 3 t/Tag = 840 t\n"
 "Bestellhäufigkeit = Jahresbedarf ÷ Bestellmenge\n"
 "= 840 t/Jahr ÷ 30 t/Bestellung = 28 Bestellungen/Jahr",

('BW', 3, 'c'):
 "Ø Lagerreichweite = verfügbarer Lagerbestand ÷ Verbrauch pro Tag\n"
 "= 30 t ÷ 3 t/Tag = 10 Tage\n"
 "verfügbarer Lagerbestand = maximale Lagerkapazität − Sicherheitsbestand\n"
 "= 45 t − 15 t = 30 t",

('BW', 4, 'a'):
 "Vorgabezeit = 60 min/h ÷ Normalleistung in Stück/h\n"
 "= 60 min/h ÷ 15 Stück/h = 4 min/Stück",

('BW', 4, 'b'):
 "Prämienlohn = 19,50 €/h + (23,40 €/h − 19,50 €/h) ÷ 3 Stück/h · 2 Stück/h\n"
 "= 22,10 €/h\n"
 "max. Mehrleistung = 15 Stück/h · 1,2 − 15 Stück/h = 3 Stück",

('BW', 5, 'b'):
 "Erzielter Verkaufspreis 34,90 €\n"
 "− Provision 10 % 3,49 €\n"
 "= Barverkaufspreis 31,41 €\n"
 "− Selbstkosten 24,15 €\n"
 "= Gewinn 7,26 €\n"
 "Gewinn [%] = Gewinn ÷ Selbstkosten · 100 = 7,26 € ÷ 24,15 € · 100 = 30,06 %",

('BW', 7, 'a'):
 "xBEP = Kf ÷ (p − kv)\n"
 "= 246.500 €/Monat ÷ (32,50 €/Stück − 18,00 €/Stück) = 17.000 Stück/Monat\n"
 "UBEP = p · xBEP = 32,50 €/Stück · 17.000 Stück/Monat = 552.500 €/Monat\n"
 "BGBEP = xBEP ÷ xmax · 100 = 17.000 Stück/Monat ÷ 20.000 Stück/Monat · 100 = 85 %",

('BW', 7, 'b'):
 "xBEP = (246.500 €/Monat + 17.560 €/Monat) ÷ (32,50 €/Stück − 16,20 €/Stück)\n"
 "= 16.200 Stück/Monat\n"
 "Da die Break-even-Menge durch die Automatisierung im Fertigungsbereich von "
 "17.000 Stück auf 16.200 Stück sinkt, ist die Maßnahme als positiv zu beurteilen.",

('BW', 7, 'c'):
 "BGBEP 75 % → xBEP = 15.000 Stück\n"
 "dbSoll = Kf ÷ xBEP = 247.500 € ÷ 15.000 Stück = 16,50 €/Stück\n"
 "kvSoll = p − db = 32,50 €/Stück − 16,50 €/Stück = 16 €/Stück\n"
 "Die variablen Stückkosten müssen um 2 €/Stück von 18 €/Stück auf 16 €/Stück "
 "gesenkt werden.",

# --------------------------------------------------------------- MIKP H2024
('MI', 2, 'a'):
 "Flussdiagramm (Zeichnung) mit folgendem Ablauf:\n"
 "Beginn → „Anstehende Aufträge übernehmen“ → „Information über Betriebsmittel "
 "entgegennehmen“ → Verzweigung „Alle Betriebsmittel in Ordnung?“\n"
 "– ja: → „Auftragsbearbeitung beginnen“ → Ende\n"
 "– nein: → „Umfang der Störungen der Betriebsmittel prüfen“ → Verzweigung "
 "„Mit eigenen Mitteln zu beheben?“\n"
 "   – ja: → „Störungen der Betriebsmittel mit eigenen Kräften beheben“ → "
 "„Auftragsbearbeitung beginnen“ → Ende\n"
 "   – nein: → „Störungen der Betriebsmittel durch Instandhaltung beheben "
 "lassen“ → „Auftragsbearbeitung beginnen“ → Ende\n"
 "Start und Ende als abgerundete Rechtecke, Tätigkeiten als Rechtecke, "
 "Entscheidungen als Rauten mit beschrifteten Ausgängen.",

('MI', 4, 'a'):
 "ΔK (in %) = (K kommendes Jahr − K laufendes Jahr) ÷ K laufendes Jahr · 100 %\n"
 "– Personalgesamtkosten: 20,0 %\n"
 "– Kosten der Betriebsmittel: −15,0 %\n"
 "– Reisekosten: −20,0 %\n"
 "– Energiekosten: 40,0 %",

('MI', 4, 'b'):
 "Balkendiagramm „prozentuale Veränderungen der Kosten im kommenden Jahr“ "
 "(Zeichnung): waagerechte Balken je Kostenart, Skala von −30 % bis +50 % mit "
 "einer Nulllinie in der Mitte.\n"
 "– Personalgesamtkosten: +20 %\n"
 "– Kosten der Betriebsmittel: −15 %\n"
 "– Reisekosten: −20 %\n"
 "– Energiekosten: +40 %\n"
 "Zuwächse zeigen nach rechts, Rückgänge nach links.",

# ---------------------------------------------------------------- NTG H2024
('NT', 2, 'a'):
 "m = V · ρ = 1,5 dm³ · 1 kg/dm³ = 1,5 kg\n"
 "QWasser = m · c · ΔT\n"
 "QWasser = 1,5 kg · 4,18 kJ/(kg · K) · 80 K = 501,6 kJ\n"
 "Ezu = QWasser ÷ η\n"
 "Ezu = 501,6 kJ ÷ 0,7 = 716,57 kJ\n"
 "Ezu = Pzu · t\n"
 "t = Ezu ÷ Pzu\n"
 "t = 716.570 J ÷ 1.900 W = 716.570 Ws ÷ 1.900 W = 377,14 s\n"
 "= 6 Minuten, 17 Sekunden",

('NT', 3, 'a'):
 "FG = m · g\n"
 "FG = 20.000 kg · 9,81 m/s²\n"
 "FG = 196.200 N\n"
 "FG/3 = FG ÷ 3 = 196.200 N ÷ 3 = 65.400 N\n"
 "FR = FG/3 ÷ cos 30°\n"
 "FR = 65.400 N ÷ cos 30°\n"
 "FR = 75.517,42 N\n"
 "AR = (D² − d²) · π ÷ 4\n"
 "AR = (60² mm² − 50² mm²) · π ÷ 4\n"
 "AR = 863,94 mm²\n"
 "σd = FR ÷ AR\n"
 "σd = 75.517,42 N ÷ 863,94 mm²\n"
 "σd = 87,41 N/mm²",

('NT', 3, 'b'):
 "ν = σd zul ÷ σd\n"
 "ν = 300 N/mm² ÷ 87,41 N/mm²\n"
 "ν = 3,43\n"
 "Die Sicherheitszahl ist mit 3,43 geringer als die geforderte Sicherheit von 4. "
 "Die Vorgabe ist nicht erfüllt.\n"
 "Hinweis für den Korrektor: Bei einer angenommenen Druckspannung von 70 N/mm² "
 "beträgt die Sicherheitszahl 4,3 und erfüllt somit die Bedingungen.",

('NT', 4, 'a'):
 "Kräfteparallelogramm (zeichnerische Lösung): Von einem gemeinsamen Anfangspunkt "
 "wird die Drohnengeschwindigkeit vDrohne = 10 m/s nach Süden abgetragen und die "
 "Windgeschwindigkeit vWind = 8 m/s aus südöstlicher Richtung unter 45° zur "
 "Nord-Süd-Achse. Die Diagonale des aufgespannten Parallelogramms ist die "
 "resultierende Geschwindigkeit.\n"
 "vres = 7,1 m/s\n"
 "Hinweis für den Korrektor: geringe Abweichungen sind zu tolerieren.",

('NT', 4, 'b'):
 "v²res = v²x,Wind + (vy,Drohne − vy,Wind)²  mit  vx,Wind = vy,Wind = √(v²Wind ÷ 2)\n"
 "v²res = (5,66 m/s)² + (4,34 m/s)²\n"
 "vres = √((5,66 m/s)² + (4,34 m/s)²)\n"
 "vres = √(50,87 m²/s²)\n"
 "vres = 7,13 m/s\n"
 "Alternativer Lösungshinweis:\n"
 "v²res = (vWind)² + (vDrohne)² − 2 · vWind · vDrohne · cos 45°\n"
 "v²res = (8 m/s)² + (10 m/s)² − 2 · (8 m/s) · (10 m/s) · cos 45°\n"
 "vres = 7,13 m/s",

('NT', 4, 'c'):
 "vres ÷ sin 45° = vWind ÷ sin α\n"
 "sin α = vWind ÷ vres · sin 45°\n"
 "sin α = 8 m/s ÷ 7,13 m/s · sin 45°\n"
 "α = 52,5°\n"
 "Alternativer Lösungshinweis:\n"
 "tan α = vx,Wind ÷ (vy,Drohne − vy,Wind)\n"
 "tan α = 5,66 m/s ÷ 4,34 m/s = 1,304\n"
 "α = tan⁻¹(1,304) = 52,5°",

('NT', 5, 'a'):
 "ΔR = 60.000 Ω − 200 Ω = 59.800 Ω",

('NT', 5, 'b'):
 "R2 aus Kennlinie: bei 40 °C = 200 Ω\n"
 "UAUS = UEIN · R2 ÷ (R1 + R2)\n"
 "UAUS = 24 V · 200 Ω ÷ (1.000 Ω + 200 Ω) = 4 V\n"
 "Alternativ:\n"
 "I = UEin ÷ (R1 + R2) = 24 V ÷ 1.200 Ω = 0,02 A\n"
 "UAus = R2 · I = 200 Ω · 0,02 A = 4 V",

('NT', 6, 'b'):
 "– Leistung nur R1:\n"
 "I1 = U ÷ R1 = 230 V ÷ 70 Ω = 3,29 A\n"
 "P1 = U · I1 = 230 V · 3,29 A = 756 W\n"
 "– Leistung nur R2:\n"
 "I2 = U ÷ R2 = 230 V ÷ 115 Ω = 2 A\n"
 "P2 = U · I2 = 230 V · 2 A = 460 W\n"
 "– Leistung R1 und R2 in Reihe:\n"
 "I1/2 = U ÷ (R1 + R2) = 230 V ÷ (70 Ω + 115 Ω) = 1,24 A\n"
 "P1/2 = U · I = 230 V · 1,24 A = 285 W\n"
 "– Leistung R1 und R2 parallel:\n"
 "RGes = R1 · R2 ÷ (R1 + R2) = 70 Ω · 115 Ω ÷ (70 Ω + 115 Ω) = 43,5 Ω\n"
 "I = U ÷ RGes = 230 V ÷ 43,5 Ω = 5,29 A\n"
 "P = U · I = 230 V · 5,29 A = 1.217 W\n"
 "Alternativ: Pges = P1 + P2 = 756 W + 460 W = 1.216 W",

('NT', 6, 'c'):
 "Schaltbild (Zeichnung): Die höchste Leistung liefert die Parallelschaltung. "
 "Zu zeichnen ist die Spannungsquelle U mit ihren beiden Klemmen, daran R1 und "
 "R2 nebeneinander im selben Stromkreiszweigpaar (Parallelschaltung). Der "
 "Spannungspfeil U zeigt an der Quelle von der oberen zur unteren Klemme, der "
 "Strompfeil I liegt in der Zuleitung oberhalb des Verzweigungspunktes und zeigt "
 "in Richtung der Widerstände.",

('NT', 6, 'd'):
 "W = P1 · t = 756 W · 2,5 h\n"
 "W = 1.892,5 Wh = 1,893 kWh\n"
 "K = W · k = 1,893 kWh · 0,4 €/kWh = 0,76 €",

('NT', 7, 'c'):
 "Das Schwankungsintervall 95,45 % entspricht dem Intervall x̄ ± 2 · s.\n"
 "xunten = x̄ − 2 · s = 10,14 ml − 2 · 0,22 ml = 9,70 ml\n"
 "xoben = x̄ + 2 · s = 10,14 ml + 2 · 0,22 ml = 10,58 ml",

('NT', 7, 'd'):
 "Gesamtausschuss: 2 % + 5 % = 7 %\n"
 "Anzahl = 180.000 · 7 % ÷ 100 % = 12.600 (Ampullen)",
}

# ── Fragetexte ─────────────────────────────────────────────────────────────
FRAGE = {}


def anwenden(exams):
    """Korrekturen einspielen. Wirft AssertionError, sobald eine Korrektur ins
    Leere läuft – dann hat sich die Quelle geändert und muss neu geprüft werden."""
    treffer = 0
    genutzt_l, genutzt_f = set(), set()
    for ex in exams:
        k = ex['kuerzel']
        for nr, a in ex['loesungen'].items():
            for t in a['teile']:
                neu = LOESUNG.get((k, nr, t['label']))
                if neu is not None:
                    t['loesung'] = neu
                    genutzt_l.add((k, nr, t['label']))
                    treffer += 1
        for nr, a in ex['aufgaben'].items():
            for t in a['teile']:
                neu = FRAGE.get((k, nr, t['label']))
                if neu is not None:
                    t['text'] = neu
                    genutzt_f.add((k, nr, t['label']))
                    treffer += 1
    fehlend = (set(LOESUNG) - genutzt_l) | (set(FRAGE) - genutzt_f)
    assert not fehlend, 'Korrektur greift nicht mehr: %s' % sorted(fehlend)
    return treffer
