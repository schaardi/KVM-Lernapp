# -*- coding: utf-8 -*-
"""Die Inhalte der Web-App liegen neben ``index.html`` in ``data/``.

Früher standen Fragen, Prüfungen und Bildanlagen als Literale in
``index.html`` – bei 121 Prüfungen und über hundert Abbildungen wird die
Datei damit mehrere Megabyte groß, und jede Inhaltsänderung schreibt sie
komplett neu. Jetzt liegt je Datensatz eine eigene Datei:

    data/questions.js   window.KVM_QUESTIONS=[…];
    data/cases.js       window.KVM_CASES=[…];

``index.html`` lädt sie über ``<script src="…">`` – klassische Skripte laufen
in Dokumentreihenfolge, die Globals stehen also fest, bevor der App-Code
startet. Kein Ladezustand, kein ``fetch``, und die Seite lässt sich weiterhin
direkt aus dem Dateisystem öffnen.

Dieses Modul ist die einzige Stelle, die das Format kennt; alle Builder
lesen und schreiben darüber.

Original-IHK-Prüfungen
----------------------
Die Original-Prüfungen (Fall-IDs „P-…“) und ihre Bildanlagen gehören nicht
ins Repository. Sie liegen im privaten Paket unter ``privat/hochladen/``
(steht in ``.gitignore``) und von dort im privaten Supabase-Bucket
„pruefungen“, aus dem die Web-App sie nach der Freigabe lädt
(``docs/supabase-pruefungen-freigabe.sql``)::

    privat/hochladen/pruefungen.json   {"version": 1, "pruefungen": […], "anlagen": {…}}
    privat/hochladen/anlagen/<Datei>   die Bilder zu den Anlagen

``lesen('KVM_CASES')`` liefert die öffentlichen Fälle aus ``data/cases.js``
und, falls das Paket da ist, die Prüfungen dahinter. ``schreiben('KVM_CASES',
…)`` trennt wieder: Prüfungen ins Paket, alles andere nach ``data/cases.js``.
``KVM_ANLAGEN`` gibt es nur noch im Paket. So landen Prüfungen nie in einer
Datei, die eingecheckt wird – auch nicht, wenn ein Builder alles zurückschreibt.
"""
import json
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
DATEN = os.path.join(ROOT, 'data')

# Global -> Dateiname. Die Reihenfolge ist zugleich die Ladereihenfolge in index.html.
DATEIEN = {
    'KVM_QUESTIONS': 'questions.js',
    'KVM_CASES': 'cases.js',
}

# Privates Paket mit den Original-Prüfungen (siehe oben)
PRIVAT = os.path.join(ROOT, 'privat', 'hochladen')
PAKET = os.path.join(PRIVAT, 'pruefungen.json')
PAKET_BILDER = os.path.join(PRIVAT, 'anlagen')


def ist_pruefung(fall):
    """Original-IHK-Prüfung? (Fall-ID „P-…“)"""
    return isinstance(fall, dict) and str(fall.get('id', '')).startswith('P-')


def pfad(name):
    """Absoluter Pfad der Datei zu einem Global (z. B. ``KVM_CASES``)."""
    if name == 'KVM_ANLAGEN':
        return PAKET
    try:
        return os.path.join(DATEN, DATEIEN[name])
    except KeyError:
        raise SystemExit('Unbekannter Datensatz: %s (bekannt: %s)'
                         % (name, ', '.join(sorted(DATEIEN) + ['KVM_ANLAGEN'])))


def paket_lesen():
    """Das private Prüfungspaket oder ``None``, wenn es fehlt."""
    if not os.path.exists(PAKET):
        return None
    with open(PAKET, encoding='utf-8') as f:
        paket = json.load(f)
    if not isinstance(paket, dict) or not isinstance(paket.get('pruefungen'), list):
        raise SystemExit('%s ist kein Prüfungspaket (erwartet {"pruefungen": [...]}).' % PAKET)
    paket.setdefault('anlagen', {})
    return paket


def paket_schreiben(pruefungen=None, anlagen=None):
    """Prüfungen und/oder Anlagen im Paket ersetzen. Gibt die Größe in Byte zurück."""
    alt = paket_lesen() or {}
    neu = {'version': 1,
           'pruefungen': alt.get('pruefungen', []) if pruefungen is None else pruefungen,
           'anlagen': alt.get('anlagen', {}) if anlagen is None else anlagen}
    fremd = [c.get('id') for c in neu['pruefungen'] if not ist_pruefung(c)]
    if fremd:
        raise SystemExit('Ins Prüfungspaket gehören nur Prüfungen (P-…): %s' % fremd[:5])
    os.makedirs(PRIVAT, exist_ok=True)
    text = kompakt(neu) + '\n'
    with open(PAKET, 'w', encoding='utf-8') as f:
        f.write(text)
    return len(text.encode('utf-8'))


def lesen(name):
    """Datensatz als Python-Objekt (Liste bzw. dict).

    ``KVM_CASES`` enthält die Prüfungen aus dem privaten Paket, wenn es da ist;
    ``KVM_ANLAGEN`` kommt nur von dort (ohne Paket: leer)."""
    if name == 'KVM_ANLAGEN':
        paket = paket_lesen()
        return dict(paket['anlagen']) if paket else {}
    p = pfad(name)
    if not os.path.exists(p):
        raise SystemExit('%s fehlt – erst `python3 tools/webdaten.py --pruefen` ausführen.' % p)
    daten = aus_text(open(p, encoding='utf-8').read(), name)
    if name == 'KVM_CASES':
        paket = paket_lesen()
        if paket:
            daten = [c for c in daten if not ist_pruefung(c)] + paket['pruefungen']
    return daten


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


def als_datei(name, daten):
    """Dateiinhalt zu einem Datensatz – ohne zu schreiben.

    Getrennt von ``schreiben()``, damit ein Aufrufer vergleichen kann, ob sich
    überhaupt etwas ändert (``tools/sync_content.py --check``). Prüfungen
    kommen nie in die öffentliche Datei.
    """
    if name == 'KVM_CASES':
        daten = [c for c in daten if not ist_pruefung(c)]
    return 'window.%s=%s;\n' % (name, kompakt(daten))


def schreiben(name, daten):
    """Datensatz ablegen. Gibt die Größe der Datei in Byte zurück.

    Prüfungen und Anlagen gehen ins private Paket (siehe oben)."""
    if name == 'KVM_ANLAGEN':
        return paket_schreiben(anlagen=daten)
    if name == 'KVM_CASES':
        pruefungen = [c for c in daten if ist_pruefung(c)]
        if pruefungen:
            paket_schreiben(pruefungen=pruefungen)
    os.makedirs(DATEN, exist_ok=True)
    text = als_datei(name, daten)
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
            d = aus_text(open(p, encoding='utf-8').read(), name)
            print('%-14s %7d Einträge  %8.1f KB  %s'
                  % (name, len(d), os.path.getsize(p) / 1024,
                     os.path.relpath(p, ROOT)))
            if name == 'KVM_CASES' and any(ist_pruefung(c) for c in d):
                print('FEHLER  %s enthält Original-Prüfungen – die gehören ins private Paket.'
                      % os.path.relpath(p, ROOT))
                fehlt += 1
        paket = paket_lesen()
        if paket:
            print('%-14s %7d Prüfungen, %d Anlagen  %8.1f KB  %s (privat)'
                  % ('Prüfungspaket', len(paket['pruefungen']), len(paket['anlagen']),
                     os.path.getsize(PAKET) / 1024, os.path.relpath(PAKET, ROOT)))
        else:
            print('Prüfungspaket  fehlt (%s) – ohne Paket nur öffentliche Fälle.'
                  % os.path.relpath(PAKET, ROOT))
        return 1 if fehlt else 0
    print(__doc__)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
