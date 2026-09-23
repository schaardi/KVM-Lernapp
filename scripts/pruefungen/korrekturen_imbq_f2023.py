# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2023."""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
    # Verschachtelte Brüche und Einheitenbrüche aus dem Layout von Hand
    # ausgeschrieben (linear: „Zähler ÷ Nenner“) und nachgerechnet.
    ('BW', 3, 'c'):
     "Bestellmenge x = 500 Stück\n"
     "KL = 250 Stück · 0,125 · 40,00 €/Stück = 1.250 €/Jahr\n"
     "KB = 32 Bestellungen/Jahr · 100 €/Bestellung = 3.200 €/Jahr\n"
     "Kges = 4.450 €/Jahr\n"
     "optimale Bestellmenge xopt = 800 Stück\n"
     "KL = 400 Stück · 0,125 · 40,00 €/Stück = 2.000 €/Jahr\n"
     "KB = 20 Bestellungen/Jahr · 100 €/Bestellung = 2.000 €/Jahr\n"
     "Kges = 4.000 €/Jahr\n"
     "Kostenersparnis bei Wahl der optimalen Bestellmenge: Δ Kges = 450 €/Jahr\n"
     "Kostenersparnis in Prozent: 450 € ÷ 4.450 € · 100 % = 10,11 %",
    ('BW', 5, 'a'):
     "Benennung | Berechnung | Wert (€/Jahr)\n"
     "kalkulatorische Abschreibung | 462.000 € ÷ 12 Jahre = 38.500 €/Jahr | 38.500\n"
     "kalkulatorische Zinsen | 384.000 € ÷ 2 · 0,06 = 11.520 € | 11.520\n"
     "Raumkosten | 35 m² · 14 €/m² · 12 Monate = 5.880 € | 5.880\n"
     "Energiekosten | 13,5 kW · 0,32 €/kWh · 3.000 h = 12.960 € | 12.960\n"
     "Instandhaltungskosten | 384.000 € · 0,07 = 26.880 €/Jahr | 26.880\n"
     "Werkzeugkosten |  | 3.860\n"
     "Maschinenkosten |  | 99.600\n"
     "Maschinenstundensatz = Maschinenkosten/Jahr ÷ geplante Einsatzzeit/Jahr = 99.600 €/Jahr ÷ 3.000 h/Jahr = 33,20 €/h",
    ('NT', 4, 'a'):
     "Benötigte Energie mit Elektroantrieb pro km: 0,2 kWh/km\n"
     "Energie des Fahrzeugs mit 15.000 km Laufleistung:\n"
     "E1 = 15.000 km · 0,2 kWh/km\n"
     "E1 = 3.000 kWh\n"
     "Benötigte Energie mit Benzinantrieb:\n"
     "Masse Benzin pro km und pro Fahrzeug (pro Fahrzeug werden V = 0,07 dm³/km an Benzin benötigt):\n"
     "mB = ρ · V\n"
     "mB = 0,8 kg/dm³ · 0,07 dm³/km\n"
     "mB = 0,056 kg/km\n"
     "E2 = 15.000 km · mB · Hi\n"
     "E2 = 15.000 km · 0,056 kg/km · 42.000 kJ/kg ÷ 3.600 kWs/kWh\n"
     "E2 = 9.800 kWh\n"
     "Eingesparte Energie pro Jahr:\n"
     "E = E2 − E1\n"
     "E = 9.800 kWh − 3.000 kWh\n"
     "E = 6.800 kWh",
    ('NT', 6, 'b'):
     "Spezifischer Widerstand aus der IHK-Formelsammlung: 0,49 Ω · mm²/m\n"
     "Querschnitt des Konstantandrahts:\n"
     "A = d² · π ÷ 4 = (0,6 mm)² · π ÷ 4 = 0,28 mm²\n"
     "Länge des Konstantandrahts:\n"
     "L = R · A ÷ ρ = 15 Ω · 0,28 mm² ÷ (0,49 Ω · mm²/m) = 8,57 m",
# Bewertungstabelle: mehrzeilige Zellen ("gerade noch / akzeptabel") zerrissen die Zeilen.
('MI', 2, 'c'):
 'Punkte | Servicequalität | Verfügbarkeit in Prozent | Reaktionszeit in Stunden | Funktionsumfang | laufende Kosten in €/Tag\n10 | gerade noch akzeptabel | 90 | 10 | 6 | 3.000\n20 | ausreichend | 92 | 8 | 8 | 2.880\n30 | befriedigend | 94 | 6 | 10 | 2.760\n40 | gut | 96 | 4 | 12 | 2.640\n50 | sehr gut | 98 | 3 | 14 | 2.520\n60 | ausgezeichnet | 100 | 2 | 16 | 2.400',

# Paarweiser Vergleich: mehrzeilige Kriterien zerrissen die Tabelle.
('MI', 2, 'b'):
 ' | Servicequalität | Verfügbarkeit | Reaktionszeit | Funktionsumfang | laufende Kosten | Summe | Faktor\nServicequalität | – | 2 | 1 | 2 | 0 | 5 | 25 %\nVerfügbarkeit | 0 | – | 2 | 1 | 0 | 3 | 15 %\nReaktionszeit | 1 | 0 | – | 2 | 0 | 3 | 15 %\nFunktionsumfang | 0 | 1 | 0 | – | 1 | 2 | 10 %\nlaufende Kosten | 2 | 2 | 2 | 1 | – | 7 | 35 %\nSummen |  |  |  |  |  | 20 | 100 %\nHinweis für den Korrektor: Es sollen je 2 Punkte für jede richtige Zeile (bis zur Zeilensumme) vergeben werden und die restlichen beiden Punkte für die Umrechnung der Zeilensummen in Gewichtungsfaktoren.',
}
FRAGE = {
    # BWL, Aufgabe 7 a): Die Gegenüberstellung von Neuanschaffung und
    # Umrüstung steht im Heft als Tabelle; pdftotext legt sie zerrissen mitten
    # in den Aufgabentext ("variable Kosten pro Fixkosten pro max. Kapazität
    # Stück Monat Neuanschaffung 200 € …"). Die Werte hängen jetzt als
    # Tabellenanlage an der Aufgabe (anlagen_imbq._MASCHINENVARIANTEN).
    ('BW', 7, 'a'):
     "Während einer Sitzung der Führungskräfte wurde diskutiert, welche "
     "Variante bei einer bekannten Produktionsmenge von bis zu 125 Stück/Monat "
     "die Bessere ist: Entweder die Neuanschaffung einer Maschine oder die "
     "kostengünstigere Umrüstung der bereits vorhandenen Maschine. Beide "
     "Varianten weisen unterschiedliche Kostenverläufe und Maximalkapazitäten "
     "auf. Berechnen Sie, bei welcher Stückzahl pro Monat beide Varianten zu "
     "gleichen Kosten führen und begründen Sie, welcher Variante Sie bei einer "
     "bekannten Stückzahl von 125 Stück/Monat den Vorzug geben.",
}

PUNKTE = {
    # BWL, Aufgabe 6 a): Fixkosten, Break-Even-Umsatz und Betriebsergebnis –
    # der Aufgabenteil weist dafür 10 Punkte aus, das Lösungsheft druckt 3.
    ('BW', 6, 'a'): 10,
}

LABEL = {
    # Recht, Aufgabe 8: Das Lösungsheft druckt beide Teile als "a"; der zweite
    # (4 Punkte, Haftung nach ProdHaftG) ist Teil b.
    ('RE', 8, 1): 'b',
}


INTRO = {
    # NTG, Aufgabe 7: Die Messwerte der 15 Stichproben stehen im Heft als
    # Tabelle und landen sonst als Zahlenkette in der Ausgangslage.
    ('NT', 7): (
        'Während eines Kühlprozesses bei der Herstellung von Lebensmitteln wird die '
        'Kühltemperatur überwacht.\n'
        'Es liegen die Werte für die Temperaturmessung der letzten 15 Stichproben in '
        'der Tabelle zu dieser Aufgabe vor.'),
}


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL, intro=INTRO)
