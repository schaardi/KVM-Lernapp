# -*- coding: utf-8 -*-
"""Ordnet den Teilaufgaben der BQ-Prüfungen ihre Anlagen zu.

Viele Aufgaben verweisen auf eine Abbildung, eine Kennlinie oder eine Anlage;
ohne sie lässt sich die Aufgabe nicht lösen. Die Bilder liegen zentral in
``anlagen/`` (siehe ``anlagen_bau.py``) und werden über ihren Schlüssel
referenziert – ``bild`` erscheint bei der Frage, ``bildL`` bei der Lösung.
Tabellenanlagen stehen hier als Struktur und werden als ``tab`` angezeigt.

Schlüssel: (Kürzel, Jahrgang, Aufgabennummer, Teil-Label).
"""

# ---------------------------------------------------------- Bild zur Aufgabe
BILDER = {
    # Naturwissenschaft und Technik, Herbst 2024
    ('NT', 'h2024', 3, 'a'): 'nt24-stuetzbock',
    ('NT', 'h2024', 3, 'b'): 'nt24-stuetzbock',
    ('NT', 'h2024', 4, 'a'): 'nt24-flug-wind',
    ('NT', 'h2024', 4, 'b'): 'nt24-flug-wind',
    ('NT', 'h2024', 4, 'c'): 'nt24-flug-wind',
    ('NT', 'h2024', 5, 'a'): 'nt24-ntc',
    ('NT', 'h2024', 5, 'b'): 'nt24-ntc',
    ('NT', 'h2024', 5, 'c'): 'nt24-ntc',
    ('NT', 'h2024', 7, 'a'): 'nt24-wnetz',
    ('NT', 'h2024', 7, 'b'): 'nt24-wnetz',
    ('NT', 'h2024', 7, 'c'): 'nt24-wnetz',
    # Naturwissenschaft und Technik, Herbst 2025
    ('NT', 'h2025', 3, 'a'): 'nt25-rampe',
    ('NT', 'h2025', 3, 'b'): 'nt25-rampe',
    ('NT', 'h2025', 3, 'c'): 'nt25-rampe',
    ('NT', 'h2025', 5, 'a'): 'nt25-typenschild',
    ('NT', 'h2025', 5, 'b'): 'nt25-typenschild',
    ('NT', 'h2025', 5, 'c'): 'nt25-typenschild',
    ('NT', 'h2025', 5, 'd'): 'nt25-typenschild',
    ('NT', 'h2025', 6, 'a'): 'nt25-schaltung',
}

# ------------------------------------------------- Bild zum Lösungshinweis
# Bei diesen Aufgaben ist die Zeichnung die Lösung; Text allein trägt nicht.
BILDER_L = {
    ('NT', 'h2024', 4, 'a'): 'nt24-l-kraefte',
    ('NT', 'h2024', 6, 'c'): 'nt24-l-schaltbild',
    ('NT', 'h2024', 7, 'a'): 'nt24-l-wnetz',
    ('MI', 'h2024', 2, 'a'): 'mi24-l-fluss',
    ('MI', 'h2024', 4, 'b'): 'mi24-l-diagramm',
    ('BW', 'h2025', 4, 'b'): 'bw25-l-akkord',
}

# ------------------------------------------------------- Tabellen-Anlagen
_KOSTENTABELLE = {
    'titel': 'Anlage 1 zu Aufgabe 6',
    'kopf': ['Fertigungsmenge (Stück)', 'fixe Kosten insgesamt (€)',
             'fixe Kosten pro Stück (€)', 'variable Kosten insgesamt (€)',
             'variable Kosten pro Stück (€)', 'Gesamtkosten (€)',
             'Stückkosten (€)'],
    'zeilen': [
        ['1.000', '', '', '', '', '', ''],
        ['2.000', '', '', '', '', '', ''],
        ['2.500', '', '168', '500.000', '', '', ''],
        ['4.000', '', '', '', '', '', ''],
    ],
    'hinweis': 'Die leeren Felder sind zu ergänzen; zwei Werte sind vorgegeben.',
}

_GESCHAEFTSFAELLE = {
    'titel': 'Anlage 1 zu Aufgabe 5',
    'kopf': ['Geschäftsfälle', 'Betrag in €', 'neutraler Aufwand',
             'Zweckaufwand', 'kalkulatorische Kosten'],
    'zeilen': [
        ['Zahlung von Fertigungslöhnen', '30.000', '', '', ''],
        ['entgangene Zinserträge', '8.000', '', '', ''],
        ['Verbrauch von Rohstoffen bei der Produktion', '50.000', '', '', ''],
        ['Zahlung von Mehrarbeitsstunden', '4.500', '', '', ''],
        ['Spende für „Brot für die Welt“', '500', '', '', ''],
        ['Zahlung von Beiträgen an die Berufsgenossenschaft', '800', '', '', ''],
        ['Gebühren für die Entsorgung von Produktionsabfällen', '1.200', '', '', ''],
        ['Gewerbesteuernachzahlung für 2024', '5.000', '', '', ''],
        ['Totalschaden eines betrieblich genutzten LKW', '16.000', '', '', ''],
        ['Einbau eines geringwertigen Ersatzteils in eine Produktionsmaschine',
         '1.500', '', '', ''],
    ],
    'hinweis': 'Jeder Geschäftsfall ist genau einer der drei Spalten zuzuordnen.',
}

TABELLEN = {
    ('BW', 'h2024', 6, 'a'): _KOSTENTABELLE,
    ('BW', 'h2024', 6, 'b'): _KOSTENTABELLE,
    ('BW', 'h2025', 5, 'a'): _GESCHAEFTSFAELLE,
}


def anwenden(schritt, kuerzel, jahrgang, nr, label):
    """Anlagen an einen gebauten Schritt hängen. Gibt die Trefferzahl zurück."""
    k = (kuerzel, jahrgang, nr, label)
    n = 0
    if k in BILDER:
        schritt['bild'] = BILDER[k]
        n += 1
    if k in BILDER_L:
        schritt['bildL'] = BILDER_L[k]
        n += 1
    if k in TABELLEN:
        schritt['tab'] = TABELLEN[k]
        n += 1
    return n


def pruefe(vorhandene_bilder):
    """Alle referenzierten Bildschlüssel müssen als Datei existieren."""
    fehlend = sorted({v for v in list(BILDER.values()) + list(BILDER_L.values())}
                     - set(vorhandene_bilder))
    assert not fehlend, 'Bildanlage fehlt in anlagen/: %s' % fehlend
