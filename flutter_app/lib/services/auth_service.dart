import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

/// Anmeldung über Google (nativer idToken-Flow) gegen Supabase.
/// Weitere Anbieter (z. B. Apple) lassen sich analog ergänzen.
class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  /// Wird in main() nach erfolgreicher Supabase-Initialisierung gesetzt.
  bool ready = false;

  GoogleSignIn? _google;
  GoogleSignIn get _googleClient => _google ??= GoogleSignIn(
        serverClientId:
            Config.googleWebClientId.isEmpty ? null : Config.googleWebClientId,
      );

  SupabaseClient get _sb => Supabase.instance.client;

  User? get user => ready ? _sb.auth.currentUser : null;
  bool get isSignedIn => user != null;
  String? get userId => user?.id;
  String? get email => user?.email;
  String? get displayName =>
      (user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'])?.toString();

  /// Reagiert auf An-/Abmeldungen (Session-Restore, Login, Logout).
  Stream<AuthState> get onAuthChange => _sb.auth.onAuthStateChange;

  /// Startet den Google-Login. Gibt false zurück, wenn der Nutzer abbricht.
  Future<bool> signInWithGoogle() async {
    if (!ready) throw StateError('Login nicht konfiguriert.');
    final account = await _googleClient.signIn();
    if (account == null) return false; // abgebrochen
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw StateError('Kein idToken von Google erhalten – Web-Client-ID prüfen.');
    }
    await _sb.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: auth.accessToken,
    );
    return true;
  }

  Future<void> signOut() async {
    try {
      await _googleClient.signOut();
    } catch (_) {}
    if (ready) await _sb.auth.signOut();
  }
}
