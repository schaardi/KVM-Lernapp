import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models.dart';
import '../services/answer_store.dart';
import '../services/data_service.dart';
import '../services/pruef_stat.dart';
import '../services/selection_service.dart';
import 'bereiche.dart';
import 'echt.dart';

/// Prüfungsergebnisse und Bestehenschance (FR-014 2–4, Web „Prüfungsergebnisse
/// und Bestehenschance“).
///
/// Jeder ausgewertete Durchgang einer Original-Prüfung steht in
/// `kvm_pruef_erg`: `{k, id, t, g, pkt, max, bew, teile, echt, dauer, min}`.
/// `k` kennzeichnet den Durchgang; `kvm_pruef_lauf` merkt ihn je Prüfung, bis
/// sie neu gestartet wird. Wer „Zum Ergebnis“ mehrmals drückt, ändert also
/// denselben Durchgang.
///
/// Gewertet wird ein Durchgang, wenn jede Teilaufgabe Punkte hat (auch 0) oder
/// er unter Prüfungsbedingungen lief – dort zählt Offenes wie in der Prüfung 0.
/// Für Statistik, Rangliste und Bestehenschance zählt je Prüfung nur der erste
/// gewertete Durchgang: Bei einer Wiederholung kennt man die Lösungen schon.
class PruefDurchgang {
  final String k;
  final String id;
  final int t; // ausgewertet am (ms)
  final int g; // zuletzt bewertet (ms) – gewinnt beim Abgleich
  final int pkt;
  final int max;
  final int? bew; // Teilaufgaben mit Punkten
  final int? teile; // Teilaufgaben mit Punktangabe
  final bool echt;
  final int? dauer; // ms, nur unter Prüfungsbedingungen
  final int? min; // vorgesehene Zeit in Minuten

  const PruefDurchgang({
    required this.k,
    required this.id,
    required this.t,
    this.g = 0,
    required this.pkt,
    required this.max,
    this.bew,
    this.teile,
    this.echt = false,
    this.dauer,
    this.min,
  });

  PruefDurchgang kopie({int? t, int? g, bool? echt, int? dauer, int? min}) => PruefDurchgang(
        k: k,
        id: id,
        t: t ?? this.t,
        g: g ?? this.g,
        pkt: pkt,
        max: max,
        bew: bew,
        teile: teile,
        echt: echt ?? this.echt,
        dauer: dauer ?? this.dauer,
        min: min ?? this.min,
      );

  /// Punkte in Prozent (IHK: Prozent = Punkte).
  int get prozent => max > 0 ? (pkt / max * 100).round() : 0;

  bool get gewertet => max > 0 && (echt || ((teile ?? 0) > 0 && (bew ?? 0) >= (teile ?? 0)));

  bool get bestanden => prozent >= 50;

  int get note => ihkGrade(prozent).note;

  Map<String, dynamic> toJson() => {
        'k': k,
        'id': id,
        't': t,
        'g': g,
        'pkt': pkt,
        'max': max,
        'bew': bew,
        'teile': teile,
        'echt': echt ? 1 : 0,
        if (echt) 'dauer': dauer ?? 0,
        if (echt) 'min': min ?? 0,
      };

  static int? _int(dynamic v) => v is num ? v.toInt() : null;

  static PruefDurchgang? fromJson(dynamic j) {
    if (j is! Map) return null;
    final k = j['k'], id = j['id'];
    if (k is! String || k.isEmpty || id is! String || id.isEmpty) return null;
    return PruefDurchgang(
      k: k,
      id: id,
      t: _int(j['t']) ?? 0,
      g: _int(j['g']) ?? 0,
      pkt: _int(j['pkt']) ?? 0,
      max: _int(j['max']) ?? 0,
      bew: _int(j['bew']),
      teile: _int(j['teile']),
      echt: j['echt'] == true || j['echt'] == 1,
      dauer: _int(j['dauer']),
      min: _int(j['min']),
    );
  }
}

/// Erstversuch eines Bereichs: Prozent und ob unter Prüfungsbedingungen.
class PruefVersuch {
  final String id;
  final int p;
  final bool echt;
  final int t;
  const PruefVersuch(this.id, this.p, this.echt, this.t);
}

/// Stand je Prüfungsbereich.
class BereichStand {
  final PruefBereich bereich;
  final List<PruefVersuch> erst; // Erstversuche, ältester zuerst
  final double? chance;
  const BereichStand(this.bereich, this.erst, this.chance);

  int get n => erst.length;
  int get ok => erst.where((e) => e.p >= 50).length;
  int? get schnitt => n == 0 ? null : (erst.fold<int>(0, (a, e) => a + e.p) / n).round();
}

/// Chance eines Teils: Produkt der Bereichschancen, nur wenn jeder Bereich
/// gewertet ist – sonst fehlen Bereiche.
class TeilStand {
  final List<String> fehlt;
  final int n;
  final double? p;
  const TeilStand(this.fehlt, this.n, this.p);
}

class PruefUebersicht {
  final Map<String, BereichStand> bereiche;
  final TeilStand bq;
  final TeilStand? hq; // null, wenn die Fachrichtung Kraftverkehr aus ist
  final double? gesamt;
  final ({double p, String teil})? haupt;
  final int n;
  final int ok;
  final int? schnitt;
  final int durchgaenge;
  const PruefUebersicht({
    required this.bereiche,
    required this.bq,
    required this.hq,
    required this.gesamt,
    required this.haupt,
    required this.n,
    required this.ok,
    required this.schnitt,
    required this.durchgaenge,
  });
}

/// Standardnormalverteilung (Abramowitz/Stegun 7.1.26, Fehler < 2e-7).
double peCdf(double z) {
  final t = 1 / (1 + 0.3275911 * z.abs() / math.sqrt2);
  final y = 1 -
      ((((1.061405429 * t - 1.453152027) * t + 1.421413741) * t - 0.284496736) * t + 0.254829592) *
          t *
          math.exp(-z * z / 2);
  return z >= 0 ? (1 + y) / 2 : (1 - y) / 2;
}

const double _peStreu = 12;
const double _peGrenze = 49.5;

/// Bestehenschance eines Prüfungsbereichs aus den Erstversuchen (ältester
/// zuerst): gewichteter Schnitt – jede ältere Prüfung zählt 0,8-mal so viel
/// wie die nächste, Prüfungsbedingungen 1,5-fach. Die Streuung zwischen zwei
/// Prüfungen ist auf 12 Punkte gestützt und wird ab der zweiten Prüfung aus
/// den eigenen Ergebnissen dazugelernt. Chance = P(nächste Prüfung ≥ 50
/// Punkte) unter einer Normalverteilung, die auch die Unsicherheit des
/// Schnitts enthält – mit einer Prüfung ist sie deshalb vorsichtig.
double? peChance(List<PruefVersuch> xs) {
  final n = xs.length;
  if (n == 0) return null;
  var sw = 0.0, sw2 = 0.0, mu = 0.0;
  final w = <double>[];
  for (var i = 0; i < n; i++) {
    final g = math.pow(0.8, n - 1 - i).toDouble() * (xs[i].echt ? 1.5 : 1);
    w.add(g);
    sw += g;
    sw2 += g * g;
    mu += g * xs[i].p;
  }
  mu /= sw;
  var s2 = 0.0;
  for (var i = 0; i < n; i++) {
    s2 += w[i] * (xs[i].p - mu) * (xs[i].p - mu);
  }
  s2 = n > 1 ? s2 / sw * n / (n - 1) : 0;
  final streu2 = (3 * _peStreu * _peStreu + (n - 1) * s2) / (n + 2);
  final neff = sw * sw / sw2;
  return peCdf((mu - _peGrenze) / math.sqrt(streu2 * (1 + 1 / neff)));
}

/// Chance als Text: ganze Prozent, darüber und darunter mit Zeichen.
String peProzent(double? p) {
  if (p == null) return '–';
  final x = (p * 100).round();
  if (x >= 99 && p > 0.99) return '> 99 %';
  if (x < 1) return '< 1 %';
  return '$x %';
}

/// Stufe der Chance: ab 70 % grün, ab 40 % gelb, darunter rot.
enum ChanceStufe { gut, mittel, knapp }

ChanceStufe? chanceStufe(double? p) => p == null ? null : (p >= 0.7 ? ChanceStufe.gut : (p >= 0.4 ? ChanceStufe.mittel : ChanceStufe.knapp));

class PruefErgebnisse {
  PruefErgebnisse._();
  static final PruefErgebnisse instance = PruefErgebnisse._();

  static const _key = 'kvm_pruef_erg';
  static const _laufKey = 'kvm_pruef_lauf';
  static const _altKey = 'kvm_echt_verlauf';

  SharedPreferences? _prefs;
  List<PruefDurchgang> _liste = [];
  Map<String, String> _lauf = {};
  final _rng = math.Random();

  /// Nach jeder Änderung (neu gewertet, aus der Cloud übernommen) – die Cloud
  /// gleicht dann ab, die Startseite zeichnet neu.
  void Function()? onGeaendert;

  /// Liest die Durchgänge; einmalig wird der alte Verlauf unter
  /// Prüfungsbedingungen (`kvm_echt_verlauf`, FR-007) übernommen.
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _liste = [];
    _lauf = {};
    final roh = _prefs!.getString(_key);
    if (roh != null) {
      try {
        final v = json.decode(roh);
        if (v is List) _liste = v.map(PruefDurchgang.fromJson).whereType<PruefDurchgang>().toList();
      } catch (_) {}
    } else {
      _liste = _uebernehmen(_prefs!.getString(_altKey));
      _speichern();
    }
    final l = _prefs!.getString(_laufKey);
    if (l != null && l.isNotEmpty) {
      try {
        (json.decode(l) as Map).forEach((k, v) {
          if (k is String && v is String) _lauf[k] = v;
        });
      } catch (_) {}
    }
    _aktualisieren();
  }

  /// Übernahme aus `kvm_echt_verlauf`: Kennung `e<tag>-<id>-<dauer>`,
  /// `t = g = tag·86400000 + 12 h`, unter Prüfungsbedingungen.
  static List<PruefDurchgang> _uebernehmen(String? roh) {
    if (roh == null || roh.isEmpty) return [];
    dynamic alt;
    try {
      alt = json.decode(roh);
    } catch (_) {
      return [];
    }
    if (alt is! List) return [];
    final neu = <PruefDurchgang>[];
    for (final x in alt) {
      if (x is! Map) continue;
      final id = x['id'], max = x['max'], tag = x['tag'];
      if (id is! String || id.isEmpty || max is! num || max <= 0) continue;
      final tg = tag is num ? tag.toInt() : 0;
      final dauer = x['dauer'] is num ? (x['dauer'] as num).toInt() : 0;
      final t = tg * 86400000 + 43200000;
      neu.add(PruefDurchgang(
        k: 'e$tg-$id-$dauer',
        id: id,
        t: t,
        g: t,
        pkt: x['pkt'] is num ? (x['pkt'] as num).toInt() : 0,
        max: max.toInt(),
        echt: true,
        dauer: dauer,
        min: x['min'] is num ? (x['min'] as num).toInt() : 0,
      ));
    }
    neu.sort((a, b) => a.t.compareTo(b.t));
    return neu;
  }

  void _speichern() {
    if (_liste.length > 500) _liste = _liste.sublist(_liste.length - 500);
    _prefs?.setString(_key, json.encode(_liste.map((e) => e.toJson()).toList()));
  }

  /// Statistik für die anderen Pakete setzen und alle benachrichtigen.
  void _aktualisieren() {
    pruefStatistik = statistikFuerCloud;
    nachDemBauen(() => pruefStand.value++);
  }

  void _geaendert() {
    _aktualisieren();
    onGeaendert?.call();
  }

  /// Alle Durchgänge, nach `t` sortiert.
  List<PruefDurchgang> get alle => List.unmodifiable(_liste);

  /// Die Durchgänge einer Prüfung, ältester zuerst.
  List<PruefDurchgang> von(String id) => _liste.where((e) => e.id == id).toList();

  /// Aktuelle Durchgangskennung einer Prüfung; [neu] vergibt eine neue (Start
  /// unter Prüfungsbedingungen, „Neu starten“).
  String lauf(String id, {bool neu = false}) {
    if (neu || !_lauf.containsKey(id)) {
      const zeichen = '0123456789abcdefghijklmnopqrstuvwxyz';
      final zufall = List.generate(5, (_) => zeichen[_rng.nextInt(36)]).join();
      _lauf[id] = '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}$zufall';
      _prefs?.setString(_laufKey, json.encode(_lauf));
    }
    return _lauf[id]!;
  }

  /// Der Durchgang, wie er gerade auf dem Blatt steht: Punkte je Teilaufgabe.
  PruefDurchgang durchgang(CaseStudy fall, {EchtLauf? echt, int? jetzt}) {
    var pkt = 0, max = 0, bew = 0, teile = 0;
    for (final s in fall.steps) {
      final m = s.maxPoints;
      if (m <= 0) continue;
      max += m;
      teile++;
      final g = AnswerStore.instance.points(s.id);
      if (g != null) {
        pkt += g;
        bew++;
      }
    }
    return PruefDurchgang(
      k: lauf(fall.id),
      id: fall.id,
      t: jetzt ?? DateTime.now().millisecondsSinceEpoch,
      pkt: pkt,
      max: max,
      bew: bew,
      teile: teile,
      echt: echt != null,
      dauer: echt?.dauer,
      min: echt?.min,
    );
  }

  /// Einen Durchgang merken. Denselben Durchgang ersetzt er; `t` bleibt, `echt`
  /// bleibt 1, `g` = max(jetzt, altes g + 1).
  PruefDurchgang merken(PruefDurchgang r, {int? jetzt}) {
    PruefDurchgang? alt;
    _liste = _liste.where((x) {
      if (x.k == r.k) {
        alt = x;
        return false;
      }
      return true;
    }).toList();
    var neu = r;
    final a = alt;
    if (a != null) {
      neu = neu.kopie(t: a.t);
      if (a.echt && !neu.echt) neu = neu.kopie(echt: true, dauer: a.dauer, min: a.min);
    }
    final t = jetzt ?? DateTime.now().millisecondsSinceEpoch;
    neu = neu.kopie(g: math.max(t, a != null && a.g > 0 ? a.g + 1 : 0));
    _liste.add(neu);
    _liste.sort((x, y) => x.t.compareTo(y.t));
    _speichern();
    _geaendert();
    return neu;
  }

  /// Stand aus der Cloud übernehmen: je Durchgang gilt der zuletzt bewertete,
  /// `echt` bleibt 1. Gibt true zurück, wenn sich etwas geändert hat.
  bool zusammenfuehren(List<dynamic> fremd) {
    final m = <String, PruefDurchgang>{for (final e in _liste) e.k: e};
    var neu = false;
    for (final f in fremd) {
      if (f is! Map) continue;
      final k = f['k'], id = f['id'], max = f['max'];
      if (k is! String || k.isEmpty || id is! String || !RegExp(r'^P-[A-Z]+-\d+$').hasMatch(id)) continue;
      if (max is! num || max <= 0) continue;
      final e = m[k];
      final g = f['g'] is num ? (f['g'] as num).toInt() : 0;
      if (e == null || g > e.g) {
        m[k] = PruefDurchgang.fromJson(f)!;
        neu = true;
      } else if ((f['echt'] == 1 || f['echt'] == true) && !e.echt) {
        m[k] = e.kopie(
          echt: true,
          dauer: (e.dauer ?? 0) > 0 ? e.dauer : (f['dauer'] is num ? (f['dauer'] as num).toInt() : 0),
          min: (e.min ?? 0) > 0 ? e.min : (f['min'] is num ? (f['min'] as num).toInt() : 0),
        );
        neu = true;
      }
    }
    if (!neu) return false;
    _liste = m.values.toList()..sort((a, b) => a.t.compareTo(b.t));
    _speichern();
    _aktualisieren();
    return true;
  }

  /// Erster gewerteter Durchgang je Prüfung (Liste ist nach Zeit sortiert).
  List<PruefDurchgang> erstversuche() {
    final gesehen = <String>{};
    final out = <PruefDurchgang>[];
    for (final e in _liste) {
      if (e.gewertet && gesehen.add(e.id)) out.add(e);
    }
    return out;
  }

  /// Zählt der handlungsspezifische Teil mit? Nur, wenn die Fachrichtung
  /// Kraftverkehr aktiv ist.
  static bool mitHq() =>
      SelectionService.instance.isFachActive(5) && (DataService.instance.fachCounts()[5] ?? 0) > 0;

  PruefUebersicht statistik({bool? hqAktiv}) {
    final erst = <String, List<PruefVersuch>>{for (final b in kPruefBereiche) b.k: []};
    for (final e in erstversuche()) {
      erst[bereichVonId(e.id)]?.add(PruefVersuch(e.id, e.prozent, e.echt, e.t));
    }
    final bereiche = <String, BereichStand>{};
    var n = 0, ok = 0, summe = 0;
    for (final b in kPruefBereiche) {
      final xs = erst[b.k]!;
      final st = BereichStand(b, xs, peChance(xs));
      bereiche[b.k] = st;
      n += st.n;
      ok += st.ok;
      summe += xs.fold<int>(0, (a, e) => a + e.p);
    }
    TeilStand teil(List<String> ks) {
      final fehlt = ks.where((k) => bereiche[k]!.chance == null).toList();
      return TeilStand(
          fehlt, ks.length, fehlt.isNotEmpty ? null : ks.fold<double>(1, (a, k) => a * bereiche[k]!.chance!));
    }

    final hq = hqAktiv ?? mitHq();
    final bq = teil(kBereicheBq);
    final hqT = hq ? teil(kBereicheHq) : null;
    final gesamt = hq ? ((bq.p != null && hqT!.p != null) ? bq.p! * hqT.p! : null) : bq.p;
    // Eine Zahl für Rangliste und Profilkopf: beide Teile, sonst der Teil, in
    // dem jeder Bereich gewertet ist.
    final ({double p, String teil})? haupt = gesamt != null
        ? (p: gesamt, teil: hq ? 'g' : 'bq')
        : (bq.p != null ? (p: bq.p!, teil: 'bq') : (hqT?.p != null ? (p: hqT!.p!, teil: 'hq') : null));
    return PruefUebersicht(
      bereiche: bereiche,
      bq: bq,
      hq: hqT,
      gesamt: gesamt,
      haupt: haupt,
      n: n,
      ok: ok,
      schnitt: n > 0 ? (summe / n).round() : null,
      durchgaenge: _liste.length,
    );
  }

  /// Die Kennzahlen für das Paket „Cloud“ (Rangliste, Profil-Details).
  PruefStatistik statistikFuerCloud() {
    final st = statistik();
    return PruefStatistik(
      n: st.n,
      ok: st.ok,
      schnitt: st.schnitt,
      bq: st.bq.p,
      hq: st.hq?.p,
      gesamt: st.gesamt,
      haupt: st.haupt?.p,
      bereiche: {
        for (final e in st.bereiche.entries)
          e.key: PruefBereichStat(
            kurz: e.value.bereich.kurz,
            n: e.value.n,
            ok: e.value.ok,
            schnitt: e.value.schnitt,
            chance: e.value.chance,
          ),
      },
    );
  }

  /// Durchgänge unter Prüfungsbedingungen (für „Zuletzt unter
  /// Prüfungsbedingungen“ und die Rangliste): ein Ausschnitt aus
  /// `kvm_pruef_erg`.
  List<PruefDurchgang> echtVerlauf() => _liste.where((e) => e.echt).toList();

  /// Neu starten ohne Nachfrage: Ein vollständig bewerteter Durchgang, der nie
  /// „Zum Ergebnis“ gesehen hat, wird vorher gemerkt; ein Durchgang unter
  /// Prüfungsbedingungen endet; die Blätter werden geleert; die Prüfung
  /// bekommt eine neue Durchgangskennung.
  void neuStarten(CaseStudy fall) {
    final e = Echtbedingungen.instance.von(fall.id);
    final d = durchgang(fall, echt: (e != null && e.abgegeben) ? e : null);
    if ((d.teile ?? 0) > 0 && (d.bew ?? 0) >= (d.teile ?? 0)) merken(d);
    if (e != null) Echtbedingungen.instance.setzen(null);
    AnswerStore.instance.leeren(fall.steps.map((s) => s.id));
    lauf(fall.id, neu: true);
    _aktualisieren();
  }

  /// Start unter Prüfungsbedingungen ohne Nachfrage: leere Blätter, Uhr ab
  /// jetzt, neue Durchgangskennung.
  void echtStarten(CaseStudy fall, {int? jetzt}) {
    final ids = fall.steps.map((s) => s.id).toList();
    if (ids.any(AnswerStore.instance.hatStand)) AnswerStore.instance.leeren(ids);
    Echtbedingungen.instance.setzen(EchtLauf(
      id: fall.id,
      start: jetzt ?? DateTime.now().millisecondsSinceEpoch,
      min: echtMinuten(fall),
    ));
    lauf(fall.id, neu: true);
    _aktualisieren();
  }
}
