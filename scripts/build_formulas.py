# -*- coding: utf-8 -*-
"""Formelbuch-Build: hält die Web-App mit der App-Formelsammlung synchron.

Einzige Quelle der Wahrheit ist ``flutter_app/assets/data/formulas.json``. Die
Web-App (``index.html``) trägt dieselben Formeln als JavaScript-Array
``var FORMULAS=[…]``. Dieses Skript erzeugt dieses Array frisch aus der JSON und
ersetzt es in der Web-App, damit beide nie auseinanderlaufen.

Aufruf:
    python3 scripts/build_formulas.py            # nutzt Standardpfade
    python3 scripts/build_formulas.py <json> <html>
"""
import json
import re
import sys


def js_array(data):
    """Baut das kompakte ``[{g:"…",items:[{n:"…",e:"…",d:"…"}]}]`` wie im
    bestehenden index.html (unquotierte Schlüssel, doppelte Anführungszeichen)."""
    def s(x):
        return json.dumps(x, ensure_ascii=False)  # sauberes Escaping der Strings

    def item(it):
        # Das Feld d nur schreiben, wenn eine Beschreibung vorhanden ist –
        # so bleibt die Web-Fassung Zeichen für Zeichen wie die App-Quelle.
        teile = ['n:%s' % s(it['n']), 'e:%s' % s(it['e'])]
        if it.get('d'):
            teile.append('d:%s' % s(it['d']))
        return '{' + ','.join(teile) + '}'

    gruppen = []
    for g in data:
        items = ','.join(item(it) for it in g['items'])
        gruppen.append('{g:%s,items:[%s]}' % (s(g['g']), items))
    return '[' + ','.join(gruppen) + ']'


def build(json_path, html_path):
    data = json.load(open(json_path, encoding='utf-8'))
    html = open(html_path, encoding='utf-8').read()

    muster = re.compile(r'(var FORMULAS=)(\[.*?\])(;)', re.S)
    m = muster.search(html)
    if not m:
        raise SystemExit('var FORMULAS=[…]; nicht in %s gefunden.' % html_path)

    neu = m.group(1) + js_array(data) + m.group(3)
    if neu == m.group(0):
        print('  %s: bereits aktuell' % html_path)
        return
    open(html_path, 'w', encoding='utf-8').write(
        html[:m.start()] + neu + html[m.end():])
    n = sum(len(g['items']) for g in data)
    print('  %s: %d Formeln in %d Gruppen synchronisiert'
          % (html_path, n, len(data)))


if __name__ == '__main__':
    j = sys.argv[1] if len(sys.argv) > 1 else 'flutter_app/assets/data/formulas.json'
    h = sys.argv[2] if len(sys.argv) > 2 else 'index.html'
    build(j, h)
