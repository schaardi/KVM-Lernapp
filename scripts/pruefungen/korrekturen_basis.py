# -*- coding: utf-8 -*-
"""Gemeinsame Mechanik der Nachkorrekturen je Prüfungstermin.

Jeder Termin hat ein eigenes Korrekturmodul (``korrekturen_imbq_<termin>.py``)
mit bis zu vier Tabellen, alle mit dem Schlüssel
``(Kürzel, Aufgabennummer, Teil-Label)``:

``LOESUNG``   Lösungstext ersetzen – vor allem dort, wo ``pdftotext`` Word-
              Formeln in Zeichenfolgen zerlegt (Brüche gehen verloren).
``FRAGE``     Fragetext ersetzen.
``PUNKTE``    Punktzahl **im Lösungsheft** berichtigen. Maßgeblich ist der
              Aufgabenteil: er ergibt in allen Heften genau 100 Punkte, das
              Lösungsheft verdruckt gelegentlich eine Zahl.
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
             datum=None):
    """Korrekturen einspielen; gibt die Zahl der Treffer zurück."""
    loesung, frage = loesung or {}, frage or {}
    punkte, label, datum = punkte or {}, label or {}, datum or {}
    treffer = 0
    genutzt = {'l': set(), 'f': set(), 'p': set(), 'b': set(), 'd': set()}

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
            for t in a['teile']:
                neu = frage.get((k, nr, t['label']))
                if neu is not None:
                    t['text'] = neu
                    genutzt['f'].add((k, nr, t['label']))
                    treffer += 1

    fehlend = ((set(loesung) - genutzt['l']) | (set(frage) - genutzt['f'])
               | (set(punkte) - genutzt['p']) | (set(label) - genutzt['b'])
               | (set(datum) - genutzt['d']))
    assert not fehlend, 'Korrektur greift nicht mehr: %s' % sorted(map(str, fehlend))
    return treffer
