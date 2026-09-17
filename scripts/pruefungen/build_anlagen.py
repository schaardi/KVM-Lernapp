# -*- coding: utf-8 -*-
"""Legt die Bildanlagen der Prüfungen in Web und App ab.

Die Bilder in ``anlagen/`` sind die Quelle. Sie werden als **Dateien**
ausgeliefert, nicht als Data-URI:

    anlagen/<schlüssel>.<jpg|png>                 Web (GitHub Pages)
    flutter_app/assets/anlagen/<schlüssel>.…      App

Dazu je ein Verzeichnis mit den Metadaten – ``data/anlagen.js`` (Web) und
``flutter_app/assets/data/anlagen.json`` (App):

    {"nt25-rampe": {"f": "nt25-rampe.jpg", "t": "Abbildung 1 – …",
                    "w": 780, "h": 431}}

``f`` ist nur der Dateiname; die Front-Ends setzen ihr Verzeichnis davor.
``w``/``h`` halten beim Laden den Platz frei und geben der Lightbox die
Originalgröße. Eingebettete Data-URIs hätten die Startdateien um mehrere
Megabyte wachsen lassen, sobald die Altklausuren dazukommen – und einzelne
Dateien kann der Browser zwischenspeichern.

Die Teilaufgaben verweisen über den Schlüssel (Feld ``bild`` bzw. ``bildL``),
eine Abbildung liegt also auch bei mehreren Verweisen nur einmal vor.

    python3 scripts/pruefungen/build_anlagen.py
"""
import json
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import webdaten as W          # Inhalte der Web-App in data/*.js

QUELLE = os.path.join(HERE, 'anlagen')
APP_META = os.path.join(ROOT, 'flutter_app', 'assets', 'data', 'anlagen.json')
APP_BILDER = os.path.join(ROOT, 'flutter_app', 'assets', 'anlagen')
WEB_BILDER = os.path.join(ROOT, 'anlagen')
ENDUNGEN = ('.jpg', '.jpeg', '.png')

# Bildunterschriften: die Zuschnitt-Tabelle in anlagen_bau.py ist die Quelle,
# damit Titel und Ausschnitt nicht auseinanderlaufen. Ältere Bilder, die dort
# nicht stehen, bekommen ihren Titel hier. Schlägt der Import fehl, bricht der
# Lauf ab – früher fing ein `except` das ab und schrieb alle Anlagen ohne
# Bildunterschrift zurück.
sys.path.insert(0, HERE)
from anlagen_bau import FIGUREN
from anlagen_titel import TITEL as TITEL_EXTRAKT

TITEL = {k: v[3] for k, v in FIGUREN.items()}
TITEL.update(TITEL_EXTRAKT)
TITEL.setdefault('P-FT-20251111-s3', 'Lastverteilungsplan Sattelauflieger')


def masse(pfad):
    """Breite und Höhe in Pixeln."""
    from PIL import Image
    with Image.open(pfad) as img:
        return img.width, img.height


def sammeln():
    anlagen, dateien = {}, []
    for name in sorted(os.listdir(QUELLE)):
        stamm, endung = os.path.splitext(name)
        if endung.lower() not in ENDUNGEN:
            continue
        quelle = os.path.join(QUELLE, name)
        b, h = masse(quelle)
        eintrag = {'f': name, 'w': b, 'h': h}
        if TITEL.get(stamm):
            eintrag['t'] = TITEL[stamm]
        anlagen[stamm] = eintrag
        dateien.append((name, quelle, os.path.getsize(quelle)))
    return anlagen, dateien


def kopieren(dateien, ziel):
    """Bilder ablegen und verwaiste Dateien im Ziel entfernen."""
    os.makedirs(ziel, exist_ok=True)
    gewollt = {name for name, _, _ in dateien}
    for name, quelle, _ in dateien:
        zieldatei = os.path.join(ziel, name)
        if not (os.path.exists(zieldatei)
                and open(zieldatei, 'rb').read() == open(quelle, 'rb').read()):
            shutil.copyfile(quelle, zieldatei)
    entfernt = []
    for name in sorted(os.listdir(ziel)):
        if os.path.splitext(name)[1].lower() in ENDUNGEN and name not in gewollt:
            os.remove(os.path.join(ziel, name))
            entfernt.append(name)
    return entfernt


def dump_compact(x):
    return json.dumps(x, ensure_ascii=False, separators=(',', ':'))


def main():
    anlagen, dateien = sammeln()
    if not anlagen:
        raise SystemExit('Keine Bilder in %s' % QUELLE)
    ohne_titel = sorted(k for k in anlagen if not anlagen[k].get('t'))
    if ohne_titel:
        raise SystemExit('Ohne Bildunterschrift (in anlagen_bau.FIGUREN ergänzen): %s'
                         % ', '.join(ohne_titel))

    open(APP_META, 'w', encoding='utf-8').write(dump_compact(anlagen) + '\n')
    W.schreiben('KVM_ANLAGEN', anlagen)
    weg_web = kopieren(dateien, WEB_BILDER)
    weg_app = kopieren(dateien, APP_BILDER)

    gesamt = sum(g for _, _, g in dateien)
    print('Anlagen: %d Bilder, %.1f KB gesamt' % (len(anlagen), gesamt / 1024))
    for name, _, groesse in dateien:
        stamm = os.path.splitext(name)[0]
        print('    %-22s %6.1f KB  %4dx%-4d  %s'
              % (stamm, groesse / 1024, anlagen[stamm]['w'], anlagen[stamm]['h'],
                 anlagen[stamm].get('t', '–')))
    for weg, wo in ((weg_web, 'anlagen/'), (weg_app, 'flutter_app/assets/anlagen/')):
        if weg:
            print('    entfernt aus %s: %s' % (wo, ', '.join(weg)))
    print('  Web  data/anlagen.js + anlagen/   ·  App  assets/data/anlagen.json + assets/anlagen/')


if __name__ == '__main__':
    main()
