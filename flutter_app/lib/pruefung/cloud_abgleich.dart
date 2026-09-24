import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../services/auth_service.dart';
import 'ergebnisse.dart';

/// Prüfungsergebnisse abgleichen (FR-014 6, `docs/supabase-pruefungen.sql`):
/// Ausgewertete Durchgänge wandern in die Cloud, zurück kommen alle eigenen –
/// so zeigen Übersicht und Bestehenschance auf jedem Gerät dasselbe.
///
/// Gesendet wird beim Anmelden alles, danach (entprellt, 1,5 s) nach jeder
/// Änderung, was seit dem letzten Abgleich bewertet wurde (Feld `g`); der
/// Stand steht in `kvm_pruef_sync_<Konto-ID>`. Fehlt die Funktion (PGRST202),
/// bleibt alles auf dem Gerät. Das Melden an die Rangliste übernimmt das
/// Paket „Cloud“ (es hört auf `pruefStand`).
class PruefCloud {
  PruefCloud._();
  static final PruefCloud instance = PruefCloud._();

  /// null = unbekannt, false = Funktion fehlt (dann kein weiterer Versuch).
  bool? ok;
  bool _laeuft = false;
  bool _nochmal = false;
  Timer? _takt;
  String? _konto;
  StreamSubscription<AuthState>? _abo;

  static bool get _bereit => Config.authEnabled && AuthService.instance.ready && AuthService.instance.isSignedIn;

  /// Beim Start: auf Anmeldungen hören, Änderungen entprellt abgleichen und –
  /// bei bestehender Sitzung – gleich einmal alles abgleichen.
  void anbinden() {
    PruefErgebnisse.instance.onGeaendert = geaendert;
    if (!Config.authEnabled || !AuthService.instance.ready) return;
    try {
      _abo ??= AuthService.instance.onAuthChange.listen((_) => _kontoPruefen(), onError: (_) {});
    } catch (_) {}
    _kontoPruefen();
  }

  void _kontoPruefen() {
    final id = AuthService.instance.userId;
    if (id == _konto) return;
    _konto = id;
    ok = null; // anderes Konto: Einrichtung neu prüfen
    if (id != null) unawaited(abgleichen(alles: true));
  }

  /// Nach jeder Änderung – entprellt.
  void geaendert() {
    if (!_bereit) return;
    _takt?.cancel();
    _takt = Timer(const Duration(milliseconds: 1500), () => unawaited(abgleichen()));
  }

  Future<void> abgleichen({bool alles = false}) async {
    if (!_bereit || ok == false) return;
    if (_laeuft) {
      _nochmal = true;
      return;
    }
    final uid = AuthService.instance.userId;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final standKey = 'kvm_pruef_sync_$uid';
    var stand = 0;
    if (!alles) {
      try {
        stand = int.tryParse(prefs.getString(standKey) ?? '') ?? 0;
      } catch (_) {}
    }
    var neu = PruefErgebnisse.instance.alle.where((e) => e.g > stand).toList();
    if (neu.length > 500) neu = neu.sublist(neu.length - 500);
    _laeuft = true;
    try {
      final antwort = await Supabase.instance.client.rpc('pruefungen_abgleichen', params: {
        'p_neu': [
          for (final e in neu)
            {
              'k': e.k,
              'id': e.id,
              't': e.t,
              'g': e.g,
              'pkt': e.pkt,
              'max': e.max,
              'bew': e.bew,
              'teile': e.teile,
              'echt': e.echt ? 1 : 0,
              'dauer': (e.dauer ?? 0) > 0 ? e.dauer : null,
              'min': (e.min ?? 0) > 0 ? e.min : null,
            }
        ],
      });
      ok = true;
      if (antwort is List) PruefErgebnisse.instance.zusammenfuehren(antwort);
      var mx = 0;
      for (final e in PruefErgebnisse.instance.alle) {
        if (e.g > mx) mx = e.g;
      }
      await prefs.setString(standKey, '$mx');
    } on PostgrestException catch (e) {
      // Funktion fehlt: still weiter ohne Cloud.
      if (e.code == 'PGRST202' || e.code == '42883') ok = false;
    } catch (_) {
      // Netz- oder Rechtefehler: lokal bleibt alles erhalten.
    } finally {
      _laeuft = false;
    }
    if (_nochmal) {
      _nochmal = false;
      await abgleichen();
    }
  }
}
