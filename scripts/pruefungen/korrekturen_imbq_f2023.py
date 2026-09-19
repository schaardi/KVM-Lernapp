# -*- coding: utf-8 -*-
"""Nachkorrekturen für die IHK-Basisqualifikations-Prüfungen Frühjahr 2023."""
from korrekturen_basis import anwenden as _anwenden

LOESUNG = {}
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


def anwenden(exams):
    return _anwenden(exams, LOESUNG, FRAGE, PUNKTE, LABEL)
