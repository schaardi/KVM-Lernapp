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
import re
import sys

# --------------------------------------------------------------------------- #
# Textkorrekturen: {Prüfungs-ID: [(alt, neu), ...]}
# Angewandt auf die Ausgangssituation und auf jede Teilaufgabe.
# --------------------------------------------------------------------------- #
TEXTE = {
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
        ('– zweiReisebusse', '– zwei Reisebusse'),
        ('sowie Ver-\nstöße', 'sowie Verstöße'),
        ('mit einer zGM von 18 t, einem Leergewicht von 8 t und einer\n'
         'Sattellast von 10t',
         'mit einer zGM von 18 t, einem Leergewicht von 8 t und einer '
         'Sattellast von 10 t'),
        # zZGM gibt es nicht; beim Auflieger ist die zulässige Gesamtmasse gemeint.
        ('mit einer zZGM von 36 t, einem Leergewicht von 7 t,\n'
         'einer Aufliegelast von 10 t mit einer Länge von 13,60 m',
         'mit einer zGM von 36 t, einem Leergewicht von 7 t, '
         'einer Aufliegelast von 10 t und einer Länge von 13,60 m'),
        ('– Sattelauflieger nach DIN 12642 in Code-L-Ausführung',
         '– Sattelauflieger nach DIN EN 12642 in Code-L-Ausführung'),
        ('verteilt auf 16 Europaletten mit einem\nGewicht von 1.000 kg/Palette',
         'verteilt auf 16 Europaletten mit einem Gewicht von 1.000 kg/Palette'),
        # Das Diagramm der Anlage ist als Bild nicht lesbar; die OCR lieferte nur
        # Achsenbeschriftung und Striche. Statt des Trümmerfelds steht jetzt eine
        # Beschreibung, aus der sich die Aufgabe lösen lässt.
        ('– Nachfolgender Lastverteilungsplan liegt Ihnen vom Sattelauflieger vor:\n'
         'Ladefläche (m) 2m 4m 6m 8m 10m 12m 25t / \\ 20t Fi rau . 10t 5t - Last ()',
         '– Nachfolgender Lastverteilungsplan liegt Ihnen vom Sattelauflieger vor '
         '(Beschreibung der Anlage): Die waagerechte Achse zeigt den Abstand des '
         'Ladungsschwerpunkts von der Stirnwand (0 m bis 13,60 m, beschriftet in '
         'Schritten von 2 m), die senkrechte Achse die dort jeweils höchstzulässige '
         'Last (5 t bis 25 t). Die zulässige Last steigt von der Stirnwand aus an, '
         'erreicht zwischen 6 m und 8 m ihr Maximum von rund 25 t und fällt zum Heck '
         'hin wieder ab.'),
        ('eines AssessmentCenters (AC)', 'eines Assessment-Centers (AC)'),
    ],
    # ----------------------------------------------------------------- 08.05.2025
    'P-OK-20250508': [
        ('Der Fuhrpark besteht aus folgenden Fahrzeugen: m 20 Transporter, zZ6M 3,5t\n'
         '– 4Lkws, zGM 12t\n'
         '– 40 Sattelkraftfahrzeuge, zGM 40t\n'
         '– 16 Gliederzüge, zGM 40 t als Kühlfahrzeuge',
         'Der Fuhrpark besteht aus folgenden Fahrzeugen:\n'
         '– 20 Transporter, zGM 3,5 t\n'
         '– 4 Lkw, zGM 12 t\n'
         '– 40 Sattelkraftfahrzeuge, zGM 40 t\n'
         '– 16 Gliederzüge, zGM 40 t als Kühlfahrzeuge'),
        ('nach DIN ISO EN 9001:2015 zertifiziert', 'nach DIN EN ISO 9001:2015 zertifiziert'),
        ('‚Aufgrund des aktuellen', 'Aufgrund des aktuellen'),
        ('von drei exter-\nnen Dienstleistern', 'von drei externen Dienstleistern'),
        ('der NutzwertanaIyse durch.', 'der Nutzwertanalyse durch.'),
        ('ist unter ande-\nrem eine Anpassung', 'ist unter anderem eine Anpassung'),
        ('auf Grundlage des $ 3 der', 'auf Grundlage des § 3 der'),
        ('Kaufpreis 270.000 € Jahreslaufleistung 96.000 km Nutzungszeit 10 Jahre '
         'Kraftstoffverbrauch 35 /100 km Kraftstoffkosten 1,20 €/l jährliche '
         'Einsatztage 240 Abschreibung wird zu 40 % den variablen Kosten zugerechnet '
         'Kapitalverzinsung 5% Reparaturkosten 3.600 €/Jahr fester Fahrerlohn '
         'einschließlich Nebenkosten 57.600 €/Jahr Unternehmerlohn 4.000 €/Jahr '
         'Unternehmerrisiko 3.000 €/Jahr Kfz-Steuer 2.800 €/Jahr Kfz-Versicherung '
         '10.200 €/Jahr',
         '– Kaufpreis: 270.000 €\n'
         '– Jahreslaufleistung: 96.000 km\n'
         '– Nutzungszeit: 10 Jahre\n'
         '– Kraftstoffverbrauch: 35 l/100 km\n'
         '– Kraftstoffkosten: 1,20 €/l\n'
         '– jährliche Einsatztage: 240\n'
         '– Abschreibung wird zu 40 % den variablen Kosten zugerechnet\n'
         '– Kapitalverzinsung: 5 %\n'
         '– Reparaturkosten: 3.600 €/Jahr\n'
         '– fester Fahrerlohn einschließlich Nebenkosten: 57.600 €/Jahr\n'
         '– Unternehmerlohn: 4.000 €/Jahr\n'
         '– Unternehmerrisiko: 3.000 €/Jahr\n'
         '– Kfz-Steuer: 2.800 €/Jahr\n'
         '– Kfz-Versicherung: 10.200 €/Jahr'),
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
        ('unterstützen Sie den Ausbildunggsleiter', 'unterstützen Sie den Ausbildungsleiter'),
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
TABELLEN = {
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
