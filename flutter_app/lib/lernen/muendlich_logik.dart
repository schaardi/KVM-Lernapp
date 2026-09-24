import 'dart:math';
import '../models.dart';
import '../services/data_service.dart';
import '../services/round_builder.dart';

/// Mündliche Prüfung üben (FR-011): welche Fragen sich eignen, welche
/// Begriffe der Lösung in der Antwort vorkamen – reine Logik wie im Web
/// (`orGeeignet`, `orBegriffe`, `orStamm`, `orGetroffen`).

/// Fragen je Übung.
const int kMuendlichLaenge = 10;

/// Unter so vielen geeigneten Fragen ist die Übung aus.
const int kMuendlichMindestens = 3;

/// Auswahlfragen, die ohne ihre Optionen nicht verständlich sind.
final RegExp _ungeeignet = RegExp(
  r'folgend|Aussage|trifft|richtig|falsch|zutreffend|\bnicht\b|\bkein|Beispiel|welche[rs]? (der|dieser)|'
  r'Welche Antwort|Was gilt|Wofür steht|Kombination|Reihenfolge|ordnen',
  caseSensitive: false,
);

/// Füllwörter, die nie als Begriff zählen (Web `OR_FUELL`).
const Set<String> _fuell = {
  'aber', 'alle', 'allem', 'allen', 'aller', 'alles', 'also', 'auch', 'auf', 'aus', 'bei', 'beim', 'bzw', 'dabei',
  'damit', 'dann', 'dass', 'dem', 'den', 'denen', 'der', 'des', 'die', 'dies', 'diese', 'diesem', 'diesen', 'dieser',
  'dieses', 'durch', 'eine', 'einem', 'einen', 'einer', 'eines', 'etwa', 'für', 'gegen', 'hat', 'haben', 'ihre',
  'ihren', 'immer', 'indem', 'insbesondere', 'jede', 'jedem', 'jeden', 'jeder', 'jedes', 'kann', 'können', 'mehr',
  'mit', 'muss', 'müssen', 'nach', 'noch', 'nur', 'oder', 'ohne', 'sich', 'sind', 'soll', 'sollen', 'sowie', 'über',
  'unter', 'usw', 'vom', 'von', 'vor', 'während', 'weil', 'wenn', 'werden', 'wird', 'wurde', 'wurden', 'zum', 'zur',
  'zwischen', 'sehr', 'sein', 'seine', 'seiner', 'jeweils', 'möglichst', 'bestimmte', 'bestimmten',
};

final RegExp _wort = RegExp(r'[A-Za-zÄÖÜäöüß][A-Za-zÄÖÜäöüß-]{4,}');
final RegExp _gross = RegExp(r'^[A-ZÄÖÜ]');
final RegExp _endung = RegExp(r'(ungen|ung|en|er|es|e|n|s)$');

/// Eignet sich die Frage fürs Fachgespräch?
/// - offene Fragen mit Musterlösung oder Erklärung,
/// - Auswahlfragen, die allein verständlich sind: enden auf „?“, höchstens
///   220 Zeichen, eine richtige Option, keine „Welche Aussage …“-Form.
bool muendlichGeeignet(Question q) {
  if (q.type == 'open') return (q.a ?? '').isNotEmpty || q.e.isNotEmpty;
  if (q.type != 'mc' || q.o.isEmpty) return false;
  return !_ungeeignet.hasMatch(q.q) &&
      q.q.length <= 220 &&
      _frageZeichen.hasMatch(q.q) &&
      q.o.any((o) => o.ok);
}

final RegExp _frageZeichen = RegExp(r'\?\s*$');

/// Richtige Option einer Auswahlfrage (leer, falls keine).
String richtigeOption(Question q) {
  for (final o in q.o) {
    if (o.ok) return o.t;
  }
  return '';
}

/// Lösung zum Vergleich: offen die Musterlösung, sonst die richtige Option
/// und darunter die Erklärung.
String muendlichLoesung(Question q) {
  if (q.type == 'open') {
    final a = q.a ?? '';
    return a.isNotEmpty ? a : q.e;
  }
  final r = richtigeOption(q);
  return q.e.isNotEmpty ? '$r\n\n${q.e}' : r;
}

/// Quelle der Begriffe: bei Auswahlfragen die richtige Option, sonst die
/// Musterlösung.
String begriffeQuelle(Question q) {
  if (q.type == 'mc') {
    final r = richtigeOption(q);
    return r.isNotEmpty ? r : muendlichLoesung(q);
  }
  return muendlichLoesung(q);
}

/// Schlüsselbegriffe: Wörter ab 5 Buchstaben ohne Füllwörter und Dopplungen,
/// großgeschriebene zuerst, höchstens 8.
List<String> begriffe(String text) {
  final gesehen = <String>{};
  final out = <String>[];
  for (final m in _wort.allMatches(text)) {
    final w = m.group(0)!;
    final k = w.toLowerCase();
    if (_fuell.contains(k) || !gesehen.add(k)) continue;
    out.add(w);
  }
  // Stabil sortieren: Großgeschriebene nach vorn, sonst Reihenfolge behalten.
  final gross = out.where((w) => _gross.hasMatch(w)).toList();
  final klein = out.where((w) => !_gross.hasMatch(w)).toList();
  return [...gross, ...klein].take(8).toList();
}

/// Wortstamm: klein, Endung ab, auf 4–8 Zeichen gekürzt.
String wortstamm(String w) {
  final k = w.toLowerCase().replaceFirst(_endung, '');
  return k.substring(0, min(8, max(4, k.length)).clamp(0, k.length));
}

/// Kommt der Begriff (als Stamm) in der Antwort vor?
bool begriffGetroffen(String begriff, String antwort) => antwort.toLowerCase().contains(wortstamm(begriff));

/// Geeignete Fragen im gewählten Bereich (Fach + Themenbereich).
List<Question> muendlichKandidaten(int fach, String sub) =>
    DataService.instance.forScope(fach, sub).where(muendlichGeeignet).toList();

/// Zehn Fragen, gewichtet wie im Training (neue und zuletzt falsche zuerst).
List<Question> muendlichPool(List<Question> kandidaten) =>
    RoundBuilder.gemischt(RoundBuilder.gewichtet(kandidaten, min(kMuendlichLaenge, kandidaten.length)));
