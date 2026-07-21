# Industriemeister Trainer – native Android-App (Flutter) für Google Play

Ein nativer Port der KVM-Lernapp mit **Flutter** – eine echte native **Android**-App
(keine WebView). Die 2200 Fragen, 10 Fallaufgaben und das Formelbuch sind als Assets
gebündelt (offline).

## Was drin ist
- Fächerauswahl, Themenbereiche, Lernfortschritt (Leitner-Boxen + Spaced Repetition, persistent)
- Modi: Heute fällig, Training, Alle Themen, Schwächen, Prüfungssimulation (IHK-Notenschlüssel), Fallaufgaben
- Fragetypen: Auswahlfragen (mit „Warum-falsch"-Begründung je Distraktor), Rechenaufgaben, offene Fragen
- Prüfungsreife-Radar (CustomPainter)
- Werkzeuge: Taschenrechner, Rechenblatt (Zeichnen), durchsuchbares Formelbuch
- **Sprachbedienung nativ** – Frage vorlesen (TTS) + Antwort per A/B/C/D-Spracherkennung
  (nativ, anders als im Web).

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
- Mikrofon-Berechtigung ist bereits gesetzt (`RECORD_AUDIO`) – im Play-Datenschutzformular deklarieren.

## App-Icon
Aktuell ist das Standard-Flutter-Icon gesetzt. Für ein eigenes Icon empfiehlt sich das Paket
`flutter_launcher_icons` (ein Quell-PNG, ein Befehl generiert alle Größen für Android).

## Struktur
```
lib/
  constants.dart              Fächer, Farben, Leitner/SR-Parameter, IHK-Notenschlüssel
  models.dart                 Question / Opt / CaseStudy / Progress / Formula
  services/
    data_service.dart         lädt die gebündelten JSON-Assets
    progress_service.dart     Fortschritt (SharedPreferences) + Leitner + Spaced Repetition
    round_builder.dart        baut die Fragen-Pools je Modus
    voice_service.dart        TTS (flutter_tts) + STT (speech_to_text)
  widgets/
    radar_chart.dart          Prüfungsreife-Radar (CustomPainter)
    calculator.dart           Taschenrechner (eigener Parser)
    drawing_pad.dart          Rechenblatt (CustomPaint + Gesten)
    formula_book.dart         durchsuchbares Formelbuch
  screens/
    home_screen.dart          Startseite
    quiz_screen.dart          Frage-Ablauf
    result_screen.dart        Ergebnis + IHK-Note
assets/data/                  questions.json (2200), cases.json (10), formulas.json
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
- Getestet mit `flutter analyze` (0 Fehler/Warnungen). Der Cloud-Build (GitHub Actions)
  erzeugt die installierbare APK; die Store-Signierung erfolgt auf deiner Maschine.
- Der Lernfortschritt liegt lokal (SharedPreferences). Ein geräteübergreifender Transfer
  (wie der QR-/Code-Export der Web-App) ist als nächster Baustein vorgesehen.
