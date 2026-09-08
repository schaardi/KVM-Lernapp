# -*- coding: utf-8 -*-
"""Legt die Bildanlagen der Prüfungen in Web und App ab.

Die Bilder in ``anlagen/`` werden einmal zentral als Data-URI hinterlegt –
in der App als ``assets/data/anlagen.json``, in der Web-App als
``window.KVM_ANLAGEN``. Die Teilaufgaben verweisen nur noch über den
Schlüssel darauf (Feld ``bild`` bzw. ``bildL``). So liegt eine Abbildung
auch dann nur einmal in der Datei, wenn sich mehrere Teilaufgaben auf sie
beziehen.

    python3 scripts/pruefungen/build_anlagen.py
"""
import base64
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
QUELLE = os.path.join(HERE, 'anlagen')
APP = os.path.join(ROOT, 'flutter_app', 'assets', 'data', 'anlagen.json')
WEB = os.path.join(ROOT, 'index.html')
MIME = {'.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png'}

# Bildunterschriften: die Zuschnitt-Tabelle in anlagen_bau.py ist die Quelle,
# damit Titel und Ausschnitt nicht auseinanderlaufen. Ältere Bilder, die nicht
# dort stehen, bekommen ihren Titel hier.
try:
    sys.path.insert(0, HERE)
    from anlagen_bau import FIGUREN
    TITEL = {k: v[3] for k, v in FIGUREN.items()}
except Exception:            # pragma: no cover – Pillow fehlt, Titel egal
    TITEL = {}
TITEL.setdefault('P-FT-20251111-s3', 'Lastverteilungsplan Sattelauflieger')


def sammeln():
    anlagen = {}
    for name in sorted(os.listdir(QUELLE)):
        stamm, endung = os.path.splitext(name)
        if endung.lower() not in MIME:
            continue
        with open(os.path.join(QUELLE, name), 'rb') as f:
            uri = 'data:%s;base64,%s' % (
                MIME[endung.lower()], base64.b64encode(f.read()).decode('ascii'))
        eintrag = {'u': uri}
        if TITEL.get(stamm):
            eintrag['t'] = TITEL[stamm]
        anlagen[stamm] = eintrag
    return anlagen


def dump_compact(x):
    return json.dumps(x, ensure_ascii=False, separators=(',', ':'))


def web_schreiben(anlagen):
    html = open(WEB, encoding='utf-8').read()
    marke = 'window.KVM_ANLAGEN = '
    neu = marke + dump_compact(anlagen) + ';'
    if marke in html:
        i = html.index(marke)
        j = html.index(';\n', i) + 1
        html = html[:i] + neu + html[j:]
    else:
        # direkt vor die Fälle setzen, damit beides zusammen geladen wird
        anker = 'window.KVM_CASES = '
        i = html.index(anker)
        html = html[:i] + neu + '\n' + html[i:]
    open(WEB, 'w', encoding='utf-8').write(html)


def main():
    anlagen = sammeln()
    if not anlagen:
        raise SystemExit('Keine Bilder in %s' % QUELLE)
    open(APP, 'w', encoding='utf-8').write(dump_compact(anlagen) + '\n')
    web_schreiben(anlagen)
    gesamt = sum(len(a['u']) for a in anlagen.values())
    print('  %d Bildanlagen, %.0f KB als Data-URI' % (len(anlagen), gesamt / 1024))
    for k, a in sorted(anlagen.items()):
        print('    %-20s %6.1f KB  %s' % (k, len(a['u']) / 1024, a.get('t', '–')))


if __name__ == '__main__':
    main()
