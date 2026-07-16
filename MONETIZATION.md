# Monetarisierung: Werbung (AdMob) + Werbefrei-Abo

Die App ist **Freemium**:

- **Gratis** nutzbar – nach je **10 beantworteten Fragen** erscheint eine
  Interstitial-Werbung (an einem natürlichen Übergang, nicht mitten in der Frage).
- Das **Abo „Werbefrei"** (Standard `premium_monthly`, **5,99 €/Monat**) schaltet
  die App komplett werbefrei. Google Play verwaltet das Abo pro Konto und
  synchronisiert es geräteübergreifend.

> **Wichtig zur Werbedauer:** Die Länge eines Spots bestimmt AdMob / der
> Werbekunde, **nicht die App**. Steuerbar ist nur die *Häufigkeit* (alle 10
> Fragen). Ein Interstitial ist meist nach einigen Sekunden wegklickbar.

## Sofort testbar – ohne echte Konten

Damit im Repo **keine echten/geheimen IDs** liegen, laufen ab Werk **Googles
offizielle Test-IDs**:

- AdMob-App-ID (Manifest): `ca-app-pub-3940256099942544~3347511713`
- Interstitial-Ad-Unit (Fallback in `config.dart`): `ca-app-pub-3940256099942544/1033173712`

Diese zeigen **Test-Anzeigen** (kein echtes Geld, kein Policy-Verstoß). Das Abo
ist im Test „nicht verfügbar", bis du in der Play Console ein Produkt anlegst –
der Kauf-Button meldet das dann sauber.

Komplett abschalten (reine Testversion ohne Werbung/Abo-UI):
`--dart-define=MONETIZATION_ENABLED=false`.

---

## A) AdMob einrichten (für echte Werbeeinnahmen)

1. AdMob-Konto anlegen: https://apps.admob.com (kostenlos, mit dem Google-Konto).
2. **App hinzufügen** → Plattform **Android** → Paketname
   `com.kvmtrainer.kvm_trainer`. Du bekommst eine **AdMob-App-ID**
   (`ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`).
3. **Anzeigenblock** anlegen → Typ **Interstitial** → du bekommst eine
   **Ad-Unit-ID** (`ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ`).
4. **App-ID im Manifest ersetzen:** in
   `flutter_app/android/app/src/main/AndroidManifest.xml` den Wert von
   `com.google.android.gms.ads.APPLICATION_ID` durch deine echte App-ID tauschen.
5. **Ad-Unit-ID setzen** (nicht ins Repo!): als GitHub-Secret
   `ADMOB_INTERSTITIAL_ID` = deine Interstitial-Ad-Unit-ID. Der Build reicht sie
   per `--dart-define` durch (leeres Secret ⇒ Test-Unit).
6. In AdMob unter **App-ads.txt** / **Zahlungen** die üblichen Schritte
   abschließen, damit echte Anzeigen ausgeliefert werden.

> Erst **nach** Schritt 4 + 5 verdienst du echtes Geld. Vorher laufen Test-Ads.

## B) Werbefrei-Abo in der Play Console anlegen

1. Play Console → deine App → **Monetarisierung → Produkte → Abos**.
2. **Abo erstellen** → Produkt-ID **`premium_monthly`** (muss zum Default bzw. zum
   Secret `PREMIUM_PRODUCT_ID` passen).
3. **Basis-Abo** anlegen: Abrechnungszeitraum **monatlich**, Preis **5,99 €**
   (Google rechnet die weiteren Währungen um). Optional eine Gratis-Testphase.
4. Abo **aktivieren**.
5. Zum Testen **Lizenztester** hinterlegen (Play Console → *Einstellungen →
   Lizenztests*) – die kaufen ohne echte Belastung.

> Weicht deine Produkt-ID von `premium_monthly` ab, setze das Secret
> `PREMIUM_PRODUCT_ID` entsprechend.

## C) GitHub-Secrets (optional, für echte IDs)

| Secret | Inhalt |
|--------|--------|
| `ADMOB_INTERSTITIAL_ID` | echte Interstitial-Ad-Unit-ID |
| `PREMIUM_PRODUCT_ID` | Abo-Produkt-ID (falls nicht `premium_monthly`) |

Leere/fehlende Secrets ⇒ die App fällt automatisch auf Test-Unit bzw.
`premium_monthly` zurück (Build bleibt grün).

---

## Wie es im Code hängt
- `lib/config.dart` – IDs + `monetizationEnabled` (mit Test-Fallbacks).
- `lib/services/premium_service.dart` – Abo-Status (in_app_purchase), Kauf/Restore,
  Cache; reaktiver `ValueNotifier<bool> isPremium`.
- `lib/services/ad_service.dart` – Interstitial laden/zeigen, Zähler alle
  `kAdEveryQuestions` (=10) Fragen; zeigt nie für Premium-Nutzer.
- `lib/screens/quiz_screen.dart` – zählt beantwortete Fragen und zeigt die Ad am
  „Weiter"-Übergang.
- `lib/widgets/premium_sheet.dart` + Home-Banner – Kauf/Status-UI.

## Bekannte Grenze
Der Premium-Status wird lokal gecacht und beim Start über Play wiederhergestellt.
Eine **serverseitige Ablauf-/Kündigungsprüfung** (Google Play Developer API) ist
bewusst nicht enthalten – für eine harte Entitlement-Prüfung (z. B. sofortiger
Entzug nach Kündigung) müsste man diese später ergänzen.
