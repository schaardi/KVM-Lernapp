import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models.dart';
import '../constants.dart';

/// Lädt die gebündelten Fragen, Fälle und Formeln aus den Assets.
class DataService {
  static final DataService instance = DataService._();
  DataService._();

  List<Question> questions = [];
  List<CaseStudy> cases = [];
  List<FormulaGroup> formulas = [];
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final qRaw = await rootBundle.loadString('assets/data/questions.json');
    final cRaw = await rootBundle.loadString('assets/data/cases.json');
    final fRaw = await rootBundle.loadString('assets/data/formulas.json');
    questions = (json.decode(qRaw) as List)
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
    cases = (json.decode(cRaw) as List)
        .map((e) => CaseStudy.fromJson(e as Map<String, dynamic>))
        .toList();
    formulas = (json.decode(fRaw) as List)
        .map((e) => FormulaGroup.fromJson(e as Map<String, dynamic>))
        .toList();
    _loaded = true;
  }

  List<Question> forFach(int f) => questions.where((q) => q.f == f).toList();

  List<Question> forScope(int f, String sub) =>
      questions.where((q) => q.f == f && (sub == '*' || q.sub == sub)).toList();

  List<String> subsOfFach(int f) {
    final s = <String>[];
    for (final q in forFach(f)) {
      if (!s.contains(q.sub)) s.add(q.sub);
    }
    s.sort((a, b) => subOrderIndex(a).compareTo(subOrderIndex(b)));
    return s;
  }

  Map<int, int> fachCounts() {
    final c = <int, int>{};
    for (final q in questions) {
      c[q.f] = (c[q.f] ?? 0) + 1;
    }
    return c;
  }
}
