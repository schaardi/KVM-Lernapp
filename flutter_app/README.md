# Meister-Trainer (Flutter)

Nativer Port der KVM-Lernapp für **Android** –
eine echte native App für Google Play (keine WebView), auf dem Stand der Web-App
(FR-001 bis FR-015 in `APP_FEATURE_REQUESTS.md`).

- **Fünf Seiten:** Start ohne Scrollen, mit Statistik zum Aufziehen, dazu Lernen, Prüfungen,
  Vergleich und Konto. Die Seiten wechseln gleitend.
- **Inhalte offline:** 3.666 Fragen, 15 Fallaufgaben und 121 Original-IHK-Prüfungen, dazu
  Formelbuch, Kostenwesen und Gefahrgut (ADR).
- **Prüfungen:** Aufgabenblatt mit Rechenweg, Skizzen, Prüfungsbedingungen, Ergebnissen und
  Bestehenschance.
- **Werkzeug-Dock:** Taschenrechner, Rechenblatt und Formelbuch; „Fehler melden“.
- **Lernen:** Mündlich üben mit Vorlesen und Diktat, Prüfungstermin mit Lernplan, tägliche
  Lern-Erinnerung.
- **Vergleich (Supabase):** Wochen- und Prüfungsrangliste, Lerngruppen, Freunde und Profile.
- **Darstellung:** hell, dunkel oder automatisch; die Schriften sind gebündelt (OFL).

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
