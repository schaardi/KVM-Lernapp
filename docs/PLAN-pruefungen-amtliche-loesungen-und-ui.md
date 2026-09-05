# Plan: Amtliche IHK-Lösungshinweise für 20 Prüfungen + UI-Politur

**Für:** ausführende Claude-Session (Opus 4.7) · **Repo:** schaardi/KVM-Lernapp · **Branch:** `claude/meitner-app-build-6lnk2z`
**Stand der Analyse:** 5. September 2026 (Session `session_01PD5ddV5C1Qcpq4Q8dgm6C4`)

---

## 0. Kurzfassung

Der Nutzer hat die IHK-Prüfungssammlung *„Prüfungen Meister im Kraftverkehr – Fuhrparktechnik und
Fuhrparkmanagement komplett mit Lösungen"* (204 Seiten) bereitgestellt. Entgegen dem Dateinamen
enthält sie **beide Handlungsbereiche** – je Prüfungstermin *Situationsaufgabe/Aufgabenstellung 1 =
Fuhrparktechnik und Fuhrparkmanagement (FT)* und *2 = Organisation und Kommunikation (OK)* – und vor
allem die **amtlichen Lösungshinweise der IHK** (mit Bezug auf die Prüfungsordnung, z. B.
`[VO: § 5 Absatz 4 Nr. 6]`, teils mit Korrektor-Hinweisen und Teilpunkte-Verteilung).

Bisher hat die App **3 Prüfungen** (P-OK-20251112, P-FT-20251111, P-OK-20250508) mit **handgeschriebenen,
ausdrücklich „nicht amtlichen" Musterlösungen**. Ziel dieses Plans:

1. **20 Prüfungen (10 FT + 10 OK, Frühjahr 2021 – Frühjahr 2026, 298 Teilaufgaben) mit amtlichen
   Lösungshinweisen** in Web-App und Android-App bringen; die 3 vorhandenen Prüfungen bekommen dabei die
   amtlichen Lösungen statt der handgeschriebenen.
2. Den Lösungs-Pfad der Pipeline von „Wörterbuch `loesungen.py`" auf „aus der Quelle geparst" umstellen,
   ohne die bewährte Qualitätskontrolle (100-Punkte-Invariante, `korrekturen.py`, `rechenpruefung.py`)
   aufzugeben.
3. Einen **echten Build** für `window.KVM_CASES` in `index.html` einführen (analog `scripts/build_formulas.py`),
   damit Web und App nie mehr von Hand synchron gehalten werden müssen.
4. Das **UI polieren** (konkrete Befunde aus Screenshots, siehe Teil B) – vor allem Layout-Fehler auf dem
   Handy und ein Ergebnisbildschirm, der die neue Punkte-Selbstbewertung wirklich ausspielt.

Die Original-PDF wurde auf Wunsch des Nutzers **aus dem Repo entfernt** (sie liegt noch in der
Git-Historie, Commit `044f4ed`, 26 MB). Alles, was die Umsetzung braucht, ist im Repo gesichert
(Abschnitt 1).

---

## 1. Was im Repo bereitliegt (Quellen)

| Pfad | Inhalt |
|---|---|
| `scripts/pruefungen/quellen/ihk-pruefungen-2021-2026-mit-loesungshinweisen.ocr.txt` | OCR-Volltext aller 204 Seiten (tesseract, `deu`, 200 dpi), Seitenmarker `=== Seite N ===` |
| `scripts/pruefungen/quellen/seiten/seite-NNN.jpg` | 65 Seiten-Renderings (90 dpi, grau) der Seiten mit Diagrammen, Tabellen, Formeln, Anlagen, Titelblättern – zum Anschauen/Zuschneiden für `tab`/`bild` |
| `scripts/pruefungen/anlagen/P-FT-20251111-s3.jpg` | bereits vorhandener Lastverteilungsplan (Beispiel für `bild`) |
| `scripts/pruefungen/*.py` + `README.md` | bestehende Pipeline (parse → build → korrekturen → ki_export, rechenpruefung) |

**OCR-Qualität:** gut. Bekannte, systematische Fehler:
- `§` wird als `8` oder `$` gelesen: `[VO: 8 5 Absatz 4 Nr. 6]` → `[VO: § 5 Absatz 4 Nr. 6]`, `(8 3 Entgeltfortzahlungsgesetz)` → `(§ 3 …)`.
- Das blaue Buchstaben-Badge vor „Mögliche Punktzahl" ist unzuverlässig (`a`, `b|`, `e|`, `fa]`, `|da|`):
  **Buchstaben a/b/c aus der Reihenfolge ableiten** (macht `parse_exams.py` bereits).
- Aufzählungspunkte kommen als `=`, `= _`, `m`, `■` (bestehende `BULLET`/`clean()`-Regeln greifen).
- Im Kopf der ersten Prüfung ist „Hand-/lungsbereich:" über die Titelzeile getrennt → `BEREICH`-Regex
  **nicht am Zeilenanfang verankern** und Trennstrich zulassen.

---

## 2. Inventar der Quelle (validiert)

Zwei Layout-Epochen:

- **2021–2022:** Lösungshinweise stehen **direkt hinter jeder Aufgabe** („Aufgabe N" … „Lösungshinweise Aufgabe N").
- **ab 2023:** je Termin erst FT-Aufgaben, dann OK-Aufgaben, danach ein **Lösungsteil** mit Titelblatt
  „Frühjahr/Herbst YYYY · Lösungshinweise · Aufgabenstellung 1 · Handlungsbereich FT" und anschließend
  „Aufgabenstellung 2 · Handlungsbereich OK". Die Booklets tragen **kein Datum** – Zuordnung über
  `(Saison, Jahr, Aufgabenstellung/Bereich)` mit **Mai = Frühjahr, November = Herbst**.

| Termin | FT (Aufgabenstellung 1) | OK (Aufgabenstellung 2) | Lösungen |
|---|---|---|---|
| Frühjahr 2021 | 17. Mai 2021 · S 1–13 · 7 Aufg. · 18 Teile | 18. Mai 2021 · S 14–23 · 6 Aufg. · 17 Teile | inline |
| Herbst 2021 | 15. Nov 2021 · S 24–35 · 5 · 14 | 16. Nov 2021 · S 36–45 · 5 · 13 | inline |
| Herbst 2022 | 14. Nov 2022 · S 46–57 · 5 · 17 | 15. Nov 2022 · S 58–66 · 5 · 12 | inline |
| Frühjahr 2023 | 15. Mai 2023 · S 67–70 · 5 · 16 | 16. Mai 2023 · S 71–74 · 5 · 10 | Booklet S 75–87 |
| Herbst 2023 | 20. Nov 2023 · S 88–93 · 5 · 16 | 21. Nov 2023 · S 94–99 · 7 · 19 | Booklet S 99–111 |
| Frühjahr 2024 | 14. Mai 2024 · S 112–116 · 7 · 18 | 15. Mai 2024 · S 117–121 · 5 · 17 | Booklet S 121–126 |
| Herbst 2024 | 12. Nov 2024 · S 127–130 · 5 · 16 | 13. Nov 2024 · S 131–135 · 5 · 14 | Booklet S 136–147 |
| Frühjahr 2025 | 7. Mai 2025 · S 148–152 · 5 · 14 | 8. Mai 2025 · S 153–156 · 5 · 14 | Booklet S 157–167 |
| Herbst 2025 | 11. Nov 2025 · S 168–171 · 5 · 13 | 12. Nov 2025 · S 172–174 · 6 · 14 | Booklet S 175–185 |
| Frühjahr 2026 | 6. Mai 2026 · S 186–189 · 5 · 13 | 7. Mai 2026 · S 190–194 · 5 · 13 | Booklet S 195–204 |

Alle 20 Prüfungen ergeben im Aufgabenteil **exakt 100 Punkte** (Invariante hält). Bereits in der App:
P-FT-20251111, P-OK-20251112, P-OK-20250508 → **Lösungen ersetzen**, IDs bleiben. Der Termin Frühjahr 2022
fehlt in der Quelle. Die im README als „abgeschnitten" vermerkte Prüfung vom 18. Mai 2021 ist hier vollständig.

**Bekannte Lücken beim ersten Probelauf (Lösungsteil), die `korrekturen.py` bzw. der Parser schließen müssen:**
- 17. Mai 2021: 16 von 18 Teil-Lösungen erkannt (82 statt 100 Lösungs-Punkte) → zwei „Mögliche Punktzahl"-Zeilen im Lösungsteil (S 3–13) nicht erkannt; Seiten 5/7 sind Diagramm-/Formelseiten.
- 15. Nov 2021: 12 von 14 (83 Punkte) → S 29/33–35 prüfen (Anlage 2, Tabellen).
- 14. Nov 2022: Lösungs-Punkte 98 statt 100 → eine Punktzahl falsch gelesen.
- Booklet Frühjahr 2024 FT: 90 Punkte, Booklet Herbst 2024 FT: 15 von 16 Teilen / 94 Punkte → je eine Teil-Lösung fehlt/verschmolzen.
- Booklet-Seiten, die mit dem Text der vorherigen Aufgabe beginnen (S 99, 121, 157, 175): der Umbruch liegt **mitten auf der Seite**, nicht am Seitenanfang – Parser muss zeilenweise trennen, nicht seitenweise.

---

## 3. Teil A – Pipeline: amtliche Lösungen einbauen

### A1. Parser erweitern (`scripts/pruefungen/parse_exams.py`)

Ziel: aus dem OCR-Text **Aufgabenteil und Lösungsteil getrennt** erfassen und je Teilaufgabe die amtliche
Lösung zuordnen.

1. **Eingabe:** die eine OCR-Datei aus `quellen/` (Seitenmarker entfernen, Seitenzahlen-Zeilen `^\d{1,3}$` weiter filtern).
2. **Blockmarker (zeilenweise):**
   - Prüfungskopf: bestehende `HEADER` (`Aufgabenstellung|Situationsaufgabe N`) **nur mit** `Datum:` innerhalb der nächsten ~12 Zeilen = Aufgabenteil.
   - Booklet-Kopf: Zeile `^(Frühjahr|Herbst)\s+(\d{4})` (Titelblatt, z. B. S 75, 136, 195) = Beginn eines Lösungsteils. Der Bereich steht in den nächsten ~4 Zeilen entweder als `Handlungsbereich: …` **oder** als nackte Zeile `Fuhrparktechnik und Fuhrparkmanagement` / `Organisation und Kommunikation` (2023 ohne „Aufgabenstellung N", ab 2024 mit). Innerhalb eines Lösungsteils wechselt der Bereich bei der nächsten `Aufgabenstellung 2`/`Handlungsbereich: Organisation…`-Zeile (z. B. S 106, 142). Merke `(saison, jahr, bereich)`; `Datum:` fehlt hier immer.
   - Innerhalb: `^Aufgabe N$` = Aufgabe; `^Lösungshinweise Aufgabe N` = Lösung zu Aufgabe N; `Mögliche Punktzahl: N` = Teilaufgabe (bestehende `PUNKTE`, Präfix bis 8 Zeichen).
   - `BEREICH` unverankert, Trennstrich tolerieren: `Hand-?\s*lungsbereich:?\s*(Fuhrparktechnik[^\n]*|Organisation[^\n]*)`.
3. **Zuordnung Lösung → Prüfung:**
   - 2021–2022: Lösung folgt der Aufgabe im selben Prüfungsblock (Aufgabennummer gleich).
   - ab 2023: Booklet `(saison, jahr, bereich)` → Prüfung mit `Datum` im Monat *Mai* (Frühjahr) bzw. *November* (Herbst) desselben Jahres und gleichem Bereich. Assertion: genau eine Prüfung passt.
4. **Teil-Lösungen:** im Lösungsblock jeder Aufgabe die Abschnitte zwischen den `Mögliche Punktzahl`-Zeilen; Reihenfolge = a, b, c … Zusätzlich extrahieren:
   - `vo`: Zeile(n) `[VO: … ]` (nach `§`-Korrektur), optional mehrzeilig.
   - `bewertung`: Teilpunkt-Angaben `(\d+) Punkte\)` in Klammern am Zeilenende sowie „Hinweise für den Korrektor:"-Absätze → als Liste `["4 P: Berechnung", "2 P: Beurteilung"]` oder Freitext. (Wird im UI als Bewertungsschema neben der Punkte-Auswahl gezeigt, Teil B4.)
5. **Ausgabe `exams.json`:** wie bisher, plus je Teilaufgabe `loesung` (Absätze), `vo`, `bewertung`, und je Prüfung `saison`.
6. **Validierung (harte Fehler):** je Prüfung Aufgaben-Punkte = 100 **und** Lösungs-Punkte = 100 **und** Anzahl Teil-Lösungen = Anzahl Teilaufgaben **und** `Anzahl Aufgaben:` = gefundene Aufgaben. Ausgabe einer Tabelle wie in Abschnitt 2. Erst wenn alle 20 grün sind, weiter.

### A2. Korrekturen (`scripts/pruefungen/korrekturen.py`)

- Neue globale Ersetzungen (vor dem Parsen): `\[VO:\s*[8$]\s*5` → `[VO: § 5`; `\(\s*[8$]\s*(\d+)\s` → `(§ \1 ` nur in Lösungstexten; `= _` / `=` Aufzählungen → `– `.
- Je Lücke aus Abschnitt 2 eine explizite Korrektur „alt → neu" (bestehendes Prinzip: greift sie nicht mehr, bricht der Lauf ab).
- Tabellen als `tab` (Anlagen, Kostentabellen, Nutzwert, Beschäftigungsgrad – Seiten 9, 11, 12, 34, 61, 63, 129, 152–154, 164, 170, 177–178 als Kandidaten), Diagramme/Formeln als `bild` (Seiten 5–7 Geschwindigkeits-Zeit-Diagramm, Lastverteilungspläne u. ä.): aus `quellen/seiten/*.jpg` zuschneiden (`pdftoppm` gibt es nicht mehr – die 90-dpi-Renderings reichen fürs Handy; falls höhere Auflösung nötig, PDF beim Nutzer anfragen). Ablage wie bisher in `anlagen/`, Verdrahtung über `BILDER`/`TABELLEN`.
- Wo die Lösung selbst eine Tabelle ist (z. B. S 12 Beschäftigungsgrad-Tabelle, S 100 Kräfte-Rechnung), die Lösung als Markdown-ähnliche Zeilen `Spalte | Spalte` erhalten – der Chat zeigt Text; ein `tab` an der Lösung ist optional (Modell erweitern: `a_tab`).

### A3. Fallaufgaben bauen (`scripts/pruefungen/build_cases.py`)

- Lösung aus `teil['loesung']` nehmen; `LOESUNGEN`-Wörterbuch nur noch als **Override** (falls eine amtliche Lösung unbrauchbar/unvollständig ist). Prüfungen, denen Teil-Lösungen fehlen, weiterhin auslassen.
- Kontext-Fußzeile ändern: „… Lösungshinweise: **amtlich (IHK)**." statt „nicht amtlich". Neues Feld je Fall `amtlich: true`.
- Je Schritt zusätzlich: `vo` (String), `bewertung` (Liste/String), damit App und Web sie zeigen können. `e` (Merksatz) entfällt bei amtlichen Lösungen oder wird aus dem Korrektor-Hinweis gespeist.
- `title` bleibt `IHK-Prüfung <Bereich> – <Datum>`; **zusätzlich** `termin: "Frühjahr 2025"` für die Gruppierung im Picker.
- `rechenpruefung.py` auf die neuen Prüfungen ausdehnen (mindestens: alle Rechenaufgaben, deren Lösungshinweis Zahlenwerte enthält – Kosten je km, Deckungsbeitrag, Sicherungskräfte, Bremsweg/Zeit, Lagerkennzahlen).

### A4. Ein Build für Web und App (neu: `scripts/pruefungen/build_web_cases.py`)

Analog zu `scripts/build_formulas.py`:
- Liest `faelle.json` (Pipeline-Ausgabe) und `index.html`, ersetzt in `window.KVM_CASES = [...]` **nur die Einträge mit `id` ^P-** (alle Nicht-Prüfungsfälle bleiben, sie kommen aus dem Content-Branch), schreibt kompakt zurück.
- Schreibt dieselben P-Fälle in `flutter_app/assets/data/cases.json` (Nicht-P-Fälle unverändert lassen). `tools/sync_content.py` bewahrt P-Fälle bereits (`preserve_local_cases`) – **nicht anfassen**.
- Gegenprobe wie beim Formelbuch: Web-Array und App-JSON per Node/Python parsen und vergleichen; Ausgabe „N Prüfungen synchronisiert".
- README der Pipeline aktualisieren (Ablauf, amtliche Lösungen, Build).

### A5. KI-Export anpassen

- `scripts/pruefungen/ki_export.py`, Web (`index.html`, Funktion `exportText`, ca. Zeile 3025 ff.) und Android (`answer_store.dart` `exportTask`, `pruefungen_screen.dart`): Prüfauftrag umformulieren – die Lösung ist **amtlicher IHK-Lösungshinweis**; die KI soll die *eigene Antwort* des Nutzers **gegen den Lösungshinweis bewerten und Punkte vorschlagen** (nicht mehr die Musterlösung „prüfen"). VO-Bezug und Bewertungsschema mit exportieren.

**Akzeptanz Teil A:** 20 Prüfungen in `cases.json` und `KVM_CASES`, jede 100 Punkte, alle Teilaufgaben mit amtlicher Lösung; `rechenpruefung.py` grün; `python3 tools/sync_content.py --check` meldet 20 bewahrte P-Fälle; Web (Headless-Chromium, siehe Abschnitt 5) startet jede Prüfung über `window.KVM_startCase(id)`; CI `build-apk` grün.

---

## 4. Teil B – UI-Politur (Befunde aus Screenshots, 430 px Breite)

Screens liegen nicht im Repo; die Befunde sind konkret genug zum Nachstellen (Headless-Chromium, Abschnitt 5).

| # | Befund | Fix | Wo |
|---|---|---|---|
| B1 | Startseite: Titel „INDUSTRIEMEISTER BASISQUALIFIKATION**EN**" bricht mitten im Wort um; Branding ist generisch/veraltet – die App ist der **Meister-für-Kraftverkehr**-Trainer | Titel kürzen („KVM-Trainer" / „Meister für Kraftverkehr"), `hyphens: manual`, kleinere Display-Größe unter 480 px; Untertitel mit Fächern behalten | `index.html` `.mast` (~Z. 594–600), Android `home_screen` |
| B2 | Feste Werkzeugleiste unten (4 grelle Farben) **überdeckt** die Hauptaktion („Weiter →", Feedback) und Chat-Inhalte | Inhalt bekommt `padding-bottom: calc(Leistenhöhe + env(safe-area-inset-bottom))`; Leiste einfarbig (Petrol) mit Icon+Label, dezenter Schatten; optional bei Scroll nach unten ausblenden | `index.html` `.toolbar`/`.qactions`, `#scrQuiz` |
| B3 | Ergebnis: Titel „PRÜFUNGSERGEBN…" wird abgeschnitten; Ring + Titel nebeneinander passen nicht | Unter 480 px stapeln (Ring oben, Titel darunter), `overflow-wrap`, Titel eine Stufe kleiner | `index.html` `.res-head`, `#resTitle` |
| B4 | Ergebnis ist bei Prüfungen leer unter der Kopfzeile – die neue **Punkte-Selbstbewertung** wird nicht ausgespielt | **Aufgabenliste je Prüfung**: „Aufgabe 1 a) · 4/6 P" mit Mini-Balken, Summe je Aufgabe, Tippen öffnet die Aufgabe (Chat mit Lösung) zum Nachlesen; gleiche Liste in Android `ResultScreen` | Web `finishRound`/`#breakdown`, Android `result_screen.dart` (Daten: `opGet`/`AnswerStore.points`) |
| B5 | Prüfungs-Chat: Ausgangssituation (lange Wand) bei jedem der ~14 Schritte aufgeklappt | `<details>` nur bei Schritt 1 offen, danach zu (Zustand merken); im Prüfer-Kopf „Anlage/Ausgangssituation ▸" | `index.html` `renderQuestion` (`caseEl`), Android `_caseBanner` |
| B6 | Punkte-Auswahl: Nutzer weiß nicht, wofür es Punkte gibt | Unter der Auswahl das **Bewertungsschema** aus der amtlichen Lösung zeigen („4 P Rechnung · 2 P Beurteilung", VO-Bezug klein) – Daten aus A1/A3 | Web `buildOpenChat`, Android `_scoreSelector` |
| B7 | Prüfungs-Picker: mit 20 Prüfungen wird die flache Liste je Bereich lang | Gruppieren nach **Termin** (Frühjahr/Herbst YYYY), pro Karte: Bereich, Datum, Aufgaben/Punkte, Badge „amtliche Lösung", eigener letzter Stand (Punkte %) | Web `#mPruef` (Z. ~3003 ff.), Android `pruefungen_screen.dart` |
| B8 | Formelbuch: 118 Formeln als eine lange Liste | Gruppen einklappbar mit klebrigem Gruppenkopf, Sprung-Chips oben, Suchfeld bleibt | Web `#mFormula`, Android `formula_book.dart` |
| B9 | Rechner/Formelbuch überlagern sich (gewollt), aber der Rechner hat keinen „Ergebnis in Antwort übernehmen"-Weg | Knopf „→ in Antwort einfügen" (fügt Ergebnis ans Ende von `#oaInput`/Composer) | Web Rechner-IIFE, Android `CalculatorSheet` |
| B10 | Kleinigkeiten | Fußnote unter dem Quiz („Übungsfragen eigenständig formuliert …") nur auf der Startseite; MC-Feedback-Box Abstand zur Leiste (siehe B2); Fokus-Ring auf Buttons für Tastatur; Dark-Mode via `prefers-color-scheme` **optional** (Token existieren als CSS-Variablen) | |

Design-Leitplanken (beibehalten): Petrol/Amber-Palette, Barlow Condensed für Display, Mono für Labels;
keine neue Farbfamilie einführen; Touch-Ziele ≥ 44 px; `touch-action: manipulation` bleibt.

**Akzeptanz Teil B:** Screenshots (430 × 900) von Start, Auswahlfrage, Feedback, Prüfungs-Chat vor/nach
Abgabe, Ergebnis, Picker, Formelbuch – ohne abgeschnittene Titel, ohne überdeckte Aktionen; Android
`build-apk` grün; die Ergebnisliste zeigt die selbst vergebenen Punkte je Aufgabe.

---

## 5. Arbeitsweise, Werkzeuge, Reihenfolge

- **Web testen ohne Netz:** Kopie von `index.html` ohne Google-Fonts-`<link>` und Supabase-`<script>` (beide blockieren sonst das Laden), dann Chromium `/opt/pw-browsers/chromium-1194/chrome-linux/chrome --headless=new --remote-debugging-port=…` über CDP (Node 22 hat `WebSocket`; `Runtime.evaluate`, `Page.captureScreenshot`). `window.KVM_startCase(id)` startet eine Prüfung gezielt. Vorlage: das Vorgehen aus dieser Session (CDP-Skript mit `oaInput`/`oaSend`/`oaScore`/`btnScoreNext`).
- **Dart:** kein lokales Toolchain – Kompilierung nur über CI `build-apk` (Workflow `android-build.yml`, ~8 min). Vor dem Push Dart-Änderungen gegen die bewährte Web-Logik spiegeln.
- **Sync-Vorsicht:** Der nächtliche Content-Sync (`sync-content.yml`, 04:00 UTC) überschreibt `cases.json` aus dem Content-Branch; P-Fälle werden bewahrt. Keine P-Fälle in den Content-Branch schreiben.
- **Git:** Branch `claude/meitner-app-build-6lnk2z`, Draft-PR, Commits mit Session-Trailer. PR #30 ist gemergt – vor Beginn `git fetch origin main && git checkout -B claude/meitner-app-build-6lnk2z origin/main`.

**Reihenfolge / grobe Größenordnung**
1. A1 Parser + Pairing + Validierungstabelle (alle 20 grün) – größter Brocken.
2. A2 Korrekturen, Tabellen/Bilder für die Rechenaufgaben (zuerst die 3 vorhandenen Prüfungen, dann die neuen).
3. A3 + A4 Build, Web/App befüllen, `rechenpruefung.py` erweitern, A5 KI-Export-Text.
4. B2, B3, B1 (Layout-Fehler) → B4, B6 (Ergebnis + Bewertungsschema) → B5, B7 → B8, B9, B10.
5. Screenshots + CI, PR-Beschreibung mit Vorher/Nachher.

**Risiken:** OCR-Lücken im Lösungsteil (Abschnitt 2) kosten Handarbeit – nicht raten, sondern die
Seiten-JPEGs ansehen; Tabellen in Lösungen sind als Text mehrdeutig; Urheberrecht: Prüfungsinhalte sind
IHK-Material – wie bisher als Lernmaterial mit Quellenangabe, keine Weitergabe der Roh-PDF.
