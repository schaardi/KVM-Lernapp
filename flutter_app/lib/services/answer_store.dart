import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../pruefung/skizze_daten.dart';
import 'data_service.dart';
import 'rechenkern.dart';

/// Speichert die selbst formulierten Antworten zu offenen Aufgaben, damit sie
/// beim Blättern und nach einem Neustart erhalten bleiben – dazu Rechenwege,
/// Skizzen, Eintragungen in Anlagen und die selbst vergebenen Punkte. Die
/// Schlüssel sind dieselben wie im Web (`kvm_open_*`).
class AnswerStore {
  AnswerStore._();
  static final AnswerStore instance = AnswerStore._();

  static const _key = 'kvm_open_answers';
  static const _pkey = 'kvm_open_points';
  static const _tkey = 'kvm_open_tabs';
  static const _ckey = 'kvm_open_calc';
  static const _skey = 'kvm_open_sketch';
  SharedPreferences? _prefs;
  Map<String, String> _answers = {};
  Map<String, int> _points = {};
  Map<String, Map<String, String>> _tabs = {};
  Map<String, List<Map<String, String>>> _calc = {};
  Map<String, Map<String, dynamic>> _skizzen = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _answers = {};
    _points = {};
    _tabs = {};
    _calc = {};
    _skizzen = {};
    final raw = _prefs?.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        _answers = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {
        _answers = {};
      }
    }
    final traw = _prefs?.getString(_tkey);
    if (traw != null && traw.isNotEmpty) {
      try {
        final decoded = json.decode(traw) as Map<String, dynamic>;
        _tabs = decoded.map((k, v) => MapEntry(
            k,
            (v as Map<String, dynamic>)
                .map((a, b) => MapEntry(a, b.toString()))));
      } catch (_) {
        _tabs = {};
      }
    }
    final praw = _prefs?.getString(_pkey);
    if (praw != null && praw.isNotEmpty) {
      try {
        final decoded = json.decode(praw) as Map<String, dynamic>;
        _points = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {
        _points = {};
      }
    }
    final craw = _prefs?.getString(_ckey);
    if (craw != null && craw.isNotEmpty) {
      try {
        final decoded = json.decode(craw) as Map<String, dynamic>;
        decoded.forEach((k, v) {
          if (v is! List) return;
          _calc[k] = [
            for (final r in v.whereType<Map>())
              {
                'l': (r['l'] ?? '').toString(),
                'f': (r['f'] ?? '').toString(),
                'u': (r['u'] ?? '').toString(),
              }
          ];
        });
      } catch (_) {
        _calc = {};
      }
    }
    final sraw = _prefs?.getString(_skey);
    if (sraw != null && sraw.isNotEmpty) {
      try {
        final decoded = json.decode(sraw) as Map<String, dynamic>;
        decoded.forEach((k, v) {
          if (v is Map && v['els'] is List) _skizzen[k] = Map<String, dynamic>.from(v);
        });
      } catch (_) {
        _skizzen = {};
      }
    }
  }

  String get(String id) => _answers[id] ?? '';

  void set(String id, String text) {
    if (text.trim().isEmpty) {
      _answers.remove(id);
    } else {
      _answers[id] = text;
    }
    _prefs?.setString(_key, json.encode(_answers));
  }

  /// Eintragungen in einer Tabellenanlage: je Anlage ein Objekt
  /// "Zeile-Spalte" -> Eingabe. Ein Betriebsabrechnungsbogen wird in der
  /// Prüfung in die Anlage geschrieben, nicht in den Antwortkasten.
  Map<String, String> tabWerte(String key) => _tabs[key] ?? const {};

  bool tabGefuellt(String key) => (_tabs[key] ?? const {}).isNotEmpty;

  void setTab(String key, String rc, String wert) {
    final t = Map<String, String>.from(_tabs[key] ?? const {});
    if (wert.trim().isEmpty) {
      t.remove(rc);
    } else {
      t[rc] = wert;
    }
    if (t.isEmpty) {
      _tabs.remove(key);
    } else {
      _tabs[key] = t;
    }
    _prefs?.setString(_tkey, json.encode(_tabs));
  }

  /// Selbst vergebene Punkte einer offenen Prüfungsaufgabe (null = noch nicht
  /// bewertet), damit am Ende ein echtes Punkte-Ergebnis herauskommt.
  int? points(String id) => _points[id];

  void setPoints(String id, int? p) {
    if (p == null) {
      _points.remove(id);
    } else {
      _points[id] = p;
    }
    _prefs?.setString(_pkey, json.encode(_points));
  }

  // ─────────────────── Rechenweg (FR-003 B, `kvm_open_calc`) ───────────────────

  /// Die Zeilen des Rechenwegs: `{l: Bezeichnung, f: Rechnung, u: Einheit}`.
  List<Map<String, String>> calc(String id) => [for (final r in _calc[id] ?? const []) Map.of(r)];

  /// Zeilen ohne Bezeichnung und ohne Rechnung werden nicht gespeichert.
  void setCalc(String id, List<Map<String, String>> rows) {
    final keep = [
      for (final r in rows)
        if ((r['l'] ?? '').trim().isNotEmpty || (r['f'] ?? '').trim().isNotEmpty)
          {'l': r['l'] ?? '', 'f': r['f'] ?? '', 'u': r['u'] ?? ''}
    ];
    if (keep.isEmpty) {
      _calc.remove(id);
    } else {
      _calc[id] = keep;
    }
    _prefs?.setString(_ckey, json.encode(_calc));
  }

  /// Wahr, sobald eine Zeile eine Rechnung hat.
  bool hatCalc(String id) => (_calc[id] ?? const []).any((r) => (r['f'] ?? '').trim().isNotEmpty);

  /// Der Rechenweg als Text, Zeile für Zeile („Kosten: 4.400 ÷ 22 = 200 €“).
  String calcText(String id) => (_calc[id] ?? const [])
      .map((r) => zeileText(l: r['l'] ?? '', f: r['f'] ?? '', u: r['u'] ?? ''))
      .where((z) => z.isNotEmpty)
      .join('\n');

  // ─────────────────── Skizze (FR-013, `kvm_open_sketch`) ───────────────────

  /// `{v: 1, bg: 'karo'|'anlage', fmt: 'quer'|'hoch', els: [...]}` oder null.
  Map<String, dynamic>? skizze(String id) {
    final d = _skizzen[id];
    if (d == null) return null;
    return {
      ...d,
      'els': [for (final e in (d['els'] as List).whereType<Map>()) Map<String, dynamic>.from(e)],
    };
  }

  /// Leere Skizzen werden nicht gespeichert.
  void setSkizze(String id, {required String bg, required String fmt, required List<Map<String, dynamic>> els}) {
    if (els.isEmpty) {
      _skizzen.remove(id);
    } else {
      _skizzen[id] = {'v': 1, 'bg': bg, 'fmt': fmt, 'els': els};
    }
    _prefs?.setString(_skey, json.encode(_skizzen));
  }

  bool hatSkizze(String id) => ((_skizzen[id]?['els'] as List?) ?? const []).isNotEmpty;

  // ─────────────────── Gesamtstand einer Teilaufgabe ───────────────────

  /// Beantwortet heißt in der Prüfungsliste: Text oder Rechenweg (Web
  /// `KVM_hasAnswer`).
  bool hatAntwort(String id) => get(id).trim().isNotEmpty || hatCalc(id);

  /// Die ganze eigene Antwort einer Teilaufgabe: Skizze, Rechenweg und Text
  /// (Web `antwortText`) – für „Deine Antwort“, den KI-Export und die Abgabe.
  String antwortText(String id) =>
      [skText(_skizzen[id]), calcText(id), get(id).trim()].where((x) => x.isNotEmpty).join('\n\n');

  /// Gibt es zu dieser Teilaufgabe Antworten, Rechenwege, Skizzen, Tabellen
  /// oder Punkte? Tabelleneinträge sind alle Schlüssel, die mit `<id>#`
  /// beginnen.
  bool hatStand(String id) =>
      get(id).trim().isNotEmpty ||
      hatCalc(id) ||
      hatSkizze(id) ||
      _points.containsKey(id) ||
      _tabs.keys.any((k) => k.startsWith('$id#'));

  /// Leert Antworten, Punkte, Rechenwege, Skizzen und Tabellen der
  /// Teilaufgaben – eine Prüfung beginnt so mit leeren Blättern.
  void leeren(Iterable<String> ids) {
    final alle = ids.toSet();
    for (final i in alle) {
      _answers.remove(i);
      _points.remove(i);
      _calc.remove(i);
      _skizzen.remove(i);
    }
    _tabs.removeWhere((k, _) => alle.any((i) => k.startsWith('$i#')));
    _prefs?.setString(_key, json.encode(_answers));
    _prefs?.setString(_pkey, json.encode(_points));
    _prefs?.setString(_tkey, json.encode(_tabs));
    _prefs?.setString(_ckey, json.encode(_calc));
    _prefs?.setString(_skey, json.encode(_skizzen));
  }

  /// Welche Prüfungen haben Antworten, Rechenwege, Skizzen, Tabellen oder
  /// Punkte? Ein Durchlauf über die Speicher statt je Teilaufgabe –
  /// Teilaufgaben heißen „<Prüfung>-s<n>“ (Web `KVM_pruefMitStand`).
  Set<String> pruefungenMitStand() {
    final ids = <String>{};
    final re = RegExp(r'^(P-[A-Z]+-\d+)-s\d+');
    void nimm(String k) {
      final m = re.firstMatch(k);
      if (m != null) ids.add(m.group(1)!);
    }

    _answers.forEach((k, v) {
      if (v.trim().isNotEmpty) nimm(k);
    });
    _calc.forEach((k, v) {
      if (v.any((r) => (r['f'] ?? '').trim().isNotEmpty)) nimm(k);
    });
    _skizzen.forEach((k, v) {
      if (((v['els'] as List?) ?? const []).isNotEmpty) nimm(k);
    });
    _points.keys.forEach(nimm);
    _tabs.keys.forEach(nimm);
    return ids;
  }

  /// Eine einzelne Teilaufgabe samt eigener Antwort als Prüfauftrag – wortgleich
  /// zur Web-Fassung, damit beide Wege dasselbe Ergebnis liefern.
  static String exportTask(Question q) {
    final eigene = AnswerStore.instance.antwortText(q.id);
    final teile = TaskParts.of(q).volltext.split('\n\n');
    final kopf = teile.isNotEmpty ? teile.first : '';
    final rest = teile.skip(1).join('\n\n');
    final punkte = RegExp(r'·\s*(\d+)\s*Punkt').firstMatch(kopf)?.group(1);

    final b = StringBuffer()
      ..writeln('PRÜFAUFTRAG – einzelne Prüfungsaufgabe')
      ..writeln()
      ..writeln('Du bist erfahrener Prüfer für die Fortbildung "Geprüfte/-r '
          'Meister/-in für Kraftverkehr (IHK)". Unten stehen eine '
          'Original-Prüfungsaufgabe, MEINE eigene Antwort und ${q.amtlich ? 'der AMTLICHE Lösungshinweis der IHK.' : 'eine Musterlösung, die NICHT von der IHK stammt.'}')
      ..writeln()
      ..writeln('Bewerte bitte MEINE Antwort:')
      ..writeln('1. Wie viele der ${punkte ?? 'möglichen'} Punkte würdest du '
          'vergeben? Begründe kurz.')
      ..writeln('2. Was fehlt meiner Antwort zur vollen Punktzahl? Nenne die '
          'fehlenden Elemente konkret.')
      ..writeln('3. Welche fachlichen Fehler enthält meine Antwort (falsche '
          'Aussage, falsche Rechnung, veraltete Rechtsgrundlage)?')
      ..writeln('4. Prüfe zusätzlich die Musterlösung selbst auf Richtigkeit '
          'und Aktualität (u. a. ArbSchG, ArbZG, StVO, StVZO, BetrVG, DGUV, '
          'VO (EG) 561/2006, VO (EU) 165/2014, BKrFQG, BetrSichV, '
          'DIN EN ISO 9001; Behörde heißt heute BALM).')
      ..writeln('Bei Rechenaufgaben: rechne eigenständig nach und zeige deinen '
          'Rechenweg.')
      ..writeln()
      ..writeln('==============================');
    final c = q.caseCtx;
    if (c != null) {
      b
        ..writeln('PRÜFUNG: ${c.title}')
        ..writeln()
        ..writeln('AUSGANGSSITUATION')
        ..writeln(c.context)
        ..writeln();
    }
    b
      ..writeln('------------------------------')
      ..writeln('AUFGABE: $kopf')
      ..writeln()
      ..writeln(rest);
    for (final t in q.tabsEffektiv) {
      b
        ..writeln()
        ..writeln(t.asText());
    }
    // Die Abbildung selbst lässt sich nicht als Text mitgeben – aber der
    // Hinweis darauf verhindert, dass die KI sie stillschweigend übergeht.
    final anlage = DataService.instance.anlage(q.bildEffektiv);
    if (anlage != null) {
      b
        ..writeln()
        ..writeln('[Zur Aufgabe gehört eine Abbildung: '
            '${anlage.titel.isNotEmpty ? anlage.titel : 'Anlage zur Aufgabe'}]');
    }
    b
      ..writeln()
      ..writeln('------------------------------')
      ..writeln('MEINE ANTWORT:')
      ..writeln(eigene.isEmpty ? '(noch nichts eingetragen)' : eigene)
      ..writeln()
      ..writeln('------------------------------')
      ..writeln(q.amtlich
          ? 'AMTLICHER LÖSUNGSHINWEIS (IHK):'
          : 'MUSTERLÖSUNG (nicht amtlich, bitte ebenfalls prüfen):')
      ..writeln(q.a ?? '(keine hinterlegt)');
    if (q.vo != null && q.vo!.isNotEmpty) {
      b
        ..writeln()
        ..writeln('VO-Bezug: ${q.vo}');
    }
    if (q.bewertung.isNotEmpty) {
      b.writeln('Punkteverteilung: ${q.bewertung.join(' + ')} Punkte');
    }
    if (q.e.isNotEmpty) {
      b
        ..writeln()
        ..writeln('Merksatz: ${q.e}');
    }
    b.writeln('==============================');
    return b.toString();
  }
}
