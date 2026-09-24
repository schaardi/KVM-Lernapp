import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../services/auth_service.dart';

/// Fehler eines Cloud-Aufrufs – der Code kommt von PostgREST bzw. Postgres
/// (z. B. `23505` Name vergeben, `P0002` nicht gefunden, `PGRST202` Funktion
/// fehlt). Ohne Code: keine Verbindung oder Zeitüberschreitung.
class CloudFehler implements Exception {
  final String? code;
  final bool netz;
  const CloudFehler({this.code, this.netz = false});

  /// Die Funktion gibt es auf dem Server nicht (SQL-Skript fehlt) – die
  /// Teilfunktion bleibt dann still verborgen, wie im Web.
  bool get fehlt => code == 'PGRST202' || code == '42883';

  @override
  String toString() => 'CloudFehler(${code ?? (netz ? 'netz' : '?')})';
}

/// Datenquelle der Cloud-Funktionen (Rangliste, Gruppen, Profile). Im Betrieb
/// Supabase, in Tests und Screenshots eine Attrappe.
abstract class CloudQuelle {
  /// Angemeldet und Supabase eingerichtet – nur dann wird aufgerufen.
  bool get bereit;

  /// Konto der angemeldeten Person (nur zum Erkennen eines Kontowechsels).
  String? get konto;

  /// Ruft eine Datenbankfunktion auf. Wirft [CloudFehler].
  Future<dynamic> rpc(String funktion, [Map<String, dynamic>? params]);
}

/// Supabase: `Supabase.instance.client.rpc(...)`, nur mit Anmeldung.
class SupabaseQuelle implements CloudQuelle {
  const SupabaseQuelle();

  static const _frist = Duration(seconds: 20);

  @override
  bool get bereit =>
      Config.authEnabled && AuthService.instance.ready && AuthService.instance.isSignedIn;

  @override
  String? get konto => bereit ? AuthService.instance.userId : null;

  @override
  Future<dynamic> rpc(String funktion, [Map<String, dynamic>? params]) async {
    if (!bereit) throw const CloudFehler(code: 'abgemeldet');
    try {
      return await Supabase.instance.client.rpc(funktion, params: params).timeout(_frist);
    } on PostgrestException catch (e) {
      throw CloudFehler(code: e.code);
    } catch (_) {
      // Keine Verbindung, Zeitüberschreitung, abgelaufene Sitzung …
      throw const CloudFehler(netz: true);
    }
  }
}
