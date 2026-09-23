# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2023."""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {
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
