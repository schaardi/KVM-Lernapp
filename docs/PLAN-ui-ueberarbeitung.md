# Plan: UI-Überarbeitung – Arbeitsplatz statt Fenster über Fenster

Stand 20. 9. 2026. Dieser Plan ist für eine **Opus-Sitzung** geschrieben, die
ihn umsetzt. Er beschreibt, was die Lernenden stört, wie die Oberfläche heute
gebaut ist (mit Zeilenangaben), welche Arbeitspakete in welcher Reihenfolge
anstehen, woran jedes Paket abgenommen wird und welche Regeln beim Bauen
gelten. Inhalte, Datenmodell und Pipeline bleiben unangetastet – es geht nur
um die Darstellung in Web (`index.html`) und App (`flutter_app/`).

## 1. Auslöser

Der Nutzer löst Original-IHK-Aufgaben auf dem Aufgabenblatt und braucht dabei
Aufgabentext, Anlagen, Antwortfeld und ein Werkzeug (Rechner, Rechenblatt,
Formelbuch) **gleichzeitig**. Genau das leistet die Oberfläche nicht:

- „Das Kernproblem ist, dass ich die Werte nicht lesen kann, wenn ich das
  Formelblatt geöffnet habe." (19. 9. 2026)
- „Die Formeln sind in Textform nur vorhanden, hätte ganz gerne in der
  Lösungseingabe das Formular. Ansonsten gerne auch die Formel herauslösen,
  dass ich die daneben rechnen und einfügen kann." (19. 9. 2026)
- „Ich möchte die Formeln in der Lösungseingabe ausfüllen (also übernehmen und
  dort ausfüllen, damit ich die Werte aus der Frage habe)." (18. 9. 2026)
- „da kann ich nichts eintragen" – Tabellenanlage ohne Eingabefelder
  (17. 9. 2026, inzwischen behoben, Muster für weitere Anlagen).
- „Dat schaut nicht gut aus." – Screenshot vom 19. 9. 2026: das Formelbuch als
  Seitenpanel lag hinter der Werkzeugleiste, die Formelkarten waren rechts
  abgeschnitten, die Inhaltsspalte war auf Restbreite gequetscht.

Die Zwischenlösungen der letzten Tage (Formelbuch als Seitenschublade,
„Vorlage ins Antwortfeld", ausfüllbare Tabellen) sind Notbehelfe im alten
Fenstersystem. Dieser Plan ersetzt das Fenstersystem.

## 2. Leitbild

**Ein Arbeitsplatz, keine Fenster über Fenstern.** Beim Lösen einer Aufgabe
sind vier Dinge gleichzeitig sichtbar und bedienbar:

1. der Aufgabentext mit seinen Zahlen,
2. die Anlagen (Tabellen, Abbildungen) – ausfüllbar, zoombar,
3. das Antwortfeld der gerade bearbeiteten Teilaufgabe,
4. genau **ein** Werkzeug: Rechner, Rechenblatt oder Formelbuch.

Daraus folgen fünf Regeln:

- **Werkzeuge verdecken nie die Aufgabe.** Ab 1024 px Breite docken sie als
  Panel rechts an, die Inhaltsspalte rückt zusammen. Darunter liegen sie als
  Bottom-Sheet mit zwei Rasthöhen (etwa 45 % und 90 % der Bildschirmhöhe),
  die Aufgabe bleibt darüber scrollbar.
- **Ein Werkzeugpanel mit drei Reitern** (Rechner · Rechenblatt · Formelbuch)
  statt drei Fenstertypen (frei schwebender Rechner, Modal-Rechenblatt,
  Schubladen-Formelbuch). Die Werkzeugleiste wird zur Reiterleiste des Panels.
- **Werte wandern, nicht die Augen.** Aus dem Werkzeug in das Antwortfeld
  (Formelvorlage, Rechnerergebnis) und aus der Aufgabe in das Werkzeug
  (Zahlen im Aufgabentext sind anklickbar und landen im Rechner).
- **Ein Bausatz für alles.** Aufgabenblatt, Einzelfrage und Ergebnis nutzen
  dieselben Bausteine (Aufgabenkopf, Anlagenblock, Antwortfeld mit
  Werkzeugzeile, Aufdeck-Knopf). Web und App sehen gleich aus und heißen
  gleich: „Rechner", „Rechenblatt", „Formelbuch", „Aufgabenblatt".
- **Drei Breiten, eine Skala.** Handy (bis 600 px), Tablet (601–1023 px),
  Desktop (ab 1024 px). Abstände in 4-px-Schritten (4/8/12/16/24/32), Radien
  8/14, eine Schriftskala. Die heutigen acht Breakpoints entfallen.

## 3. Ist-Zustand (Befund vom 20. 9. 2026)

### 3.1 Web (`index.html`, 330 KB, 4 372 Zeilen)

- **Aufbau.** Stylesheet inline in den Zeilen 13–786 (774 Zeilen). Daten
  kommen aus `data/questions.js`, `data/cases.js`, `data/anlagen.js`
  (Zeilen 1088–1090). Danach **sechs getrennte `<script>`-Blöcke** (Zeilen
  1091, 2486, 2867, 3015, 3214, 3380) mit jeweils eigenem Funktionsraum;
  Aufrufe über Blockgrenzen laufen ausschließlich über Brücken auf `window`
  (`KVM_startCase`, `KVM_tabText`, `KVM_anlageTitel`, `KVM_hasAnswer`,
  `KVM_formel`, `KVM_blattAntwort`). Es gibt **zwei** Funktionen namens
  `close()` (Zeilen 2503 und 4357) in verschiedenen Blöcken.
- **Bildschirme.** Vier `.card`-Container `scrHome` (Zeile 791), `scrQuiz`
  (886), `scrBlatt` (938), `scrResult` (956); `show(id)` (2401) blendet über
  `hidden` um. Inhaltsspalte `.app{max-width:820px;margin:0 auto}` (27),
  `body` mit `padding:20px 16px 96px`, ab 561 px seitlich 64 px.
- **Werkzeuge – drei Fenstertypen.**
  - Rechner `#mCalc` als `.floatwin` (Zeile 992; CSS 435): frei ziehbar,
    `z-index:70`, `openCalc/closeCalc` (2508 f.).
  - Rechenblatt `#mPad` als `.modal` mit `.backdrop` (1002; CSS 387/410):
    sperrt die Seite, Aufgabe unsichtbar.
  - Formelbuch `#mFormula` (1076): Sonderfall im Modalsystem – `open()`
    setzt `body.has-formel` (2498), CSS 390–408 macht daraus eine
    Seitenschublade (Breite `min(420px,45vw)`, Seitenränder der `.app`
    werden verschoben); unter 820 px ein Bottom-Sheet mit 80 % Höhe, dabei
    wird die Werkzeugleiste ausgeblendet (408).
  - Werkzeugleiste `#toolbar` (984; CSS 347) fest unten rechts mit vier
    Knöpfen `tbCalc`, `tbPad`, `tbFormula`, `tbVoice`; unter 560 px eine
    Leiste über die volle Breite (382 f.).
- **Weitere Modale.** `mADR` (1026), `mPruef` (1051), `mKW` (1060) – Dialoge,
  die bleiben dürfen (kurz, blockierend gewollt).
- **Breakpoints.** `max-width` 380/520/560/820/1199 und `min-width`
  561/640/720 – acht Schwellen ohne gemeinsames Raster.
- **Aufgabenblatt** (`renderBlatt` 2090, `blTeilHTML` 2060, `blLoesungHTML`
  2023, `blAnlagenHTML` 1994): Stepper `blStepper`, Hinweis, Ausgangslage
  als `<details id="blCase">`, darunter Teil-Karten mit Antwortfeld,
  Aufdecken, Selbstbewertung; Anlagen einmal am Kopf. Wenn die Ausgangslage
  lang ist, scrollt sie beim Antworten aus dem Bild – dann fehlen die Werte.
- **Einzelfrage** (`renderQuestion` 1726): `qCase` (Ausgangslage), `qHead`
  (Aufgabenleiste), `qSit`/`qText`, `qTab`, `qOpts`, `qOpen` (Chat-Modus
  mit `oaInput`), `qCalc` (Zahlenantwort), `qFeedback`. Eigene Bausteine,
  die nicht mit denen des Aufgabenblatts geteilt werden.
- **Was schon trägt.** Ausfüllbare Tabellen (`kvm_open_tabs`, `tabHTML`,
  `otSet`), Lösungstabellen `tabL`, „Vorlage ins Antwortfeld"
  (`fbUebernahme`, `ksText`, `fxText`, `blAntwortAnhaengen`), Lightbox mit
  Zoom, Antwortspeicher `kvm_open_answers`. Diese Funktionen bleiben und
  werden in den neuen Bausatz eingehängt.

### 3.2 App (`flutter_app/lib/`)

- **Werkzeuge** nur als `showModalBottomSheet`: auf der Startseite alle drei
  (`home_screen.dart:87` `_openTool`), im Quiz Rechner und Rechenblatt
  (`quiz_screen.dart`, `_openRechner`/`_openRechenblatt`), aber **kein
  Formelbuch**; auf dem **Aufgabenblatt gar keine Werkzeuge**
  (`aufgabenblatt_screen.dart`, kein Aufruf von `CalculatorSheet`,
  `DrawingPad` oder `FormulaBook`).
- **Bausteine** vorhanden: `widgets/calculator.dart` (183 Zeilen),
  `drawing_pad.dart` (112), `formula_book.dart` (497, mit „Als Vorlage"
  → Zwischenablage), `anlage_tabelle.dart`, `anlage_bild.dart`,
  `calc_kit.dart` (`parseDe`, `fmtNum`). Antwortspeicher
  `services/answer_store.dart` (`kvm_open_answers`, `kvm_open_tabs`).
- **Theme** in `main.dart` (`ColorScheme.fromSeed(seedColor: kPetrol)`,
  Card/Chip/Button-Themes) – gute Basis, aber Abstände und Schriftgrößen
  liegen verstreut in den Screens (`aufgabenblatt_screen.dart` 842 Zeilen,
  `quiz_screen.dart` 1 024, `home_screen.dart` 773).
- Ein Modal-Bottom-Sheet **verdeckt** die Aufgabe genauso wie im Web das
  Modal – dasselbe Kernproblem.

## 4. Arbeitspakete

Reihenfolge ist Abhängigkeitsreihenfolge. U1 und U2 sind der Kern und lösen
das Kernproblem; U0 macht sie handhabbar. Jedes Paket ist ein eigener Commit
(gern mehrere), jedes hat Abnahmekriterien, die per Headless-Prüfung
(Abschnitt 6) oder Flutter-CI nachweisbar sind.

### U0 – Stylesheet und Gestaltungs-Tokens auslagern

- `index.html` Zeilen 13–786 nach `app.css` verschieben, per
  `<link rel="stylesheet" href="app.css">` laden (die Seite lädt bereits
  `data/*.js` relativ, ein weiterer Pfad ändert nichts am Deployment).
- Tokens in `:root` konsolidieren: Farben (bestehend `--steel --paper --ink
  --muted --petrol --petrol-deep --petrol-soft --amber --amber-soft --line
  --line-strong --shadow`), dazu Abstände `--s1…--s6` (4…32 px), Radien
  `--r-s: 8px`, `--r-m: 14px`, Schriftskala `--t-xs…--t-xl`, Panelbreite
  `--panel-w`, Breakpoints als Kommentar (CSS kennt keine Variablen in
  Media-Queries – alle Media-Queries auf die drei Schwellen 600/1024
  umstellen).
- Keine sichtbare Änderung. **Abnahme:** Screenshot-Vergleich Home, Quiz,
  Aufgabenblatt bei 1280 und 500 px vor/nach (Headless, `Page.captureScreenshot`
  ergänzen oder DOM-Maße vergleichen); `tools/sync_content.py --check` grün.

### U1 – Werkzeugpanel (Web)

Ein Panel `#werkzeug` ersetzt `.floatwin #mCalc`, `.modal #mPad` und die
Schubladen-Sonderbehandlung von `#mFormula`.

- **Struktur.** `#werkzeug` mit Reiterleiste (Rechner · Rechenblatt ·
  Formelbuch · Sprache bleibt als Umschalter außerhalb der Reiter) und einem
  Körper, in dem die drei bestehenden Inhalte liegen. Die **inneren IDs
  bleiben** (`calcExpr`, `calcRes`, `calcGrid`, das Rechenblatt-Canvas,
  `mFormula`-Innenleben mit `fbRender`, `FBVALS`), damit die Skriptblöcke
  unverändert weiterlaufen. Die alten Container `mCalc`/`mPad`/`mFormula`
  dürfen als Hüllen bestehen bleiben, wenn das Umhängen der Inhalte per
  `appendChild` zur Laufzeit geschieht – bevorzugt aber direkt im Markup.
- **Desktop (≥ 1024 px).** Panel rechts angedockt, `position:sticky`/
  `fixed` über volle Höhe, Breite `--panel-w` (Standard 400 px, ziehbar
  340–560 px, gemerkt in `localStorage kvm_ui_panel`). Die `.app`-Spalte
  bekommt `margin-right: var(--panel-w) + 24px` nur mit `body.has-panel`;
  keine Überlappung, keine horizontale Scrollleiste.
- **Tablet/Handy (< 1024 px).** Bottom-Sheet mit Griff; zwei Rasthöhen
  45 % und 90 %, Wischen oder Griff-Tipp wechselt; Standard 45 %, damit die
  Aufgabe sichtbar bleibt. Die Reiterleiste ist Teil des Sheets, die
  bisherige `#toolbar` verschwindet (bleibt nur als zugeklappter
  Reiterstreifen unten). Kein `backdrop`, die Seite scrollt weiter.
- **Zustand.** `state.panel = {offen, reiter, breite, hoehe}`; `open()`/
  `close()` (2494–2504) rufen für die drei Werkzeuge nur noch
  `KVM_panel(reiter)`. Das Panel bleibt beim Bildschirmwechsel
  `scrQuiz ↔ scrBlatt` offen, auf `scrHome` und `scrResult` zugeklappt.
- **Tastatur.** Esc klappt zu, Tab-Reihenfolge Aufgabe → Panel → Aufgabe;
  Rechner-Tastaturbedienung (Ziffern, Enter, ⌫) bleibt, sofern das Panel
  den Fokus hat und kein Antwortfeld aktiv ist.
- **Abnahme** (Headless, `tools/headless/beispiele/panel-desktop.js` und
  `panel-handy.js` an das neue Markup anpassen):
  - 1280×900: `app_ueberlappt_panel=false`, `karten_abgeschnitten=0`,
    `seite_scrollt_horizontal=false`, Reiterwechsel ohne JS-Fehler.
  - 500×757: Sheet-Anteil ≤ 50 % nach Öffnen, `aufgabe_sichtbar_px ≥ 300`,
    kein horizontales Scrollen, keine Werkzeugleiste auf dem Sheet.
  - Rechnerergebnis per Knopf „Ins Antwortfeld" landet im aktiven Feld
    (`blAntwortAnhaengen`), Formelvorlage weiterhin über
    `KVM_blattAntwort`.

### U2 – Aufgabenblatt als Arbeitsplatz

- **Klebender Aufgabenkopf.** Fach, Aufgabe N, Punkte, Stepper und der Knopf
  „Ausgangslage" bleiben beim Scrollen oben (`position:sticky`). Der Knopf
  öffnet die Ausgangslage samt Anlagen als **Einblendung unter dem Kopf**
  (kein Modal), sodass Werte und Antwortfeld gleichzeitig sichtbar sind;
  ab 1024 px alternativ als linke Randspalte, wenn Panel und Inhaltsspalte
  zusammen noch ≥ 1 360 px Platz haben.
- **Wertezeile.** Aus Ausgangslage und Teilaufgabentext werden Zahlen mit
  Einheit erkannt (`28.800 €`, `1.250 kg`, `35 %`, `4,5 h`) und als Chips
  unter dem Text gezeigt; Tipp kopiert die Zahl in den Rechner (aktiver
  Reiter) oder ans Antwortfeld. Erkennung als reine Darstellung, keine
  Datenänderung; Regex in einer Funktion `werteAusText(txt)` mit Tests im
  Headless-Skript (mindestens die vier Beispielformen).
- **Antwortfeld mit Werkzeugzeile.** Über jedem Antwortfeld eine Zeile:
  „Formelvorlage", „Rechnerergebnis", „Tabelle prüfen" (wenn ausfüllbare
  Tabelle), rechts „Aufdecken". Die Zeile ist ein gemeinsamer Baustein
  (`antwortfeldHTML(q, opt)`), den U3 wiederverwendet.
- **Anlagen.** Tabellen ausfüllbar wie heute; Abbildungen mit Zoom; bei
  mehreren Anlagen eine Reiterleiste „Anlage 1 · Anlage 2" statt
  Untereinander. Lösungstabellen `tabL` neben der eigenen Eingabe
  (zweispaltig ab 1024 px, sonst untereinander) nach dem Aufdecken.
- **Abnahme:** Headless mit `P-BW-20201103` Aufgabe 5 und 6 (BAB und
  Maschinenstundensatz), `P-BW-20181106` Aufgabe 6, `P-NT-20241106`
  Aufgabe 5 (Abbildung): Kopf bleibt bei `scrollTo(0, 2000)` sichtbar
  (`getBoundingClientRect().top ≥ 0`), Ausgangslage-Einblendung überdeckt
  das Antwortfeld nicht, `werteAusText` findet in Aufgabe 5 mindestens die
  Beträge des BAB, Eingabe in Tabelle und Antwortfeld landen in
  `kvm_open_tabs`/`kvm_open_answers` (Beispiel `tabelle-ausfuellen.js`).

### U3 – Einzelfrage und Ergebnis auf den Bausatz umstellen

- `scrQuiz` nutzt Aufgabenkopf, Anlagenblock und `antwortfeldHTML` aus U2;
  `qOpen` (Chat-Modus) behält seine Logik, bekommt aber dieselbe
  Werkzeugzeile; `qCalc` (Zahlenantwort) zeigt die Einheit im Feld und
  nimmt „Rechnerergebnis" entgegen.
- `scrResult`: Karten nach Aufgaben gruppiert wie heute, gleiche
  Typografie und Abstände wie das Aufgabenblatt.
- **Abnahme:** Übungsfrage mit Zahlenantwort (`PX-B-…`) und eine
  Fallfrage mit Ausgangslage im Headless-Lauf ohne JS-Fehler; Vergleich
  der Klassen-/ID-Struktur zwischen `scrQuiz` und `scrBlatt` (gemeinsame
  Bausteine tragen dieselben Klassen).

### U4 – App: Werkzeugpanel und Parität

- Neues `widgets/werkzeug_panel.dart`: `LayoutBuilder` – ab 900 dp ein
  rechts angedocktes Panel (`Row` mit `SizedBox(width: 380)`), darunter ein
  `DraggableScrollableSheet` (Rasthöhen 0.45/0.9) **ohne** Modal-Barriere.
  Reiter Rechner · Rechenblatt · Formelbuch mit den bestehenden Widgets.
- Einhängen in `aufgabenblatt_screen.dart` (heute ohne Werkzeuge) und
  `quiz_screen.dart` (heute ohne Formelbuch); `home_screen.dart` behält den
  Werkzeuge-Einstieg, ruft aber dasselbe Panel.
- „Als Vorlage" im Formelbuch schreibt in das **aktive Antwortfeld**
  (Callback `onEinfuegen(String)` statt nur Zwischenablage); Rechner
  bekommt „Ins Antwortfeld".
- Klebender Aufgabenkopf (`SliverAppBar`/`SliverPersistentHeader`) mit
  Ausgangslage-Einblendung wie U2; Wertezeile als `Wrap` von `ActionChip`s.
- **Abnahme:** `flutter analyze` ohne Fehler, `flutter test` grün (heute
  26 Tests, dazu Tests für `werteAusText`-Pendant in Dart und für die
  Panel-Rasthöhen per `WidgetTester` bei 400×800 und 1024×768); Log der
  CI lesen, weil `continue-on-error` gesetzt ist.

### U5 – Startseite und Prüfungsübersicht

- Kacheln (`.tiles`) auf das Raster (U0) heben; Prüfungsliste mit
  Fach-Filter als klebende Filterzeile; Fortschritt je Prüfung
  (beantwortet/aufgedeckt aus `kvm_open_answers`) als schmaler Balken.
- Werkzeuge-Einstieg auf der Startseite öffnet das Panel (U1), nicht mehr
  drei Fenster.
- **Abnahme:** Headless 500 px: keine Kachel schmaler als 140 px, keine
  horizontale Scrollleiste; 1280 px: Kachelraster zwei- oder dreispaltig.

### U6 – Zugänglichkeit und Feinschliff

- Fokusführung (Panel, Einblendung, Lightbox), `aria-expanded`/
  `aria-controls` an Kopf-Knöpfen, Kontrast der Chips ≥ 4,5:1,
  `prefers-reduced-motion` bleibt beachtet.
- Tastenkürzel: `Alt+1/2/3` Reiter, `Alt+0` Panel zu, `Alt+A` Ausgangslage.
- **Abnahme:** Headless-Skript, das per `document.activeElement` die
  Tab-Reihenfolge Aufgabe → Panel → Aufgabe protokolliert; Kontrastwerte
  aus den Tokens rechnen (einfache Luminanzformel im Skript).

## 5. Regeln für die Umsetzung

- **Branch** `claude/meitner-app-build-6lnk2z`. Commits mit klaren deutschen
  Betreffzeilen und den Anhängen `Co-Authored-By: Claude Fable 5.1
  <noreply@anthropic.com>` und `Claude-Session: https://claude.ai/code/session_01PD5ddV5C1Qcpq4Q8dgm6C4`
  (in der Opus-Sitzung die dort vorgegebenen Anhänge). **Keinen Pull
  Request** eröffnen, außer der Nutzer bittet darum – er öffnet und mergt
  selbst. Kein Modellname in Code, Kommentaren oder Commits.
- **Datenvertrag ist eingefroren.** `data/*.js`, `flutter_app/assets/`,
  Schritt-IDs, `tab`/`tabL`/`bild`, `kvm_open_answers`, `kvm_open_tabs`,
  `kvm_open_points` bleiben zeichengleich. `python3 tools/sync_content.py
  --check` und `--validate-assets` müssen vor jedem Commit grün sein.
- **Skriptblöcke nicht zusammenlegen.** Die sechs Blöcke in `index.html`
  haben getrennte Funktionsräume; neue Übergänge nur über `window.KVM_*`.
  Jede ID, die ein Skript per `$()` anfasst, bleibt bestehen (bei Zweifel:
  `grep -o '\$("[a-zA-Z]*")' index.html | sort -u`).
- **Sprache.** Oberfläche, Kommentare, Commit-Betreff und Plan-Nachträge auf
  Deutsch; Bezeichnungen „Rechner", „Rechenblatt", „Formelbuch",
  „Aufgabenblatt", „Ausgangslage", „Anlage", „Aufdecken".
- **Flutter ohne SDK im Container.** Dart nur per Hand prüfen, dann pushen;
  die CI (`.github/workflows/android-build.yml`) läuft nur bei Änderungen
  unter `flutter_app/**` und lässt `flutter analyze`/`flutter test` mit
  `continue-on-error` durch – deshalb **immer die Job-Logs lesen**
  (`actions_list` → `get_job_logs`) und Befunde beheben, bevor das Paket
  als fertig gilt.
- **Web ohne Build.** Statische Dateien, keine Frameworks, kein Bundler.
  `app.css` (U0) ist die einzige neue Datei neben `index.html`.
- **Geheimhaltung.** PDFs der Prüfungen liegen bewusst nicht im Repo
  („Einsatz nur im Rahmen des Korrekturprozesses gestattet. Weitergabe an
  unbefugte Dritte untersagt."); Textlayer und Ausschnitte sind drin. Nichts
  davon anfassen, nichts freigeben.
- **Kein Agent-Fächer, keine Workflows**, es sei denn, der Nutzer bittet
  darum. Kein `send_later`, keine Cron-Erinnerungen.
- Nach jedem Paket die Statuszeile in Abschnitt 7 fortschreiben.

## 6. Prüfen ohne Bildschirm

`tools/headless/cdp.mjs` treibt das vorinstallierte Chromium und führt ein
Prüfskript im Seitenkontext aus; Rückgabe als JSON, JS- und Ladefehler
darunter. Testkopie und Aufruf:

```
mkdir -p /tmp/kvm-web && cp -r index.html app.css data anlagen /tmp/kvm-web/
python3 -m http.server 8099 --bind 127.0.0.1 --directory /tmp/kvm-web &
node tools/headless/cdp.mjs http://127.0.0.1:8099/ tools/headless/beispiele/panel-desktop.js
CDP_GROESSE=500,900 node tools/headless/cdp.mjs http://127.0.0.1:8099/ tools/headless/beispiele/panel-handy.js
node tools/headless/cdp.mjs http://127.0.0.1:8099/ tools/headless/beispiele/tabelle-ausfuellen.js
```

Eigenheiten: Headless-Chromium erzwingt mindestens 500 px Breite und zieht
die Fensterleiste ab (1280×900 → innerHeight 813); hinter dem Proxy der
Cloud-Sitzung scheitern Supabase-CDN und Google Fonts mit
`ERR_CERT_AUTHORITY_INVALID` – diese zwei Ladefehler sind kein Befund. In der
Sitzung ist `sleep` im Vordergrund gesperrt: den Server mit
`run_in_background` starten, Port mit `fuser -k 8099/tcp` freigeben.

Referenzwerte heute (Stand vor U1): Desktop `app=[80,757]`,
`panel_links=845`, `panel_breite=420`, keine Überlappung; Handy Sheet 80 %,
Aufgabe sichtbar 151 px (zu wenig – Ziel ≥ 300 px); Tabelle
`P-BW-20201103-s10#t1` mit 34 Eingabefeldern.

Prüfaufgaben, die alle Fälle abdecken:

| Fall | Warum |
|---|---|
| `P-BW-20201103` Aufgabe 5, 6 | ausfüllbarer BAB mit `tabL`, Maschinenstundensatz mit Tabelle |
| `P-BW-20181106` Aufgabe 6 | Tabelle im Teil, lange Ausgangslage |
| `P-NT-20241106` Aufgabe 5 | Abbildung (`nt24-ntc`) mit Lightbox |
| `P-RE-20201102` Aufgabe 6 | Ausgangslage mit vielen Zahlen, ohne Anlage |
| Übungsfrage `PX-B-…` mit Zahlenantwort | `qCalc`, Einheit, Rechnerergebnis |
| Fallfrage mit `qCase` | Ausgangslage im Quiz |

## 7. Stand

| Paket | Stand |
|---|---|
| U0 Stylesheet und Tokens | offen |
| U1 Werkzeugpanel Web | offen |
| U2 Aufgabenblatt als Arbeitsplatz | offen |
| U3 Einzelfrage und Ergebnis | offen |
| U4 App: Panel und Parität | offen |
| U5 Startseite und Übersicht | offen |
| U6 Zugänglichkeit | offen |
| Vorarbeit: Headless-Treiber im Repo (`tools/headless/`) | **fertig** 20. 9. 2026 |

## 8. Nicht-Ziele

- Keine neuen Inhalte, keine Änderung an Pipeline (`scripts/pruefungen/`)
  oder Datenmodell; die drei fehlenden Diagramm-Figuren (nth22 S. 9,
  mif23 S. 2, reh20 S. 11) sind ein eigener Inhaltsnachtrag laut
  `PLAN-altklausuren-und-aufgabenblatt.md` A6.
- Kein Framework, kein Build-Schritt, keine Umbenennung von Schritt-IDs.
- Kein Dunkelmodus (die Tokens aus U0 machen ihn später billig, er ist
  aber nicht Teil dieses Plans).
- Sprachbedienung (`tbVoice`) bleibt funktional wie heute, nur der Knopf
  zieht um.
- Kein Umbau von Login, Konto, Premium, Werbung.

## 9. Abnahme des Gesamtplans

Der Plan ist erfüllt, wenn auf `P-BW-20201103` Aufgabe 5 bei 1280 px und
bei 500 px Breite gleichzeitig sichtbar sind: Aufgabenkopf, mindestens ein
Absatz Aufgabentext oder die Ausgangslage-Einblendung, das ausfüllbare BAB
oder das Antwortfeld, und das Formelbuch mit einem Rechenschema – ohne
Überlappung, ohne horizontales Scrollen, ohne JS-Fehler; und wenn die
Flutter-App auf dem Aufgabenblatt dieselben drei Werkzeuge anbietet und CI
`analyze`/`test` ohne Befund durchläuft.
