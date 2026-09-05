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

## Nachkorrekturen (`korrekturen.py`)

Die OCR liest zuverlässig, aber nicht fehlerfrei. `build_cases.py` ruft deshalb
zum Schluss `korrekturen.anwenden()` auf. Dort steht jede Korrektur einzeln als
Paar „alt → neu“; greift eine davon nicht mehr, bricht der Lauf ab, statt die
Korrektur stillschweigend zu verlieren. Korrigiert werden:

- **Trennstriche am Zeilenende** („drei exter-\nnen Dienstleistern“).
- **Zusammengelaufene Datenlisten**: Was im Original eine Tabelle ist, liest die
  OCR als einen Absatz. Die Daten der Fahrzeug- und Linienkostenrechnungen
  stehen jetzt wieder zeilenweise.
- **Verrutschte Anlagen**: In der Prüfung vom 8. Mai 2025 hing die
  Nutzwert-Tabelle aus Anlage 2 am Ende von Aufgabe 1 c) – gehört aber zu
  Aufgabe 1 a), die ohne die Werte nicht lösbar war. Sie liegt jetzt als
  Tabelle (`tab`) an der Aufgabe und wird in App, Web-App und KI-Export
  angezeigt.
- **Zeichenverwechslungen**: `$` statt `§`, `I` statt `l`, `zZ6M` statt `zGM`,
  `DIN ISO EN 9001` statt `DIN EN ISO 9001`, `DIN 12642` statt `DIN EN 12642`.
- **Unlesbare Diagramme**: Der Lastverteilungsplan der Prüfung vom
  11. November 2025 kam als Zeichensalat an. An seiner Stelle steht eine
  Beschreibung der Achsen und des Kurvenverlaufs, mit der sich die Aufgabe
  lösen lässt.
- **Fehler in einer Musterlösung**: Die Kosten je Leistungseinheit der
  Omnibuslinien waren als „Cent je 1.000 Nutzplatzkilometer“ ausgewiesen;
  richtig sind 4,33 bzw. 4,44 Cent **je** Nutzplatzkilometer.

## Rechenaufgaben nachrechnen (`rechenpruefung.py`)

```bash
python3 scripts/pruefungen/rechenpruefung.py index.html
```

Rechnet jede Rechenaufgabe der drei Prüfungen unabhängig aus den in der
Aufgabenstellung genannten Daten nach – Fahrzeugkosten, Wirtschaftlichkeit,
Nutzplatzkilometer, Sicherungskräfte, Ladungsschwerpunkt, Lagerkennzahlen,
Andlersche Formel, Nutzwertanalyse und Kostenkalkulation – und prüft, ob die
Ergebnisse so in den Musterlösungen stehen. Exit-Code 1 bei jeder Abweichung.
Gerechnet wird mit `Decimal` und kaufmännischer Rundung, sonst weicht der Wert
schon durch die Gleitkommadarstellung um einen Cent ab.

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

## Amtliche Lösungshinweise (Stand 2026)

Seit die vollständige Prüfungssammlung *„… komplett mit Lösungen"* vorliegt,
kommen die Lösungen nicht mehr aus dem Wörterbuch `loesungen.py`, sondern
**direkt aus der Quelle** – es sind die **amtlichen Lösungshinweise der IHK**.

```bash
# OCR-Volltext liegt versioniert unter quellen/ (kein PDF nötig):
#   quellen/ihk-pruefungen-2021-2026-mit-loesungshinweisen.ocr.txt
python3 scripts/pruefungen/parse_amtlich.py   # nur Prüfen: Inventar + 100-P-Test
python3 scripts/pruefungen/build_amtlich.py   # baut & schreibt Web + App
```

- `parse_amtlich.py` liest den OCR-Volltext mit Seitenmarkern, trennt die zwei
  Layout-Epochen (2021–22 interleaved, ab 2023 Saison-Booklets) und ordnet jeder
  Teilaufgabe ihren amtlichen Lösungshinweis samt VO-Bezug und – wo angegeben –
  der Punkteverteilung zu.
- `build_amtlich.py` erzeugt daraus die Prüfungsfälle und schreibt sie in
  `flutter_app/assets/data/cases.json` **und** `window.KVM_CASES` in
  `index.html` (nur IDs mit Präfix `P-`; alle übrigen Fälle bleiben unberührt).
  Aufgenommen wird nur, was **genau 100 Punkte** ergibt und zu **jeder**
  Teilaufgabe eine nicht-leere amtliche Lösung hat.

Nicht vollständig lesbare Termine (OCR-Lücken oder in der Quelle fehlende
Lösungsseiten) werden automatisch ausgelassen. `korrekturen.py` (Bilder wie der
Lastverteilungsplan, Tabellen) wird per Schritt-ID weich eingespielt.
