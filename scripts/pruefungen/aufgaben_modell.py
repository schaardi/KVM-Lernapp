# -*- coding: utf-8 -*-
"""Prüfungen als Aufgabenblatt: Aufgabe mit allen Teilaufgaben a–x.

Bisher war jede **Teilaufgabe** ein eigener Schritt, und ihr Text `q` war ein
zusammengesetzter String::

    Aufgabe 2 c) · 3 Punkte

    Für die Beschaffung eines Kunststoffgranulats …      <- Ausgangslage
                                                            der ganzen Aufgabe
    Ermitteln Sie die optimale Bestellmenge.             <- die Fragestellung

Web und App haben ihn per Regex wieder zerlegt, und die Ausgangslage stand in
jedem Teil noch einmal – bei Aufgabe 2 der BWL H2025 viermal derselbe Absatz.
Wer 2 a) beantwortet, sah außerdem nicht, dass 2 c) und 2 d) darauf aufbauen.

Jetzt trägt der Fall eine Liste ``aufgaben``::

    {"nr": 2, "pts": 17, "sit": "Für die Beschaffung …", "tab": {…}, "bild": […]}

und der Schritt nur noch seine eigene Fragestellung plus die Zuordnung::

    {"id": "P-BW-20251106-s3", "nr": 2, "teil": "c", "pts": 3,
     "q": "Ermitteln Sie die optimale Bestellmenge.", "braucht": ["a"], …}

Die **Schritt-IDs bleiben** – an ihnen hängen die selbst geschriebenen
Antworten und die Punkte-Selbstbewertung.

`volltext` baut den alten String wieder zusammen. Damit bleiben der KI-Export
und alles, was den Aufgabenkopf im Fließtext braucht, zeichengleich; zugleich
ist es die Probe, dass beim Umbau nichts verloren geht.
"""
import re

# "Aufgabe 2 c) · 3 Punkte" – der Buchstabe ist in allen vorhandenen Prüfungen
# gesetzt, die Punktzahl steht im Singular, wenn es nur einer ist.
KOPF = re.compile(r'^Aufgabe\s+(\d+)\s*([a-h])\)\s*·\s*(\d+)\s*(Punkte?)$')

# Verweise einer Teilaufgabe auf eine frühere: "aus Teilaufgabe a)", "aus a)",
# "in Teilaufgabe d)", "zu Teilaufgabe a)". Bewusst eng gefasst – ein falscher
# Verweis führt in der App zu einem falschen Zwischenergebnis.
VERWEIS = (
    re.compile(r'\b(?:Teilaufgabe|Aufgabenteil)\s+([a-h])\)'),
    re.compile(r'\baus\s+([a-h])\)'),
)
# "Anlage 1 zu Aufgabe 7 a)" ist eine Anlagen-Überschrift, kein Verweis.
KEIN_VERWEIS = re.compile(r'^\s*Anlage\s+\d+\s+zu\s+Aufgabe', re.I | re.M)


def kopfzeile(nr, teil, pts):
    """"Aufgabe 2 c) · 3 Punkte" – die Form, die auch im Export erscheint."""
    return 'Aufgabe %d %s) · %d %s' % (nr, teil, pts, 'Punkt' if pts == 1 else 'Punkte')


def kopf_lesen(text):
    """Kopfzeile zerlegen. Gibt (nr, teil, pts) oder None."""
    m = KOPF.match(text.strip())
    return (int(m.group(1)), m.group(2), int(m.group(3))) if m else None


def braucht_finden(frage, eigenes_label, labels):
    """Labels früherer Teilaufgaben, auf deren Ergebnis diese aufbaut."""
    text = KEIN_VERWEIS.sub('', frage)
    gefunden = []
    for muster in VERWEIS:
        for lab in muster.findall(text):
            if lab != eigenes_label and lab in labels and lab not in gefunden:
                gefunden.append(lab)
    return sorted(gefunden)


def volltext(step, aufgabe=None):
    """Den alten zusammengesetzten Fragetext wiederherstellen."""
    teile = []
    if step.get('pts'):
        teile.append(kopfzeile(step['nr'], step['teil'], step['pts']))
    if aufgabe and aufgabe.get('sit'):
        teile.append(aufgabe['sit'])
    teile.append(step.get('q', ''))
    return '\n\n'.join(teile)


def aufgaben_index(case):
    """{nr: aufgabe} für schnellen Zugriff."""
    return {a['nr']: a for a in case.get('aufgaben', [])}


def zerlegen(case):
    """Fall vom alten in das Aufgabenblatt-Format überführen (verlustfrei).

    Schritte ohne Aufgabenkopf – die 15 Fallaufgaben ohne IHK-Bezug – werden zu
    einer Aufgabe 1 mit den Teilen a, b, c … ohne Punkte; ihr Fragetext bleibt
    unangetastet, und `volltext` gibt ihn unverändert zurück.
    """
    if case.get('aufgaben'):
        return case            # schon im Aufgabenblatt-Format
    neu = {k: v for k, v in case.items() if k != 'steps'}
    aufgaben, schritte = [], []
    nach_nr = {}
    naechstes_label = 0
    for st in case['steps']:
        s = dict(st)
        stuecke = s['q'].split('\n\n')
        gelesen = kopf_lesen(stuecke[0]) if len(stuecke) >= 2 else None
        if gelesen:
            nr, teil, pts = gelesen
            sit = '\n\n'.join(stuecke[1:-1])
            frage = stuecke[-1]
        else:
            # Fallaufgabe: eine Aufgabe, fortlaufende Teile, keine Punkte
            nr, pts, sit, frage = 1, 0, '', s['q']
            teil = chr(ord('a') + naechstes_label)
            naechstes_label += 1
        if nr not in nach_nr:
            nach_nr[nr] = {'nr': nr, 'pts': 0, 'sit': sit}
            aufgaben.append(nach_nr[nr])
        elif sit and not nach_nr[nr]['sit']:
            nach_nr[nr]['sit'] = sit
        elif sit and nach_nr[nr]['sit'] != sit:
            raise SystemExit('%s: Aufgabe %d hat je Teil eine andere Ausgangslage'
                             % (case['id'], nr))
        nach_nr[nr]['pts'] += pts
        s['nr'], s['teil'], s['pts'] = nr, teil, pts
        s['q'] = frage
        schritte.append(s)

    # Anlagen, auf die sich mehrere Teile einer Aufgabe beziehen, gehören an
    # die Aufgabe – sonst erscheint dieselbe Abbildung in jedem Teil noch
    # einmal. Dass ein Teil sie nicht trägt, spricht nicht dagegen: die
    # Abbildung gehört im Original zur Aufgabe (NTG H2024 A7: a–c verweisen
    # auf das Wahrscheinlichkeitsnetz, d rechnet nur weiter).
    for a in aufgaben:
        teile = [s for s in schritte if s['nr'] == a['nr']]
        for feld in ('bild', 'tab'):
            werte = [s[feld] for s in teile if s.get(feld)]
            # Eine Anlage gehört zur Aufgabe, wenn mehrere Teile dieselbe
            # tragen – oder wenn die Aufgabe nur aus einem Teil besteht. Trägt
            # dagegen nur einer von mehreren Teilen eine Anlage, gehört sie
            # allein zu diesem Teil und bleibt dort.
            if not werte or any(w != werte[0] for w in werte):
                continue
            if len(werte) < 2 and len(teile) > 1:
                continue
            a[feld] = werte[0]
            for s in teile:
                s.pop(feld, None)

    # Verweise auf frühere Teilaufgaben
    for a in aufgaben:
        teile = [s for s in schritte if s['nr'] == a['nr']]
        labels = {s['teil'] for s in teile}
        for s in teile:
            b = braucht_finden(s['q'], s['teil'], labels)
            if b:
                s['braucht'] = b

    neu['aufgaben'] = aufgaben
    neu['steps'] = schritte
    return neu


def pruefen(alt, neu):
    """Round-Trip: der alte Fragetext muss sich exakt rekonstruieren lassen."""
    idx = aufgaben_index(neu)
    fehler = []
    if len(alt['steps']) != len(neu['steps']):
        fehler.append('%s: Schrittzahl %d != %d' % (alt['id'], len(alt['steps']), len(neu['steps'])))
        return fehler
    for a, n in zip(alt['steps'], neu['steps']):
        if a['id'] != n['id']:
            fehler.append('%s: ID %s != %s' % (alt['id'], a['id'], n['id']))
        auf = idx.get(n['nr'], {})
        if volltext(n, auf) != a['q']:
            fehler.append('%s: Fragetext weicht ab' % a['id'])
        for feld in ('bild', 'tab'):
            if a.get(feld) and not (n.get(feld) or auf.get(feld)):
                fehler.append('%s: %s verloren' % (a['id'], feld))
    pf = sum(s['pts'] for s in neu['steps'])
    pa = sum(a['pts'] for a in neu['aufgaben'])
    if pf != pa:
        fehler.append('%s: Punkte Schritte %d != Aufgaben %d' % (alt['id'], pf, pa))
    return fehler
