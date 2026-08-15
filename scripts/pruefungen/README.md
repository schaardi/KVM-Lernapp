# Original-IHK-Prüfungen als Fallaufgaben

Pipeline, die eingescannte IHK-Prüfungssammlungen (Handlungsspezifische
Qualifikationen) in Fallaufgaben der App und der Web-App überführt – samt
Musterlösungen und einem Export, den man einer KI zur fachlichen Prüfung
vorlegen kann.

## Warum die Zwischenschritte

Die Original-PDFs sind aus Word erzeugt, enthalten die Aufgaben aber **als
Bilder** – es gibt keine Textebene. Deshalb wird jede Seite gerendert und per
OCR gelesen. Die PDFs enthalten **keine Lösungen**; die Musterlösungen sind
nachträglich fachlich erarbeitet und ausdrücklich **nicht amtlich**.

## Ablauf

```bash
# 1. Seiten rendern und mit deutschem OCR lesen (benötigt poppler-utils, tesseract-ocr-deu)
pdftoppm -png -r 200 "pruefung.pdf" /tmp/ocr/OK
for f in /tmp/ocr/*.png; do tesseract "$f" "${f%.png}" -l deu; done
cat /tmp/ocr/OK-*.txt > /tmp/OK_full.txt

# 2. In Prüfungen, Aufgaben und Teilaufgaben zerlegen
python3 scripts/pruefungen/parse_exams.py /tmp        # erzeugt exams.json

# 3. Mit den Musterlösungen zu Fallaufgaben verbinden
python3 scripts/pruefungen/build_cases.py /tmp/exams.json /tmp/faelle.json

# 4. KI-Export erzeugen
python3 scripts/pruefungen/ki_export.py /tmp/faelle.json docs/pruefungen/ki-export
```

Die erzeugten Fallaufgaben werden anschließend in
`flutter_app/assets/data/cases.json` sowie in das Array `window.KVM_CASES`
in `index.html` übernommen.

## Qualitätskontrolle

Der Parser prüft sich an einer harten Invariante: **Jede vollständige Prüfung
ergibt genau 100 Punkte.** Weicht eine Prüfung ab, fehlt eine Teilaufgabe oder
die Quelle ist unvollständig. Beim ersten Durchlauf hat genau diese Prüfung
zwei Fehler aufgedeckt:

- Prüfungen heißen je nach Jahrgang „Aufgabenstellung N" **oder**
  „Situationsaufgabe N" – zwei Prüfungen waren dadurch verschmolzen.
- OCR verstümmelt das Buchstaben-Badge vor der Punktzahl (`6 |`, `|da|`,
  `ba `), wodurch zwölf Teilaufgaben verlorengingen.

Bekannte Einschränkung: Die Prüfung vom 18. Mai 2021 ist in der Quelle
**abgeschnitten** (das PDF endet mitten in Aufgabe 5); sie ergibt daher nur
80 Punkte und wird erst aufgenommen, wenn die fehlenden Seiten vorliegen.

## Musterlösungen ergänzen

`loesungen.py` enthält ein Wörterbuch mit dem Schlüssel

```
"<OK|FT>|<Datum>|<Aufgabennummer>|<Teilaufgabe>"
```

Eine Fallaufgabe wird nur erzeugt, wenn **alle** ihre Teilaufgaben eine
Musterlösung haben – halbfertige Prüfungen landen nicht in der App.

## KI-Export

`docs/pruefungen/ki-export/` enthält je Prüfung eine Markdown-Datei mit
Prüfauftrag, Ausgangssituation, allen Aufgaben und den Musterlösungen. Die
Datei lässt sich vollständig in ein KI-Chatfenster kopieren, um die Lösungen
fachlich gegenprüfen zu lassen. `alle-pruefungen.md` bündelt alle Prüfungen.
