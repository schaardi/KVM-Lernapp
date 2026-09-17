# -*- coding: utf-8 -*-
"""Bildunterschriften der Anlagen, die nicht aus dem Zuschnitt stammen.

Für Abbildungen, die ``anlagen_bau.py`` aus einer Seitenvorschau schneidet,
steht der Titel in ``FIGUREN`` – dort, wo auch der Ausschnitt festgelegt ist.
Abbildungen, die ``anlagen_extrakt.py`` anhand ihrer Bildunterschrift aus dem
Heft holt, bekommen ihren Titel hier. ``build_anlagen.py`` führt beide Quellen
zusammen und bricht ab, wenn eine Abbildung ohne Titel bliebe.

Die Titel sind die des Originals, damit der Verweis im Aufgabentext
("… unter Verwendung der Abbildung 2 …") und die Bildunterschrift in der App
zusammenpassen.
"""

TITEL = {
    # Naturwissenschaftliche und technische Gesetzmäßigkeiten, Frühjahr 2023
    'ntf23-kettenspanner': 'Abbildung 1: Kettenspanner',
    'ntf23-ntc': 'Abbildung 2: NTC-Widerstand · Abbildung 3: Widerstandsschaltung',

    # … Herbst 2023
    'nth23-winkelprofil': 'Abbildung 1: Querschnittsfläche des Winkelprofils',
    'nth23-schaltbild': 'Abbildung 2: Schaltbild',
    'nth23-kiste': 'Abbildung 3: Transportkonstruktion der Kiste',
    'nth23-wnetz': 'Anlage 1 zu Aufgabe 7: Normalverteilung (Vordruck)',

    # … Frühjahr 2024
    'ntf24-ebene': 'Abbildung 1: Schiefe Ebene',
    'ntf24-stapler': 'Abbildung 2: Gabelstapler mit Last',
    'ntf24-aufhaengung': 'Abbildung 3: Aufhängung',
    'ntf24-schaltplan': 'Abbildung 4: Schaltplan',
}
