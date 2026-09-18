# -*- coding: utf-8 -*-
"""Nachkorrekturen an den OCR-Texten der Original-IHK-Prüfungen.

Die Prüfungs-PDFs enthalten die Aufgaben als Bild, der Text stammt also aus
einer OCR-Erkennung. Die liest zuverlässig, aber nicht fehlerfrei:

* Trennstriche am Zeilenende bleiben stehen („drei exter-\\nnen Dienstleistern“).
* Datenlisten, die im Original als Tabelle stehen, laufen zu einem Absatz
  zusammen und sind dann kaum noch lesbar.
* Anlagen (Tabellen, Diagramme) werden verstümmelt und landen mitunter beim
  falschen Aufgabenteil – in der Prüfung vom 8. Mai 2025 hing die Nutzwert-
  Tabelle aus Anlage 2 am Ende von Aufgabe 1 c) statt bei Aufgabe 1 a), zu der
  sie gehört. Damit war 1 a) ohne die Werte gar nicht lösbar.
* Einzelne Zeichen werden verwechselt: ``$`` statt ``§``, ``I`` statt ``l``,
  ``zZ6M`` statt ``zGM``.

Dieses Modul sammelt alle Korrekturen an einer Stelle. ``anwenden`` prüft, dass
jede Ersetzung auch wirklich greift – ändert sich die Quelle, schlägt der Lauf
fehl, statt eine Korrektur stillschweigend zu verlieren.

Aufruf als Skript (korrigiert die Prüfungen direkt in der Web-App):

    python3 scripts/pruefungen/korrekturen.py index.html
"""
import json
import base64, os
import re
import sys

# --------------------------------------------------------------------------- #
# Textkorrekturen: {Prüfungs-ID: [(alt, neu), ...]}
# Angewandt auf die Ausgangssituation und auf jede Teilaufgabe.
# --------------------------------------------------------------------------- #
TEXTE = {
    # ---------------------------------------------------------------- 20.11.2023
    # Die Kalkulationstabelle des Reisebusses zerfiel in zwei Blöcke: erst alle
    # zwanzig Beschriftungen, dann alle zwanzig Werte. So ist die Aufgabe nicht
    # lösbar; die Zuordnung steht jetzt als Tabellenanlage an der Aufgabe.
    'P-FT-20231120': [
        ('Wiederbeschaffungskosten kalkulierter Restwert\nWert des Reifensatzes Nutzungszeit\nKalkulationszins\nFahrleistung pro Jahr\nVerbrauch Dieselkraftstoff (1,50 €/ I) AdBlue (0,90 €/ |)\nSchmierstoffe\nMaut\nmautpflichtige km pro Jahr\nLebensdauer eines Reifensatzes\nReparatur und Wartungskosten pro Jahr\nSteuern und Versicherungen pro Jahr\nNettolohn Fahrer je Monat\nLohnnebenkosten\nPersonaleinsatzfaktor\nSpesen pro Jahr und Fahrzeug\nGemeinkostenumlage gemäß Betriebsabrechnungsbogen (BAB) je Fahrzeug\nkalkuliertes Einzelwagnis je Fahrzeug\nHinweis: sw Die Entwertung ist mit 60 % zu berücksichtigen.\n380.000 € 95.000 € 3.200 €\n5 Jahre 4%\n115.000 km\n37 /100 km\n0,4 1/1100 km 3,50 €/1.000 km 17,3 Cent/km 92.000 km 130.000 km\n5.400 €\n7.500 €\n2.400 €\n25%\n1,3\n1.250 €\n7.000 € 1.500 €\n',
         'Die Kalkulationsdaten des Fahrzeugs stehen in der Tabelle zu dieser Aufgabe.\n'),
    ],
    # ---------------------------------------------------------------- 12.11.2025
    'P-OK-20251112': [
        # Die Daten beider Buslinien liefen zu einem einzigen Absatz zusammen.
        ('Linie 910:\n'
         'Anzahl Busse: 2 Plätze je 15-m-Bus: 50 Laufleistung je Fahrzeug im Jahr: '
         '67.000 km Anteil Leerkilometer: 3% Linie 920:\n'
         'Plätze je 12-m- Bus: 45 durchschnittliche Wagenkilometer je Arbeitsstunde: '
         '18 km/h Bruttoarbeitsstunden je Fahrdienst im Jahr: 2.200 h Urlaub im Jahr: '
         '225 h Fehlzeiten: 10% erforderliches Fahrpersonal: 5,1 Mitarbeiter '
         'Anteil Leerkilometer: 4.000 km',
         'Linie 910:\n'
         '– Anzahl Busse: 2\n'
         '– Plätze je 15-m-Bus: 50\n'
         '– Laufleistung je Fahrzeug im Jahr: 67.000 km\n'
         '– Anteil Leerkilometer: 3 %\n'
         'Linie 920:\n'
         '– Plätze je 12-m-Bus: 45\n'
         '– durchschnittliche Wagenkilometer je Arbeitsstunde: 18 km/h\n'
         '– Bruttoarbeitsstunden je Fahrdienst im Jahr: 2.200 h\n'
         '– Urlaub im Jahr: 225 h\n'
         '– Fehlzeiten: 10 %\n'
         '– erforderliches Fahrpersonal: 5,1 Mitarbeiter\n'
         '– Anteil Leerkilometer: 4.000 km'),
    ],
    # ---------------------------------------------------------------- 11.11.2025
    'P-FT-20251111': [
        # Dieselben OCR-Reste in der Fahrzeugliste.
        ('Der Fuhrpark umfasst folgende Fahrzeuge: m zehn Überlandbusse\nm zweiReisebusse\nm sieben Sattelkraftfahrzeuge\n– fünf Gliederzüge',
         'Der Fuhrpark umfasst folgende Fahrzeuge:\n– zehn Überlandbusse\n– zwei Reisebusse\n– sieben Sattelkraftfahrzeuge\n– fünf Gliederzüge'),

        # Aufzählungszeichen ("m") und ein Zeilenumbruch mitten in der Angabe.
        ('– Sattelkraftfahrzeug bestehend aus\nm einer Zweiachs-Sattelzugmaschine mit einer zGM von 18 t, einem Leergewicht von 8 t und einer Sattellast von 10t\n– einem Dreiachs-Sattelauflieger (Curtainsider) mit einer zGM von 36 t, einem Leergewicht von 7 t,\neiner Aufliegelast von 10 t mit einer Länge von 13,60 m',
         '– Sattelkraftfahrzeug bestehend aus\n  – einer Zweiachs-Sattelzugmaschine mit einer zGM von 18 t, einem Leergewicht von 8 t und einer Sattellast von 10 t\n  – einem Dreiachs-Sattelauflieger (Curtainsider) mit einer zGM von 36 t, einem Leergewicht von 7 t, einer Aufliegelast von 10 t und einer Länge von 13,60 m'),
        # zZGM gibt es nicht; beim Auflieger ist die zulässige Gesamtmasse gemeint.
        ('– Sattelauflieger nach DIN 12642 in Code-L-Ausführung',
         '– Sattelauflieger nach DIN EN 12642 in Code-L-Ausführung'),
        ('verteilt auf 16 Europaletten mit einem\nGewicht von 1.000 kg/Palette',
         'verteilt auf 16 Europaletten mit einem Gewicht von 1.000 kg/Palette'),
        # Das Diagramm der Anlage ist als Bild nicht lesbar; die OCR lieferte nur
        # Achsenbeschriftung und Striche. Statt des Trümmerfelds steht jetzt eine
        # Beschreibung, aus der sich die Aufgabe lösen lässt.
        # Aus dem Lastverteilungsplan hat die OCR nur Achsenfragmente gelesen
        # ("Ladefläche (m) 2m 4m … ARE | E | ET. u"). Die Zeichnung selbst hängt
        # als Bild an der Aufgabe (BILDER).
        ('m _Nachfolgender Lastverteilungsplan liegt Ihnen vom Sattelauflieger vor:\nLadefläche (m) 2m 4m 6m 8m 10m 12m 28\nARE | E | ET. u\n10t\nst\nLast (t)',
         '– Nachfolgender Lastverteilungsplan des Sattelaufliegers liegt Ihnen vor (siehe Abbildung):'),
        ('eines AssessmentCenters (AC)', 'eines Assessment-Centers (AC)'),
    ],
    # ----------------------------------------------------------------- 08.05.2025
    'P-OK-20250508': [
        # Die Fahrzeugliste trägt noch OCR-Reste der Aufzählungszeichen
        # ("m", "sw") und zusammengelaufene Angaben ("4Llkws,zGM 12t").

        # Die Fahrzeugliste trägt OCR-Reste der Aufzählungszeichen ("m", "sw")
        # und zusammengelaufene Angaben ("4Llkws,zGM 12t").
        ('Der Fuhrpark besteht aus folgenden Fahrzeugen: m 20 Transporter, z6M 3,5 t\nm 4Llkws,zGM 12t\nsw 40 Sattelkraftfahrzeuge, zGM 40t\nm 16 Gliederzüge, zGM 40 t als Kühlfahrzeuge',
         'Der Fuhrpark besteht aus folgenden Fahrzeugen:\n– 20 Transporter, zGM 3,5 t\n– 4 Lkws, zGM 12 t\n– 40 Sattelkraftfahrzeuge, zGM 40 t\n– 16 Gliederzüge, zGM 40 t, als Kühlfahrzeuge'),
        ('nach DIN ISO EN 9001:2015 zertifiziert', 'nach DIN EN ISO 9001:2015 zertifiziert'),
        ('der NutzwertanaIyse durch.', 'der Nutzwertanalyse durch.'),
        ('auf Grundlage des $ 3 der', 'auf Grundlage des § 3 der'),
        # Die Kalkulationsdaten liefen als ein einziger Absatz in die Aufgabe;
        # die Werte hängen jetzt als Tabellenanlage daran (TABELLEN).
        ('Nachfolgende Daten stehen Ihnen zur Verfügung:\nKaufpreis 270.000 € Jahreslaufleistung 96.000 km Nutzungszeit 10 Jahre Kraftstoffverbrauch 35 /100 km Kraftstoffkosten 1,20 €/| jährliche Einsatztage 240 Abschreibung wird zu 40 % den variablen Kosten zugerechnet Kapitalverzinsung 5% Reparaturkosten 3.600 €/Jahr fester Fahrerlohn einschließlich Nebenkosten 57.600 €/Jahr Unternehmerlohn 4.000 €/Jahr Unternehmerrisiko 3.000 €/Jahr Kfz-Steuer 2.800 €/Jahr Kfz-Versicherung 10.200 €/Jahr',
         'Die Kalkulationsdaten des Fahrzeugs stehen in der Tabelle zu dieser Aufgabe.'),
        ('Berechnen Sie jeweils auf zwei Stellen nach dem Komma gerundet\n\n'
         'die variablen Kosten in €/km,',
         'Berechnen Sie – jeweils auf zwei Stellen nach dem Komma gerundet – '
         'die variablen Kosten in €/km.'),
        ('Berechnen Sie jeweils auf zwei Stellen nach dem Komma gerundet\n\n'
         'die gesamten fixen Kosten in €/Tag,',
         'Berechnen Sie – jeweils auf zwei Stellen nach dem Komma gerundet – '
         'die gesamten fixen Kosten in €/Tag.'),
        ('Berechnen Sie jeweils auf zwei Stellen nach dem Komma gerundet\n\n'
         'die Fahrzeugkosten pro 100 kg Fracht',
         'Berechnen Sie – jeweils auf zwei Stellen nach dem Komma gerundet – '
         'die Fahrzeugkosten pro 100 kg Fracht'),
    ],
}

# --------------------------------------------------------------------------- #
# Anhängsel, die durch den Seitenumbruch beim falschen Aufgabenteil gelandet
# sind: {Teilaufgaben-ID: ab dieser Zeichenkette abschneiden}
# --------------------------------------------------------------------------- #
ABSCHNEIDEN = {
    # Anlage 2 gehört zu Aufgabe 1 a) und wird dort als Tabelle eingesetzt.
    'P-OK-20250508-s2': '\nAnlage 2 zu Aufgabe 1 a)',
}

# --------------------------------------------------------------------------- #
# Anlagen als saubere Tabelle: {Teilaufgaben-ID: Tabelle}
# Die App zeigt sie direkt bei der Aufgabe an, zu der sie gehört.
# --------------------------------------------------------------------------- #
_LKW_KALKULATION = {
    'titel': 'Aufgabe 4: Kalkulationsdaten des Kühlfahrzeugs (40 t zGM, '
             '24 t Nutzlast)',
    'kopf': ['Position', 'Wert'],
    'zeilen': [
        ['Kaufpreis', '270.000 €'],
        ['Jahreslaufleistung', '96.000 km'],
        ['Nutzungszeit', '10 Jahre'],
        ['Kraftstoffverbrauch', '35 l/100 km'],
        ['Kraftstoffkosten', '1,20 €/l'],
        ['jährliche Einsatztage', '240'],
        ['Anteil der Abschreibung an den variablen Kosten', '40 %'],
        ['Kapitalverzinsung', '5 %'],
        ['Reparaturkosten', '3.600 €/Jahr'],
        ['fester Fahrerlohn einschließlich Nebenkosten', '57.600 €/Jahr'],
        ['Unternehmerlohn', '4.000 €/Jahr'],
        ['Unternehmerrisiko', '3.000 €/Jahr'],
        ['Kfz-Steuer', '2.800 €/Jahr'],
        ['Kfz-Versicherung', '10.200 €/Jahr'],
    ],
}

TABELLEN = {
    'P-OK-20250508-s8': _LKW_KALKULATION,
    'P-OK-20250508-s9': _LKW_KALKULATION,
    'P-OK-20250508-s10': _LKW_KALKULATION,
    'P-FT-20231120-s7': {
        'titel': 'Aufgabe 3: Kalkulationsdaten des Reisebusses',
        'kopf': ['Position', 'Wert'],
        'zeilen': [
            ['Wiederbeschaffungskosten', '380.000 €'],
            ['kalkulierter Restwert', '95.000 €'],
            ['Wert des Reifensatzes', '3.200 €'],
            ['Nutzungszeit', '5 Jahre'],
            ['Kalkulationszins', '4 %'],
            ['Fahrleistung pro Jahr', '115.000 km'],
            ['Verbrauch Dieselkraftstoff (1,50 €/l)', '37 l/100 km'],
            ['AdBlue (0,90 €/l)', '0,4 l/100 km'],
            ['Schmierstoffe', '3,50 €/1.000 km'],
            ['Maut', '17,3 Cent/km'],
            ['mautpflichtige km pro Jahr', '92.000 km'],
            ['Lebensdauer eines Reifensatzes', '130.000 km'],
            ['Reparatur- und Wartungskosten pro Jahr', '5.400 €'],
            ['Steuern und Versicherungen pro Jahr', '7.500 €'],
            ['Nettolohn Fahrer je Monat', '2.400 €'],
            ['Lohnnebenkosten', '25 %'],
            ['Personaleinsatzfaktor', '1,3'],
            ['Spesen pro Jahr und Fahrzeug', '1.250 €'],
            ['Gemeinkostenumlage gemäß Betriebsabrechnungsbogen (BAB) je Fahrzeug',
             '7.000 €'],
            ['kalkuliertes Einzelwagnis je Fahrzeug', '1.500 €'],
        ],
        'hinweis': 'Die Entwertung ist mit 60 % zu berücksichtigen.',
    },
    'P-OK-20250508-s0': {
        'titel': 'Anlage 2 zu Aufgabe 1 a): Nutzwertanalyse der drei externen '
                 'Dienstleister/Werkstätten',
        'kopf': ['Kriterium', 'Gewichtung (1–10)', 'Werkstatt A (0–100)',
                 'Werkstatt B (0–100)', 'Werkstatt C (0–100)'],
        'zeilen': [
            ['Verrechnungspreis', '8', '60', '80', '70'],
            ['Qualität', '9', '70', '60', '60'],
            ['Reparaturzeit', '5', '100', '40', '60'],
            ['Termintreue', '10', '90', '70', '40'],
            ['technischer Support', '5', '60', '80', '70'],
            ['kaufmännischer Service', '4', '50', '50', '60'],
            ['Entfernung Werkstatt', '10', '80', '70', '80'],
            ['Know-how', '7', '60', '80', '70'],
            ['erreichte Punkte', '', '?', '?', '?'],
            ['Rang', '', '?', '?', '?'],
        ],
        'hinweis': 'Je Kriterium ist der Teilnutzwert aus Gewichtung × Punkten zu '
                   'bilden; die Summe der Teilnutzwerte ergibt die erreichten Punkte '
                   'und daraus die Rangfolge.',
    },
}

# --------------------------------------------------------------------------- #
# --------------------------------------------------------------------------- #
# Anlagen als Bild: {Teilaufgaben-ID: Dateiname in anlagen/}
# Manche Anlagen sind Diagramme (z. B. der Lastverteilungsplan) und lassen sich
# nicht als Tabelle abbilden. Sie werden als JPEG in der Aufgabe eingebettet
# (data-URI) und in App und Web-App direkt angezeigt.
# --------------------------------------------------------------------------- #
BILDER = {
    'P-FT-20251111-s3': 'P-FT-20251111-s3.jpg',  # Lastverteilungsplan Sattelauflieger
}
_ANLAGEN = os.path.join(os.path.dirname(__file__), 'anlagen')


# --------------------------------------------------------------------------- #
# Korrekturen an den Musterlösungen: {Teilaufgaben-ID: [(alt, neu), ...]}
# --------------------------------------------------------------------------- #
LOESUNGEN = {
    # Bezugsgröße war falsch: 281.400 € ÷ 6.499.000 Platz-km sind 4,33 Cent je
    # Nutzplatzkilometer – nicht je 1.000 Nutzplatzkilometer.
    'P-OK-20251112-s13': [
        ('Bezogen auf die Leistungseinheit kostet Linie 910 rund 4,33 Cent und '
         'Linie 920 rund 4,44 Cent je 1.000 Nutzplatzkilometer – Linie 910 arbeitet '
         'damit geringfügig günstiger.',
         'Bezogen auf die Leistungseinheit kostet Linie 910 rund 4,33 Cent je '
         'Nutzplatzkilometer (281.400,00 € ÷ 6.499.000 Platz-km) und Linie 920 rund '
         '4,44 Cent je Nutzplatzkilometer (318.190,28 € ÷ 7.162.852,50 Platz-km) – '
         'Linie 910 arbeitet damit geringfügig günstiger.'),
    ],
}


def anwenden(cases):
    """Korrigiert die Prüfungsfälle in ``cases`` an Ort und Stelle.

    Gibt die Zahl der vorgenommenen Ersetzungen zurück und wirft einen
    ``AssertionError``, sobald eine hinterlegte Korrektur ins Leere läuft.
    """
    treffer = 0
    for c in cases:
        for alt, neu in TEXTE.get(c['id'], []):
            n = 0
            if alt in c.get('context', ''):
                c['context'] = c['context'].replace(alt, neu)
                n += 1
            for s in c['steps']:
                if alt in s['q']:
                    s['q'] = s['q'].replace(alt, neu)
                    n += 1
            assert n, 'Korrektur greift nicht mehr in %s: %r' % (c['id'], alt[:60])
            treffer += n
        for s in c['steps']:
            marke = ABSCHNEIDEN.get(s['id'])
            if marke:
                assert marke in s['q'], 'Abschnitt fehlt in %s: %r' % (s['id'], marke)
                s['q'] = s['q'].split(marke)[0].rstrip()
                treffer += 1
            tab = TABELLEN.get(s['id'])
            if tab:
                s['tab'] = tab
                treffer += 1
            bild = BILDER.get(s['id'])
            if bild:
                pfad = os.path.join(_ANLAGEN, bild)
                assert os.path.exists(pfad), 'Anlage-Bild fehlt: %s' % pfad
                with open(pfad, 'rb') as f:
                    daten = base64.b64encode(f.read()).decode('ascii')
                s['bild'] = 'data:image/jpeg;base64,' + daten
                treffer += 1
            for alt, neu in LOESUNGEN.get(s['id'], []):
                assert alt in s.get('a', ''), 'Lösungskorrektur greift nicht in %s' % s['id']
                s['a'] = s['a'].replace(alt, neu)
                treffer += 1
    return treffer


def _patch_html(pfad):
    """Wendet die Korrekturen auf ``window.KVM_CASES`` in der Web-App an."""
    html = open(pfad, encoding='utf-8').read()
    muster = re.compile(r'(window\.KVM_CASES\s*=\s*)(\[.*?\])(;\s*\n)', re.S)
    m = muster.search(html)
    if not m:
        raise SystemExit('window.KVM_CASES nicht in %s gefunden.' % pfad)
    cases = json.loads(m.group(2))
    treffer = anwenden(cases)
    neu = m.group(1) + json.dumps(cases, ensure_ascii=False, separators=(',', ':')) + m.group(3)
    open(pfad, 'w', encoding='utf-8').write(html[:m.start()] + neu + html[m.end():])
    print('  %s: %d Korrekturen angewandt' % (pfad, treffer))


if __name__ == '__main__':
    _patch_html(sys.argv[1] if len(sys.argv) > 1 else 'index.html')
