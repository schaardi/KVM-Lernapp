import 'dart:convert';
import '../constants.dart';
import '../services/data_service.dart';
import '../services/lerntage_service.dart';
import '../services/progress_service.dart';
import '../services/pruef_stat.dart';
import '../services/selection_service.dart';
import '../util/format.dart';
import 'modelle.dart';

/// Rechnungen und Texte des Vergleichs ohne Netz – wie im Web (`isoWoche`,
/// `vgWerte`, `profilDetails`, `pruefIch`, `pruefSortiert` …).

// ---------------------------------------------------------------------------
// Woche

/// ISO-Kalenderwoche „2026-W39“: die Rangliste beginnt jeden Montag neu.
String isoWoche(DateTime t) {
  // UTC-Daten: keine Sommerzeit-Sprünge in der Tagesdifferenz
  final d = DateTime.utc(t.year, t.month, t.day).add(Duration(days: 3 - ((t.weekday + 6) % 7))); // Donnerstag
  final w1 = DateTime.utc(d.year, 1, 4);
  final kw = 1 + ((d.difference(w1).inDays - 3 + ((w1.weekday + 6) % 7)) / 7).round();
  return '${d.year}-W${kw.toString().padLeft(2, '0')}';
}

/// Nummer der Woche („2026-W09“ → 9).
int kwNummer(String woche) => int.tryParse(woche.split('-W').last) ?? 0;

/// „KW 39“ mit geschütztem Leerzeichen – bricht nicht zwischen KW und Zahl um.
String kwText(int kw) => 'KW $kw';

// ---------------------------------------------------------------------------
// Spitzname

final RegExp kSpitznameMuster = RegExp(r'^[A-Za-zÄÖÜäöüß0-9 _.-]{3,20}$');

/// Eingabe → Spitzname: außen gekürzt, Leerraum zusammengezogen.
String spitznameAus(String eingabe) => eingabe.trim().replaceAll(RegExp(r'\s+'), ' ');

// ---------------------------------------------------------------------------
// Werte melden

/// Parameter für `rangliste_melden` (Web `vgWerte`): Prüfungsreife wie im
/// Lernstand-Ring, gemeisterte Fragen (Box ≥ 3), Antworten dieser Woche aus
/// den Lerntagen und die Tage in Folge.
Map<String, dynamic> ranglisteWerte(String name, {DateTime? jetzt}) {
  final prog = ProgressService.instance;
  var gemeistert = 0;
  for (final q in DataService.instance.questions) {
    final p = prog.get(q.id);
    if (p != null && p.box >= kMasterBox) gemeistert++;
  }
  return {
    'p_name': name,
    'p_reife': (prog.overallReife() * 100).round(),
    'p_gemeistert': gemeistert,
    'p_woche': isoWoche(jetzt ?? DateTime.now()),
    'p_antworten': LerntageService.instance.dieseWoche(),
    'p_serie': LerntageService.instance.serie(),
  };
}

/// Anteil 0..1 → ganze Prozent.
int? prozent(double? p) => p == null || p.isNaN ? null : (p * 100).round();

/// Parameter für `pruefungen_melden` (Web `pruefIch`). Null, solange keine
/// Prüfung gewertet ist – dann wird nichts gemeldet, damit ein noch leerer
/// Stand auf diesem Gerät die Werte vom Server nicht mit 0 überschreibt.
Map<String, dynamic>? pruefWerte(PruefStatistik st) {
  if (st.n <= 0) return null;
  return {'p_n': st.n, 'p_ok': st.ok, 'p_schnitt': st.schnitt, 'p_chance': prozent(st.haupt)};
}

/// Eigener Eintrag für die Prüfungsliste bei Freunden (lokale Werte).
PruefEintrag pruefIch(PruefStatistik st, String name) =>
    PruefEintrag(name: name, n: st.n, ok: st.ok, schnitt: st.schnitt, chance: prozent(st.haupt), ich: true);

// ---------------------------------------------------------------------------
// Prüfungsbereiche (FR-014)

const List<String> kBereicheBQ = ['RE', 'BW', 'MI', 'ZI', 'NT'];
const List<String> kBereicheHQ = ['FT', 'OK'];
const List<String> kBereiche = [...kBereicheBQ, ...kBereicheHQ];

/// Kurznamen wie im Web (`PB`), falls die Statistik einen Bereich nicht nennt.
const Map<String, String> kBereichKurz = {
  'RE': 'Recht',
  'BW': 'BWL',
  'MI': 'Methoden',
  'ZI': 'Zusammenarbeit',
  'NT': 'Naturwiss. & Technik',
  'FT': 'Fuhrpark',
  'OK': 'Organisation',
};

String bereichKurz(PruefStatistik st, String k) => st.bereiche[k]?.kurz ?? kBereichKurz[k] ?? k;

/// Zählt der handlungsspezifische Teil mit? Nur mit aktiver Fachrichtung
/// Kraftverkehr (Web `peMitHQ`).
bool mitHandlungsspezifisch() =>
    SelectionService.instance.isFachActive(5) && (DataService.instance.fachCounts()[5] ?? 0) > 0;

/// Bereiche eines Teils ohne Bestehenschance (noch nicht gewertet).
List<String> fehlendeBereiche(PruefStatistik st, List<String> teil) =>
    [for (final k in teil) if (st.bereiche[k]?.chance == null) k];

/// Teil des Hauptwerts wie im Web: 'g' beide Teile, 'bq' Basisqualifikationen,
/// 'hq' handlungsspezifischer Teil.
String? hauptTeil(PruefStatistik st, bool mitHQ) {
  if (st.haupt == null) return null;
  if (st.gesamt != null) return mitHQ ? 'g' : 'bq';
  if (st.bq != null) return 'bq';
  if (st.hq != null) return 'hq';
  return mitHQ ? 'g' : 'bq';
}

const Map<String, String> kTeilName = {
  'g': 'beide Teile',
  'bq': 'Basisqualifikationen',
  'hq': 'handlungsspezifischer Teil',
};

/// Kennzahl-Kachel: großer Wert und Text darunter.
typedef Kennzahl = ({String wert, String text});

/// Kennzahlen oben im Prüfungsmodus (Web `vgPruefTopHTML`): eigener Hauptwert
/// samt Teil bzw. gewertete Bereiche – und der eigene Platz.
(Kennzahl, Kennzahl) pruefKennzahlen(PruefStatistik st, bool mitHQ, PruefRangliste? ps) {
  Kennzahl k1;
  final teil = hauptTeil(st, mitHQ);
  if (teil != null) {
    var t = 'Bestehenschance · ${kTeilName[teil]}';
    if (teil != 'g' && mitHQ) {
      final fehlt = fehlendeBereiche(st, teil == 'bq' ? kBereicheHQ : kBereicheBQ);
      t += ' – für beide Teile fehlt noch: ${fehlt.map((k) => bereichKurz(st, k)).join(', ')}';
    }
    k1 = (wert: chanceText(prozent(st.haupt)), text: t);
  } else if (st.n > 0) {
    final fehlt = [...fehlendeBereiche(st, kBereicheBQ), if (mitHQ) ...fehlendeBereiche(st, kBereicheHQ)];
    final alle = kBereicheBQ.length + (mitHQ ? kBereicheHQ.length : 0);
    k1 = (
      wert: '${alle - fehlt.length}/$alle',
      text: 'Prüfungsbereiche gewertet – für die Bestehenschance fehlt noch: '
          '${fehlt.map((k) => bereichKurz(st, k)).join(', ')}',
    );
  } else {
    k1 = (
      wert: '–',
      text: 'Noch keine Prüfung gewertet. Löse eine Original-Prüfung und gib dir Punkte – '
          'dann rechnet die App deine Bestehenschance.',
    );
  }
  final ich = ps?.ich;
  final Kennzahl k2 = ich != null && ich.platz > 0
      ? (
          wert: '${ich.platz}.',
          text: 'Platz von ${fmtN(ps!.teilnehmende)} · ${st.ok} von ${st.n} '
              '${st.n == 1 ? 'Prüfung' : 'Prüfungen'} bestanden',
        )
      : (
          wert: '–',
          text: st.n > 0
              ? 'Dein Stand wird gemeldet – gleich stehst du in der Liste.'
              : 'Ab der ersten gewerteten Prüfung stehst du in der Prüfungsrangliste.',
        );
  return (k1, k2);
}

// ---------------------------------------------------------------------------
// Profil-Details (FR-012, FR-014 6)

/// Prüfungen unter Echtbedingungen aus den gespeicherten Durchgängen
/// (`kvm_pruef_erg`, FR-014 2): Anzahl und bestes Ergebnis in %.
({int n, int best})? echtAusErgebnissen(String? roh) {
  if (roh == null || roh.isEmpty) return null;
  try {
    final v = json.decode(roh);
    if (v is! List) return null;
    var n = 0, best = 0;
    for (final e in v) {
      if (e is! Map || !(e['echt'] == 1 || e['echt'] == true)) continue;
      n++;
      final max = e['max'], pkt = e['pkt'];
      if (max is num && max > 0) {
        final p = ((pkt is num ? pkt : 0) / max * 100).round();
        if (p > best) best = p;
      }
    }
    return n > 0 ? (n: n, best: best) : null;
  } catch (_) {
    return null;
  }
}

/// Lernstand im Detail fürs Profil (Web `profilDetails`): Reife je Fach,
/// Aktivität der letzten 14 Tage, Lerntage, Prüfungen unter Echtbedingungen
/// und – sobald eine Prüfung gewertet ist – die Ergebnisse je Prüfungsbereich
/// (`pr`) und die Bestehenschance (`pc`). Die Datenbank säubert alles noch einmal.
Map<String, dynamic> profilDetails({
  required PruefStatistik st,
  required ({int n, int best})? echt,
  required bool mitHQ,
}) {
  final data = DataService.instance;
  final prog = ProgressService.instance;
  final f = <String, dynamic>{};
  for (final x in data.activeFacher()) {
    final qs = data.forFach(x);
    var m = 0, g = 0;
    for (final q in qs) {
      final p = prog.get(q.id);
      if (p != null && p.seen > 0) {
        g++;
        if (p.box >= kMasterBox) m++;
      }
    }
    f['$x'] = {'r': (prog.fachReife(x) * 100).round(), 'm': m, 'g': g, 'n': qs.length};
  }
  final tage = LerntageService.instance;
  final o = <String, dynamic>{
    'f': f,
    't14': [for (final t in tage.letzte(14)) t.anzahl],
    'tage': tage.lerntage(),
  };
  if (echt != null && echt.n > 0) o['echt'] = {'n': echt.n, 'best': echt.best};
  if (st.n > 0) {
    o['pr'] = {
      for (final k in kBereiche)
        if ((st.bereiche[k]?.n ?? 0) > 0)
          k: {
            'n': st.bereiche[k]!.n,
            'ok': st.bereiche[k]!.ok,
            's': st.bereiche[k]!.schnitt,
            'c': prozent(st.bereiche[k]!.chance),
          },
    };
    // Web: gesamt ist ohne Fachrichtung die Chance der Basisqualifikationen.
    o['pc'] = {'bq': prozent(st.bq), 'hq': prozent(st.hq), 'g': prozent(st.gesamt ?? (mitHQ ? null : st.bq))};
  }
  return o;
}

/// Die 14 Tage aus den Profil-Details, ab `details_am` bis heute nachgerückt;
/// fehlende Tage zählen 0 (Web `lernstandHTML`).
List<({int tag, int anzahl})> aktivitaetAus(Object? t14, DateTime? am, {DateTime? jetzt}) {
  var t = t14 is List ? [for (final v in t14) ganz(v)] : <int>[];
  if (t.length > 14) t = t.sublist(t.length - 14);
  if (t.isEmpty) return const [];
  final heute = LerntageService.heute(jetzt);
  final weg = am == null ? 0 : (heute - LerntageService.heute(am.toLocal())).clamp(0, t.length);
  t = [...t.sublist(weg), ...List.filled(weg, 0)];
  final n = t.length;
  return [for (var i = 0; i < n; i++) (tag: heute - (n - 1 - i), anzahl: t[i])];
}

// ---------------------------------------------------------------------------
// Sortierung (Freunde und Gruppen liegen ganz vor – hier wird nur umsortiert)

int _nameVergleich(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

/// Prüfungsliste: bestanden, dann Schnitt (ohne Schnitt hinten), dann Name.
/// Gleicher Stand (bestanden und Schnitt) ergibt denselben Platz.
List<PruefEintrag> pruefSortiert(Iterable<PruefEintrag> l) {
  final s = [...l]..sort((a, b) {
      final d = b.ok.compareTo(a.ok);
      if (d != 0) return d;
      final e = (b.schnitt ?? -1).compareTo(a.schnitt ?? -1);
      if (e != 0) return e;
      return _nameVergleich(a.name, b.name);
    });
  var platz = 0;
  String? vor;
  return [
    for (var i = 0; i < s.length; i++)
      () {
        final k = '${s[i].ok}/${s[i].schnitt ?? -1}';
        if (k != vor) {
          platz = i + 1;
          vor = k;
        }
        return s[i].mitPlatz(platz);
      }(),
  ];
}

/// Wochenliste der Freunde: Antworten, dann Name; gleiche Antwortzahl ergibt
/// denselben Platz.
List<WochenEintrag> wocheSortiert(Iterable<WochenEintrag> l) {
  final s = [...l]..sort((a, b) {
      final d = b.antworten.compareTo(a.antworten);
      return d != 0 ? d : _nameVergleich(a.name, b.name);
    });
  var platz = 0;
  int? vor;
  return [
    for (var i = 0; i < s.length; i++)
      () {
        if (s[i].antworten != vor) {
          platz = i + 1;
          vor = s[i].antworten;
        }
        return s[i].mitPlatz(platz);
      }(),
  ];
}

// ---------------------------------------------------------------------------
// Anzeige

/// Bestehenschance in ganzen Prozent als Text (Web `vgChance`).
String chanceText(int? c) => c == null ? '–' : (c >= 100 ? '> 99 %' : (c <= 0 ? '< 1 %' : '$c %'));

/// Zwei Buchstaben: Anfänge der ersten beiden Wörter, sonst die ersten zwei Zeichen.
String kuerzel(String name) {
  final s = name.trim().isEmpty ? '?' : name.trim();
  final w = s.split(RegExp(r'[\s_.@-]+')).where((x) => x.isNotEmpty).toList();
  final ini = w.length > 1 ? w[0][0] + w[1][0] : (s.length > 2 ? s.substring(0, 2) : s);
  return (ini.isEmpty ? '?' : ini).toUpperCase();
}

/// Farbton 0..359 aus dem Namen (`h = (h·31 + Zeichencode) mod 360`).
int farbton(String name) {
  final s = name.trim().isEmpty ? '?' : name.trim();
  var h = 0;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) % 360;
  }
  return h;
}

const List<String> _monate = [
  'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
  'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
];

/// „September 2026“.
String monatJahr(DateTime d) => '${_monate[d.month - 1]} ${d.year}';

/// Zeile unter dem Namen: „64 % prüfungsreif · 312 Antw. diese Woche · 5 Tage in Folge“.
String zahlenText(ProfilKarte k) =>
    '${k.reife} % prüfungsreif · ${fmtN(k.antworten)} Antw. diese Woche'
    '${k.serie > 0 ? ' · ${k.serie} Tage in Folge' : ''}';

// ---------------------------------------------------------------------------
// Texte (wortgleich zum Web)

const String kTextNichtGeklappt = 'Das hat nicht geklappt – bitte später noch einmal.';
const String kTextNameRegel = '3–20 Zeichen: Buchstaben, Ziffern, Leerzeichen, _ . -';

/// Fehler beim Beitreten oder beim Ändern des Spitznamens.
String beitrittsFehler(String? code, {bool netz = false}) {
  if (netz) return 'Keine Verbindung – bitte später noch einmal.';
  return switch (code) {
    '23505' => 'Dieser Spitzname ist schon vergeben.',
    '23514' => kTextNameRegel,
    'P0006' => 'Dein Konto ist für Rangliste, Gruppen und Freunde gesperrt.',
    _ => kTextNichtGeklappt,
  };
}

const Map<String, String> kGruppenFehler = {
  'P0002': 'Keine Gruppe mit diesem Code gefunden.',
  'P0003': 'Tritt erst der Rangliste bei.',
  'P0004': 'Du bist schon in 5 Gruppen – verlasse zuerst eine.',
  'P0005': 'Die Gruppe ist voll (200 Mitglieder).',
  '23514': 'Der Gruppenname braucht 3–40 Zeichen.',
};

const Map<String, String> kLeuteFehler = {
  'P0002': 'Diese Person ist nicht mehr dabei.',
  'P0003': 'Tritt erst der Rangliste bei.',
  'P0004': 'Du hast gerade sehr viele offene Anfragen – warte, bis einige beantwortet sind.',
  '22023': 'Das geht leider nicht.',
};

const String kPruefFussnote =
    'Bestanden: je Prüfung der erste vollständig bewertete Durchgang. Chance: Bestehenschance '
    'für beide Teile, sonst für den Teil, in dem jeder Bereich gewertet ist.';

// ---------------------------------------------------------------------------
// Einladen (in der App ohne Deep Link: Text mit Code und Web-Link)

const String _webAdresse = String.fromEnvironment('WEB_ADRESSE');

/// Adresse der Web-App für den Einladungslink (per `--dart-define=WEB_ADRESSE`
/// überschreibbar; ein leerer Wert fällt auf die Vorgabe zurück).
String get webAdresse => _webAdresse.isNotEmpty ? _webAdresse : 'https://schaardi.github.io/KVM-Lernapp/';

/// Einladung in eine Lerngruppe: Text und Link wie im Web.
({String text, String link}) einladungFuer(GruppenStand g) => (
      text: 'Lerngruppe „${g.name}“ im Meister-Trainer – lern mit! Code: ${g.code}',
      link: '$webAdresse#gruppe=${g.code}',
    );
