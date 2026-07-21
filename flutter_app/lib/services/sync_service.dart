import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import 'auth_service.dart';
import 'progress_service.dart';

/// Geräteübergreifender Fortschritt über Supabase (Tabelle `progress`,
/// Spalten: user_id uuid, data jsonb, updated_at timestamptz).
///
/// Beim Anmelden wird der Cloud-Stand geladen, mit dem lokalen zusammengeführt
/// (je Frage gewinnt der weiter fortgeschrittene Datensatz) und zurückgeschrieben.
/// Danach pusht jede Änderung (entprellt) automatisch in die Cloud.
class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  static const _table = 'progress';
  Timer? _debounce;
  bool _busy = false;

  bool get _ready =>
      Config.authEnabled && AuthService.instance.ready && AuthService.instance.isSignedIn;

  SupabaseClient get _sb => Supabase.instance.client;

  /// Verbindet den Fortschritt mit dem Cloud-Push (in main aufrufen).
  void attach() {
    ProgressService.instance.onChanged = schedulePush;
  }

  /// Nach dem Login: Cloud laden, mergen, zurückschreiben.
  Future<void> pullMergePush() async {
    if (!_ready || _busy) return;
    _busy = true;
    try {
      final remote = await _fetch();
      if (remote != null) ProgressService.instance.mergeRemote(remote);
      await _push();
    } catch (_) {
      // Netzwerk-/Rechtefehler ignorieren – lokal bleibt alles erhalten.
    } finally {
      _busy = false;
    }
  }

  void schedulePush() {
    if (!_ready) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      _push().catchError((_) {});
    });
  }

  Future<Map<String, dynamic>?> _fetch() async {
    final uid = AuthService.instance.userId;
    if (uid == null) return null;
    final row = await _sb.from(_table).select('data').eq('user_id', uid).maybeSingle();
    final data = row?['data'];
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  Future<void> _push() async {
    if (!_ready) return;
    final uid = AuthService.instance.userId;
    if (uid == null) return;
    await _sb.from(_table).upsert({
      'user_id': uid,
      'data': ProgressService.instance.exportJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
