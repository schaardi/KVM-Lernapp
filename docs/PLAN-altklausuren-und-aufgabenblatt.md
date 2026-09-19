# Plan: Altklausuren einspielen, Prüfungen als Aufgabenblatt, Aufgabenserien

Stand 19. 9. 2026. Drei Themen, die zusammengehören, aber getrennt umsetzbar
sind. **Erledigt** sind Teil B vollständig (B0, B1, B2, B3, B4), Teil A mit
allen vier Tranchen T1–T4 und die Übungsfragen (`PX-`) zu allen 99
Archiv-Prüfungen (siehe „Was steht" weiter unten); offen sind die
Aufgabenserien (Teil C).

- **Teil A** – Das Archiv `Altklausuren.rar` (99 IHK-Prüfungen der
  Industriemeister-Basisqualifikationen, Herbst 2014 bis Frühjahr 2024, alle
  mit amtlichen Lösungshinweisen) über die bestehende Pipeline in startbare
  Prüfungen, Übungsfragen und Anlagen überführen. Textlayer und Inventar
  liegen bereits im Repo.
- **Teil B** – Die Darstellung der Prüfungen neu schichten: statt einer
  Teilaufgabe je Bildschirm ein **Aufgabenblatt**, auf dem Aufgabe N mit
  Ausgangslage, Anlagen und **allen** Teilaufgaben a–x sichtbar ist. Grafiken
  und Tabellen bekommen dabei einen festen Platz und werden zoombar. Vorweg
  müssen die Daten aus `index.html` ausgelagert werden – mit 121 Prüfungen
  passt das nicht mehr in eine Datei.
- **Teil C** – Die Übungsfragen (`PX-`) als **Aufgabenserien** verketten, damit
  die Lernenden beim Lösen von a) auch b) und c) kennen.

Auslöser (Nutzer, 14. 9. 2026): „Die Darstellung (auch die Grafiken)
überdenken und den Aufbau der Fragen von a–x durchdenken und neu schichten.
Manchmal ist es wichtig, auch die anderen Fragen zu kennen, um z. B. a)
richtig zu lösen." – und: „Nutze diese ganzen Klausuren für unsere App."

## Was steht (19. 9. 2026)

| Schritt | Stand |
|---|---|
| **B0** Inhalte aus `index.html` auslagern | **fertig** – `data/questions.js`, `data/cases.js`, `data/anlagen.js`, geladen über `<script src>`; `index.html` 3,3 MB → 280 KB. Einzige Schnittstelle: `tools/webdaten.py` |
| **B1** Datenmodell Aufgabenblatt | **fertig** – `scripts/pruefungen/aufgaben_modell.py`; Fälle tragen `aufgaben[]`, Schritte `nr/teil/pts/braucht`. Schritt-IDs unverändert, Exporte zeichengleich, Web und App lesen die Felder (Darstellung noch wie bisher) |
| **B4** Bilder als Dateien | **fertig** – `anlagen/` bzw. `assets/anlagen/`, Verzeichnis nur noch mit Dateiname, Titel und Maßen; in der App öffnen sie sich als Vollbild mit Zoom |
| **A0/A1** Archiv, Inventar, Textlayer | **fertig** – 99 Textlayer, `quellen/INVENTAR-altklausuren.md` |
| **A T1** F2023, H2023, F2024 | **fertig** – 14 Prüfungen, 10 Abbildungen; Bestand jetzt **36 Original-Prüfungen** |
| **B2** Web-Aufgabenblatt | **fertig** – eigener Bildschirm `scrBlatt`: Aufgaben-Stepper, Ausgangslage und Anlagen einmal am Kopf, alle Teilaufgaben a–x als Karten mit eigenem Antwortfeld, Aufdecken je Teil oder je Aufgabe, Zwischenergebnis aus `braucht`, Lightbox mit Zoom, Ergebnis nach Aufgaben gruppiert, Übersicht mit Fach-Filter |
| **B3** Flutter-Aufgabenblatt | **fertig** – `screens/aufgabenblatt_screen.dart` mit Stepper, Ausgangslage, Anlagen am Kopf, Teil-Karten mit Antwortfeld und Selbstbewertung, Prüfauftrag über die ganze Aufgabe; Prüfungsübersicht zeigt die Aufgaben mit Teil-Chips |
| **A T2** F2019 … H2022 | **fertig** – 40 Prüfungen, 36 neue Anlagen; Bestand jetzt **76 Original-Prüfungen** |
| **A T3** F2018, H2018 | **fertig** – 10 Prüfungen, 7 Anlagen, neuer `parse_imbq_alt.py`; Bestand jetzt **86 Original-Prüfungen** |
| **A T4** H2017 … H2014 | **fertig** – 35 Prüfungen aus PDF24-Scans, alle 100/100 beidseitig und gegen die Seitenbilder gesichtet; 46 Abbildungen (davon 23 Lösungszeichnungen) und 26 Tabellenanlagen; neu `ocr_scan.py` (Nachbesserung des Tesseract-Textlayers) und die Rohtext-Korrekturen `ROHTEXT`. Bestand jetzt **121 Original-Prüfungen** (alle 99 Hefte des Archivs, dazu die 22 aus H2024/H2025 und den eigenen Sätzen) |
| **C** Aufgabenserien | offen |
| Übungsfragen (`PX-`) aus T1 bis T3 | **fertig** – 16 Quellensätze, 788 `PX-`-Fragen (vorher 327). Zu jeder der 64 neuen Prüfungen ein eigener Satz von 25 bis 43 Fragen, Schwerpunkt auf den Rechenwegen der Originallösungen |
| Übungsfragen (`PX-`) aus T4 | **fertig** – 7 Quellensätze (H2017 bis H2014), 326 neue `PX-`-Fragen (196 Auswahl-, 130 Rechenfragen), je Termin 43 bis 56 über alle fünf Hefte; Bestand jetzt **1.114** `PX-`. Rechtsstand auf heute gezogen (siehe A4a, Nachtrag T4); Dublettenvergleich (Jaccard ≥ 0,65) gegen den ganzen Pool und untereinander vor dem Bau, 0 Treffer im Endstand |
| Lösungszeichnungen der Methoden-Hefte | **fertig** – sieben der acht Aufgaben „Stellen Sie … in einem Diagramm dar“ aus T2 haben jetzt ihr Lösungsbild (`bildL`). Die achte (F2022 4 b) hat als amtliche Lösung eine Tabelle, keine Zeichnung |
| Verrutschte Tabellen | **fertig** – sechs Datentabellen, die als Fließtext in Frage oder Ausgangslage standen, hängen als Tabellenanlage an ihrer Aufgabe. `build_amtlich.py` spielt außerdem die Textkorrekturen wieder ein, die seit dem Aufgabenblatt-Umbau ins Leere liefen |

Neue Werkzeuge: `scripts/pruefungen/anlagen_extrakt.py` (Abbildungen über ihre
Bildunterschrift aus dem Heft schneiden – ersetzt das Abmessen von Koordinaten
in `anlagen_bau.py`), `scripts/pruefungen/korrekturen_basis.py` (Nachkorrekturen
für Text, Punktzahlen, Teil-Buchstaben, Prüfungstag und Ausgangslage),
`scripts/pruefungen/inventar.py`, `scripts/pruefungen/quellen_bau.py`.
`anlagen_bau.py` hat mit `AUSZUEGE` eine zweite Tabelle: Abbildung je
Schlüssel, geholt ohne Koordinaten – entweder als eingebettetes Bild oder über
ihre Bildunterschrift. Welches Bild zu welchem Schlüssel wurde, steht damit
zum ersten Mal im Repository und lässt sich aus den PDFs nachbauen.

## Ausgangslage

### Bestand in der App

Stand nach T4 und den Übungsfragen dazu (in Klammern der Stand vor dieser Session):

| Was | Stand | Wo |
|---|---|---|
| Startbare Prüfungen (`P-`) | **121** (22) – 13 × Kraftverkehr FT/OK 2021–2026, 108 × Basisqualifikation H2014–H2025, alle mit amtlichen Lösungshinweisen, je 100 Punkte; 822 Aufgaben mit 2.030 Teilaufgaben | `flutter_app/assets/data/cases.json` (1,4 MB), `data/cases.js` |
| Fallaufgaben ohne IHK-Bezug | 15 (`F-`/`R-`/`M-`/`Z-`, je 4–5 Teile, Musterlösungen) | ebd. |
| Übungsfragen aus Prüfungen (`PX-`) | **1.114** (327) – 127 Kraftverkehr, 987 aus den Basisqualifikationen H2014–H2025; 696 Auswahl-, 418 Rechenfragen | `questions.json`, Quellensätze `scripts/pruefungen/fragen/*.json` |
| Bildanlagen | **120** (67) als Dateien; 69 an einer Aufgabe, 52 an einer Lösung | `anlagen/`, `flutter_app/assets/anlagen/`, Verzeichnis in `data/anlagen.js` |
| Tabellenanlagen | **40** (7) als `tab` – an Aufgabe oder Schritt | an Aufgabe oder Schritt |
| `index.html` | **280 KB** (3,3 MB) – die Inhalte liegen daneben in `data/*.js` | Root |

### Wie eine Prüfung heute dargestellt wird

- Eine Prüfung ist ein `case` mit flachen `steps[]`; **jeder Schritt ist eine
  Teilaufgabe** (`P-BW-20251106-s3` = 4. Schritt). Der Schritt-Text `q` ist ein
  zusammengesetzter String: `"Aufgabe 2 c) · 3 Punkte\n\n<Situation der
  Aufgabe 2>\n\n<Fragestellung c>"`. Web (`splitTask`, `index.html:1335`) und
  App (`TaskParts.of`, `models.dart:47`) zerlegen ihn per Regex wieder.
- Die Situation der Aufgabe wird **in jedem Schritt wiederholt** (bei Aufgabe 2
  der BWL H2025 viermal derselbe Absatz mit den Beschaffungsdaten).
- Web: `startRound('cases', id, startIdx)` (`index.html:1194`) legt die Schritte
  in `state.pool`; `renderQuestion` (`:1428`) zeigt **eine** Teilaufgabe mit
  „Teil 4/17", die Ausgangssituation zu allen Aufgaben als `<details id="qCase">`
  (nur beim ersten Schritt offen), den Fragetext im Chat-Layout
  (`buildOpenChat`, `:1374`: Prüfer-Blase mit Kopf, Situation, Frage, Tabelle,
  Bild; nach dem Aufdecken die eigene Antwort, die amtliche Lösung samt
  `bildL`, der KI-Export-Button und die Punkte-Selbstbewertung).
- App: `QuizScreen` mit `RoundMode.cases` (`quiz_screen.dart`), gleiches
  Prinzip – `_caseBanner()`, `_taskText()`, `_bild()`, „Teil i/total".
- Übersicht: Web-Modal `mPruef` (`index.html:3380 ff.`) und
  `pruefungen_screen.dart` zeigen je Prüfung eine Kachel mit „Prüfung starten",
  „Für KI kopieren" und – eingeklappt – ein Raster aus **allen Teilaufgaben**
  (`Aufgabe 2 c) · 3 P.`), 10–22 Chips ohne Gruppierung nach Aufgabe.
- Eigene Antworten und Selbstbewertung hängen an der **Schritt-ID**
  (`localStorage`/`SharedPreferences`: `kvm_open_answers`, `kvm_open_points`).
  Die IDs müssen deshalb stabil bleiben.
- Grafiken: `bildHTML(ref)` bzw. `_bild(ref)` rendern das Bild in voller Breite
  in die Prüfer-Blase, ohne Zoom. Eine Abbildung, die zur ganzen Aufgabe
  gehört, hängt heute **an jedem Teil einzeln** (`anlagen_imbq.BILDER` ist
  je Label eingetragen: `nt25-rampe` an 3 a/b/c, `nt25-typenschild` an
  5 a–d, `nt24-flug-wind` an 4 a–c) – beim Blättern erscheint sie also drei-
  bis viermal, und das Typenschild ist auf dem Handy ohne Zoom kaum lesbar.

Warum das den Nutzer stört: Wer 2 a) beantwortet, sieht nicht, dass 2 c) die
optimale Bestellmenge und 2 d) die Gesamtkosten verlangt – und rechnet in a)
schon zu viel oder das Falsche. Im Original liegt das Aufgabenblatt komplett
vor; die IHK erwartet die Antwort im Umfang der Teilaufgabe.

### Das Archiv `Altklausuren.rar` – was drin ist

Google Drive, Datei-ID `1REtcGsj7_pR2w0iely_zHF3mq2HFLeZP`, 201 MB, RAR 5;
am 17. 9. 2026 per Link-Freigabe geholt, entpackt und inventarisiert
(`scripts/pruefungen/inventar.py` → `scripts/pruefungen/quellen/INVENTAR-altklausuren.md`).
Die PDFs selbst bleiben außerhalb des Repos.

- **108 PDFs = 100 Fachhefte + 8 Sammelbände.** Ausschließlich
  **Industriemeister-Basisqualifikationen** (keine Kraftverkehr-Prüfungen):
  fünf Fächer (RBH = Rechtsbewusstes Handeln, BWH = Betriebswirtschaftliches
  Handeln, MIKP = Methoden der Information, Kommunikation und Planung, ZIB =
  Zusammenarbeit im Betrieb, NTG = Naturwissenschaftliche und technische
  Gesetzmäßigkeiten) × **20 Termine** von Herbst 2014 bis Frühjahr 2024.
  Kein Termin überschneidet sich mit den 9 vorhandenen BQ-Prüfungen
  (H2024, H2025).
- **99 verschiedene Prüfungen.** `BQ 2023/Herbst/MIKP 2023 November.pdf` ist
  zeichengleich mit der ZiB-Prüfung desselben Termins – **MIKP H2023 fehlt**
  im Archiv. Die 8 Sammelbände (`Herbst 2014.pdf`, `BQ Frühjahr 2015.pdf`, …,
  `2019 Herbst_compressed.pdf`) enthalten nur Hilfsmittelliste + die fünf
  Fachhefte desselben Termins noch einmal – Dubletten, nur als Ersatz für
  fehlende Seiten nützlich.
- **Alle 99 sind Lösungshefte** („L 050-0N-MMJJ"): sie enthalten die
  vollständigen Aufgaben **und** die amtlichen Lösungshinweise. Prüfungen
  ohne Lösung (Klasse K4) kommen im Archiv nicht vor; die Entscheidung dazu
  (unten, Nr. 2) bleibt für künftige Quellen gültig, greift hier aber nicht.
- **Drei Heftformate** (Spalte „Format" im Inventar):

  | Format | Termine | Prüfungen | Aufbau | Textlayer |
  |---|---|---:|---|---|
  | **PL** | F2023, H2023, F2024 | 14 | Prüfungsheft (P-Nr.) und Lösungsheft (L-Nr.) hintereinander, Lösungsteil beginnt mit Zeile `Lösungshinweise`, Badges `a Mögliche Punktzahl: n` – identisch zu H2024/H2025 | nativ (Word/Acrobat) |
  | **L-I** | F2019 – H2022 | 40 | nur Lösungsheft; `Aufgabe N` (mit Badges) und `Lösungshinweise Aufgabe N` (Badges wiederholt, `[VO: …]`) **wechseln sich ab**; Deckblatt trägt schon die Zeile `Lösungshinweise` | nativ; ZiB H2021 nur als Scan (7 Seiten, ohne Deckblatt) |
  | **L-ALT** | H2014 – H2018 | 45 | nur Lösungsheft; Teilaufgaben `a) … (4 Punkte)` (Punkte am Ende der ersten Zeile), Kopf `Lösungshinweise Aufgabe N (13 Punkte)`, `[VO: § 4 Absatz 3 Nr. 1]` (ab 2016) bzw. `(RP: 1.4.4)` (2014/15), Deckblatt mit `Prüfungstag` statt `Datum:` | 2018 nativ (10); 2014–2017 Scans (28) und RBH mit unbrauchbarer Fremd-OCR (7) → alle 35 mit Tesseract neu gelesen |

- **Textlayer liegen im Repo:** `scripts/pruefungen/quellen/imbq-<f|h><jahr>/0N-<fach>.txt`
  mit Seitenmarkern, erzeugt von `scripts/pruefungen/quellen_bau.py`
  (`pdftotext -layout`; für Scans `pdftoppm -r 300 -gray` + `tesseract -l deu
  --psm 3`). 99 Dateien, 19 Termine (`imbq-h2014` … `imbq-f2024`; `imbq-h2023`
  ohne `03-methoden.txt`).
- **Auffälligkeiten aus dem Inventar**, die Korrekturen brauchen:
  - NTG H2022: Deckblatt sagt „3. November **2023**" – Druckfehler, Termin laut
    Ordner und Schwesterheften 3. 11. 2022 → Fall-ID `P-NT-20221103`, Datum
    per Korrektur setzen.
  - ZiB H2021: Scan ohne Deckblatt → Datum/Anzahl Aufgaben aus dem
    Schwesterheft RBH H2021 (3./4. November 2021) übernehmen.
  - Deckblätter von BWH F2016, BWH H2016, ZiB H2016 sind per OCR nicht
    lesbar (Datum fehlt) → Datum aus den Schwesterheften.
  - Eingebettete Bilder (Spalte „Bilder"): NTG-Hefte im Median 15
    (Abbildungen zu Mechanik/Elektrotechnik), RBH F2017 185 und MIKP H2018
    87 sind Bildkacheln aus Scan/Layout, keine Anlagen – je Prüfung sichten.
- **Fachlicher Stand:** Recht und BWL von 2014–2018 spiegeln den damaligen
  Rechtsstand (u. a. Mutterschutz 2018, BetrVG-Novelle 2021, Nachweisgesetz
  2022, Mindestlohn). Die Aufgaben sind als Prüfungstraining weiter wertvoll,
  aber Übungsfragen daraus brauchen einen Gegenprüfer mit ausdrücklichem
  Auftrag „Rechtsstand heute". Vorschlag: Prüfungen vor 2019 im
  Aufgabenkopf mit „Prüfung von 2016 – Rechtsstand beachten" kennzeichnen
  (Feld `hinweis` am Fall, siehe B1).

## Rechtliches (bleibt eine Entscheidung des Nutzers)

Die IHK-/DIHK-Prüfungen tragen den Vermerk „Einsatz nur im Rahmen des
Korrekturprozesses gestattet. Weitergabe an unbefugte Dritte untersagt."
PDFs werden **nicht** eingecheckt. Textlayer (`scripts/pruefungen/quellen/`,
jetzt 99 Dateien mehr) und zugeschnittene Abbildungen
(`scripts/pruefungen/anlagen/`) liegen im **öffentlichen** Repo. Wer umsetzt,
hält sich an diese Praxis, weist im PR aber erneut darauf hin.

## Teil A – Altklausuren einspielen

### A0 – Beschaffung (erledigt) und Reproduktion

Sollte das Archiv erneut gebraucht werden (Sammelbände, Seitenbilder für
Anlagen), solange die Link-Freigabe steht:

```bash
curl -L -o Altklausuren.rar \
  'https://drive.usercontent.google.com/download?id=1REtcGsj7_pR2w0iely_zHF3mq2HFLeZP&export=download&confirm=t'
file Altklausuren.rar                      # "RAR archive data, v5" – sonst kam die Login-Seite
apt-get install -y libarchive-tools tesseract-ocr tesseract-ocr-deu poppler-utils
bsdtar -xf Altklausuren.rar -C <scratch>
python3 scripts/pruefungen/inventar.py <scratch>/Altklausuren --md quellen/INVENTAR-altklausuren.md
python3 scripts/pruefungen/quellen_bau.py <scratch>/Altklausuren --nur f2024,h2023   # Textlayer je Termin
```

`quellen_bau.py` überspringt Sammelbände und Dateien, deren Inhalt nicht zum
Dateinamen passt (so fiel das ZiB-Doppel auf), und liest Scans sowie
Fremd-OCR („PDF24 Tools - OCR") mit Tesseract neu. Tesseract nur mit
`--psm 3` und `OMP_THREAD_LIMIT=1` aufrufen – `--psm 4` hängt minutenlang auf
den grafischen Deckblättern.

### A1 – Inventar (erledigt)

`scripts/pruefungen/quellen/INVENTAR-altklausuren.md` (Markdown-Tabelle je
PDF: Seiten, Zeichen/Seite, Bilder, Fach, Datum, Anzahl Aufgaben, Badges,
Lösungshinweise, Heftnummer, Format, Klasse, Fall-ID, Erzeuger, Hinweis).
Termin × Fach (Format; `*` = Scan/OCR):

| Termin | RE | BW | MI | ZI | NT |
|---|---|---|---|---|---|
| H2014 – H2016 (5 Termine) | L-ALT* | L-ALT* | L-ALT* | L-ALT* | L-ALT* |
| F2017, H2017 | L-ALT* | L-ALT* | L-ALT* | L-ALT* | L-ALT* |
| F2018, H2018 | L-ALT | L-ALT | L-ALT | L-ALT | L-ALT |
| F2019 – F2022 (7 Termine) | L-I | L-I | L-I | L-I | L-I (ZI H2021: L-I*) |
| H2022 | L-I | L-I | L-I | L-I | L-I (Datum korrigieren) |
| F2023 | PL | PL | PL | PL | PL |
| H2023 | PL | PL | **fehlt** | PL | PL |
| F2024 | PL | PL | PL | PL | PL |

Fall-IDs wie bisher `P-<RE|BW|MI|ZI|NT>-<JJJJMMTT>` aus dem Datum des
Deckblatts (Termin: Mai = Frühjahr, November = Herbst).

### A2 – Parser je Format (mit Trockenlauf-Ergebnissen)

Alle Termine werden in `parse_imbq.JAHRGAENGE` eingetragen
(`'f2024': {'dir': 'imbq-f2024', 'korrekturen': 'korrekturen_imbq_f2024',
'format': 'PL', 'pruefungen': [...]}`); `H2023` ohne `METHOD`. Der Parser
wählt nach `format`:

**PL (14 Prüfungen)** – `parse_imbq.py` unverändert. Trockenlauf ohne
Korrekturen: 8 von 14 sofort 100/100 (RE/MI/ZI F2024, RE/BW/ZI H2023, MI/ZI
F2023). Zu korrigieren wie bei H2024/H2025 (Badge-Tippfehler, Bild-Lösungen):

| Prüfung | Befund | Vermutung |
|---|---|---|
| BW F2024 | Lösungsteil 103 P, A1c 6≠9 | Badge im Lösungsheft falsch |
| NT F2024 | Lösungsteil 102 P, A4a 10≠11, A4b 6≠7 | Badges im Lösungsheft |
| NT H2023 | Frageteil 92 P | Badge fehlt im Textlayer (Zeilenumbruch) – Seite prüfen |
| RE F2023 | A8a 6≠4, A8b Lösung fehlt | Lösungsteil A8 anders gegliedert |
| BW F2023 | Lösungsteil 93 P, A6a 10≠3 | Badge/Anlage |
| NT F2023 | Lösungsteil 83 P, A2a Lösung fehlt | Lösung nur als Bild/Anlage |

**L-I (40 Prüfungen)** – neuer Modus in `parse_datei`: Sobald vor der ersten
`Aufgabe N` eine Zeile `Lösungshinweise` steht (Deckblatt), werden die Zeilen
nicht am Deckblatt geteilt, sondern **umsortiert**: jede Zeile ab `^Aufgabe N$`
gehört zum Frageteil, ab `^Lösungshinweise Aufgabe N$` zum Lösungsteil, bis
zum nächsten Wechsel; danach laufen `aufgaben(frage, False)` und
`aufgaben(loes, True)` wie bisher. Die Ausgangssituation (nur RBH) steht
zwischen Deckblatt und Aufgabe 1. Prototyp (15 Zeilen) im Trockenlauf:
**35 von 39** Textlayer-Prüfungen sofort 100/100 mit Label-Deckung. Rest:

| Prüfung | Befund |
|---|---|
| NT H2022 | Datum „3. November 2023" (Druckfehler) → per Korrektur; A6d Lösung leer (Bild) |
| MI F2021 | A2a Lösung leer (Diagramm) |
| NT F2021 | A3a Lösung leer (Skizze) |
| BW H2019 | Lösungsteil 88 P, A7a Lösung fehlt (Anlage/Tabelle) |
| ZI H2021 | OCR-Text, noch nicht getestet |

```python
# Prototyp L-I (in parse_datei, wenn LOES_TL vor der ersten AUFG-Zeile steht)
frage, loes, ziel = [], [], None
for l in lines:
    if AUFG.match(l):   ziel = frage
    elif LOES_A.match(l): ziel = loes
    if ziel is not None: ziel.append(l)
A, L = aufgaben(frage, False), aufgaben(loes, True)
```

**Erfahrungen aus T3** (für T4 einplanen):

- Die Symbol-Schrift war die größte Fehlerquelle im ganzen Archiv, nicht die
  Heftform: ``clean()`` hat alles aus dem Privatbereich U+F0xx weggeworfen, was
  die Tabelle nicht kannte – **845 Gleichheitszeichen**, 124 Plus, 91 Minus.
  Die Tabelle deckt jetzt die ganze Adobe-Symbol-Kodierung ab. Vor jeder
  weiteren Tranche lohnt ein Blick auf die Privatbereich-Zeichen der neuen
  Quellen.
- Die Punktzahl am rechten Rand verrutscht in der Heftform L-ALT regelmäßig um
  eine Zeile. Die Regel „allein stehende Punktzahl unmittelbar vor einer
  Teilaufgabe gehört zu dieser“ trägt; die 100-Punkte-Summe allein deckt den
  Fehler **nicht** auf, weil zwei Teile nur ihre Punkte tauschen. Der Abgleich
  mit den eindeutig gedruckten Paaren (Buchstabe und Klammer in derselben
  Zeile) ist die eigentliche Probe.
- Kopfzeilen können doppelt und versetzt gesetzt sein (MIKP H2018). Die
  Bruchstücke am Ende („IN,“, „Kommunikation und“) sind so gewöhnliche Wörter,
  dass nur eine Korrektur hilft – ein Filtermuster nähme echten Text mit.

**Erfahrungen aus T2** (für T3/T4 einplanen):

- Die Fußzeile `L 050-01-0519-7` trägt eine Prüfziffer, die das alte
  JUNK-Muster nicht kannte – sie stand **459-mal** mitten im Aufgaben- und
  Lösungstext. Nach dem Filter fielen fünf Lösungen auf, die *nur* aus dieser
  Heftnummer bestanden: reine Zeichnungen ohne Text. Für T3/T4 ist das Muster
  der Fußzeile also zuerst zu prüfen, sonst täuscht `pruefe()` Vollständigkeit
  vor.
- `pruefe()` prüft neben den Punkten jetzt auch den Prüfungstag gegen den
  Termin. Das hat einen Druckfehler (NTG H2022: „3. November 2023“) und ein
  fehlendes Deckblatt (ZiB H2021) gefunden, die sonst als falsch einsortierte
  Prüfung durchgerutscht wären.
- Beschriftungen aus Zeichnungen („R1 R2 UEIN R3 UAUS 1 kΩ“) landen als
  Fließtext in der Ausgangslage. Dafür gibt es die Korrekturtabelle `INTRO`;
  die Zeichnung selbst hängt als Anlage an der Aufgabe.

### A4a – Erfahrungen aus den Übungsfragen (T1 bis T4)

Zu jeder der 64 neuen Prüfungen ist ein Satz `scripts/pruefungen/fragen/imbq-<termin>.json`
entstanden, gebaut aus dem Digest der amtlichen Lösung (Aufgabe, Teil, Punkte,
Lösungstext). Aus 794 Kandidaten sind 788 Fragen geworden; sechs waren
Dubletten und wurden vom Builder verworfen.

- **Die Toleranz bei `calc` ist 0,01 absolut** (`index.html`, `checkCalc`) und
  lässt sich je Frage nicht übersteuern – `clean_q` übernimmt kein `tol`.
  Damit ist jede Frage unbrauchbar, deren Ergebnis von der Rundung des
  Zwischenschritts abhängt: Der Verdichtungsdruck aus „1:17“ ergibt je nach
  Rundung des Teilvolumens 68,03 oder 68,06 bar. Solche Aufgaben bekommen
  entweder den Zwischenwert vorgegeben oder eine ausdrückliche Rundungsansage
  („auf ganze Millimeter gerundet“).
- **Die amtliche Lösung ist nicht immer konsistent.** Beim Beschickungswagen
  (NTG F2018, Aufgabe 4) fehlt in der Musterrechnung die Masse des Wagens
  selbst; die Zeichnungslösung zum Wahrscheinlichkeitsnetz (NTG H2021) war in
  unserer eigenen Korrekturtabelle mit x̄ ∓ 3s beschriftet, obwohl die
  Prozentwerte zu x̄ ∓ s gehören. Wo die Vorlage nicht trägt, wird die Frage
  umformuliert statt den Fehler zu übernehmen.
- **Dubletten entstehen fachlich, nicht wörtlich.** Der Builder vergleicht
  normalisierten Fragetext; inhaltlich gleiche Fragen mit anderer Formulierung
  rutschen durch. Die Streik-Voraussetzungen aus F2018 standen so fast
  wortgleich schon als `R-BR-035` im Pool. Ein Ähnlichkeitsvergleich über
  Wortmengen (Jaccard ≥ 0,65 auf dem normalisierten Fragetext) hat fünf
  weitere gefunden – darunter zwei Aufgaben, welche die IHK in zwei Terminen
  wörtlich wiederverwendet hat (Winkelprofil H2019/H2023, Drohne H2019/H2024).
  Alle sechs sind durch andere Aufgaben desselben Hefts ersetzt; der Vergleich
  gehört künftig in die Abnahme jedes neuen Satzes.
- **Abnahme:** `build_exam_questions.py`, `tools/sync_content.py --check` und
  `--validate-assets`, dazu zwei Läufe im Headless-Browser – ein
  Struktur-Check über alle `PX-` und ein Lauf, der neue Rechenfragen in der
  Oberfläche beantwortet und die Musterantwort gegen `checkCalc` prüft.

**Nachtrag T4** (sieben Sätze `imbq-h2017` … `imbq-h2014`, 326 Fragen aus den
Digests der Scan-Hefte; der Builder hat davon keine verworfen):

- **Der Rechtsstand der Hefte ist alt.** Die Lösungen von 2014 bis 2017
  zitieren aufgehobenes Recht: § 91 und § 85 SGB IX (heute §§ 174, 168),
  § 32 und § 35 BDSG (heute § 26 BDSG, Artikel 16 und 17 DSGVO), § 4f BDSG
  (heute Artikel 37 DSGVO, § 38 BDSG), §§ 4, 8, 9 MuSchG alter Fassung
  (heute §§ 4, 5, 11, 17), das AÜG vor der Reform 2017 (Höchstdauer 18
  Monate, Equal Pay nach neun Monaten), Verpackungs- und Batterie**verordnung**
  (heute VerpackG, BattG), das Kreislaufwirtschafts- und Abfallgesetz (heute
  KrWG). Jede Frage nennt das heutige Recht und in der Erklärung die alte
  Fundstelle, damit die amtliche Lösung im Heft nicht widerspricht.
- **Die IHK wiederholt Aufgaben wörtlich** – auch über Jahre: RE F2015 und
  F2017 teilen sich die Aufgaben zu Aushilfen, Urlaub, Toilettenunfall und
  Betriebsvereinbarung; ZI F2017 fragt Schlüsselqualifikation, teilautonome
  Gruppe und informelle Gruppen so, wie es schon in T1–T3 stand. Der
  Jaccard-Vergleich (≥ 0,65) fand neun Paare, davon drei wortgleich mit
  vorhandenen `PX-`, eines inhaltsgleich (Organe der GmbH mit 1.800
  Beschäftigten), drei nur wortähnlich bei anderem Inhalt (Stab- statt
  Einliniensystem, situative statt laterale Führung) und eines innerhalb der
  neuen Sätze (Zeitgrad F2017/H2015). Alle sind vor dem Bau durch andere
  Aufgaben desselben Hefts ersetzt oder umformuliert; F2015 deckt nur die
  Aufgaben ab, die F2017 nicht schon hat.
- **Gerundete Zwischenwerte in den alten Lösungen.** Die Hefte rechnen mit
  gerundeten Winkeln und Geschwindigkeiten weiter (Kurvenfahrt 59,65 statt
  59,66 km/h, Aufprall 17,15 statt 17,16 m/s, Rampe 281,2 statt 281,5 N,
  Seildrähte 179,26 statt 180,2). Wo exakter und gerundeter Rechenweg um mehr
  als die Toleranz auseinanderliegen, fragt die Übungsfrage in einer Einheit
  oder Stellenzahl, in der beide Wege dasselbe ergeben (m/s statt km/h,
  ganze Newton), oder gibt den Zwischenwert vor („rechnen Sie mit
  sin α = 0,0624“).
- **`Entgelt und Arbeitszeit`** steht in `TAX` unter Fach 4; der Builder biegt
  ein `f: 2` stillschweigend um. Die Quellensätze tragen jetzt einheitlich
  Fach 4, damit Quelle und Ausgabe übereinstimmen.
- **Abnahme** wie oben, zusätzlich ein Lauf, der jede neue Rechenfrage in den
  Schreibweisen „1600“, „0.506“ und „0,506“ durch `parseCalcNum` schickt.
  Dabei aufgefallen (nicht geändert): `parseCalcNum` liest „28.800“ ohne
  Komma als 28,8 – Tausenderpunkte ohne Nachkommastellen werden nicht
  erkannt; wer die Zahl so eintippt, bekommt „falsch“.

### A2a – Die Scans (T4): wie sie eingespielt wurden

`parse_imbq_alt.py` liest die 35 Scans über den **Lösungskopf** statt über die
Aufgabenüberschrift: `Lösungshinweise Aufgabe N (x Punkte)` wird zuverlässig
erkannt, die verzierte Ziffer der Überschrift dagegen nicht (`Aufgabe En`,
`Aufgabe |s`, manchmal gar nichts). Ohne Handarbeit erreichte trotzdem nur
**1 von 35** Heften 100/100. Drei Werkzeuge haben den Rest getragen:

- **`ocr_scan.py`** zieht den Tesseract-Textlayer vor dem Parsen gerade:
  Paragrafen (`88 53` → `§§ 53`, `8 102` nach „gemäß“ → `§ 102`), Umlaute aus
  einem Wortschatz der sauberen Hefte, Aufzählungszeichen in allen Lesarten
  (`= _`, `=»`, `«=`, `"=`, `®`, `>` …), verstümmelte Teilmarker (`eb)`, `€)`),
  „Z. B.:“ in jeder Schreibweise, die abgesetzte **Punktespalte** (steht mal
  hinter der Fußzeile, mal mitten auf der Seite – sie wird den Teilmarkern
  der Seite in Lesereihenfolge zugeordnet, wenn die Zahl der Klammern zur
  Zahl der offenen Marker passt), Kopf- und Fußzeilen in Dutzenden Lesarten
  sowie ganze Seiten, die quer oder auf dem Kopf gescannt sind (erkennbar an
  der gespiegelten Kopfzeile oder daran, dass fast nur ein- und zweistellige
  Bruchstücke übrig bleiben).
- **`ROHTEXT`** im Korrekturmodul: Ersetzungen im Rohtext *vor* dem Parsen,
  jede muss genau einmal greifen. Damit werden verschluckte Marker
  (`D)N 2 Z.B` → `b) Z. B.:`), verlorene Lösungsköpfe und falsch verteilte
  Klammern gesetzt – der einzige Weg, wenn der Parser die Struktur selbst
  nicht mehr sehen kann.
- **`LOESUNG`/`FRAGE`/`INTRO`** wie in T1–T3, jetzt aber für jede Rechenaufgabe
  ein vollständiges Abschreiben des Rechenwegs vom Seitenbild: Formeln
  überleben den Scan nie (`P = U² / R` wird zu `2 a pe R`). Tabellen im Text
  gehen als Tabellenanlage an die Aufgabe, Zeichnungen und Lösungsdiagramme
  als Zuschnitt (`anlagen_bau.FIGUREN`, quer gedruckte Anlagen mit
  Drehwinkel).

Jede der 35 Prüfungen wurde Aufgabe für Aufgabe gegen die Seitenbilder
(`pdftoppm -r 120`) gelesen; die Sichtprüfung kostete je Heft die geplanten
1–2 h. Die Hefte bis 2015 nennen den Verordnungsbezug in runden Klammern
(`(VO: § 4 Abs. 2 Nr. 1)`, `(RVO § 4 Absatz 2 Nr. 1)`), die von 2014 nur den
Rahmenplan (`(RP: 1.5.2)`) – letzterer wird nicht mitgeführt.

**Erfahrungen aus T4:**

- Die MRC-Scans (100-ppi-JPEG plus 200-ppi-Bilevel-Stencil) haben i-Punkte und
  Umlautpunkte physisch verloren; bessere Tesseract-Modelle (`tessdata_best`)
  und höhere Auflösung ändern daran nichts. Nachkorrektur mit Wortschatz und
  festen Regeln ist der Hebel, nicht die OCR.
- Die 100-Punkte-Probe bleibt notwendig, aber sie sieht nur die Struktur.
  Zahlen im Text (Maße, Beträge, Paragrafen) sind nur mit dem Seitenbild zu
  prüfen – und dort waren sie regelmäßig falsch („23,92“ statt 23,52 €;
  Rang „2“ statt 3).
- Punktespalten wandern: Zwei Klammern in einer Teilaufgabe (Szenario 1 und 2
  à 3 Punkte) lassen den Parser die erste nehmen; das fällt nur an der Summe
  auf. `PUNKTE` überschreibt seit T4 auch den Frageteil.
- Lösungsseiten für Anlagen stehen physisch hinter der letzten Aufgabe und
  liefen als Buchstabensalat in deren Lösung; der Schnitt an `Anlage N zu
  Aufgabe M` und das Verwerfen gedrehter Seiten halten sie draußen.
- Silbentrennung an Aufzählungspunkten und Ergänzungsstriche („Anfangs- und
  Endzeitpunkte“) waren in allen Tranchen falsch zusammengesetzt; die
  Korrektur in `join_para` hat rückwirkend auch T1–T3 verbessert, ohne dass
  eine Korrektur ins Leere lief (eine wurde überflüssig).

### A3 – Reihenfolge, Tranchen, Aufwand

Neueste zuerst; jede Tranche ein eigener PR mit Prüfungen **und** ihren
Übungsfragen und Anlagen:

| Tranche | Termine | Prüfungen | Parser | Aufwand (Richtwert) |
|---|---|---|---:|---|
| T1 | F2024, H2023, F2023 | 14 | PL, vorhanden | 6 Korrekturen · je Prüfung 30–45 min + Fragen-Workflow |
| T2 | H2022 … F2019 | 40 | L-I, 15 Zeilen neu | **erledigt** – 35 Hefte sofort 100/100; 9 Korrekturen (Datum, Doppelpunkt im Badge, OCR ZiB H2021, 5 Zeichnungs-Lösungen), 6 bereinigte Ausgangslagen, 36 Anlagen |
| T3 | H2018, F2018 | 10 | L-ALT neu (`parse_imbq_alt.py`) | **erledigt** – alle zehn Hefte auf 100/100; 4 Korrekturen (Zeichnung, zwei verrutschte Formeln, doppelt gesetzte Kopfzeile), 7 Anlagen |
| T4 | H2017 … H2014 | 35 | L-ALT + OCR-Normalisierung | je Prüfung 1–2 h Sichtprüfung gegen Seitenbilder; Rechtsstand-Hinweis Pflicht |

Erst B0 (Daten auslagern) und B1 (Datenmodell) umsetzen, dann T1 – sonst
wächst `index.html` je Tranche um 1–2 MB.

### A4 – Übungsfragen und Anlagen je Tranche

- Fragen wie in PR #33/#36: je Prüfung ein Autor-Agent (nur die amtliche
  Lösung als Quelle, 4–10 Fragen, `mc` mit genau einer richtigen Option oder
  `calc` mit `ans`+`unit`, Serienfelder aus C1), je Frage ein Gegenprüfer –
  für T3/T4 zusätzlich mit dem Auftrag, Rechts- und Normstand auf heute zu
  prüfen und veraltete Fragen zu verwerfen. Quellensatz je Termin
  `scripts/pruefungen/fragen/imbq-<termin>.json`, in `REIHENFOLGE`
  (`build_exam_questions.py:23`) **hinten** anhängen (ID-Stabilität der 327
  vorhandenen `PX-`). Erwartung: 99 × 6–10 ≈ 600–1.000 neue Fragen.
- Anlagen: NTG-Hefte tragen fast immer Abbildungen (Schaltungen, Kräfte,
  Typenschilder), MIKP gelegentlich Diagramme, BWL Tabellen. Je Prüfung
  `anlagen_bau.FIGUREN` ergänzen (Heft = PDF im Scratch, Seite, Box, Titel),
  `anlagen_<termin>.py` mit `BILDER`/`BILDER_L`/`TABELLEN` (Aufgabenebene
  `"*"`, siehe B4). Erwartung: 100–150 Abbildungen – ein Grund mehr für B4
  (externe Dateien).
- Abnahme je Tranche: `parse_imbq.py <termine>` ohne Fehler (100/100 beidseitig),
  `build_imbq.py`, `build_exam_questions.py`, `build_anlagen.py`,
  `tools/sync_content.py --check` und `--validate-assets`, Headless-Browser,
  CI `build-apk` (Logs lesen).

## Teil B – Darstellung: vom Teilaufgaben-Chat zum Aufgabenblatt

### B0 – Daten aus `index.html` auslagern (Voraussetzung)

Heute stecken `KVM_QUESTIONS` (2,1 MB), `KVM_CASES` (0,6 MB) und
`KVM_ANLAGEN` (0,7 MB) als Literale in `index.html`; `tools/sync_content.py`
und die Builder patchen die Arrays per `finde_array` in die Datei. Mit 121
Prüfungen (~3 MB) und 100+ Bildern trägt das nicht mehr.

- `data/questions.json`, `data/cases.json`, `data/anlagen.json` neben
  `index.html` (GitHub Pages liefert sie mit); die App lädt sie beim Start
  mit `fetch` (relativ, ohne führenden `/`), zeigt solange einen Ladehinweis
  und setzt danach dieselben Globals (`window.KVM_QUESTIONS` …), damit die
  bestehenden IIFEs unverändert bleiben. Bilder als Dateien `anlagen/<key>.jpg`
  (B4).
- Builder (`build_imbq.py`, `build_amtlich.py`, `build_exam_questions.py`,
  `build_anlagen.py`, `build_formulas.py`) schreiben JSON-Dateien statt in
  `index.html` zu injizieren; `tools/sync_content.py` liest/schreibt die
  JSON-Dateien (`_extract_global`/`finde_array` entfallen), die Bewahrung von
  `P-`/`PX-` bleibt. `sync-content.yml` prüfen (Pfad der Content-Quelle).
- `file://`-Nutzung geht damit verloren (kein `fetch`); die Web-App wird über
  GitHub Pages genutzt, die Flutter-App bringt ihre Assets mit – akzeptiert,
  im README vermerken.
- Abnahme: `index.html` < 1 MB, Web-App lädt Fragen/Prüfungen/Bilder von
  Pages, `sync_content.py --check` grün, Test-Kopie im Headless-Chromium über
  einen lokalen HTTP-Server (`python3 -m http.server`) statt `file://`.

### B1 – Datenmodell (Build-Zeit, beide Front-Ends)

Ziel: Struktur statt Regex, Situation nur einmal, Aufgabe als Einheit. Die
**Schritt-IDs bleiben** (`…-sN`), damit gespeicherte Antworten und Punkte
weiter passen.

```jsonc
// case
{ "id": "P-BW-20251106", "f": 2, "sub": "IHK-Prüfung: …", "title": "…",
  "termin": "Herbst 2025", "amtlich": true,
  "hinweis": "",                  // z. B. "Prüfung von 2016 – Rechtsstand beachten"
  "context": "Ausgangssituation zu allen Aufgaben …",
  "aufgaben": [
    { "nr": 2, "pts": 17,
      "sit": "Für die Beschaffung eines Kunststoffgranulats …\n– Jahresbedarf …",
      "tab": { … },               // optional, gilt für alle Teile
      "bild": ["nt25-schaltung"]  // optional, gilt für alle Teile
    } ],
  "steps": [
    { "id": "P-BW-20251106-s3", "nr": 2, "teil": "c", "pts": 3,
      "q": "Ermitteln Sie die optimale Bestellmenge.",   // nur noch die Frage
      "a": "x_opt = √(2 · kB · Xges ÷ (EP · iL)) …", "amtlich": true,
      "braucht": ["a"],           // optional: baut auf a) auf
      "bild": "…", "bildL": "…", "tab": { … }, "vo": "…", "bewertung": [ … ] } ] }
```

- Builder (`build_imbq.py`, `build_amtlich.py`, `build_cases.py` für die 15
  Fallaufgaben) erzeugen `aufgaben[]` und die Felder `nr`/`teil`/`pts`; `q`
  enthält **nur die Fragestellung**. Die 15 Fallaufgaben ohne Kopf werden zu
  einer Aufgabe 1 mit Teilen a–e.
- `braucht`: Der Builder erkennt Verweise in der Fragestellung
  (`aus (Teil)?aufgabe ([a-h])\)`, `Ergebnis(se)? aus ([a-h])\)`, `unter
  ([a-h])\)`, `Ihr(e|em) (Ergebnis|Lösung) aus`) und trägt das Label ein;
  Handkorrekturen über `korrekturen_*.py`. Ein Selbsttest bricht ab, wenn ein
  verwiesenes Label in der Aufgabe fehlt.
- Kompatibilität: `splitTask`/`TaskParts` bleiben für Fremd-Content
  (Fallaufgaben aus dem Content-Branch) erhalten, werden aber nur noch
  genutzt, wenn `nr` fehlt. `taskMaxPoints(q)` liest `pts`. `tools/sync_content.py`
  bewahrt `P-`-Fälle unverändert (nur `validate_cases` um die neuen Felder
  erweitern: `aufgaben[].nr` eindeutig, jeder Schritt verweist auf eine
  vorhandene Aufgabe, `pts`-Summe je Prüfung 100).
- Exporte („Für KI kopieren", `oaExportText`, `_exportText`) bauen den Kopf
  wieder aus den Feldern zusammen; Ausgabe muss zeichengleich zur heutigen
  bleiben (Testfall: Export von `P-BW-20251106` vor/nach der Umstellung
  diffen).

### B2 – Web-App: Aufgabenblatt

Neuer Abschnitt `/* ===== Aufgabenblatt ===== */` in `index.html`, aktiv für
`state.mode === 'cases'`. `state.pool` bleibt die flache Schrittliste (Ergebnis,
Protokoll und Punkte-Logik in `finishRound` rechnen weiter darauf), die
Anzeige gruppiert nach `nr`:

1. **Kopfzeile** (sticky): „Aufgabe 2 von 7 · 17 Punkte", darunter der
   **Aufgaben-Stepper** – 7 Pillen `1 … 7` mit Zustand
   leer / teilweise beantwortet / alle beantwortet / aufgedeckt. Tippen wechselt
   die Aufgabe. Ersetzt `qCount` „Teil 4/17" und `btnPrev`. Darunter, falls
   gesetzt, der `hinweis` des Falls (Rechtsstand) als schmale Zeile.
2. **Ausgangssituation zu allen Aufgaben**: bestehendes `<details id="qCase">`,
   bei Aufgabe 1 offen, Nutzerentscheidung wird gemerkt (`state.ctxOpen`).
3. **Aufgabenkopf**: `aufgaben[].sit` als ruhiger Absatz (`.msg-sit`-Stil),
   darunter **Anlagen-Leiste**: Tabellen ausgeklappt (`tabHTML`), Abbildungen
   als Kacheln 160 px mit Bildunterschrift; Tippen → **Lightbox**
   (`<dialog class="lb">`, Bild in Originalgröße, Pinch/Scroll-Zoom über
   `touch-action: pinch-zoom` + `overflow:auto`, Schließen per ✕/Esc/Tippen
   außerhalb). Gleiche Lightbox für Bilder im Teil und für `bildL`.
4. **Teilaufgaben a–x** als Karten untereinander (`.bl-teil`): Badge `c)`,
   Punkte, Fragestellung, ggf. Teil-Tabelle/-Bild, Chip „baut auf a) auf"
   (aus `braucht`; Tippen springt zu a). Darunter das Antwortfeld – eingeklappt
   als einzeilige Vorschau („Deine Antwort … 3 Zeilen"), beim Antippen die
   bekannte `cc-input`-Textarea mit Zeichen-/Sprach-Buttons. Ein Button
   **„Lösung zu c) aufdecken"** je Karte, am Ende der Aufgabe **„Alle
   Lösungen dieser Aufgabe aufdecken"**. Aufgedeckt: eigene Antwort,
   amtlicher Lösungshinweis (+ `bildL`, VO-Bezug, Punkteverteilung),
   Punkte-Selbstbewertung `0 … max` (bestehende `oas-p`-Buttons, `opSet`),
   „Diese Aufgabe von Claude prüfen lassen" (Export der **ganzen Aufgabe**
   mit allen Teilen, nicht mehr nur des einen Teils).
   Wenn a) aufgedeckt ist und c) `braucht: ["a"]`, zeigt c) oberhalb des
   Antwortfelds „Zwischenergebnis aus a)" mit den ersten zwei Zeilen der
   Lösung von a) – ein Fehler in a) zieht sich dann nicht durch.
5. **Fußleiste**: „← Aufgabe 1" / „Aufgabe 3 →", bei der letzten Aufgabe
   „Zum Ergebnis →". Scrollposition je Aufgabe merken.
6. **Ergebnis** (`finishRound`): `taskList` nach Aufgabe gruppieren
   („Aufgabe 2 · 12/17 P", darunter a–d als schmale Zeilen); Breakdown je
   Themenbereich bleibt.
7. **Übersicht** (`mPruef`): mit 121 Prüfungen braucht die Liste Filter –
   Chips je Fach (RE/BW/MI/ZI/NT/FT/OK) und Jahr-Gruppen, nur die zwei
   neuesten Termine ausgeklappt. Je Prüfung statt des Teilaufgaben-Rasters
   eine Liste **„Aufgabe N · 17 P"** mit Chips `a b c d` (grün = beantwortet,
   gefüllt = aufgedeckt); Tippen öffnet die Aufgabe und scrollt zum Teil
   (`KVM_startCase(id, stepIdx)` bleibt die Schnittstelle, `startIdx` ist
   weiter der Schritt-Index).
8. `buildOpenChat` und die Chat-Blasen entfallen (Entscheidung des Nutzers,
   17. 9. 2026); die 15 Fallaufgaben laufen über dasselbe Aufgabenblatt (eine
   Aufgabe, fünf Teile). Erst entfernen, wenn beide Front-Ends umgestellt sind.

CSS: `.blatt`, `.bl-head`, `.bl-stepper`, `.bl-sit`, `.bl-anlagen`,
`.bl-thumb`, `.bl-teil`, `.bl-teil.done/.revealed`, `.bl-braucht`, `.lb`.
Mobil zuerst (Kacheln umbrechen, Karten volle Breite, 16 px Rand), Tokens
`--paper/--ink/--muted/--petrol` wie bisher.

### B3 – Flutter-App

- `models.dart`: `Aufgabe {nr, pts, sit, tab, bild[]}`, `CaseStudy.aufgaben`,
  `CaseStudy.hinweis`, `Question.nr/teil/pts/braucht`; `TaskParts` nur noch
  Fallback.
- Neuer `screens/aufgabenblatt_screen.dart` für `RoundMode.cases`: `PageView`
  je Aufgabe (Wischen = Aufgabe wechseln), oben Stepper (`Wrap` aus
  `ChoiceChip`s), `ListView` mit Situationskarte, Anlagen-Leiste
  (`Wrap` aus Thumbnails → `Navigator.push` auf eine Vollbild-Route mit
  `InteractiveViewer(minScale: 1, maxScale: 5)`), darunter die Teil-Karten
  (eigene `StatefulWidget` `_TeilKarte` mit `AnswerStore`, Aufdecken,
  Selbstbewertung wie in `quiz_screen.dart` heute: `_bild`, `_anlage`,
  Punkte-Buttons, Sprach-/Zeichen-Widgets aus `calc_kit.dart`).
- `QuizScreen` behält Auswahl-/Rechen-/Trainingsmodi; der `cases`-Zweig
  (Banner, „Teil i/total", `_caseBanner`) wird entfernt, sobald das Blatt
  steht. `ResultScreen` bekommt die Aufgaben-Gruppierung (Parameter
  `aufgaben` mit Punkten je Aufgabe und je Teil).
- `pruefungen_screen.dart`: Filter-Chips und Jahr-Gruppen wie im Web, Kachel
  mit Aufgaben-Zeilen + Teil-Chips; `_exportText` aus den Feldern (siehe B1).
- `flutter analyze`/`flutter test` in der CI lesen; Tests: Modell-Parsing
  (`aufgaben` ↔ `steps` konsistent, Punktsumme 100), `braucht`-Auflösung,
  Export-Text unverändert.

### B4 – Grafiken und Tabellen

- **Extern statt eingebettet.** Web: Dateien `anlagen/<key>.jpg|png` im Root
  (GitHub Pages liefert sie mit aus), `data/anlagen.json = {key: {f:
  "anlagen/nt24-ntc.png", t: "Titel", w: 780, h: 431}}` – nur noch Metadaten.
  App: `assets/anlagen/<key>.*` in `pubspec.yaml`, `anlagen.json` mit
  `{f,t,w,h}`, `DataService.anlage()` liefert den Asset-Pfad, Anzeige über
  `Image.asset`. `build_anlagen.py` schreibt beides; die Data-URI-Variante
  entfällt (alle 14 Bilder migrieren, `anlageBild()`/`Anlagenbild` verlieren
  den `data:`-Zweig nach der Migration).
- **Auflösung für den Zoom:** `anlagen_bau.py` `RENDER_DPI = 300`,
  `MAX_BREITE = 1400`, JPEG-Qualität 78 (Fotos/Schaltungen) bzw. PNG-32
  (Strichzeichnungen) – bei externen Dateien ist die Größe (150–300 KB)
  unkritisch; `w`/`h` verhindern Layout-Sprünge. Für die gescannten Hefte
  2014–2017 direkt aus dem Scan schneiden (200 dpi Vorlage, keine Vergrößerung).
- **Ort der Anlage:** gehört eine Abbildung/Tabelle zur ganzen Aufgabe
  (mehrere Teile verweisen darauf oder sie steht vor a)), liegt sie an
  `aufgaben[].bild/tab`; nur teil-spezifische Anlagen bleiben am Schritt.
  In `anlagen_imbq.py` dafür Label `"*"` in `BILDER`/`TABELLEN` erlauben
  (`(Kürzel, Jahrgang, nr, "*")`). Die heute je Label mehrfach eingetragenen
  Abbildungen wandern auf die Aufgabenebene: NTG H2025 Rampe (3 a–c) und
  Typenschild (5 a–d), NTG H2024 Stützbock (3 a/b), Flugzeug/Wind (4 a–c),
  NTC (5 a–c), Widerstandsnetz (7 a–c). Einzelne bleiben am Teil: NTG H2025
  Schaltung (6 a, einziger Teil), BWL H2025 Anlage-1-Tabelle (5 a).
- **Bezeichnung wie im Original:** Bildunterschrift = Titel aus `FIGUREN`
  („Abbildung 3 – Gemischte Schaltung", „Anlage 1 – Geschäftsfälle"), damit
  der Verweis im Fragetext und die Unterschrift übereinstimmen.
- **Tabellen:** `tab` wie bisher (`titel, kopf, zeilen, hinweis`), neu optional
  `align: ["l","r","r"]` für rechtsbündige Zahlenspalten; Web `.qtab-scroll`
  bleibt, App `_anlage()` mit horizontalem Scroll; Summenzeilen per
  `zeilen`-Eintrag mit führendem `Σ ` fett darstellen.
- **Lösungsskizzen** (`bildL`) bleiben in der Lösung, ebenfalls in der Lightbox.
- Offen aus PR #36: Anlagen der Kraftverkehr-Prüfungen `P-FT-20250507`,
  `P-OK-20221115`, `P-FT-20260506` (Lastverteilungsplan, Tabellen) – aus den
  Original-PDFs nachziehen.

## Teil C – Übungsfragen a–x als Aufgabenserien

Die 327 `PX-`-Fragen sind einzeln beantwortbar (Regel: alle nötigen Werte im
Fragetext). Was fehlt, ist der Zusammenhang: b) fragt die Folge dessen ab,
was a) berechnet hat; wer beide nacheinander sieht, versteht den Rechenweg.

### C1 – Felder im Quellensatz

Optional je Frage in `scripts/pruefungen/fragen/*.json`:

```jsonc
{ "serie": "P-BW-20251106-A2",  // Prüfung + Aufgabe, aus der die Frage stammt
  "pos": 2,                      // Reihenfolge in der Serie (1 … n)
  "ctx": "Ein Betrieb bezieht Kunststoffgranulat …" }  // eigene, knappe Ausgangslage, max. 500 Zeichen
```

- `clean_q` (`build_exam_questions.py:38`) reicht die drei Felder durch;
  Validierung: `serie` ⇒ `pos` ganzzahlig, Serie hat ≥ 2 Mitglieder mit
  lückenlosen `pos`, `ctx` innerhalb einer Serie identisch (wird nur einmal
  gespeichert und beim Build in jede Frage kopiert – 500 Zeichen × 300 Fragen
  sind vertretbar).
- Nachrüsten der vorhandenen 327 Fragen: Die Quellensätze tragen keine
  Aufgaben-Referenz mehr. Ein Skript `scripts/pruefungen/serien.py` ordnet
  jede `PX-`-Frage per Textähnlichkeit (Zahlenwerte, Schlüsselwörter der
  amtlichen Lösung) der Ursprungs-Aufgabe zu und schlägt Serien vor; Ausgabe
  wird **von Hand** in die Quellensätze übernommen (Agent prüft je Serie, ob
  die Reihenfolge a→x fachlich stimmt). Neue Sätze (Teil A) bekommen die
  Felder direkt vom Autor-Agent.

### C2 – Runden-Aufbau (Web `startRound`, App `RoundBuilder.build`)

Nach der gewichteten Auswahl in den Modi `train`, `weak`, `due`, `all`:
für jede gezogene Frage mit `serie` alle Geschwister aus dem **aktiven** Pool
holen (auch aus anderen Themenbereichen desselben Fachs), nach `pos`
sortieren und **zusammenhängend** an die Stelle der gezogenen Frage setzen.
Rundenlänge darf um höchstens 5 wachsen; danach Auswahl abschneiden. `sim`
und `retry` bleiben unverändert (Simulation soll mischen).

### C3 – Darstellung

- Serien-Banner über der Frage: bestehendes `qCase`-Element mit Tag
  **„Aufgabenserie"**, Titel „Teil 2 von 3", Inhalt `ctx` (aufklappbar, bei
  Teil 1 offen). Protokoll-Segmente der Serie bekommen eine gemeinsame
  Klammer (`.seg.serie`).
- Nach dem Beantworten von Teil 1 zeigt Teil 2 oberhalb der Frage
  „Aus Teil 1: 6 t" (das `ans`+`unit` bzw. die richtige Option von Teil 1) –
  gleiche Idee wie `braucht` im Aufgabenblatt.
- App: `QuizScreen` nutzt `caseCtx` bereits für das Banner – `CaseContext`
  um `tag` erweitern („Fallaufgabe" / „Aufgabenserie").

## Abnahme

1. Datenmodell: `tools/sync_content.py --check` und `--validate-assets` grün;
   Punktsumme je Prüfung 100 (Frage- und Lösungsseite); alle Prüfungen haben
   `aufgaben[]`; Schritt-IDs unverändert (Diff gegen `main`).
2. Exporte („Für KI kopieren") vor/nach der Umstellung zeichengleich.
3. Web (Headless-Chromium über lokalen HTTP-Server): `P-BW-20251106` öffnen →
   Aufgabe 2 zeigt vier Teile a–d, Situation einmal, Stepper mit 7 Aufgaben;
   Lightbox für `nt25-schaltung` öffnet/schließt; Antwort in c) speichern,
   Seite neu laden, Antwort da; Ergebnis nach Aufgaben gruppiert; keine
   JS-Fehler.
4. Serien: Trainingsrunde Fach 2 enthält mindestens eine Serie in richtiger
   Reihenfolge mit Banner; Rundenlänge ≤ ROUND_LEN + 5.
5. `index.html` < 1 MB nach B0/B4; Daten und Bilder laden auf GitHub Pages
   (relative Pfade).
6. CI `build-apk` grün, `flutter analyze` ohne neue Meldungen (11 bekannte
   Infos), Tests grün.
7. Nutzer-Abnahme auf dem Handy: Aufgabenblatt mit 20 Teilen (RE H2024) bleibt
   flüssig; Pinch-Zoom auf Typenschild lesbar; Prüfungsübersicht mit 121
   Prüfungen über Filter bedienbar.

## Reihenfolge und Aufwand

1. **B0 Daten auslagern** – 2–3 h (Loader, fünf Builder, `sync_content.py`,
   Workflow, README).
2. **B1 Datenmodell + Builder** (inkl. Fallaufgaben, `braucht`, `hinweis`,
   Validierung, Export-Diff) – 2–3 h.
3. **B4 Bilder externalisieren** – 1 h (14 Bilder, zwei Builder, zwei Loader).
4. **A T1** (F2024, H2023, F2023 – 14 Prüfungen, PL) – 1 Tag inkl. Fragen und
   Anlagen.
5. **B2 Web-Aufgabenblatt** – 4–6 h inkl. Lightbox, Ergebnis, Übersicht mit
   Filtern.
6. **B3 Flutter-Aufgabenblatt** – 4–6 h (ohne lokales Flutter: CI-Runden
   einplanen).
7. **A T2** (L-I, 40 Prüfungen) – 2–3 Tage in Tranchen à 10.
8. **C1–C3 Serien** – 3 h (Skript, Nachrüsten von Hand, Runden-Aufbau, Banner).
9. **A T3, T4** (L-ALT, 45 Prüfungen) – Parser ½ Tag, dann 1–2 h je Prüfung;
   T4 nur mit Sichtprüfung gegen die Seitenbilder.

Empfohlene PR-Schnitte: (1) B0+B1+B4, (2) A T1, (3) B2+B3, (4…) A T2 in
Zehnerpaketen, (n) C, (n+1…) A T3/T4.

## Risiken

- **Menge.** 99 Prüfungen sind das Vierfache des heutigen Bestands; ohne B0
  wächst `index.html` auf > 8 MB. Tranchen und PR-Schnitte einhalten.
- **OCR-Hefte 2014–2017.** Tesseract erkennt die Struktur sicher, aber
  Zahlen, Paragrafen und Umlaute nicht fehlerfrei („ı" statt „i", „8 4" statt
  „§ 4"). Jede dieser Prüfungen braucht eine Sichtprüfung gegen die
  Seitenbilder; Rechenaufgaben nachrechnen (`rechenpruefung.py`).
- **Rechtsstand** älterer Recht-/BWL-Prüfungen: Hinweis im Aufgabenkopf und
  strenger Gegenprüfer bei den Übungsfragen; im Zweifel keine `PX-`-Frage.
- **Datenmodell-Umstellung** berührt Web, App, Sync, Exporte und den
  Content-Branch gleichzeitig. Deshalb zuerst und als eigener PR, mit dem
  Export-Diff als Sicherheitsnetz.
- **ID-Stabilität**: Schritt-IDs und `PX-`-IDs dürfen sich nicht ändern
  (gespeicherte Antworten, Lernfortschritt) – Diff gegen `main` in der Abnahme.
- **Copyright** der Textlayer und Bilder im öffentlichen Repo (siehe oben).

## Entscheidungen des Nutzers

1. **Zugriff auf `Altklausuren.rar`** – erledigt (Link-Freigabe am
   17. 9. 2026; Archiv inventarisiert, Textlayer im Repo).
2. **Prüfungen ohne amtliche Lösung** – **entschieden 17. 9. 2026: wie
   empfohlen** – einspielen mit KI-Musterlösung, klar als „Musterlösung ·
   nicht amtlich" gekennzeichnet, keine `PX-`-Fragen daraus. Für dieses
   Archiv gegenstandslos (alle Hefte enthalten die amtlichen Lösungshinweise).
3. **Chat-Darstellung** – **entschieden 17. 9. 2026: wie empfohlen** – das
   Aufgabenblatt ersetzt den Teilaufgaben-Chat vollständig, auch für die 15
   Fallaufgaben (B2 Punkt 8).
4. **Copyright**: Textlayer/Bilder weiter im öffentlichen Repo oder nur
   lokal halten – **offen**.
5. **Neu – Reihenfolge der Tranchen**: neueste zuerst (T1 → T4) wie
   vorgeschlagen, oder ein bestimmtes Fach (z. B. NTG komplett) vorziehen?
   Ohne Rückmeldung gilt T1 → T4.
