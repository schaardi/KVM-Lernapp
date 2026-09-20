# Plan: Prüfung grundlegend überarbeiten – wie am Prüfungstag

Stand 20. 9. 2026. Zweiter Teil des Opus-Auftrags, **nach**
`PLAN-ui-ueberarbeitung.md` umzusetzen (er setzt den klebenden Aufgabenkopf
U2, das Werkzeugpanel U1 und die App-Parität U4 voraus). Gegenstand ist die
**Original-IHK-Prüfung** als Ganzes: wie sie gestartet wird, wie sie abläuft,
wie sie bewertet wird, was davon bleibt. Inhalte und Pipeline bleiben
unangetastet; das Datenmodell bekommt genau ein zusätzliches Feld (`dauer`).

## 1. Auslöser

- „Und danach noch für die Prüfung, verbessere dort nochmal grundlegend."
  (Nutzer, 20. 9. 2026)
- Vorgeschichte: „Nutze diese ganzen Klausuren für unsere App." (14. 9.),
  danach 121 Original-Prüfungen mit amtlichen Lösungshinweisen und das
  Aufgabenblatt (Plan „Altklausuren und Aufgabenblatt", Teil B). Die
  Prüfung ist inhaltlich komplett, aber als **Prüfungserlebnis** noch ein
  Übungsblatt: kein Zeitlauf, Lösungen jederzeit aufdeckbar, kein
  Versuch, kein Verlauf, Ergebnis flüchtig.
- Aus dem Plan „Amtliche Lösungshinweise und UI-Politur" ist B7 („eigener
  letzter Stand je Prüfung") bis heute offen.

## 2. Leitbild

**Wie am Prüfungstag, danach wie beim Korrektor.** Jede Prüfung kennt zwei
Wege:

1. **Prüfung ablegen (Klausurmodus).** Zeitlauf nach amtlicher
   Bearbeitungszeit, alle Aufgaben frei anspringbar, Lösungen bis zur
   Abgabe gesperrt, Abgabe mit Bestätigung, bei Ablauf automatisch. Danach
   die **Korrekturphase**: eigene Antwort neben amtlichem Lösungshinweis,
   Punkte je Teilaufgabe nach Bewertungsschema, KI-Prüfauftrag je Aufgabe.
2. **Aufgaben üben.** Der heutige Ablauf: Aufgabe für Aufgabe, Lösung je
   Teil aufdecken, sofort bewerten, kein Zeitlauf.

Daraus folgen fünf Regeln:

- **Der Versuch ist die Einheit.** Jeder Durchlauf (Klausur oder Übung)
  ist ein gespeicherter *Versuch* mit Prüfung, Modus, Start, Ende,
  Antworten, Tabellen, Punkten, Zeit je Aufgabe und Ergebnis. Ein neuer
  Versuch beginnt leer; ein unterbrochener lässt sich fortsetzen.
- **Zeit ist echt.** 90 Minuten für die Basisqualifikationen (RE, BW, NT,
  MI, ZI – Textlayer: „Bearbeitungszeit: 90 Minuten"), 180 Minuten für die
  Kraftverkehrsmeister-Prüfungen (FT, OK). Der Zeitlauf überlebt Neuladen
  und App-Wechsel, weil das geplante Ende gespeichert wird, nicht der
  Restwert.
- **Bewerten wie ein Korrektor.** Punkte je Teilaufgabe, Bewertungsschema
  sichtbar, wo es die IHK angibt; Hinweise (welche Schlüsselzahlen der
  Lösung in der eigenen Antwort vorkommen) sind Hinweise, keine Noten.
- **Ergebnisse bleiben.** Verlauf je Prüfung, letzter und bester Versuch,
  Vergleich mit dem vorigen Versuch, Zeit je Aufgabe gegen den Richtwert
  (Punkteanteil × Bearbeitungszeit).
- **Web und App gleich.** Gleiche Begriffe („Prüfung ablegen", „Aufgaben
  üben", „Abgeben", „Korrektur", „Versuch"), gleicher Speicherschlüssel,
  gleiche Abnahmefälle.

## 3. Ist-Zustand (Befund vom 20. 9. 2026)

### 3.1 Web (`index.html`)

- **Start.** `startRound('cases', id, startIdx)` (Zeile 1356) baut den
  Pool aus den Schritten der Prüfung und öffnet das Aufgabenblatt
  (`blOeffnen`, 1965). Einen Zeitlauf gibt es nur im Modus `sim`
  (`SIM_LEN=30`, `SIM_SECONDS=3600`, Zeile 1226; Timer 1394) – das ist
  die „Prüfungssimulation" mit 30 Übungsfragen, nicht die Prüfung.
- **Ablauf.** Jede Teilaufgabe hat Antwortfeld und Knopf „Lösung zu x)
  aufdecken" (`blTeilHTML`, 2060); „Alle Lösungen dieser Aufgabe
  aufdecken" im Fuß (`renderBlatt`, 2090). Aufdecken ist jederzeit möglich,
  es gibt keine Abgabe. Der letzte Aufgaben-Knopf „Zum Ergebnis →" ruft
  `finishRound(false)` (2325).
- **Bewertung.** Nach dem Aufdecken Punkteknöpfe 0…max (`blLoesungHTML`,
  2023), gespeichert in `kvm_open_points` je Schritt-ID (`opSet`, 1443);
  `blFortschritt` (2238) meldet „gewusst" an die Wiederholungslogik, wenn
  mindestens die Hälfte der Punkte vergeben ist. Bewertungsschema
  (`bewertung`) nur bei 20 von 2 030 Teilaufgaben vorhanden.
- **Ergebnis.** `scrResult` (956): Ring, Bestanden-Badge mit
  IHK-Notenschlüssel (`ihkGrade`, 1887: 92/81/67/50/30), Balken je
  Themengebiet, Punkte je Aufgabe. **Flüchtig** – nichts wird gespeichert;
  Knöpfe „Neue Runde starten", „Zur Startseite", „Nur Fehler wiederholen".
- **Kein Versuch, kein Verlauf.** `localStorage` kennt nur `kvm_progress_v1`
  (Karteikasten je Frage), `kvm_open_answers`, `kvm_open_points`,
  `kvm_open_tabs`, `kvm_zusatz_v1`, `kvm_voice`. Antworten und Punkte
  liegen global je Schritt-ID: wer dieselbe Prüfung ein zweites Mal
  startet, sieht seine alten Antworten und alten Punkte. Der einzige
  Reset (`btnReset`, 2437) löscht den Karteikasten, nicht Antworten,
  Punkte oder Tabellen.
- **Übersicht** `mPruef` (`render`, 4245): nach Termin gruppiert, Filter
  je Fach, je Prüfung „Prüfung starten", „Für KI-Prüfung kopieren", Zahl
  der bearbeiteten Teile. Die Zeile „… · 180 Minuten" ist **fest
  verdrahtet** (4304) – für 108 der 121 Prüfungen falsch (90 Minuten).
  Kein letztes Ergebnis, keine Note, kein Datum.
- **Cloud.** `push`/`pull` (2474/2476) sichern nur `progressSubset()`
  (gesehen/richtig/falsch/Fach) in der Supabase-Tabelle `progress`.
  Antworten, Punkte, Tabellen werden nicht gesichert.
- **Referenzlauf** (`tools/headless/beispiele/pruefung-ablauf.js`, heute):
  Übersicht zeigt für `P-BW-20201103` „3. November 2020 · 7 Aufgaben mit
  16 Teilaufgaben · 180 Minuten"; `timer_bei_pruefung=false`; drei
  Aufdeck-Knöpfe schon vor jeder Abgabe; nach dem Ergebnis
  `versuch_gespeichert=[]` und die Antwort bleibt in `kvm_open_answers`.

### 3.2 App (`flutter_app/lib/`)

- `screens/pruefungen_screen.dart` (349 Zeilen): dieselbe Liste, „180
  Minuten" fest verdrahtet (Zeile 232), Punkte per Regex aus dem
  Kontexttext (44), „Prüfung starten", „Für KI kopieren"; kein Ergebnis,
  kein Verlauf.
- `screens/aufgabenblatt_screen.dart`: `_bewerten` → `AnswerStore.setPoints`
  (157), `_zumErgebnis` → `ResultScreen(mode: cases, …)` (173); kein
  Zeitlauf, keine Abgabe, kein Versuch.
- `screens/result_screen.dart` (275 Zeilen): wie Web, flüchtig.
- `services/answer_store.dart`: `kvm_open_answers`, `kvm_open_points`,
  `kvm_open_tabs` lokal; `services/progress_service.dart` (`kvm_progress_v1`)
  ist das Einzige, was `sync_service.dart` in die Tabelle `progress`
  schreibt.
- `round_builder.dart`: `RoundMode.sim` = `kSimLen` Fragen, 60 Minuten
  (Startseite 262); `RoundMode.cases` ist leer, die Prüfung öffnet den
  `AufgabenblattScreen` direkt.

### 3.3 Daten (`data/cases.js`, 136 Fälle, davon 121 `P-`)

- Je Prüfung: `id`, `f`, `sub`, `title`, `termin` (24 Termine, Frühjahr
  2015 … Herbst 2025 plus Eigene), `amtlich` (alle 121), `context`,
  `aufgaben[{nr,pts,sit,…}]` (5–9 Aufgaben), `steps[]` (10–25 Teile; alle
  `t:'open'`, alle mit amtlicher Lösung `a`, 1 936 mit `vo`, 20 mit
  `bewertung`, 14 mit `braucht`). Summe `pts` je Prüfung = 100, immer.
- Kürzel → Fach: RE 1, BW 2, MI 3, ZI 4, OK 4, NT 5, FT 5. Zahlen je
  Kürzel: RE 22, BW 22, NT 22, ZI 22, MI 20, OK 8, FT 5.
- **Keine Bearbeitungszeit im Datensatz.** Nur die FT/OK-Kontexte tragen
  „Bearbeitungszeit 180 Minuten" im Fußtext; die IMBQ-Kontexte nicht. In
  den Textlayern (`scripts/pruefungen/quellen/imbq-*`) steht 118-mal
  „Bearbeitungszeit: 90 Minuten".

## 4. Arbeitspakete

Reihenfolge ist Abhängigkeitsreihenfolge. P0–P3 sind der Kern (Web), P4
zieht die App nach, P5 und P6 runden ab. Jedes Paket ein eigener Commit
mit Abnahme per Headless-Lauf (Abschnitt 6) oder Flutter-CI.

### P0 – Bearbeitungszeit in die Daten, Versuchsspeicher anlegen

- **`dauer` (Minuten) je Prüfung**, additiv: 90 für RE/BW/NT/MI/ZI, 180 für
  FT/OK. Gesetzt in dem Builder, der die Fälle erzeugt
  (`scripts/pruefungen/build_imbq.py` für die Basisqualifikationen,
  `build_amtlich.py` für FT/OK, zusammengeführt in `build_cases.py`;
  Quelle: Textlayer „Bearbeitungszeit"),
  durchgereicht über `tools/webdaten.py` nach `data/cases.js` und
  `flutter_app/assets/data`; `tools/sync_content.py --check` und
  `--validate-assets` bleiben grün. Web und App lesen `dauer` mit
  Rückfall nach Kürzel (FT/OK → 180, sonst 90), damit alte Datenstände
  weiter laufen. Die festen „180 Minuten" (index.html 4304,
  `pruefungen_screen.dart` 232) verschwinden.
- **Versuchsspeicher** `kvm_versuche_v1` (Web `localStorage`, App
  `SharedPreferences`, gleicher Schlüssel und gleiches JSON):

  ```
  { "<versuchId>": {
      id, pruefung: "P-BW-20201103", modus: "klausur" | "ueben",
      start: ISO, endeUm: ISO | null,   // Klausur: geplantes Ende
      ende: ISO | null, abgegeben: bool, korrigiert: bool,
      antworten: { stepId: text }, tabellen: { key: { "z-s": wert } },
      punkte: { stepId: n }, aufgedeckt: [stepId], zeitJeAufgabe: { nr: sek },
      ergebnis: { punkte, moeglich, prozent, note, bestanden,
                  jeAufgabe: [{nr, got, max, sek}], jeSub: [{sub, got, max}],
                  unbewertet: n } } }
  ```

  **Arbeitskopie bleibt.** Während ein Versuch läuft, arbeiten
  `kvm_open_answers`, `kvm_open_points` und `kvm_open_tabs` wie heute –
  aller bestehender Code (`oaGet/oaSet`, `otSet`, `opSet`, Tabellen,
  Formelvorlage) bleibt unverändert. Beim Start eines neuen Versuchs
  werden die Einträge der Schritt-IDs **dieser Prüfung** aus der
  Arbeitskopie in den vorigen Versuch gesichert und geleert; bei
  „Fortsetzen" zurückgespielt. Funktionen: `vsNeu(pruefung, modus)`,
  `vsAktiv(pruefung)`, `vsSichern()`, `vsFortsetzen(id)`,
  `vsAbschliessen(ergebnis)`, `vsListe(pruefung)`; Brücken
  `window.KVM_versuch*` für die anderen Skriptblöcke.
- **Abnahme:** `data/cases.js` trägt bei allen 121 `P-`-Fällen `dauer`
  (Headless: `KVM_CASES.filter(c=>c.id.startsWith('P-')&&!c.dauer).length===0`);
  Übersichtszeile zeigt „90 Minuten" für `P-BW-20201103` und „180 Minuten"
  für `P-OK-20210518`; Start eines zweiten Versuchs derselben Prüfung
  zeigt leere Antwortfelder, der erste Versuch liegt mit seinen Antworten
  in `kvm_versuche_v1`.

### P1 – Klausurmodus (Web)

- **Startdialog** aus der Übersicht und vom Aufgabenblatt: „Prüfung
  ablegen · 90 Minuten · 100 Punkte" oder „Aufgaben üben"; bei einem
  unterbrochenen Versuch stattdessen „Fortsetzen (noch 37 Minuten)" und
  „Neu beginnen".
- **Zeitlauf** im klebenden Aufgabenkopf (U2): Restzeit aus `endeUm`,
  jede Sekunde neu gerechnet (kein `timeLeft--`), Warnung bei 15 und 5
  Minuten (`aria-live="polite"`), bei 0 automatische Abgabe. Neuladen der
  Seite setzt den Versuch fort (`vsAktiv` beim Start prüfen).
- **Gesperrte Lösungen.** Im Klausurmodus rendert `blTeilHTML` keine
  Aufdeck-Knöpfe, `renderBlatt` keinen „Alle Lösungen …"-Knopf; die
  Stepper-Pillen zeigen nur „beantwortet/teilweise/leer". Werkzeugpanel
  (U1) bleibt verfügbar – Rechner und Formelsammlung sind in der IHK-
  Prüfung zugelassen.
- **Abgabe.** Knopf „Abgeben" im Fuß jeder Aufgabe; Bestätigung nennt die
  Zahl unbeantworteter Teile („3 von 16 Teilaufgaben sind leer. Trotzdem
  abgeben?"). Danach `vsSichern`, `abgegeben=true`, Wechsel in die
  Korrekturphase (P2).
- **Zeit je Aufgabe.** Sekunden werden der angezeigten Aufgabe
  zugeschrieben (`visibilitychange` pausiert die Zählung nicht – wie in
  der Prüfung). Richtwert je Aufgabe = `pts/100 × dauer`.
- **Abnahme** (`tools/headless/beispiele/klausur-ablauf.js`, neu):
  Klausurstart auf `P-BW-20201103` → Timer sichtbar mit „90:00" (oder
  „1:30:00"), `aufdeck_knoepfe_vor_abgabe=0`, `kvm_versuche_v1` enthält
  genau einen Versuch mit `endeUm`; nach `KVM_versuchAbgeben()` sind alle
  16 Teile als `.bl-loesung` gerendert; ein Versuch mit `endeUm` in der
  Vergangenheit wird beim Öffnen automatisch abgegeben.

### P2 – Korrekturphase und bleibendes Ergebnis (Web)

- **Korrekturansicht** = Aufgabenblatt im Zustand „Korrektur": je Teil die
  eigene Antwort (schreibgeschützt, ausgefüllte Tabellen daneben), der
  amtliche Lösungshinweis, VO-Bezug, Bewertungsschema (falls `bewertung`),
  Punkteknöpfe wie heute. Neu: **Schlüsselzahlen-Abgleich** – Zahlen mit
  Einheit aus dem Lösungshinweis (`werteAusText` aus U2), grün wenn sie in
  der eigenen Antwort oder Tabelle vorkommen, grau sonst; Beschriftung
  „Hinweis, keine Bewertung". Der KI-Prüfauftrag je Aufgabe (`blExport`,
  2248) bleibt und nimmt die Punkte des Versuchs mit.
- **Korrektur abschließen** (Fuß der letzten Aufgabe, jederzeit möglich):
  unbewertete Teile zählen 0 Punkte und werden im Ergebnis als
  „unbewertet" ausgewiesen; `vsAbschliessen` schreibt `ergebnis`.
- **Ergebnis** (`scrResult`, umgebaut): Kopf mit Note/Bestanden,
  Punkten, Zeitverbrauch; Vergleich mit dem vorigen Versuch derselben
  Prüfung („+12 Punkte gegenüber 14. 9."); Punkte je Aufgabe mit Zeit
  gegen Richtwert („Aufgabe 5 · 9/16 P · 21 min, Richtwert 14"); Balken je
  Themengebiet wie heute. Knöpfe: „Korrektur ansehen", „Prüfung erneut
  ablegen", „Aufgaben üben", „Zur Übersicht". Das Ergebnis ist aus dem
  Verlauf (P3) jederzeit wieder aufrufbar.
- **Übungsmodus** nutzt dieselben Bausteine: Aufdecken je Teil wie heute,
  „Zum Ergebnis" schließt den Versuch mit `modus:'ueben'` ab.
- **Abnahme:** nach Abgabe und Vergabe von Punkten auf zwei Teilen liefert
  `KVM_versuchAktiv('P-BW-20201103').ergebnis` `punkte`, `note`,
  `unbewertet=14`; das Ergebnis erscheint nach `location.reload()` über
  die Übersicht erneut; der Schlüsselzahlen-Abgleich markiert bei
  Aufgabe 5 eine Zahl aus dem Lösungshinweis grün, wenn sie in der
  eigenen Tabelle steht.

### P3 – Prüfungsübersicht mit Verlauf (Web)

- Je Prüfung eine Karte: Fach, Termin, Dauer, Aufgaben/Teile, **Status**
  (nie begonnen · unterbrochen · abgegeben, unkorrigiert · abgeschlossen),
  **letzter Versuch** (Datum, Punkte, Note), **bester Versuch**, Zahl der
  Versuche; Knöpfe „Prüfung ablegen", „Aufgaben üben", bei Bedarf
  „Fortsetzen", „Ergebnisse" (Verlaufsliste mit allen Versuchen, Tipp
  öffnet das Ergebnis).
- Filter je Fach wie heute, dazu Status-Chips (offen · unterbrochen ·
  bestanden · nicht bestanden); Sortierung nach Termin, alternativ nach
  letztem Versuch.
- Kopfzeile der Übersicht: „121 Prüfungen · 14 abgelegt · Ø 61 Punkte"
  und der Vorschlag „Als Nächstes: NT Herbst 2021 (Fach mit den wenigsten
  Versuchen)".
- Startseiten-Kachel „Original-IHK-Prüfungen" zeigt die drei letzten
  Versuche mit Note; die alte „Prüfungssimulation" heißt fortan
  „Fragen-Test (30 Fragen, 60 Minuten)", damit „Prüfung" nur noch die
  echte Prüfung meint.
- **Abnahme:** nach zwei abgeschlossenen Versuchen auf `P-BW-20201103`
  zeigt die Karte „2 Versuche", letzten und besten Versuch mit Note;
  Status-Filter „bestanden" blendet die Karte je nach Ergebnis ein oder
  aus; keine JS-Fehler, Übersicht bei 500 px ohne horizontales Scrollen.

### P4 – App: Versuche, Klausurmodus, Korrektur, Verlauf

- `models.dart`: `CaseStudy.dauer` (mit Rückfall nach Kürzel).
- `services/versuch_store.dart`: Gegenstück zu P0 (gleicher Schlüssel
  `kvm_versuche_v1`, gleiches JSON, Arbeitskopie in `AnswerStore`).
- `screens/aufgabenblatt_screen.dart`: Modus-Parameter, Zeitlauf im
  klebenden Kopf (U4), gesperrte Lösungen, Abgabe-Dialog, Korrekturzustand,
  Zeit je Aufgabe; `_zumErgebnis` schließt den Versuch ab.
- `screens/result_screen.dart`: aus dem Versuch gespeist, Vergleich mit
  dem vorigen Versuch, Zeit gegen Richtwert, Knöpfe wie Web.
- `screens/pruefungen_screen.dart`: Karten mit Status, letztem und bestem
  Versuch, Fortsetzen, Verlaufsliste; Startdialog; Startseite:
  „Fragen-Test" statt „Prüfungssimulation".
- **Abnahme:** `flutter analyze` ohne Befund; `flutter test` mit neuen
  Tests: Versuchsspeicher (neu → sichern → fortsetzen → abschließen),
  Richtwert-Rechnung, Notenschlüssel, `dauer`-Rückfall; Widget-Test: im
  Klausurmodus kein „aufdecken"-Text im Baum, nach Abgabe 16 Lösungskarten.
  CI-Logs lesen (`continue-on-error`).

### P5 – Rückfluss ins Lernen

- Teile mit weniger als der Hälfte der Punkte melden wie heute
  `recordResult(false)`; zusätzlich landen sie in einer Liste „Aus
  Prüfungen nachzuarbeiten" (Startseite, Zahl im Modus „Schwächen"), die
  den Übungsmodus genau dieser Teile startet (`KVM_startCase(id, idx)`
  mit `modus:'ueben'` und Vorauswahl).
- Ergebnisseite verlinkt je Aufgabe „Ähnliche Übungsfragen" nur dann,
  wenn eine Zuordnung Prüfung → Übungsfragen existiert; die gibt es
  heute nicht (Übungsfragen `PX-` tragen kein Feld zur Herkunftsaufgabe).
  Deshalb hier nur der Rückfluss über die Wiederholungslogik; die
  Zuordnung ist ein Inhaltsnachtrag (Nicht-Ziel, Abschnitt 8).
- **Abnahme:** nach einem Versuch mit zwei schwachen Teilen zeigt die
  Startseite „2 aus Prüfungen nachzuarbeiten", Klick startet den
  Übungsmodus mit genau diesen Teilen.

### P6 – Versuche in die Cloud (optional, zuletzt)

- Neue Tabelle `pruefungen` (`user_id`, `data jsonb`, `updated_at`) mit
  RLS wie `progress`; SQL in `SUPABASE_SETUP.md`. Die Supabase-Verbindung
  der Sitzung ist nicht autorisiert – das SQL führt der Nutzer aus.
- Web `push`/`pull` (2474/2476) und `sync_service.dart` bekommen einen
  zweiten Datensatz; Zusammenführung je Versuch-ID, jüngeres `ende`
  gewinnt; laufende Versuche werden nicht synchronisiert. Fehlt die
  Tabelle (HTTP 404), bleibt der Sync für Versuche still aus.
- **Abnahme:** ohne Tabelle keine Fehler in der Konsole; mit Tabelle
  (manuell durch den Nutzer) erscheint ein am Handy abgeschlossener
  Versuch im Web.

## 5. Regeln für die Umsetzung

Es gelten die Regeln aus `PLAN-ui-ueberarbeitung.md`, Abschnitt 5 (Branch,
Commit-Anhänge, kein Pull Request ohne Bitte, kein Modellname, getrennte
Skriptblöcke, Brücken über `window.KVM_*`, Flutter ohne SDK, CI-Logs lesen,
Geheimhaltung der PDFs, keine Agent-Fächer, keine Erinnerungen). Dazu:

- **Datenvertrag:** genau ein additives Feld `dauer` je Fall; alle anderen
  Felder, Schritt-IDs und Exporte zeichengleich. Die Arbeitskopie
  (`kvm_open_*`) bleibt in Form und Bedeutung erhalten.
- **Kein Zeitlauf ohne `endeUm`.** Restzeit wird immer aus dem
  gespeicherten Endzeitpunkt berechnet, nie aus einem Zähler.
- **Keine Bewertung durch die App.** Punkte vergibt der Nutzer; der
  Schlüsselzahlen-Abgleich und der KI-Prüfauftrag sind Hilfen und so
  beschriftet.
- **Versuche löschen** nur durch den Nutzer (Knopf „Versuch löschen" in
  der Verlaufsliste mit Bestätigung); der globale Reset (`btnReset`)
  fragt gesondert, ob auch Versuche gelöscht werden sollen.
- Nach jedem Paket die Statuszeile in Abschnitt 7 fortschreiben.

## 6. Prüfen ohne Bildschirm

Treiber und Testkopie wie in `PLAN-ui-ueberarbeitung.md`, Abschnitt 6.
Referenzlauf des heutigen Ablaufs:

```
node tools/headless/cdp.mjs http://127.0.0.1:8099/ tools/headless/beispiele/pruefung-ablauf.js
```

Heutige Werte: `picker_zeigt_180=true` (falsch für BW),
`timer_bei_pruefung=false`, `aufdeck_knoepfe_vor_abgabe=3`,
`letzter_knopf="Zum Ergebnis →"`, `ergebnis_zeile="1 von 100 Punkten · Note 6
(ungenügend)"`, `aufgaben_im_ergebnis=7`, `versuch_gespeichert=[]`,
`antworten_bleiben=["P-BW-20201103-s0"]`. Nach P0–P3 müssen daraus werden:
`picker_zeigt_180=false`, im Klausurmodus `timer_bei_pruefung=true` und
`aufdeck_knoepfe_vor_abgabe=0`, `versuch_gespeichert=["kvm_versuche_v1"]`,
`antworten_bleiben=[]` nach Abschluss.

Prüfaufgaben:

| Fall | Warum |
|---|---|
| `P-BW-20201103` (BW H2020, 90 min) | ausfüllbare Tabellen, `tabL`, 16 Teile |
| `P-OK-20210518` (OK F2021, 180 min) | 180-Minuten-Fall, langer Kontext |
| `P-NT-20241106` | Abbildung, Rechenaufgaben mit Schlüsselzahlen |
| `P-RE-20201102` | reine Textantworten, viele VO-Bezüge |
| `P-FT-20251111` (6 Teile mit `bewertung`) | Bewertungsschema in der Korrektur |

## 7. Stand

| Paket | Stand |
|---|---|
| P0 Bearbeitungszeit und Versuchsspeicher | offen |
| P1 Klausurmodus Web | offen |
| P2 Korrekturphase und bleibendes Ergebnis | offen |
| P3 Übersicht mit Verlauf | offen |
| P4 App-Parität | offen |
| P5 Rückfluss ins Lernen | offen |
| P6 Versuche in die Cloud | offen (optional) |
| Vorarbeit: Referenzlauf `pruefung-ablauf.js` | **fertig** 20. 9. 2026 |

## 8. Nicht-Ziele

- Keine automatische Benotung von Freitext, keine KI-Anbindung in der App;
  der Prüfauftrag bleibt Text zum Kopieren.
- Keine Zuordnung Übungsfragen ↔ Prüfungsaufgaben (Inhaltsnachtrag, eigener
  Plan).
- Keine Prüfungsplanung nach Kalender (Lernplan bis zum Prüfungstermin).
- Keine Änderung an Pipeline, Textlayern, Anlagen; die drei fehlenden
  Diagramm-Figuren bleiben der Nachtrag A6 aus
  `PLAN-altklausuren-und-aufgabenblatt.md`.
- Der „Fragen-Test" (bisher Prüfungssimulation) wird nur umbenannt, nicht
  umgebaut.

## 9. Abnahme des Gesamtplans

Erfüllt, wenn ein Nutzer `P-BW-20201103` im Klausurmodus startet, die Seite
nach 10 Minuten neu lädt und mit „noch 80 Minuten" weitermacht, abgibt,
in der Korrektur Punkte vergibt, ein gespeichertes Ergebnis mit Note und
Zeit je Aufgabe sieht, die Prüfung ein zweites Mal leer startet und in der
Übersicht beide Versuche mit Vergleich findet – im Web und in der App, ohne
JS-Fehler, mit grüner CI und grünem `sync_content.py --check`.
