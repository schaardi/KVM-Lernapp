import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../models.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';

/// Schickt eine Meldung ab; wirft bei Fehlern (Netz, Bremse, fehlendes Skript).
typedef MeldungSender = Future<void> Function(Map<String, dynamic> parameter);

/// Fragt, ob Melden eingerichtet ist (`meldungen_bereit()` antwortet `true`).
typedef BereitAbfrage = Future<bool> Function();

/// Arten wie im Web (`data-art`) mit den Beschriftungen der Auswahl-Chips.
const List<(String, String)> kMeldeArten = [
  ('text', 'Text unleserlich oder Tippfehler'),
  ('loesung', 'Lösung falsch'),
  ('rechnung', 'Rechnung oder Zahl falsch'),
  ('anlage', 'Tabelle oder Anlage fehlt'),
  ('sonstiges', 'Sonstiges'),
];

/// Fehler melden (FR-008): Bereitschaft, gemeldete Fragen und Senden über
/// `meldung_senden` (docs/supabase-meldungen.sql).
///
/// Der Knopf erscheint erst, wenn `meldungen_bereit()` beim Start oder nach
/// der Anmeldung `true` liefert. Fehlt das Skript (PGRST202) oder ist
/// niemand angemeldet, bleibt er unsichtbar. Gemeldete Fragen merkt sich das
/// Gerät wie im Web unter `kvm_gemeldet` = `{"<id>": <ms>}`.
class MeldenDienst extends ChangeNotifier {
  MeldenDienst._();
  static final MeldenDienst instance = MeldenDienst._();

  static const String schluessel = 'kvm_gemeldet';

  /// Melden ist eingerichtet und möglich – erst dann gibt es Knöpfe.
  final ValueNotifier<bool> bereit = ValueNotifier<bool>(false);

  /// Sendefunktion – in Tests austauschbar (ohne Netz).
  MeldungSender sender = _supabaseSenden;

  /// Bereitschaftsabfrage – in Tests austauschbar.
  BereitAbfrage abfrage = _supabaseBereit;

  final Map<String, int> _gemeldet = {};
  SharedPreferences? _prefs;
  Future<void>? _pruefung;
  StreamSubscription<AuthState>? _abo;

  static bool get _cloud =>
      Config.authEnabled && AuthService.instance.ready && AuthService.instance.isSignedIn;

  static Future<void> _supabaseSenden(Map<String, dynamic> parameter) async {
    if (!_cloud) throw StateError('Melden braucht eine Anmeldung.');
    await Supabase.instance.client.rpc('meldung_senden', params: parameter);
  }

  static Future<bool> _supabaseBereit() async {
    if (!_cloud) return false;
    final r = await Supabase.instance.client.rpc('meldungen_bereit');
    return r == true;
  }

  // ─────────────────────────── Gemeldet ───────────────────────────

  /// Liest `kvm_gemeldet`.
  Future<void> laden() async {
    _gemeldet.clear();
    try {
      _prefs = await SharedPreferences.getInstance();
      final roh = _prefs!.getString(schluessel);
      if (roh != null && roh.isNotEmpty) {
        final d = jsonDecode(roh);
        if (d is Map) {
          for (final e in d.entries) {
            if (e.value is num) _gemeldet[e.key.toString()] = (e.value as num).toInt();
          }
        }
      }
    } catch (_) {
      // Kaputter Eintrag: nichts gemeldet.
    }
    notifyListeners();
  }

  bool istGemeldet(String frageId) => _gemeldet.containsKey(frageId);

  /// Merkt eine gemeldete Frage; alle Knöpfe dieser Frage zeigen „Gemeldet ✓“.
  Future<void> merken(String frageId) async {
    _gemeldet[frageId] = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(schluessel, jsonEncode(_gemeldet));
    } catch (_) {}
  }

  // ─────────────────────────── Bereitschaft ───────────────────────────

  /// Fragt `meldungen_bereit()` (Web: beim Laden). Jeder Fehler – auch
  /// PGRST202, wenn das Skript fehlt – lässt den Knopf unsichtbar.
  Future<void> bereitPruefen() => _pruefung ??= _pruefen().whenComplete(() => _pruefung = null);

  Future<void> _pruefen() async {
    try {
      bereit.value = await abfrage();
    } catch (_) {
      bereit.value = false;
    }
  }

  /// Prüft nach jeder Anmeldung neu; nach dem Abmelden gibt es keine Knöpfe.
  void anmeldungBeobachten() {
    if (_abo != null || !Config.authEnabled || !AuthService.instance.ready) return;
    try {
      _abo = AuthService.instance.onAuthChange.listen((s) {
        if (s.event == AuthChangeEvent.signedOut) {
          bereit.value = false;
        } else if (s.event == AuthChangeEvent.signedIn || s.event == AuthChangeEvent.initialSession) {
          bereitPruefen();
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  // ─────────────────────────── Senden ───────────────────────────

  static Map<String, Question>? _index;
  static Set<String> _teile = {};
  static int _indexStand = -1;

  static Map<String, Question> get _fragen {
    final d = DataService.instance;
    final stand = d.questions.length * 100003 + d.cases.length;
    if (_index == null || stand != _indexStand) {
      final index = <String, Question>{for (final q in d.questions) q.id: q};
      final teile = <String>{};
      for (final c in d.cases) {
        for (final s in c.steps) {
          index.putIfAbsent(s.id, () => s);
          teile.add(s.id);
        }
      }
      _index = index;
      _teile = teile;
      _indexStand = stand;
    }
    return _index!;
  }

  /// Frage oder Teilaufgabe zur ID (Web `mdFrage`).
  static Question? frage(String id) => _fragen[id];

  /// Gehört die ID zu einer Teilaufgabe (Aufgabenblatt)?
  static bool istTeilaufgabe(String id) {
    _fragen;
    return _teile.contains(id);
  }

  static bool _istTeilaufgabe(String id) => istTeilaufgabe(id);

  /// Die ersten 160 Zeichen, Leerraum zusammengezogen (Web `mdAuszug`).
  static String auszug(String text) {
    final t = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.length > 160 ? t.substring(0, 160) : t;
  }

  /// Auszug der Frage zur ID; ohne Treffer aus [ersatz].
  static String auszugFuer(String id, [String ersatz = '']) {
    final q = frage(id);
    return auszug(q != null && q.q.trim().isNotEmpty ? q.q : ersatz);
  }

  /// Kontext wie im Web: `{"modus": …, "fach": …, "bereich": ≤ 80, "auszug": 160}`.
  /// `modus` ist in der App `quiz` oder `blatt` (Web-Namen `scrQuiz`/`scrBlatt`
  /// werden umgesetzt); fehlt er, folgt er der Herkunft der ID. Angaben aus
  /// [extra] gehen vor. Höchstens rund 2 kB (Grenze der Datenbank).
  static Map<String, dynamic> kontextFuer(String id, {Map<String, dynamic> extra = const {}, String bezug = ''}) {
    final q = frage(id);
    final k = <String, dynamic>{
      'modus': _istTeilaufgabe(id) ? 'blatt' : 'quiz',
      if (q != null && q.f > 0) 'fach': q.f,
      if (q != null && q.sub.isNotEmpty) 'bereich': q.sub,
      'auszug': auszugFuer(id, bezug),
    };
    k.addAll(extra);
    final modus = k['modus'];
    if (modus is String && modus.startsWith('scr') && modus.length > 3) {
      k['modus'] = modus.substring(3).toLowerCase();
    }
    final bereich = k['bereich'];
    if (bereich is String && bereich.length > 80) k['bereich'] = bereich.substring(0, 80);
    final a = k['auszug'];
    if (a is String && a.length > 160) k['auszug'] = a.substring(0, 160);
    if (utf8.encode(jsonEncode(k)).length > 1800) {
      k.removeWhere((key, _) => !const {'modus', 'fach', 'bereich', 'auszug'}.contains(key));
    }
    return k;
  }

  /// Sendet eine Meldung – Parameter exakt wie im Web (`sb.rpc('meldung_senden', …)`),
  /// Quelle `app`.
  Future<void> senden({
    required String frageId,
    required String art,
    required String text,
    required Map<String, dynamic> kontext,
  }) {
    return sender({
      'p_frage': frageId,
      'p_art': art,
      'p_text': text.length > 1000 ? text.substring(0, 1000) : text,
      'p_kontext': kontext,
      'p_quelle': 'app',
    });
  }

  /// Bremse der Datenbank („zu viele Meldungen“)?
  static bool istBremse(Object fehler) {
    final m = fehler is PostgrestException ? fehler.message : fehler.toString();
    return m.contains('zu viele');
  }

  /// Zurück auf Anfang (Tests).
  @visibleForTesting
  void zuruecksetzen() {
    _gemeldet.clear();
    bereit.value = false;
    sender = _supabaseSenden;
    abfrage = _supabaseBereit;
    _pruefung = null;
    notifyListeners();
  }
}
