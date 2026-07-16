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
}
