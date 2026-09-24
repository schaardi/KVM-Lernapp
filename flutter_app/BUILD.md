# Meister-Trainer – native Android-App (Flutter) für Google Play

Ein nativer Port der KVM-Lernapp mit **Flutter** – eine echte native **Android**-App
(keine WebView). 3.666 Fragen, 136 Fälle (davon 121 Original-IHK-Prüfungen), Anlagen und
das Formelbuch sind als Assets gebündelt (offline).

## Was drin ist
Stand der Web-App (FR-001 bis FR-015 in `../APP_FEATURE_REQUESTS.md`) – Überblick in
**[README.md](README.md)**.

## Voraussetzungen
- Flutter SDK (stable) – https://docs.flutter.dev/get-started/install
- **Android-Build:** Android Studio / Android SDK (auf jedem OS).
- Developer-Account: Google Play Console (25 € einmalig).

## Schnellstart (lokal ausprobieren)
```bash
cd flutter_app
flutter pub get
flutter run            # auf angeschlossenem Gerät/Emulator
```
Der Ordner `android/` ist bereits erzeugt. Falls du ihn neu generieren willst:
`flutter create --platforms=android --org com.kvmtrainer --project-name kvm_trainer .`

## Automatischer Cloud-Build (ohne lokales SDK)
Ein Push auf `claude/meitner-app-build-6lnk2z`, `claude/flutter-native-app` oder `main`
(bzw. manuelles Auslösen des Workflows „App bauen (Android APK)") baut die App in
GitHub Actions und stellt die installierbare APK bereit:
- als **Artefakt** am jeweiligen Actions-Lauf (Debug- und Release-APK) und
- als **Direkt-Download** unter *Releases → `android-latest`* (Release-APK, Debug-signiert).

Zum Installieren die `.apk` aufs Android-Gerät laden und öffnen (Installation aus
unbekannten Quellen erlauben). Für die Store-Veröffentlichung dienen die folgenden Schritte.

## Android → Google Play
```bash
flutter build appbundle --release      # erzeugt build/app/outputs/bundle/release/app-release.aab
```
- App-Signatur einrichten (`android/key.properties` + Keystore), siehe
  https://docs.flutter.dev/deployment/android
- Das `.aab` in der Google Play Console hochladen.
- Berechtigungen sind gesetzt und im Play-Datenschutzformular zu deklarieren:
  - Mikrofon (`RECORD_AUDIO`) für Diktat und Sprachbedienung.
  - Mitteilungen (`POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`) für die Lern-Erinnerung.

## Test-APK lokal bauen (zum Weitergeben)
```bash
flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk
```
- Signiert mit dem festen Debug-Keystore `android/app/kvm-debug.keystore`. Dessen SHA-1 ist
  bei Google hinterlegt, deshalb klappt die Google-Anmeldung auch mit der weitergegebenen APK.
- Die `version:` in `pubspec.yaml` hochzählen und `lib/version.dart` (`kAppVersion`) mitziehen.
  Die Build-Nummer muss steigen, sonst lässt sich die APK nicht über eine ältere installieren.

## App-Icon
Das Industriemeister-Logo (Buch + Zahnrad) ist als adaptives Icon in
`android/app/src/main/res/mipmap-*` hinterlegt.

## Struktur
```
lib/
  main.dart                   Start, Darstellung (hell/dunkel), Init der Pakete
  config.dart                 Supabase, Google-Login, Web-Adresse, Werbung
  constants.dart, theme/      Farbtokens (Palette hell/dunkel), Fächer, Leitner/SR
  screens/
    home_screen.dart          Startansicht: fünf Seiten, Leiste, Zurück-Taste
    pages/                    Start, Lernen, Prüfungen, Vergleich, Konto
    quiz_screen.dart          Frage-Ablauf mit Werkzeug-Dock
    aufgabenblatt_screen.dart Original-Prüfung als Aufgabenblatt
    muendlich_screen.dart     Mündlich üben
  pruefung/                   Rechenweg, Skizze, Ergebnisse, Bestehenschance, Prüfungstexte
  werkzeuge/                  Rechner-Modell, Fehler melden, Gefahrgut-Daten
  lernen/                     Lernplan, Lern-Erinnerung
  cloud/                      Rangliste, Lerngruppen, Freunde, Profile (Supabase)
  services/                   Daten, Lernstand, Lerntage, Rechenkern, Sync, Sprache
  widgets/                    Seitenstapel, Startkarten, Rechner, Formelbuch, Radar …
assets/data/                  questions.json, cases.json, anlagen.json, formulas.json
assets/fonts/                 Inter, Barlow Condensed, IBM Plex Mono (OFL)
```

## Inhalte / Fragenkatalog
Die Fragen und Fälle sind **nicht** hier gepflegt, sondern werden aus der Web-App
(`index.html`, Content-Branch) übernommen. Ablauf, Datenvertrag und Sync-Befehle:
siehe **[../CONTENT_SYNC.md](../CONTENT_SYNC.md)**. Kurz:
```bash
python tools/sync_content.py --check   # aktuell?  (aus dem Repo-Root)
python tools/sync_content.py           # Katalog aus dem Content-Branch übernehmen
```

## Hinweise
- Geprüft mit `flutter analyze` (ohne Befund) und `flutter test`.
- `flutter test --update-goldens tool/screenshots/` rendert alle Bildschirme hell und dunkel mit
  den echten Schriften nach `tool/screenshots/goldens/`; der Ordner ist nicht eingecheckt.
- Der Cloud-Build (GitHub Actions) erzeugt die installierbare APK. Die Store-Signierung erfolgt
  auf deiner Maschine.
- Der Lernfortschritt liegt lokal (SharedPreferences) und wird nach der Google-Anmeldung über
  Supabase mit der Web-App abgeglichen.
