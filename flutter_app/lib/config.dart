/// Laufzeit-/Build-Konfiguration. Werte werden per --dart-define injiziert
/// (siehe SUPABASE_SETUP.md). Fehlen sie, läuft die App als Offline-App ohne
/// Login/Cloud-Sync – der Build bleibt in jedem Fall grün.
class Config {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// OAuth-Web-Client-ID (Google Cloud) für den nativen Google-Login.
  static const String googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  /// Login/Sync nur, wenn Supabase-Zugang konfiguriert ist.
  static bool get authEnabled =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
