# KVM-Trainer (Flutter)

Nativer Port der KVM-Lernapp für **iOS** und **Android** aus einer Codebasis –
echte native Apps für App Store und Google Play (keine WebView).

2200 Fragen, 10 Fallaufgaben und das Formelbuch sind offline gebündelt.
Sprachbedienung (Vorlesen + Antwort per A/B/C/D) funktioniert nativ auch auf iOS.

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
