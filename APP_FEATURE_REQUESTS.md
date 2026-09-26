# App-Feature-Requests – Content-Session → App-Session

Ergänzung zu `CONTENT_SYNC.md`. Während `CONTENT_SYNC.md` den **Datenvertrag**
(Fragen/Fälle) regelt, ist dieses Dokument der Kanal für **UI-/Feature-Änderungen**,
die die Web-App (`index.html`, Quelle der Wahrheit) bereits umgesetzt hat und die
in der nativen App (`flutter_app/**`) nachgezogen werden sollen.

Ablauf: Content-Session beschreibt hier die Änderung → App-Session setzt sie in
Flutter um und hakt sie unter „Status" ab. Reine Katalog-Änderungen laufen
weiter über den Sync, **nicht** hier.

---

## FR-001 · Startseite umgestellt: Industriemeister (fix) + Fachrichtung (abwählbar)

**Status App-Session:** ✅ erledigt (`claude/meitner-app-build-6lnk2z`)
**Web umgesetzt:** ✅ `claude/focused-meitner-ilnlqj` (Commit „Startseite umgestellt …")
**Priorität:** hoch (User-Wunsch: „Mach das es auf der App (android) und Webapp umgesetzt wird")

### Ziel / Framing
Die Startseite war bisher in *Kraftverkehrsmeister* (Hauptsache) und
*Industriemeister* (nicht verfügbar) geteilt. **Umgekehrt:**

- **Industriemeister-Basisqualifikationen** = das Hauptmodul mit den **4 festen
  Fächern** (Fach 1 Recht, 2 BWL, 3 Methoden, 4 Zusammenarbeit). **Immer aktiv,
  nicht abwählbar.**
- **Fachrichtung** = darunter, mit **Kraftverkehr (Fach 5)** als **abwählbarem**
  Zusatzfach (Schalter). Standardmäßig **an**.
- Weitere Fachrichtungen später möglich → generisch über Listen lösen, nicht auf
  Fach 5 hart codieren.

### Datenmodell / Konstanten (analog Web)
```
BASE_FACHER   = [1, 2, 3, 4]   // immer aktiv
ZUSATZ_FACHER = [5]            // abwählbar
```
Persistenz in `shared_preferences` (Web nutzt `localStorage['kvm_zusatz_v1']`):
- Key-Vorschlag: `kvm_zusatz_v1`
- Wert: Map `int(Fach) → bool(aktiv)`. **Fehlender Eintrag = aktiv** (Zusatz ist
  standardmäßig an; nur ein explizites `false` schaltet ab).

Kernlogik (Dart-Pseudocode, 1:1 aus der Web-App übernommen):
```dart
bool isFachActive(int f) =>
    BASE_FACHER.contains(f) ? true : (zusatzActive[f] != false);

// alle Fächer mit Fragen, die aktiv sind (Reihenfolge 1..5)
List<int> activeFacher() =>
    [1,2,3,4,5].where((f) => (fachCount[f] ?? 0) > 0 && isFachActive(f)).toList();

List<Question> activeQuestions() =>
    allQuestions.where((q) => isFachActive(q.f)).toList();

void toggleZusatz(int f) {
  zusatzActive[f] = !isFachActive(f);
  save();                                  // shared_preferences
  if (!isFachActive(f) && state.fach == f) { state.fach = 1; state.sub = '*'; }
  // danach: Home/Progress/Radar/Chips/Modus neu rendern
}
```

### Auswirkungen (überall die aktive Fächerauswahl respektieren)
Genau wie in der Web-App müssen diese Stellen `activeQuestions()`/`activeFacher()`
statt „alle Fragen" verwenden:

1. **Fortschrittsanzeige** (gemeistert / gesehen / offen, Fortschrittsbalken):
   nur über `activeQuestions()`.
2. **Prüfungsreife-Radar (#6):** Achsenzahl = `activeFacher().length`
   (**4 oder 5 Zacken dynamisch**, nicht fest 5). Gesamt-Reife nur über aktive
   Fächer gewichten. Radar-Hinweistext: „alle Zacken" (nicht „alle fünf Zacken").
3. **Modus „Alle Themen" / gemischte Runde:** Pool = `activeQuestions()`.
   Beschreibungstext sinngemäß „aus allen gewählten Fächern · Basisqualifikationen
   + aktive Fachrichtung(en)".
4. **„Heute fällig" / Spaced Repetition (Due-Liste & Zähler):** nur Fragen mit
   `isFachActive(q.f)` zählen/anzeigen (inaktive Fachrichtung fällt raus, auch
   „neue/frische" Fragen).
5. **Fach-Auswahl:** Wird eine gerade gewählte Fachrichtung abgeschaltet, auf ein
   Basisfach zurückfallen (`state.fach = 1; state.sub = '*'`).

### UI
- **Header:** Titel „**Industriemeister Basisqualifikationen**", Eyebrow
  „Meister-Trainer · IHK-Prüfungsvorbereitung".
- Untertitel sinngemäß: „**{N} Wissensfragen** · 4 Basisqualifikationen (fix) +
  {k} Fachrichtung(en) (wählbar) · …" — `k` = Anzahl `ZUSATZ_FACHER` mit Fragen.
- **Zwei Fach-Gruppen** mit Überschriften:
  - „Basisqualifikationen (Industriemeister) `[fix]`" → 4 feste Kacheln.
  - „Fachrichtung `[abwählbar]`" → Kraftverkehr-Kachel **mit Schalter**
    (`role=switch`, an/aus, tastaturbedienbar).
- Erklärtext unter der Fachrichtung: „Die vier Basisqualifikationen gelten für
  alle IHK-Meister und sind immer aktiv. Eine Fachrichtung (z. B. Kraftverkehr →
  Kraftverkehrsmeister) kannst du dazuschalten oder abwählen – sie zählt dann bei
  ‚Alle Themen', Fortschritt und Prüfungsreife mit."
- Abgewählte Fachrichtungs-Kachel visuell gedämpft (Opacity ~.55). Tippt man die
  gedämpfte Kachel (nicht den Schalter) an, schaltet sie sich wieder ein.
- Schalter-Farbe „an" = `#a2497f` (Fach-5-Akzentfarbe). Fach-Badge-Farben
  unverändert: `{1:#0C6C78, 2:#D9820A, 3:#2C8A4E, 4:#3f6fb5, 5:#a2497f}`.

### Akzeptanzkriterien
- [x] Beim ersten Start sind alle 5 Fächer aktiv (Kraftverkehr an).
- [x] Kraftverkehr abwählen: Radar zeigt 4 Zacken, Fortschritt/„Alle Themen"/
      „Heute fällig" ohne Fach-5-Fragen; Auswahl übersteht App-Neustart.
- [x] Basisfächer haben keinen Schalter und sind nie abwählbar.
- [x] Wieder anwählen stellt den vorigen Zustand her (5 Zacken etc.).

### Umsetzung App-Session (Flutter)
- `services/selection_service.dart` (neu): `baseFacher [1-4]`, `zusatzFacher [5]`,
  `isFachActive`, `toggle`, Persistenz `shared_preferences['kvm_zusatz_v1']`
  (fehlender Eintrag = aktiv).
- `services/data_service.dart`: `activeFacher()` / `activeQuestions()`.
- `services/progress_service.dart`: Kennzahlen + Reife nur über aktive Fächer.
- `services/round_builder.dart`: „Alle Themen" & „Heute fällig" über
  `activeQuestions()`.
- `widgets/radar_chart.dart`: dynamische Achsenzahl (`facher`-Liste), 4 oder 5
  Zacken.
- `screens/home_screen.dart`: Industriemeister-Header, zwei Fach-Gruppen
  (Basis fix + Fachrichtung mit Schalter, gedämpft wenn aus), dynamische
  Radar-Legende, generischer „Alle Themen"-Text; Konto-Zugang hierher verschoben.
- `main.dart`: Einstieg direkt auf `HomeScreen` (Kategorie-Zwischenseite
  entfernt), `SelectionService.load()` beim Start.

### Referenz Web-Implementierung (`index.html`, Commit auf Content-Branch)
- Logik: `BASE_FACHER/ZUSATZ_FACHER/zusatzActive/isFachActive/activeFacher/
  activeQuestions/toggleZusatz` (um Zeile 744–757).
- Rendering: `renderFachGroup(grid, fachs, isZusatz)` (Zeile 808), `renderProgress`
  (765), `renderReadiness`/`overallReife` (778–801), `dueList`/`dueCount` (657/658),
  Home-Untertitel (1144).
- HTML-Anker: `#fachGridBase`, `#fachGridZusatz`, `#zusatzNote`; Tags `.fixtag`,
  `.opttag`, `.fach-toggle`, `.fach.fach-off`.

---

## FR-002 · UI-Überarbeitung: „Heute“-Karte, Werkzeug-Dock, Dunkelmodus, Layout-Fixes

**Status App-Session:** ✅ erledigt (`claude/ui-design-improvement-my0f66`, PR #52, App 1.1.0)  
Abweichungen App: Auf dem Tablet steht das Werkzeug-Dock als Leiste unten rechts statt als Symbolspalte rechts, weil es den Platz der `bottomNavigationBar` nutzt. Weiche Trennstellen (U+00AD) trennen zwar, zeichnen aber keinen Bindestrich – das entspricht dem U+200B-Ausweg aus H.  
**Web umgesetzt:** ✅ `claude/ui-design-improvement-my0f66` (Commit „UI überarbeitet …“)
**Priorität:** hoch für A–E, mittel für F–H, eigenständiges Paket für I (Dunkelmodus) und J (Schriften)

### Ziel / Framing
Die Web-App wurde gestalterisch überarbeitet. Die Leitplanken bleiben: Petrol/Amber,
Barlow Condensed für Überschriften, Mono für Labels, Touch-Ziele ≥ 44 dp. Die App soll
sich danach genauso anfühlen. Kern der Überarbeitung:

1. **Die erste Aktion steht oben.** Eine „Heute“-Karte mit „Jetzt lernen“ liegt direkt
   unter dem Kopf. Vorher kamen erst Statistik und Radar – auf dem Handy war „Üben“
   erst nach ca. 2,5 Bildschirmen erreichbar.
2. **Werkzeuge nur dort, wo gerechnet wird.** Ein ruhiges, einfarbiges Dock erscheint
   nur im Quiz und im Aufgabenblatt. Auf der Startseite gibt es keine Werkzeuge,
   dafür eine Formelbuch-Kachel.
3. **Dunkelmodus** über Design-Tokens (System / Hell / Dunkel wählbar).
4. **Layout-Fehler behoben**, die es in ähnlicher Form auch in der App gibt oder
   geben kann.

Die Pakete A–J lassen sich einzeln umsetzen und einzeln abnehmen. Empfohlene
Reihenfolge: A → B → C → D → E → F → G → H → I → J.

Zeilenangaben zur App stammen aus dem Stand vor dieser Änderung
(`flutter_app/lib/...`). Web-Referenzen stehen am Ende.

---

### A · Farbtokens an die Web-App angleichen (klein)

Einige App-Konstanten weichen sichtbar vom Web ab. Das Web ist die Quelle der Wahrheit.

In `constants.dart:70-87` diese Werte ändern:

| App-Konstante | heute | neu (= Web) |
|---|---|---|
| `kBg` | #F2F5F6 | **#EDF1F3** (`--steel`) |
| `kInk` | #14262C | **#17272E** |
| `kMuted` | #5F6E75 | **#5C6B72** |
| `kPetrolSoft` | #E1EEEF | **#E3F0F1** |
| `kAmber` | #C9780C | **#D9820A** |
| `kLine` | #DCE6E7 | **#D4DCDF** |
| `kDue` | #5E64D6 | **#6D5AE6** (Web `--violet`, Sprache aktiv) |
| `kInkSoft` | #3A4A50 | **#33454C** |

Diese Konstanten neu anlegen. Die Namen folgen den CSS-Tokens in `index.html`, damit
man beide Seiten nebeneinander lesen kann:

| Konstante | Hell | Zweck |
|---|---|---|
| `kSurface` | #F6FAFA | dezente Fläche (Zellen, Hover, Quiz-Kopf) |
| `kSurface2` | #EEF4F5 | stärkere Fläche (Tabellenkopf, Rechner-Operatoren) |
| `kTrack` | #DDE5E8 | Hintergrund von Fortschrittsbalken und Ring |
| `kLineStrong` | #B7C3C7 | Rahmen von Kacheln und Optionen |
| `kPetrolLine` | #BCD9DD | Rahmen von Petrol-Pills |
| `kAmberDeep` | #A65F00 | **gefüllte** Amber-Flächen mit weißer Schrift (Tag „Klausur“) |
| `kAmberSoft` | #FBEFD9 | ersetzt die lokale `_amberSoft` (`quiz_screen.dart:518`) |
| `kAmberLine` | #EDD4A6 | |
| `kAmberInk` | #7A4A00 | Amber als **Text** (Lösungsblase, VO-Bezug) |
| `kOkLine` / `kOkInk` | #B9DCC5 / #226B3C | Grün als Rahmen bzw. Text auf `kOkSoft` |
| `kErrLine` / `kErrInk` / `kErrFaint` | #E8BEB2 / #A8391F / #FDF6F4 | Rot als Rahmen, Text und „warum falsch“-Fläche |
| `kPlum` / `kPlumSoft` / `kPlumLine` / `kPlumInk` | #A2497F / #FBF2F8 / #E6C9DE / #8E3A6C | Fallaufgaben, Ausgangssituation, Fachrichtung |
| `kBlue` / `kBlueSoft` / `kBlueInk` | #3F6FB5 / #E6EDF8 / #2F5A99 | Typ-Tag „Rechenaufgabe“ |
| `kGoldSoft` / `kGoldLine` / `kGoldInk` | #FDF8EC / #D9C79A / #8A6D1F | Stepper „teilweise“, „baut auf … auf“ |

**Warum die *Ink*-Töne:** Grün, Rot und Amber als Text auf ihren Soft-Flächen
erreichten nur 2,9–4,2 : 1 Kontrast (WCAG verlangt 4,5 : 1). Die Regel lautet:
**Füllfarbe mit weißer Schrift = Grundton**, **Textfarbe auf heller Fläche = *Ink*-Ton**.
Beispiel: der Titel „✓ Richtig“ in `kOkInk`.

Die Inline-Farben aus der Bestandsaufnahme ersetzen, zum Beispiel:
- #FBF2F8 / #E6C9DE → `kPlumSoft` / `kPlumLine`
- #7A4A00 → `kAmberInk`
- #B9DCC5 → `kOkLine`
- #D9C79A / #FDF8EC / #8A6D1F → Gold-Tokens
- #127A4B / #B3261E (`anlage_tabelle:117`) → `kOkInk` / `kErrInk`

**Abnahme:** In `lib/` stehen keine Hex-Farben mehr außerhalb von `constants.dart`.
Ausnahmen sind der Rechner-Display (#0F1E23), das Rechenblatt-Raster, das
Logo-Schatten-Alpha und die Fachfarben. Die Startseite wirkt im Screenshot farblich
wie die Web-App.

---

### B · Startseite: „Heute“-Karte oben, klare Reihenfolge (mittel, hoher Nutzen)

**Neue Reihenfolge in `home_screen.dart` `build` (Zeilen 152-291):**

1. `_hero` (349-389) bleibt, aber kompakter.
   - Untertitel: „**3.666 Wissensfragen** · 4 Basisqualifikationen + 1 Fachrichtung ·
     121 Original-IHK-Prüfungen · Fahrschul-Prinzip“.
   - Zahlen mit Tausenderpunkt; die Prüfungszahl = Anzahl Fälle mit `id` `P-…`.
2. **Neu: `_todayCard()`** – ersetzt die Zeile „Heute fällig“ in der Modusliste
   (248-252) und die Stat-Zeile „Lernfortschritt“ (162-190).
3. Gruppen „Basisqualifikationen“ und „Fachrichtung“ (219-235) – unverändert.
4. „Themenbereich“-Chips (239-243) – unverändert.
5. **„Üben“** mit zwei Unterüberschriften statt einer flachen Liste:
   - **„Im gewählten Fach · {Kurzname} – {Bereich}“**: Training, Schwächen gezielt,
     Prüfungssimulation. Diese Modi hängen von der Auswahl direkt darüber ab.
   - **„Fachübergreifend“**: Alle Themen, Fallaufgaben.
6. **„Nachschlagen & Prüfen“**: Original-IHK-Prüfungen, **Formelbuch (neu, öffnet das
   Formelbuch-Sheet)** und Betriebliches Kostenwesen.
7. **„Dein Stand“** ans Ende. Er enthält:
   - den Titel „Prüfungsreife {x} %“ mit „Zurücksetzen“ rechts
   - Radar und Legende
   - Erklärtext
   - Konto/Sicherung (bisher nur als Icon im Hero)
   - die Darstellungswahl (Paket I)

**`_todayCard()` – Spezifikation (Web: `index.html:944` `.today`, Logik `updateDueCard` Z. 1501):**

**Karte**
- Verlauf 135° von #0C6C78 nach #08535C, Radius `kRadius`, Innenabstand 18/18/18/16.
- Alle Texte weiß.

**Inhalt, von oben nach unten**
1. Kicker „HEUTE · LEITNER-WIEDERHOLUNG“: Mono 10,5, Buchstabenabstand ≈ 1,3, Weiß 74 %.
2. Titel: Barlow Condensed / Display 26–32, w700, GROSS, Weiß. Der Text hängt vom
   Zustand ab:
   - `due > 0`: „{due} Frage(n) fällig“ (Tausenderpunkt)
   - sonst, wenn `fresh > 0`: „Neue Fragen lernen“
   - sonst: „Alles wiederholt“
3. Beschreibung 13 sp, Weiß 84 %, wortgleich zum Web:
   - `due > 0`: „Heute zur Wiederholung dran (Leitner-System) – je Runde 20 Fragen,
     aufgefüllt mit neuen.“
   - `fresh > 0`: „Aktuell nichts fällig – starte mit neuen Fragen. Beantwortete Fragen
     kommen je nach Box in 1–33 Tagen zur Wiederholung.“
   - sonst: „Alles wiederholt und nichts fällig. Komm morgen wieder – oder nutze das
     Schwächen-Training.“
4. CTA „Jetzt lernen →“, startet `RoundMode.due`.
   - Weißer `FilledButton`, Schrift `kPetrolDeep` w700 15,5, Mindesthöhe 48, Radius 11.
   - Auf dem Handy volle Breite unter dem Text; ab 600 dp rechts neben dem Text.
   - Deaktiviert, wenn `due + fresh == 0`.
5. Trennlinie Weiß 18 %, darunter drei Paare:
   - Zahl: Display 23 w700 Weiß
   - Label: 12 sp, Weiß 76 %
   - Paare: „gemeistert“, „gesehen“, „offen“ – aus `progress_service`, nur aktive Fächer
6. Fortschrittsbalken:
   - 7 dp hoch, Spur Weiß 20 %
   - Füllung als Verlauf #FFD28F → `kAmber`
   - Breite = gemeistert / aktiv

Tausenderpunkt ohne `intl`:
```dart
String fmtN(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
```

**Radar in „Dein Stand“**
- Unter 420 dp Breite Netz (max. 200 dp) und Legende untereinander, darüber nebeneinander.
- Die Werte der Legende brechen nie um: `softWrap:false`, eigene Spalte.

**Abnahme**
- Handy 390 × 844: „Jetzt lernen“ ist ohne Scrollen sichtbar.
- Die Zahl im Titel stimmt mit der „Heute fällig“-Runde überein.
- Kraftverkehr abwählen ändert „offen“ (3.666 → 2.726).
- Modusliste ohne „Heute fällig“; die zwei Unterüberschriften sind da, der Bezug
  zeigt das gewählte Fach.

---

### C · Werkzeug-Dock in Quiz und Aufgabenblatt, Formelbuch-Kachel (mittel, hoher Nutzen)

**Web-Verhalten (`.toolbar`, `index.html:459` ff.)**
- Weiße Leiste mit Rahmen und Schatten, Radius 16, Innenabstand 5.
- Je Werkzeug ein Knopf: Icon 20 in Petrol, darunter ein Label (11, w600).
- Auf dem Handy am unteren Rand (Abstand 10), auf dem Tablet rechts als Icon-Spalte.
- Sichtbar **nur im Quiz und im Aufgabenblatt**.
- Im Aufgabenblatt ohne „Sprache“ – die Sprachbedienung wirkt nur bei Auswahlfragen.
- Aktive Werkzeuge sind markiert:
  - Rechner offen: Fläche `kPetrolSoft`
  - Sprache an: Fläche `kDue`/Violett, Icon und Label weiß

**App heute**
- Home hat einen FAB „Werkzeuge“ (`home_screen.dart:295`, `_toolsFab` 464-518).
- Das Quiz hat nur das Mikrofon in der AppBar (249-253). Rechner und Rechenblatt
  gibt es nur im Composer offener Fragen (814-831).
- Das Aufgabenblatt hat **gar keine Werkzeuge**.

**Umsetzung**
1. `_openTool` (`home_screen.dart:87-127`) in ein gemeinsames `lib/widgets/tools.dart`
   ziehen. Darin:
   - `openCalculator(ctx)`
   - `openDrawingPad(ctx)`
   - `openFormulaBook(ctx, {String? Function(String text)? onVorlage})`
2. Neues Widget **`ToolDock`** (`lib/widgets/tool_dock.dart`), eingebunden als
   `Scaffold(bottomNavigationBar: ToolDock(...))`:
   - Aufbau: `SafeArea(minimum: EdgeInsets.fromLTRB(10,0,10,10))` →
     `Container(padding 5, kPaper, Rahmen kLine, Radius 16, Schatten)` →
     `Row` aus `Expanded`-Knöpfen (Icon über Label, Mindesthöhe 50).
   - Da `bottomNavigationBar` den Platz reserviert, verdeckt das Dock nie „Weiter“.
   - Die Knöpfe:
     - **QuizScreen**: Rechner · Blatt · Formeln · Sprache. Das Mikrofon aus der
       AppBar wandert ins Dock; aktiv = Violett gefüllt.
     - **AufgabenblattScreen**: Rechner · Blatt · Formeln.
3. **FAB auf Home entfernen.** Stattdessen die Kachel „Formelbuch – Formeln und
   Kalkulationsschemata zum Ausrechnen“ (Icon `menu_book_outlined`, `kOk`) unter
   „Nachschlagen & Prüfen“. Kostenwesen bleibt dort ohnehin eine Kachel.
   - Die `ListView`-Unterkante `padding …96` (Zeile 155) auf 24 senken – der FAB-Platz
     entfällt.
4. **Formelbuch im Aufgabenblatt → Vorlage ins Antwortfeld** (Web:
   `window.KVM_blattAntwort`, `blAntwortAnhaengen`):
   - Der Blatt-Screen merkt sich die zuletzt fokussierte, noch nicht aufgedeckte
     Teilaufgabe. Fallback ist die erste offene Teilaufgabe.
   - `onVorlage(text)` hängt den Text mit einer Leerzeile an deren Antwort an:
     Controller und `AnswerStore`, Stepper aktualisieren. Rückgabe ist das Ziel, z. B.
     „Aufgabe 1 a)“.
   - Die SnackBar lautet dann „Als Vorlage in die Antwort zu Aufgabe 1 a) übernommen –
     dort ausfüllen.“
   - Ohne Ziel (Home) bleibt es bei der Zwischenablage (`formula_book.dart:459-472`).
     Den Kommentar dort anpassen.

**Abnahme**
- Auf Home gibt es kein Dock und keinen FAB; das Formelbuch öffnet über die Kachel.
- Im Quiz liegt das Dock unten und verdeckt nichts.
- Im Aufgabenblatt gibt es Rechner, Blatt und Formeln. „Vorlage ins Antwortfeld“ landet
  in der richtigen Teilaufgabe und übersteht einen Neustart (AnswerStore).

---

### D · Quiz: Antwortoptionen, Feedback, Ausgangssituation (klein)

`quiz_screen.dart`:

1. **Buchstaben-Badge färbt sich mit dem Zustand** (`_mcOptions` 434-494, Badge um 474).
   Heute bleibt er immer grau umrandet. Neu:

   | Zustand | Badge-Fläche | Badge-Text | Rahmen der Option |
   |---|---|---|---|
   | gewählt | `kPetrol` | Weiß | `kPetrol` |
   | richtig | `kOk` | Weiß | `kOk` |
   | falsch gewählt | `kErr` | Weiß | `kErr` |
   | falsch mit Begründung (nicht gewählt) | – | – | `kErrLine`, Fläche `kErrFaint` |
2. **„Warum falsch“-Text** bündig unter dem Optionstext, nicht unter dem Badge:
   - Einzug 36 dp (Badge ≈ 25 + Abstand 11)
   - 12,5 sp, linke Linie 2 dp `kErr`
   - Textfarbe `kMuted`; bei der gewählten falschen Option `kInkSoft`
3. **Feedback-Box** (`_feedback` 907-930):
   - 1-dp-Rahmen `kOkLine` / `kErrLine`
   - Titel in `kOkInk` / `kErrInk`
   - bei Rechenaufgaben 6 dp Abstand zwischen Lösung und Erklärung
4. **Fall-Banner** (`_caseBanner` 307-332):
   - wird einklappbar – `ExpansionTile` in der Plum-Karte, Tag „FALLAUFGABE“ bzw.
     „IHK-PRÜFUNG“, Titel, Knopf „AUSGANGSSITUATION ▾“
   - nur bei Teil 1 aufgeklappt, ab Teil 2 zu – außer der Nutzer hat ihn selbst geöffnet
   - Web: `state.ctxOpen` / `ctxTouched`, `keepCtx()`
5. Typ-Tag „Rechenaufgabe“ in Blau (`kBlueSoft` / `kBlueInk`) statt Amber, damit sich
   Auswahl (Petrol), Rechnen (Blau) und Offen (Amber) unterscheiden.

**Abnahme:** Badge-Farben wie in der Tabelle. Die Begründung steht bündig unter dem
Text. Ab Teil 2 ist die Ausgangssituation zugeklappt.

---

### E · Ergebnis (klein)

`result_screen.dart`:

1. **Ringfarbe** (Zeile 85):
   - ≥ 80 % → `kOk`
   - ≥ 50 % → `kPetrol`
   - sonst → `kAmber`

   Heute: ≥ 50 % grün, sonst Amber. Balken je Themenbereich (216, 250) unverändert
   (≥ 50 % grün).
2. **„Nur Fehler wiederholen (n)“** (147-161):
   - `OutlinedButton` mit 1,5-dp-Rahmen `kAmber`, Fläche `kAmberSoft`, Text `kAmberInk`
     w700, Mindesthöhe 48
   - bisher Amber-Text auf Weiß – zu wenig Kontrast
3. **Neu: „Neue Runde starten“** als `FilledButton` (Petrol) zwischen
   „Fehler wiederholen“ und „Zur Startseite“. Startet denselben Modus erneut; nach
   einer Retry-Runde ein Training.
   - „Zur Startseite“ wird dann `OutlinedButton`.
   - Web-Reihenfolge: Fehler wiederholen · Neue Runde starten (primär) · Zur Startseite.

**Abnahme:** 30 % → Amber-Ring; 65 % → Petrol; 85 % → Grün. Drei Aktionen in der
Web-Reihenfolge.

---

### F · Original-IHK-Prüfungen: Filterchips und einklappbare Termine (klein bis mittel)

`pruefungen_screen.dart`:

1. **Filterchips nach Bereich** über der Liste (in der App neu; das Web hat sie schon und zeigt jetzt Kurznamen):
   - Kurznamen, die Reihenfolge ist fachlich und fest:

     | Bereich (amtlich) | Chip |
     |---|---|
     | Rechtsbewusstes Handeln | Recht |
     | Betriebswirtschaftliches Handeln | BWL |
     | Methoden der Information, Kommunikation und Planung | Methoden |
     | Zusammenarbeit im Betrieb | Zusammenarbeit |
     | Naturwissenschaftliche und technische Gesetzmäßigkeiten | Naturwiss. & Technik |
     | Fuhrparktechnik und Fuhrparkmanagement | Fuhrpark (FT) |
     | Organisation und Kommunikation | Organisation (OK) |

   - Unbekannte Bereiche behalten den vollen Namen und stehen am Ende.
   - Erster Chip „Alle“.
   - Die Anzahl steht als kleine Mono-Zahl im Chip („BWL 22“).
   - Aktiver Chip gefüllt Petrol; Mindesthöhe 36; `Semantics(selected: …)` bzw.
     `ChoiceChip`.
   - Den vollen Namen per `Tooltip`/`semanticsLabel` zugänglich machen.
2. **Termine einklappbar**: die zwei jüngsten offen, ältere zu. Mit aktivem Filter sind
   alle offen (Web: `offeneTermine<2 || filter`).
3. Die Aufgabenliste je Prüfung (`_aufgabenListe` 277-329, heute immer offen) hinter
   „Einzelne Aufgabe öffnen ▾“ einklappen – die Liste wird sonst sehr lang.

**Abnahme:** Die Chip-Zeile passt auf 390 dp in höchstens 3 Zeilen. Ein Filter zeigt
nur Prüfungen dieses Bereichs.

---

### G · Aufgabenblatt: Ausgangssituation und Stepper (klein)

`aufgabenblatt_screen.dart`:

1. `_ctxOffen` (48, 320-321):
   - offen beim Start; beim Wechsel zu einer anderen Aufgabe zu, **es sei denn**, der
     Nutzer hat sie selbst aufgeklappt (Web: `ctxTouched`)
   - `onExpansionChanged` muss den Zustand wirklich halten: `setState` bzw. ein
     `ExpansionTileController`
2. Stepper-Pillen (`_pille` 253-296) mindestens 40 × 40 dp (heute 36 × ~31).
3. Punkte-Knöpfe (`_punkteKnopf` 823-841) mindestens 42 × 42 dp, Rahmen `kLineStrong`.

---

### H · Formelbuch: schmale Handys (klein)

`formula_book.dart`:

1. **Kalkulationsschema-Zeilen** (`_schemaRow` 364-414) auf < 400 dp Breite:
   - Prozentfeld 58 statt 70, Wertfeld 92 statt 104, Abstand 5
   - das Label `Expanded` darf umbrechen
   - Im Web lief „+ Materialgemeinkosten“ sonst unter das Prozentfeld.
2. **Weiche Trennstellen** an Wortfugen, nur fürs Anzeigen (nie in Vorlagen oder der
   Zwischenablage):
   ```dart
   final _fuge = RegExp(r'(Material|Fertigungs|Verwaltungs|Vertriebs|Sonder|einzel|'
       r'gemein|Herstell|Selbst|Listen|verkaufs|Bezugs|Einstands|Kunden)(?=[a-zäöüß]{4,})');
   String weich(String s) => s.replaceAllMapped(_fuge, (m) => '${m[1]}­');
   ```
   Ergibt z. B. „Fertigungs·gemein·kosten“ und „Listen·verkaufs·preis“.
   - Falls die Flutter-Version U+00AD nicht als Trennstelle darstellt, stattdessen
     U+200B verwenden – dann ohne Bindestrich.
3. **Rechenbare Formeln** (`_rechner` 197-284): die Variablenzeile mit
   `NumField width 124` darf auf 360 dp nicht überlaufen – Feld `Flexible` mit
   `maxWidth 124`. Das Web hatte hier einen echten Überlauf (zweites Feld ragte aus
   der Karte).

---

### I · Dunkelmodus (eigenständiges Paket, groß)

**Web**
- Tokens werden unter `@media (prefers-color-scheme: dark)` getauscht, außer Hell ist
  gewählt.
- Zusätzlich gibt es `:root[data-theme="dark"]`.
- Die Wahl „Darstellung: Automatisch / Hell / Dunkel“ steht in `localStorage['kvm_theme']`:
  `light` | `dark`, fehlend = System.

**App**
1. `ThemeExtension<KvmColors>` mit allen Tokens aus A (Hell) und der Dunkel-Palette
   unten, dazu eine Zugriffs-Erweiterung `context.kc`.
   - `MaterialApp(theme:, darkTheme:, themeMode:)` in `main.dart:40-85`.
2. `themeMode` in `shared_preferences['kvm_theme']` speichern (gleiche Werte wie im
   Web; fehlend → `ThemeMode.system`).
   - Umschalter als `SegmentedButton<ThemeMode>` in „Dein Stand“ (Paket B, Punkt 7).
3. Alle Inline-Verwendungen von Flächen- und Textfarben (`kPaper`, `kInk`, `kMuted`,
   `kLine`, Soft-Töne …) auf `context.kc.*` umstellen. `const` fällt dabei an vielen
   Stellen weg.
   - Screen für Screen vorgehen: Home → Quiz → Ergebnis → Prüfungen → Aufgabenblatt →
     KW → Sheets.
4. Bewusst **hell** bleiben:
   - Scans und Anlagen (`AnlageBild`) und das Rechenblatt, weil sie Papier sind
   - die Fachfarben (`kFachColor`), weil es Mitteltöne mit weißer Schrift sind
   - der Rechner-Display, der ohnehin dunkel ist

**Dunkel-Palette** (Kontraste geprüft; jede Textkombination ≥ 4,5 : 1):

**Flächen und Linien**

| Token | Dunkel |
|---|---|
| steel (Seite) | #0B1417 |
| paper (Karte) | #132024 |
| surface | #18282D |
| surface2 | #1D3036 |
| track | #263A40 |
| line | #27393F |
| lineSoft | #1F3035 |
| lineStrong | #3A5159 |

**Text**

| Token | Dunkel |
|---|---|
| ink | #E2EBED |
| inkSoft | #C3D0D4 |
| muted | #93A5AB |

**Akzentfarben**

| Token | Dunkel |
|---|---|
| petrol (Füllung) | #0E7C89 |
| petrolDeep (Füllung, gedrückt) | #0A5F69 |
| petrolSoft | #123A40 |
| petrolLine | #1F5A62 |
| petrolInk (Text) | #6CC7D2 |
| petrolInkDeep (Text) | #A6E1E8 |
| amber | #D9820A |
| amberDeep | #A65F00 |
| amberSoft | #35260E |
| amberLine | #6A4A17 |
| amberInk | #F2BC6B |
| ok | #2F9455 |
| okSoft | #142D1D |
| okLine | #2B5B3B |
| okInk | #7ED39A |
| err | #C8503A |
| errSoft | #381C17 |
| errFaint | #2A1A17 |
| errLine | #6B3226 |
| errInk | #F3A08D |
| plum | #A2497F |
| plumSoft | #2B1824 |
| plumLine | #5C2E4A |
| plumInk | #E3A3CB |
| violet | #6D5AE6 |
| violetSoft | #221E45 |
| violetInk | #BDB2FA |
| blue | #3F6FB5 |
| blueSoft | #172538 |
| blueInk | #A2C0F2 |
| goldSoft | #2E2710 |
| goldLine | #6B5B26 |
| goldInk | #E3C77A |

**Sonderfälle**

| Element | Dunkel |
|---|---|
| Heute-Karte | Verlauf #0D5B65 → #0A3F47 |
| Heute-Karte, CTA | Fläche #E6F4F6, Text #0A4B53 |
| Schalter aus | #3A4E55 |
| Button deaktiviert | #2C4A50 |

**Regel:** Füllungen (Buttons, aktive Chips, Badges) tragen in beiden Modi **weiße**
Schrift. Akzent-**Text** auf Flächen nimmt immer den *Ink*-Ton. Genau das hält beide
Modi lesbar.

**Abnahme:**
- Alle Screens im Dunkelmodus ohne weiße Flächen, außer Scans und Rechenblatt.
- Kein Text unter 4,5 : 1.
- Die Wahl übersteht einen Neustart.
- „Automatisch“ folgt dem System.

---

### J · Schriften (optional, klein bis mittel)

Die App nutzt heute die Plattformschrift und 5× generisches `'monospace'`.

Für den gleichen Charakter wie im Web die drei OFL-Schriften als Assets bündeln, nicht
per Netz laden – die App soll offline starten:
- **Barlow Condensed** 500/600/700: Überschriften, Heute-Titel, Modus-Titel,
  Sheet-Titel, Ring-Prozent
- **Inter** 400–700: Fließtext
- **IBM Plex Mono** 500/600: Eyebrows, Abschnittslabels in Großbuchstaben mit
  Buchstabenabstand, Zähler, Formeln

`pubspec.yaml` → `fonts:`; `ThemeData(fontFamily: 'Inter')`. Display- und Mono-Stile
kommen als `TextTheme`-Einträge bzw. Konstanten dazu.

---

### Bewusst NICHT übernehmen (nur Web)
- `@media (hover:hover)`, `scroll-padding`, `overflow:clip` – reine Browser-Details.
- Das Formelbuch als **Seitenschublade** neben dem Aufgabenblatt (Web ≥ 821 px). In der
  App bleibt es ein Bottom-Sheet.
- Die Enter-Taste im Quiz. Im Web lief nach „Antwort prüfen“ per Enter derselbe
  Tastendruck auch in „Weiter“ – die Erklärung verschwand sofort. Behoben mit
  `preventDefault`. Für die App nur relevant, falls Hardware-Tastatur-Kürzel
  (`Shortcuts`/`Actions`) eingebaut werden.

### Referenz Web-Implementierung (`index.html` auf `claude/ui-design-improvement-my0f66`)

**CSS**
- Tokens: `:root` Z. 27, Dunkel Z. 57 (Media) und Z. 81 (`data-theme`).
- Heute-Karte: `.today` Z. 131 ff.
- Dock: `.toolbar` Z. 459 ff. (Sichtbarkeit über `body[data-screen]`).
- MC-Option: `.opt .opt-t` Z. 304, `.opt-why` Z. 316.
- Ringfarben: `.ring .fg.is-ok/.is-low` Z. 392.
- Kalkulationsschema: `.ks-row` Z. 623; Formelfelder `.fb-calc` Z. 606.
- Filterchips: `.pr-chip` Z. 758.

**HTML-Anker**
- `#todayTitle`, `#dueDesc`, `#btnDue`, `#pMastered`/`#pSeen`/`#pOpen`/`#pFill`
- `#scopeHint`, `#btnFormelHome`, `#themeCtl`, `#readySection`

**JS**
- `fmtN` Z. 1397, `updateDueCard` Z. 1501
- Ringfarbe in `finishRound` Z. 2508, `show()` setzt `data-screen` (Z. 2574)
- `theme()` Z. 2619, `calcKnopf` Z. 2714, `weich()` Z. 2892
- `BEREICH_KURZ` Z. 4377

---

## FR-003 · Prüfungen neu: strukturierte Texte, Rechenweg, Aufgabenblatt, Startseite mit Lernstand

**Status App-Session:** ✅ erledigt (`claude/ui-design-improvement-my0f66`, PR #52, App 1.1.0)  
Abweichungen App: Mit dem heutigen Datenstand öffnet die Web-Logik 439 Rechenteile statt 435, der Test erwartet 439. Die Test-ID aus A heißt heute `P-BW-20230504-s14` statt `-s0`.  
**Web umgesetzt:** ✅ `claude/ui-design-improvement-my0f66` (Commit „Prüfungen überarbeitet …“)
**Priorität:** sehr hoch für A (ohne A zeigt die App nach dem nächsten Sync „a | b“-Rohtext),
hoch für B und C, mittel für D, mittel bis hoch für E.
**Baut auf FR-002 auf.** Wo sich beide widersprechen, gilt FR-003:
- Der Untertitel der Startseite endet **ohne** „· Fahrschul-Prinzip“ (ersetzt FR-002 B.1).
- Die „Heute“-Karte aus FR-002 B.2 geht in der Lernstand-Karte (E.2) auf.

### Ziel / Framing
Rückmeldung aus der Nutzung: Tabellen kamen als unverständlicher Fließtext an, Anlagen
zum Ausfüllen fehlten, Rechenaufgaben im Textfeld waren mühsam, das Aufgabenblatt wirkte
unaufgeräumt, die Startseite zu flach. Die Web-App löst das so:

1. **Daten** (kommen per Sync, nichts zu tun außer A): Tabellen stehen im Text als
   Zeilen „a | b | c“, Formeln und Rechenschritte auf eigenen Zeilen, Brüche linear
   („Zähler ÷ Nenner“). Neu sind acht ausfüllbare Anlagen mit Lösungstabelle (`tab` +
   `tabL`) und rund 100 rechnerisch belegte Korrekturen von OCR-Rechenzeichen.
2. **Text-Renderer** macht daraus echte Tabellen, Listen und Rechenblöcke (A).
3. **Rechenweg** statt Textfeld für Rechenaufgaben: Zeile für Zeile, Ergebnis sofort (B).
4. **Aufgabenblatt** wie ein Prüfungsbogen, mit mitlaufender Aufgabenleiste,
   Bearbeitungsstand und klarer Lösungsansicht (C).
5. **Prüfungsliste** mit Fortschritt je Prüfung und „Weiter bei Aufgabe …“ (D).
6. **Startseite** in eigenen Karten: Lernstand-Ring mit Ampel, Lernweg durch die Fächer,
   Erfolge, Aktivität – angelehnt an „Fahren Lernen“ (E).

Empfohlene Reihenfolge: A → C → B → D → E. Jedes Paket ist einzeln abnehmbar.

---

### A · Prüfungstexte strukturiert darstellen (klein bis mittel, sehr hoher Nutzen)

**Wo:** überall, wo heute Prüfungstext als `Text(...)` steht:
- `aufgabenblatt_screen.dart`: Ausgangssituation `_ausgangslage` (Z. 332), Ausgangslage
  der Aufgabe in `_aufgabenkopf` (Z. 366), Frage in `_TeilKarte` (Z. 648),
  Lösungshinweis (Z. 750)
- `quiz_screen.dart`: `t.sit` (Z. 362 und 593), Fragetext von Fallaufgaben, Lösung in der Chat-Blase

**Neues Widget `PruefText(String text)`**. Es liefert eine `Column` aus Blöcken. Der Text
wird zeilenweise gelesen (`\n`); die Regeln greifen in dieser Reihenfolge:

1. **Leerzeile** → größerer Abstand vor dem nächsten Block (Web: 1,05 em statt 0,6 em).
2. **Tabellenzeile:** enthält „ | “, beginnt mit „| “ oder endet mit „ |“
   (`/\s\|\s|^\|\s|\s\|$/`). Aufeinanderfolgende Tabellenzeilen bilden eine Tabelle.
   - Zellen: `zeile.split('|').map(trim)`. **Leere Zellen bleiben erhalten**, sie halten die Spalte.
   - Spaltenzahl = längste Zeile. Kürzere Zeilen werden **hinter der ersten Zelle** mit
     leeren Zellen aufgefüllt (der Wert rutscht so in die letzte Spalte).
   - **Einzelne Zeile mit einer Zelle > 60 Zeichen:** keine Tabelle, sondern Absatz mit
     „ · “ zwischen den Zellen.
   - **Zahlzelle:** `/^[−–+-]?\s?\(?\s?\d/` und höchstens 32 Zeichen.
   - **Kopfzeile.** Die Tabelle braucht mindestens 2 Zeilen, und die erste Zeile mindestens
     2 nichtleere Zellen. Dann gilt die erste Regel, die zutrifft:
     1. **Eckfeld leer**, alle anderen Zellen der ersten Zeile gefüllt → Kopf. Das gilt auch für
        Zahlen und Skalen, z. B. „ | 2019 | 2020“ oder „ | ++ | + | 0 | −“.
     2. Eine Zelle der ersten Zeile ist eine Zahlzelle → kein Kopf.
     3. **Formular** (mindestens 3 Spalten): In allen späteren Zeilen ist nur die erste Spalte
        beschriftet. Die übrigen Zellen sind leer oder Ankreuzkästchen `☐ □ ○ ◯` → Kopf.
        Beispiele: Checkliste, Qualifikationsmatrix.
     4. Mindestens 3 Spalten, und eine spätere Zeile hat ab Spalte 2 eine Zahlzelle → Kopf.
     5. 2 Spalten, mindestens 3 Zeilen, und alle Werte der zweiten Spalte sind Zahlzellen → Kopf.
   - **Ankreuzkästchen** (`☐` usw.) stehen mittig in `kMuted`.
   - **Spaltenausrichtung:** Eine Spalte ab der zweiten ist rechtsbündig, wenn mindestens
     60 % ihrer gefüllten Zellen Zahlzellen sind. Diese Zellen brechen nicht um. Ausnahme:
     2-spaltige Listen auf dem Handy dürfen umbrechen.
   - **2 Spalten ohne Kopf** = Werteliste („Strecke | 10 km“):
     - Beschriftung in `kInkSoft`
     - Wert w600
   - **Optik:**
     - Rahmen `kLine`, Radius 10.
     - Kopf auf `kSurface2`, Schrift `kPetrolDeep`, w700.
     - Jede zweite Zeile auf `kSurface`.
     - Zellabstand 6 × 11.
     - Ziffern mit `FontFeature.tabularFigures()`.
     - Breite nach Inhalt (höchstens volle Breite). Zu breite Tabellen scrollen waagerecht
       (`SingleChildScrollView(scrollDirection: Axis.horizontal)`).
3. **Aufzählung:** `/^\s*(?:[–•▪■◦]|-(?=\s))\s+/`. Aufeinanderfolgende Zeilen bilden eine
   Liste mit Punkt in `kPetrol`. Das Zeichen selbst entfällt.
4. **Rechenzeile:** enthält „=“ oder „⇒“, ist höchstens 240 Zeichen lang und hat nach
   Entfernen von Klammerinhalten höchstens 5 kleingeschriebene Wörter mit mindestens
   4 Buchstaben (`/(?:^|[\s„])[a-zäöüß]{4,}/`).
   - Aufeinanderfolgende Rechenzeilen bilden einen **Rechenblock**:
     - Fläche `kSurface`, linker Rand 3 dp in `kPetrolLine`, Radius 0/9/9/0
     - Ziffern tabellarisch
   - **Ergebnis hervorheben.** Der Text hinter dem **letzten** „=“ wird w700 in
     `kPetrolDeep` gesetzt, wenn alle folgenden Bedingungen gelten:
     - Er beginnt mit einer Zahl.
     - Er endet vor Komma + Leerzeichen, Semikolon, Klammer oder Zeilenende. Ein Komma
       zwischen Ziffern (Dezimalkomma) gilt nicht als Ende.
     - Er ist höchstens 40 Zeichen lang.
     - Er enthält **kein** Rechenzeichen mit Leerzeichen davor und danach
       (`/\s[+−–·÷×:\/-]\s/`). Dann ist es noch eine Rechnung, kein Ergebnis.
4a. **Hinweis:** `/^(?:Hinweise?(?:\s+(?:für|an|zur|zum)\s+[^:]{2,40})?|Achtung|Beachte|Merke)\s*:\s*/`.
    - Kasten auf `kAmberSoft` mit linkem Rand in `kAmber`.
    - Das Präfix („Hinweis für den Korrektor:“) steht fett in `kAmberInk`.
5. **Beschriftung:** Zeile ohne „=“ und ohne „|“, 2–90 Zeichen, endet auf „:“ → w600.
6. Alles andere ist ein Absatz.

**Inline, in jedem Block:** Punkteangaben in Klammern (`/\((?=[^()]*\bPunkte?\b)[^()]{1,160}\)/`)
werden zur kleinen Marke ohne Klammern:
- Mono 0,74 em
- Schrift `kGoldInk` auf `kGoldSoft`, Rahmen `kGoldLine`
- Radius 6, Umsetzung als `WidgetSpan`

**Testfälle** (aus `assets/data/cases.json`)

| Text | Erwartung |
|---|---|
| `P-OK-20221115`, Aufgabe 3, `sit` | Absatz. Dann drei Wertelisten, je mit einer fetten Beschriftung davor (die zweite mit 3 Zeilen). Kein „|“ sichtbar. |
| `P-MI-20200505`, Aufgabe 2, `sit` | Tabelle mit Kopf „Nr. \| Vorgang \| Dauer in Tagen \| Vorgänger“ und 9 Zeilen. |
| `P-OK-20231121-s10`, `a` | Rechenblock (2 Zeilen, Ergebnis „10%“ fett). Dann Beschriftung „Maßnahmen:“, Liste mit 4 Punkten und die Punkte-Marke. |
| `P-BW-20230504-s0`, `a` | Liste, Absatz, Rechenblock. „BE = 3.000.000 € ÷ 75 · 85 − 3.000.000 €“ **ohne** Hervorhebung, „BE = 400.000 €“ **mit**. |
| `P-OK-20221115-s3`, `a` | Tabelle mit leerem Eckfeld → Kopfzeile „… aus Sicht der Mitarbeiter \| …“. |
| `P-OK-20211116-s0`, `a` | Checkliste als Formular mit Kopf „Prüfpunkt \| Ja \| Nein \| Nicht zutreffend \| Maßnahme \| Termin/verantwortlich“, 21 Zeilen. Danach „Datum:“ und „Unterschrift:“ als Beschriftungen. |
| `P-OK-20251112-s12`, `a` | Bewertungsbogen mit Kopf „ \| ++ \| + \| 0 \| − \| − −“ und mittigen ☐. |
| `P-OK-20260507-s6`, `a` | Kostenvergleich mit Kopf „Kosten pro Jahr \| Diesel-Lkw \| Batterie-Lkw“, 6 Zeilen, Rechnungen in den Zellen. |

**Abnahme**
- In keinem Prüfungstext steht nach dem Rendern ein „ | “.
- Ein Durchlauf über alle 121 Prüfungen verliert kein Zeichen außer den
  Aufzählungszeichen. Web-Prüfung: 5.003 Texte, 169 Tabellen (30 mit Kopf),
  732 Rechenblöcke, 1.799 Listen, 0 Verluste.

---

### B · Rechenweg statt Textfeld (mittel, hoher Nutzen)

**Idee:** Eine Rechenaufgabe wird wie auf dem Prüfungsbogen Zeile für Zeile gelöst:
Bezeichnung, Rechnung, Ergebnis. Jede Zeile rechnet sofort. Ergebnisse früherer Zeilen
lassen sich antippen und einsetzen.

**Speicher:**
- `SharedPreferences`, Schlüssel **`kvm_open_calc`** (wie Web)
- JSON `{ "<stepId>": [ {"l": "Bezeichnung", "f": "Rechnung", "u": "Einheit"}, … ] }`
- Zeilen ohne `l` und ohne `f` werden nicht gespeichert.
- Neu in `answer_store.dart`: `calc(id)`, `setCalc(id, rows)`, `hatCalc(id)`. `hatCalc`
  ist wahr, wenn eine Zeile eine nichtleere Rechnung hat.

**Rechner `rechne(String)`**
- Kein `eval`. Rekursiver Abstieg mit dieser Rangfolge:
  1. Summe
  2. Produkt
  3. Vorzeichen
  4. Potenz `^`
  5. nachgestelltes `%`, `²`, `³`
  6. Zahl, `(…)` oder `√x`
- Zeichen:
  - Zahlen deutsch oder englisch:
    - Enthält die Zahl ein Komma: Punkte sind Tausenderpunkte.
    - Sonst ist `1.234.567` ein Tausenderformat.
    - Sonst ist der Punkt ein Dezimalpunkt.
  - Plus `+`.
  - Minus `- − –`.
  - Mal `* · × ⋅ ∙`, außerdem `x` zwischen Zahl bzw. `)` und Zahl, `(` oder `√`.
  - Geteilt `/ ÷ :`.
- Hinter einem `=` wird nicht weitergelesen.
- Einheiten werden überlesen:
  - erst Einheitenbrüche wie `km/h`, `€/kWh`
  - dann Buchstabenfolgen einschließlich `€ $ °`
- Ergebnis nicht endlich oder Ausdruck unvollständig → ungültig. Anzeige „Rechnung prüfen“ in `kErrInk`.
- **Erweitert in FR-005 A:** Prozent wie auf dem Tischrechner (`200 + 19 %` = 238), π,
  sin/cos/tan in Grad samt Umkehrung, Zeit (`6 h 45 min`), Mal vor π/√/Funktion/`(` darf fehlen.
  Rechner und Rechenweg teilen sich diesen Kern.

**Referenzwerte** (müssen exakt so herauskommen, Web-Stand):

| Eingabe | Einheit | Ergebnis | Zeile als Text |
|---|---|---|---|
| `4.400 ÷ 22` | | 200 | `4.400 ÷ 22 = 200` |
| `30.250 · 6 %` | | 1.815 | `30.250 · 6 % = 1.815` |
| `√(2·7000·120÷(12·0,14))` | | 1.000 | `√(2 · 7.000 · 120 ÷ (12 · 0,14)) = 1.000` |
| `1.5+1` | | 2,5 | `1,5 + 1 = 2,5` |
| `1.500+1` | | 1.501 | `1.500 + 1 = 1.501` |
| `(20+6+4)·2` | | 60 | |
| `5²` / `2^3` | | 25 / 8 | |
| `10 km/h · 2` | | 20 | `10 · 2 = 20` |
| `3 x 4` | | 12 | `3 · 4 = 12` |
| `-5+2` | | −3 | `−5 + 2 = −3` |
| `99.600 / 3.000` | `€` | 33,20 | `99.600 ÷ 3.000 = 33,20 €` |
| `12,5 %` | | 0,125 | |
| `4400/0` | | ungültig | `4400/0` (unverändert) |

**Formatierung**
- `de_DE`, höchstens 4 Nachkommastellen, negatives Vorzeichen als „−“ (U+2212).
- Enthält die Einheit „€“ und das Ergebnis Cent: genau 2 Nachkommastellen.
- Die Rechnung für den Text wird neu gesetzt:
  - Zahlen mit Tausenderpunkt, die eingegebenen Nachkommastellen bleiben.
  - Rechenzeichen mit Leerzeichen: „ + “, „ − “, „ · “, „ ÷ “.
  - Vorzeichen, `^`, `²`, `√` und Klammern ohne Leerzeichen.
  - Prozent als „ %“.

**Zeile als Text:**
- Aufbau: `Bezeichnung: Rechnung = Ergebnis Einheit`. Die Bezeichnung endet immer auf
  genau einen Doppelpunkt.
- Ist die Rechnung nur eine Zahl: `Bezeichnung: Ergebnis Einheit`.
- Beispiel: `Kosten je Auftrag: 4.400 ÷ 22 = 200 €`.

**Ganze Antwort (`antwortText`):**
- Aufbau: Rechenweg-Zeilen, Leerzeile, Freitext.
- Verwendet in:
  - „Deine Antwort“ nach dem Aufdecken
  - KI-Export (`AnswerStore.exportTask`, `_kopieren` Z. 466)
  - der Prüfung „beantwortet“

**Wann offen?**
- Der Rechenweg steht sofort offen, wenn beides gilt:
  - Die Frage verlangt eine Rechnung: `/\b(berechn|errechn|ermittel|kalkulier|rechnerisch|Rechenweg)/i`.
  - Der Lösungshinweis hat eine Zeile mit Ziffer, „=“ und Rechenzeichen.
  - Das trifft auf 435 von 2.030 Teilaufgaben zu.
- Sonst gibt es unter dem Textfeld den Knopf „Rechenweg“, der ihn einblendet.
- Hat eine Teilaufgabe gespeicherte Zeilen, ist er immer offen.
- Ist er offen, heißt das Textfeld „Erläuterung · optional“ und ist kleiner (min. 64 statt 92).

**UI je Zeile** (Web `.rw-row`)
- Handy:
  - Zeile 1: „Z1“, Bezeichnung (Unterstrich-Feld), ✕
  - Zeile 2: Rechnung in voller Breite, Mono 15 w600
  - Zeile 3: Einheit (76 dp) links, Ergebnis rechts („= 20 min“, Mono 15 w700 `kPetrolDeep`)
- Ab 640 dp:
  - Zeile 1: Bezeichnung
  - Zeile 2: Rechnung | Ergebnis | Einheit (72) | ✕
- Tastatur der Rechnung: `TextInputType.numberWithOptions(decimal: true, signed: true)`.
- Enter bzw. „Weiter“ springt in die nächste Zeile oder legt eine neue an.
- **Tastenleiste**, sichtbar solange ein Feld des Rechenwegs den Fokus hat:
  - `+ − · ÷ ( ) % x² √(`
  - danach je frühere Zeile mit gültigem Ergebnis ein Knopf „Z1 = 1.815“, der
    den Wert (ohne Einheit) einsetzt
  - Folgt der Wert direkt auf eine Ziffer, wird „ · “ davor gesetzt.
  - Eingefügt wird an der Schreibmarke.
  - Die Knöpfe dürfen den Fokus nicht aus dem Feld nehmen (`FocusNode` behalten,
    `canRequestFocus:false` an den Tasten).
- Unter den Zeilen: „+ Zeile“ (gestrichelter Rahmen). Eine leere letzte Zeile wird
  genutzt statt eine neue anzuhängen.
- ✕ löscht die Zeile. Die letzte Zeile wird nur geleert.
- Eine Teilaufgabe mit Rechenweg zählt als **beantwortet** (Stepper, Fortschritt, Liste).

**Abnahme:** Die Referenzwerte stimmen. Ein Rechenweg übersteht einen Neustart. Nach
dem Aufdecken steht er als Rechenblock unter „Deine Antwort“, Ergebnisse fett. Im
KI-Export steht er vor dem Freitext.

---

### C · Aufgabenblatt neu (mittel, hoher Nutzen)

Bezug: `aufgabenblatt_screen.dart`. Web: `renderBlatt`, `blTeilHTML`, `blLoesungHTML`.

1. **Mitlaufende Leiste oben** (ersetzt Kopf Z. 192–200 und `_stepper` Z. 239).
   - Umsetzung: `SliverPersistentHeader(pinned: true)` bzw. ein fixer Kopf über dem Scrollbereich.
   - Inhalt: ✕, dann die Aufgaben-Pillen (waagerecht scrollbar; die aktuelle wird in
     die Mitte gescrollt).
   - **Pille** 42 × 42, Radius 11:
     - Nummer w700 14, darunter „24 P“ (Mono 9)
     - Statuspunkt 7 dp oben rechts:
       - Amber = teilweise bearbeitet
       - Grün = alle Teile bearbeitet
       - Petrol = alle aufgedeckt (dazu Fläche `kPetrolSoft`)
     - Aktuelle Pille: gefüllt `kPetrol`, weiße Schrift, Schatten, Statuspunkt mit weißem Ring
   - Darunter der Balken (5 dp) mit zwei Anteilen:
     - aufgedeckt `kPetrol`
     - bearbeitet, aber nicht aufgedeckt `kOk`
   - Rechts daneben Text „**7**/17 Teile · **23** P“. Der Punkteteil erscheint erst
     nach der ersten Bewertung.
   - Bei nur einer Aufgabe (Fallaufgaben) keine Pillen.
2. **Kopf der Aufgabe**
   - Eyebrow „FACH · DATUM“ (Mono 10,5, `kPetrol`), z. B.
     „BETRIEBSWIRTSCHAFTLICHES HANDELN · 4. MAI 2023“. Das Datum ist der Titelteil nach „– “.
   - Titel „AUFGABE 6“: Display 30–40, w700, groß geschrieben.
   - Chips:
     - „17 Punkte“ (petrol)
     - „3 Teilaufgaben“
     - „x von n bearbeitet“ (grün mit ✓, wenn vollständig)
     - „Deine Punkte: p / max“ (gold), sobald bewertet
3. **Ausgangssituation der Prüfung** (einklappbar) nur, wenn `context` **nicht** mit
   „In dieser Prüfung hat jede Aufgabe ihre eigene Ausgangssituation“ beginnt. Das
   betrifft die Basisqualifikationen: Dort ist der Text nur ein Hinweis.
   - Tag „AUSGANGSSITUATION“ (petrol)
   - Titel „Gilt für alle Aufgaben dieser Prüfung“
   - Knopf „Lesen ▾“
   - Inhalt über `PruefText`
4. **Ausgangslage der Aufgabe**
   - Kasten `kSurface` mit Rahmen, Radius 12
   - Label „AUSGANGSLAGE“ (Mono 10, `kMuted`)
   - darunter `PruefText(sit)`, dann die Anlagen (Tabellen und Bilder wie bisher)
5. **Teilaufgabe als eigene Karte**
   - Karte: Radius 14, Schatten `0 8 22 -12 rgba(16,42,50,.18)`.
   - **Linker Statusstreifen** 4 dp: grau offen, grün bearbeitet, petrol aufgedeckt.
   - Kopf:
     - Buchstabe im Kreis (32 dp, Display 17). Grund `kInk`, bearbeitet `kOk`, aufgedeckt `kPetrol`.
     - Daneben „Teilaufgabe a)“ (12,5, `kMuted`), Punkte-Pill (Mono 11, `kPetrolSoft`)
       und ggf. „baut auf a) auf“ (gold)
   - Frage: `PruefText`, Grundschrift w600 15,5. Tabellen darin w400.
   - Antwortbereich: Rechenweg (B), Textfeld und die Knöpfe „👁 Lösung zu a) aufdecken“
     (gefüllt petrol) und ggf. „Rechenweg“.
6. **Nach dem Aufdecken:** zwei Blöcke mit Kopfzeile (Mono 10,5 groß):
   - **„DEINE ANTWORT“**:
     - Rechenweg als Rechenblock, dann Freitext
     - leer: „— leer abgegeben —“ kursiv
   - **„AMTLICHE LÖSUNGSHINWEISE · IHK“**:
     - Kopf auf `kPetrolSoft`, Rahmen `kPetrolLine`
     - Inhalt über `PruefText`, dann Lösungsbild und Lösungstabelle wie bisher
     - Fußzeile „VO-Bezug: … · Punkteverteilung: …“ (11,5, `kMuted`)
7. **Selbstbewertung** (Kasten `kSurface`)
   - Kopf „DEINE PUNKTE“, rechts „6 von 10“ bzw. „noch nicht bewertet“.
   - **Bis 12 Punkte:** durchgehende Knopfleiste mit n+1 gleich breiten Knöpfen (höchstens
     60 dp je Knopf), Höhe 40.
     - gewählt: gefüllt petrol
     - kleinere Werte: `kPetrolSoft` (wirkt wie ein Füllstand)
   - **Über 12 Punkte:** `Slider` 0…max (Teilstriche), darunter „0 · max/2 · max“.
   - Ersetzt die umbrechenden Einzelknöpfe (`_punkteKnopf` Z. 823). Auf dem Handy
     stand die „10“ sonst allein in der zweiten Reihe.
8. **Einstieg:** Wird eine Aufgabe an ihrer **ersten** Teilaufgabe geöffnet, bleibt die
   Seite oben (Ausgangslage sichtbar). Nur bei späteren Teilen wird zu ihnen gescrollt.
9. **Handy:** Solange im Aufgabenblatt ein Eingabefeld den Fokus hat, ist das
   Werkzeug-Dock (FR-002 C) ausgeblendet. Über der Tastatur stehen dann Eingabe und
   Tastenleiste.

**Abnahme:** Handy 390 × 844.
- `P-OK-20221115`, Aufgabe 3: Ausgangslage mit drei Tabellen; a) mit offenem Rechenweg;
  nach dem Aufdecken beide Blöcke; die 11 Punkteknöpfe in einer Reihe.
- `P-MI-20200505`, Aufgabe 2: Die Netzplan-Anlage ist ausfüllbar (FAZ/FEZ/SAZ/SEZ/Puffer).
  Nach dem Aufdecken stehen die amtlichen Werte neben den eigenen.

---

### D · Prüfungsliste (klein bis mittel)

Bezug: `pruefungen_screen.dart` `_kachel` (Z. 199). Web: `render()` im Prüfungs-Modul.

**Karte je Prüfung** (Radius 14, leichter Schatten)
- **Kürzel-Kachel** 40 × 40, Radius 11, weiße Display-Schrift. Das Kürzel kommt aus der ID
  (`P-XX-…`):
  - RE `kPetrol`
  - BW `kAmber`
  - MI `kOk`
  - ZI `kBlue`
  - NT `kViolet` (#6D5AE6)
  - FT und OK `kPlum`
- Daneben Bereich (w700 15) und darunter „7. Mai 2026 · 5 Aufgaben · 13 Teile“.
- Rechts Pill „100 P“.

**Fortschritt** (nur wenn begonnen)
- Balken 6 dp als Verlauf petrol → grün.
- Text „**6**/18 Teile · **18** P“. Teile gelten als bearbeitet mit Text **oder** Rechenweg.

**Hauptknopf**
- „Weiter bei Aufgabe N →“ springt zur ersten unbearbeiteten Teilaufgabe.
- Alles bearbeitet: „Prüfung öffnen“. Nichts bearbeitet: „Prüfung starten“.

**Zweitknopf** „Für KI kopieren“.

**Einleitung:** „**121 Original-Prüfungen** mit amtlichen Lösungshinweisen: Aufgaben wie
auf dem Prüfungsbogen lösen – mit Rechenweg und ausfüllbaren Anlagen –, dann die Lösung
aufdecken und dir selbst Punkte geben.“

---

### E · Startseite mit Lernstand, Lernweg und Erfolgen (mittel bis groß)

Bezug: `home_screen.dart` `build` (Z. 130). Web: `#scrHome`, CSS „Startseite“, JS
`renderHero`, `renderFachGroup`, `erfolgeList`, `renderAktiv`, `renderPruefLast`.

**Grundsatz:** eigene Karten auf `kBg` statt einer langen Liste. Karten: `kPaper`, Rahmen
`kLine`, Radius 16, Schatten wie FR-002. Über jeder Karte ein Gruppentitel: Mono 11,
Großbuchstaben, Buchstabenabstand 1,3, `kMuted`; rechts optional ein Zusatz in `kPetrol`.

**Reihenfolge**

1. **Kopf** ohne Karte:
   - Eyebrow „MEISTER-TRAINER · IHK-PRÜFUNGSVORBEREITUNG“
   - Titel „MEISTER FÜR KRAFTVERKEHR“ (Display 28–46)
   - Untertitel „**3.666 Wissensfragen** · 4 Basisqualifikationen + 1 Fachrichtung ·
     **121** Original-IHK-Prüfungen“ (**ohne** „Fahrschul-Prinzip“)
2. **Lernstand-Karte (Hero)**
   - Karte:
     - Verlauf wie FR-002 B, Radius 20, Schatten `0 22 44 -22 rgba(8,79,88,.75)`
     - zwei weiche Lichtkreise: Weiß 16 % oben rechts, Amber 30 % unten links
   - **Ring** 120 dp (Handy 96):
     - Spur Weiß 16 %, Strich 10, runde Enden
     - Füllung = Prüfungsreife (`overallReife`)
     - Strichfarbe nach Ampel: rot #FF9B85, gelb #FFD28F, grün #8FE3AA; ohne Fortschritt Weiß 50 %
     - In der Mitte „15 %“ (Display 31/25) und „PRÜFUNGSREIF“ (Mono 9)
   - **Ampel**:
     - Punkt 10 dp: rot #E8604A, gelb #F3B53C, grün #46C46F
     - Schwellen: unter 35 % „Grundlagen aufbauen“, unter 70 % „auf gutem Weg“,
       ab 70 % „prüfungsreif“, ohne gesehene Frage „noch nicht begonnen“
     - Kicker „PRÜFUNGSREIFE · {Status}“. Ohne Fortschritt: „Willkommen – leg los“.
   - Titel, Beschreibung und „Jetzt lernen →“ wie FR-002 B.2. Auf dem Handy volle Breite unter Ring und Titel.
   - **Vier Kennzahlen**: gemeistert, gesehen, offen, **Tage in Folge**. Darunter der Fortschrittsbalken.
   - **Lerntage** (neu):
     - Speicher: Schlüssel `kvm_tage`, `{ "<Tagesindex>": Anzahl }`
     - Tagesindex = `floor((jetzt − Zeitzonenversatz) / 86 400 000)`
     - Jede beantwortete Frage zählt +1 (in `recordResult`). Einträge älter als 120 Tage entfallen.
     - Serie: aufeinanderfolgende Tage bis heute. Ist heute noch nichts gelernt, zählt bis gestern.
3. **„DEIN LERNWEG“** – die fünf Fächer als Stationen.
   - Zwischen den Fachnummern (Kreis 40 dp in Fachfarbe, Ring 4 dp in Kartenfarbe)
     läuft eine gestrichelte senkrechte Linie (`kLineStrong`, 6 an / 5 aus).
   - Je Station:
     - Name (w600 14,5)
     - Zeile „● {Ampel-Text} · 107/662 gemeistert“, bei Kraftverkehr zusätzlich „FACHRICHTUNG“-Tag
     - Minibalken 5 dp in der Fachfarbe
     - rechts „24 %“ (Mono 14 w700)
   - Gewählte Station: Fläche `kPetrolSoft`, Rahmen `kPetrolLine`. Der Schalter für die
     Fachrichtung bleibt (FR-001).
   - Hinweis: Im Web waren die Minibalken bisher unsichtbar (fehlendes `display:block`).
     In der App prüfen, dass sie sichtbar sind.
4. **„ÜBEN“** (Zusatz: „Im gewählten Fach · Recht – alle Bereiche“)
   - Themenbereich-Chips. Auf dem Handy **eine waagerecht wischbare Zeile** statt mehrerer Reihen.
   - Moduskarten mit Symbolkachel 40 dp links. Kachelfarben:
     - Training `kPetrol`, Buch-Symbol
     - Schwächen `kAmber`, Zielscheibe
     - Simulation #33474E, Stoppuhr
     - Alle Themen `kPetrolDeep`, Mischen
     - Fallaufgaben `kPlum`, Koffer
5. **„PRÜFEN“**
   - Dunkle Karte:
     - Verlauf 135° #1C3A42 → #10262C, Radius 18
     - Amber-Lichtkreis oben rechts
   - Inhalt:
     - Symbolkachel 48 dp als Amber-Verlauf
     - „ORIGINAL-IHK-PRÜFUNGEN“ (Display 21)
     - Zeile „121 Prüfungen mit amtlichen Lösungshinweisen · Rechenweg und ausfüllbare Anlagen“
   - Darunter, getrennt durch eine Linie in Weiß 12 %, **„ZULETZT GEÖFFNET“**:
     - Fach · Datum und Fortschrittsbalken
     - weißer Knopf „Weiter bei Aufgabe N →“
   - Speicher: Schlüssel `kvm_letzte_pruefung` = `{id, nr}`, gesetzt bei jedem Öffnen einer Aufgabe.
6. **„ERFOLGE“** (Zusatz „5 von 10“)
   - Medaillen 54 dp:
     - verdient: radialer Goldverlauf #FBD88A → #E3A032 → #B96C06, Symbol weiß
     - offen: `kSurface2` mit Rahmen, Symbol `kPh`, darunter ein Fortschrittsbalken
   - Handy: waagerecht wischbar. Ab 560 dp: 5 Spalten.
   - Erfolge werden **aus dem Lernstand berechnet**, nicht gespeichert:

     | Titel | Bedingung |
     |---|---|
     | Erste Schritte | 10 Antworten (Summe `seen`) |
     | Am Ball | 250 Antworten |
     | Vielleser | 1.000 Fragen gesehen |
     | Sattelfest | 100 Fragen gemeistert |
     | Meisterlich | 1.000 Fragen gemeistert |
     | Dranbleiben | 3 Lerntage in Folge |
     | Wochenserie | 7 Lerntage in Folge |
     | Fachprofi | ein Fach mit Reife ≥ 70 % |
     | Prüfungsluft | erste Teilaufgabe einer Original-Prüfung bewertet |
     | Bestanden | ≥ 50 selbst vergebene Punkte in einer Original-Prüfung |
7. **„NACHSCHLAGEN“**: Formelbuch, Kostenwesen, ADR als Kacheln (Tablet 3 Spalten).
8. **„STATISTIK“** (rechts „Zurücksetzen“)
   - Radar und Legende wie bisher
   - **Aktivität · 14 Tage**:
     - 14 Säulen aus `kvm_tage`, Höhe relativ zum Maximum (mindestens 6 dp)
     - leere Tage als 3-dp-Strich
     - gefüllte Säulen als Verlauf `kPetrol` → `kPetrolDeep`
     - Wochentag-Kürzel darunter; heute in `kPetrol` fett
     - rechts im Titel „272 Antworten · 9 Tage“
9. **„KONTO & DARSTELLUNG“**: Anmelden/Sichern und die Darstellungswahl (FR-002 I).

**Abnahme**
- Handy 390 × 844: Ring, Ampel, „Jetzt lernen“ und die Kennzahlen sind ohne Scrollen sichtbar.
- Kraftverkehr abwählen ändert Ring und Lernweg.
- Nach einer beantworteten Frage steht „Tage in Folge“ auf 1 und die heutige Säule ist gefüllt.
- Nach dem Öffnen einer Prüfung erscheint „Zuletzt geöffnet“.

---

### Datenvertrag
- `cases.json`: keine neuen Felder. `tab`/`tabL` sind aus FR-001 bekannt. Neu sind nur
  weitere Einträge.
- **Neue lokale Schlüssel:** `kvm_open_calc`, `kvm_tage`, `kvm_letzte_pruefung`.
  Sie sind nur lokal und laufen, wie `kvm_open_answers`, nicht über den Cloud-Sync.

### Bewusst NICHT übernehmen (nur Web)
- `position: sticky` / `overflow: clip`. In Flutter übernimmt das ein Sliver-Kopf.
- `:has()`-Regel für das Dock. In Flutter über `MediaQuery.viewInsets.bottom > 0`
  bzw. den Fokus lösen.

### Referenz Web-Implementierung (`index.html` auf `claude/ui-design-improvement-my0f66`)

**CSS**
- Startseite: Kommentar „Startseite“ Z. 920
- Texte: „Aufgabentexte: Tabellen …“ Z. 1460
- Aufgabenblatt Z. 1492
- Rechenweg Z. 1665

**JS**
- Renderer:
  - `rtIstRechnung` Z. 3136
  - `rtKopf` Z. 3156
  - `rtTabelle` Z. 3171
  - `rtHTML` Z. 3194
- Rechenweg:
  - `rwTokens` Z. 3260
  - `rwRechne` Z. 3341
  - `rwZeileText` Z. 3379
  - `rwHTML` Z. 3412
  - `rwBinden` Z. 3425
- Bewertung: `scoreHTML` Z. 3512
- Aufgabenblatt:
  - `blStepperHTML` Z. 3801
  - `blFortschrittHTML` Z. 3819
  - `blLoesungHTML` Z. 3888
  - `blRechenteil` Z. 4220
  - `blTeilHTML` Z. 4227
  - `renderBlatt` Z. 4267
- Startseite:
  - `tagZaehlen` Z. 2282
  - `renderFachGroup` Z. 2450
  - `renderHero` Z. 2478
  - `erfolgeListe` Z. 2599
  - `renderAktiv` Z. 2640
  - `renderPruefLast` Z. 2657
- Prüfungsliste: `items.forEach` in `render()` Z. 8452

Zeilennummern: Stand dieses Commits.

---

## FR-004 · Vergleich mit anderen: freiwillige Wochenrangliste

**Status App-Session:** ✅ erledigt (`claude/ui-design-improvement-my0f66`, PR #52, App 1.1.0)
**Web umgesetzt:** ✅ `claude/ui-design-improvement-my0f66` (Commit „Vergleich mit anderen …“)
**Voraussetzungen:**
- Supabase-Login (wie beim Sync)
- einmalig `docs/supabase-rangliste.sql` im Supabase-SQL-Editor (siehe
  `SUPABASE_SETUP.md`, Abschnitt 5)

Fehlt das Skript, zeigen Web und App den Abschnitt nicht. Es gibt dann weder
Fehlermeldung noch leere Karte.

**Priorität:** mittel, nach FR-003 E (Startseite).

### Ziel / Framing
Lernende wollen sehen, wo sie im Vergleich zu anderen stehen. Umgesetzt ist das
datensparsam und nur auf Wunsch:
- **Opt-in:** Man tritt mit einem selbst gewählten Spitznamen bei.
- **Geteilt werden nur:** Spitzname, Prüfungsreife in %, Antworten dieser Woche
  und Lerntage in Folge.
- **Zwei Vergleiche:**
  - eine **Wochenrangliste** nach beantworteten Fragen, jeden Montag neu und damit
    auch für Neue gewinnbar
  - der Anteil der anderen, die bei der **Prüfungsreife** hinter einem liegen
- **Austreten löscht den Eintrag.**

### Server (fertig, nur zur Info)
Die Tabelle `public.rangliste` ist für Clients gesperrt. Alles läuft über vier
RPCs:

| RPC | Rolle | Zweck |
|---|---|---|
| `rangliste_info()` → Zahl | anon, authenticated | Teilnehmende gesamt, für den Hinweis vor dem Login |
| `rangliste_stand(p_woche)` → JSON | authenticated | eigener Stand und Top 10 der Woche |
| `rangliste_melden(p_name, p_reife, p_gemeistert, p_woche, p_antworten, p_serie)` | authenticated | beitreten, Werte melden, Spitzname ändern |
| `rangliste_austreten()` | authenticated | Eintrag löschen |

Die Antwort von `rangliste_stand` enthält diese Felder:

| Feld | Inhalt |
|---|---|
| `dabei` | ob man beigetreten ist |
| `name` | eigener Spitzname |
| `teilnehmende` | Teilnehmende gesamt |
| `reife_vor` | wie viele eine niedrigere Prüfungsreife haben |
| `woche_teilnehmende` | Teilnehmende mit Antworten in dieser Woche |
| `mein_platz` | eigener Platz; `null` ohne Antwort diese Woche |
| `meine_antworten` | eigene Antworten diese Woche |
| `liste` | Top 10: `platz`, `name`, `antworten`, `reife`, `serie`, `ich` |

Gleiche Antwortzahl ergibt denselben Platz. Beispiel: `rangliste_stand('2026-W39')`.

Serverseitig abgesichert:
- Die Werte werden begrenzt.
- Spitznamen sind eindeutig (Groß-/Kleinschreibung zählt nicht) und dürfen nur
  `^[A-Za-zÄÖÜäöüß0-9 _.-]{3,20}$` enthalten.
- Antworten derselben Woche werden nie kleiner. Bei zwei Geräten gilt der
  höhere Stand.

### App (Flutter)
1. **`RanglisteService`** (neu, `lib/services/rangliste_service.dart`)
   - nutzt `Supabase.instance.client.rpc(...)`
   - `Future<int?> info()`
   - `Future<RanglisteStand?> stand()`
   - `Future<String?> melden(String name)`: gibt einen Fehlertext zurück oder `null`
   - `Future<void> austreten()`
   - Jede Exception bzw. jeder PostgREST-Fehler bei `info`/`stand` bedeutet
     „nicht verfügbar“: Der Abschnitt bleibt verborgen.
2. **Werte zum Melden** (identisch zum Web, `vgWerte`)

   | Parameter | Wert |
   |---|---|
   | `p_reife` | `round(overallReife * 100)`, also der Wert im Lernstand-Ring |
   | `p_gemeistert` | Anzahl Fragen mit Box ≥ 3 |
   | `p_woche` | ISO-Woche als `JJJJ-Www` |
   | `p_antworten` | Summe von `kvm_tage` (FR-003 E) von Montag bis heute |
   | `p_serie` | Lerntage in Folge |

   ISO-Woche in Dart:
   ```dart
   String isoWoche(DateTime t) {
     // UTC-Daten: keine Sommerzeit-Sprünge in der Tagesdifferenz
     final d = DateTime.utc(t.year, t.month, t.day)
         .add(Duration(days: 3 - ((t.weekday + 6) % 7)));   // Donnerstag
     final w1 = DateTime.utc(d.year, 1, 4);
     final kw = 1 + ((d.difference(w1).inDays - 3 + ((w1.weekday + 6) % 7)) / 7).round();
     return '${d.year}-W${kw.toString().padLeft(2, '0')}';
   }
   ```
   `DateTime.weekday` beginnt bei Montag = 1. Die Formel oben ist darauf abgestimmt.
   Testwerte:
   - 2026-09-23 → `2026-W39`
   - 2027-01-01 → `2026-W53`
   - 2024-12-30 → `2025-W01`
3. **Melden:** entprellt 4 s nach jeder gespeicherten Antwort, dort, wo auch der
   Sync angestoßen wird. Nur wenn `dabei == true`.
4. **Startseite:** Abschnitt „VERGLEICH“ nach „ERFOLGE“, gleiche Karte wie die übrigen.
   - **Abgemeldet:**
     - Text „Wie stehst du im Vergleich zu anderen? Mit Konto kannst du einer
       freiwilligen **Wochenrangliste** beitreten …“
     - bei `info > 0` zusätzlich „**n** Lernende sind schon dabei.“
     - Knopf „Mit Google anmelden“ (wie im Account-Sheet)
   - **Angemeldet, nicht dabei:**
     - zwei Punkte als Liste (Wochenrangliste · Prüfungsreife)
     - Textfeld „Spitzname, z. B. Lkw_Profi“ (max. 20) und Knopf „Mitmachen“
     - darunter der Hinweis: „Sichtbar für andere sind nur dein Spitzname, deine
       Prüfungsreife, deine Antworten dieser Woche und deine Lerntage in Folge.
       Austreten geht jederzeit – dein Eintrag wird dann gelöscht.“
     - Fehlertexte:
       - `23505` → „Dieser Spitzname ist schon vergeben.“
       - `23514` oder Prüfung vorab → „3–20 Zeichen: Buchstaben, Ziffern, Leerzeichen, _ . -“
       - sonst → „Das hat nicht geklappt – bitte später noch einmal.“
   - **Dabei:**
     - Zwei Kennzahl-Kacheln:
       - „**x %** der anderen liegen bei der Prüfungsreife hinter dir“, mit Balken.
         Bei 0 %: „Noch liegen alle vor dir – jede gemeisterte Frage bringt dich
         nach vorn.“ Allein: „Noch bist du allein …“
       - „**7.** Platz diese Woche von n · m Antworten“. Ohne Antwort diese Woche:
         „Diese Woche noch ohne Antwort – ab der ersten bist du in der Wochenliste.“
     - Liste „WOCHENRANGLISTE · KW 39“ mit Kopfzeile Pl. · Spitzname · Antw. · Reife:
       - Plätze 1–3 als Medaille (Gold/Silber/Bronze, Verläufe wie im Web)
       - eigene Zeile auf `kPetrolSoft` mit „· du“
       - Ist man nicht in den Top 10: „⋯“ und darunter die eigene Zeile
     - Fußzeile „Du bist dabei als **Name**“ mit den Textknöpfen „Spitzname ändern“
       und „Austreten“ (mit Rückfrage)
   - Laden höchstens alle 30 s. Nach Login/Logout sofort.
5. **Datenschutz:** Vor der Freischaltung die Datenschutzerklärung und das
   Play-Datenschutzformular ergänzen: Spitzname und Lernkennzahlen, nur nach
   Beitritt, Zweck „Vergleich“.

### Abnahme
- Ohne SQL-Skript ist kein Vergleichsabschnitt zu sehen, und es gibt keinen Fehler.
- Abgemeldet: Hinweis mit Teilnehmerzahl. Der Knopf startet den Google-Login.
- Beitritt:
  - Ein zu kurzer Name wird abgelehnt.
  - Ein vergebener Name (auch in anderer Schreibweise) ergibt „schon vergeben“.
  - Danach erscheint die Liste mit der eigenen Zeile.
- Nach 10 beantworteten Fragen steigt „Antw.“ in der eigenen Zeile nach spätestens
  4 s + Neuladen.
- Austreten führt zurück zum Beitrittsformular. Der Eintrag ist serverseitig gelöscht.

### Referenz Web-Implementierung (`index.html` auf `claude/ui-design-improvement-my0f66`)
- **HTML:** `#vgKopf` / `#vgBox`, Z. 1940
- **CSS:** Kommentar „Vergleich: freiwillige Wochenrangliste“, Z. 1290
- **JS** im Cloud-Block:

  | Funktion | Zeile |
  |---|---|
  | `isoWoche` | 5364 |
  | `wocheAntworten` | 5371 |
  | `vgWerte` | 5376 |
  | `vgMeldenSpaeter` | 5381 |
  | `vgLaden` | 5388 |
  | `vgZeigen` | 5605 |

- **SQL:** `docs/supabase-rangliste.sql`. Lokal geprüft mit PGlite: Rechte,
  Rangfolge, Wochenwechsel, zwei Geräte, Namensregeln, Austritt, Kontolöschung.

---

## FR-005 · Taschenrechner: rechnet wie ein Prüfungsrechner, mit Verlauf und „Übernehmen“

**Status App-Session:** ✅ erledigt (`claude/ui-design-improvement-my0f66`, PR #52, App 1.1.0)  
Abweichungen App: „Übernehmen ins Formelbuch“ fehlt, weil das Formelbuch als Blatt über dem Rechner liegt. Rechenweg und Rechner teilen sich den Kern `lib/services/rechenkern.dart`.  
**Web umgesetzt:** ✅ `claude/ui-design-improvement-my0f66` (Commit „Taschenrechner …“)
**Priorität:** hoch. Der Rechner hängt an 801 Rechenfragen und an jeder Prüfung.

### Ziel / Framing
Der alte Rechner (Web und `widgets/calculator.dart`) konnte nur Grundrechenarten und hatte Fallen:
- `200 + 19 %` ergab 200,19 statt 238.
- √ und ± wirkten auf die ganze Rechnung statt auf die letzte Zahl.
- Nach „=“ hing eine neue Ziffer am Ergebnis dran (aus „12“ wurde „125“).
- Es fehlten π, Potenzen und Winkel. Die Fragen brauchen sie: π in 16 Fragen,
  sin/cos in 21, dazu Andler- und Barwertformel.
- Es gab keinen Verlauf; Ergebnisse musste man abtippen.
- In der App fehlten sogar Komma, % und √, und der Punkt war das Dezimalzeichen.

Neu ist ein Rechner, der wie ein zugelassener Prüfungsrechner rechnet, deutsche Zahlen
zeigt, sich die letzten Rechnungen merkt und das Ergebnis mit einem Tipp ins
Antwortfeld setzt.

### A) Rechenkern (gemeinsam mit dem Rechenweg aus FR-003)
Rechner und Rechenweg benutzen **einen** Kern `rechne()`. Gegenüber FR-003 kommt dazu:
- **Prozent wie auf dem Tischrechner:** Steht rechts von `+` oder `−` nur ein
  Prozentsatz (Zahl oder Klammer, direkt gefolgt von `%`), ist er ein Anteil des
  Werts davor: `a + b %` = a · (1 + b/100). Sonst gilt `b %` = b/100.
- **π** (auch `pi`).
- **sin, cos, tan in Grad**, dazu die Umkehrung `sin⁻¹ cos⁻¹ tan⁻¹` (auch `arcsin`
  usw.; Ergebnis in Grad).
  - Die Funktion wirkt auf den nächsten Faktor: `sin 30°` oder `sin(30)`.
  - `tan 90` ist ungültig. Werte mit |x| < 10⁻¹² werden 0.
- **Zeit:** `6 h 45` bzw. `6 h 45 min` = 6,75 Stunden. Minuten 0–59, sonst ungültig.
  `45 min` allein bleibt 45 (die Einheit wird überlesen).
- **Das Mal darf fehlen** vor π, √, einer Funktion und `(`: `2π`, `2√9`, `2(3+4)`.
- `rechne()` nimmt Text oder schon zerlegte Zeichen. Der Rechner reicht Zahlen so
  in voller Genauigkeit durch, ohne Umweg über Text.

**Referenzwerte** (Web-Stand; Format wie im Rechenweg, höchstens 4 Nachkommastellen):

| Eingabe | Ergebnis |
|---|---|
| `200 + 19 %` | 238 |
| `238 − 16 %` | 199,92 |
| `1.000 − 10 % − 2 %` | 882 |
| `200 × 19 %` / `38 ÷ 19 %` | 38 / 200 |
| `200 + 3 · 10 %` | 200,3 |
| `(200 + 19 %) · 2` | 476 |
| `2π` | 6,2832 |
| `(60² − 50²) · π ÷ 4` | 863,938 |
| `2√9` / `2(3+4)` | 6 / 14 |
| `9,81 · sin 30°` | 4,905 |
| `tan⁻¹ 0,15` | 8,5308 |
| `arcsin 2` / `tan 90` | ungültig |
| `12.100 ÷ 1,1^2` | 10.000 |
| `-2²` / `(−2)²` | −4 / 4 |
| `10 h − 6 h 45 min` | 3,25 |
| `5 h 75` | ungültig |
| `12 h · 30 €/h` | 360 |

Zeile als Text im Rechenweg:
- `10 h − 6 h 45 min` mit Einheit `h` ergibt `10 − 6 h 45 min = 3,25 h`.
- `cos 30° · 2500` mit Einheit `daN` ergibt `cos 30° · 2.500 = 2.165,0635 daN`.
- `sin⁻¹(0,5)` ergibt `sin⁻¹(0,5) = 30`.

Die Referenzwerte aus FR-003 gelten unverändert weiter.

### B) Eingabe als Zeichenliste
Der Rechner bearbeitet keinen Text, sondern eine Liste von Zeichen:

| Zeichen | Inhalt |
|---|---|
| Zahl | getippte Ziffern („12,5“) oder fester Wert (Ergebnis, Verlaufseintrag) |
| Zeit | Stunden, Minuten (bis zu 2 Ziffern) |
| π | |
| Rechenzeichen | `+ − × ÷ ^`; ein Vorzeichen-Minus ist markiert |
| Klammer | auf / zu |
| Funktion | `√ sin cos tan sin⁻¹ cos⁻¹ tan⁻¹`, öffnet eine Klammer |
| `%`, `²` | nachgestellt |

„Zahl-Ende“ heißt: Zahl, Zeit, π, `)`, `%` oder `²`.

**Tasten:**
- **Ziffer:**
  - Hängt an die gerade getippte Zahl an (höchstens 15 Ziffern; eine „0“ wird ersetzt).
  - Nach einer Zeit ergänzt sie die Minuten.
  - Nach einem anderen Zahl-Ende oder einem festen Wert kommt erst ein `×`.
- **Komma:** nur einmal je Zahl; ohne Zahl davor „0,“.
- **Rechenzeichen:**
  - Ersetzt ein direkt davor stehendes Rechenzeichen.
  - `−` nach `× ÷ ^ (`, nach einer Funktion oder am Anfang ist ein Vorzeichen.
- **`%`, `x²`:** nur hinter einem Zahl-Ende.
- **`(`:** nach einem Zahl-Ende kommt erst ein `×`.
- **`)`:** nur wenn eine Klammer offen ist und davor ein Zahl-Ende steht. Offene
  Klammern schließt der Rechner selbst; die Anzeige zeigt sie blass.
- **√, sin, cos, tan:**
  - Nach „=“ wirken sie auf das Ergebnis.
  - Hinter einem Zahl-Ende wirken sie auf den letzten Operanden (Zahl oder Klammer
    samt `%`/`²`): „16 √“ = 4, „5 + 9 √“ = 8.
  - Sonst beginnen sie eine Funktion: „√(“.
- **`inv`:** schaltet sin/cos/tan für den nächsten Druck auf die Umkehrung.
- **`±`:**
  - Wechselt das Vorzeichen der letzten Zahl.
  - Nach `+` oder `−` mit Klammer: „5 − 9 ±“ wird „5 − (−9)“ = 14.
  - Ein zweites `±` hebt das auf.
- **`h min`:** macht aus der gerade getippten ganzen Zahl die Stunden; die nächsten
  zwei Ziffern sind Minuten. „1 0 h min − 6 h min 4 5“ ergibt „10 h 00 min − 6 h 45 min“.
- **`⌫`:** löscht die letzte Ziffer bzw. das ganze letzte Zeichen (eine Funktion
  samt Klammer). Nach „=“ wirkt es wie C.
- **`C`:** löscht die Rechnung; der Verlauf bleibt.
- **`=`:**
  - Zeigt das Ergebnis; die Rechnung wandert in den Verlauf.
  - Danach beginnen Ziffer, `(` und π eine neue Rechnung.
  - Rechenzeichen, `%` und `²` rechnen mit dem Ergebnis weiter.

**Fehler** (statt des Ergebnisses; die Rechnung bleibt stehen, die Anzeige wackelt kurz):
- Die Rechnung endet offen („5 +“): „Rechnung unvollständig“.
- ÷ 0, √ aus einer negativen Zahl, tan 90°, sin⁻¹ 2: „Nicht definiert“.
- Minuten über 59: „Minuten gehen nur bis 59“.

**Referenz-Tastenfolgen:**

| Tasten | Anzeige |
|---|---|
| `2 0 0 + 1 9 % =` | 238 |
| `1 0 0 0 − 1 0 % − 2 % =` | 882 |
| `1 6 √ =` / `√ 1 6 =` | 4 / 4 |
| `5 + 9 √ =` | 8 |
| `2 π =` | 6,28318530718 |
| `3 0 sin =` | 0,5 |
| `inv tan 1 =` | 45 |
| `1 0 h·min − 6 h·min 4 5 =` | 3,25, Zeitfeld „3 h 15 min“ |
| `5 − 9 ± =` | 14 |
| `1 2 + 3 = × 2 =` | 30 |
| `1 2 + 3 = 7` | 7 (neue Rechnung) |
| `5 + =` | „Rechnung unvollständig“ |

### C) Anzeige
- Dunkles Anzeigefeld wie bisher (`#0F1E23`).
- **Verlauf** oben im Feld:
  - die letzten 25 Rechnungen als „Rechnung = Ergebnis“, die neueste unten
  - 3 Zeilen hoch (Handy: 2), scrollbar
  - Antippen setzt das Ergebnis als festen Wert ein; „Verlauf leeren“ steht ganz oben.
- **Rechnung:**
  - Zahlen mit Tausenderpunkt, Rechenzeichen mit Leerzeichen, „ %“.
  - Zeit als „6 h 45 min“, **nie** „6:45“, denn im Rechenweg ist `:` ein Geteilt-Zeichen.
  - Fehlende Klammern blass. Nach „=“ steht dort „Rechnung =“.
- **Ergebnis:**
  - Live während des Tippens. Ist die Rechnung gerade unvollständig, bleibt der letzte
    gültige Wert blass stehen.
  - Format `de_DE`: bis zu 12 gültige Stellen, ganze Zahlen bis 10¹⁵ vollständig,
    Minus als „−“ (U+2212).
- **Zeitfeld** links neben dem Ergebnis, sobald eine Zeit in der Rechnung steckt:
  „3 h 15 min“ (Minuten gerundet).
- **Speicher:** `SharedPreferences` **`kvm_rechner`** (Web: localStorage, gleicher Schlüssel):
  ```json
  {"T": [Zeichen …], "v": [{"a": "4.400 ÷ 22", "v": 200, "z": false}],
   "fr": true, "l": "4.400 ÷ 22", "mini": false}
  ```
  `v` = Verlauf, `fr` = gerade „=“ gedrückt, `l` = letzte Rechnung, `mini` = eingeklappt.

### D) Übernehmen
- Der Knopf „↩ Übernehmen <Ziel>“ steht unter der Anzeige. Er ist nur sichtbar, wenn
  es ein Ziel und ein gültiges Ergebnis gibt.
- Ziel ist das zuletzt fokussierte Antwortfeld. Ohne Fokus ist es das Ergebnisfeld der
  Rechenfrage.

| Ziel | Beschriftung | eingesetzt wird |
|---|---|---|
| Ergebnisfeld der Rechenfrage | „ins Ergebnisfeld“ | Wert ohne Tausenderpunkt („1234,5“), ersetzt den Inhalt |
| leere Rechenweg-Zeile | „Rechnung in den Rechenweg · Z2“ | die ganze Rechnung („4.400 ÷ 22“); der Rechenweg rechnet sie nach |
| Rechenweg-Zeile mit Inhalt | „in den Rechenweg · Z2“ | Wert mit Tausenderpunkt an der Cursorstelle |
| Textantwort | „in deine Antwort“ | Wert mit Tausenderpunkt an der Cursorstelle |
| Anlagen-Tabelle / Formelbuch | „in die Tabelle“ / „ins Formelbuch“ | Wert ohne Tausenderpunkt |

- Vor dem Wert steht ein Leerzeichen, wenn davor weder Leerraum noch „(“ steht.
- Danach leuchtet das Zielfeld kurz auf und wird über den Rechner gescrollt. Die
  Änderung wird wie eine Eingabe gespeichert.
- **Flutter:** Der öffnende Screen gibt dem Rechner einen Callback
  `onUebernehmen(String wert, String rechnung)` und die Zielbeschreibung mit.
  - Quiz: Ergebnisfeld der Rechenfrage.
  - Aufgabenblatt: aktives Rechenweg- oder Textfeld (FR-003).

### E) Aufbau und Layout
- **Kopf:** Rechner-Symbol, „Taschenrechner“, Einklappen (⌄), ✕.
  - Einklappen blendet die Tasten aus; Antippen der Anzeige klappt wieder auf.
- **Funktionsreihe:** `inv sin cos tan π h min`, 6 gleich breite Tasten, 34 hoch, Mono 13.
  Ist `inv` aktiv, ist die Taste petrol gefüllt und die Tasten heißen sin⁻¹, cos⁻¹, tan⁻¹.
- **Tastenfeld** 5 × 5, 46 hoch, Abstand 6:
  ```
  C   (   )   %   ⌫
  7   8   9   ÷   √
  4   5   6   ×   x²
  1   2   3   −   xʸ
  0   ,   ±   +   =
  ```
  - C und ⌫ in `kAmberInk`.
  - Rechenzeichen in Petrol auf `kSurface2`; √, x², xʸ in Petrol.
  - „=“ petrol gefüllt.
- **Handy:**
  - Unten angedockt über die volle Breite, Ecken oben 16, Tasten 42 hoch, Verlauf 2 Zeilen.
  - Höhe etwa 60 % des Bildschirms.
  - Die Aufgabe darüber bleibt lesbar und scrollbar: in Flutter
    `Scaffold.showBottomSheet` oder ein Overlay, **kein** modales Bottom-Sheet.
- **Tablet/breit:**
  - Schwebendes Fenster, 324 breit, oben rechts, ziehbar.
  - Der Inhalt weicht nach links aus, solange das Fenster nicht verschoben wurde.
- **Hardware-Tastatur** (optional): Ziffern, `+ - * / : x ^ % ( ) , .`, Enter und `=`,
  ⌫, Entf/`c`, `p` (π), `h` (Zeit).

### F) Ergebnisfeld liest Tausenderpunkte
- `quiz_screen.dart` `_parseNum` liest „4.400“ als 4,4.
- Auf `parseDe` aus `calc_kit.dart` umstellen. Das liest „4.400“ = 4400, „1.5“ = 1,5
  und „1.234,5“ richtig.
- Zusätzlich „−“ (U+2212) als Minus akzeptieren. Web: `parseCalcNum`.

### Abnahme
- Alle Referenzwerte aus A und B stimmen.
- Rechenfrage: Rechner öffnen, `12345 ÷ 10 =`, „Übernehmen ins Ergebnisfeld“. Das Feld
  zeigt „1234,5“, und „Antwort prüfen“ ist aktiv.
- Aufgabenblatt: leere Rechenweg-Zeile antippen, `4400 ÷ 22 =`, Übernehmen. Die Zeile
  zeigt „4.400 ÷ 22“ mit „= 200“ und ist gespeichert.
- Handy: Die Frage bleibt über dem Rechner lesbar. Nach dem Übernehmen ist das Feld
  sichtbar.
- Der Verlauf übersteht einen Neustart.
- „4.400“ im Ergebnisfeld zählt als 4400.

### Referenz Web-Implementierung (`index.html` auf `claude/ui-design-improvement-my0f66`)
- **HTML:** `#mCalc`, Z. 2108
- **CSS:** Kommentar „Taschenrechner: Anzeige mit Verlauf …“, Z. 575
- **JS:**

  | Funktion | Zeile |
  |---|---|
  | `rwTokens` (Kern: Zeichen) | 3260 |
  | `rwFunktion` (Winkel, Wurzel) | 3298 |
  | `rwAuswerten` (Kern: Rechnen) | 3316 |
  | `parseCalcNum` | 3630 |
  | `calcDock` (Andocken, Ausweichen) | 6324 |
  | `rkKern` (Zeichenliste → Kern) | 6388 |
  | `rkAusdruck` (Anzeige, Text) | 6421 |
  | `rkFunktion` | 6472 |
  | `rkVorzeichen` | 6482 |
  | `rkZeit` | 6500 |
  | `rkGleich` | 6514 |
  | `rkTaste` | 6528 |
  | `rkZielVon` / `rkUebernehmen` | 6549 / 6572 |
  | `FN_TASTEN` / `TASTEN` | 6593 |
  | `rkZeigen` | 6603 |

Zeilennummern: Stand dieses Commits.

---

## FR-006 · Prüfungstermin und Lernplan

**Status App-Session:** ✅ erledigt (`claude/ui-design-improvement-my0f66`, PR #52, App 1.1.0)  
Abweichungen App: Der Termin wird in einem Blatt eingegeben, nicht in einem Formular in der Karte – so bleibt Start ohne Scrollen.  
**Web umgesetzt:** ✅ `claude/ui-design-improvement-my0f66` (Commit „Prüfungstermin und Lernplan …“)
**Priorität:** hoch. Das Tagesziel ist der tägliche Anlass zum Lernen.

### Ziel / Framing
Lernende tragen ihren IHK-Termin ein. Die Heute-Karte zeigt dann:
- wie viele Tage bleiben
- wie viele Fragen heute dran sind
- ob man bei seinem Tempo rechtzeitig prüfungsreif wird

**Ziel des Plans** ist die Ampel „prüfungsreif“, also 70 % Prüfungsreife wie im Ring
(`ampel()`), erreicht bis zum Tag vor der Prüfung.

### Speicher
`SharedPreferences` **`kvm_pruefung`** (Web: localStorage, gleicher Schlüssel):
```json
{"datum": "2026-11-04", "tag": 20719, "n": 3666, "ziel": 245}
```
- `datum`: Prüfungstag (ISO).
- `tag`: Tagindex, an dem `ziel` festgelegt wurde. Gleiche Zählung wie `kvm_tage`:
  `floor((jetzt − Zeitzonenversatz) / 86 400 000)`.
- `n`: Zahl der aktiven Fragen bei der Festlegung.
- `ziel`: Tagesziel (Fragen).

Der Termin bleibt auf dem Gerät und wird (noch) nicht synchronisiert. Ein Sonderschlüssel
in `progress.data` würde den Merge beider Clients stören.

### Rechnung
Mit N = aktive Fragen, box = Leitner-Box, `MASTER_BOX` = 3:
- `noetig` = max(0, ⌈0,7 · 3 · N − Σ min(box, 3)⌉). Das sind die richtigen Antworten
  bis 70 %.
- `quote`:
  - Trefferquote richtig ÷ (richtig + falsch) über den ganzen Lernstand, begrenzt auf 0,5–0,95
  - unter 30 Antworten: 0,75
- `tage` = Prüfungstag − heute. Heute zählt als Lerntag, der Prüfungstag nicht.
- `ziel` = ⌈noetig ÷ quote ÷ tage⌉.
  - Ist `noetig` = 0: die Zahl der heute fälligen Fragen.
  - Bei `tage` ≤ 0: 0.
  - **Einmal je Tag festlegen:** neu nur, wenn `tag` ≠ heute oder `n` sich geändert hat
    (Fächerwahl), oder wenn der Termin neu gespeichert wird. Sonst schrumpfte das Ziel
    beim Lernen.
- `geschafft` = Antworten heute (`kvm_tage[heute]`).
- `tempo` = Antworten der letzten 7 Tage ohne heute ÷ 7.
- `prognose` = heute + ⌈noetig ÷ (tempo · quote)⌉, nur wenn `noetig` > 0 und `tempo` ≥ 1.

**Referenzfall:** N = 3.666, kein Fortschritt, 42 Tage → `noetig` = 7.699, `ziel` =
⌈7.699 ÷ 0,75 ÷ 42⌉ = **245**.

### Anzeige (Block in der Heute-Karte)
- **Platz:**
  - breit (≥ 900): dritte Spalte der Karte, 250–320 breit
  - sonst: unter „Jetzt lernen“
- **Aussehen:** Fläche weiß 8 %, Rand weiß 17 %, Radius 14, Innenabstand 12/14.

**Zustände:**

| Zustand | Inhalt |
|---|---|
| kein Termin | „Wann ist deine Prüfung?“ · „Trag den Termin ein – die App rechnet dir ein Tagesziel bis zur Prüfungsreife aus.“ · Knopf „Termin eintragen“ |
| Formular | „Prüfungstermin“ · Datumsauswahl (frühestens morgen) · „Speichern“ (hell) · „Entfernen“ (nur mit Termin) · „Abbrechen“ |
| vorbei | „Prüfung vorbei“ · „Deine Prüfung war am Mi., 4. Nov. 2026. Steht ein neuer Termin an?“ · „Neuen Termin eintragen“ |
| heute | „Heute ist Prüfung“ · „Viel Erfolg! Kurz vorher helfen die fälligen Fragen mehr als neuer Stoff.“ |
| morgen / N Tage | Kopf, Tageszielzeile und Statuszeile (siehe unten) |

Fehler im Formular: „Bitte ein Datum wählen.“ / „Der Termin muss in der Zukunft liegen.“

**Kopf:**
- „Noch 42 Tage“ (Barlow Condensed 23, Versalien) + „bis zur Prüfung am Mi., 4. Nov. 2026“
- bei 1 Tag: „Morgen ist Prüfung“ + Datum
- rechts der Link „ändern“

**Tageszielzeile:** „Heute“ · „20 / 142“ (Mono) · Balken (grün `#8FE3AA` auf weiß 18 %) ·
„Fragen“. Nur bei `ziel` > 0.

**Statuszeile:** Ampel-Punkt + Text. Es gilt die erste passende Regel:
1. `noetig` = 0:
   - Ampel grün
   - „Ziel erreicht: 70 % prüfungsreif. Halte den Stand mit den fälligen Fragen.“
   - Ist nichts fällig: „… Heute ist nichts fällig – probier eine Original-Prüfung.“
2. `geschafft` ≥ `ziel`: grün, „Tagesziel geschafft – stark! Morgen geht es weiter.“
3. Prognose vor dem Prüfungstag: grün, „Im Plan: Mit Ø 64 Fragen am Tag bist du am 28. Okt.
   prüfungsreif (70 %).“
4. Prognose am oder nach dem Prüfungstag:
   - Ampel rot bei `ziel` > 120, sonst gelb
   - „Rückstand: Mit Ø 29 Fragen am Tag wärst du erst am 15. Apr. 2027 prüfungsreif. Mit
     dem Tagesziel klappt es bis zur Prüfung.“
5. Ohne Tempo, eingestuft nach `ziel`:
   - bis 60: grün, „Gut machbar“
   - bis 120: gelb, „Sportlich“
   - darüber: rot, „Sehr knapp“
   - Text: „…: Mit 245 Fragen am Tag bist du bis zur Prüfung zu 70 % prüfungsreif.“
- Zusatz bei `noetig` > 0 und `ziel` > 150: „Setz Schwerpunkte, z. B. mit „Schwächen üben“.“
- Datumsformat:
  - kurz „28. Okt.“, mit Jahr, wenn es nicht das laufende ist
  - lang „Mi., 4. Nov. 2026“

### Abnahme
- Termin in 42 Tagen ohne Fortschritt: „Noch 42 Tage“, „Heute 0 / 245“ (bei 3.666 Fragen).
- Drei Antworten später: „Heute 3 / 245“. Das Ziel bleibt.
- Mit Ø 400 Antworten in den letzten 7 Tagen erscheint „Im Plan …“, mit Ø 20 „Rückstand …“.
- Morgen, heute und ein vergangener Termin zeigen den jeweiligen Zustand.
- „Entfernen“ führt zurück zu „Wann ist deine Prüfung?“.

### Referenz Web-Implementierung (`index.html` auf `claude/ui-design-improvement-my0f66`)
- **HTML:** `#planBox` in `.hero-main`, Z. 1846
- **CSS:** Kommentar „Prüfungstermin und Lernplan: eigener Block …“, Z. 972
- **JS:**
  - Block-Kommentar „Prüfungstermin und Lernplan“, Z. 2493
  - `planRechnen`, Z. 2508
  - `renderPlan`, Z. 2524 (aufgerufen am Ende von `renderHero`)

Zeilennummern: Stand dieses Commits.

---

## FR-007 · Prüfung unter Echtbedingungen

**Status App-Session:** ✅ erledigt (`claude/ui-design-improvement-my0f66`, PR #52, App 1.1.0)
**Web umgesetzt:** ✅ `claude/ui-design-improvement-my0f66` (Commit „Prüfung unter Echtbedingungen …“)
**Voraussetzung:** Aufgabenblatt aus FR-003.

### Ziel / Framing
Eine Original-Prüfung am Stück schreiben, wie bei der IHK:
- mit Uhr über die echte Bearbeitungszeit
- ohne Blick in die Lösungen
- danach Selbstbewertung, Note und Bearbeitungszeit

Die bisherige Simulation nutzt Übungsfragen. Die echte schriftliche Prüfung besteht aber
aus Situationsaufgaben.

### Bearbeitungszeit
- Steht im Text der Ausgangssituation „Bearbeitungszeit N Minuten“, gilt N.
  Kraftverkehr (`P-OK`, `P-FT`): 180.
- Sonst Basisqualifikationen: 90 Minuten, `P-NT-…` (Naturwissenschaften): 60 Minuten.

### Speicher
- **`kvm_echt`**: `{"id": "P-NT-20150429", "start": <ms>, "min": 60, "ende": <ms>|fehlt, "zeitUm": true|fehlt}`
  - Es gibt immer nur einen Durchgang.
  - Die Uhr rechnet ab `start`. Sie läuft also weiter, wenn man die Prüfung verlässt
    oder die App neu startet, wie in der echten Prüfung.
- **`kvm_echt_verlauf`**: Liste (höchstens 40) von
  `{"id", "tag", "min", "dauer": <ms>, "pkt", "max", "note"}`. `tag` wie in `kvm_tage`.
  **Seit FR-014** stehen die Durchgänge in `kvm_pruef_erg` (mit `echt: 1`); der alte Verlauf
  wird einmalig übernommen und nicht mehr geschrieben.

### Start (Prüfungsliste)
- Neuer Knopf je Prüfung: Uhr-Symbol + „Unter Prüfungsbedingungen · 90 min“.
- Läuft für diese Prüfung schon ein Durchgang, geht es dort weiter.
- Läuft ein Durchgang einer anderen Prüfung, fragt die App: „Es läuft noch eine andere
  Prüfung unter Prüfungsbedingungen. Diesen Durchgang beenden und die neue Prüfung starten?“
- Gibt es zu dieser Prüfung gespeicherte Antworten, Rechenwege, Tabelleneinträge oder
  Punkte, fragt die App: „Für diese Prüfung sind schon Antworten gespeichert. Unter
  Prüfungsbedingungen startest du mit leeren Blättern – die bisherigen Antworten und Punkte
  dieser Prüfung werden gelöscht.“ Bei Ja werden sie gelöscht.
  - Tabelleneinträge sind alle Schlüssel, die mit `<stepId>#` beginnen.
- Danach wird `kvm_echt` gesetzt und das Aufgabenblatt bei Aufgabe 1 geöffnet.

### Während der Prüfung
- **Leiste oben:**
  - Uhr (Mono, Pillenform wie der Simulations-Timer): `1:29:45`, unter einer Stunde `29:45`.
  - Ab 10 Minuten Restzeit rot (`.low`).
  - Daneben der Knopf „Abgeben“ (petrol).
- **Band unter dem Kopf:** „Unter Prüfungsbedingungen: 1 h 30 min Bearbeitungszeit,
  Lösungen erst nach der Abgabe. Die Uhr läuft weiter, auch wenn du die Prüfung verlässt.“
- **Gesperrt:**
  - „Lösung aufdecken“ je Teilaufgabe und „Alle Lösungen aufdecken“ im Fuß
  - Zwischenergebnisse aus früheren Teilen (gibt es ohnehin erst nach dem Aufdecken)
- Auf der letzten Aufgabe heißt der Hauptknopf „Abgeben“ statt „Zum Ergebnis →“.
- Rechner, Rechenblatt und Formelbuch bleiben nutzbar.
- **Verlassen (✕):** Nachfrage „Prüfung verlassen? Die Uhr läuft weiter – wie in der
  echten Prüfung. Über die Prüfungsliste geht es weiter.“

### Abgabe
- **Von Hand:** „Jetzt abgeben?“, bei leeren Teilen mit „N Teilaufgaben sind noch leer.“,
  dazu „Danach siehst du die Lösungen und bewertest dich selbst.“
- **Automatisch**, wenn die Uhr 0 erreicht, auch beim Wiederöffnen nach Ablauf. Dann wird
  `zeitUm` gesetzt.
- **Danach:**
  - `ende` = min(jetzt, start + min).
  - Alle Teilaufgaben sind aufgedeckt, und es geht zurück zu Aufgabe 1.
  - Die Uhr zeigt die Bearbeitungszeit („1 h 12 min“); „Abgeben“ verschwindet.
- **Band (grün):**
  - „Abgegeben nach 1 h 12 min.“ bzw. „Zeit abgelaufen – deine Antworten sind abgegeben.“
  - dazu: „Sieh dir jetzt die Lösungen an und vergib dir je Teilaufgabe Punkte. Danach
    „Zum Ergebnis“ – mit Note und Bearbeitungszeit.“
- **Ergebnis:**
  - Die Zeile bekommt „ · Bearbeitungszeit 1 h 12 min von 1 h 30 min“, bei Ablauf mit
    „ (Zeit abgelaufen)“.
  - Ein Eintrag geht nach `kvm_echt_verlauf`, danach wird `kvm_echt` gelöscht.

### Prüfungsliste
| Zustand | Hauptknopf |
|---|---|
| Durchgang läuft | Uhr + „Läuft · noch 45 min – weiter →“ (nach Ablauf: „Zeit abgelaufen – auswerten →“) |
| abgegeben, noch nicht ausgewertet | „Abgegeben – jetzt auswerten →“ |
| sonst | wie bisher + „Unter Prüfungsbedingungen · N min“ |

Unter den Knöpfen steht der letzte Durchgang: „Zuletzt unter Prüfungsbedingungen: 64 von
100 P · Note 3 · 2 h 37 min · am 4. Sept.“

### Abnahme
- NT-Prüfung unter Prüfungsbedingungen starten:
  - Die Uhr zeigt `1:00:00` bzw. `59:xx`.
  - Es gibt keine Aufdecken-Knöpfe.
- Antwort schreiben, verlassen, über die Liste fortsetzen: Antwort und Uhr sind noch da.
- `start` 61 Minuten zurückstellen:
  - Die Prüfung wird automatisch abgegeben („Zeit abgelaufen“), die Lösungen sind offen.
  - Das Ergebnis zeigt „Bearbeitungszeit 1 h von 1 h (Zeit abgelaufen)“.
- Neuer Durchgang mit gespeicherten Antworten: Nachfrage, danach leere Blätter.
- Normales Öffnen der Prüfung: keine Uhr, Aufdecken wie bisher.

### Referenz Web-Implementierung (`index.html` auf `claude/ui-design-improvement-my0f66`)
- **HTML:**
  - Uhr und „Abgeben“ in `.bl-bar`, Z. 2035
  - Band `#blEcht`, Z. 2047
- **CSS:** Kommentar „Prüfung unter Echtbedingungen: Uhr und Abgabe …“, Z. 1603
- **JS:**
  - Block-Kommentar „Prüfung unter Echtbedingungen“, Z. 4588
  - `echtUhr`, Z. 4620
  - `echtAbgeben`, Z. 4641
  - `KVM_startEcht`, Z. 4655
  - `KVM_echtInfo`, Z. 4671
  - Ergebnis in `finishRound`, Z. 5049
  - Prüfungsliste, Z. 8462

Zeilennummern: Stand dieses Commits.

---

## FR-008 · Fehler melden

**Status App-Session:** ✅ erledigt (`claude/ui-design-improvement-my0f66`, PR #52, App 1.1.0)
**Web umgesetzt:** ✅ `claude/ui-design-improvement-my0f66` (Commit „Fehler melden …“)
**Voraussetzung:** einmalig `docs/supabase-meldungen.sql` im Supabase-SQL-Editor
(siehe `SUPABASE_SETUP.md`, Abschnitt 6). Fehlt das Skript, zeigen Web und App keinen Knopf.

### Ziel / Framing
Viele Texte stammen per OCR aus PDFs. Lernende finden Fehler schneller als jede
Prüfroutine. Ein unauffälliger Knopf an jeder Frage macht aus ihnen Mitprüfende. Melden
geht auch ohne Konto.

### Datenbank (Skript `docs/supabase-meldungen.sql`)
- **Tabelle `meldungen`:** `id`, `frage` (≤ 80), `art` (siehe unten), `text` (≤ 1.000),
  `kontext` (jsonb, ≤ 2 kB), `quelle` (`web` | `app`), `user_id` (nur bei Anmeldung),
  `status` (`neu` | `erledigt` | `abgelehnt`), `created_at`.
- **Kein Client-Zugriff auf die Tabelle.** Es gibt zwei RPCs, beide für `anon` und
  `authenticated`:
  - `meldungen_bereit()` → `true`. Nur zum Prüfen, ob Melden eingerichtet ist.
  - `meldung_senden(p_frage, p_art, p_text, p_kontext, p_quelle)`.
- **Bremse:** 50 je Konto und Tag, 300 je Stunde insgesamt. Überschreitung:
  Fehlermeldung mit „zu viele Meldungen“.
- Lokal mit PGlite geprüft (17 Fälle): Rechte, Kürzen, Art-Prüfung, Kontextgröße,
  Bremse, Kontolöschung (Meldung bleibt ohne Konto).

### Knopf
- **Quiz:** in der Metazeile rechts (neben Fragetyp und Themenbereich).
- **Aufgabenblatt:** im Kopf jeder Teilaufgabe rechts.
- **Aussehen:** Fähnchen 13 + „Fehler?“, 12 w600 in `kMuted`, ohne Rahmen.
  - Schon gemeldet: „Gemeldet ✓“ in `kOkInk`.
  - Gemerkt wird das in `SharedPreferences` **`kvm_gemeldet`** = `{"<id>": <ms>}`.
- Sichtbar erst, wenn `meldungen_bereit()` beim Start `true` liefert.

### Dialog
- **Handy:** Blatt von unten, Höhe nach Inhalt. **Breit:** Dialog mit 480 Breite.
- **Titel** „Fehler melden“. Darunter ein Bezugskasten: Nummer in Mono, dann „ · “ und die
  ersten 160 Zeichen der Frage (dahinter „ …“, wenn gekürzt).
- **„Was stimmt nicht?“:** fünf Auswahl-Chips (Radiogruppe, gewählt = petrol gefüllt):

  | Chip | `art` |
  |---|---|
  | Text unleserlich oder Tippfehler | `text` |
  | Lösung falsch | `loesung` |
  | Rechnung oder Zahl falsch | `rechnung` |
  | Tabelle oder Anlage fehlt | `anlage` |
  | Sonstiges | `sonstiges` |

- **„Beschreibung · optional“:** Textfeld, höchstens 1.000 Zeichen, Platzhalter „Was genau
  stimmt nicht? Gern mit der richtigen Angabe.“
- **Hinweis:** „Gesendet werden die Fragennummer, deine Angaben und – falls du angemeldet
  bist – dein Konto für Rückfragen.“
- **„Meldung senden“:** erst aktiv, wenn eine Art gewählt ist. Beim Senden „Wird gesendet …“.
- **Erfolg:**
  - „Danke! Deine Meldung ist angekommen.“ (grün), Knopf „Gesendet ✓“
  - nach 1,4 s schließt der Dialog
  - alle Knöpfe dieser Frage zeigen „Gemeldet ✓“
- **Fehler:**
  - bei der Bremse: „Gerade gehen zu viele Meldungen ein – bitte später noch einmal.“
  - sonst: „Senden hat nicht geklappt. Bist du online? Bitte noch einmal versuchen.“
  - der Knopf ist wieder aktiv
- **Kontext (`p_kontext`):**
  - `{"modus": <Bildschirm>, "fach": <f>, "bereich": <sub, ≤ 80>, "auszug": <160 Zeichen>}`
  - App: `modus` = `quiz` | `blatt`, `p_quelle` = `app`

### Abnahme
- Ohne Skript ist kein Knopf zu sehen.
- Mit Skript, Quiz:
  - „Fehler?“ öffnet den Dialog mit Nummer und Auszug.
  - Ohne Art lässt sich nichts senden.
  - Mit Art und Text kommt eine Zeile in `meldungen` an, der Knopf zeigt „Gemeldet ✓“.
- Aufgabenblatt: Jede Teilaufgabe hat einen Knopf; der Dialog zeigt die Nummer der
  Teilaufgabe.
- Nach 51 Meldungen desselben Kontos an einem Tag erscheint der Hinweis zur Bremse.

### Referenz Web-Implementierung (`index.html` auf `claude/ui-design-improvement-my0f66`)
- **HTML:**
  - Knopf `#qMelden`, Z. 1990
  - Dialog `#mMelden`, Z. 2125
- **CSS:** Kommentar „Fehler melden: unauffälliger Knopf …“, Z. 546
- **JS:**
  - `meldenKnopfHTML` (Aufgabenblatt), Z. 4582
  - Block „Fehler melden“ im Cloud-Teil, Z. 5292
  - `mdOeffnen`, Z. 5303
  - Senden, Z. 5329
  - Bereitschaft, Z. 5343
- **SQL:** `docs/supabase-meldungen.sql`

Zeilennummern: Stand dieses Commits.

---

## FR-009 · Lern-Erinnerung

**Status App-Session:** ✅ erledigt (`claude/ui-design-improvement-my0f66`, PR #52, App 1.1.0)  
Abweichungen App: Ohne `flutter_timezone`: Die Zeitpunkte sind fest geplant, die Sommerzeit kommt aus der Gerätezeit. Nach dem Prüfungstag gibt es keine Erinnerungen mehr. Auf dem Gerät ist das noch nicht abgenommen.  
**Web umgesetzt:** ✅ als Kalendereintrag (Commit „Lern-Erinnerung …“). Die Push-Mitteilung
gibt es nur in der App.
**Priorität:** mittel. Sie hält die Serie („Tage in Folge“) am Leben.

### Ziel / Framing
Eine tägliche Mitteilung zur selbst gewählten Uhrzeit, damit die Lernserie nicht reißt.
- Gelernt wurde heute schon: keine Mitteilung.
- Kein Server nötig, alles läuft als lokale Mitteilung auf dem Gerät.

### App: Einstellungen
- **Wo:** in „Konto & Einstellungen“ (Web: gleicher Abschnitt) eine Zeile
  „Lern-Erinnerung“ mit Schalter und Uhrzeit (Standard 19:00, Schritte 5 min).
- **Speicher:** `SharedPreferences` **`kvm_erinnerung`** = `{"an": true, "zeit": "19:00"}`.
  Web nutzt denselben Schlüssel nur für die Uhrzeit.
- **Einschalten:**
  - Unter Android 13+ Berechtigung `POST_NOTIFICATIONS` anfragen.
  - Bei Ablehnung bleibt der Schalter aus. Hinweis: „Mitteilungen sind für die App
    ausgeschaltet – in den Systemeinstellungen erlauben.“
- **Ausschalten** entfernt alle geplanten Erinnerungen.

### App: Technik
- **Pakete:** `flutter_local_notifications`, `timezone`, `flutter_timezone` (lokale Zeitzone).
- **Android-Manifest:**
  - `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`
  - die Receiver von `flutter_local_notifications` (`ScheduledNotificationReceiver`,
    `ScheduledNotificationBootReceiver`)
  - **Keine exakten Alarme:** `AndroidScheduleMode.inexactAllowWhileIdle`. Eine Viertelstunde
    Spielraum ist in Ordnung.
- **Kanal:** `lernen`, Name „Lern-Erinnerung“, Wichtigkeit Standard.
- **Planen statt Wiederholen:** Es gibt keine tägliche Wiederholung, denn die könnte „heute
  schon gelernt“ nicht berücksichtigen. Stattdessen werden die nächsten 7 Tage einzeln geplant
  (IDs 7001–7007):
  - **Tag 0 = heute:** nur wenn heute noch nichts beantwortet wurde (`kvm_tage[heute]` fehlt)
    und die Uhrzeit noch nicht vorbei ist.
  - **Tage 1–6:** immer, außer nach dem Prüfungstermin (FR-006).
- **Neu planen:** beim App-Start, beim Zurückkehren in den Vordergrund, nach der ersten
  beantworteten Frage des Tages und nach jeder Änderung der Einstellung. Jeweils vorher alle
  IDs 7001–7007 löschen.
- Antippen öffnet die Startseite.

### App: Texte
- **Titel:** „Zeit zum Lernen“
- **Text für heute** (erste passende Zeile):
  1. Lernplan aktiv (FR-006) und Tagesziel > 0: „Heute dran: 58 Fragen bis zur Prüfung am 4. Nov.“
  2. Serie ≥ 2: „Deine Serie: 6 Tage – ein paar Fragen, und sie hält.“
  3. Fällige Fragen > 0: „12 Fragen sind heute fällig – 10 Minuten reichen.“
  4. Sonst: „Ein paar Fragen zwischendurch halten dein Wissen frisch.“
- **Text für die Folgetage** (beim Planen unbekannt, deshalb allgemein): „Kurz reinschauen: Die
  fälligen Fragen warten, und deine Serie hält.“

### Web: Kalendereintrag
Ohne Server gibt es im Browser keine verlässlichen Push-Mitteilungen. Die Web-App bietet
stattdessen **„In den Kalender“**:
- Eine `.ics`-Datei mit einem täglichen Termin (20 min) zur gewählten Uhrzeit und einer
  Erinnerung zum Beginn (`VALARM`, `TRIGGER:PT0M`).
- **Zeiten:** schwebende Ortszeit, ohne Zeitzone. So zeigt jeder Kalender den Termin in
  seiner Zone.
  - Beginn: heute, wenn die Uhrzeit noch kommt, sonst morgen.
  - Mit Prüfungstermin endet die Reihe am Tag davor (`UNTIL=…T235959`), sofern das nach dem
    Beginn liegt.
- **Format:** Zeilen mit CRLF und auf 75 Byte gefaltet, Text maskiert (`\\ \; \, \n`).
- **Dateiname:** `lern-erinnerung.ics`. Danach steht unter der Zeile: „Kalendereintrag
  erstellt: täglich um 07:30 Uhr. Öffne die Datei, um ihn in deinen Kalender zu übernehmen.“

### Abnahme (App)
- Einschalten, Zeit auf in zwei Minuten stellen: Die Mitteilung kommt.
- Eine Frage beantworten, Zeit wieder auf in zwei Minuten stellen: keine Mitteilung heute,
  aber für morgen geplant.
- Ausschalten: keine geplanten Mitteilungen mehr (`pendingNotificationRequests` leer).
- Neustart des Geräts: Die geplanten Erinnerungen bleiben.

### Referenz Web-Implementierung (`index.html` auf `claude/ui-design-improvement-my0f66`)
- **HTML:** Zeile „Lern-Erinnerung“ (`#erinnZeit`, `#erinnIcs`), Z. 1967
- **CSS:** Kommentar „Lern-Erinnerung: Uhrzeit + Kalendereintrag“, Z. 440
- **JS:**
  - Block-Kommentar „Lern-Erinnerung (Web)“, Z. 4531
  - `erIcs`, Z. 4544

Zeilennummern: Stand dieses Commits.

---

## FR-010 · Lerngruppen mit Einladungscode

**Status App-Session:** ✅ erledigt (`claude/ui-design-improvement-my0f66`, PR #52, App 1.1.0)
**Web umgesetzt:** ✅ `claude/ui-design-improvement-my0f66` (Commit „Lerngruppen …“)
**Voraussetzungen:**
- FR-004 (Wochenrangliste) umgesetzt
- einmalig `docs/supabase-gruppen.sql` **nach** `docs/supabase-rangliste.sql` (siehe
  `SUPABASE_SETUP.md`, Abschnitt 7)

Fehlt das Skript, sieht die Rangliste aus wie bisher.

### Ziel / Framing
Lernende eines Meisterkurses wollen sich untereinander vergleichen, nicht mit ganz
Deutschland. Dafür gibt es eine private Rangliste je Gruppe.
- Beitritt per 6-stelligem Code oder Einladungslink.
- Sichtbar ist dasselbe wie in der großen Rangliste.
- Später denkbar: eine Übersicht für Lehrkräfte bzw. ein Angebot an Bildungsträger.

### Datenbank (RPCs, alle nur für `authenticated`)
| RPC | Ergebnis |
|---|---|
| `gruppe_gruenden(p_name)` | `{id, code, name}`. Der Name wird getrimmt, Leerraum zusammengezogen, 3–40 Zeichen. |
| `gruppe_beitreten(p_code)` | `{id, code, name}`. Groß-/Kleinschreibung und Leerzeichen egal; schon Mitglied → dieselbe Antwort. |
| `gruppe_verlassen(p_gruppe)` | – |
| `gruppen_meine()` | `[{id, code, name, mitglieder, leitung}]`, in Beitrittsreihenfolge |
| `gruppe_stand(p_gruppe, p_woche)` | `{id, name, code, leitung, mitglieder, liste:[{platz, name, antworten, reife, serie, ich}]}`, nur für Mitglieder, sonst `null` |

- **In `gruppe_stand`:**
  - Alle Mitglieder stehen in der Liste, auch ohne Antworten.
  - Antworten aus einer anderen Woche zählen 0.
  - Rang nach Antworten, bei Gleichstand der Name.
- **Fehlercodes → Text:**

  | Code | Text |
  |---|---|
  | `P0002` | „Keine Gruppe mit diesem Code gefunden.“ |
  | `P0003` | „Tritt erst der Rangliste bei.“ |
  | `P0004` | „Du bist schon in 5 Gruppen – verlasse zuerst eine.“ |
  | `P0005` | „Die Gruppe ist voll (200 Mitglieder).“ |
  | `23514` | „Der Gruppenname braucht 3–40 Zeichen.“ |
  | sonst | „Das hat nicht geklappt – bitte später noch einmal.“ |

- **Serverseitig:**
  - Codes aus `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`
  - falsche Codes kosten 0,5 s
  - höchstens 5 Gruppen je Person, 200 Mitglieder je Gruppe
  - Aufräumen per Trigger (Rangliste verlassen oder Konto gelöscht → raus aus allen Gruppen;
    leere Gruppe weg; neue Leitung)
- Lokal mit PGlite geprüft, 20 Fälle.

### UI (im Vergleichsabschnitt, nur mit Rangliste und Skript)
- **Reiter über der Liste** (waagerecht scrollbar, Pillenform):
  - „Alle“ (die große Wochenrangliste), dann je Gruppe ihr Name, zuletzt „+ Gruppe“
    (gestrichelt)
  - gewählt: petrol gefüllt
- **Gruppenansicht:**
  - Überschrift „Meisterkurs IHK Köln · 4 Mitglieder · KW 39“, darunter die Liste wie in
    FR-004 (Medaillen, eigene Zeile markiert).
  - Allein in der Gruppe: „Noch bist du allein in der Gruppe. Lade die anderen aus deinem Kurs
    mit dem Code ein.“
  - Fuß: „Code **ABCDEF**“ (Mono, gesperrt), Knopf „Einladen“, leiser Knopf „Gruppe verlassen“
    (Nachfrage: „Gruppe verlassen? Du kannst später mit dem Code wieder beitreten.“).
- **„Einladen“:**
  - Teilen-Dialog des Systems: Titel „Lerngruppe <Name>“, Text „Lerngruppe „<Name>“ im
    Meister-Trainer – lern mit! Code: <Code>“, Link `<Web-Adresse>#gruppe=<Code>`.
  - Ohne Teilen-Dialog in die Zwischenablage, mit der Rückmeldung „Einladung kopiert –
    einfach in euren Chat einfügen.“
- **„+ Gruppe“:** zwei kleine Formulare untereinander:
  - „Mit Code beitreten“: Feld, Großbuchstaben, vorbelegt mit einer offenen Einladung;
    Knopf „Beitreten“
  - „Neue Gruppe gründen“: Feld mit Platzhalter „Name, z. B. Meisterkurs Herbst 2026“;
    Knopf „Gründen“
  - darunter Fehlerzeile, Hinweis und „Abbrechen“
  - Nach Erfolg ist die neue Gruppe gewählt.
- **Einladungslink:**
  - Beim Start `#gruppe=<6 Zeichen>` aus der Adresse lesen, groß schreiben und in
    **`kvm_einladung`** merken. Der Google-Login kehrt ohne `#` zurück, deshalb der Speicher.
  - Dann den `#`-Teil entfernen (`history.replaceState`).
  - App: Deep Link `…/#gruppe=` bzw. App-Link, sonst manuelle Eingabe.
  - **Abgemeldet:** Hinweis „Du wurdest in eine Lerngruppe eingeladen. Melde dich an und mach
    bei der Rangliste mit – dann kannst du beitreten.“
  - **Angemeldet, nicht in der Rangliste:** Hinweis „… Nach dem Mitmachen kannst du beitreten.“
  - **In der Rangliste:** Band (Bernstein) „Du wurdest in eine Lerngruppe eingeladen
    (Code ABCDEF).“ mit „Beitreten“ und „Nein danke“. Beides löscht `kvm_einladung`.
- Die Einführung vor dem Beitritt zur Rangliste nennt als dritten Punkt „auf Wunsch
  Lerngruppen mit deinem Kurs – per Code“.

### Abnahme
- Ohne Skript: keine Reiter, die Rangliste wie bisher.
- „+ Gruppe“ → Name „ab“ → Fehlertext.
- Gründen mit „ Meisterkurs Herbst 2026 “: Reiter „Meisterkurs Herbst 2026“ gewählt,
  „1 Mitglied“, Code sichtbar.
- „Einladen“ teilt bzw. kopiert Text und Link mit dem Code.
- Link `#gruppe=abcdef` öffnen: Band mit Code ABCDEF → „Beitreten“ → Reiter der Gruppe,
  Liste sortiert, Einladung gelöscht.
- Falscher Code → „Keine Gruppe mit diesem Code gefunden.“
- Verlassen → zurück zu „Alle“, der Reiter ist weg.

### Referenz Web-Implementierung (`index.html` auf `claude/ui-design-improvement-my0f66`)
- **Zustand und Einladungslink** im Vergleichsblock, Z. 5352
- **CSS:** Kommentar „Lerngruppen: Reiter über der Liste …“, Z. 1332
- **JS:**
  - Block-Kommentar „Lerngruppen: private Rangliste per Code“, Z. 5414
  - `grLaden`, Z. 5418
  - `grTabsHTML`, Z. 5443
  - `grFormHTML`, Z. 5452
  - `grAnsichtHTML`, Z. 5464
  - `grBinden`, Z. 5494
- **SQL:** `docs/supabase-gruppen.sql`

Zeilennummern: Stand dieses Commits.

---

## FR-011 · Mündliche Prüfung üben (Fachgespräch)

**Status App-Session:** ✅ erledigt (`claude/ui-design-improvement-my0f66`, PR #52, App 1.1.0)  
Abweichungen App: „Neue Runde“ und „Nur Fehler wiederholen“ bleiben im mündlichen Modus. Im mündlichen Üben gibt es keine Werbung. Vorlesen und Diktat sind noch nicht auf dem Gerät abgenommen.  
**Web umgesetzt:** ✅ `claude/ui-design-improvement-my0f66` (Commit „Mündlich üben …“)
**Voraussetzung:** Sprachausgabe/-erkennung der Plattform. Die App hat schon
`voice_service.dart` für A/B/C/D.

### Ziel / Framing
Zur Meisterprüfung gehören das situationsbezogene Fachgespräch und die mündliche
Ergänzungsprüfung. Geübt wird hier das freie Antworten in ganzen Sätzen:
- Die Frage wird vorgelesen.
- Man antwortet frei per Sprache.
- Danach kommen die Musterlösung und die Begriffe daraus, die in der Antwort vorkamen,
  als Hilfe, nicht als Bewertung.
- Zum Schluss bewertet man sich selbst.

### Einstieg
- **Modus-Karte** im Übungsbereich (je Fach, nach der Simulation):
  - Symbol Mikrofon auf Violett, Tag „Mündlich“, Titel „Fachgespräch üben“
  - Beschreibung: „10 Fragen aus „<Bereich>“ werden vorgelesen – du antwortest frei per
    Sprache, danach Musterlösung und Selbstcheck.“
  - Ohne Spracherkennung „… frei, laut oder in Stichpunkten …“
  - Unter 3 geeigneten Fragen deaktiviert: „Für diesen Bereich gibt es noch keine passenden
    Fragen fürs Fachgespräch.“
- **Fragenpool:** gewählter Bereich (Fach + Themenbereich), dann Gewichtung wie im Training
  (`weightedPick`), 10 Fragen.
  - Offene Fragen mit `a` oder `e`.
  - Auswahlfragen, die allein verständlich sind:
    - endet auf „?“, höchstens 220 Zeichen, eine richtige Option
    - nicht passend zu `folgend|Aussage|trifft|richtig|falsch|zutreffend|\bnicht\b|\bkein|Beispiel|welche[rs]? (der|dieser)|Welche Antwort|Was gilt|Wofür steht|Kombination|Reihenfolge|ordnen` (ohne Groß-/Kleinschreibung)
  - Das sind derzeit 2.353 Auswahl- und 88 offene Fragen.

### Ablauf je Frage (Bildschirm wie das Quiz, eigener Kopf „<Fach> · mündlich“, „Frage 3/10“, Fortschrittspunkte)
1. **Frage:**
   - Chip „Fachgespräch“ (Violett), Themenbereich, Fragetext.
   - Die Frage wird automatisch vorgelesen (de-DE); Link „Nochmal vorlesen“.
   - Mit Spracherkennung: Hinweis „Antworte frei und vollständig, wie im Fachgespräch vor dem
     Prüfungsausschuss. Tippe auf „Fertig“, wenn du fertig bist.“ Knöpfe „Antworten“
     (Mikrofon, primär) und „Ohne Mikrofon“.
   - Ohne Spracherkennung direkt ein Stichpunkt-Feld und „Lösung zeigen“.
2. **Zuhören:**
   - Band „Ich höre zu …“ mit pulsierendem Punkt.
   - Darunter die Mitschrift live, vorläufige Teile kursiv.
   - Knopf „Fertig“.
   - Erkennung: de-DE, fortlaufend, mit Zwischenergebnissen.
   - Ohne Mikrofonrecht: Hinweis „Kein Zugriff aufs Mikrofon – erlaube es im Browser oder
     schreib deine Antwort unten.“
3. **Gehört:**
   - Die Mitschrift steht in einem Textfeld („bei Hörfehlern einfach korrigieren“).
   - „Weiter sprechen“ hängt an, „Lösung zeigen“ deckt auf.
4. **Lösung:**
   - „Deine Antwort“ (oder „— keine Antwort notiert —“).
   - Grüner Kasten: „Musterlösung“ (offen) bzw. „Richtige Antwort“ (Auswahl: richtige
     Option, dann die Erklärung).
   - Darunter die Begriffe:
     - Text: „Begriffe aus der Lösung in deiner Antwort: 2 von 5 – ein Hinweis, keine
       Bewertung.“
     - Chips: getroffen grün, sonst neutral.
   - Selbstcheck: „Nicht gewusst“ (rot), „Teilweise“ (Bernstein), „Gewusst“ (grün).
     - Gewusst → Lernstand richtig.
     - Nicht gewusst → falsch.
     - Teilweise → Box bleibt, nur der Lerntag zählt; landet wie „Nicht gewusst“ in
       „Falsche wiederholen“.
5. Nach der 10. Frage kommt das bekannte Ergebnis mit Titel „Mündlich üben“ („3 von 10
   richtig“, Aufschlüsselung nach Themenbereichen).

### Begriffe (Hinweis, keine Bewertung)
- **Quelle:** bei Auswahlfragen die richtige Option, sonst die Musterlösung.
- **Wörter:** ab 5 Buchstaben (inkl. Umlaute, Bindestrich).
  - ohne Füllwörter (Liste im Web-Code `OR_FUELL`), ohne Dopplungen
  - Großgeschriebene zuerst, höchstens 8
- **Treffer:**
  - Wortstamm = kleingeschrieben, Endung `ungen|ung|en|er|es|e|n|s` ab, auf 4–8 Zeichen
    gekürzt
  - getroffen, wenn der Stamm in der Antwort vorkommt (klein)
- **Referenz:**
  - „Boden, Arbeit und Kapital sind die originären Produktionsfaktoren …“ → Begriffe
    beginnen mit „Boden“, enthalten „Produktionsfaktoren“, nicht „sind“.
  - „Produktionsfaktoren“ trifft „die produktionsfaktor boden“.

### App: Technik
- Sprachausgabe: `flutter_tts` bzw. vorhandener `voice_service.dart`.
- Erkennung: `speech_to_text` mit `localeId: de_DE`, `listenMode: dictation`,
  `partialResults: true`. Pausen bis ca. 5 s tolerieren; endet die Sitzung, geht es in den
  Zustand „Gehört“.
- Mikrofon-Berechtigung ist schon im Manifest (`RECORD_AUDIO`).

### Abnahme
- Karte zeigt „10 Fragen aus … werden vorgelesen“. Start → Frage 1/10, Frage wird gelesen.
- „Antworten“ → „Ich höre zu …“ mit Live-Mitschrift → „Fertig“ → Mitschrift im Feld,
  korrigierbar.
- „Lösung zeigen“ → eigene Antwort, Lösung, Begriffe mit Treffern.
- „Gewusst“ → Frage 2/10, erster Punkt grün.
- Zehn Fragen später: Ergebnis „Mündlich üben“ mit richtiger Zahl; der Lernstand hat die
  Antworten.
- Ohne Spracherkennung: Stichpunkt-Feld statt Mikrofon, sonst gleich.

### Referenz Web-Implementierung (`index.html` auf `claude/ui-design-improvement-my0f66`)
- **HTML:**
  - Karte `#btnOral`, Z. 1907
  - Bildschirm `#scrOral`, Z. 2055
- **CSS:** Kommentar „Mündlich üben: Frage vorlesen …“, Z. 1208
- **JS:**
  - Block-Kommentar „Mündlich üben (Fachgespräch)“, Z. 4404
  - `orGeeignet`, Z. 4415
  - `orBegriffe`, Z. 4426
  - `orHoeren`, Z. 4442
  - `startOral`, Z. 4457
  - `orZeigen`, Z. 4478

Zeilennummern: Stand dieses Commits.

---

## FR-012 · Profile, Freunde und Nutzerübersicht

**Status App-Session:** ✅ erledigt (`claude/ui-design-improvement-my0f66`, PR #52, App 1.1.0)  
Die Verwaltung für Admins bleibt wie vorgesehen nur im Web.  
**Web umgesetzt:** ✅ `claude/ui-design-improvement-my0f66` (Commit „Profile, Freunde, Verwaltung …“)
**Voraussetzungen:**
- FR-004 (Wochenrangliste) umgesetzt
- einmalig `docs/supabase-profile.sql` **nach** `docs/supabase-rangliste.sql` (siehe
  `SUPABASE_SETUP.md`, Abschnitt 8)

Fehlt das Skript, sieht die Rangliste aus wie bisher.

### Ziel / Framing
- Lernende sehen, wer noch mitlernt, und können sich befreunden.
- Befreundete sehen gegenseitig ihren **Lernstand je Fach**.
- **Datenschutz:**
  - Ein Profil hat nur, wer der Rangliste beigetreten ist (Spitzname).
  - Für alle Teilnehmenden sichtbar ist nur, was die Rangliste ohnehin zeigt:
    Spitzname, Prüfungsreife, Antworten dieser Woche, Lerntage in Folge.
  - Den Lernstand je Fach sehen **standardmäßig nur Freunde**; wer mag, stellt auf „alle“.
  - Die Konto-ID verlässt die Datenbank nicht. Öffentliche Kennung ist `pid`.
- Die **Verwaltung für Admins gibt es nur in der Web-App** – in der App nicht nachbauen.
  Einzige Berührung: der Fehlercode `P0006` beim Beitritt zur Rangliste (unten).

### Datenbank (RPCs, alle nur für `authenticated`)
| RPC | Ergebnis |
|---|---|
| `profil_melden(p_details)` | – (Details siehe unten; der Server säubert und begrenzt sie) |
| `profil_sichtbarkeit(p_wert)` | – ; `'freunde'` (Standard) oder `'alle'` |
| `freunde_stand(p_woche)` | `{ich:{pid, name, sichtbarkeit}, anfragen:[Karte], gesendet:[Karte], freunde:[Karte]}`; `null`, wenn nicht in der Rangliste |
| `leute_suche(p_suche, p_seite, p_woche)` | `{gesamt, seite, liste:[Karte]}`: alle anderen, aktivste der Woche zuerst, 30 je Seite, Suche im Spitznamen |
| `profil_ansehen(p_pid, p_name, p_woche)` | `{pid, name, reife, serie, antworten, bez, sichtbarkeit, sichtbar, admin_sicht, seit, gemeistert, details, details_am}` – über `pid` oder Spitzname |
| `freund_anfragen(p_pid)` | `'angefragt'` oder `'freund'` (die andere Person hatte schon angefragt) |
| `freund_antworten(p_pid, p_annehmen)` | `'freund'` oder `null` (still abgelehnt) |
| `freund_entfernen(p_pid)` | – (Freundschaft beenden oder eigene Anfrage zurückziehen) |

- **Karte:** `{pid, name, reife, serie, antworten, bez}`, `bez` ∈ `'ich'`, `'freund'`,
  `'angefragt'` (eigene Anfrage), `'anfrage'` (Anfrage an mich), `null`.
- **`profil_ansehen`:** `seit`, `gemeistert`, `details` und `details_am` kommen nur, wenn
  `sichtbar` ist (man selbst, befreundet, Sichtbarkeit „alle“ oder Admin).
- **Details** (`p_details`), in der App aus dem Lernstand gerechnet wie Web `profilDetails`:
  - `f`: je aktivem Fach `{r, m, g, n}` = Reife in %, gemeistert (Box ≥ 3), gesehen, Fragen
  - `t14`: Antworten je Tag, die letzten 14 Tage, ältester zuerst
  - `tage`: Lerntage in den letzten 120 Tagen
  - `echt`: `{n, best}` = Prüfungen unter Echtbedingungen und bestes Ergebnis in %
    (nur, wenn es welche gibt)
- **Wann melden:** einmal nach dem Laden (sobald `freunde_stand` antwortet), beim Öffnen
  der Übersicht und nach jedem `rangliste_melden` (entprellt wie dort).
- **Fehlercodes → Text:**

  | Code | Text |
  |---|---|
  | `P0002` | „Diese Person ist nicht mehr dabei.“ |
  | `P0003` | „Tritt erst der Rangliste bei.“ |
  | `P0004` | „Du hast gerade sehr viele offene Anfragen – warte, bis einige beantwortet sind.“ |
  | `22023` | „Das geht leider nicht.“ |
  | `P0006` (bei `rangliste_melden`) | „Dein Konto ist für Rangliste, Gruppen und Freunde gesperrt.“ |
  | sonst | „Das hat nicht geklappt – bitte später noch einmal.“ |

- **Serverseitig:**
  - Abgelehnt wird still: Die anfragende Person sieht weiter „Angefragt“, eine erneute
    Anfrage wird nicht zugestellt.
  - höchstens 30 offene Anfragen und 50 neue am Tag
  - Rangliste verlassen oder Konto löschen → Profil und Freundschaften weg
- Lokal mit PGlite geprüft, 90 Fälle (inklusive Verwaltung).

### UI
- **Vergleichsabschnitt (Startseite), nur in der Rangliste:**
  - Reiter „Freunde“ zwischen „Alle“ und den Gruppen: „Du und deine Freunde · KW 39“, Liste wie
    in FR-004, eigene Zeile markiert. Ohne Freunde: „Noch keine Freunde.“ und „Lernende finden“.
  - Offene Anfragen als Band (Bernstein) über den Reitern: „**Cora** möchte mit dir befreundet
    sein.“ bzw. „**3** Freundschaftsanfragen warten auf dich.“, Knopf „Ansehen“.
  - Im Fuß ein Knopf „Lernende & Freunde“.
  - Namen in Rangliste, Gruppe und Freundesliste sind antippbar und öffnen das Profil.
  - Einführung vor dem Beitritt: vierter Punkt „**Freunde** finden und ihren Lernstand je Fach
    sehen – und sie deinen“. Hinweis darunter ergänzt: „Deinen Lernstand je Fach sehen nur deine
    Freunde – das kannst du im Profil ändern.“ und „… dein Eintrag samt Profil und
    Freundschaften wird dann gelöscht.“
- **Dialog „Lernende“** mit Reitern „Freunde“ (mit Zähler offener Anfragen), „Alle
  Lernenden“ (Handy: „Alle“) und „Mein Profil“. Geöffnet wird „Freunde“, wenn es Freunde oder
  Anfragen gibt, sonst „Alle“.
  - **Freunde:**
    - „Anfragen an dich“ mit „Annehmen“ / „Ablehnen“
    - „Deine Freunde · n“
    - „Gesendete Anfragen“ mit „Angefragt“ / „Zurückziehen“
    - ohne Freunde ein Leerkasten mit „Lernende finden“
  - **Alle:**
    - Suchfeld „Spitzname suchen …“ (300 ms entprellt)
    - Zeile „5 Personen in der Rangliste · aktivste dieser Woche zuerst“
    - Liste, „Mehr anzeigen“
  - **Zeile:**
    - rundes Kürzel, Name, darunter „64 % prüfungsreif · 312 Antw. diese Woche · 5 Tage in Folge“
    - rechts je nach Beziehung „Anfragen“, „Angefragt“, „✓ Befreundet“ oder „Annehmen“ /
      „Ablehnen“
    - reicht der Platz nicht, rutschen die Knöpfe unter den Namen
  - **Mein Profil:**
    - Text zu dem, was alle sehen
    - Umschalter „Lernstand je Fach zeigen: Nur Freunden | Allen Lernenden“
    - Hinweis „… Admins der App können zur Betreuung und Moderation alle Angaben sehen.“
    - Knopf „Mein Profil ansehen“
  - **Profil:**
    - „‹ Zurück“, großes Kürzel, Name, darunter „dabei seit September 2026“
    - Beim eigenen Profil zusätzlich „Lernstand nur für Freunde sichtbar“ bzw. „für alle
      sichtbar“.
    - Knöpfe je Beziehung: „Freundschaft anfragen“, „Angefragt“ + „Zurückziehen“, „Annehmen“ +
      „Ablehnen“, „✓ Befreundet“ + „Freundschaft beenden“ (mit Nachfrage)
    - Kacheln: prüfungsreif, Antworten diese Woche, Tage in Folge, bei Sichtbarkeit
      „Fragen gemeistert“
    - **Sichtbar:**
      - „Prüfungsreife je Fach“: Balken in der Fachfarbe, rechts %, darunter
        „150 von 260 gemeistert · 200 gesehen“; auf dem Handy Name/Prozent, Balken, Zahlen
        untereinander
      - „Aktivität · 14 Tage“ wie auf der Startseite. Die Tage rücken ab `details_am` bis heute
        nach; fehlende Tage zählen 0.
      - Kacheln „Lerntage in 120 Tagen“, „Prüfungen unter Echtbedingungen“, „bestes Ergebnis
        dabei“
    - **Nicht sichtbar:** Kasten mit Schloss „Den Lernstand je Fach zeigt <Name> nur Freunden.“
      und je nach Beziehung „Schick eine Anfrage – befreundet seht ihr ihn gegenseitig.“ bzw.
      „Deine Anfrage ist unterwegs.“
- **Kürzel:**
  - zwei Buchstaben: Anfangsbuchstaben der ersten beiden Wörter (getrennt an Leerzeichen,
    `_`, `.`, `-`), sonst die ersten zwei Zeichen
  - Farbton `h = (h·31 + Zeichencode) mod 360` über den Namen, Farbe `hsl(h 40% 40%)`
  - Keine Profilbilder.
- Rückmeldungen als Zeile über dem Inhalt: „Anfrage an <Name> gesendet.“, „Ihr seid jetzt
  befreundet.“, „Alle Lernenden sehen jetzt deinen Lernstand je Fach.“ bzw. „Deinen Lernstand
  je Fach sehen jetzt nur noch Freunde.“

### Abnahme
- Ohne Skript: kein Reiter „Freunde“, kein Knopf „Lernende & Freunde“, Namen nicht antippbar.
- Anfrage von Cora: Band auf der Startseite → „Ansehen“ → „Annehmen“ → Cora unter „Deine
  Freunde“, Zähler und Band weg.
- „Alle“: Suche „lkw“ findet „Lkw-Profi“ → „Anfragen“ → „Angefragt“.
- Profil von jemandem mit Sichtbarkeit „freunde“ ohne Freundschaft: Grundwerte, Schloss-Kasten,
  keine Fächer.
- Profil mit Sichtbarkeit „alle“: Fächerbalken, 14 Balken Aktivität, Kacheln.
- „Freundschaft beenden“ → Details verschwinden.
- „Mein Profil“ → „Allen Lernenden“ → `profil_sichtbarkeit('alle')`.
- Beitritt mit gesperrtem Konto → Text zu `P0006`.

### Referenz Web-Implementierung (`index.html` auf `claude/ui-design-improvement-my0f66`)
- **HTML:**
  - Kachel `#btnAdmin` (nur Web), Z. 1952
  - Dialog `#mLeute`, Z. 2150
  - Dialog `#mAdmin` (nur Web), Z. 2159
- **CSS:**
  - Kommentar „Namen in Rangliste, Gruppe und Freundesliste öffnen das Profil“, Z. 1351
  - Kommentar „Lernende: Nutzerübersicht, Freunde und Profile …“, Z. 1357
- **JS:**
  - Block-Kommentar „Lernende: Nutzerübersicht, Freunde und Profile“, Z. 5710
  - `ltStandLaden`, Z. 5718
  - `profilDetails`, Z. 5730
  - `frAnsichtHTML`, Z. 5762
  - `avatarHTML`, Z. 5793
  - `lernstandHTML`, Z. 5802
  - `ltProfilHTML`, Z. 5898
  - `ltZeigen`, Z. 5917
  - `frAktion`, Z. 5964
  - `ltOeffnen`, Z. 5992
  - Block-Kommentar „Verwaltung (nur Admins)“ (nur Web), Z. 6007
- **SQL:** `docs/supabase-profile.sql`

Zeilennummern: Stand dieses Commits.

---

## FR-013 · Zeichenaufgaben: Skizze je Teilaufgabe

**Status App-Session:** ✅ erledigt (`claude/ui-design-improvement-my0f66`, PR #52, App 1.1.0)
**Web umgesetzt:** ✅ `claude/ui-design-improvement-my0f66` (Commit „Skizze für Zeichenaufgaben …“)
**Anlass:** zwei Meldungen über „Fehler?“ zur Methoden-Prüfung vom 06.11.2024:
- Aufgabe 2 a): „Erstellen Sie … ein Flussdiagramm.“
- Aufgabe 4 b): „Stellen Sie … in einem Diagramm dar.“

Beide Meldungen sagen dasselbe: Eine Zeichnung lässt sich im Textfeld nicht beantworten.

### Ziel / Framing
Rund 60 der gut 2000 Prüfungs-Teilaufgaben verlangen eine Zeichnung:
- Flussdiagramm, Säulen-/Balken-/Liniendiagramm, Ursache-Wirkungs-Diagramm
- Netz- und Balkenplan, Organigramm, Erzeugnisstruktur
- v-t-Diagramm, Normalverteilung, Wahrscheinlichkeitsnetz, Schaltungsskizze

In der Prüfung wird das auf Papier gezeichnet. Die App gibt dafür eine **Skizze je
Teilaufgabe**:
- Sie wird gespeichert und zählt als Antwort.
- Nach dem Aufdecken steht sie direkt über der amtlichen Lösungsskizze (`bildL`), zum
  Vergleichen.

### Erkennung (wie Web `skZeichenteil`)
Eine Teilaufgabe ist eine Zeichenaufgabe, wenn ihr Fragetext (`q`) eine Aufforderung zum
Zeichnen enthält. Groß-/Kleinschreibung egal, `…` = beliebiger Text ohne Satzende:
- „zeichnen Sie“ oder „skizzieren Sie“
- „zeichnerisch“, „grafisch“ oder „graphisch“
- „stellen/tragen Sie … in/im/als/auf … <Objekt>“
- „erstellen/entwerfen/ergänzen/vervollständigen/vergleichen Sie … <Objekt>“
- „kennzeichnen Sie … im/in … <Objekt>“

<Objekt> ist eines von: Flussdiagramm, Programmablaufplan, Struktogramm, Diagramm (auch
in Säulendiagramm usw.), Schaubild, Histogramm, Organigramm, Netzplan, Balkenplan, Gantt,
Erzeugnisstruktur, Wahrscheinlichkeitsnetz, Wahrscheinlichkeitsgerade, Portfolio, Matrix,
Kurve, Gerade, Normalverteilung.

„Nennen Sie vier Diagrammarten“ oder „Beschreiben Sie Vorteile von Flussdiagrammen“ fallen
damit heraus. Die genauen Regeln stehen in `SK_RE` / `SK_OBJ` (Web).

### Verhalten im Aufgabenblatt
- **Zeichenaufgabe:**
  - Die Skizze ist gleich offen.
  - Das Textfeld darunter heißt „Erläuterung · optional“, Platzhalter „Erläuterung zur
    Skizze, z. B. gewählte Diagrammart …“.
- **Jede andere Teilaufgabe:** neben „Rechenweg“ ein Knopf „Skizze“, der sie aufklappt.
- **Kopf:** „Skizze · wie auf dem Lösungsblatt · wird gespeichert“
- **Werkzeuge:**
  - Stift (Freihand), Linie, Pfeil, Rechteck, Raute, Oval, Text, Radierer
  - Farben Schwarz `#17272E`, Petrol `#0C6C78`, Rot `#C0472F`, Blau `#3f6fb5`
  - Zurück (Rückgängig, bis 60 Schritte), Leeren (mit Nachfrage), Groß/Fertig (Vollbild)
- **Raster:**
  - Linien, Pfeile und Formen rasten auf ein halbes Karo ein (12,5 Einheiten).
  - Formen sind leicht in ihrer Farbe gefüllt (10 %), mit 3 Einheiten Strichstärke.
- **Text:**
  - In eine Form tippen → Beschriftung, mittig und umbrochen.
  - Auf einen Text tippen → ändern; leer = löschen.
  - Sonst → freier Text an der Stelle.
- **Format:**
  - „Quer“ 1000 × 625 oder „Hoch“ 1000 × 1250
  - „Hoch“ ist voreingestellt, wenn der Fragetext „Flussdiagramm“, „Programmablaufplan“
    oder „Struktogramm“ nennt.
- **Hintergrund:**
  - Karopapier (Karo 25 Einheiten)
  - oder „Auf der Anlage“, wenn die Teilaufgabe bzw. ihre Aufgabe eine Bild-Anlage hat
  - „Auf der Anlage“ ist voreingestellt, wenn der Fragetext „Anlage“ nennt, etwa beim
    Wahrscheinlichkeitsnetz.
  - Die Fläche nimmt dann das Seitenverhältnis des Bildes an. Die Formatwahl ist dann
    ausgeblendet.
- **Handy:**
  - Werkzeuge nur als Symbol, alle acht in einer Zeile
  - Die Fläche nutzt fast die ganze Breite.
  - Darunter ein breiter Knopf „Groß zeichnen“.
  - Zeichnen per Finger; die Fläche scrollt dabei nicht.
- Die Skizze zählt als Antwort: Die Karte ist „bearbeitet“, Leiste und Fortschritt zählen
  sie.
- **Nach dem Aufdecken:**
  - Unter „Deine Antwort“ steht die Skizze als Bild; Antippen vergrößert sie.
  - Darunter folgt die amtliche Lösung mit `bildL`.
- **Prüfung unter Echtbedingungen:** Beim Start wird die Skizze mit den anderen Antworten
  geleert.
- **„Von Claude prüfen lassen“:** Die Skizze erscheint als Zeile „[Eigene Skizze: 1 Rechteck,
  1 Raute, 1 Oval, 1 Pfeil … · Beschriftungen: „Beginn“, …]“.

### Datenmodell (wie Web, Schlüssel `kvm_open_sketch`)
`{ <Teilaufgaben-ID>: { v: 1, bg: 'karo'|'anlage', fmt: 'quer'|'hoch', els: [...] } }`,
Koordinaten in einem festen Raum von 1000 Einheiten Breite.

| `t` | Element | Felder |
|---|---|---|
| `p` | Freihand | `pts: [x0, y0, x1, y1, …]` (ganze Zahlen) |
| `l` / `a` | Linie / Pfeil | `x1, y1, x2, y2` |
| `r` / `d` / `o` | Rechteck / Raute / Oval | `x, y, w, h`, optional `txt` |
| `x` | Text | `x, y` (linke Mitte), `txt` |

Dazu je Element `c` ∈ `k|p|r|b` (Farbe) und `s` (Strichstärke, 3). Leere Skizzen werden
nicht gespeichert.

### Nachtrag zu FR-008 (Fehler melden)
Offene Fragen im Quiz (Chat-Ansicht) blenden den Fragekopf aus, und mit ihm den Knopf
„Fehler?“. Der Knopf steht jetzt in der Kopfzeile der Prüfer-Nachricht („PRÜFER … Fehler?“).
Bitte in der App ebenso: Jede Frage muss sich melden lassen, auch offene.

### Abnahme
- Prüfung Methoden 06.11.2024, Aufgabe 2 a):
  - Skizze offen, „Hoch“ voreingestellt
  - Oval „Beginn“ → Pfeil → Rechteck → Raute zeichnen und beschriften
  - nach Neustart unverändert
  - „Lösung aufdecken“: eigene Skizze über der IHK-Lösungsskizze
- Aufgabe 2 b) (Textaufgabe): Skizze zu, Knopf „Skizze“ klappt sie auf.
- Wahrscheinlichkeitsnetz (NT 12.11.2014, Aufgabe mit „Anlage 1“): Hintergrund „Auf der
  Anlage“, Seitenverhältnis wie das Bild; „Karo“ schaltet um.
- Radierer entfernt einen Strich, „Zurück“ holt ihn wieder.
- Prüfung unter Echtbedingungen starten → Skizzen der Prüfung sind leer.
- Offene Frage im Quiz: Knopf „Fehler?“ in der Prüfer-Kopfzeile öffnet den Melde-Dialog mit
  ihrer Nummer.

### Referenz Web-Implementierung (`index.html` auf `claude/ui-design-improvement-my0f66`)
- **CSS:** Kommentar „Skizze: Zeichenfläche für Zeichenaufgaben …“, Z. 1697
- **JS:**
  - Block-Kommentar „Skizze: Zeichenfläche für Zeichenaufgaben“, Z. 3925
  - `skZeichenteil`, Z. 3960
  - `skElement`, Z. 3984
  - `skMalen`, Z. 4010
  - `skTreffer`, Z. 4028
  - `skHTML`, Z. 4049
  - `skStart`, Z. 4087
  - `skZeigenBinden`, Z. 4202
  - Einbau in `blTeilHTML`, Z. 4247
  - Melde-Knopf in `buildOpenChat`, Z. 3078

Zeilennummern: Stand dieses Commits.

---

## FR-014 · Prüfungen: Neustart, Übersicht, Bestehenschance, Prüfungsrangliste

**Status App-Session:** ✅ erledigt (`claude/ui-design-improvement-my0f66`, PR #52, App 1.1.0)
**Web umgesetzt:** ✅ `claude/ui-design-improvement-my0f66`
**SQL:** `docs/supabase-pruefungen.sql` (neu), `docs/supabase-rangliste.sql`, `docs/supabase-gruppen.sql`,
`docs/supabase-profile.sql` (erweitert). Live eingespielt als Migration `pruefungsergebnisse`.

### Anlass
Rückmeldung aus der Nutzung:
- Eine Original-Prüfung ließ sich nicht neu starten. Die Liste bot nur „Prüfung öffnen“ mit den
  alten Antworten. „Neue Runde starten“ im Ergebnis startete eine zufällige andere Prüfung.
- Gewünscht: eine Übersicht, welche Prüfungen bestanden sind, die Übernahme in die Rangliste
  und daraus die Wahrscheinlichkeit, die echte Prüfung zu bestehen.

### 1. Neu starten
- **Wo:**
  - In der Prüfungsliste steht „Neu starten“ neben „Weiter …“ bzw. „Prüfung öffnen“, sobald
    die Prüfung Antworten, Rechenwege, Skizzen, Tabellen oder Punkte hat.
  - Auch neben „Läuft …“ und „Abgegeben …“, wenn ein Durchgang unter Prüfungsbedingungen läuft.
  - Auf dem Ergebnis-Bildschirm einer Original-Prüfung heißt der Hauptknopf
    „Prüfung neu starten“. Daneben steht „Alle Prüfungen“, das die Liste öffnet.
  - Für Fallaufgaben bleibt „Neue Runde starten“ wie bisher.
- **Nachfrage:**
  - „Prüfung neu starten? Deine Antworten, Rechenwege, Skizzen und Punkte dieser Prüfung werden
    gelöscht – ausgewertete Durchgänge bleiben in deiner Übersicht.“
  - Bei laufenden Prüfungsbedingungen steht davor: „Der laufende Durchgang unter
    Prüfungsbedingungen wird abgebrochen.“
- **Danach:**
  - Ist jede Teilaufgabe bewertet, der Durchgang aber nie über „Zum Ergebnis“ gemerkt, wird er
    vorher gemerkt, damit nichts verloren geht.
  - Ein laufender Durchgang unter Prüfungsbedingungen endet.
  - Alle Antworten dieser Prüfung werden geleert (wie beim Start unter Prüfungsbedingungen).
  - Die Prüfung bekommt eine neue Durchgangskennung und öffnet bei Aufgabe 1.

### 2. Durchgänge speichern (wie Web)
- **`kvm_pruef_erg`:** Liste, nach `t` sortiert, höchstens 500 Einträge.
  `{k, id, t, g, pkt, max, bew, teile, echt, dauer, min}`:

  | Feld | Bedeutung |
  |---|---|
  | `k` | Durchgangskennung, z. B. `mfd3k2a9x1b` (Zeit base36 + Zufall) |
  | `id` | Prüfung, z. B. `P-RE-20241106` |
  | `t` | ausgewertet am (ms), bleibt bei späteren Änderungen erhalten |
  | `g` | zuletzt bewertet (ms), gewinnt beim Abgleich; bei jeder Änderung `max(jetzt, altes g + 1)` |
  | `pkt` / `max` | eigene Punkte / Höchstpunkte (Teilaufgaben ohne Punkte zählen 0) |
  | `bew` / `teile` | Teilaufgaben mit Punkten / mit Punktangabe |
  | `echt` | 1 = unter Prüfungsbedingungen; bleibt 1, auch wenn später nachbewertet |
  | `dauer` / `min` | Bearbeitungszeit (ms) / vorgesehene Zeit (min), nur bei `echt` |

- **`kvm_pruef_lauf`:** `{Prüfung: Kennung}`, die aktuelle Durchgangskennung je Prüfung.
  - Neu beim Start unter Prüfungsbedingungen und bei „Neu starten“.
  - Sonst bleibt sie. Wer „Zum Ergebnis“ mehrmals drückt, ändert also denselben Durchgang.
- **Merken:** bei „Zum Ergebnis“ einer Original-Prüfung, bei Prüfungsbedingungen mit Dauer.
- **Übernahme:** Einmalig werden Einträge aus `kvm_echt_verlauf` (FR-007) übernommen:
  - Kennung `e<tag>-<id>-<dauer>`
  - `t = g = tag·86400000 + 12 h`
  - `echt: 1`, `bew`/`teile` leer
  - `kvm_echt_verlauf` wird danach nicht mehr geschrieben. „Zuletzt unter
    Prüfungsbedingungen“ liest aus `kvm_pruef_erg`.

### 3. Wertung
- **Gewertet** ist ein Durchgang, wenn jede Teilaufgabe Punkte hat (auch 0) oder er unter
  Prüfungsbedingungen lief. Dort zählt Offenes wie in der Prüfung 0.
- **Bestanden:** mindestens 50 % der Punkte (IHK: 50 von 100). Note nach IHK-Schlüssel.
- **Erstversuch:** Für Statistik, Rangliste und Bestehenschance zählt je Prüfung nur der erste
  gewertete Durchgang. Bei einer Wiederholung kennt man die Lösungen schon.
- **Status je Prüfung** in der Liste: der letzte Durchgang, bei mehreren gewerteten der Verlauf
  „3 Durchgänge: 42 → 55 → 68 P“.

### 4. Bestehenschance (genau so rechnen)
Je Prüfungsbereich aus den Erstversuchen `x₁ … xₙ` in % (ältester zuerst):
- **Gewichte:** `wᵢ = 0,8^(n−i)` (der jüngste 1), unter Prüfungsbedingungen ×1,5.
  - Schnitt `μ = Σwᵢxᵢ / Σwᵢ`
  - wirksame Anzahl `n_eff = (Σwᵢ)² / Σwᵢ²`
- **Streuung zwischen zwei Prüfungen:**
  - `s² = Σwᵢ(xᵢ−μ)²/Σwᵢ · n/(n−1)` (0 bei n = 1)
  - `σ² = (3·12² + (n−1)·s²) / (n+2)`, also auf 12 Punkte gestützt und ab der zweiten Prüfung
    dazugelernt
- **Chance:** `P = Φ((μ − 49,5) / √(σ²·(1 + 1/n_eff)))`, Φ = Standardnormalverteilung.
  - Die Web-App nutzt die Näherung nach Abramowitz/Stegun 7.1.26.
- **Prüfwerte:** eine Prüfung mit 70 % → 88,6 %; mit 62 % → 76,9 %; mit 45 % → 39,5 %.
- **Teile:**
  - Basisqualifikationen = RE, BW, MI, ZI, NT
  - handlungsspezifischer Teil = FT, OK, nur wenn die Fachrichtung Kraftverkehr aktiv ist
  - Chance eines Teils = Produkt der Bereichschancen, nur wenn jeder Bereich gewertet ist, sonst
    „x/5 Bereiche geprüft · fehlt: …“
  - Beide Teile = Produkt beider
- **Hauptwert** für Rangliste und Profilkopf: beide Teile, sonst der vollständig geprüfte Teil
  (erst Basisqualifikationen, dann handlungsspezifisch), sonst keiner.
- **Anzeige:**
  - ganze Prozent
  - unter 1 % als „< 1 %“, über 99 % als „> 99 %“
  - Stufen: ab 70 % grün, ab 40 % gelb, darunter rot
- **Hinweistext** (sinngemäß):
  - Die Chance ist eine Schätzung aus Selbstbewertungen.
  - Neuere Prüfungen und solche unter Prüfungsbedingungen zählen mehr; mit wenigen Prüfungen
    ist sie vorsichtig.
  - Für einen Teil muss jeder Bereich sitzen.
  - Mündliche Ergänzungsprüfung und Fachgespräch sind nicht eingerechnet.

### 5. Oberfläche
- **Startseite:** In der dunklen Prüfungskarte steht unter „Zuletzt geöffnet“ ein Streifen
  „Bestehenschance“, sobald es eine gewertete Prüfung gibt.
  - Je Teil der Wert bzw. „4/5 · Bereiche geprüft · fehlt: …“.
  - Darunter „x von y Prüfungen bestanden · am knappsten: Methoden 37 %“, wenn ein Bereich
    unter 70 % liegt.
  - Antippen öffnet die Liste.
- **Prüfungsliste**, oben aufklappbar „Deine Ergebnisse“:
  - Kopf: „x von y Prüfungen bestanden · Ø z P“
  - Kacheln: Basisqualifikationen, Handlungsspezifisch, bei beiden „Beide Teile“
  - je Bereich eine Zeile: Name, die letzten 6 Erstversuche als Chips (grün ≥ 50, rot darunter),
    Chance und Balken. Antippen filtert die Liste auf den Bereich, erneut antippen hebt den
    Filter auf.
  - ohne gewertete Prüfung ein kurzer Hinweis, wie man eine wertet
- **Je Prüfung:**
  - Die Ergebniszeile zeigt „Bestanden“ bzw. „Nicht bestanden“ bzw. „Noch nicht gewertet“,
    dazu Punkte, Note, Datum und ggf. „unter Prüfungsbedingungen, 1 h 23 min“ und den Verlauf.
  - Termine mit begonnener oder ausgewerteter Prüfung sind aufgeklappt.
- **Ergebnis-Bildschirm** (Original-Prüfung), Hinweis unter dem Kopf:
  - Erstversuch: „Bestehenschance Recht: 71 % (vorher 64 %) · aus 3 Prüfungen in diesem Bereich.“
  - Wiederholung: „steht in deiner Übersicht, zählt aber nicht für die Bestehenschance …“
  - Nicht gewertet: „8 von 13 Teilaufgaben haben Punkte …“. Das Abzeichen lautet dann „Noch
    nicht vollständig bewertet“ statt bestanden/nicht bestanden.
  - Link „Zur Übersicht“

### 6. Cloud
Alles ist optional: Fehlt eine Funktion (PGRST202), bleibt die App wie ohne.
- **`pruefungen_abgleichen(p_neu jsonb)`:**
  - beim Anmelden mit allen Durchgängen, danach entprellt (1,5 s) nach jeder Änderung mit
    denen, deren `g` größer ist als der gemerkte Stand
  - Stand gemerkt in `kvm_pruef_sync_<Konto-ID>` = größtes `g`
  - Felder wie oben, `echt` als 0/1
  - Antwort: alle eigenen Durchgänge. Zusammenführen je `k`: das größere `g` gewinnt, `echt`
    bleibt 1.
- **`pruefungen_melden(p_n, p_ok, p_schnitt, p_chance)`:** ganze Zahlen, `p_chance` = Hauptwert
  in % oder null.
  - nach jedem Abgleich und einmal je Sitzung vor dem Laden der Prüfungsrangliste
  - nur wenn man der Rangliste beigetreten ist
- **`rangliste_pruefungen()`:** `{teilnehmende, ich:{platz,n,ok,schnitt,chance}, liste:[{platz,name,n,ok,schnitt,chance,ich}]}`,
  Top 10 nach bestanden, dann Schnitt.
- **Neue Felder:**
  - `gruppe_stand` (je Mitglied), `profil_karte` (Freunde, Anfragen, Suche) und `profil_ansehen`
    liefern zusätzlich `pruef_n`, `pruef_ok`, `pruef_schnitt`, `chance`.
- **Profil-Details** (`profil_melden`, sehen nur Freunde):
  - `pr: {RE: {n, ok, s, c}, …}` je Bereich mit gewerteter Prüfung
  - `pc: {bq, hq, g}` in %

### 7. Rangliste
- Umschalter „Diese Woche / Prüfungen“ unter den Reitern (Alle, Freunde, Gruppen). Er erscheint
  nur, wenn `rangliste_pruefungen` antwortet.
- **Prüfungen:**
  - Spalten Pl. · Spitzname · Bestanden (`ok/n`) · Chance
  - Alle: Top 10 vom Server, der eigene Eintrag nach „⋯“, falls außerhalb
  - Freunde und Gruppe: lokal sortiert (bestanden, dann Schnitt, ohne Schnitt hinten)
  - Fußnote zur Wertung
- **Kennzahlen oben im Prüfungsmodus:**
  - eigener Hauptwert samt Teil, sonst „x/7 Prüfungsbereiche gewertet …“
  - eigener Platz „3. · Platz von 5 · 6 von 6 Prüfungen bestanden“
- **Profil:**
  - Kopf: „x/y Prüfungen bestanden“ und „Bestehenschance“
  - bei Freunden: „Prüfungen je Bereich“ (Name, „2 von 3 bestanden · Ø 61 P“, Chance)
- **Verwaltung:** Konto-Detail mit „Prüfungen bestanden“ und „Bestehenschance“

### Abnahme
- Prüfung vollständig bewerten → „Zum Ergebnis“:
  - „Bestanden · Note 3“
  - Hinweis mit Bestehenschance
  - Knopf „Prüfung neu starten“
- Noch einmal „Zum Ergebnis“ → kein zweiter Durchgang.
- „Prüfung neu starten“ → Nachfrage, danach:
  - leere Blätter bei Aufgabe 1
  - Durchgang bleibt in der Übersicht
- Wiederholen und werten:
  - Hinweis „Wiederholung“
  - Chance unverändert
  - in der Liste „2 Durchgänge: 70 → 90 P“
- Nur 2 Teilaufgaben bewerten → „Noch nicht vollständig bewertet“, zählt nicht.
- Unter Prüfungsbedingungen abgeben, 3 Teile bewerten, „Zum Ergebnis“ → gewertet (Rest 0).
- Laufende Prüfungsbedingungen über „Neu starten“ abbrechen → Uhr weg.
- Zwei Geräte, gleiches Konto: Auf Gerät A werten, auf Gerät B anmelden → B zeigt denselben Stand.
- Rangliste → „Prüfungen“: Reihenfolge nach bestanden, dann Schnitt. Gruppe und Freunde ebenso.

### Referenz Web-Implementierung (`index.html` auf `claude/ui-design-improvement-my0f66`)
- **Speicher, Wertung, Chance:**
  - Block „Prüfungsergebnisse und Bestehenschance“, Z. 4678
  - `peChance`, Z. 4777
  - `peStatistik`, Z. 4787
  - `peNeuStarten`, Z. 4837
  - `peErgebnis`, Z. 4852
- **Startseite:** `renderPruefChance`, Z. 2673
- **Liste:** `ergebnisHTML`, Z. 8353 · `uebersichtHTML`, Z. 8367
- **Cloud:**
  - Block „Prüfungsergebnisse abgleichen“, Z. 5247
  - `pruefStandLaden`, Z. 5405
  - Block „Rangliste nach Prüfungen“, Z. 5548

Zeilennummern: Stand dieses Commits.

---

## FR-015 · Mehrseitige Oberfläche: Start ohne Scrollen, Seitenleiste, Statistik zum Aufziehen

**Status App-Session:** ✅ erledigt (`claude/ui-design-improvement-my0f66`, PR #52, App 1.1.0)  
Mit Nachtrag 4 (Übergänge) in Web und App.  
**Web umgesetzt:** ✅ `claude/ui-design-improvement-my0f66`
**Priorität:** hoch (User-Wunsch: „Mach die Webseite gerne Mehrseitig, aber vielleicht mit einem
Hauptscreen mit direkter Funktionsübersicht und Statistiken, die Prüfungen auch presenter
(Homescreen ohne Scrollen, Statistiken vielleicht zum Runterziehen?)“)

### Anlass
- Die Startseite war eine lange Liste: Kopf, Lernstand, Lernweg, Üben, Prüfen, Erfolge, Nachschlagen,
  Vergleich, Statistik, Konto. Vieles lag weit unten, die Prüfungen irgendwo in der Mitte.
- Gewünscht: mehrere Seiten, ein Hauptbildschirm ohne Scrollen mit allen Funktionen auf einen Blick,
  die Prüfungen prominent, die Statistik zum Herunterziehen.

### Was sich gegenüber früheren FRs ändert
- Die Inhalte bleiben, sie verteilen sich nur auf Seiten. Wo FR-003 E, FR-004, FR-009 bis FR-012
  und FR-014 „Startseite“ sagen, gilt die Zuordnung unten.
- Die Prüfungsliste ist kein Dialog mehr, sondern die Seite „Prüfungen“ (ersetzt den Dialog aus
  FR-003 und FR-014 5). „Alle Prüfungen“, „Zur Übersicht“ und der Streifen „Bestehenschance“ öffnen
  diese Seite.

### 1. Seiten und Navigation
- **Fünf Seiten:** Start · Lernen · Prüfungen · Vergleich · Konto.
- **Leiste:**
  - Handy: fest unten (Material 3 `NavigationBar`), Symbol über Beschriftung (w600 11).
    Symbole: Haus, aufgeschlagenes Buch, Dokument mit Haken, Pokal, Person.
  - Aktives Ziel: Symbol auf einer Pille `kPetrolSoft` (36 × 28, Radius 10), Text `kPetrolInk`.
    Andere Ziele `kMuted`.
  - Leiste: `kPaper`, oben Linie `kLine`, Schatten nach oben, Abstand für die Gestenleiste
    (`SafeArea`).
  - Ab 900 dp Breite oben mittig als schwebende Pillenleiste (Radius 15, Rahmen `kLine`,
    Schatten wie Karten), links „MEISTER FÜR KRAFTVERKEHR“ (Display 15). Aktives Ziel als gefüllte
    Pille `kPetrolSoft`, Text `kPetrolInkDeep`. Alternativ `NavigationRail` – Hauptsache, die fünf
    Ziele sind ohne Scrollen erreichbar.
  - Die Leiste gibt es nur in der Startansicht. Quiz, Aufgabenblatt, Mündlich und Ergebnis bleiben
    ohne Leiste (dort ✕ bzw. „Zur Startseite“ wie bisher).
- **„Vergleich“** erscheint nur, wenn die Rangliste eingerichtet ist (`rangliste_info` bzw.
  `rangliste_stand` antwortet). Sonst hat die Leiste vier Ziele. Wer auf „Vergleich“ steht, wenn es
  wegfällt (Abmelden, Fehler), landet auf Start. Solange unklar ist, ob es die Rangliste gibt,
  zeigt die Seite „Rangliste wird geladen …“.
- **Hinweispunkt:** Amber-Punkt 9 dp (`kAmber`, Ring 2 dp in `kPaper`) oben rechts am Symbol von
  „Vergleich“, solange eine Gruppeneinladung (`kvm_einladung`, FR-010) oder Freundschaftsanfragen
  (FR-012) warten. Semantik-Label: „Vergleich – eine Einladung oder Anfrage wartet“.
- **Seitenwechsel** springt nach oben. Die Seiten behalten ihren Zustand (in Flutter `IndexedStack`),
  „Prüfungen“ und „Vergleich“ laden beim Öffnen neu (wie Web `KVM_pruefListe`, `KVM_vergleich`).
- **Seitentitel** (Display 24–32, Großbuchstaben): „Lernen“, „Original-IHK-Prüfungen“, „Vergleich“
  (rechts „x dabei“), „Konto & Einstellungen“. Start hat den bisherigen Kopf.
- **Zurück:**
  - Web: Adresse `#/lernen`, `#/pruefungen`, `#/vergleich`, `#/konto`, Start `#/`. Browser-Zurück
    und -Vor wechseln die Seite; eine unbekannte Seite zeigt Start und berichtigt die Adresse.
    Fremde Anker (Login-Rückkehr, `#gruppe=…`) bleiben unangetastet. Der Tab-Titel lautet
    „Lernen · Meister-Trainer“ usw.
  - App: Android-Zurück auf einer Unterseite → Start; auf Start wie bisher (App verlassen).
    Mitten in einer Runde wirkt Zurück wie ✕, unter Prüfungsbedingungen mit derselben Nachfrage
    („Prüfung verlassen? Die Uhr läuft weiter …“). Beim mündlichen Üben stoppen Mikrofon und
    Vorlesen wie bei ✕. In Flutter über `PopScope`.
- **Rückkehr:**
  - ✕ in Quiz, Aufgabenblatt oder Mündlich führt auf die Seite, von der aus gestartet wurde
    (z. B. Lernen oder Prüfungen). „Zur Startseite“ im Ergebnis → Start. „Alle Prüfungen“ → Prüfungen.
  - Ein Einladungslink (`…#gruppe=CODE`) öffnet gleich „Vergleich“.
  - Nach dem Google-Login zurück auf die Seite, auf der man „Anmelden“ getippt hat (Web:
    `sessionStorage['kvm_seite_login']`, eingelöst beim Ereignis `SIGNED_IN`). In der App nur nötig,
    wenn der Login die Ansicht neu aufbaut.

### 2. Start – alles auf einen Bildschirm
Ziel: kein Scrollen auf 390 × 760 dp (Handy abzüglich Systemleisten) und 1280 × 800 (Desktop).
Web gemessen: passt ohne Scrollen bei 360 × 740, 375 × 667, 390 × 760, 412 × 915, 673 × 841
(Foldable), 768 × 1024, 1024 × 768, 1280 × 800 und 1366 × 768. Ist das Fenster doch zu klein (etwa
Handy quer), darf die Seite scrollen (in Flutter `SingleChildScrollView` als Rückfall), aber nichts
wird abgeschnitten.
Unten bleibt Platz für die Leiste (Web: 72 px, Leiste 63 px).

Reihenfolge von oben:
1. **Kopf:** „MEISTER FÜR KRAFTVERKEHR“ einzeilig (Display 18–34, notfalls „…“). Auf dem Handy
   ohne Eyebrow und Untertitel, bis 899 dp ohne Eyebrow, unter 700 dp Höhe ganz ohne Kopf. Ab
   900 dp steht der Name in der Leiste und der Kopf entfällt.
2. **Statistikleiste** (Karte `kPaper`, Rahmen `kLine`, Radius 16):
   - Eine Zeile mit vier Kennzahlen: gemeistert · gesehen · offen · Tage in Folge. Zahl Display
     17 (Handy) bzw. 19, Beschriftung 10–10,5 `kMuted`, einzeilig. Spalten so breit wie ihr Inhalt,
     gleichmäßig verteilt (Web `justify-content: space-between`), damit „Tage in Folge“ ganz
     sichtbar bleibt.
   - Rechts der Griff: „STATISTIK“ (Mono 8,5, `kPetrolInk`) über einem Chevron 17 dp, der sich
     aufgeklappt um 180° dreht. Darunter über die ganze Breite der Fortschrittsbalken (4 dp).
   - **Aufziehen:** Antippen öffnet und schließt. Auf dem Handy öffnet Wischen nach unten
     (≥ 36 dp), Wischen nach oben schließt; kürzere Bewegungen ändern nichts. Ein Tippen bis
     500 ms nach dem Wischen zählt nicht (sonst schlösse es gleich wieder). In Flutter
     `GestureDetector.onVerticalDragUpdate` + `AnimatedSize`.
   - Aufgeklappt: „Prüfungsreife je Fach“ (Radar + Legende, FR-003 E.8), „Aktivität · 14 Tage“,
     „Erfolge“ (FR-003 E.6) und unten rechts klein „Lernstand zurücksetzen“ (umrandet, beim
     Überfahren `kErr`).
3. **Heute-Karte** (FR-003 E.2) kompakter:
   - Ring 78 dp (Handy) bzw. 110 dp (ab 900 dp), Prozent Display 20, „PRÜFUNGSREIF“ Mono 7,5.
   - Kicker einzeilig mit „…“, Titel Display 21, die Beschreibung entfällt auf dem Handy.
   - „Jetzt lernen →“ nicht mehr volle Breite (Höhe 38).
   - Ohne Prüfungstermin statt des Absatzes nur ein unterstrichener Link „Prüfungstermin eintragen“
     (FR-006); mit Termin der Plan wie bisher, etwas enger.
4. **Prüfungskarte** (dunkel, FR-003 E.5) mit „Zuletzt geöffnet“ und dem Streifen
   „Bestehenschance“ (FR-014 5). Die ganze Kopfzeile öffnet „Prüfungen“. Auf dem Handy:
   - Symbolkachel 42 dp, Titel Display 18, ohne die Beschreibungszeile.
   - „Zuletzt geöffnet“ ohne die Beschriftung, Titel einzeilig mit „…“, Balken 4 dp,
     „Weiter bei Aufgabe N →“ Höhe 36.
   - Bestehenschance: die Werte zweispaltig (Display 21), ohne „fehlt: …“, Summenzeile einzeilig.
5. **Funktionen:** 3 Spalten × 2 Reihen (Abstand 7–8), Kachel `kPaper`, Rahmen `kLine`, Radius 14,
   Symbolkachel 32 dp (Radius 10, weißes Symbol 18):

   | Kachel | Farbe | Symbol | Aktion |
   |---|---|---|---|
   | Lernen | `kPetrol` | Buch | Seite Lernen |
   | Mündlich | `kViolet` #6D5AE6 | Mikrofon | Mündlich üben im gewählten Fach (FR-011) |
   | Fallaufgaben | `kPlum` | Koffer | Fallaufgaben starten |
   | Formelbuch | `kOk` | Buch mit Lesezeichen | Formelbuch |
   | Kostenwesen | `kPetrol` | Rechner | Kostenwesen |
   | Gefahrgut | `kAmber` | Raute mit ! | ADR |

   Handy und bis 1199 dp: Symbol über dem Titel, nur der Titel (w700 12,5–13,5); zwischen 561 und
   899 dp mit Kurzbeschreibung darunter. Ab 1200 dp Symbol links, rechts Titel und Kurzbeschreibung
   („Fächer, Training, Simulation“, „Fachgespräch üben“, „Praxisfälle mit Teilaufgaben“,
   „Formeln und Schemata“, „Lehrgang und Rechner“, „ADR-Klassen und Quiz“), höchstens zwei Zeilen.
- **Ab 900 dp** zweispaltig (links 1,1 : rechts 1): links die Heute-Karte, darunter die
  Funktionen; rechts die Prüfungskarte. Die Statistikleiste darüber, Kennzahlen höchstens 640 dp
  breit. Inhalt höchstens 1120 dp breit.
- **Kleine Bildschirme:**
  - Höhe unter 700 dp: ohne Kopf, Abstände 6, Ring 64 (ohne „PRÜFUNGSREIF“), Kacheln 52 hoch mit
    Symbolkachel 26, Prüfungskarte oben und unten je 7–8 dp Innenabstand.
  - Breite unter 380 dp: Kacheln seitlich 7 dp Innenabstand, Titel 11,5.
  - Breite unter 340 dp: Kachelabstand 5, seitlich 5 dp, Titel 10,5, Kennzahlen Display 15, am
    Griff nur der Chevron (ohne „STATISTIK“).
  - Prüfen: Von 320 bis 412 dp Breite ist kein Kacheltitel und keine Kennzahl-Beschriftung
    abgeschnitten.

### 3. Die anderen Seiten
- **Lernen:** „DEIN LERNWEG“ (FR-003 E.3, FR-001) und „ÜBEN“ (FR-003 E.4 samt Mündlich,
  „Fachübergreifend“: Alle Themen, Fallaufgaben). Unverändert, nur auf eigener Seite.
- **Prüfungen:** die bisherige Prüfungsliste mit „Deine Ergebnisse“ (FR-003, FR-014 5) als Seite,
  in einer Karte. Beim Öffnen neu aufbauen (Stand, Ergebnisse, laufende Prüfungsbedingungen).
- **Vergleich:** der Vergleichsabschnitt (FR-004, FR-010, FR-012, FR-014 7) als Seite.
- **Konto:** Anmelden/Abmelden, „Verwaltung“ (nur Admins), Darstellung (FR-002 I),
  Lern-Erinnerung (FR-009). Die Quellen-Fußnote steht nur hier.

### 4. Übergänge (Nachtrag)
User-Wunsch: „Ich hätte gerne einen fließenden Übergang, wenn ich die Seite wechsel so ein Swoosh
oder so. Oben die Auswahlleiste verschiebt auch bei jedem Wechsel.“ und „Auch das Runterziehen der
Statistik soll smoother werden.“

1. **Seitenwechsel in Laufrichtung:**
   - Ein Ziel weiter rechts in der Leiste kommt von rechts, eins weiter links von links.
   - **Nacheinander, nicht übereinander:** Die alte Seite blendet in etwa 0,12 s aus und huscht
     dabei 36 dp zur Gegenseite. Erst danach (ab 0,12 s) gleitet die neue Seite in etwa 0,2 s
     herein (Versatz 36 dp, easeOutCubic) und blendet ein.
   - Nie liegen zwei Seiten sichtbar übereinander. Nachtrag: Gleichzeitig überblendet war das auf
     dem iPhone (Web-App) ein Geisterbild mit ineinandergeschobenen Titeln („LERORIGINAL-IHK-…“).
   - Die Leiste bleibt dabei stehen.
   - Gilt für Leiste, Kacheln und Zurück/Vor.
   - Nicht beim Rückweg aus einer Runde und nicht bei „weniger Bewegung“ bzw. „Animationen
     entfernen“; dann wird sofort gewechselt.
   - Zustand und Scrollposition der Seiten bleiben erhalten.
2. **Markierung gleitet:** Die Hinterlegung des aktiven Reiters gleitet zum neuen Reiter, statt zu
   springen. Im Web auf dem Handy liegt sie hinter dem Symbol. In der App übernimmt die
   `NavigationBar` das mit ihrem eigenen Indikator.
3. **Leiste springt nicht (Web):**
   - Ab 900 px bleibt der Platz für den Scrollbalken immer frei (`scrollbar-gutter: stable`).
   - Vorher rückte die mittig stehende Leiste um die halbe Scrollbalken-Breite (7,5 px), sobald
     eine Seite länger als der Bildschirm war.
4. **Statistik zum Ziehen:**
   - Antippen klappt gleitend auf und zu (≈ 0,34 s).
   - Beim Ziehen am Kopf folgt die Höhe dem Finger, der Pfeil dreht sich mit.
   - Beim Loslassen rastet sie ein: offen ab gut einem Drittel der vollen Höhe, oder bei einem
     schnellen Wisch (> 450 px/s über mehr als 24 px) in dessen Richtung. Sonst schnappt sie zurück.
   - Ein Klick direkt nach dem Ziehen (< 0,5 s) zählt nicht.

### Abnahme
- Handy 390 × 760 und 375 × 667: Start ohne Scrollen, alle sechs Funktionen und die Prüfungskarte
  sichtbar, „Tage in Folge“ und „Kostenwesen“ nicht abgeschnitten (auch bei 320 und 360 dp Breite).
  Desktop 1280 × 800 ebenso.
- Statistik: Antippen öffnet und schließt gleitend, ein schneller Wisch nach unten öffnet, nach
  oben schließt. Langsam 100 dp ziehen: Die Leiste ist so weit offen, loslassen → zu. Über ein
  Drittel ziehen und loslassen → offen. Aufgeklappt sind Radar, Aktivität, Erfolge und
  „Lernstand zurücksetzen“ erreichbar.
- Seitenwechsel: Start → Prüfungen gleitet von rechts, Prüfungen → Lernen von links. Die
  Scrollposition von „Lernen“ bleibt beim Hin und Her erhalten.
- Seitenwechsel Bild für Bild (Bildschirmaufnahme, iPhone-Web-App und App): Kein Bild zeigt alte
  und neue Seite zugleich deutlich – auch nicht bei unterschiedlich langen Seiten (Prüfungen →
  Vergleich).
- Web, Desktop mit sichtbaren Scrollbalken: Start → Lernen → Prüfungen → Konto → Start, die
  Leiste steht auf den Pixel still.
- Leiste: jede Seite öffnet sich, das aktive Ziel ist markiert, die Seite beginnt oben.
- Web: Adresse `#/lernen` direkt aufrufen → Lernen. Zurück/Vor im Browser wechselt die Seiten.
  `#/gibtsnicht` → Start mit Adresse `#/`.
- Kachel „Lernen“ → Seite Lernen. „Mündlich“ und „Fallaufgaben“ starten direkt, ✕ führt zurück
  auf Start. Training von „Lernen“ aus starten, ✕ → wieder Lernen.
- Zurück mitten in einer Runde beendet sie. Unter Prüfungsbedingungen erst nach der Nachfrage,
  die Uhr läuft weiter.
- Ohne Rangliste: vier Ziele, `#/vergleich` → Start.
- Freundschaftsanfrage oder Einladung offen → Punkt an „Vergleich“; angenommen → Punkt weg.
- Einladungslink → Seite Vergleich mit der Einladung.

### Referenz Web-Implementierung (`index.html` auf `claude/ui-design-improvement-my0f66`)
- **CSS:**
  - Block „Seiten und Navigation“, Z. 999; Scrollbalken-Platz Z. 1027, Seitenwechsel Z. 1028
  - Block „Start: ohne Scrollen“, Z. 1068
- **HTML:**
  - Leiste `#seitenNav` mit Markierung `#snZeiger`, Z. 1819
  - Statistik `#statLeiste` mit `#statRahmen`, Z. 1840
  - Funktionen `.start-fn`, Z. 1901
  - Seite `#seiteLernen`, Z. 1913
- **JS:**
  - `seiteZeigen` samt Übergang, Z. 5123
  - Markierung `zeigerSetzen`, Z. 5164
  - Zurück-Taste (`hashchange`), Z. 5191
  - Statistik antippen und ziehen, Z. 5204
  - Hinweispunkt in `vgZeigen`, Z. 5741
  - Einladungslink → Vergleich, Z. 5491
  - Rückkehr vom Google-Login, Z. 6417
- **App:** `lib/widgets/seiten_stapel.dart` (Seitenwechsel), `_OberLeiste` in
  `lib/screens/home_screen.dart` (Markierung ab 900 dp), `lib/widgets/start/stat_leiste.dart`
  (Statistik zum Ziehen).

Zeilennummern: Stand dieses Commits.
