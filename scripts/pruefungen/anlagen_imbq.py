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
    # ---- Tranche T4 (Scans), Herbst 2017
    ('NT', 'h2017', 3, 'a'): 'nth17-heizstufe2',
    ('NT', 'h2017', 3, 'b'): 'nth17-heizstufe1',
    ('NT', 'h2017', 5, '*'): 'nth17-leuchte',
    ('NT', 'h2017', 6, '*'): 'nth17-zylinder',
    ('NT', 'f2017', 4, '*'): 'ntf17-gleitbahn',
    ('NT', 'f2017', 5, '*'): 'ntf17-strompfade',
    ('NT', 'f2017', 7, '*'): 'ntf17-wnetz',
    ('NT', 'h2016', 2, '*'): 'nth16-schaltung',
    ('BW', 'f2016', 6, '*'): 'bwf16-kosten',
    ('MI', 'f2016', 5, '*'): 'mif16-balkenplan',
    ('NT', 'f2016', 5, '*'): 'ntf16-ventil',
    ('NT', 'f2016', 7, '*'): 'ntf16-urwertkarte',
    ('NT', 'h2015', 3, '*'): 'nth15-seil',
    ('NT', 'h2015', 4, '*'): 'nth15-zylinder',
    ('NT', 'h2015', 6, '*'): 'nth15-ebene',
    ('NT', 'h2015', 7, '*'): 'nth15-wnetz',
    ('NT', 'f2015', 2, '*'): 'ntf15-schaltung',
    ('NT', 'f2015', 4, '*'): 'ntf15-zugstange',
    ('NT', 'f2015', 5, '*'): 'ntf15-rampe',
    ('NT', 'f2015', 6, '*'): 'ntf15-winde',
    ('NT', 'f2015', 7, 'f'): 'ntf15-saeulen',
    ('MI', 'h2014', 4, 'a'): 'mih14-netzplan',
    ('NT', 'h2014', 7, '*'): 'nth14-wnetz',

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

    # ---- Tranche T4 (Scans)
    ('MI', 'h2017', 2, 'b'): 'mih17-l-netzplan',
    ('MI', 'h2017', 4, 'b'): 'mih17-l-sollist',
    ('NT', 'h2017', 7, 'a'): 'nth17-l-histogramm',
    ('MI', 'f2017', 2, 'a'): 'mif17-l-ishikawa',
    ('MI', 'f2017', 4, 'a'): 'mif17-l-netz',
    ('MI', 'f2017', 5, 'a'): 'mif17-l-balken',
    ('NT', 'f2017', 7, 'd'): 'ntf17-l-wnetz',
    ('MI', 'h2016', 4, 'a'): 'mih16-l-nutzwert',
    ('MI', 'h2016', 5, 'a'): 'mih16-l-erzeugnis',
    ('NT', 'h2016', 3, 'a'): 'nth16-l-vtdiagramm',
    ('BW', 'f2016', 6, 'a'): 'bwf16-l-kosten',
    ('MI', 'f2016', 4, 'a'): 'mif16-l-kosten',
    ('NT', 'f2016', 7, 'a'): 'ntf16-l-urwertkarte',
    ('MI', 'h2015', 4, 'a'): 'mih15-l-histogramm',
    ('NT', 'h2015', 7, 'd'): 'nth15-l-wnetz',
    ('BW', 'f2015', 2, 'b'): 'bwf15-l-organigramm',
    ('BW', 'f2015', 5, 'a'): 'bwf15-l-bab',
    ('MI', 'f2015', 3, 'b'): 'mif15-l-kreis',
    ('NT', 'f2015', 7, 'f'): 'ntf15-l-saeulen',
    ('MI', 'h2014', 2, 'a'): 'mih14-l-minmax',
    ('MI', 'h2014', 4, 'a'): 'mih14-l-netzplan',
    ('MI', 'h2014', 4, 'b'): 'mih14-l-balkenplan',
    ('NT', 'h2014', 7, 'a'): 'nth14-l-wnetz',

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

_NETZPLAN_H2017 = {
    'titel': 'Aufgabe 2 b): Vorgänge des Projekts',
    'kopf': ['Nummer', 'Kürzel', 'Dauer', 'Vorgänger'],
    'zeilen': [
        ['1', 'A', '6', 'Start'], ['2', 'B', '8', 'Start'], ['3', 'C', '6', 'A'],
        ['4', 'D', '6', 'A, B'], ['5', 'E', '7', 'B'], ['6', 'F', '5', 'C, D'],
        ['7', 'G', '8', 'D, E'], ['8', 'H', '6', 'F'], ['9', 'I', '4', 'F, G'],
    ],
}

_SCHICHTDICKEN_H2017 = {
    'titel': 'Aufgabe 7: Schichtdicken der Stichprobe (n = 50)',
    'kopf': ['Dicke in µm', 'Anzahl', 'relative Häufigkeit', 'kumulierte relative Häufigkeit'],
    'zeilen': [
        ['32', '1', '2 %', '2 %'], ['33', '4', '8 %', '10 %'],
        ['34', '8', '16 %', '26 %'], ['35', '12', '24 %', '50 %'],
        ['36', '11', '22 %', '72 %'], ['37', '9', '18 %', '90 %'],
        ['38', '4', '8 %', '98 %'], ['39', '1', '2 %', '100 %'],
    ],
}

_RECHTSFORMEN_F2017 = {
    'titel': 'Anlage 1 zu Aufgabe 1: Tabelle ausgewählter Rechtsformen (zu vervollständigen)',
    'kopf': ['Rechtsform', 'Geschäftsführungsbefugnisse', 'Haftungsumfang der Gesellschafter',
             'Mindestgründungskapital der Gesellschaft'],
    'zeilen': [['GmbH', '', '', ''], ['OHG', '', '', ''], ['KG', '', '', '']],
}

_KOSTENSITUATION_F2017 = {
    'titel': 'Anlage 2 zu Aufgabe 6: Kosten- und Erlössituation (leere Felder ergänzen)',
    'kopf': ['Beschäftigungsgrad', 'BG', '80 %', '100 %'],
    'zeilen': [
        ['Menge in Stück', 'x', '', ''],
        ['fixe Stückkosten', 'kf', '12,50 €/Stück', ''],
        ['gesamte Fixkosten', 'Kf', '', ''],
        ['gesamte variable Kosten', 'Kv', '', '1.800.000 €'],
        ['Stückdeckungsbeitrag', 'db', '', ''],
        ['Gesamtdeckungsbeitrag', 'DB', '', '1.440.000 €'],
        ['Betriebsergebnis', 'BE', '', '240.000 €'],
    ],
}

_VORGAENGE_F2017 = {
    'titel': 'Aufgabe 5: Vorgänge des Projekts',
    'kopf': ['Vorgang', 'Beschreibung', 'Dauer in Tagen', 'direkte Vorgänger'],
    'zeilen': [
        ['A', 'Maschinenfundamente errichten', '7', 'Start'],
        ['B', 'Aufstellen der Maschinen', '3', 'A'],
        ['C', 'Anschließen der Maschinen', '2', 'B, E, I'],
        ['D', 'Probelauf der Maschinen', '3', 'C'],
        ['E', 'elektrische Leitungen verlegen', '2', 'A'],
        ['F', 'Innenanstrich', '2', 'E, I'],
        ['G', 'Außenanstrich', '1', 'F, I'],
        ['H', 'Fahrwege in der Halle markieren', '1', 'B, I'],
        ['I', 'Einsetzen der Fenster', '2', 'Start + 2 Tage'],
    ],
}

_FAHRZEUGE_F2017 = {
    'titel': 'Aufgabe 4: Bewertung der Fahrzeuge (Skala 0 bis 10 Punkte)',
    'kopf': ['Kriterien', 'Fahrzeug A', 'Fahrzeug B'],
    'zeilen': [['Spurführung', '8', '6'], ['Nutzlast', '8', '6'],
               ['Batterieladekonzept', '6', '8'], ['Preis', '8', '10'],
               ['maximale Entfernung', '6', '8']],
}

_NUTZWERT_H2016 = {
    'titel': 'Aufgabe 4: Gewichtung der Kriterien und Punktetabellen',
    'kopf': ['Kriterium', 'Gewichtung', '10 Punkte', '8 Punkte', '6 Punkte'],
    'zeilen': [
        ['Maximale Reichweite pro Ladevorgang', '20 %', '> 100 km', '> 60 bis 100 km', '> 40 bis 60 km'],
        ['Anschaffungskosten', '25 %', '≤ 20.000 €', '> 20.000 € und ≤ 30.000 €', '> 30.000 € und ≤ 40.000 €'],
        ['Ladevolumen', '15 %', '2 Kubikmeter', '1,75 Kubikmeter', '1,5 Kubikmeter'],
        ['Nutzlast', '30 %', '> 150 kg', '> 100 kg und ≤ 150 kg', '> 50 kg und ≤ 100 kg'],
        ['Batterie-Ladekonzept', '10 %', 'induktiv', 'Wechselbatterie', 'Ladegerät'],
    ],
}

_STUECKLISTE_H2016 = {
    'titel': 'Aufgabe 5: Strukturstückliste des Erzeugnisses E',
    'kopf': ['lfd. Nummer', 'Ebene 1', 'Ebene 2', 'Ebene 3', 'Anzahl'],
    'zeilen': [
        ['1', 'B2', '', '', '2'], ['2', '', 'T1', '', '2'], ['3', '', 'B1', '', '1'],
        ['4', '', '', 'T2', '2'], ['5', '', '', 'T3', '3'], ['6', '', '', 'T4', '1'],
        ['7', 'T5', '', '', '4'], ['8', 'B3', '', '', '2'], ['9', '', 'T2', '', '3'],
        ['10', '', 'B6', '', '2'], ['11', '', '', 'T1', '4'], ['12', '', '', 'T5', '3'],
        ['13', '', '', 'T6', '2'],
    ],
}

_STICHPROBE_H2016 = {
    'titel': 'Aufgabe 7: Stichprobenergebnisse (Masse in g)',
    'kopf': ['Lfd. Stichprobe', 'Masse in g', 'Lfd. Stichprobe', 'Masse in g'],
    'zeilen': [
        ['1', '21,5', '11', '17,8'], ['2', '19,1', '12', '18,6'], ['3', '18,6', '13', '19,5'],
        ['4', '20,9', '14', '20,7'], ['5', '22,3', '15', '21,3'], ['6', '19,7', '16', '22,0'],
        ['7', '20,1', '17', '18,9'], ['8', '18,9', '18', '19,9'], ['9', '19,4', '19', '21,7'],
        ['10', '22,0', '20', '19,0'],
    ],
}

_PAARVERGLEICH_F2016 = {
    'titel': 'Anlage 1 zu Aufgabe 2: Paarweiser Vergleich (auszufüllen)',
    'kopf': ['', 'Preis', 'Handhabung', 'Lebensdauer', 'Kundendienst', 'laufende Kosten',
             'Summe', 'Gewichtung in Prozent'],
    'zeilen': [['Preis', '–', '', '', '', '', '', ''],
               ['Handhabung', '', '–', '', '', '', '', ''],
               ['Lebensdauer', '', '', '–', '', '', '', ''],
               ['Kundendienst', '', '', '', '–', '', '', ''],
               ['laufende Kosten', '', '', '', '', '–', '', ''],
               ['Summe', '', '', '', '', '', '', '']],
}

_PROJEKTKOSTEN_F2016 = {
    'titel': 'Aufgabe 4: Kennzahlen des Projekts (1. April bis 1. Oktober)',
    'kopf': ['', '01.04.', '01.05.', '01.06.', '01.07.', '01.08.', '01.09.', '01.10.'],
    'zeilen': [
        ['Geplante Gesamtkosten', '80.000 €', '80.000 €', '80.000 €', '80.000 €',
         '80.000 €', '80.000 €', '80.000 €'],
        ['Geplanter Kostenverlauf (kumuliert)', '6.000 €', '10.000 €', '14.000 €',
         '18.000 €', '23.000 €', '28.000 €', '33.000 €'],
        ['Tatsächlicher Kostenverlauf (kumuliert)', '5.000 €', '7.000 €', '11.500 €',
         '17.000 €', '28.000 €', '32.000 €', '36.000 €'],
        ['Geschätzte Restkosten', '75.000 €', '74.000 €', '70.000 €', '66.000 €',
         '59.000 €', '56.000 €', '52.000 €'],
    ],
}

_BECHER_H2014 = {
    'titel': 'Aufgabe 5: Produktionsprogramm des letzten Monates',
    'kopf': ['Typ', 'Produktionsmenge (in Verpackungseinheiten)', 'Gewicht (kg/Verpackungseinheit)'],
    'zeilen': [
        ['S 125 ml', '8.900', '3,50'], ['M 250 ml', '6.750', '4,20'], ['L 500 ml', '3.200', '7,70'],
    ],
}

_BAB_H2014 = {
    'titel': 'Aufgabe 7: Werte aus dem Betriebsabrechnungsbogen',
    'kopf': ['Kostenstelle', 'Fertigungshauptkostenstelle A', 'Fertigungshauptkostenstelle B',
             'Material', 'Verwaltung und Vertrieb'],
    'zeilen': [
        ['Gemeinkosten', '1.603.674 €', '3.284.225 €', '2.839.788 €', '5.495.010 €'],
        ['Fertigungsmaterial', '', '', '22.538.000 €', ''],
        ['Fertigungslohnkosten', '378.225 €', '756.110 €', '', ''],
    ],
}

_HILFSSTOFFE_H2014 = {
    'titel': 'Aufgabe 2: Lagertemperaturen der Hilfsstoffe',
    'kopf': ['Hilfsstoff', 'Minimaltemperatur', 'Maximaltemperatur', 'Lagerbox-Typ'],
    'zeilen': [
        ['A', '2 °C', '10 °C', 'T1'], ['B', '2 °C', '16 °C', 'T1'], ['C', '10 °C', '17 °C', 'T1'],
        ['D', '10 °C', '18 °C', 'T2'], ['E', '10 °C', '15 °C', 'T2'], ['F', '15 °C', '24 °C', 'T2'],
        ['G', '20 °C', '25 °C', 'T3'], ['H', '25 °C', '50 °C', 'T3'], ['I', '25 °C', '42 °C', 'T3'],
    ],
}

_LEISTUNGEN_F2015 = {
    'titel': 'Aufgabe 5: Leistungen der Hilfskostenstellen im April',
    'kopf': ['Empfänger', 'Fuhrpark', 'Arbeitsvorbereitung', 'Instandhaltung'],
    'zeilen': [
        ['Fuhrpark', '–', '–', '–'], ['Material', '900 km', '–', '–'],
        ['Arbeitsvorbereitung', '300 km', '–', '–'],
        ['Instandhaltung', '200 km', '10 %', '–'],
        ['Fertigung A', '400 km', '40 %', '420 Std.'],
        ['Fertigung B', '500 km', '50 %', '480 Std.'],
        ['Verwaltung und Vertrieb', '3.700 km', '–', '–'],
    ],
}

_DB_F2015 = {
    'titel': 'Anlage 2 zu Aufgabe 6: Deckungsbeitragsrechnung (auszufüllen)',
    'kopf': ['', 'Produkt A', 'Produkt B', 'Produkt C', 'Produkt D', 'Summe'],
    'zeilen': [
        ['p (€/Stück)', '18,30', '10,40', '15,20', '7,50', ''],
        ['kv (€/Stück)', '11,98', '6,30', '8,59', '8,43', ''],
        ['db (€/Stück)', '', '', '', '', ''],
        ['x (Stück)', '7.200', '14.300', '9.400', '23.800', ''],
        ['DB (€)', '', '', '', '', ''],
        ['Kf (€)', '', '', '', '', '150.000,00'],
        ['Betriebsergebnis (€)', '', '', '', '', ''],
    ],
}

_BLECHE_F2015 = {
    'titel': 'Aufgabe 7: Blechsorten und Kostenerfahrungswerte',
    'kopf': ['Stärke (mm)', 'Menge (t)', 'Zunahme der Fertigungskosten pro Tonne gegenüber 1,0 mm'],
    'zeilen': [
        ['0,4', '1.500', '40 %'], ['0,6', '1.000', '25 %'],
        ['0,8', '1.800', '5 %'], ['1,0', '2.100', '–'],
    ],
}

_VORGAENGE_F2015 = {
    'titel': 'Aufgabe 2: Abschätzung des Arbeitszeitaufwandes (Dauer in Personentagen)',
    'kopf': ['Vorgänge', 'Dauer'],
    'zeilen': [
        ['Ist-Analyse', '40'], ['Soll-Analyse', '30'], ['Anpassung der Software', '60'],
        ['Installation der Hard- und Software', '50'], ['Tests', '20'],
        ['Einweisung der Mitarbeiter', '20'], ['Dokumentation', '20'],
        ['Summe Tätigkeiten bis hier', '240'], ['geteilt durch 4 Monate', '60'],
        ['geteilt durch 20 Arbeitstage pro Monat', '3'],
        ['Ergebnis', 'Es werden rechnerisch drei Personen benötigt.'],
    ],
}

_FEHLER_F2015 = {
    'titel': 'Aufgabe 3: Fehlerursachen der Pilotanlage',
    'kopf': ['Fehlerursache', 'Anteil an der Gesamtproduktion'],
    'zeilen': [
        ['mangelnde Dokumentation', '8 %'], ['mangelhafte Maßhaltigkeit', '7 %'],
        ['mangelhafte Beschaffenheit der Oberfläche', '5 %'], ['Korrosion', '4 %'],
        ['Gesamtfehlerquote', '24 %'],
    ],
}

_UMSATZ_F2015 = {
    'titel': 'Aufgabe 6: Jahresumsatz je Erzeugnisgruppe',
    'kopf': ['Erzeugnisgruppe', 'Jahresumsatz'],
    'zeilen': [
        ['A', '24.360 €'], ['B', '74.810 €'], ['C', '56.400 €'], ['D', '240.310 €'],
        ['E', '18.160 €'], ['F', '540.200 €'], ['G', '160.200 €'], ['H', '84.240 €'],
        ['gesamt', '1.198.680 €'],
    ],
}

_AIRBAG_F2015 = {
    'titel': 'Aufgabe 7: Auslösezeiten der Stichprobe (n = 32)',
    'kopf': ['Messergebnis in ms', '27', '28', '29', '30', '31', '32', '33', '34'],
    'zeilen': [['absolute Einzelhäufigkeit', '1', '2', '6', '10', '8', '3', '1', '1']],
}

_CONTROLLING_H2015 = {
    'titel': 'Aufgabe 6: Daten aus dem Controlling',
    'kopf': ['Monat', 'August', 'September'],
    'zeilen': [
        ['Produktions- und Absatzmenge', '5.400 Stück', '6.750 Stück'],
        ['Beschäftigungsgrad', '72 %', '90 %'],
        ['Gesamtkosten', '504.000 €', '585.000 €'],
        ['Betriebsergebnis', '–18.000 €', '+22.500 €'],
    ],
}

_ABC_H2015 = {
    'titel': 'Aufgabe 2: Mengen und Einkaufswerte der acht Materialien',
    'kopf': ['Produkt', 'Menge', 'gesamter Einkaufswert'],
    'zeilen': [
        ['A', '4.500', '290.000 €'], ['B', '7.000', '80.000 €'],
        ['C', '11.000', '20.000 €'], ['D', '5.500', '10.000 €'],
        ['E', '9.000', '40.000 €'], ['F', '8.000', '60.000 €'],
        ['G', '4.000', '260.000 €'], ['H', '1.000', '240.000 €'],
    ],
}

_FUELLMENGEN_H2015 = {
    'titel': 'Aufgabe 4: Gemessene Füllmengen (80 Messungen)',
    'kopf': ['Nummer', 'Füllmenge von (g)', 'Füllmenge bis (g)', 'Anzahl'],
    'zeilen': [
        ['1', '65', '66', '2'], ['2', '66', '67', '4'], ['3', '67', '68', '8'],
        ['4', '68', '69', '16'], ['5', '69', '70', '22'], ['6', '70', '71', '14'],
        ['7', '71', '72', '8'], ['8', '72', '73', '4'], ['9', '73', '74', '2'],
    ],
}

_RAUTIEFE_H2015 = {
    'titel': 'Aufgabe 7: Stichprobe – maximale Rautiefe Rmax in µm',
    'kopf': ['Stichprobe', 'Rmax in µm', 'Stichprobe', 'Rmax in µm'],
    'zeilen': [
        ['1', '3,7', '7', '3,8'], ['2', '4,0', '8', '3,9'], ['3', '3,8', '9', '3,4'],
        ['4', '3,9', '10', '3,8'], ['5', '4,1', '11', '3,5'], ['6', '3,6', '12', '3,8'],
    ],
}

_CONTROLLING_H2017 = {
    'titel': 'Aufgabe 7: Daten aus dem Controlling',
    'kopf': ['Monat', 'September', 'Oktober'],
    'zeilen': [
        ['Produktions- und Absatzmenge', '13.500 Stück', '10.800 Stück'],
        ['Beschäftigungsgrad', '90 %', '72 %'],
        ['Gesamtkosten', '1.755.000 €', '1.512.000 €'],
        ['Betriebsergebnis', '+67.500 €', '–54.000 €'],
    ],
}

TABELLEN = {
    ('BW', 'h2017', 7, '*'): _CONTROLLING_H2017,
    ('MI', 'h2017', 2, 'b'): _NETZPLAN_H2017,
    ('NT', 'h2017', 7, '*'): _SCHICHTDICKEN_H2017,
    ('BW', 'f2017', 1, 'a'): _RECHTSFORMEN_F2017,
    ('BW', 'f2017', 6, 'a'): _KOSTENSITUATION_F2017,
    ('MI', 'f2017', 4, '*'): _FAHRZEUGE_F2017,
    ('MI', 'f2017', 5, '*'): _VORGAENGE_F2017,
    ('MI', 'h2016', 4, '*'): _NUTZWERT_H2016,
    ('MI', 'h2016', 5, '*'): _STUECKLISTE_H2016,
    ('NT', 'h2016', 7, '*'): _STICHPROBE_H2016,
    ('MI', 'f2016', 2, '*'): _PAARVERGLEICH_F2016,
    ('MI', 'f2016', 4, '*'): _PROJEKTKOSTEN_F2016,
    ('BW', 'h2015', 6, '*'): _CONTROLLING_H2015,
    ('MI', 'h2015', 2, '*'): _ABC_H2015,
    ('MI', 'h2015', 4, '*'): _FUELLMENGEN_H2015,
    ('NT', 'h2015', 7, '*'): _RAUTIEFE_H2015,
    ('BW', 'f2015', 5, '*'): _LEISTUNGEN_F2015,
    ('BW', 'f2015', 6, '*'): _DB_F2015,
    ('BW', 'f2015', 7, '*'): _BLECHE_F2015,
    ('MI', 'f2015', 2, '*'): _VORGAENGE_F2015,
    ('MI', 'f2015', 3, '*'): _FEHLER_F2015,
    ('MI', 'f2015', 6, '*'): _UMSATZ_F2015,
    ('NT', 'f2015', 7, '*'): _AIRBAG_F2015,
    ('BW', 'h2014', 5, '*'): _BECHER_H2014,
    ('BW', 'h2014', 7, '*'): _BAB_H2014,
    ('MI', 'h2014', 2, '*'): _HILFSSTOFFE_H2014,
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
