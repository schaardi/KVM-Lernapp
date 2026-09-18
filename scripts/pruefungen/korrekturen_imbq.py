# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen H2025.

Die PDFs setzen Formeln als Word-Formelobjekte. ``pdftotext`` löst diese in
Zeichenfolgen auf, bei denen Brüche, Wurzeln und griechische Buchstaben
verlorengehen ("Pab 2,2kW K 0,694 69,4% Pzu 3,17kW"). Solche Stellen sind hier
Zeichen für Zeichen aus den Originalseiten (``quellen/imbq-h2025/seiten``)
übertragen. Zwei weitere Fälle sind Layout-Artefakte:

* ``BW 4 b`` – die amtliche Lösung ist ein Diagramm; hier als Text beschrieben.
* ``BW 5 a`` – die amtliche Lösung ist eine Tabelle auf einer eigenen Seite
  ("Siehe Anlage 1"); hier als Liste übertragen.
* ``ZI 7 a/b`` – ein Fragesatz läuft über beide Teilaufgaben hinweg; beide
  Teile werden zu vollständigen Sätzen ergänzt.

Schlüssel: (Kürzel, Aufgabennummer, Teil-Label).
"""

# ── Lösungshinweise ────────────────────────────────────────────────────────
LOESUNG = {
('BW', 2, 'a'):
 "Ø Lagerbestand = Sicherheitsbestand + Bestellmenge ÷ 2\n"
 "= 2 t + 10 t ÷ 2 = 7 t",

('BW', 2, 'c'):
 "x_opt = √(2 · kB · Xges ÷ (EP · iL))\n"
 "x_opt = √(2 · 180 € · 90 t ÷ (4.500 €/t · 0,2))\n"
 "x_opt = 6 t",

('BW', 2, 'd'):
 "Bestellmenge 10 Tonnen:\n"
 "KB = 9 Bestellungen/Jahr · 180 €/Bestellung = 1.620 €/Jahr\n"
 "KL = (10 t ÷ 2 + 2 t) · 0,2 · 4.500 €/t = 6.300 €\n"
 "Kges = 7.920 €\n\n"
 "Optimale Bestellmenge 6 Tonnen:\n"
 "KB = 15 Bestellungen/Jahr · 180 €/Bestellung = 2.700 €/Jahr\n"
 "KL = (6 t ÷ 2 + 2 t) · 0,2 · 4.500 €/t = 4.500 €\n"
 "Kges = 7.200 €\n\n"
 "Durch Wahl der optimalen Bestellmenge können 720 € eingespart werden.",

('BW', 4, 'a'):
 "Akkordrichtsatz = 30 €/h + (30 €/h · 10 ÷ 100) = 33,00 €/h\n"
 "Stückgeld = Akkordrichtsatz ÷ Normalleistung = 33,00 €/h ÷ 12 Stück/h = 2,75 €/Stück\n"
 "Bruttostundenlohn (Akkordlohn) = 2,75 €/Stück · 13 Stück/h = 35,75 €/h",

('BW', 4, 'b'):
 "Im Akkordlohn bleiben die Lohnkosten je Stück unabhängig vom Leistungsgrad "
 "konstant. Im Diagramm (Lohnkosten in €/Stück über dem Leistungsgrad LG in %) "
 "ergibt sich deshalb eine waagerechte Gerade bei 2,75 €/Stück über den "
 "gesamten dargestellten Bereich von LG 100 % bis 125 %.",

('BW', 5, 'a'):
 "Zuordnung der Geschäftsfälle:\n"
 "– Zahlung von Fertigungslöhnen: 30.000 € → Zweckaufwand\n"
 "– entgangene Zinserträge: 8.000 € → kalkulatorische Kosten\n"
 "– Verbrauch von Rohstoffen bei der Produktion: 50.000 € → Zweckaufwand\n"
 "– Zahlung von Mehrarbeitsstunden: 4.500 € → Zweckaufwand\n"
 "– Spende für „Brot für die Welt“: 500 € → neutraler Aufwand\n"
 "– Zahlung von Beiträgen an die Berufsgenossenschaft: 800 € → Zweckaufwand\n"
 "– Gebühren für die Entsorgung von Produktionsabfällen: 1.200 € → Zweckaufwand\n"
 "– Gewerbesteuernachzahlung für 2024: 5.000 € → neutraler Aufwand\n"
 "– Totalschaden eines betrieblich genutzten Lkw: 16.000 € → neutraler Aufwand\n"
 "– Einbau eines geringwertigen Ersatzteils in eine Produktionsmaschine: "
 "1.500 € → Zweckaufwand",

('NT', 2, 'a'):
 "Dichte von Wasser = 1,0 kg/l; Masse = Dichte · Volumen, d. h. kg entspricht Liter.\n"
 "m1 · c1 · (Θ1 − ΘM) = m2 · c2 · (Θ1 − Θ2)\n"
 "m1 · (Θ1 − ΘM) = m2 · (Θ1 − Θ2)\n"
 "m2 = m1 · (Θ1 − ΘM) ÷ (Θ1 − Θ2)\n"
 "m2 = 15 kg · 40 K ÷ 25 K\n"
 "m2 = 24 kg ⇒ 24 l",

('NT', 3, 'a'):
 "FH ÷ FG ≙ aH ÷ g   mit   FH = FG · sin α\n"
 "sin α = aH ÷ g\n"
 "aH = g · sin α\n"
 "aH = 9,81 m/s² · sin 30°\n"
 "aH = 4,905 m/s²\n\n"
 "Hinweis für den Korrektor: Sollte der Prüfungsteilnehmer die Lösung über die "
 "Kräfte errechnen, ist dies auch als richtig zu werten.",

('NT', 3, 'b'):
 "Ersatzhebel für die Gleichgewichtsüberlegung: a_maxH · 0,36 m = aN · 0,48 m\n\n"
 "aN = g · cos α\n"
 "aN = 9,81 m/s² · cos 30°\n"
 "aN = 8,496 m/s²\n\n"
 "a_maxH · h = aN · l\n"
 "a_maxH = aN · l ÷ h\n"
 "a_maxH = 8,496 m/s² · 0,48 m ÷ 0,36 m\n"
 "a_maxH = 11,328 m/s²\n\n"
 "a = a_maxH − aH\n"
 "a = 11,328 m/s² − 4,905 m/s²\n"
 "a = 6,423 m/s²\n\n"
 "Hinweis für den Korrektor: Sollte der Prüfungsteilnehmer die Lösung über die "
 "Kräfte errechnen, ist dies auch als richtig zu werten.",

('NT', 4, 'a'):
 "V = V0 · (1 − αV · ΔT)\n"
 "Tankvolumen = 25 l; 90 % = 0,9 · 25 l = 22,5 l ⇒ V0 = 22,5 l\n"
 "αV = 0,0011 · 1/K\n"
 "Δϑ = 20 °C − 8 °C = 12 °C ⇒ ΔT = 12 K\n"
 "V = 22,5 l · (1 − 0,0011 · 1/K · 12 K)\n"
 "V = 22,2 l",

('NT', 4, 'b'):
 "V = 25 l; 90 % davon sind 0,9 · 25 l = 22,5 l\n"
 "22,5 l ÷ 1,6 l/h = 14,0625 h ⇒ 14 h 3 min 45 s",

('NT', 4, 'c'):
 "η = Eab ÷ Ezu\n"
 "Eab = 4 kVA = 4 kW · 3.600 s = 14.400 kWs (kJ)\n"
 "Ezu = Q;  Q = Hi · m\n"
 "Hi = 42.000 kJ/kg\n"
 "m = ρ · V;  ρ = 0,8 kg/dm³\n"
 "m = 0,8 kg/dm³ · 1,6 l/h = 1,28 kg/h\n"
 "Q = 42.000 kJ/kg · 1,28 kg/h = 53.760 kJ/h\n"
 "η = 14.400 kJ ÷ 53.760 kJ\n"
 "η = 0,27",

('NT', 5, 'b'):
 "η = Pab ÷ Pzu = 2,2 kW ÷ 3,17 kW = 0,694 = 69,4 %",

('NT', 5, 'c'):
 "ω = 2 · π · n = 2 · π · 2.160 (1/min) ÷ 60 (s/min) = 226,19 s⁻¹\n"
 "M = Pab ÷ ω = 2.200 W ÷ 226,19 s⁻¹ = 9,73 Nm",

('NT', 6, 'a'):
 "I = U ÷ R = 450 V ÷ 300 Ω = 1,5 A\n\n"
 "R24 = R2 + R4 = 200 Ω + 400 Ω = 600 Ω\n"
 "1/R234 = 1/R3 + 1/R24 = 1/300 Ω + 1/600 Ω ⇒ R234 = 200 Ω\n"
 "Rges = R1 + R234 = 100 Ω + 200 Ω = 300 Ω\n\n"
 "U1 = I · R1 = 1,5 A · 100 Ω = 150 V\n"
 "U3 = U − U1 = 450 V − 150 V = 300 V\n"
 "I3 = U3 ÷ R3 = 300 V ÷ 300 Ω = 1 A\n"
 "P3 = U3 · I3 = 300 V · 1 A = 300 W\n\n"
 "I24 = Iges − I3 = 1,5 A − 1 A = 0,5 A\n"
 "P4 = I² · R4 = (0,5 A)² · 400 Ω = 100 W",

('NT', 7, 'a'):
 "Relative Fehleranteile in Prozent (p = Anzahl ÷ 1.400 Stück · 100 %):\n"
 "1. Vorderrad nicht ordnungsgemäß eingebaut: 14 Stück → 1,00 %\n"
 "2. Bremsseil nicht angeschlossen: 6 Stück → 0,43 %\n"
 "3. Kettenschutz verbogen: 7 Stück → 0,50 %\n"
 "4. Kette nicht ordnungsgemäß gespannt: 3 Stück → 0,21 %\n"
 "5. Lenker schwergängig: 15 Stück → 1,07 %\n"
 "6. Lackschäden am Rahmen: 5 Stück → 0,36 %",

('NT', 7, 'b'):
 "relativer Anteil aller Fehler in Prozent:\n"
 "p = g ÷ N · 100 % = 50 Stück ÷ 1.400 Stück · 100 % = 3,57 %",

('NT', 7, 'c'):
 "Fehlerhafte Fahrräder bei n = 165 Stück:\n"
 "x = p · n ÷ 100 % = 3,57 % · 165 Stück ÷ 100 % = 5,89 ⇒ gewählt: 6 Fahrräder\n"
 "In einer Stichprobe von 165 Stück sind 6 fehlerhafte Fahrräder zu erwarten.",
}

# ── Aufgabentexte ──────────────────────────────────────────────────────────
FRAGE = {
# Die Beträge stehen in Anlage 1 auf einer eigenen Seite – hier in die
# Aufgabe geholt, damit sie eigenständig lösbar ist.
('BW', 5, 'a'):
 "In der Industrie GmbH fallen unterschiedlichste Geschäftsfälle an. Ordnen Sie "
 "die folgenden Geschäftsfälle den Begriffen neutraler Aufwand, Zweckaufwand und "
 "kalkulatorische Kosten zu (Anlage 1):\n"
 "– Zahlung von Fertigungslöhnen: 30.000 €\n"
 "– entgangene Zinserträge: 8.000 €\n"
 "– Verbrauch von Rohstoffen bei der Produktion: 50.000 €\n"
 "– Zahlung von Mehrarbeitsstunden: 4.500 €\n"
 "– Spende für „Brot für die Welt“: 500 €\n"
 "– Zahlung von Beiträgen an die Berufsgenossenschaft: 800 €\n"
 "– Gebühren für die Entsorgung von Produktionsabfällen: 1.200 €\n"
 "– Gewerbesteuernachzahlung für 2024: 5.000 €\n"
 "– Totalschaden eines betrieblich genutzten Lkw: 16.000 €\n"
 "– Einbau eines geringwertigen Ersatzteils in eine Produktionsmaschine: 1.500 €",

('ZI', 7, 'a'):
 "Beschreiben Sie, wie Sie mit dieser Situation lösungsorientiert und sachlich "
 "umgehen, um vor allem Ihre Autorität gegenüber dem Seniorchef zu wahren.",
('ZI', 7, 'b'):
 "Beschreiben Sie, wie Sie mit dieser Situation lösungsorientiert und sachlich "
 "umgehen, um vor allem Ihre Autorität gegenüber Ihren Mitarbeitern zu wahren.",
}


# ── Ausgangslagen ──────────────────────────────────────────────────────────
# Schlüssel: (Kürzel, Aufgabennummer).
INTRO = {
    # BWL, Aufgabe 6: Die Tabelle mit Menge und Gesamtkosten der drei Quartale
    # lief als Fließtext in die Ausgangslage ("Quartal 1 2 3 Produktions- und
    # Absatzmenge 680 940 820 Gesamtkosten 3.940.200 € …"). Die Werte hängen
    # jetzt als Tabellenanlage an der Aufgabe.
    ('BW', 6):
     "Die Industrie GmbH produziert in Gütersloh ein spezielles E-Bike, das "
     "stark nachgefragt wird. Bei Vollauslastung können 1.060 Stück pro Quartal "
     "produziert werden. Menge und Gesamtkosten der vergangenen Quartale stehen "
     "in der Tabelle. Die Fixkosten und die variablen Stückkosten sind in den "
     "genannten Quartalen konstant geblieben. Der Verkaufspreis beträgt im "
     "gesamten Zeitraum 5.625 € pro E-Bike.",
}


def anwenden(exams):
    """Korrekturen einspielen. Wirft AssertionError, sobald eine Korrektur ins
    Leere läuft – dann hat sich die Quelle geändert und muss neu geprüft werden."""
    treffer = 0
    genutzt_l, genutzt_f, genutzt_i = set(), set(), set()
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
            neu = INTRO.get((k, nr))
            if neu is not None:
                a['intro'] = neu
                genutzt_i.add((k, nr))
                treffer += 1
            for t in a['teile']:
                neu = FRAGE.get((k, nr, t['label']))
                if neu is not None:
                    t['text'] = neu
                    genutzt_f.add((k, nr, t['label']))
                    treffer += 1
    fehlend = ((set(LOESUNG) - genutzt_l) | (set(FRAGE) - genutzt_f)
               | (set(INTRO) - genutzt_i))
    assert not fehlend, 'Korrektur greift nicht mehr: %s' % sorted(fehlend)
    return treffer
