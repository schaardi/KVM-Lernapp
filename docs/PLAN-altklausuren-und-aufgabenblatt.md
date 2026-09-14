# Plan: Altklausuren einspielen, Prüfungen als Aufgabenblatt, Aufgabenserien

Umsetzungsplan für die nächste Session (Stand 14. 9. 2026, nach Merge von
PR #36). Drei Themen, die zusammengehören, aber getrennt umsetzbar sind:

- **Teil A** – Das Archiv `Altklausuren.rar` vom Google Drive beschaffen,
  inventarisieren und über die bestehende Pipeline in startbare Prüfungen,
  Übungsfragen und Anlagen überführen.
- **Teil B** – Die Darstellung der Prüfungen neu schichten: statt einer
  Teilaufgabe je Bildschirm ein **Aufgabenblatt**, auf dem Aufgabe N mit
  Ausgangslage, Anlagen und **allen** Teilaufgaben a–x sichtbar ist. Grafiken
  und Tabellen bekommen dabei einen festen Platz und werden zoombar.
- **Teil C** – Die Übungsfragen (`PX-`) als **Aufgabenserien** verketten, damit
  die Lernenden beim Lösen von a) auch b) und c) kennen.

Auslöser (Nutzer, 14. 9. 2026): „Die Darstellung (auch die Grafiken)
überdenken und den Aufbau der Fragen von a–x durchdenken und neu schichten.
Manchmal ist es wichtig, auch die anderen Fragen zu kennen, um z. B. a)
richtig zu lösen."

## Ausgangslage

### Bestand in der App

| Was | Stand | Wo |
|---|---|---|
| Startbare Prüfungen (`P-`) | 22 (13 × Kraftverkehr FT/OK 2021–2026, 9 × Basisqualifikation H2024/H2025), alle mit amtlichen Lösungshinweisen, je 100 Punkte | `flutter_app/assets/data/cases.json` (560 KB), `window.KVM_CASES` in `index.html` |
| Fallaufgaben ohne IHK-Bezug | 15 (`F-`/`R-`/`M-`/`Z-`, je 4–5 Teile, Musterlösungen) | ebd. |
| Übungsfragen aus Prüfungen (`PX-`) | 327 (127 Kraftverkehr, 94 BQ H2025, 107 BQ H2024) | `questions.json`, Quellensätze `scripts/pruefungen/fragen/*.json` |
| Bildanlagen | 14 (20 Teilaufgaben mit `bild`, 6 mit `bildL`), als Data-URI | `assets/data/anlagen.json` (676 KB), `window.KVM_ANLAGEN` |
| Tabellenanlagen | 4 (`tab`) | in den Schritten |
| `index.html` | 3,3 MB – davon ~0,7 MB Bilder | Root |

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

### Das Archiv `Altklausuren.rar`

- Google Drive, Datei-ID `1REtcGsj7_pR2w0iely_zHF3mq2HFLeZP`, **201 MB**,
  `application/x-rar`, hochgeladen 14. 9. 2026 20:45 UTC, Freigabe nur für den
  Eigentümer. (Es liegt außerdem ein **leerer** Zwilling mit 0 Byte vom
  20:39 UTC im selben Ordner – ID `1D_e_iWkd6qxH2qZlSzYZYPz62juxKpqR` –, den der
  Nutzer löschen kann.)
- **In dieser Session nicht beschaffbar:** Der Drive-Connector liefert
  Dateiinhalte nur base64-kodiert in die Konversation (≈ 270 MB Text – nicht
  verarbeitbar), und ein direkter Download ohne Anmeldung liefert nur die
  Google-Anmeldeseite (geprüft mit `drive.google.com/uc?export=download` und
  `drive.usercontent.google.com/download`).
- Inhalt daher **unbekannt**. Aus der Größe (201 MB) sind eher gescannte
  Prüfungen als Word-PDFs zu erwarten (die BQ-PDFs H2024 hatten je 0,3–0,8 MB).
- Entpacken: `bsdtar` (Paket `libarchive-tools`, liest RAR 4 und 5) und
  `unrar-free` lassen sich in der Umgebung per `apt-get install` installieren
  (in dieser Session verifiziert; `deb.debian.org` ist erreichbar). Für Scans
  zusätzlich `tesseract-ocr tesseract-ocr-deu` (noch nicht installiert, Paket
  verfügbar).

## Rechtliches (bleibt eine Entscheidung des Nutzers)

Die IHK-/DIHK-Prüfungen tragen den Vermerk „Einsatz nur im Rahmen des
Korrekturprozesses gestattet. Weitergabe an unbefugte Dritte untersagt."
PDFs werden **nicht** eingecheckt. Textlayer (`scripts/pruefungen/quellen/`)
und zugeschnittene Abbildungen (`scripts/pruefungen/anlagen/`) liegen heute
im **öffentlichen** Repo; das gilt ebenso für alles, was aus dem Archiv
übernommen wird. Wer umsetzt, hält sich an diese Praxis, weist im PR aber
erneut darauf hin.

## Teil A – Altklausuren beschaffen, inventarisieren, einspielen

### A0 – Beschaffung (blockiert, Nutzer muss einen Weg wählen)

Eine der drei Möglichkeiten, in absteigender Bequemlichkeit:

1. **Freigabe „Jeder mit dem Link" (Leser)** für `Altklausuren.rar`, nur für
   die Dauer der Session. Dann im Scratchpad:
   ```bash
   curl -L -o Altklausuren.rar \
     'https://drive.usercontent.google.com/download?id=1REtcGsj7_pR2w0iely_zHF3mq2HFLeZP&export=download&confirm=t'
   file Altklausuren.rar            # muss "RAR archive" melden, nicht HTML
   mkdir alt && bsdtar -xf Altklausuren.rar -C alt
   ```
   Danach Freigabe wieder zurücknehmen.
2. **Upload der PDFs in die Session** (wie bei den H2024-PDFs) – ohne RAR,
   die Dateien landen unter `/root/.claude/uploads/<session>/`.
3. Archiv auf dem Drive in einen **Ordner entpacken** und die PDFs einzeln
   über den Drive-Connector holen. Nur für wenige, kleine Dateien sinnvoll
   (jede Datei geht base64 durch die Konversation).

Der Umsetzer darf die Freigabe **nicht selbst** setzen (`share_file`) – das
wäre eine Veröffentlichung geschützten Materials ohne Rückfrage.

### A1 – Inventar (`scripts/pruefungen/inventar.py`, neu)

Läuft über den entpackten Baum und schreibt `scripts/pruefungen/quellen/INVENTAR.md`
(Markdown-Tabelle) plus `inventar.json`. Je PDF:

- Datei, Größe, Seiten (`pdfinfo`).
- **Textlayer?** `pdftotext -l 3 -layout` → Zeichen je Seite; < 200 Zeichen/Seite
  = Scan (OCR nötig).
- **Kopf** aus den ersten zwei Seiten (Textlayer oder OCR der ersten Seite mit
  `pdftoppm -f 1 -l 1 -r 200` + `tesseract -l deu`): Fortbildung („Geprüfte/-r
  Meister/-in für Kraftverkehr", „Industriemeister"), Teil („Handlungsspezifische
  Qualifikationen" → HQ, „Basisqualifikationen" → BQ), `Handlungsbereich:` /
  Prüfungsfach, `Datum:`, `Anzahl Aufgaben:`, Vorkommen von `Lösungshinweise`.
- **Klasse**:
  - **K1** BQ mit Textlayer und Lösungshinweisen → `parse_imbq.py` (JAHRGAENGE
    erweitern; Format ist seit H2024 stabil).
  - **K2** Kraftverkehr HQ mit Textlayer und Lösungshinweisen → `parse_amtlich.py`
    (ist auf OCR-Text ausgelegt, verträgt `pdftotext -layout` nach dem
    `clean()`-Schritt – am ersten Exemplar prüfen).
  - **K3** Scan (kein Textlayer) → OCR-Weg wie in `scripts/pruefungen/README.md`
    (`pdftoppm -r 300 -gray`, `tesseract -l deu --psm 4`), danach K1/K2-Parser
    plus `korrekturen_*.py`.
  - **K4** ohne Lösungshinweise → siehe Entscheidung unten.
  - **K0** Dublette eines bereits eingespielten Termins (Bereich + Datum
    identisch mit einem `P-`-Fall) → nur als Quelle für fehlende Anlagen nutzen.
- Aus dem Kopf die **Fall-ID** ableiten: `P-<Kürzel>-<JJJJMMTT>`; Kürzel wie
  bisher `FT`, `OK`, `RE`, `BW`, `MI`, `ZI`, `NT`. Unbekannte Handlungsbereiche
  (ältere Prüfungsordnung, andere Bezeichnungen) im Inventar als „offen"
  markieren – Fach-Zuordnung und Kürzel legt der Nutzer fest, bevor eingespielt
  wird (`build_amtlich.BEREICH_FACH/BEREICH_LANG`, `SUB_ORDER` in
  `index.html`, `kSubOrder` in `constants.dart`).

Das Inventar wird als erster Commit gepusht, damit der Nutzer die Auswahl
sehen und Reihenfolge/Auslassungen bestimmen kann.

### A2 – Einspielen je Klasse

Reihenfolge: neueste Termine zuerst, innerhalb eines Termins Kraftverkehr vor
BQ. Pro Prüfung derselbe Ablauf wie in PR #36:

1. Textlayer mit Seitenmarkern (`=== Seite N ===`) unter
   `quellen/<sammlung>/`, Seiten-JPEGs (`pdftoppm -jpeg -r 100`) für die
   Sichtprüfung **nicht** einchecken (nur im Scratchpad).
2. Parser laufen lassen; **Invariante: Frageteil = Lösungsteil = 100 Punkte**,
   sonst Abbruch mit der abweichenden Aufgabe. Abweichungen (fehlende Badges,
   Symbol-Font-Zeichen, Kopfzeilen im Text, Lösungsanhänge) über
   `korrekturen_<sammlung>.py` beheben – jede Korrektur muss greifen, sonst
   bricht der Build ab.
3. `build_imbq.py` / `build_amtlich.py` → `cases.json` + `KVM_CASES`; dabei
   die **neuen Felder aus Teil B1** gleich mit erzeugen.
4. Übungsfragen: je Prüfung ein Autor-Agent (nur die amtliche Lösung als
   Quelle, 4–10 Fragen, `mc` mit genau einer richtigen Option oder `calc` mit
   `ans`+`unit`), je Frage ein Gegenprüfer; Ergebnis als
   `scripts/pruefungen/fragen/<sammlung>.json`, Datei in `REIHENFOLGE`
   (`build_exam_questions.py:23`) **hinten** anhängen (ID-Stabilität der 327
   vorhandenen `PX-`). Dabei die Serien-Felder aus Teil C1 setzen.
5. Anlagen: `anlagen_bau.FIGUREN` (Heft, Seite, Box in 100-dpi-Einheiten,
   Titel) ergänzen, `anlagen_bau.py <pdf-dir> <keys>` → `anlagen/`,
   `anlagen_<sammlung>.py` mit `BILDER`/`BILDER_L`/`TABELLEN`,
   `build_anlagen.py`. Bilder nach dem Schema aus Teil B4 (extern, nicht als
   Data-URI).
6. `tools/sync_content.py --check` und `--validate-assets` grün, Web-App im
   Headless-Chromium ohne JS-Fehler, CI `build-apk` grün (Logs lesen –
   `continue-on-error`).

### A3 – Prüfungen ohne Lösungshinweise (K4)

Empfehlung: **einspielen, aber sichtbar als „Musterlösung · nicht amtlich"**
(`amtlich: false`; das Label existiert in Web und App bereits, ebenso der
KI-Prüfauftrag „Musterlösung (zu prüfen)"). Musterlösungen erarbeitet ein
Autor-Agent je Aufgabe mit Gegenprüfer wie bei den ersten Kraftverkehr-Fällen.
**Keine `PX-`-Übungsfragen** aus K4 (die Regel „Quelle = amtliche Lösung"
bleibt). Wenn der Nutzer das nicht will: K4 auslassen, im Inventar bleibt es
dokumentiert.

### A4 – Aufwand (grobe Richtwerte je Prüfung)

| Klasse | Parser + Korrekturen | Übungsfragen (Workflow) | Anlagen |
|---|---|---|---|
| K1/K2 Textlayer | 30–60 min | 20–30 min (läuft parallel) | 10–20 min je Abbildung |
| K3 Scan/OCR | 1,5–3 h (OCR-Fehler, Tabellen) | wie oben | wie oben |
| K4 ohne Lösung | + 1 h Musterlösungen | entfällt | wie oben |

Bei > 10 Prüfungen in Tranchen von 3–5 arbeiten und jede Tranche als eigenen
PR abschließen (Reviewbarkeit, Größe von `index.html`).

## Teil B – Darstellung: vom Teilaufgaben-Chat zum Aufgabenblatt

### B1 – Datenmodell (Build-Zeit, beide Front-Ends)

Ziel: Struktur statt Regex, Situation nur einmal, Aufgabe als Einheit. Die
**Schritt-IDs bleiben** (`…-sN`), damit gespeicherte Antworten und Punkte
weiter passen.

```jsonc
// case
{ "id": "P-BW-20251106", "f": 2, "sub": "IHK-Prüfung: …", "title": "…",
  "termin": "Herbst 2025", "amtlich": true,
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
   die Aufgabe. Ersetzt `qCount` „Teil 4/17" und `btnPrev`.
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
7. **Übersicht** (`mPruef`): je Prüfung statt des Teilaufgaben-Rasters eine
   Liste **„Aufgabe N · 17 P"** mit Chips `a b c d` (grün = beantwortet,
   gefüllt = aufgedeckt); Tippen öffnet die Aufgabe und scrollt zum Teil
   (`KVM_startCase(id, stepIdx)` bleibt die Schnittstelle, `startIdx` ist
   weiter der Schritt-Index).
8. `buildOpenChat` und die Chat-Blasen entfallen für Prüfungen; die 15
   Fallaufgaben laufen über dasselbe Aufgabenblatt (eine Aufgabe, fünf Teile).
   Erst entfernen, wenn beide Front-Ends umgestellt sind.

CSS: `.blatt`, `.bl-head`, `.bl-stepper`, `.bl-sit`, `.bl-anlagen`,
`.bl-thumb`, `.bl-teil`, `.bl-teil.done/.revealed`, `.bl-braucht`, `.lb`.
Mobil zuerst (Kacheln umbrechen, Karten volle Breite, 16 px Rand), Tokens
`--paper/--ink/--muted/--petrol` wie bisher.

### B3 – Flutter-App

- `models.dart`: `Aufgabe {nr, pts, sit, tab, bild[]}`, `CaseStudy.aufgaben`,
  `Question.nr/teil/pts/braucht`; `TaskParts` nur noch Fallback.
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
- `pruefungen_screen.dart`: Kachel mit Aufgaben-Zeilen + Teil-Chips wie im
  Web; `_exportText` aus den Feldern (siehe B1).
- `flutter analyze`/`flutter test` in der CI lesen; Tests: Modell-Parsing
  (`aufgaben` ↔ `steps` konsistent, Punktsumme 100), `braucht`-Auflösung,
  Export-Text unverändert.

### B4 – Grafiken und Tabellen

- **Extern statt eingebettet.** Web: Dateien `anlagen/<key>.jpg|png` im Root
  (GitHub Pages liefert sie mit aus), `window.KVM_ANLAGEN = {key: {f:
  "anlagen/nt24-ntc.png", t: "Titel", w: 780, h: 431}}` – nur noch Metadaten;
  `index.html` verliert ~0,7 MB. App: `assets/anlagen/<key>.*` in
  `pubspec.yaml`, `anlagen.json` mit `{f,t,w,h}`, `DataService.anlage()`
  liefert den Asset-Pfad, Anzeige über `Image.asset`. `build_anlagen.py`
  schreibt beides; die Data-URI-Variante entfällt (alle 14 Bilder migrieren,
  `anlageBild()`/`Anlagenbild` verlieren den `data:`-Zweig nach der
  Migration).
- **Auflösung für den Zoom:** `anlagen_bau.py` `RENDER_DPI = 300`,
  `MAX_BREITE = 1400`, JPEG-Qualität 78 (Fotos/Schaltungen) bzw. PNG-32
  (Strichzeichnungen) – bei externen Dateien ist die Größe (150–300 KB)
  unkritisch; `w`/`h` verhindern Layout-Sprünge.
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
  Original-PDFs bzw. dem Archiv (K0) nachziehen.

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
   Punktsumme je Prüfung 100 (Frage- und Lösungsseite); alle 22 + neuen
   Prüfungen haben `aufgaben[]`; Schritt-IDs unverändert (Diff gegen `main`).
2. Exporte („Für KI kopieren") vor/nach der Umstellung zeichengleich.
3. Web (Headless-Chromium): `P-BW-20251106` öffnen → Aufgabe 2 zeigt vier
   Teile a–d, Situation einmal, Stepper mit 7 Aufgaben; Lightbox für
   `nt25-schaltung` öffnet/schließt; Antwort in c) speichern, Seite neu laden,
   Antwort da; Ergebnis nach Aufgaben gruppiert; keine JS-Fehler.
4. Serien: Trainingsrunde Fach 2 enthält mindestens eine Serie in richtiger
   Reihenfolge mit Banner; Rundenlänge ≤ ROUND_LEN + 5.
5. `index.html` < 2,7 MB nach der Bild-Externalisierung; Bilder laden auf
   GitHub Pages (relativer Pfad, keine absoluten `/`-Pfade).
6. CI `build-apk` grün, `flutter analyze` ohne neue Meldungen (11 bekannte
   Infos), Tests grün.
7. Nutzer-Abnahme auf dem Handy: Aufgabenblatt mit 20 Teilen (RE H2024) bleibt
   flüssig; Pinch-Zoom auf Typenschild lesbar.

## Reihenfolge und Aufwand

1. **B1 Datenmodell + Builder** (inkl. Fallaufgaben, `braucht`, Validierung,
   Export-Diff) – 2–3 h. Erst dann lohnt jede weitere Prüfung.
2. **B4 Bilder externalisieren** – 1 h (14 Bilder, zwei Builder, zwei Loader).
3. **B2 Web-Aufgabenblatt** – 4–6 h inkl. Lightbox, Ergebnis, Übersicht.
4. **B3 Flutter-Aufgabenblatt** – 4–6 h (ohne lokales Flutter: CI-Runden
   einplanen).
5. **A0/A1 Beschaffung + Inventar** – 1 h, sobald der Zugriff steht; Inventar
   als eigener Commit → Nutzer entscheidet Auswahl.
6. **A2 Einspielen** – je Prüfung nach Tabelle A4; in Tranchen à 3–5.
7. **C1–C3 Serien** – 3 h (Skript, Nachrüsten von Hand, Runden-Aufbau, Banner).

Empfohlene PR-Schnitte: (1) B1+B4, (2) B2+B3, (3) A1 Inventar, (4…) A2-Tranchen,
(n) C.

## Risiken

- **Archivinhalt unbekannt.** Scans mit schlechter Qualität (Tabellen,
  Formeln) sind teuer; im Inventar Tesseract-Konfidenz je Seite ausweisen und
  schwache Prüfungen zurückstellen.
- **Ältere Prüfungsordnung.** Andere Handlungsbereiche/Fächer lassen sich nicht
  1:1 auf die fünf Fächer der App legen – Entscheidung des Nutzers vor dem
  Einspielen (A1).
- **Datenmodell-Umstellung** berührt Web, App, Sync, Exporte und den
  Content-Branch gleichzeitig. Deshalb zuerst und als eigener PR, mit dem
  Export-Diff als Sicherheitsnetz.
- **ID-Stabilität**: Schritt-IDs und `PX-`-IDs dürfen sich nicht ändern
  (gespeicherte Antworten, Lernfortschritt) – Diff gegen `main` in der Abnahme.
- **Copyright** der Textlayer und Bilder im öffentlichen Repo (siehe oben).

## Entscheidungen, die der Nutzer treffen muss

1. **Zugriff auf `Altklausuren.rar`** – Link-Freigabe, Upload oder
   Einzeldateien (A0).
2. **Prüfungen ohne amtliche Lösung** – einspielen mit KI-Musterlösung
   (empfohlen, klar gekennzeichnet) oder auslassen (A3).
3. **Chat-Darstellung** der Prüfungen ganz durch das Aufgabenblatt ersetzen
   (empfohlen) oder als Option behalten (B2 Punkt 8).
4. **Copyright**: Textlayer/Bilder weiter im öffentlichen Repo oder nur
   lokal halten.
