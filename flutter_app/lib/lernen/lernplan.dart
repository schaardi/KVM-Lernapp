import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../services/data_service.dart';
import '../services/lerntage_service.dart';
import '../services/progress_service.dart';
import '../util/format.dart';
import '../widgets/ui.dart' show Ampel;
import 'datum.dart';

/// Prüfungstermin und Lernplan (FR-006), gerechnet wie im Web (`planRechnen`).
///
/// Ziel des Plans ist die Ampel „prüfungsreif“ – 70 % Prüfungsreife wie im
/// Ring – bis zum Tag vor der Prüfung. Dafür fehlen je Frage so viele richtige
/// Antworten, wie ihr bis Box 3 fehlen; die eigene Trefferquote rechnet die
/// falschen dazu. Das Tagesziel wird einmal am Tag festgelegt – sonst
/// schrumpfte es beim Lernen – und neu gerechnet, wenn sich Termin oder
/// Fächerwahl ändern. Die Prognose nimmt das Tempo der letzten sieben Tage.
const double kPlanZiel = 0.7;

/// Gespeicherter Termin – `kvm_pruefung` wie im Web:
/// `{"datum": "2026-11-04", "tag": 20719, "n": 3666, "ziel": 245}`.
@immutable
class PruefungsTermin {
  /// Prüfungstag (ISO).
  final String datum;

  /// Tagesindex, an dem [ziel] festgelegt wurde (fehlt nach dem Speichern).
  final int? tag;

  /// Zahl der aktiven Fragen bei der Festlegung.
  final int? n;

  /// Tagesziel (Fragen).
  final int? ziel;

  const PruefungsTermin({required this.datum, this.tag, this.n, this.ziel});

  /// Liest den gespeicherten Wert; `null` bei fehlendem oder kaputtem Eintrag.
  static PruefungsTermin? lesen(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final d = json.decode(raw);
      if (d is! Map || !istIsoDatum(d['datum']?.toString())) return null;
      int? zahl(Object? v) => v is num ? v.toInt() : null;
      return PruefungsTermin(datum: d['datum'].toString(), tag: zahl(d['tag']), n: zahl(d['n']), ziel: zahl(d['ziel']));
    } catch (_) {
      return null;
    }
  }

  String schreiben() => json.encode({
        'datum': datum,
        if (tag != null) 'tag': tag,
        if (n != null) 'n': n,
        if (ziel != null) 'ziel': ziel,
      });

  int get pruefungsTag => tagVon(datum);
}

/// Alles, was die Rechnung aus dem Lernstand braucht.
@immutable
class PlanEingabe {
  /// Heutiger Tagesindex (Ortszeit, wie `kvm_tage`).
  final int heute;

  /// Zahl der aktiven Fragen (N).
  final int n;

  /// Σ min(box, 3) über die aktiven Fragen.
  final int summeBoxen;

  /// Richtige und falsche Antworten über den ganzen Lernstand.
  final int richtig;
  final int falsch;

  /// Antworten der letzten sieben Tage ohne heute.
  final int woche;

  /// Antworten heute (`kvm_tage[heute]`).
  final int geschafft;

  /// Heute fällige Fragen.
  final int faellig;

  const PlanEingabe({
    required this.heute,
    required this.n,
    this.summeBoxen = 0,
    this.richtig = 0,
    this.falsch = 0,
    this.woche = 0,
    this.geschafft = 0,
    this.faellig = 0,
  });
}

/// Ergebnis der Rechnung (Web: Rückgabe von `planRechnen`).
@immutable
class PlanStand {
  final int pruefung; // Tagesindex der Prüfung
  final int tage; // Prüfungstag − heute
  final int noetig; // richtige Antworten bis 70 %
  final int ziel; // Tagesziel
  final int geschafft; // Antworten heute
  final double tempo; // Ø Antworten je Tag der letzten 7 Tage
  final double quote; // Trefferquote
  final int? prognose; // Tagesindex der Prüfungsreife bei diesem Tempo

  const PlanStand({
    required this.pruefung,
    required this.tage,
    required this.noetig,
    required this.ziel,
    required this.geschafft,
    required this.tempo,
    required this.quote,
    this.prognose,
  });
}

/// Rechnet den Plan. Gibt auch den Termin zurück – mit neu festgelegtem
/// Tagesziel, falls heute noch keins feststand oder sich die Fächerwahl
/// geändert hat (dann ist er ein neues Objekt und muss gespeichert werden).
({PlanStand stand, PruefungsTermin termin}) planRechnen(PruefungsTermin t, PlanEingabe e) {
  final pruefung = t.pruefungsTag;
  final tage = pruefung - e.heute;
  final zusammen = e.richtig + e.falsch;
  final quote = zusammen >= 30 ? (e.richtig / zusammen).clamp(0.5, 0.95).toDouble() : 0.75;
  // Reihenfolge wie im Web (0,7 · 3 · N), damit die Rundung gleich ausfällt.
  final roh = (kPlanZiel * kMasterBox * e.n - e.summeBoxen).ceil();
  final noetig = roh < 0 ? 0 : roh;
  var termin = t;
  if (t.tag != e.heute || t.n != e.n) {
    final ziel = tage > 0 ? (noetig > 0 ? (noetig / quote / tage).ceil() : e.faellig) : 0;
    termin = PruefungsTermin(datum: t.datum, tag: e.heute, n: e.n, ziel: ziel);
  }
  final tempo = e.woche / 7;
  return (
    stand: PlanStand(
      pruefung: pruefung,
      tage: tage,
      noetig: noetig,
      ziel: termin.ziel ?? 0,
      geschafft: e.geschafft,
      tempo: tempo,
      quote: quote,
      prognose: (noetig > 0 && tempo >= 1) ? e.heute + (noetig / (tempo * quote)).ceil() : null,
    ),
    termin: termin,
  );
}

/// Statuszeile unter dem Tagesziel: Ampel und Text (erste passende Regel).
/// [schwerpunkte]: bei sehr hohem Tagesziel den Tipp „Setz Schwerpunkte …“
/// anhängen (auf sehr niedrigen Bildschirmen entfällt er).
({Ampel ampel, String text}) planStatus(PlanStand p, {int? laufendesJahr, bool schwerpunkte = true}) {
  final z = p.ziel;
  final g = p.geschafft;
  final prozent = (kPlanZiel * 100).round();
  late Ampel amp;
  late String txt;
  if (p.noetig == 0) {
    amp = Ampel.gruen;
    txt = z > 0
        ? 'Ziel erreicht: $prozent % prüfungsreif. Halte den Stand mit den fälligen Fragen.'
        : 'Ziel erreicht: $prozent % prüfungsreif. Heute ist nichts fällig – probier eine Original-Prüfung.';
  } else if (z > 0 && g >= z) {
    amp = Ampel.gruen;
    txt = 'Tagesziel geschafft – stark! Morgen geht es weiter.';
  } else if (p.prognose != null) {
    final tempo = fmtN(p.tempo.round());
    final am = datumKurz(p.prognose!, laufendesJahr: laufendesJahr);
    if (p.prognose! < p.pruefung) {
      amp = Ampel.gruen;
      txt = 'Im Plan: Mit Ø $tempo Fragen am Tag bist du am $am prüfungsreif ($prozent %).';
    } else {
      amp = z > 120 ? Ampel.rot : Ampel.gelb;
      txt = 'Rückstand: Mit Ø $tempo Fragen am Tag wärst du erst am $am prüfungsreif. '
          'Mit dem Tagesziel klappt es bis zur Prüfung.';
    }
  } else {
    amp = z <= 60 ? Ampel.gruen : (z <= 120 ? Ampel.gelb : Ampel.rot);
    final wie = z <= 60 ? 'Gut machbar' : (z <= 120 ? 'Sportlich' : 'Sehr knapp');
    txt = '$wie: Mit ${fmtN(z)} Fragen am Tag bist du bis zur Prüfung zu $prozent % prüfungsreif.';
  }
  if (schwerpunkte && p.noetig > 0 && z > 150) txt += ' Setz Schwerpunkte, z. B. mit „Schwächen üben“.';
  return (ampel: amp, text: txt);
}

/// Prüfung für einen Termin im Formular: `null` = in Ordnung, sonst der Fehler.
String? terminFehler(String? datum, {required int heute}) {
  if (!istIsoDatum(datum)) return 'Bitte ein Datum wählen.';
  if (tagVon(datum!) <= heute) return 'Der Termin muss in der Zukunft liegen.';
  return null;
}

/// Liest die Eingaben der Rechnung aus dem Lernstand.
PlanEingabe planEingabeAusLernstand({int? heute}) {
  final h = heute ?? LerntageService.heute();
  final prog = ProgressService.instance;
  final aktiv = DataService.instance.activeQuestions();
  var summe = 0;
  for (final q in aktiv) {
    final p = prog.get(q.id);
    if (p != null) summe += p.box < kMasterBox ? p.box : kMasterBox;
  }
  // Trefferquote über den ganzen Lernstand (wie im Web: alle Einträge).
  var richtig = 0, falsch = 0;
  for (final v in prog.exportJson().values) {
    if (v is Map) {
      richtig += (v['c'] as num?)?.toInt() ?? 0;
      falsch += (v['w'] as num?)?.toInt() ?? 0;
    }
  }
  final tage = LerntageService.instance;
  var woche = 0;
  for (var k = 1; k <= 7; k++) {
    woche += tage.anTag(h - k);
  }
  return PlanEingabe(
    heute: h,
    n: aktiv.length,
    summeBoxen: summe,
    richtig: richtig,
    falsch: falsch,
    woche: woche,
    geschafft: tage.anTag(h),
    faellig: prog.dueCount(),
  );
}

/// Der Prüfungstermin auf dem Gerät (`kvm_pruefung`). Er wird (noch) nicht
/// synchronisiert – ein Sonderschlüssel in `progress.data` störte den Merge.
class Lernplan extends ChangeNotifier {
  Lernplan._();
  static final Lernplan instance = Lernplan._();

  static const schluessel = 'kvm_pruefung';

  SharedPreferences? _prefs;
  PruefungsTermin? _termin;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _termin = PruefungsTermin.lesen(_prefs!.getString(schluessel));
  }

  PruefungsTermin? get termin => _termin;

  /// Neuer Termin; das Tagesziel wird bei der nächsten Rechnung festgelegt.
  void speichern(String datum) {
    _termin = PruefungsTermin(datum: datum);
    _prefs?.setString(schluessel, _termin!.schreiben());
    notifyListeners();
  }

  void entfernen() {
    _termin = null;
    _prefs?.remove(schluessel);
    notifyListeners();
  }

  /// Der Plan für heute (ohne Termin `null`). Legt das Tagesziel einmal je Tag
  /// fest und speichert es – ohne Listener zu benachrichtigen, damit das
  /// Rechnen auch aus `build` heraus erlaubt ist.
  PlanStand? rechnen({int? heute}) {
    final t = _termin;
    if (t == null) return null;
    final r = planRechnen(t, planEingabeAusLernstand(heute: heute));
    if (!identical(r.termin, t)) {
      _termin = r.termin;
      _prefs?.setString(schluessel, r.termin.schreiben());
    }
    return r.stand;
  }

  /// Neu anzeigen (neuer Tag, geänderter Lernstand).
  void aktualisieren() => notifyListeners();
}
