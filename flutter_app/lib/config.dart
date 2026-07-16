/// Laufzeit-/Build-Konfiguration.
///
/// Supabase-URL und der öffentliche `anon`-Key sind als Default hinterlegt
/// (der anon-Key ist bewusst öffentlich – die Daten schützt die RLS-Policy,
/// nicht das Geheimhalten dieses Keys; er landet ohnehin in jeder APK).
/// Per --dart-define lassen sich alle Werte überschreiben (z. B. aus
/// GitHub-Secrets). Der Login-Knopf erscheint erst, wenn zusätzlich die
/// Google-Web-Client-ID gesetzt ist – siehe SUPABASE_SETUP.md.
class Config {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iarekdxkutwfidzgvyuy.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlhcmVrZHhrdXR3Zmlkemd2eXV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQxNjIxMTgsImV4cCI6MjA5OTczODExOH0.GsQtsioi0epiXiqYAoeFZ_C5r4C0XuHJlCuiK4UsjzQ',
  );

  /// OAuth-Web-Client-ID (Google Cloud) für den nativen Google-Login.
  /// Öffentlich (Client-IDs sind nicht geheim); das Client-Secret gehört NICHT
  /// hierher, sondern ausschließlich in die Supabase-Provider-Konfiguration.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '342520200103-78s40rb7f7o5olhd1lsrdf2clrvh5dsu.apps.googleusercontent.com',
  );

  /// Login/Sync erst, wenn Supabase UND der Google-Client konfiguriert sind –
  /// so erscheint der Knopf nicht, solange Google noch nicht eingerichtet ist.
  static bool get authEnabled =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      googleWebClientId.isNotEmpty;
}
