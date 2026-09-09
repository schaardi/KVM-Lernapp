# -*- coding: utf-8 -*-
"""Formelbuch-Build: hält die Web-App mit der App-Formelsammlung synchron.

Einzige Quelle der Wahrheit ist ``flutter_app/assets/data/formulas.json``. Die
Web-App (``index.html``) trägt dieselben Formeln als JavaScript-Array
``var FORMULAS=[…]``. Dieses Skript erzeugt das Array frisch aus der JSON und
ersetzt es in der Web-App, damit beide nie auseinanderlaufen.

Seit dem Umbau auf rechenbare Formeln enthält jede Formel optional die Felder
``v`` (Eingabefelder), ``f`` (Ausdruck), ``r`` (Ergebnis) und ``dec``; Gruppen
können unter ``s`` Kalkulationsschemas führen. Deshalb wird das Array als
reines JSON geschrieben – gültiges JavaScript und Zeichen für Zeichen die
Quelle.

Aufruf:
    python3 scripts/build_formulas.py            # nutzt Standardpfade
    python3 scripts/build_formulas.py <json> <html>
"""
import json
import sys


def finde_array(html, marke):
    """Klammertreue Suche nach dem Array hinter ``marke`` (Strings werden
    übersprungen, damit eckige Klammern im Text nichts kaputt machen)."""
    start = html.index(marke) + len(marke)
    i0 = html.index('[', start)
    tiefe = 0
    i = i0
    im_string = False
    escaped = False
    while i < len(html):
        c = html[i]
        if im_string:
            if escaped:
                escaped = False
            elif c == '\\':
                escaped = True
            elif c == '"':
                im_string = False
        else:
            if c == '"':
                im_string = True
            elif c == '[':
                tiefe += 1
            elif c == ']':
                tiefe -= 1
                if tiefe == 0:
                    return i0, i + 1
        i += 1
    raise SystemExit('%s…] nicht gefunden – Array nicht geschlossen?' % marke)


def build(json_path, html_path):
    data = json.load(open(json_path, encoding='utf-8'))
    html = open(html_path, encoding='utf-8').read()

    marke = 'var FORMULAS='
    if marke not in html:
        raise SystemExit('%s[…]; nicht in %s gefunden.' % (marke, html_path))
    i0, i1 = finde_array(html, marke)
    neu = json.dumps(data, ensure_ascii=False, separators=(',', ':'))
    if neu == html[i0:i1]:
        print('  %s: bereits aktuell' % html_path)
        return
    open(html_path, 'w', encoding='utf-8').write(html[:i0] + neu + html[i1:])

    n = sum(len(g['items']) for g in data)
    rb = sum(1 for g in data for it in g['items'] if 'f' in it)
    sc = sum(len(g.get('s', [])) for g in data)
    print('  %s: %d Formeln in %d Gruppen synchronisiert '
          '(%d rechenbar, %d Kalkulationsschemas)'
          % (html_path, n, len(data), rb, sc))


if __name__ == '__main__':
    j = sys.argv[1] if len(sys.argv) > 1 else 'flutter_app/assets/data/formulas.json'
    h = sys.argv[2] if len(sys.argv) > 2 else 'index.html'
    build(j, h)
