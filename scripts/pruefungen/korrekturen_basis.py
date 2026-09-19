# -*- coding: utf-8 -*-
"""Gemeinsame Mechanik der Nachkorrekturen je Prüfungstermin.

Jeder Termin hat ein eigenes Korrekturmodul (``korrekturen_imbq_<termin>.py``)
mit bis zu vier Tabellen, alle mit dem Schlüssel
``(Kürzel, Aufgabennummer, Teil-Label)``:

``LOESUNG``   Lösungstext ersetzen – vor allem dort, wo ``pdftotext`` Word-
              Formeln in Zeichenfolgen zerlegt (Brüche gehen verloren).
``FRAGE``     Fragetext einer Teilaufgabe ersetzen.
``INTRO``     Ausgangslage einer Aufgabe ersetzen; Schlüssel ist
              ``(Kürzel, Aufgabennummer)``. Gebraucht vor allem dort, wo
              ``pdftotext`` die Beschriftungen **aus einer Zeichnung**
              („R1 R2 UEIN R3 UAUS 1 kΩ“) als Fließtext an die Ausgangslage
              hängt – die Zeichnung selbst hängt als Anlage an der Aufgabe.
``PUNKTE``    Punktzahl **im Lösungsheft** berichtigen. Maßgeblich ist der
              Aufgabenteil: er ergibt in allen Heften genau 100 Punkte, das
              Lösungsheft verdruckt gelegentlich eine Zahl. Weicht auch der
              Aufgabenteil ab (Scans: Klammer unlesbar), wird er mitgezogen.
``ROHTEXT``   Nur Scans (T4): Ersetzungen im Rohtext des Textlayers, je Datei
              eine Liste ``[(alt, neu), …]``; Schlüssel ist der Dateiname
              (``01-recht.txt``). Jedes Paar muss genau einmal greifen. Der
              Weg für verschluckte Marker („a)“, „(6 Punkte)“, Lösungskopf)
              und falsch gelesene Zahlen – alles, was die Struktur betrifft.
``LABEL``     Teil-Buchstaben **im Lösungsheft** berichtigen; Schlüssel ist hier
              ``(Kürzel, Aufgabennummer, Position)`` mit der Position ab 0,
              weil derselbe Buchstabe zweimal gedruckt sein kann.
``DATUM``     Prüfungstag setzen oder berichtigen; Schlüssel ist allein das
              Kürzel. Gebraucht, wo das Deckblatt fehlt (Scans ohne Deckblatt)
              oder ein falsches Jahr trägt. Aus dem Datum entstehen Fall-ID und
              Termin, deshalb darf es nicht raten.

Greift eine Korrektur ins Leere, bricht der Lauf ab: dann hat sich die Quelle
geändert und die Stelle muss neu geprüft werden, statt still zu verschwinden.
"""


def anwenden(exams, loesung=None, frage=None, punkte=None, label=None,
             datum=None, intro=None):
    """Korrekturen einspielen; gibt die Zahl der Treffer zurück."""
    loesung, frage = loesung or {}, frage or {}
    punkte, label, datum = punkte or {}, label or {}, datum or {}
    intro = intro or {}
    treffer = 0
    genutzt = {'l': set(), 'f': set(), 'p': set(), 'b': set(), 'd': set(),
               'i': set()}

    for ex in exams:
        k = ex['kuerzel']
        neu_datum = datum.get(k)
        if neu_datum is not None:
            assert neu_datum != ex['datum'], \
                'Datums-Korrektur %s ist schon so gedruckt' % k
            ex['datum'] = neu_datum
            genutzt['d'].add(k)
            treffer += 1
        for nr, a in ex['loesungen'].items():
            for pos, t in enumerate(a['teile']):
                neu_label = label.get((k, nr, pos))
                if neu_label is not None:
                    assert neu_label != t['label'], \
                        'Label-Korrektur %s ist schon so gedruckt' % ((k, nr, pos),)
                    t['label'] = neu_label
                    genutzt['b'].add((k, nr, pos))
                    treffer += 1
            for t in a['teile']:
                neu = loesung.get((k, nr, t['label']))
                if neu is not None:
                    t['loesung'] = neu
                    genutzt['l'].add((k, nr, t['label']))
                    treffer += 1
                neu_p = punkte.get((k, nr, t['label']))
                if neu_p is not None:
                    assert neu_p != t['punkte'], \
                        'Punkte-Korrektur %s ist schon so gedruckt' % ((k, nr, t['label']),)
                    t['punkte'] = neu_p
                    genutzt['p'].add((k, nr, t['label']))
                    treffer += 1
        for nr, a in ex['aufgaben'].items():
            neu_intro = intro.get((k, nr))
            if neu_intro is not None:
                assert neu_intro != a['intro'], \
                    'Intro-Korrektur %s ist schon so gedruckt' % ((k, nr),)
                a['intro'] = neu_intro
                genutzt['i'].add((k, nr))
                treffer += 1
            for t in a['teile']:
                neu = frage.get((k, nr, t['label']))
                if neu is not None:
                    t['text'] = neu
                    genutzt['f'].add((k, nr, t['label']))
                    treffer += 1
                # In den Scans (L-ALT) geht die Klammer auch im Aufgabenteil
                # verloren; die Punkte-Korrektur gilt dann für beide Seiten.
                neu_p = punkte.get((k, nr, t['label']))
                if neu_p is not None and neu_p != t['punkte']:
                    t['punkte'] = neu_p

    fehlend = ((set(loesung) - genutzt['l']) | (set(frage) - genutzt['f'])
               | (set(punkte) - genutzt['p']) | (set(label) - genutzt['b'])
               | (set(datum) - genutzt['d']) | (set(intro) - genutzt['i']))
    assert not fehlend, 'Korrektur greift nicht mehr: %s' % sorted(map(str, fehlend))
    return treffer
