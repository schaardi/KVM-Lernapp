# -*- coding: utf-8 -*-
"""Rechenzeichen, die die OCR verwechselt hat, rechnerisch belegt zurücksetzen.

Die Lösungshinweise der Kraftverkehr-Prüfungen stammen aus einer OCR der
Seitenbilder. Der Malpunkt ``·`` kommt dort als ``-``, ``:`` oder ``—`` an, das
Geteiltzeichen ``÷`` als ``+``, der Folgepfeil ``⇒`` als ``>``::

    Zinsen: 30.250 : 6 % = 1.815          (gemeint: 30.250 · 6 %)
    4.400 € + 22 = 200 €/Auftrag          (gemeint: 4.400 € ÷ 22)

Ob ein Zeichen falsch gelesen ist, entscheidet allein die Rechnung: Für jede
Stelle ``links = Ergebnis`` werden alle Lesarten der mehrdeutigen Zeichen
durchgerechnet. Stimmt die wörtliche Lesart, bleibt alles, wie es ist. Sonst
wird die Lesart mit den wenigsten Änderungen genommen, die das Ergebnis trifft
– aber nur, wenn es genau eine solche gibt. Alles andere bleibt unverändert
und steht im Bericht.
"""
import itertools
import re

# Mögliche Bedeutungen je gelesenem Zeichen (erste = wörtliche Lesart).
LESARTEN = {
    '-': ['-', '*', '/'],
    '−': ['-', '*'],
    '—': ['-', '*'],
    '–': ['-', '*'],
    ':': ['/', '*'],
    '+': ['+', '/', '*'],
}
EINDEUTIG = {'·': '*', '∙': '*', 'ꞏ': '*', '×': '*', '÷': '/', '*': '*', 'x': '*'}
ZEICHEN = {'*': '·', '/': '÷'}          # so wird eine Korrektur geschrieben

ZAHL = r'\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d+(?:,\d+)?'
TOKEN = re.compile(r'(?P<zahl>' + ZAHL + r')(?P<prozent>\s*%)?(?P<skala>\s*(?:Mio\.|Tsd\.))?'
                   r'|(?P<op>[-−—–:+·∙ꞏ×÷*]|(?<=\d)\s*x\s*(?=\d))|(?P<kl>[()])')


def _wert(t):
    return float(t.replace('.', '').replace(',', '.'))


def _tokens(text, basis=0):
    """Zahlen, Rechenzeichen und Klammern; Einheiten und Wörter fallen weg.
    Ein Rechenzeichen zählt nur zwischen zwei Operanden."""
    roh = []
    for m in TOKEN.finditer(text):
        if m.group('zahl'):
            v = _wert(m.group('zahl'))
            if m.group('skala'):
                v *= 1e6 if 'Mio' in m.group('skala') else 1e3
            roh.append(('n', v, bool(m.group('prozent')), None))
        elif m.group('op'):
            op = m.group('op').strip()
            # "09:29 Uhr" ist eine Uhrzeit, kein Geteilt
            if op == ':' and re.match(r'\d:\d', text[m.start('op') - 1:m.start('op') + 2]):
                continue
            roh.append(('o', op, None, basis + m.start('op')))
        else:
            roh.append(('k', m.group('kl'), None, None))
    out = []
    for i, t in enumerate(roh):
        if t[0] == 'o':
            links = out and (out[-1][0] == 'n' or out[-1][1] == ')')
            rechts = i + 1 < len(roh) and (roh[i + 1][0] == 'n' or roh[i + 1][1] == '(')
            if not (links and rechts):
                continue
        out.append(t)
    # Klammern nur, wenn sie aufgehen
    if sum(1 for t in out if t[1] == '(') != sum(1 for t in out if t[1] == ')'):
        out = [t for t in out if t[0] != 'k']
    return out


def _rechnen(toks, wahl):
    """Ausdruck mit der gewählten Lesart je mehrdeutigem Zeichen auswerten.
    ``+ p %`` / ``− p %`` darf relativ gemeint sein (a · (1 ± p/100))."""
    s, j, i = '', 0, 0
    while i < len(toks):
        t = toks[i]
        if t[0] == 'n':
            s += repr(t[1] / 100 if t[2] else t[1])
        elif t[0] == 'k':
            s += t[1]
        else:
            op = t[1]
            if op in LESARTEN:
                w = wahl[j]; j += 1
            else:
                w = EINDEUTIG.get(op, op)
            if w.endswith('rel'):
                # relativer Prozentsatz: "a + 8 %" = a · 1,08
                p = toks[i + 1][1] / 100
                s = '(' + s + ')*(1' + w[0] + repr(p) + ')'
                i += 2
                continue
            s += w
        i += 1
    try:
        return eval(s, {'__builtins__': {}})
    except Exception:
        return None


def _passt(v, ziel):
    return v is not None and abs(v - ziel) <= max(0.006 * abs(ziel), 0.011)


def _lesarten(toks):
    """Lesarten je mehrdeutigem Zeichen; vor einem Prozentsatz kommen die
    relativen hinzu."""
    out = []
    for i, t in enumerate(toks):
        if t[0] == 'o' and t[1] in LESARTEN:
            l = list(LESARTEN[t[1]])
            nxt = toks[i + 1] if i + 1 < len(toks) else None
            if nxt and nxt[0] == 'n' and nxt[2] and l[0] in '+-':
                l.insert(1, l[0] + 'rel')
            out.append(l)
    return out


def pruefe(links, ziel_text, ziel_prozent, basis):
    """Eine Stelle ``links = ziel``. Rückgabe: None (stimmt oder nicht zu
    entscheiden) oder Liste (position, neues Zeichen)."""
    toks = _tokens(links, basis)
    # Steht vorn noch das Ergebnis der Rechnung davor ("= 15.000 €/a 160.200 € ÷ 8 a"),
    # beginnt die neue Rechnung bei der zweiten von zwei Zahlen ohne Zeichen dazwischen.
    for i in range(len(toks) - 1, 0, -1):
        if toks[i][0] == 'n' and toks[i - 1][0] == 'n':
            toks = toks[i:]
            break
    if sum(1 for t in toks if t[0] == 'n') < 2:
        return None
    mehr = [t for t in toks if t[0] == 'o' and t[1] in LESARTEN]
    if len(mehr) > 6:
        # zu viele Lesarten zum Durchprobieren – aber stimmt die wörtliche,
        # ist alles in Ordnung (lange Summen)
        v = _rechnen(toks, [LESARTEN[t[1]][0] for t in mehr])
        ziel = _wert(ziel_text)
        return [] if (_passt(v, ziel) or (ziel_prozent and _passt(v, ziel / 100))) else None
    if not mehr:
        # nur eindeutige Zeichen: stimmt die Rechnung, ist ein ">" dahinter ein "="
        v = _rechnen(toks, [])
        ziel = _wert(ziel_text)
        return [] if (_passt(v, ziel) or (ziel_prozent and _passt(v, ziel / 100))) else None
    ziele = [_wert(ziel_text)]
    if ziel_prozent:
        ziele.append(ziele[0] / 100)
    lesarten = _lesarten(toks)
    woertlich = [l[0] for l in lesarten]
    def trifft(wahl):
        v = _rechnen(toks, wahl)
        return any(_passt(v, z) or (v is not None and _passt(-v, z)) for z in ziele)
    # Die wörtliche Lesart – auch relativ bei Prozentsätzen – hat Vorrang.
    for wahl in itertools.product(*[[l[0]] + ([l[1]] if l[1].endswith('rel') else [])
                                    for l in lesarten]):
        if trifft(list(wahl)):
            return []
    kandidaten = []
    for wahl in itertools.product(*lesarten):
        if trifft(list(wahl)):
            aend = sum(1 for a, b in zip(wahl, woertlich) if a.rstrip('rel') != b)
            kandidaten.append((aend, wahl))
    if not kandidaten:
        return None
    beste = min(k[0] for k in kandidaten)
    wahlen = {tuple(w.rstrip('rel') for w in k[1]) for k in kandidaten if k[0] == beste}
    if len(wahlen) != 1:
        # Gleichstand "÷ 100 %" / "· 100 %": gemeint ist das Mal
        return None
    wahl = wahlen.pop()
    return [(t[3], ZEICHEN[w]) for t, w, l in zip(mehr, wahl, woertlich)
            if w != l and w in ZEICHEN]


TRENNER = re.compile(r'\s?=\s?|(?<=[\d€%a-z])\s>\s(?=\d)')


def zeile(text):
    """Eine Rechenzeile prüfen. Rückgabe: (neue Zeile, Anzahl Änderungen).
    Ein ``>`` zwischen zwei Rechnungen wird zu ``⇒``, wenn die Rechnung davor
    damit aufgeht ("700 Stück · 12 € ⇒ 8.400 € · 0,14 = 1.176 €")."""
    teile, pos = [], 0
    for m in TRENNER.finditer(text):
        teile.append((pos, text[pos:m.start()], m))
        pos = m.end()
    if not teile:
        return text, 0
    teile.append((pos, text[pos:], None))
    aenderungen = []
    for (p1, links, sep), (p2, rechts, _) in zip(teile, teile[1:]):
        mz = re.match(r'\s*(' + ZAHL + r')(\s*%)?', rechts)
        if not mz:
            continue
        # das linke Stück beginnt nach einem Doppelpunkt der Beschriftung
        # ("Zinsen: 30.250 : 6 %") – das Label rechnet nicht mit
        start = 0
        ml = re.match(r'^[^\d(]*?:\s', links)
        if ml:
            start = ml.end()
        fix = pruefe(links[start:], mz.group(1), bool(mz.group(2)), p1 + start)
        if fix is not None:
            aenderungen += fix
            # ">" als gelesenes "⇒": die Rechnung davor geht mit ihm auf
            if sep.group().strip() == '>':
                aenderungen.append((sep.start() + sep.group().index('>'), '⇒'))
    if not aenderungen:
        return text, 0
    z = list(text)
    for p, neu in aenderungen:
        z[p] = neu
    return ''.join(z), len(aenderungen)


def text(t):
    """Alle Zeilen eines Lösungstextes. Rückgabe: (neuer Text, Änderungen)."""
    n, out = 0, []
    for l in t.split('\n'):
        neu, k = zeile(l)
        out.append(neu)
        n += k
    return '\n'.join(out), n


if __name__ == '__main__':
    # Bericht: alle Korrekturen in den gebauten KVM-Lösungen der Web-App
    import json, os, subprocess
    wurzel = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
    daten = json.loads(subprocess.check_output(
        ['node', '-e', 'global.window={};require(%r);process.stdout.write('
         'JSON.stringify(window.KVM_CASES))' % os.path.join(wurzel, 'data', 'cases.js')]))
    n = 0
    for c in daten:
        if not re.match(r'P-(FT|OK)-', c['id']):
            continue
        for st in c['steps']:
            for l in (st.get('a') or '').split('\n'):
                neu, k = zeile(l)
                if k:
                    n += k
                    print('%s\n   alt: %s\n   neu: %s' % (st['id'], l, neu))
    print('Korrekturen: %d' % n)
