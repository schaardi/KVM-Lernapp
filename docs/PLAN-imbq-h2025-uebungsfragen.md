# Plan: Übungsfragen aus den IHK-Basisqualifikations-Prüfungen Herbst 2025

Umsetzungsplan für die nächste Session. Alles Arbeitsmaterial liegt im Repo;
die hochgeladenen PDFs werden nicht benötigt (und dürfen nicht eingecheckt
werden, siehe „Rechtliches").

## Ziel

Aus den vier **bundeseinheitlichen IHK-Prüfungen der fachrichtungsübergreifenden
Basisqualifikationen (Industriemeister), Herbst 2025** – jede mit **amtlichen
Lösungshinweisen** – eigenständige Übungsfragen (Auswahl/Rechnen) erzeugen und
in den Fragenpool der App einspielen, genau wie zuletzt bei den Kraftverkehr-
Prüfungen (PR #33, 127 `PX-`-Fragen).

Entscheidungen des Nutzers (5. 9. 2026):

- **Alle vier Prüfungen** einbeziehen: Recht, BWL, Zusammenarbeit **und NTG**.
- **Nur Übungsfragen**, keine startbaren Prüfungs-Chats.
- Die Fallstudie „HPI #1 – Der stille Leistungsabfall" (offene Aufgabe **ohne**
  amtliche Lösung) wird **ausgelassen**.

## Ausgangslage – was vorliegt

Die vier Prüfungen sind Word-erzeugte PDFs **mit sauberem Textlayer** – anders
als bei der Kraftverkehr-Sammlung ist **keine OCR** nötig. Der Text liegt mit
Seitenmarkern (`=== Seite N ===`) unter `scripts/pruefungen/quellen/imbq-h2025/`:

| Datei | Prüfung (Basisqualifikation) | Datum | Aufgaben | Teile | Punkte Frage/Lösung | App-Fach |
|---|---|---|---|---|---|---|
| `01-recht.txt` | Rechtsbewusstes Handeln | 5. 11. 2025 | 7 | 20 | **100 / 100** | 1 Recht |
| `02-bwl.txt` | Betriebswirtschaftliches Handeln | 6. 11. 2025 | 7 | 17 | **100 / 100** | 2 BWL |
| `04-zusammenarbeit.txt` | Zusammenarbeit im Betrieb | 6. 11. 2025 | 8 | 14 | **100 / 100** | 4 Zusammenarbeit |
| `05-ntg.txt` | Naturwissenschaftliche und technische Gesetzmäßigkeiten | 5. 11. 2025 | 7 | 18 (Frage) / 19 (Lösung) | **97 / 100** – siehe Abweichung | neu, siehe unten |

Aufbau ist bei allen vieren identisch und dem Kraftverkehr-Format sehr ähnlich:

1. **Deckblatt** mit `Datum:`, `Bearbeitungszeit:`, `Anzahl Aufgaben:`.
2. **Aufgabenteil**: `Ausgangssituation zu allen Aufgaben`, dann `Aufgabe N`,
   darunter Teilaufgaben mit Badge `a Mögliche Punktzahl: N`. **Neu gegenüber
   Kraftverkehr:** Aufgaben ohne Teilaufgaben tragen die Punktzahl **ohne
   Buchstaben** (`Mögliche Punktzahl: 12`) – der Parser muss das Badge optional
   machen und solche Aufgaben als einzelnen Teil `a` führen (BWL A1/A5/A7,
   ZiB A1–A3, NTG A2/A6).
3. **Lösungsteil**: beginnt mit einer Zeile, die nur `Lösungshinweise` enthält,
   wiederholt Datum/Anzahl Aufgaben und den Hinweis „Die folgenden Lösungen sind
   lediglich Lösungshinweise …", dann je Aufgabe `Lösungshinweise Aufgabe N` mit
   denselben Punktmarkern. **Kein** VO-Bezug wie bei Kraftverkehr.

Bekannte Abweichung: **NTG Aufgabe 1** hat im Frageteil a/b/c (4+4+2 = 10 P),
im Lösungsteil a/b/c/d (4+4+2+3 = 13 P). Vermutlich fehlt im Frageteil auf
Seite 2 das Badge `d` (Textlayer-Zeilenumbruch) – vor dem Generieren auf
`quellen/imbq-h2025/seiten/05-ntg-s2-02.jpg` prüfen und ggf. per Korrektur
ergänzen. Erst dann ergibt NTG 100/100.

Bild-/Tabellenabhängige Aufgaben (Seiten als JPEG unter
`quellen/imbq-h2025/seiten/` gesichert):

- **BWL A5** (10 P): Geschäftsfälle sind in **Anlage 1** (Tabelle, S. 8)
  zuzuordnen; die amtliche Lösung liegt **nur als Bild** vor (S. 17, „Lösungs-
  hinweis zu Aufgabe 5"). → Lösung von `02-bwl-s17-17.jpg` ablesen und als Text
  in den Generator geben, sonst Aufgabe überspringen.
- **NTG A3** (Abbildung 1, Fahrzeug auf Rampe, S. 3), **A5** (Typenschild
  Elektromotor, S. 5), **A6** (Abbildung 3, gemischte Schaltung, S. 6): die
  Zahlenwerte stehen teils nur in der Abbildung. → Werte aus den JPEGs ablesen
  und in den Fragetext übernehmen; was sich nicht eigenständig (ohne Bild)
  stellen lässt, auslassen. Lösungsseite mit Rechenweg: `05-ntg-s11-11.jpg`.

## Rechtliches (bitte bewusst entscheiden)

Die PDFs tragen den Vermerk „Einsatz nur im Rahmen des Korrekturprozesses
gestattet. Weitergabe an unbefugte Dritte untersagt" (DIHK-Copyright). Der
Volltext liegt jetzt – wie schon die Kraftverkehr-OCR – im **öffentlichen**
Repo. Die abgeleiteten Übungsfragen sind eigenständig formuliert; die
Quelltexte selbst könnten nach der Umsetzung aus dem Repo entfernt (und nur
lokal behalten) werden. Das ist eine Entscheidung des Nutzers, nicht des
Umsetzers.

## Teil A – Pipeline (Deltas zur Kraftverkehr-Umsetzung)

Wiederverwendet werden `scripts/pruefungen/build_exam_questions.py` (Einfügen,
Validierung, `PX-`-IDs, Dublettenprüfung) und der Generier-/Prüf-Workflow aus
PR #33 (je Prüfung ein Autor, je Frage ein adversarischer Gegenprüfer). Die
Deltas:

### A1 – Parser `parse_imbq.py` (neu, klein)

Ein eigener Parser statt Anpassung von `parse_amtlich.py` (andere Kopfzeile,
kein Saison-Booklet, kein VO-Bezug). Pro Datei:

- Kopf: `Datum:`, `Anzahl Aufgaben:`; Bereich aus dem Dateinamen
  (`01-recht` → Recht usw.).
- Trennung Frageteil/Lösungsteil an der ersten Zeile, die exakt
  `Lösungshinweise` lautet.
- Aufgaben: `^Aufgabe (\d+)$` bzw. `^Lösungshinweise Aufgabe (\d+)$`.
- Teile: `^(?:([a-h])\s+)?Mögliche Punktzahl:\s*(\d+)$` – Badge **optional**;
  ohne Badge → Label `a`.
- Zuordnung Lösung↔Frage je Aufgabe über die Label-Reihenfolge; Punkte müssen
  je Label übereinstimmen (Ausnahme NTG A1, siehe oben, per Korrektur lösen).
- Ausgabe wie zuletzt: je Prüfung eine Datei
  `scratch/exam_<kürzel>.json` mit `kontext` und `teile[]{kopf, aufgabe,
  loesung, bewertung}`; die `pdftotext -layout`-Zeilen zuvor mit `\s{2,}`
  einkürzen und Silbentrennungen (`Vertrags-\npartnern`) zusammenziehen.
- Invariante: **Frageteil = Lösungsteil = 100 Punkte** je Prüfung, sonst
  Abbruch mit Ausgabe der abweichenden Aufgabe.

### A2 – Fach-/Themenbereichs-Mapping

Recht, BWL, Zusammenarbeit: der Generator klassifiziert wie zuletzt in die
**bestehende** Taxonomie (Fach 1/2/4, `sub` aus der Liste in
`build_exam_questions.py`); der Builder korrigiert das Fach aus dem `sub`.

**NTG** passt in kein bestehendes Fach der Kraftverkehr-App. Vorschlag:

- **Neuer Themenbereich `Naturwissenschaftliche und technische Grundlagen`
  unter Fach 5.** Fach 5 ist der zuschaltbare Fachrichtungs-Slot („4 fix + 1
  wählbar") – dieselbe Rolle, die NTG beim Industriemeister als fünfte
  Basisqualifikation hat. Die Chemie-/Physik-/Elektrotechnik-Aufgaben (A1–A6:
  Redoxreaktion, Mischungsrechnung, schiefe Ebene, Energie/Generator,
  Motor-Typenschild, Widerstandsschaltung) landen dort.
- **NTG A7** (Normalverteilung, Fehlerquote einer Losgröße) gehört fachlich zu
  **Fach 3 · Statistik** – so klassifizieren, nicht unter NTG.
- Dafür nötig: `sub` in die Taxonomie von `build_exam_questions.py` (Fach 5)
  aufnehmen; in `index.html` `SUB_ORDER` (Zeile ~895) und in
  `flutter_app/lib/constants.dart` `kSubOrder` ergänzen (sonst sortiert der
  Bereich ans Ende). Die Themenbereich-Chips entstehen in Web und App aus den
  Daten (`subsOfFach`), es ist keine weitere UI-Änderung nötig.
- Formelbuch: die NTG-Formeln (Mischungsregel, Hangabtriebskraft, elektrische
  Leistung/Arbeit, Reihen-/Parallelschaltung) fehlen in `formulas.json`;
  optional als Gruppe „Physik & Elektrotechnik" ergänzen und
  `scripts/build_formulas.py` laufen lassen.

### A3 – Builder auf mehrere Quellen umstellen (wichtig)

`build_exam_questions.py` liest heute **eine** Eingabedatei und **ersetzt
alle** `PX-`-Fragen. Ein Lauf mit dem IMBQ-Satz würde die 127 Kraftverkehr-
Fragen **löschen**. Deshalb:

- Quellensätze versioniert unter `scripts/pruefungen/fragen/`:
  `kraftverkehr-2021-2026.json` (bereits abgelegt, 127 Fragen) und neu
  `imbq-h2025.json`.
- Builder liest **alle** `fragen/*.json`, vergibt IDs deterministisch je Fach
  fortlaufend (`PX-<F>-NNN`), dedupliziert über alle Sätze und den bestehenden
  Pool, schreibt Web + App. Idempotent: gleicher Input → identische Ausgabe.
- Bestehende IDs der 127 Kraftverkehr-Fragen sollen **stabil** bleiben
  (Lernfortschritt hängt an der ID): Reihenfolge Kraftverkehr zuerst, dann
  IMBQ – dann ändern sich die vergebenen Nummern der alten Fragen nicht.

### A4 – Generieren und Prüfen (Workflow)

Wie in PR #33: je Prüfung ein Autor-Agent (liest `exam_<kürzel>.json`, nur
die amtliche Lösung als Quelle, 4–10 Fragen, `mc` mit genau einer richtigen
Option oder `calc` mit `ans`+`unit`, eigenständig beantwortbar, `source`-Zitat),
dann je Frage ein Gegenprüfer (eindeutig richtig, aktuell, eigenständig,
Fach/`sub` gültig; im Zweifel verwerfen). Anpassungen:

- Taxonomie im Prompt um den neuen NTG-Bereich erweitern; NTG-Agent
  ausdrücklich anweisen, Statistik-Fragen nach Fach 3 zu legen und
  bildabhängige Werte nur zu verwenden, wenn sie im Fragetext genannt werden.
- Rechenaufgaben aus NTG/BWL sind zahlreich (Mischung, Rampe, Leistung,
  Widerstände, Kalkulation): Gegenprüfer rechnet nach; Einheit Pflicht.
- Erwartung: ~4 × 6–10 = 25–40 Fragen. Ergebnis als `fragen/imbq-h2025.json`
  ablegen (nicht nur im Scratchpad).

### A5 – Einspielen und Abnahme

1. `python3 scripts/pruefungen/build_exam_questions.py` (alle Quellensätze).
2. Prüfen: JSON gültig; IDs eindeutig; Kraftverkehr-IDs unverändert (Diff
   gegen `main`); `PX`-Menge Web == App; `tools/sync_content.py --check` und
   `--validate-assets` grün (Bewahrung der `PX-`-Fragen ist schon eingebaut).
3. Headless-Browser: Trainingsrunde Fach 1, 2, 4 und 5 – je eine `PX-`-Frage
   rendert, Themenbereich-Chip „Naturwissenschaftliche und technische
   Grundlagen" erscheint unter Fach 5, keine JS-Fehler.
4. CI `build-apk` grün (nur `questions.json`/`constants.dart` betroffen).
5. Commit auf `claude/meitner-app-build-6lnk2z`, PR, Merge → GitHub Pages.

## Reihenfolge und Aufwand

1. NTG-A1-Badge klären (Bild S. 2) und Korrektur eintragen – 10 min.
2. `parse_imbq.py` + 100-Punkte-Probe – 1 h.
3. Builder auf Mehrfach-Quellen – 30 min.
4. NTG-Sub in Taxonomie/`SUB_ORDER`/`kSubOrder` – 15 min.
5. Workflow (4 Autoren + ~35 Gegenprüfer) – läuft ~20–30 min.
6. Einspielen, Abnahme, PR – 30 min.

## Risiken

- **NTG-Mapping** ist eine Produktentscheidung (neuer Bereich unter Fach 5);
  der Plan setzt die vom Nutzer gewählte Einbeziehung so um. Alternative bei
  Nichtgefallen: NTG-Fragen weglassen, nur A7 nach Statistik.
- **Bildabhängige Aufgaben** (BWL A5, NTG A3/A5/A6) liefern ohne Ablesen der
  JPEGs keine eigenständigen Fragen – lieber weniger, dafür korrekte Fragen.
- **ID-Stabilität** der 127 vorhandenen `PX-`-Fragen: nur gewährleistet, wenn
  der Kraftverkehr-Satz beim Rebuild zuerst verarbeitet wird (A3).
- **Copyright** der Quelltexte im öffentlichen Repo (siehe oben).
