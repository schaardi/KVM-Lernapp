# -*- coding: utf-8 -*-
"""Die Inhalte der Web-App liegen neben ``index.html`` in ``data/``.

Früher standen Fragen, Prüfungen und Bildanlagen als Literale in
``index.html`` – bei 121 Prüfungen und über hundert Abbildungen wird die
Datei damit mehrere Megabyte groß, und jede Inhaltsänderung schreibt sie
komplett neu. Jetzt liegt je Datensatz eine eigene Datei:

    data/questions.js   window.KVM_QUESTIONS=[…];
    data/cases.js       window.KVM_CASES=[…];
    data/anlagen.js     window.KVM_ANLAGEN={…};

``index.html`` lädt sie über ``<script src="…">`` – klassische Skripte laufen
in Dokumentreihenfolge, die Globals stehen also fest, bevor der App-Code
startet. Kein Ladezustand, kein ``fetch``, und die Seite lässt sich weiterhin
direkt aus dem Dateisystem öffnen.

Dieses Modul ist die einzige Stelle, die das Format kennt; alle Builder
lesen und schreiben darüber.
"""
import json
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
DATEN = os.path.join(ROOT, 'data')

# Global -> Dateiname. Die Reihenfolge ist zugleich die Ladereihenfolge in index.html.
DATEIEN = {
    'KVM_QUESTIONS': 'questions.js',
    'KVM_ANLAGEN': 'anlagen.js',
    'KVM_CASES': 'cases.js',
}


def pfad(name):
    """Absoluter Pfad der Datei zu einem Global (z. B. ``KVM_CASES``)."""
    try:
        return os.path.join(DATEN, DATEIEN[name])
    except KeyError:
        raise SystemExit('Unbekannter Datensatz: %s (bekannt: %s)'
                         % (name, ', '.join(sorted(DATEIEN))))


def lesen(name):
    """Datensatz als Python-Objekt (Liste bzw. dict)."""
    p = pfad(name)
    if not os.path.exists(p):
        raise SystemExit('%s fehlt – erst `python3 tools/webdaten.py --pruefen` ausführen.' % p)
    return aus_text(open(p, encoding='utf-8').read(), name)


def aus_text(text, name):
    """``window.<name>=<json>;`` parsen – auch aus einer alten index.html."""
    m = re.search(r'window\.%s\s*=\s*' % re.escape(name), text)
    if not m:
        raise SystemExit('window.%s nicht gefunden.' % name)
    rest = text[m.end():].strip()
    # bis zum passenden Klammerende schneiden (String- und Klammer-bewusst)
    auf = rest[0]
    zu = {'[': ']', '{': '}'}.get(auf)
    if not zu:
        raise SystemExit('window.%s: erwartet [ oder {, gefunden %r' % (name, auf))
    tiefe, i, instr, esc = 0, 0, False, False
    while i < len(rest):
        ch = rest[i]
        if instr:
            if esc:
                esc = False
            elif ch == '\\':
                esc = True
            elif ch == '"':
                instr = False
        else:
            if ch == '"':
                instr = True
            elif ch == auf:
                tiefe += 1
            elif ch == zu:
                tiefe -= 1
                if tiefe == 0:
                    return json.loads(rest[:i + 1])
        i += 1
    raise SystemExit('window.%s: Klammer nicht geschlossen.' % name)


def kompakt(x):
    return json.dumps(x, ensure_ascii=False, separators=(',', ':'))


def schreiben(name, daten):
    """Datensatz ablegen. Gibt die Größe der Datei in Byte zurück."""
    os.makedirs(DATEN, exist_ok=True)
    text = 'window.%s=%s;\n' % (name, kompakt(daten))
    p = pfad(name)
    with open(p, 'w', encoding='utf-8') as f:
        f.write(text)
    return len(text.encode('utf-8'))


def main(argv=None):
    import sys
    argv = sys.argv[1:] if argv is None else argv
    if argv and argv[0] == '--pruefen':
        fehlt = 0
        for name in DATEIEN:
            p = pfad(name)
            if not os.path.exists(p):
                print('FEHLT   %s' % os.path.relpath(p, ROOT))
                fehlt += 1
                continue
            d = lesen(name)
            print('%-14s %7d Einträge  %8.1f KB  %s'
                  % (name, len(d), os.path.getsize(p) / 1024,
                     os.path.relpath(p, ROOT)))
        return 1 if fehlt else 0
    print(__doc__)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
