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

**Status App-Session:** ⬜ offen
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
- [ ] Beim ersten Start sind alle 5 Fächer aktiv (Kraftverkehr an).
- [ ] Kraftverkehr abwählen: Radar zeigt 4 Zacken, Fortschritt/„Alle Themen"/
      „Heute fällig" ohne Fach-5-Fragen; Auswahl übersteht App-Neustart.
- [ ] Basisfächer haben keinen Schalter und sind nie abwählbar.
- [ ] Wieder anwählen stellt den vorigen Zustand her (5 Zacken etc.).

### Referenz Web-Implementierung (`index.html`, Commit auf Content-Branch)
- Logik: `BASE_FACHER/ZUSATZ_FACHER/zusatzActive/isFachActive/activeFacher/
  activeQuestions/toggleZusatz` (um Zeile 744–757).
- Rendering: `renderFachGroup(grid, fachs, isZusatz)` (Zeile 808), `renderProgress`
  (765), `renderReadiness`/`overallReife` (778–801), `dueList`/`dueCount` (657/658),
  Home-Untertitel (1144).
- HTML-Anker: `#fachGridBase`, `#fachGridZusatz`, `#zusatzNote`; Tags `.fixtag`,
  `.opttag`, `.fach-toggle`, `.fach.fach-off`.
