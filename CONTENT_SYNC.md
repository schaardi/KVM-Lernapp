# Content-Sync – Austausch zwischen Content- und App-Session

Dieses Dokument ist die **Schnittstelle zwischen zwei Sessions/Branches** in
diesem Repo. Es beschreibt, wie der Fragenkatalog aus der Web-App in die native
App fließt – der Datenvertrag und der Ablauf.

## Rollen

| Rolle | Branch | Inhalt | Aufgabe |
|-------|--------|--------|---------|
| **Content-Session** | `claude/focused-meitner-ilnlqj` | `index.html` (Web-App) | Fragen, Fälle & Erklärungen pflegen – **Quelle der Wahrheit** |
| **App-Session** | `claude/meitner-app-build-6lnk2z` | `flutter_app/**` | native App bauen; Katalog aus dem Content syncen |

Der Fragenkatalog wird **nicht doppelt gepflegt**. Er entsteht in `index.html`
und wird von dort in die App-Assets (`flutter_app/assets/data/*.json`)
übernommen. Genau dieses Repo ist der gemeinsame Austauschpunkt.

## Datenvertrag (das muss die Content-Session einhalten)

Die Inhalte liegen in `index.html` als **JSON-fähige Globals** in eigenen
`<script>`-Blöcken. Der Sync liest genau diese beiden Namen:

```js
window.KVM_QUESTIONS = [ /* Fragen */ ];
window.KVM_CASES     = [ /* Fallaufgaben */ ];
```

Regeln:
- **Gültiges JSON** (doppelte Anführungszeichen bei Schlüsseln und Strings) –
  kein JS-Objektliteral mit unquoteten Keys. Der Ausdruck darf mehrzeilig sein,
  muss aber mit `[` beginnen und mit `]` (optional `;`) direkt vor `</script>` enden.
- Jeder `<script>`-Block enthält **genau einen** dieser Globals.

### Schema `window.KVM_QUESTIONS` (Array von Frage-Objekten)

| Feld | Typ | Pflicht | Bedeutung |
|------|-----|---------|-----------|
| `id` | string | ✔ | eindeutige ID (z. B. `B-VW-001`) – **repo-weit eindeutig** |
| `f` | int (1–5) | ✔ | Fach (1 Recht · 2 BWL · 3 Methoden · 4 Zusammenarbeit · 5 Kraftverkehr) |
| `sub` | string | ✔ | Themenbereich (siehe `kSubOrder` in `flutter_app/lib/constants.dart`) |
| `t` | `"mc"` \| `"calc"` \| `"open"` | ✔ | Fragetyp |
| `q` | string | ✔ | Fragetext |
| `o` | array | bei `mc` | Optionen: `{ "t": string, "ok"?: 1, "w"?: string }` – **genau eine** mit `"ok":1` |
| `e` | string | empfohlen | Erklärung |
| `a` | string | bei `open` | Musterantwort |
| `ans` | number | bei `calc` | numerisches Ergebnis |
| `unit` | string | optional | Einheit (bei `calc`) |

Beispiel:

```json
{
  "id": "B-VW-001", "f": 2, "sub": "Volkswirtschaft", "t": "mc",
  "q": "Welche Faktoren zählt die VWL zu den Produktionsfaktoren?",
  "o": [
    {"t": "Boden, Arbeit und Kapital", "ok": 1},
    {"t": "Rohstoffe, Arbeit und Kapital", "w": "Rohstoffe sind kein originärer Faktor."}
  ],
  "e": "Boden, Arbeit und Kapital sind die originären Produktionsfaktoren."
}
```

### Schema `window.KVM_CASES` (Array von Fallaufgaben)

| Feld | Typ | Pflicht | Bedeutung |
|------|-----|---------|-----------|
| `id` | string | ✔ | eindeutige Fall-ID (z. B. `F-LR-c1`) |
| `f` | int | ✔ | Fach |
| `sub` | string | ✔ | Themenbereich |
| `title` | string | ✔ | Titel der Handlungssituation |
| `context` | string | ✔ | Szenario-Text (Banner über allen Schritten) |
| `steps` | array | ✔ | Liste von **Frage-Objekten** (gleiches Schema wie oben) |

> Das Formelbuch (`var FORMULAS` in `index.html`) ist **nicht** Teil des
> Auto-Syncs (es ist JS, kein JSON) und wird separat in
> `flutter_app/assets/data/formulas.json` gepflegt.

## Ablauf des Austauschs

1. **Content-Session** pflegt Fragen/Fälle in `index.html` und pusht nach
   `claude/focused-meitner-ilnlqj`.
2. **Sync** übernimmt den Katalog in die App-Assets – auf einem der Wege:
   - **Automatisch (GitHub Actions):** Workflow **„Content syncen (Fragenkatalog)"**
     starten. Aus der Content-Session z. B. per
     ```bash
     gh workflow run "Content syncen (Fragenkatalog)" \
        --ref claude/meitner-app-build-6lnk2z \
        -f content_ref=claude/focused-meitner-ilnlqj
     ```
     Der Workflow synct, committet die geänderten Assets auf den App-Branch und
     stößt den APK-Build an.
   - **Manuell (App-Session):**
     ```bash
     git fetch origin claude/focused-meitner-ilnlqj
     python tools/sync_content.py            # schreibt questions.json & cases.json
     git add flutter_app/assets/data && git commit -m "Sync: Fragenkatalog" && git push
     ```
3. **Build:** Der Workflow **„App bauen (Android APK)"** erzeugt die
   installierbare APK (Artefakt + Release `android-latest`).

## Selbstprüfung (jederzeit)

```bash
# Ist die App auf dem Content-Stand?  (Exit 2 = Sync nötig)
python tools/sync_content.py --check

# Erfüllen die gebündelten Assets den Datenvertrag?
python tools/sync_content.py --validate-assets
```

Bricht der Sync mit Validierungsfehlern ab (z. B. „mc mit 2 richtigen
Optionen", doppelte `id`), liegt der Fehler **im Content** (`index.html`) und
sollte dort behoben werden. Der Build prüft die Assets ebenfalls und schlägt
bei Vertragsverletzungen fehl, bevor eine kaputte APK entsteht.

## Hinweis: index.html enthält jetzt Cloud-Login (an die Content-Session)
`index.html` hat einen optionalen Google-Login + Cloud-Sync (Supabase), der Konto
und Fortschritt mit der nativen App teilt. Bitte beachten:
- Die Sync-Logik liegt als IIFE `(function cloud(){…})()` **innerhalb** des großen
  App-IIFE (direkt vor dessen `})();`) und nutzt vorhandene Funktionen
  `progressSubset()`, `mergeFromCode()`, `saveProgress()`, `progress`, `MAX_BOX`,
  die Render-Kette und `$()`. **Diese nicht umbenennen/entfernen.**
- Der Supabase-Client kommt per `<script src=…supabase-js@2>` im `<head>`.
- Die frühere QR-/Lernstand-Code-Übertragung wurde entfernt (Sicherung läuft jetzt
  über den Konto-Login). Ein Home-Abschnitt „Konto & Sicherung" (`#cloudHint` /
  `#btnCloud`) ersetzt sie.
