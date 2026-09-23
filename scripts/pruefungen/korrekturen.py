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
    # ---------------------------------------------------------------- 15.11.2022
    'P-OK-20221115': [
        # Die Daten der Anlage 3 gehören in die Ausgangslage der Aufgabe 3 –
        # alle drei Teile rechnen damit (zuvor standen sie nur hinter 3 c).
        ('Von der (stillgelegten) Bahnverbindung liegen folgende Daten vor (siehe hierzu Anlage 3).',
         'Von der (stillgelegten) Bahnverbindung liegen folgende Daten vor (Anlage 3):\n'
         'Anzahl Bahnhöfe | 4\n'
         'Verkehrsaufkommen in der HVZ zwischen 05:30 Uhr und 09:29 Uhr | 520 Personen\n'
         'Betriebsleistung (ohne Leerkilometer) | 7,67 Mio. Nutzplatzkilometer/Jahr\n'
         'Strecke | 10 km\n'
         'Für den Betrieb mit den Schnellbussen wird seitens des Aufgabenträgers Folgendes geplant:\n'
         'Reisegeschwindigkeit | 30 km/h\n'
         'Wendezeit an beiden Endpunkten | jeweils 4 min\n'
         'Aufenthalt je Haltestelle (auch Endpunkte) | 1 min\n'
         'Daten der Überland-Omnibusse aus dem unternehmenseigenen Fuhrpark:\n'
         'Sitzplätze | 65\n'
         'Kraftstoffverbrauch | 46 l/100 km\n'
         'Nutzungszeit | 10 Jahre'),
        ('gesamten externen CO;-Kosten', 'gesamten externen CO₂-Kosten'),
        ('(Faktoren: 2,64 kg CO;/l Diesel und 4 Cent/kg CO)',
         '(Faktoren: 2,64 kg CO₂/l Diesel und 4 Cent/kg CO₂)'),
    ],
    # ---------------------------------------------------------------- 20.11.2023
    # Die Kennzeichnung des Aufbaus (EN 12642-XL) ist im Original eine kleine
    # Tabelle; die OCR las sie Zeile für Zeile ohne Spalten.
    'P-FT-20231120': [
        ('EN 12642-XL P (27000 kg)\nVehicle body in compliance (Pis the value) with\n'
         'Loading height up to 200 mm 800 mm max. height\n'
         'Front wall 18000 daN 15000 daN 13500 daN\n'
         'Rear wall —_ _ 8100 daN\n'
         'Side walls _ 10800 daN 10800 daN\n'
         'Number of laths per section\n'
         'XL 0 aluminium / wood\n'
         'Beverages 0 aluminium / wood\n'
         'Daimler 9.5 (pallet stop necessary) 0 aluminium / wood',
         'EN 12642-XL, P (27000 kg) – Vehicle body in compliance with EN 12642-XL (P is the value):\n'
         'Loading height | up to 200 mm | 800 mm | max. height\n'
         'Front wall | 18000 daN | 15000 daN | 13500 daN\n'
         'Rear wall | – | – | 8100 daN\n'
         'Side walls | – | 10800 daN | 10800 daN\n'
         'Number of laths per section (aluminium / wood):\n'
         'XL | 0\n'
         'Beverages | 0\n'
         'Daimler 9.5 (pallet stop necessary) | 0'),
    ],
    # ---------------------------------------------------------------- 07.05.2025
    'P-FT-20250507': [
        # Formel und Messprotokoll kamen als Zeichensalat an. Die Formel ist aus
        # dem Lösungshinweis übernommen (die dort eingesetzten Werte ergeben
        # 2.364 daN); das Messprotokoll ist ein Diagramm, das nicht als Bild
        # vorliegt – die abzulesenden Werte stehen daher in der Ausgangslage.
        ('(Winkel a = 70°, u = 0,4)', '(Winkel α = 70°, μ = 0,4)'),
        ('– Formel Niederzurren:\nVDI: F,= #8. ut\np- sina\n'
         'Im Rahmen der Unfalluntersuchung wurde folgendes Messprotokoll der Bremsverzögerung des Lkws erstellt.\n'
         'o] Q Ki ag 7 r rl N max. Verzögerung E wo- ee e—\nN =\n'
         'S i gs 0-4 “ 4 E en 4 Ä a N 7 Zeit in DD un vun u an m pt Sokunden oO = N Schwell- BremsHauer + zeit PH\n'
         'Stillstand Fhz',
         '– Formel Niederzurren (VDI 2700):\nFV = (cx,y − μ · cz) · FG ÷ (k · μ · sin α)'),
        ('Hierzu nutzen Sie das Gutachten der Unfallaufnahme.',
         'Hierzu nutzen Sie das Gutachten der Unfallaufnahme. Im Rahmen der Unfalluntersuchung '
         'wurde ein Messprotokoll der Bremsverzögerung des Lkws erstellt (Diagramm: Verzögerung '
         'über der Zeit in Sekunden, mit Schwellzeit, Bremsdauer und Stillstand des Fahrzeugs).\n'
         'Hinweis: Das Diagramm liegt in dieser Fassung nicht als Bild vor. Abzulesen sind eine '
         'maximale Verzögerung von 0,6 g und eine Einwirkdauer von ca. 0,4 Sekunden.'),
        ('unter Berücksichtigung von g = 10,0 mis?.', 'unter Berücksichtigung von g = 10,0 m/s².'),
    ],
    # ---------------------------------------------------------------- 20.11.2023
    # Die Kalkulationstabelle des Reisebusses zerfiel in zwei Blöcke: erst alle
    # zwanzig Beschriftungen, dann alle zwanzig Werte. So ist die Aufgabe nicht
    # lösbar; die Zuordnung steht jetzt als Tabellenanlage an der Aufgabe.
    'P-FT-20231120': [
        ('Wiederbeschaffungskosten kalkulierter Restwert\nWert des Reifensatzes Nutzungszeit\nKalkulationszins\nFahrleistung pro Jahr\nVerbrauch Dieselkraftstoff (1,50 €/ I) AdBlue (0,90 €/l)\nSchmierstoffe\nMaut\nmautpflichtige km pro Jahr\nLebensdauer eines Reifensatzes\nReparatur und Wartungskosten pro Jahr\nSteuern und Versicherungen pro Jahr\nNettolohn Fahrer je Monat\nLohnnebenkosten\nPersonaleinsatzfaktor\nSpesen pro Jahr und Fahrzeug\nGemeinkostenumlage gemäß Betriebsabrechnungsbogen (BAB) je Fahrzeug\nkalkuliertes Einzelwagnis je Fahrzeug\nHinweis:\n– Die Entwertung ist mit 60 % zu berücksichtigen.\n380.000 € 95.000 € 3.200 €\n5 Jahre 4%\n115.000 km\n37 l/100 km\n0,4 1/1100 km 3,50 €/1.000 km 17,3 Cent/km 92.000 km 130.000 km\n5.400 €\n7.500 €\n2.400 €\n25%\n1,3\n1.250 €\n7.000 € 1.500 €\n',
         'Die Kalkulationsdaten des Fahrzeugs stehen in der Tabelle zu dieser Aufgabe.\n'),
    ],
    # ---------------------------------------------------------------- 12.11.2025
    'P-OK-20251112': [
        # Die Daten beider Buslinien setzt der Parser als Tabelle; übrig bleibt
        # ein Trennfehler der OCR.
        ('Plätze je 12-m- Bus:', 'Plätze je 12-m-Bus:'),
    ],
    # ---------------------------------------------------------------- 11.11.2025
    'P-FT-20251111': [
        # Dieselben OCR-Reste in der Fahrzeugliste.
        ('Der Fuhrpark umfasst folgende Fahrzeuge:\n– zehn Überlandbusse\n– zweiReisebusse\n– sieben Sattelkraftfahrzeuge\n– fünf Gliederzüge',
         'Der Fuhrpark umfasst folgende Fahrzeuge:\n– zehn Überlandbusse\n– zwei Reisebusse\n– sieben Sattelkraftfahrzeuge\n– fünf Gliederzüge'),

        # Aufzählungszeichen ("m") und ein Zeilenumbruch mitten in der Angabe.
        ('– Sattelkraftfahrzeug bestehend aus\n– einer Zweiachs-Sattelzugmaschine mit einer zGM von 18 t, einem Leergewicht von 8 t und einer Sattellast von 10t\n– einem Dreiachs-Sattelauflieger (Curtainsider) mit einer zGM von 36 t, einem Leergewicht von 7 t, einer Aufliegelast von 10 t mit einer Länge von 13,60 m',
         '– Sattelkraftfahrzeug bestehend aus\n  – einer Zweiachs-Sattelzugmaschine mit einer zGM von 18 t, einem Leergewicht von 8 t und einer Sattellast von 10 t\n  – einem Dreiachs-Sattelauflieger (Curtainsider) mit einer zGM von 36 t, einem Leergewicht von 7 t, einer Aufliegelast von 10 t und einer Länge von 13,60 m'),
        # zZGM gibt es nicht; beim Auflieger ist die zulässige Gesamtmasse gemeint.
        ('– Sattelauflieger nach DIN 12642 in Code-L-Ausführung',
         '– Sattelauflieger nach DIN EN 12642 in Code-L-Ausführung'),
        # Das Diagramm der Anlage ist als Bild nicht lesbar; die OCR lieferte nur
        # Achsenbeschriftung und Striche. Statt des Trümmerfelds steht jetzt eine
        # Beschreibung, aus der sich die Aufgabe lösen lässt.
        # Aus dem Lastverteilungsplan hat die OCR nur Achsenfragmente gelesen
        # ("Ladefläche (m) 2m 4m … ARE | E | ET. u"). Die Zeichnung selbst hängt
        # als Bild an der Aufgabe (BILDER).
        ('– Nachfolgender Lastverteilungsplan liegt Ihnen vom Sattelauflieger vor:\nLadefläche (m) 2m 4m 6m 8m 10m 12m 28\nARE E ET. u\n10t\nst\nLast (t)',
         '– Nachfolgender Lastverteilungsplan des Sattelaufliegers liegt Ihnen vor (siehe Abbildung):'),
        ('eines AssessmentCenters (AC)', 'eines Assessment-Centers (AC)'),
    ],
    # ----------------------------------------------------------------- 08.05.2025
    'P-OK-20250508': [
        # Die Fahrzeugliste trägt noch OCR-Reste der Aufzählungszeichen
        # ("m", "sw") und zusammengelaufene Angaben ("4Llkws,zGM 12t").

        # Die Fahrzeugliste trägt OCR-Reste der Aufzählungszeichen ("m", "sw")
        # und zusammengelaufene Angaben ("4Llkws,zGM 12t").
        ('Der Fuhrpark besteht aus folgenden Fahrzeugen:\n– 20 Transporter, z6M 3,5 t\n– 4Llkws,zGM 12t\n– 40 Sattelkraftfahrzeuge, zGM 40t\n– 16 Gliederzüge, zGM 40 t als Kühlfahrzeuge',
         'Der Fuhrpark besteht aus folgenden Fahrzeugen:\n– 20 Transporter, zGM 3,5 t\n– 4 Lkws, zGM 12 t\n– 40 Sattelkraftfahrzeuge, zGM 40 t\n– 16 Gliederzüge, zGM 40 t, als Kühlfahrzeuge'),
        ('nach DIN ISO EN 9001:2015 zertifiziert', 'nach DIN EN ISO 9001:2015 zertifiziert'),
        ('der NutzwertanaIyse durch.', 'der Nutzwertanalyse durch.'),
        ('auf Grundlage des $ 3 der', 'auf Grundlage des § 3 der'),
        # Die Kalkulationsdaten liefen als ein einziger Absatz in die Aufgabe;
        # die Werte hängen jetzt als Tabellenanlage daran (TABELLEN).
        ('Nachfolgende Daten stehen Ihnen zur Verfügung:\nKaufpreis | 270.000 €\nJahreslaufleistung | 96.000 km\n'
         'Nutzungszeit | 10 Jahre\nKraftstoffverbrauch | 35 l/100 km\nKraftstoffkosten | 1,20 €/l\n'
         'jährliche Einsatztage | 240\nAbschreibung wird zu 40 % den variablen Kosten zugerechnet\n'
         'Kapitalverzinsung | 5%\nReparaturkosten | 3.600 €/Jahr\n'
         'fester Fahrerlohn einschließlich Nebenkosten | 57.600 €/Jahr\nUnternehmerlohn | 4.000 €/Jahr\n'
         'Unternehmerrisiko | 3.000 €/Jahr\nKfz-Steuer | 2.800 €/Jahr\nKfz-Versicherung | 10.200 €/Jahr',
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
    # Das leere Formular „Gründe für ein Mitarbeiterjahresgespräch“ (Anlage 2)
    # hing als Zeichensalat an der letzten Teilaufgabe; es steht jetzt als
    # ausfüllbare Tabelle bei 2 a) bzw. 5 a).
    'P-OK-20221115-s5': '\nAnlage 2 zu Aufgabe 2 a)',
    'P-FT-20250507-s13': '\nAnlage 2 zu Aufgabe 5 a)',
    # Die Daten der Anlage 3 standen nur bei 3 c) – gebraucht werden sie in
    # allen drei Teilen; sie stehen jetzt in der Ausgangslage der Aufgabe.
    'P-OK-20221115-s8': '\nAnlage 3 zu Aufgabe 3',
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

# Anlage 2 der Prüfungen vom 15.11.2022 (Aufgabe 2 a) und 7.5.2025
# (Aufgabe 5 a): ein leeres Formular, drei Gründe je Sichtweise.
_GESPRAECH_KOPF = ['', '… aus Sicht der Mitarbeiter', '… aus Sicht der Führungskräfte',
                   '… aus Sicht des Unternehmens']
_GESPRAECH = {
    'titel': 'Anlage 2: Gründe für ein Mitarbeiterjahresgespräch …',
    'kopf': _GESPRAECH_KOPF,
    'zeilen': [['1.', '', '', ''], ['2.', '', '', ''], ['3.', '', '', '']],
}


def _gespraech_loesung(dritter_grund):
    return {
        'titel': 'Lösungshinweis: Gründe für ein Mitarbeiterjahresgespräch …, z. B.',
        'kopf': _GESPRAECH_KOPF,
        'zeilen': [
            ['1.', 'Feedback des Mitarbeiters an den Vorgesetzten',
             'Verbesserung der Arbeitsqualität', 'Wertschätzung der Mitarbeiter'],
            ['2.', 'Austausch über gegenseitige Erwartungen',
             'Aufgabenerfüllung für die Zukunft optimieren',
             'Förderung der Motivation der Mitarbeiter'],
            ['3.', dritter_grund, 'verstärkte Wahrnehmung der Führungskompetenz',
             'Optimierung der Kommunikation'],
        ],
    }


def _als_text(tab, einleitung):
    """Eine Lösungstabelle zusätzlich als lesbarer Text (Zeilen "a | b | c")."""
    zeilen = [' | '.join(tab['kopf'])] + [' | '.join(z) for z in tab['zeilen']]
    return einleitung + '\n' + '\n'.join(zeilen)


_GESPRAECH_L22 = _gespraech_loesung('Identifikation von etwaigem Entwicklungsbedarf')
_GESPRAECH_L25 = _gespraech_loesung('Identifikation von evtl. Entwicklungsbedarf')

TABELLEN = {
    'P-OK-20221115-s3': _GESPRAECH,
    'P-FT-20250507-s11': _GESPRAECH,
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
# Lösungen, die im Original als ausgefüllte Anlage stehen – die Web-App
# vergleicht sie Zelle für Zelle mit dem ausgefüllten Formular.
TABELLEN_L = {
    'P-OK-20221115-s3': _GESPRAECH_L22,
    'P-FT-20250507-s11': _GESPRAECH_L25,
}

BILDER = {
    'P-FT-20251111-s3': 'P-FT-20251111-s3.jpg',  # Lastverteilungsplan Sattelauflieger
}
_ANLAGEN = os.path.join(os.path.dirname(__file__), 'anlagen')


# --------------------------------------------------------------------------- #
# Korrekturen an den Musterlösungen: {Teilaufgaben-ID: [(alt, neu), ...]}
# --------------------------------------------------------------------------- #
LOESUNGEN = {
    # Tabellenzeile: „-“ als Mal (5.500 € · 12 Monate = 66.000 €)
    'P-OK-20210518-s1': [
        ('(5.500 € - 12 Monate)', '(5.500 € · 12 Monate)'),
    ],
    # „Anhänge I und I B“ – die römischen Einsen las die OCR als Striche
    'P-FT-20251111-s1': [
        ('„Lenkzeit“ die Dauer der Lenktätigkeit, aufgezeichnet entweder: — vollautomatisch oder halbautomatisch durch Kontrollgeräte im Sinne der Anhänge und B der Verordnung (EWG) Nr. 3821/85, oder — von Hand gemäß den Anforderungen des Artikels 16 Absatz 2 der Verordnung (EWG) Nr. 3821/85\n(3 Punkte) Arbeitszeit, z. B.:',
         '„Lenkzeit“: die Dauer der Lenktätigkeit, aufgezeichnet entweder\n– vollautomatisch oder halbautomatisch durch Kontrollgeräte im Sinne der Anhänge I und I B der Verordnung (EWG) Nr. 3821/85 oder\n– von Hand gemäß den Anforderungen des Artikels 16 Absatz 2 der Verordnung (EWG) Nr. 3821/85 (3 Punkte)\nArbeitszeit, z. B.:'),
        ('– Abfahrtskontrolle\n=\nReinigung', '– Abfahrtskontrolle\n– Reinigung'),
    ],
    # Die frühere Korrektur zu P-OK-20251112-s13 ("je 1.000 Nutzplatzkilometer")
    # betraf die nicht amtliche Musterlösung; der amtliche Lösungshinweis
    # enthält den Satz nicht mehr.
    #
    # Wortformeln: Die OCR las den Bruchstrich der Vorlage als "+". Die
    # Zahlenrechnungen darunter korrigiert rechenzeichen.py; die Formeln in
    # Worten lassen sich nicht nachrechnen und stehen deshalb hier.
    # "46 l/100 km" kam als "461/100 km", das Liter-Zeichen als Strich, der
    # verschwand; die Rechnung selbst geht auf (124.000 · 0,46 = 57.040;
    # 57.040 · 2,64 · 0,04 · 10 = 60.234,24).
    'P-OK-20221115-s8': [
        ('124.000 km : 461/100 km = 57.040 l', '124.000 km · 46 l/100 km = 57.040 l'),
        ('57.040 2,64 kg/l - 0,04 €/kg - 10 = 60.234,24 €',
         '57.040 l · 2,64 kg/l · 0,04 €/kg · 10 = 60.234,24 €'),
    ],
    'P-OK-20231121-s4': [
        ('24 + 10 + 24 +2 = 60', '24 + 10 + 24 + 2 = 60'),
        ('Umlauf + Takt: 60 ÷60', 'Umlauf ÷ Takt: 60 ÷ 60'),
        ('Hinweis für den Korrektur:', 'Hinweis für den Korrektor:'),
    ],
    'P-OK-20231121-s8': [
        ('= Transportkosten + Anzahl Aufträge', '= Transportkosten ÷ Anzahl Aufträge'),
    ],
    'P-OK-20231121-s9': [
        ('Auslastungsgrad der Transportmittel\n– tatsächliche Betriebsstunden + mögliche Betriebsstunden',
         'Auslastungsgrad der Transportmittel = tatsächliche Betriebsstunden ÷ mögliche Betriebsstunden'),
        ('· 100 =80 %', '· 100 = 80 %'),
    ],
    'P-OK-20231121-s10': [
        ('pro Woche + Zahl der Aufträge', 'pro Woche ÷ Zahl der Aufträge'),
        ('‚Abweichung', 'Abweichung'),
        ('Maßnahmen:\nFahrverhalten prüfen\nBehaviour-Based-Safety-Schulung (BBS-Einführung) '
         'Ladungssicherungsmaßnahmen prüfen\nWarenumschlagsprozess prüfen',
         'Maßnahmen:\n– Fahrverhalten prüfen\n– Behaviour-Based-Safety-Schulung (BBS-Einführung)\n'
         '– Ladungssicherungsmaßnahmen prüfen\n– Warenumschlagsprozess prüfen'),
    ],
    'P-OK-20231121-s11': [
        ('Transporte + Anzahl Transporte', 'Transporte ÷ Anzahl Transporte'),
        ('· 100=95 %', '· 100 = 95 %'),
        ('‚Abweichung', 'Abweichung'),
    ],
}


# --------------------------------------------------------------------------- #
# Musterlösungen, die neu gesetzt werden: {Teilaufgaben-ID: Text}
# Die OCR las die dreispaltige Lösungstabelle zeilenweise über alle Spalten
# hinweg; der Text war nicht mehr zuzuordnen.
# --------------------------------------------------------------------------- #
LOESUNG_TEXT = {
    # Zerfallene Tabellen, Formulare und Brüche – aus den Seitenbildern bzw. der
    # OCR neu geschrieben und nachgerechnet (Checkliste S. 37, Formulare S. 184,
    # Kostenvergleich S. 202, Lastverteilung S. 177, Überholvorgang S. 76).
    'P-OK-20211116-s0':
        'Checkliste, z. B.:\nPrüfpunkt | Ja | Nein | Nicht zutreffend | Maßnahme | Termin/verantwortlich\nPrüfungen durch den Benutzer |  |  |  |  |\n1. Gibt es Schäden am Fahrzeug (Rahmen, Batteriekasten, Karosserie)? |  |  |  |  |\n2. Ist der Ölstand am Antrieb in Ordnung? |  |  |  |  |\n3. Ist der Kühlwasserstand in Ordnung? |  |  |  |  |\n4. Ist die Batterie in einwandfreiem Zustand und ausreichend gefüllt? |  |  |  |  |\n5. Ist das Fahrerschutzdach ohne Schäden, auch an den Befestigungen? |  |  |  |  |\n6. Ist die Griffigkeit der Pedale ausreichend? |  |  |  |  |\n7. Ist die Innenbeleuchtung (sofern erforderlich) funktionsfähig? |  |  |  |  |\n8. Ist die Beleuchtung (Blinker, Bremslicht) in Ordnung? |  |  |  |  |\n9. Ist die Hupe funktionsfähig? |  |  |  |  |\n10. Sind die Sicherheitseinrichtungen in Ordnung (z. B. Sperre gegen Weiterfahrt bei Regal- und Kommissionierstaplern bei Anwesenheit eines Fußgängers in Schmalgängen)? |  |  |  |  |\n11. Sind die Räder bzw. Reifen in Ordnung (Schäden, Fremdkörper im Profil, Profiltiefe – besonders bei Außeneinsatz)? |  |  |  |  |\n12. Sind Deichsel und Lenkung frei von Rissen und Verformungen? |  |  |  |  |\n13. Ist das Lenkspiel maximal zwei Finger breit? |  |  |  |  |\n14. Sind Stellteile frei von Schäden (Risse, Verformungen)? |  |  |  |  |\n15. Sind Betriebs- und Feststellbremse in ordnungsgemäßem Zustand? |  |  |  |  |\n16. Findet an der Hydraulik keine Absenkung in Nullstellung statt? |  |  |  |  |\n17. Sind die Hydraulikleitungen in einwandfreiem Zustand? |  |  |  |  |\n18. Sind die Gabelzinken nicht verbogen, haben sie keine Risse, sind sie nicht zu stark abgeschliffen und ist die Befestigung in Ordnung? |  |  |  |  |\n19. Prüfung Flurförderzeug gemäß DGUV-Vorschrift 68? |  |  |  |  |\n20. Ist das Traglastdiagramm angebracht? |  |  |  |  |\nDatum:\nUnterschrift:\n(18 Punkte für die Prüfpunkte und 2 Punkte für die praxistaugliche Checkliste, insgesamt max. 20 Punkte)',
    'P-OK-20251112-s11':
        'Die Qualifikationsmatrix ist ein Instrument, das in einer Tabelle die Qualifikationsanforderungen der Arbeitsaufgabe und die vorhandenen Qualifikationen der Mitarbeiter darstellt. Z. B.:\nTätigkeit/Arbeiten | MA 1 | MA 2 | MA 3 | MA 4 | MA 5 | MA 6\nFahrzeugannahme |  |  |  |  |  |\nVorbereitung HU |  |  |  |  |  |\nDurchführung AU |  |  |  |  |  |\nFahrzeugelektrik (HV) |  |  |  |  |  |\nKarosseriearbeiten |  |  |  |  |  |\nÖlwechsel |  |  |  |  |  |\nReifenwechsel |  |  |  |  |  |\nusw. |  |  |  |  |  |\nEine angemessene Bewertung der einzelnen Qualifikationen der Mitarbeiter muss in die einzelnen Zellen eingefügt werden (z. B. ja/nein, +/− etc.).\nHinweis für den Korrektor: Auch andere fachlich richtige Antworten können entsprechend gewertet werden.',
    'P-OK-20251112-s12':
        'Z. B.:\nBewertungsbogen\nSchulung Modul … (nach Berufskraftfahrer-Qualifikationsgesetz – BKrFQG)\n| ++ | + | 0 | − | − −\nDer Methodenmix trug zum besseren Verständnis der Seminarinhalte bei. | ☐ | ☐ | ☐ | ☐ | ☐\nDie Inhalte der Schulung wurden verständlich vermittelt. | ☐ | ☐ | ☐ | ☐ | ☐\nDie Stoffmenge war für die Zeitdauer des Seminars angemessen. | ☐ | ☐ | ☐ | ☐ | ☐\nDie Zeit für Fragen und Diskussionen war angemessen. | ☐ | ☐ | ☐ | ☐ | ☐\nHat der Inhalt der Schulung das vermittelt, was Sie erwartet haben? | ☐ | ☐ | ☐ | ☐ | ☐\nHat die Schulung die Themen abgedeckt, die Sie erwartet haben? | ☐ | ☐ | ☐ | ☐ | ☐\nWie zufrieden waren Sie mit der Zeitverteilung und den verschiedenen Themen? | ☐ | ☐ | ☐ | ☐ | ☐\nGab es genügend Praxisbeispiele? | ☐ | ☐ | ☐ | ☐ | ☐\nDas vermittelte Wissen kann in der Praxis angewendet werden. | ☐ | ☐ | ☐ | ☐ | ☐\nHat der Referent die Themen gut vermittelt? | ☐ | ☐ | ☐ | ☐ | ☐\nWie beurteilen Sie den Zustand der praktischen Ausbildungsgeräte (z. B. Fahrzeug, Stapler)? | ☐ | ☐ | ☐ | ☐ | ☐\nWaren die Seminarunterlagen informativ und hilfreich? | ☐ | ☐ | ☐ | ☐ | ☐\nHinweis für den Korrektor: Auch andere plausible Bewertungskriterien sind entsprechend zu bewerten.',
    'P-OK-20211116-s6':
        'Maßnahmen bezüglich der Verpackung (ADR), z. B.:\n– Schutz gegen Kurzschluss\n– Maßnahmen zur Minimierung der Auswirkungen von Erschütterungen oder Vibrationen\n– Batterie einzeln in flüssigkeitsdichte Innenverpackung\n– jede Innenverpackung mit ausreichender Menge nicht brennbarem und nicht leitendem Wärmedämmstoff umgeben\n– UN-geprüfte Außenverpackung der Verpackungsgruppe II\nMaßnahmen bezüglich der Kennzeichnung/Dokumente, z. B.:\n– Kennzeichnung „Defekte Lithium-Ionen-Batterie“\n– Gefahrensymbol Klasse 9\n– Transportgenehmigung der zuständigen Behörde als Begleitdokument\n– im Beförderungspapier vermerken: „Beförderung vereinbart gemäß den Bedingungen des Abschnitts 1.5.1 des ADR“',
    'P-OK-20211116-s8':
        'Personalentwicklungsmaßnahmen für ältere Mitarbeiter, z. B.:\nTechnische Veränderung der Arbeitsbedingungen:\n– ergonomische Maßnahmen\n– Verringerung der körperlichen Belastung\nGestaltung der Arbeitszeit:\n– Altersteilzeitarbeit\n– Teilzeit mit Abfindungsausgleich\n– Jobsharing\nSonstige Gestaltung der Vertragsbedingungen:\n– Versetzung\n– Änderungskündigung\n– vorzeitige Beendigung des Arbeitsvertrags\n– individuelle Vertragsgestaltung\n– Zahlung der Betriebsrente i. V. m. vorzeitigem Altersruhegeld\nWeitgehend altersbeständig sind z. B.:\n– der Wissensumfang\n– die Konzentrationsfähigkeit\n– die sprachlichen Kenntnisse\n– die Widerstandsfähigkeit bei normaler Belastung\n– die Fähigkeit, Alltagsprobleme zu lösen\nMit dem Alter wachsen in der Regel z. B.:\n– die Arbeits- und Berufserfahrung\n– die Urteilsfähigkeit\n– die Sozialkompetenz\n– Verantwortungsbewusstsein und Zuverlässigkeit\n– Ausgeglichenheit und Kontinuität\n– das Streben nach Sicherheit',
    'P-OK-20210518-s2':
        'geschätzte Wiederbeschaffungskosten (49.700 €) − Wiederverkauf (3.500 €) − Reifenkosten (2.200 €) = 44.000 € (1 Punkt)\n50 % von 44.000 € verteilt auf 5 Jahre | 4.400,00 €\nTreibstoffkosten (13,2 l · 1,21 € ÷ 100 km · 95.000 km) | 15.173,40 €\nReifenkosten (2.200 € ÷ 85.000 km · 95.000 km) | 2.458,82 €\nSchmierstoffe | 550,00 €\nWartung | 2.200,00 €\nGesamt | 24.782,22 €\n(je Nennung 1 Punkt)\nKilometersatz: 24.782,22 € ÷ 95.000 km = 0,26 €',
    'P-FT-20230515-s0':
        't = s ÷ (v2 − v1)\n= (16,5 m + 50 m + 16,5 m + 50 m) ÷ (24,44 m/s − 23,88 m/s)\n= 237,5 s\n= 3,96 min',
    'P-FT-20230515-s1':
        's = v2 · t\n= 24,44 m/s · 241,82 s\n= 5.910,08 m\n= 5,91 km',
    'P-FT-20230515-s2':
        't = s ÷ (v2 − v1)\n= 133 m ÷ (80 km/h − 70 km/h)\n= 133 m ÷ (22,22 m/s − 19,44 m/s)\n= 47,84 s',
    'P-FT-20231120-s13':
        'Kabsolut = KSoll − KIst = 2.200 h/Mo − 1.940,4 h/Mo = 259,6 h/Monat\nKprozentual = Kabsolut ÷ KIst · 100 % = 259,6 h/Mo ÷ 1.940,4 h/Mo · 100 % = 13,38 %\noder:\nKprozentual = Kabsolut ÷ KSoll · 100 % = 259,6 h/Mo ÷ 2.200 h/Mo · 100 % = 11,80 %',
    'P-FT-20231120-s14':
        'Mehrarbeit = 259,6 h/Mo · 60 min/h ÷ (21 Arbeitstage · 15 MA · 0,88) = 56,19 min',
    'P-FT-20251111-s4':
        'Berechnung:\nSres = ((m1 · S1) + (m2 · S2) + (m3 · S3) + …) ÷ (m1 + m2 + m3 + …)\nSres = ((1.000 · 0,4) + (1.000 · 1,20) + (1.000 · 2,00) + …) ÷ (1.000 + 1.000 + 1.000 + …)\nSres = (400 + 1.200 + 2.000 + 2.800 + 3.600 + 4.400 + 5.200 + 6.000 + 6.800 + 7.600 + 8.400 + 9.200 + 10.000 + 10.800 + 11.600 + 12.400) ÷ 16.000 ⇒ 102.400 ÷ 16.000 = 6,40 m\nSres = Gesamtschwerpunkt (m)\nm = Gewicht des jeweiligen Ladegutes (kg)\nS = Schwerpunkt des jeweiligen Ladegutes zur Stirnwand (m) (6 Punkte)\nBegründung:\nDer Gesamtschwerpunkt des Ladungsgewichts von 16.000 kg liegt bei 6,40 m und erfüllt somit die Schwerpunktlage nach Lastverteilungsplan. (2 Punkte)',
    'P-OK-20260507-s6':
        'Kosten pro Jahr | Diesel-Lkw | Batterie-Lkw\nAbschreibung | 120.000 € ÷ 8 a = 15.000 €/a | 320.400 € · 50 % = 160.200 € → 160.200 € ÷ 8 a = 20.025 €/a\nVerzinsung des Kaufpreises | (120.000 € ÷ 2) · 3 % = 1.800 €/a | (160.200 € ÷ 2) · 3 % = 2.403 €/a\nKraftstoff- bzw. Energiekosten | (70.000 km ÷ 100 km) · 1,65 €/l · 27 l = 31.185 €/a | 70.000 km · 0,24 €/kWh · 1,5 kWh/km = 25.200 €/a\nAbschreibung Ladestation (anteilig für 1 Lkw) |  | 80.000 € · 50 % = 40.000 € → 40.000 € ÷ 20 a = 2.000 €/a\nVerzinsung Ladestation (anteilig für 1 Lkw) |  | (40.000 € ÷ 2) · 3 % = 600 €/a\nSumme | 47.985 €/a | 50.228 €/a',
    'P-OK-20260507-s7':
        'Kostendifferenz: 50.228 €/a − 47.985 €/a = 2.243 €/a\nneue Nutzungszeit: 160.200 € ÷ (20.025 €/a − 2.243 €/a) = 9 Jahre',
    'P-OK-20221115-s3': _als_text(_GESPRAECH_L22, 'Gründe für ein Mitarbeiterjahresgespräch, z. B.:'),
    'P-FT-20250507-s11': _als_text(_GESPRAECH_L25, 'Gründe für ein Mitarbeiterjahresgespräch, z. B.:'),
    # Formel und Werte der Mindestvorspannkraft (VDI 2700) statt OCR-Resten
    'P-FT-20250507-s3':
        'Formel Niederzurren (VDI 2700):\n'
        'FV = (cx,y − μ · cz) · FG ÷ (k · μ · sin α)\n'
        'Einzusetzende Zahlenwerte: FG = 4.000 daN; k = 1,8; cx,y = 0,8; μ = 0,4; '
        'cz = 1,0; sin α = 0,94\n'
        'FV = 2.364 daN (4 Punkte)\n'
        'Hinweis für den Korrektor: Die Berechnung mit k = 1,5 ist ebenfalls zu bewerten.\n'
        'Beurteilung: Die durch den Fahrer des Lkws genutzten Zurrgurte ermöglichen keine '
        'ausreichende Sicherung der Ladung. (2 Punkte)',
    # Lagerkennzahlen und Andler-Formel: Brüche und Wurzel waren in der OCR
    # zerfallen (Seite 179). In der Vorlage steht "360 Stück ÷ 10" – gemeint
    # sind 360 Tage.
    'P-FT-20251111-s7':
        'durchschnittlicher Lagerbestand = (Anfangsbestand + Endbestand) ÷ 2\n'
        'durchschnittlicher Lagerbestand: (820 Stück + 580 Stück) ÷ 2 = 700 Stück\n'
        'Jahresverbrauch: 820 Stück + (6 · 710 Stück) + (4 · 625 Stück) − 580 Stück = 7.000 Stück\n'
        'Lagerumschlagshäufigkeit: 7.000 Stück ÷ 700 Stück = 10\n'
        'durchschnittliche Lagerdauer: 360 Tage ÷ 10 = 36 Tage',
    'P-FT-20251111-s8':
        'xopt = √(2 · kB · xges ÷ (EP · iL))\n'
        'xopt = √(2 · 7.000 Stück · 120 ÷ (12 · 0,14)) = 1.000 Stück',
    # Die Grafik unter dem Korrektor-Hinweis (Verleiher, Entleiher,
    # Leiharbeitnehmer) kam als unlesbarer Zeichensalat an; der Hinweis sagt
    # selbst, dass sie nicht gefordert ist.
    'P-FT-20230515-s12':
        'Z.B.:\n'
        '– Der Arbeitnehmer schließt einen Arbeitsvertrag mit dem Personaldienstleister ab.\n'
        '– Der Personaldienstleister schließt einen Arbeitnehmerüberlassungsvertrag mit dem '
        'Auftraggeber ab.\n'
        '– Der Leiharbeitnehmer hat das Verpflichtungsverhältnis aus dem Arbeits- und '
        'Arbeitnehmerüberlassungsvertrag gegenüber dem Auftraggeber.\n'
        'Hinweis für den Korrektor: Eine grafische Darstellung ist vom Prüfungsteilnehmer '
        'nicht gefordert.',
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
