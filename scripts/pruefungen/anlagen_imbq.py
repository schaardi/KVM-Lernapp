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
    # Naturwissenschaft und Technik, Frühjahr 2023
    ('NT', 'f2023', 2, '*'): 'ntf23-kettenspanner',
    ('NT', 'f2023', 5, '*'): 'ntf23-ntc',

    # Naturwissenschaft und Technik, Herbst 2023
    ('NT', 'h2023', 3, '*'): 'nth23-winkelprofil',
    ('NT', 'h2023', 4, '*'): 'nth23-schaltbild',
    ('NT', 'h2023', 6, '*'): 'nth23-kiste',
    ('NT', 'h2023', 7, '*'): 'nth23-wnetz',

    # Naturwissenschaft und Technik, Frühjahr 2024
    ('NT', 'f2024', 2, '*'): 'ntf24-ebene',
    ('NT', 'f2024', 3, '*'): 'ntf24-stapler',
    ('NT', 'f2024', 4, '*'): 'ntf24-aufhaengung',
    ('NT', 'f2024', 5, '*'): 'ntf24-schaltplan',

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

    # ---- Archiv „Altklausuren“, Heftform L-ALT 2018. Die Maße stehen nur in
    # der Zeichnung – ohne sie ist die Aufgabe nicht zu rechnen.
    ('NT', 'f2018', 2, '*'): 'ntf18-rohrprofil',
    ('NT', 'f2018', 5, '*'): 'ntf18-schaltung',
    ('NT', 'h2018', 2, '*'): 'nth18-bremsanlage',
    ('NT', 'h2018', 5, '*'): 'nth18-formteil',

    # ---- Archiv „Altklausuren“, Naturwissenschaft und Technik 2019–2022.
    # Ohne diese Abbildungen fehlen der Aufgabe die Maße, die Schaltung oder
    # die Kennlinie – sie ist dann nicht lösbar.
    ('NT', 'f2019', 3, '*'): 'ntf19-tank',
    ('NT', 'f2019', 4, '*'): 'ntf19-rollen',
    ('NT', 'f2019', 6, '*'): 'ntf19-pumpe',
    ('NT', 'h2019', 2, '*'): 'nth19-winkelprofil',
    ('NT', 'h2019', 4, '*'): 'nth19-drohne',
    ('NT', 'h2019', 5, '*'): 'nth19-seilwinde',
    ('NT', 'f2020', 3, '*'): 'ntf20-kran',
    ('NT', 'f2020', 5, '*'): 'ntf20-zaehler',
    ('NT', 'f2020', 6, '*'): 'ntf20-ntc',
    ('NT', 'h2020', 1, '*'): 'nth20-korrosion',
    ('NT', 'h2020', 2, '*'): 'nth20-zugmaschine',
    ('NT', 'h2020', 3, '*'): 'nth20-halbzeug',
    ('NT', 'f2021', 3, 'a'): 'ntf21-vt-muster',
    ('NT', 'f2021', 6, '*'): 'ntf21-heizung',
    ('NT', 'h2021', 3, '*'): 'nth21-wechselspannung',
    ('NT', 'h2021', 4, '*'): 'nth21-foerderanlage',
    ('NT', 'h2021', 5, '*'): 'nth21-zugstange',
    ('NT', 'h2021', 6, '*'): 'nth21-lastenaufzug',
    ('NT', 'f2022', 2, '*'): 'ntf22-bremspedal',
    ('NT', 'f2022', 3, '*'): 'ntf22-filter',
    ('NT', 'f2022', 4, '*'): 'ntf22-foerderband',
    ('NT', 'h2022', 2, '*'): 'nth22-ebene',
    ('NT', 'h2022', 3, '*'): 'nth22-antrieb',
    ('NT', 'h2022', 6, '*'): 'nth22-schaltung',
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

    # ---- Archiv „Altklausuren“, Heftform L-ALT 2018
    ('MI', 'f2018', 4, 'a'): 'mif18-l-diagramm',
    ('BW', 'f2018', 7, 'b'): 'bwf18-l-breakeven',
    ('MI', 'h2018', 4, 'b'): 'mih18-l-unfaelle',

    # ---- Archiv „Altklausuren“ 2019–2022
    ('MI', 'f2019', 2, 'a'): 'mif19-l-fluss',
    ('MI', 'h2019', 4, 'b'): 'mih19-l-verbund',
    ('MI', 'f2021', 2, 'a'): 'mif21-l-eisenhower',
    ('MI', 'f2021', 4, 'c'): 'mif21-l-diagramm',
    # Die acht „Stellen Sie … in einem Diagramm dar“-Aufgaben aus T2. Bei
    # F2022 4 b) ist die amtliche Lösung eine Tabelle, keine Zeichnung – dort
    # trägt der Lösungstext die Zahlen schon.
    ('MI', 'h2019', 2, 'a'): 'mih19-l-ishikawa',
    ('MI', 'f2019', 4, 'b'): 'mif19-l-energie',
    ('MI', 'f2020', 2, 'a'): 'mif20-l-netzplan',
    ('MI', 'f2020', 2, 'b'): 'mif20-l-netzplan',
    ('MI', 'f2020', 4, 'b'): 'mif20-l-fremd',
    ('MI', 'h2020', 4, 'b'): 'mih20-l-kosten',
    ('MI', 'h2021', 4, 'b'): 'mih21-l-lieferant',
    ('MI', 'h2022', 4, 'b'): 'mih22-l-fehler',
    ('NT', 'f2019', 5, 'c'): 'ntf19-l-schaltung',
    ('NT', 'f2020', 7, 'c'): 'ntf20-l-gauss',
    ('NT', 'h2020', 2, 'a'): 'nth20-l-kraefte',
    ('NT', 'h2020', 6, 'a'): 'nth20-l-heizplatte',
    ('NT', 'f2021', 3, 'a'): 'ntf21-l-vt',
    ('NT', 'f2021', 7, 'b'): 'ntf21-l-wnetz',
    ('NT', 'h2021', 7, 'c'): 'nth21-l-wnetz',
    ('NT', 'h2022', 6, 'd'): 'nth22-l-schaltung',
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

# Die „Anlage 1“ dieser drei Aufgaben ist ein Vordruck, den der Prüfling
# ausgefüllt zurückgibt. Die Hefte drucken ihn nicht ab – sie zeigen nur die
# ausgefüllte Fassung im Lösungshinweis. Hier steht deshalb der Vordruck:
# gegeben sind die Zahlen, die auch im Heft gegeben sind, leer ist alles, was
# zu rechnen ist. Ohne ihn ist die Aufgabe nicht lösbar.
_BAB_F2019 = {
    'titel': 'Anlage 1 zu Aufgabe 7: Betriebsabrechnungsbogen Juli (Beträge in €)',
    'kopf': ['Kostenart', 'Summe', 'Kantine', 'Material', 'Arbeits\u00advorbereitung',
             'Fertigung 1', 'Fertigung 2', 'Verwaltung/Vertrieb'],
    'zeilen': [
        ['Hilfslöhne', '84.000', '8.000', '11.000', '–', '32.000', '25.000', '8.000'],
        ['Gehälter', '171.500', '4.200', '5.800', '14.000', '16.400', '12.600', '118.500'],
        ['Betriebsstoffe', '32.600', '200', '2.300', '–', '14.900', '13.840', '1.360'],
        ['Abschreibungen', '84.000', '3.100', '5.400', '1.800', '39.000', '24.500', '10.200'],
        ['Energiekosten', '21.900', '1.000', '2.600', '100', '9.500', '6.500', '2.200'],
        ['sonstige Kosten', '56.000', '', '', '', '', '', ''],
        ['Σ Ist-Gemeinkosten', '450.000', '', '', '', '', '', ''],
        ['Umlage Kantine', '', '', '', '', '', '', ''],
        ['Umlage Arbeitsvorbereitung', '', '', '', '', '', '', ''],
        ['Σ Ist-Gemeinkosten', '450.000', '', '', '', '', '', ''],
        ['Bezugsbasis', '', '', '', '', '', '', ''],
        ['Zuschlagssatz', '', '', '', '', '', '', ''],
    ],
    'hinweis': 'Die leeren Felder sind zu ergänzen. Die sonstigen Kosten und die '
               'Umlagen werden nach den in der Aufgabe genannten Schlüsseln verteilt.',
}

_BAB_H2020 = {
    'titel': 'Anlage 1 zu Aufgabe 5: Betriebsabrechnungsbogen (Beträge in Tsd. €)',
    'kopf': ['Kostenart', 'Summe', 'Gebäude', 'Material', 'Arbeits\u00advorbereitung',
             'Fertigung 1', 'Fertigung 2', 'Verwaltung und Vertrieb'],
    'zeilen': [
        ['Σ Gemeinkosten', '11.450', '2.760', '596', '282', '2.115', '1.378', '4.319'],
        ['Umlage Gebäude', '', '', '', '', '', '', ''],
        ['Umlage Arbeitsvorbereitung', '', '', '', '', '', '', ''],
        ['Σ Gemeinkosten', '11.450', '', '', '', '', '', ''],
        ['Zuschlagsbasis', '', '', '', '', '', '', ''],
        ['Gemeinkostenzuschlagssätze', '', '', '', '', '', '', ''],
    ],
    'hinweis': 'Die leeren Felder sind zu ergänzen. Die Verteilungsschlüssel und die '
               'Einzelkosten stehen in der Aufgabe.',
}

_SOZIALVERSICHERUNG = {
    'titel': 'Anlage 1 zu Aufgabe 5: Zweige der Sozialversicherung',
    'kopf': ['Versicherungsträger', 'Zweig der Sozialversicherung'],
    'zeilen': [['', ''], ['', ''], ['', ''], ['', '']],
    'hinweis': 'Vier Zweige und ihre Träger eintragen.',
}

_NOTENSTATISTIK = {
    'titel': 'Anlage 1 zu Aufgabe 7: Prüfungsergebnisse der Industriemechaniker',
    'kopf': ['Jahrgang', 'Note 1', 'Note 2', 'Note 3', 'Note 4', 'Note 5', 'Note 6',
             'Anzahl der Einzelwerte', 'Σ xi', 'x̄'],
    'zeilen': [
        ['2013', '0', '9', '6', '8', '0', '2', '25', '', ''],
        ['2014', '2', '5', '7', '7', '3', '0', '24', '', ''],
        ['2015', '1', '8', '3', '8', '0', '0', '20', '', ''],
        ['2016', '3', '6', '6', '8', '0', '0', '23', '', ''],
        ['2017', '1', '6', '8', '6', '3', '0', '24', '', ''],
        ['Summen', '', '', '', '', '', '', '', '', ''],
    ],
    'hinweis': 'Die leeren Felder sind zu ergänzen: Σ xi ist die Summe der '
               'Einzelnoten eines Jahrgangs, x̄ sein Notenmittelwert.',
}

_BAB_H2023 = {
    'titel': 'Anlage 1 zu Aufgabe 5 a) und b): Betriebsabrechnungsbogen Mai '
             '(Beträge in €)',
    'kopf': ['Kostenart', 'Summe Gemeinkosten', 'Material', 'Fertigung',
             'Verwaltung', 'Vertrieb'],
    'zeilen': [
        ['Gehälter', '55.982', '3.600', '12.000', '27.982', '12.400'],
        ['Hilfslöhne', '13.000', '5.000', '8.000', '–', '–'],
        ['Heizungskosten', '4.800', '', '', '', ''],
        ['Betriebliche Steuern', '6.500', '', '', '', ''],
        ['Betriebsstoffe', '2.800', '–', '2.800', '–', '–'],
        ['Abschreibung', '14.400', '', '', '', ''],
        ['sonstige Gemeinkosten', '25.898', '3.560', '11.700', '5.998', '4.640'],
        ['Summe Gemeinkosten', '', '', '', '', ''],
        ['Bezugsbasis/Zuschlagsgrundlage in €', '', '', '', '', ''],
        ['Gemeinkostenzuschlagsatz in %', '', '', '', '', ''],
    ],
    'hinweis': 'Material, Fertigung, Verwaltung und Vertrieb sind '
               'Hauptkostenstellen. Die leeren Felder sind zu ergänzen.',
}

_AUFTRAGSDATEN_H2018 = {
    'titel': 'Aufgabe 4: Auftragsdaten der Fertigungsplanung für Oktober',
    'kopf': ['Produkt', 'Menge pro Monat', 'Losgröße', 'Rüstzeit pro Los',
             'Zeit je Einheit'],
    'zeilen': [
        ['A', '2.400 Stück', '400 Stück', '200 min', '64 min'],
        ['B', '1.500 Stück', '300 Stück', '120 min', '150 min'],
        ['C', '1.000 Stück', '125 Stück', '75 min', '70 min'],
        ['D', '2.500 Stück', '250 Stück', '70 min', '28 min'],
    ],
}

_AUFTRAGSDATEN_F2024 = {
    'titel': 'Aufgabe 2: Auftragsdaten der Fertigungsplanung für Juni',
    'kopf': ['Produkt', 'Produktionsmenge pro Monat', 'Losgröße',
             'Rüstzeit pro Los', 'Zeit je Einheit'],
    'zeilen': [
        ['A', '4.000 Stück', '500 Stück', '180 min', '25 min'],
        ['B', '2.500 Stück', '500 Stück', '152 min', '44 min'],
        ['C', '900 Stück', '300 Stück', '75 min', '30 min'],
        ['D', '500 Stück', '500 Stück', '275 min', '75 min'],
    ],
}

_QUARTALSKOSTEN_H2025 = {
    'titel': 'Aufgabe 6: Menge und Gesamtkosten der vergangenen Quartale',
    'kopf': ['Quartal', '1', '2', '3'],
    'zeilen': [
        ['Produktions- und Absatzmenge', '680', '940', '820'],
        ['Gesamtkosten', '3.940.200 €', '4.778.700 €', '4.391.700 €'],
    ],
}

_MASCHINENVARIANTEN = {
    'titel': 'Aufgabe 7: Kostenverläufe und Maximalkapazitäten der beiden Varianten',
    'kopf': ['', 'variable Kosten pro Stück', 'Fixkosten pro Monat', 'max. Kapazität'],
    'zeilen': [
        ['Neuanschaffung', '200 €', '16.428 €', '150 Stück'],
        ['Umrüstung', '256 €', '8.700 €', '200 Stück'],
    ],
}

TABELLEN = {
    ('BW', 'h2024', 6, 'a'): _KOSTENTABELLE,
    ('BW', 'h2024', 6, 'b'): _KOSTENTABELLE,
    ('BW', 'h2025', 5, 'a'): _GESCHAEFTSFAELLE,
    ('BW', 'f2019', 7, 'a'): _BAB_F2019,
    ('BW', 'h2020', 5, 'a'): _BAB_H2020,
    ('RE', 'h2022', 5, 'a'): _SOZIALVERSICHERUNG,
    ('NT', 'f2018', 7, 'a'): _NOTENSTATISTIK,
    ('BW', 'f2023', 7, 'a'): _MASCHINENVARIANTEN,
    ('BW', 'h2018', 4, 'a'): _AUFTRAGSDATEN_H2018,
    ('BW', 'f2024', 2, '*'): _AUFTRAGSDATEN_F2024,
    ('BW', 'h2025', 6, '*'): _QUARTALSKOSTEN_H2025,
    ('BW', 'h2023', 5, '*'): _BAB_H2023,
}


def anwenden(schritt, kuerzel, jahrgang, nr, label):
    """Anlagen an einen gebauten Schritt hängen. Gibt die Trefferzahl zurück.

    Das Label ``'*'`` gilt für **alle** Teile einer Aufgabe – so steht eine
    Abbildung, auf die sich mehrere Teilaufgaben beziehen, nur einmal in der
    Tabelle. Beim Umbau auf das Aufgabenblatt wandert sie dann von selbst an
    die Aufgabe (siehe ``aufgaben_modell.zerlegen``).
    """
    n = 0
    for k in ((kuerzel, jahrgang, nr, '*'), (kuerzel, jahrgang, nr, label)):
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
