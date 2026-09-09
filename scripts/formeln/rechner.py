# -*- coding: utf-8 -*-
"""Referenz-Implementierung des Formel-Rechenkerns.

Dieselbe Grammatik setzen die Web-App (JavaScript) und die Android-App (Dart)
um. Diese Fassung dient als Prüfstein: die Tests rechnen jede Formel hier und
vergleichen mit den beiden anderen Laufzeiten.

Erlaubt sind + - * / ^ ( ) , Zahlen, Variablen, die Konstante pi und die
Funktionen sqrt, sin, cos, tan, abs, min, max, round. Winkel in Grad.
"""
import math
import re

TOKEN = re.compile(r'\s*(\d+\.?\d*|[A-Za-z_][A-Za-z_0-9]*|\*\*|[-+*/^(),])')
FUNKTIONEN = {
    'sqrt': (1, math.sqrt),
    'sin': (1, lambda x: math.sin(math.radians(x))),
    'cos': (1, lambda x: math.cos(math.radians(x))),
    'tan': (1, lambda x: math.tan(math.radians(x))),
    'abs': (1, abs),
    'round': (1, lambda x: float(round(x))),
    'min': (2, min),
    'max': (2, max),
}
KONSTANTEN = {'pi': math.pi}


def tokenize(s):
    toks, i = [], 0
    while i < len(s):
        m = TOKEN.match(s, i)
        if not m:
            if s[i].isspace():
                i += 1
                continue
            raise ValueError('unerwartetes Zeichen %r' % s[i])
        toks.append(m.group(1))
        i = m.end()
    return toks


class _P:
    def __init__(self, toks, werte):
        self.t, self.i, self.w = toks, 0, werte

    def peek(self):
        return self.t[self.i] if self.i < len(self.t) else None

    def nimm(self, was=None):
        tok = self.peek()
        if was is not None and tok != was:
            raise ValueError('erwartet %r, gefunden %r' % (was, tok))
        self.i += 1
        return tok

    def expr(self):
        x = self.term()
        while self.peek() in ('+', '-'):
            op = self.nimm()
            y = self.term()
            x = x + y if op == '+' else x - y
        return x

    def term(self):
        x = self.faktor()
        while self.peek() in ('*', '/'):
            op = self.nimm()
            y = self.faktor()
            if op == '/':
                if y == 0:
                    raise ZeroDivisionError('Division durch null')
                x = x / y
            else:
                x = x * y
        return x

    def faktor(self):
        x = self.unaer()
        if self.peek() in ('^', '**'):
            self.nimm()
            return x ** self.faktor()   # rechtsassoziativ
        return x

    def unaer(self):
        if self.peek() == '-':
            self.nimm()
            return -self.unaer()
        if self.peek() == '+':
            self.nimm()
            return self.unaer()
        return self.atom()

    def atom(self):
        tok = self.peek()
        if tok is None:
            raise ValueError('Ausdruck bricht ab')
        if tok == '(':
            self.nimm('(')
            x = self.expr()
            self.nimm(')')
            return x
        if re.match(r'^\d', tok):
            self.nimm()
            return float(tok)
        name = self.nimm()
        if self.peek() == '(':
            self.nimm('(')
            args = [self.expr()]
            while self.peek() == ',':
                self.nimm(',')
                args.append(self.expr())
            self.nimm(')')
            if name not in FUNKTIONEN:
                raise ValueError('unbekannte Funktion %r' % name)
            n, fn = FUNKTIONEN[name]
            if len(args) != n:
                raise ValueError('%s erwartet %d Argument(e)' % (name, n))
            return float(fn(*args))
        if name in KONSTANTEN:
            return KONSTANTEN[name]
        if name in self.w:
            return float(self.w[name])
        raise ValueError('unbekannte Variable %r' % name)


def auswerten(ausdruck, werte):
    p = _P(tokenize(ausdruck), werte)
    x = p.expr()
    if p.peek() is not None:
        raise ValueError('überzähliges Zeichen %r' % p.peek())
    return x


# ------------------------------------------------------------ Schema-Rechner
def schema_rechnen(schema, eingaben, saetze):
    """Löst ein Kalkulationsschema vorwärts und rückwärts.

    Jeder Zeilenwert ist affin in der einen Unbekannten x: (a, b) meint a + b·x.
    Die Unbekannte ist die einzige leer gelassene Pflicht-Eingabezeile. Trägt
    man weiter unten einen Betrag ein, entsteht daraus die Gleichung, aus der x
    bestimmt wird.

    Rückgabe: (werte je Zeile, unbekannte Zeile oder None, Hinweistext oder None)
    """
    rows = schema['rows']
    pflicht = [r['k'] for r in rows
               if r['t'] == 'in' and not r.get('opt') and eingaben.get(r['k']) is None]
    ziele = [r['k'] for r in rows
             if r['t'] != 'in' and eingaben.get(r['k']) is not None]

    hinweis = None
    unbekannt = None
    if ziele and len(pflicht) == 1:
        unbekannt = pflicht[0]
    elif ziele and len(pflicht) != 1:
        hinweis = ('Für die Rückwärtsrechnung genau eine Kostenzeile frei lassen – '
                   'zurzeit %s.' % ('sind es %d' % len(pflicht) if pflicht else 'ist keine frei'))

    def lauf(x):
        """Ein Durchlauf; x=None ⇒ affin rechnen, sonst mit eingesetztem Wert."""
        val = {}

        def hole(ref):
            neg = ref.startswith('-')
            a, b = val[ref.lstrip('-')]
            return (-a, -b) if neg else (a, b)

        gleichungen = []
        for r in rows:
            k, t = r['k'], r['t']
            if t == 'in':
                e = eingaben.get(k)
                if e is not None:
                    val[k] = (float(e), 0.0)
                elif k == unbekannt:
                    val[k] = (0.0, 1.0) if x is None else (float(x), 0.0)
                else:
                    val[k] = (0.0, 0.0)
            elif t == 'pct':
                p = saetze.get(k)
                p = float(p) if p is not None else float(r.get('rd') or 0)
                a, b = val[r['base']]
                val[k] = (a * p / 100.0, b * p / 100.0)
            elif t == 'ih':
                val[k] = (0.0, 0.0)     # wird von der Summenzeile gesetzt
            elif t == 'sum':
                a = b = 0.0
                for ref in r['of']:
                    da, db = hole(ref)
                    a += da
                    b += db
                ihs = r.get('ih') or []
                if ihs:
                    ps = []
                    for ik in ihs:
                        ir = next(z for z in rows if z['k'] == ik)
                        pv = saetze.get(ik)
                        ps.append(float(pv) if pv is not None else float(ir.get('rd') or 0))
                    rest = 1.0 - sum(ps) / 100.0
                    if rest <= 0:
                        raise ValueError('Die Sätze „im Hundert" ergeben zusammen 100 % oder mehr.')
                    a, b = a / rest, b / rest
                    for ik, p in zip(ihs, ps):
                        val[ik] = (a * p / 100.0, b * p / 100.0)
                val[k] = (a, b)
            if t in ('pct', 'sum'):
                e = eingaben.get(k)
                if e is not None:
                    a, b = val[k]
                    gleichungen.append((k, a, b, float(e)))
        return val, gleichungen

    val, gl = lauf(None)
    if unbekannt is not None:
        loesbar = [g for g in gl if abs(g[2]) > 1e-12]
        if loesbar:
            _, a, b, ziel = loesbar[0]
            val, _ = lauf((ziel - a) / b)
        else:
            hinweis = hinweis or ('Aus dem eingetragenen Betrag lässt sich %s nicht '
                                  'bestimmen.' % unbekannt)
    return {k: v[0] for k, v in val.items()}, unbekannt, hinweis
