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

**Status App-Session:** ⏳ offen
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
