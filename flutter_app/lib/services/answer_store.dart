import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

/// Speichert die selbst formulierten Antworten zu offenen Aufgaben, damit sie
/// beim Blättern und nach einem Neustart erhalten bleiben.
class AnswerStore {
  AnswerStore._();
  static final AnswerStore instance = AnswerStore._();

  static const _key = 'kvm_open_answers';
  static const _pkey = 'kvm_open_points';
  SharedPreferences? _prefs;
  Map<String, String> _answers = {};
  Map<String, int> _points = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        _answers = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {
        _answers = {};
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

  /// Eine einzelne Teilaufgabe samt eigener Antwort als Prüfauftrag – wortgleich
  /// zur Web-Fassung, damit beide Wege dasselbe Ergebnis liefern.
  static String exportTask(Question q) {
    final eigene = AnswerStore.instance.get(q.id).trim();
    final teile = q.q.split('\n\n');
    final kopf = teile.isNotEmpty ? teile.first : '';
    final rest = teile.skip(1).join('\n\n');
    final punkte = RegExp(r'·\s*(\d+)\s*Punkt').firstMatch(kopf)?.group(1);

    final b = StringBuffer()
      ..writeln('PRÜFAUFTRAG – einzelne Prüfungsaufgabe')
      ..writeln()
      ..writeln('Du bist erfahrener Prüfer für die Fortbildung "Geprüfte/-r '
          'Meister/-in für Kraftverkehr (IHK)". Unten stehen eine '
          'Original-Prüfungsaufgabe, MEINE eigene Antwort und eine '
          'Musterlösung, die NICHT von der IHK stammt.')
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
          'DIN EN ISO 9001; die Behörde heißt heute BALM).')
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
    if (q.tab != null) {
      b
        ..writeln()
        ..writeln(q.tab!.asText());
    }
    b
      ..writeln()
      ..writeln('------------------------------')
      ..writeln('MEINE ANTWORT:')
      ..writeln(eigene.isEmpty ? '(noch nichts eingetragen)' : eigene)
      ..writeln()
      ..writeln('------------------------------')
      ..writeln('MUSTERLÖSUNG (nicht amtlich, bitte ebenfalls prüfen):')
      ..writeln(q.a ?? '(keine hinterlegt)');
    if (q.e.isNotEmpty) {
      b
        ..writeln()
        ..writeln('Merksatz: ${q.e}');
    }
    b.writeln('==============================');
    return b.toString();
  }
}
