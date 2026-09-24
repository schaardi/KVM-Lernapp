import 'package:kvm_trainer/cloud/quelle.dart';

/// Test-Attrappe für die Cloud: spielt die Datenbankfunktionen aus
/// docs/supabase-rangliste.sql, supabase-gruppen.sql und supabase-profile.sql
/// im Speicher nach – gleiche Namen, Parameter, Rückgabeformen und Fehlercodes.
/// Genutzt von den Tests und den Screenshots (ohne Supabase).
class TestPerson {
  final String pid;
  String name;
  int reife;
  int antworten;
  int serie;
  int gemeistert;
  int pruefN;
  int pruefOk;
  int? pruefSchnitt;
  int? chance;
  String sichtbarkeit;
  Map<String, dynamic> details;
  DateTime seit;
  DateTime? detailsAm;

  TestPerson(
    this.name, {
    String? pid,
    this.reife = 0,
    this.antworten = 0,
    this.serie = 0,
    this.gemeistert = 0,
    this.pruefN = 0,
    this.pruefOk = 0,
    this.pruefSchnitt,
    this.chance,
    this.sichtbarkeit = 'freunde',
    this.details = const {},
    DateTime? seit,
    this.detailsAm,
  })  : pid = pid ?? 'pid-${name.toLowerCase()}',
        seit = seit ?? DateTime.utc(2026, 9, 15, 12);
}

class TestGruppe {
  final String id;
  final String code;
  final String name;
  final List<TestPerson> mitglieder;
  TestGruppe(this.id, this.code, this.name, this.mitglieder);
}

class TestServer implements CloudQuelle {
  @override
  bool bereit = true;
  @override
  String? konto = 'konto-ich';

  /// Aufgerufene Funktionen mit Parametern, in Reihenfolge.
  final List<(String, Map<String, dynamic>?)> aufrufe = [];

  /// Funktionen, die es nicht gibt (SQL-Skript fehlt) → PGRST202.
  final Set<String> fehlt = {};

  /// Funktion → Fehlercode bei jedem Aufruf.
  final Map<String, String> fehler = {};

  /// Keine Verbindung.
  bool offline = false;

  bool gesperrt = false;

  final List<TestPerson> andere = [];
  TestPerson? ich;
  final List<TestGruppe> gruppen = [];
  final Set<String> freunde = {};
  final Set<String> anfragenAnMich = {};
  final Set<String> gesendet = {};
  int _codeNr = 0;

  List<String> get namen => [for (final a in aufrufe) a.$1];
  Map<String, dynamic>? letzte(String f) => aufrufe.lastWhere((a) => a.$1 == f, orElse: () => (f, null)).$2;
  int anzahl(String f) => aufrufe.where((a) => a.$1 == f).length;

  List<TestPerson> get _alle => [...andere, if (ich != null) ich!];

  TestPerson? _person(String? pid) {
    for (final p in _alle) {
      if (p.pid == pid) return p;
    }
    return null;
  }

  @override
  Future<dynamic> rpc(String f, [Map<String, dynamic>? p]) async {
    aufrufe.add((f, p));
    await Future<void>.value();
    if (offline) throw const CloudFehler(netz: true);
    if (fehlt.contains(f)) throw const CloudFehler(code: 'PGRST202');
    final c = fehler[f];
    if (c != null) throw CloudFehler(code: c);
    final q = p ?? const <String, dynamic>{};
    return switch (f) {
      'rangliste_info' => _alle.length,
      'rangliste_stand' => _stand(),
      'rangliste_melden' => _melden(q),
      'rangliste_austreten' => _austreten(),
      'pruefungen_melden' => _pruefMelden(q),
      'rangliste_pruefungen' => _pruefungen(),
      'gruppen_meine' => _gruppenMeine(),
      'gruppe_stand' => _gruppeStand(q['p_gruppe'] as String?),
      'gruppe_gruenden' => _gruenden(q['p_name'] as String? ?? ''),
      'gruppe_beitreten' => _beitreten(q['p_code'] as String? ?? ''),
      'gruppe_verlassen' => _verlassen(q['p_gruppe'] as String?),
      'freunde_stand' => _freundeStand(),
      'leute_suche' => _suche(q['p_suche'] as String? ?? '', (q['p_seite'] as int?) ?? 0),
      'profil_ansehen' => _profil(q['p_pid'] as String?, q['p_name'] as String?),
      'freund_anfragen' => _anfragen(q['p_pid'] as String),
      'freund_antworten' => _antworten(q['p_pid'] as String, q['p_annehmen'] == true),
      'freund_entfernen' => _entfernen(q['p_pid'] as String),
      'profil_sichtbarkeit' => _sichtbarkeit(q['p_wert'] as String?),
      'profil_melden' => _profilMelden(q['p_details']),
      _ => throw const CloudFehler(code: 'PGRST202'),
    };
  }

  // ---- Rangliste ----

  int _platz(List<TestPerson> l, TestPerson x) => 1 + l.where((y) => y.antworten > x.antworten).length;

  List<TestPerson> _nachAntworten(Iterable<TestPerson> l) => [...l]..sort((a, b) {
      final d = b.antworten.compareTo(a.antworten);
      return d != 0 ? d : a.name.compareTo(b.name);
    });

  Map<String, dynamic> _stand() {
    final alle = _alle;
    final woche = _nachAntworten(alle.where((x) => x.antworten > 0));
    final i = ich;
    return {
      'dabei': i != null,
      'name': i?.name,
      'teilnehmende': alle.length,
      'reife_vor': i == null ? 0 : alle.where((x) => x.reife < i.reife).length,
      'woche_teilnehmende': woche.length,
      'mein_platz': i != null && i.antworten > 0 ? _platz(woche, i) : null,
      'meine_antworten': i != null && i.antworten > 0 ? i.antworten : null,
      'liste': [
        for (final x in woche.take(10))
          {
            'platz': _platz(woche, x),
            'name': x.name,
            'antworten': x.antworten,
            'reife': x.reife,
            'serie': x.serie,
            'ich': identical(x, i),
          },
      ],
    };
  }

  Object? _melden(Map<String, dynamic> p) {
    final name = (p['p_name'] as String? ?? '').trim();
    if (!RegExp(r'^[A-Za-zÄÖÜäöüß0-9 _.-]{3,20}$').hasMatch(name)) throw const CloudFehler(code: '23514');
    if (andere.any((x) => x.name.toLowerCase() == name.toLowerCase())) throw const CloudFehler(code: '23505');
    if (gesperrt) throw const CloudFehler(code: 'P0006');
    final i = ich ??= TestPerson(name, pid: 'pid-ich');
    i.name = name;
    i.reife = p['p_reife'] as int? ?? 0;
    i.gemeistert = p['p_gemeistert'] as int? ?? 0;
    i.serie = p['p_serie'] as int? ?? 0;
    final a = p['p_antworten'] as int? ?? 0;
    if (a > i.antworten) i.antworten = a;
    return null;
  }

  Object? _austreten() {
    final i = ich;
    if (i == null) return null;
    for (final g in [...gruppen]) {
      g.mitglieder.remove(i);
      if (g.mitglieder.isEmpty) gruppen.remove(g);
    }
    freunde.clear();
    anfragenAnMich.clear();
    gesendet.clear();
    ich = null;
    return null;
  }

  Object? _pruefMelden(Map<String, dynamic> p) {
    final i = ich;
    if (i == null) return null;
    i.pruefN = p['p_n'] as int? ?? 0;
    i.pruefOk = p['p_ok'] as int? ?? 0;
    i.pruefSchnitt = p['p_schnitt'] as int?;
    i.chance = p['p_chance'] as int?;
    return null;
  }

  Map<String, dynamic> _pruefungen() {
    final l = _alle.where((x) => x.pruefN > 0).toList()
      ..sort((a, b) {
        final d = b.pruefOk.compareTo(a.pruefOk);
        if (d != 0) return d;
        final e = (b.pruefSchnitt ?? -1).compareTo(a.pruefSchnitt ?? -1);
        return e != 0 ? e : a.name.compareTo(b.name);
      });
    int platz(TestPerson x) =>
        1 +
        l
            .where((y) =>
                y.pruefOk > x.pruefOk || (y.pruefOk == x.pruefOk && (y.pruefSchnitt ?? -1) > (x.pruefSchnitt ?? -1)))
            .length;
    Map<String, dynamic> zeile(TestPerson x) => {
          'platz': platz(x),
          'name': x.name,
          'n': x.pruefN,
          'ok': x.pruefOk,
          'schnitt': x.pruefSchnitt,
          'chance': x.chance,
          'ich': identical(x, ich),
        };
    final i = ich;
    return {
      'teilnehmende': l.length,
      'ich': i != null && l.contains(i)
          ? {'platz': platz(i), 'n': i.pruefN, 'ok': i.pruefOk, 'schnitt': i.pruefSchnitt, 'chance': i.chance}
          : null,
      'liste': [for (final x in l.take(10)) zeile(x)],
    };
  }

  // ---- Gruppen ----

  void _inRangliste() {
    if (ich == null) throw const CloudFehler(code: 'P0003');
  }

  List<Map<String, dynamic>> _gruppenMeine() => [
        for (final g in gruppen)
          if (g.mitglieder.contains(ich))
            {
              'id': g.id,
              'code': g.code,
              'name': g.name,
              'mitglieder': g.mitglieder.length,
              'leitung': identical(g.mitglieder.first, ich),
            },
      ];

  Map<String, dynamic>? _gruppeStand(String? id) {
    final g = gruppen.where((x) => x.id == id).firstOrNull;
    if (g == null || !g.mitglieder.contains(ich)) return null;
    final l = _nachAntworten(g.mitglieder);
    return {
      'id': g.id,
      'name': g.name,
      'code': g.code,
      'leitung': identical(g.mitglieder.first, ich),
      'mitglieder': g.mitglieder.length,
      'liste': [
        for (final x in l)
          {
            'platz': _platz(l, x),
            'name': x.name,
            'antworten': x.antworten,
            'reife': x.reife,
            'serie': x.serie,
            'pruef_n': x.pruefN,
            'pruef_ok': x.pruefOk,
            'pruef_schnitt': x.pruefSchnitt,
            'chance': x.chance,
            'ich': identical(x, ich),
          },
      ],
    };
  }

  int get _meineGruppen => gruppen.where((g) => g.mitglieder.contains(ich)).length;

  Map<String, dynamic> _gruenden(String roh) {
    _inRangliste();
    final name = roh.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.length < 3 || name.length > 40) throw const CloudFehler(code: '23514');
    if (_meineGruppen >= 5) throw const CloudFehler(code: 'P0004');
    final code = ['K7M2QX', 'HB4TNE', 'P9WZ3A', 'Q2RS8D', 'LT6MUV'][_codeNr++ % 5];
    final g = TestGruppe('gruppe-$_codeNr', code, name, [ich!]);
    gruppen.add(g);
    return {'id': g.id, 'code': g.code, 'name': g.name};
  }

  Map<String, dynamic> _beitreten(String roh) {
    _inRangliste();
    final code = roh.toUpperCase().replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final g = gruppen.where((x) => x.code == code).firstOrNull;
    if (g == null) throw const CloudFehler(code: 'P0002');
    if (!g.mitglieder.contains(ich)) {
      if (_meineGruppen >= 5) throw const CloudFehler(code: 'P0004');
      if (g.mitglieder.length >= 200) throw const CloudFehler(code: 'P0005');
      g.mitglieder.add(ich!);
    }
    return {'id': g.id, 'code': g.code, 'name': g.name};
  }

  Object? _verlassen(String? id) {
    final g = gruppen.where((x) => x.id == id).firstOrNull;
    if (g == null) return null;
    g.mitglieder.remove(ich);
    if (g.mitglieder.isEmpty) gruppen.remove(g);
    return null;
  }

  // ---- Profile und Freunde ----

  String? _bez(TestPerson x) {
    if (identical(x, ich)) return 'ich';
    if (freunde.contains(x.pid)) return 'freund';
    if (gesendet.contains(x.pid)) return 'angefragt';
    if (anfragenAnMich.contains(x.pid)) return 'anfrage';
    return null;
  }

  Map<String, dynamic> _karte(TestPerson x) => {
        'pid': x.pid,
        'name': x.name,
        'reife': x.reife,
        'serie': x.serie,
        'antworten': x.antworten,
        'pruef_n': x.pruefN,
        'pruef_ok': x.pruefOk,
        'pruef_schnitt': x.pruefSchnitt,
        'chance': x.chance,
        'bez': _bez(x),
      };

  Map<String, dynamic>? _freundeStand() {
    final i = ich;
    if (i == null) return null;
    return {
      'ich': {'pid': i.pid, 'name': i.name, 'sichtbarkeit': i.sichtbarkeit},
      'anfragen': [for (final x in andere) if (anfragenAnMich.contains(x.pid)) _karte(x)],
      'gesendet': [for (final x in andere) if (gesendet.contains(x.pid)) _karte(x)],
      'freunde': [for (final x in _nachAntworten(andere)) if (freunde.contains(x.pid)) _karte(x)],
    };
  }

  Map<String, dynamic> _suche(String suche, int seite) {
    _inRangliste();
    final l = _nachAntworten(andere.where((x) => x.name.toLowerCase().contains(suche.trim().toLowerCase())));
    return {
      'gesamt': l.length,
      'seite': seite,
      'liste': [for (final x in l.skip(seite * 30).take(30)) _karte(x)],
    };
  }

  Map<String, dynamic> _profil(String? pid, String? name) {
    _inRangliste();
    TestPerson? x = pid != null ? _person(pid) : null;
    if (x == null && pid == null) {
      for (final p in _alle) {
        if (p.name.toLowerCase() == (name ?? '').trim().toLowerCase()) x = p;
      }
    }
    if (x == null) throw const CloudFehler(code: 'P0002');
    final bez = _bez(x);
    final sichtbar = bez == 'ich' || bez == 'freund' || x.sichtbarkeit == 'alle';
    return {
      'pid': x.pid,
      'name': x.name,
      'reife': x.reife,
      'serie': x.serie,
      'antworten': x.antworten,
      'pruef_n': x.pruefN,
      'pruef_ok': x.pruefOk,
      'pruef_schnitt': x.pruefSchnitt,
      'chance': x.chance,
      'bez': bez,
      'sichtbarkeit': x.sichtbarkeit,
      'sichtbar': sichtbar,
      'admin_sicht': false,
      'seit': sichtbar ? x.seit.toIso8601String() : null,
      'gemeistert': sichtbar ? x.gemeistert : null,
      'details': sichtbar ? x.details : null,
      'details_am': sichtbar ? x.detailsAm?.toIso8601String() : null,
    };
  }

  String _anfragen(String pid) {
    _inRangliste();
    final x = _person(pid);
    if (x == null) throw const CloudFehler(code: 'P0002');
    if (identical(x, ich)) throw const CloudFehler(code: '22023');
    if (freunde.contains(pid)) return 'freund';
    if (anfragenAnMich.remove(pid)) {
      freunde.add(pid);
      return 'freund';
    }
    gesendet.add(pid);
    return 'angefragt';
  }

  String? _antworten(String pid, bool annehmen) {
    _inRangliste();
    if (!anfragenAnMich.remove(pid)) {
      if (annehmen) throw const CloudFehler(code: 'P0002');
      return null;
    }
    if (!annehmen) return null;
    freunde.add(pid);
    return 'freund';
  }

  Object? _entfernen(String pid) {
    _inRangliste();
    freunde.remove(pid);
    gesendet.remove(pid);
    anfragenAnMich.remove(pid);
    return null;
  }

  Object? _sichtbarkeit(String? wert) {
    _inRangliste();
    if (wert != 'freunde' && wert != 'alle') throw const CloudFehler(code: '22023');
    ich!.sichtbarkeit = wert!;
    return null;
  }

  Object? _profilMelden(Object? details) {
    _inRangliste();
    if (details is Map) {
      ich!.details = Map<String, dynamic>.from(details);
      ich!.detailsAm = DateTime.now().toUtc();
    }
    return null;
  }
}
