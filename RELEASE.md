# Auto-Release an Google Play (mit automatischen Patch-Notes)

Ziel: **du schreibst & pushst – die App aktualisiert sich im Play Store von selbst.**

## So läuft es nach der Einrichtung

1. Du arbeitest wie gewohnt und pushst; wenn es auf **`main`** landet (Merge des
   Feature-Branches), startet der Workflow **„Play-Release (Android)"**.
2. Der Workflow **baut ein signiertes AAB**, zählt die `versionCode` automatisch
   hoch (= Anzahl der Commits), erzeugt die **„Was ist neu"-Notes aus deinen
   Commit-Nachrichten** und lädt alles per Play-API in den gewählten **Track**
   (Standard `internal`).
3. Google prüft das Update (meist automatisch/Stunden), danach aktualisieren sich
   die Geräte automatisch (Play-Einstellung der Nutzer).

Manuell auslösen (z. B. direkt nach `production`): Actions → *Play-Release
(Android)* → **Run workflow** → Track wählen.

> Ohne die unten genannten Secrets läuft der Workflow bewusst **grün** durch und
> überspringt nur die Veröffentlichung – du kannst also gefahrlos schon jetzt pushen.

---

## Einmalige Einrichtung (nur du, ~30–45 Min)

### 1. Application ID final festlegen
Aktuell: `com.kvmtrainer.kvm_trainer` (in `flutter_app/android/app/build.gradle.kts`
und `.github/workflows/play-release.yml` → `PACKAGE_NAME`).
**Wichtig:** Die ID lässt sich nach der ersten Play-Veröffentlichung **nie mehr
ändern**. Wenn du eine eigene Domain hast, nimm z. B. `de.deinname.kvmtrainer`.
Sag mir die gewünschte ID, dann setze ich sie an beiden Stellen.

### 2. Google Play Console
- Konto anlegen (einmalig **25 €**): https://play.google.com/console
- Neue App anlegen (Name, Sprache DE, „App", kostenlos).

### 3. Upload-Keystore erzeugen (lokal, einmalig)
```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Passwörter gut merken. **Diese Datei niemals ins Repo committen** (ist in
`.gitignore`). In der Play Console **Play App Signing** aktivieren – Google
verwaltet den finalen Signaturschlüssel, du lieferst nur den Upload-Key.

### 4. Service-Account für die Play-API
- Google Cloud Console → Projekt → Service-Account anlegen → JSON-Key erzeugen.
- Play Console → *Nutzer und Berechtigungen* → den Service-Account einladen und
  Freigabe für **Releases** erteilen (API-Zugriff unter *API-Zugriff*/„Google Play
  Android Developer API").

### 5. Erste Veröffentlichung einmal manuell
Google verlangt das **allererste** AAB eines neuen Pakets über die Console:
- Secrets setzen (Schritt 6), Workflow einmal manuell starten → er legt das
  **AAB als Artefakt** `kvm-trainer-aab` am Lauf ab.
- Dieses AAB in der Play Console als erstes **Internal-Testing**-Release hochladen.
- Danach übernimmt die API alle weiteren Uploads automatisch.

### 6. GitHub-Secrets hinterlegen
Repo → *Settings → Secrets and variables → Actions → New repository secret*:

| Secret | Inhalt |
|--------|--------|
| `PLAY_SERVICE_ACCOUNT_JSON` | kompletter Inhalt der Service-Account-JSON |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` (der ganze String) |
| `ANDROID_KEYSTORE_PASSWORD` | Store-Passwort aus Schritt 3 |
| `ANDROID_KEY_ALIAS` | `upload` (bzw. dein Alias) |
| `ANDROID_KEY_PASSWORD` | Key-Passwort aus Schritt 3 |

`base64` unter macOS/Linux:
```bash
base64 -w0 upload-keystore.jks   # Linux
base64 upload-keystore.jks | tr -d '\n'   # macOS
```

---

## Store-Eintrag: Name & Auffindbarkeit (Play Console → „Store-Präsenz")

Damit die App bei der Suche nach **„Industriemeister"** schnell gefunden wird,
steht das Suchwort vorne im Titel. Das kurze Icon-Label (`android:label`) ist
bewusst knapp gehalten, damit es unter dem Icon nicht abgeschnitten wird.

| Feld | Wert |
|------|------|
| **App-Titel** (Play, max. 30 Z.) | `Industriemeister Trainer – IHK` |
| **Icon-Label** (unter dem Icon) | `Meister-Trainer` (in der App gesetzt) |
| **Kurzbeschreibung** (max. 80 Z.) | `IHK-Prüfungstrainer für Industriemeister – Basisqualifikationen & KVM` |

**Keywords fürs Beschreibungsfeld** (Google indexiert die Langbeschreibung –
diese Begriffe natürlich einbauen): Industriemeister, IHK-Prüfung,
Basisqualifikationen, Meisterprüfung, Kraftverkehrsmeister, KVM, Prüfungsvorbereitung,
Recht, BWL, Handlungsspezifische Qualifikationen, Lernkarten, Spaced Repetition.

> Titel/Beschreibung werden **manuell in der Play Console** gepflegt (nicht per
> Workflow). Der Icon-Label-Name kommt aus `AndroidManifest.xml`, der OS-Titel
> (Task-Switcher) aus `MaterialApp(title:)`.

---

## Tracks & Rollout
- `internal` (Standard): sofort, kleiner Testerkreis – ideal fürs schnelle Draufschauen.
- `alpha`/`beta`: geschlossene/offene Tests.
- `production`: für alle. Für einen stufenweisen Rollout in der Console den
  Prozentsatz setzen.

## Was automatisch passiert
- **versionCode**: `git rev-list --count HEAD` → monoton steigend, kein manuelles Zählen.
- **versionName**: aus `flutter_app/pubspec.yaml` (`version:` vor dem `+`). Für eine
  neue Marketing-Version dort z. B. `1.1.0` eintragen.
- **Patch-Notes**: `tools/gen_patch_notes.py` erzeugt sie aus den Commit-Betreffs
  seit dem letzten `v*`-Tag (technische Commits wie `ci:`/`chore:` werden gefiltert).
  Play-Limit 500 Zeichen wird eingehalten; ein längeres Changelog landet im
  GitHub-Release. **Tipp:** aussagekräftige Commit-Titel = gute Patch-Notes.

## Sicherheit
Keystore und `key.properties` werden nur zur Laufzeit aus Secrets erzeugt, nach dem
Build wieder gelöscht und sind per `.gitignore` vom Repo ausgeschlossen. Die
JSON-/Passwörter liegen ausschließlich in GitHub-Secrets.
