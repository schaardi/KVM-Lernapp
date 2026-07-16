# KVM-Trainer (Flutter)

Nativer Port der KVM-Lernapp für **Android** –
eine echte native App für Google Play (keine WebView).

2200 Fragen, 10 Fallaufgaben und das Formelbuch sind offline gebündelt.
Sprachbedienung (Vorlesen + Antwort per A/B/C/D) funktioniert nativ.

➡️ Bau- und Veröffentlichungsanleitung: **[BUILD.md](BUILD.md)**

```bash
cd flutter_app
flutter pub get
flutter run
```

## Fertige APK ohne eigenes SDK
Ein Push auf diesen Branch baut die App automatisch in GitHub Actions
(Workflow „App bauen (Android APK)"). Die installierbare APK gibt es danach
- als Artefakt am jeweiligen Actions-Lauf und
- als Direkt-Download unter **Releases → `android-latest`**.
