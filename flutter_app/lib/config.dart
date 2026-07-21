/// Laufzeit-/Build-Konfiguration.
///
/// Supabase-URL, der öffentliche `anon`-Key und die Google-Web-Client-ID sind
/// als Default hinterlegt (alle drei sind bewusst öffentlich – die Daten schützt
/// die RLS-Policy; das Google-Client-**Secret** gehört ausschließlich in die
/// Supabase-Provider-Konfiguration, niemals hierher).
///
/// Per --dart-define lassen sich die Werte überschreiben – ein LEERER
/// --dart-define fällt jedoch auf den Default zurück (sonst würden leere
/// GitHub-Secrets in CI die Defaults „ausknipsen").
class Config {
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static String get supabaseUrl => _supabaseUrl.isNotEmpty
      ? _supabaseUrl
      : 'https://iarekdxkutwfidzgvyuy.supabase.co';

  static String get supabaseAnonKey => _supabaseAnonKey.isNotEmpty
      ? _supabaseAnonKey
      : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlhcmVrZHhrdXR3Zmlkemd2eXV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQxNjIxMTgsImV4cCI6MjA5OTczODExOH0.GsQtsioi0epiXiqYAoeFZ_C5r4C0XuHJlCuiK4UsjzQ';

  static String get googleWebClientId => _googleWebClientId.isNotEmpty
      ? _googleWebClientId
      : '342520200103-78s40rb7f7o5olhd1lsrdf2clrvh5dsu.apps.googleusercontent.com';

  /// Login/Sync sind aktiv, sobald alle drei Werte vorliegen (per Default true).
  static bool get authEnabled =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      googleWebClientId.isNotEmpty;

  // ---- Monetarisierung (Freemium: Werbung + Werbefrei-Abo) ----

  static const String _admobInterstitialId =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ID');
  static const String _premiumProductId =
      String.fromEnvironment('PREMIUM_PRODUCT_ID');
  static const String _monetizationEnabled =
      String.fromEnvironment('MONETIZATION_ENABLED');

  /// Interstitial-Ad-Unit. Fällt auf Googles offizielle TEST-Unit zurück
  /// (zeigt Test-Anzeigen, kein echtes Geld) – vor der Veröffentlichung per
  /// --dart-define/Secret durch die echte Ad-Unit ersetzen.
  static String get admobInterstitialId => _admobInterstitialId.isNotEmpty
      ? _admobInterstitialId
      : 'ca-app-pub-3940256099942544/1033173712';

  /// Produkt-ID des Werbefrei-Abos in der Google Play Console.
  static String get premiumProductId =>
      _premiumProductId.isNotEmpty ? _premiumProductId : 'premium_monthly';

  /// Freemium an/aus. Per Default aktiv; mit
  /// `--dart-define=MONETIZATION_ENABLED=false` komplett abschaltbar
  /// (keine Werbung, kein Abo-UI – z. B. für eine reine Testversion).
  static bool get monetizationEnabled =>
      _monetizationEnabled.toLowerCase() != 'false';
}
