/// Antworten der Datenbankfunktionen (docs/supabase-rangliste.sql,
/// supabase-gruppen.sql, supabase-profile.sql) als Dart-Objekte. Gelesen wird
/// nachsichtig wie im Web (`x|0`): Fehlendes zählt 0 bzw. null.
library;

int ganz(Object? v) => v is num ? v.toInt() : (v is String ? int.tryParse(v) ?? 0 : 0);

int? ganzOderNull(Object? v) => v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);

String text(Object? v) => v == null ? '' : '$v';

Map<String, dynamic>? objekt(Object? v) => v is Map ? Map<String, dynamic>.from(v) : null;

List<Map<String, dynamic>> objekte(Object? v) =>
    v is List ? [for (final e in v) if (e is Map) Map<String, dynamic>.from(e)] : const [];

DateTime? zeitpunkt(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

/// Zeile der Wochenrangliste – Top 10, Gruppe oder Freunde.
class WochenEintrag {
  final int platz;
  final String name;
  final int antworten;
  final int reife;
  final int serie;
  final bool ich;
  // Prüfungswerte (nur in der Gruppe)
  final int pruefN;
  final int pruefOk;
  final int? pruefSchnitt;
  final int? chance;

  const WochenEintrag({
    required this.platz,
    required this.name,
    required this.antworten,
    required this.reife,
    this.serie = 0,
    this.ich = false,
    this.pruefN = 0,
    this.pruefOk = 0,
    this.pruefSchnitt,
    this.chance,
  });

  factory WochenEintrag.aus(Map<String, dynamic> j) => WochenEintrag(
        platz: ganz(j['platz']),
        name: text(j['name']),
        antworten: ganz(j['antworten']),
        reife: ganz(j['reife']),
        serie: ganz(j['serie']),
        ich: j['ich'] == true,
        pruefN: ganz(j['pruef_n']),
        pruefOk: ganz(j['pruef_ok']),
        pruefSchnitt: ganzOderNull(j['pruef_schnitt']),
        chance: ganzOderNull(j['chance']),
      );

  WochenEintrag mitPlatz(int p) => WochenEintrag(
      platz: p,
      name: name,
      antworten: antworten,
      reife: reife,
      serie: serie,
      ich: ich,
      pruefN: pruefN,
      pruefOk: pruefOk,
      pruefSchnitt: pruefSchnitt,
      chance: chance);

  static List<WochenEintrag> liste(Object? v) => [for (final j in objekte(v)) WochenEintrag.aus(j)];
}

/// `rangliste_stand(p_woche)`.
class RanglisteStand {
  final bool dabei;
  final String? name;
  final int teilnehmende;
  final int reifeVor;
  final int wocheTeilnehmende;
  final int? meinPlatz;
  final int? meineAntworten;
  final List<WochenEintrag> liste;

  const RanglisteStand({
    required this.dabei,
    this.name,
    this.teilnehmende = 0,
    this.reifeVor = 0,
    this.wocheTeilnehmende = 0,
    this.meinPlatz,
    this.meineAntworten,
    this.liste = const [],
  });

  factory RanglisteStand.aus(Object? v) {
    final j = objekt(v) ?? const <String, dynamic>{};
    final name = j['name'];
    return RanglisteStand(
      dabei: j['dabei'] == true,
      name: name is String && name.isNotEmpty ? name : null,
      teilnehmende: ganz(j['teilnehmende']),
      reifeVor: ganz(j['reife_vor']),
      wocheTeilnehmende: ganz(j['woche_teilnehmende']),
      meinPlatz: ganzOderNull(j['mein_platz']),
      meineAntworten: ganzOderNull(j['meine_antworten']),
      liste: WochenEintrag.liste(j['liste']),
    );
  }
}

/// Eintrag aus `gruppen_meine()`.
class Gruppe {
  final String id;
  final String code;
  final String name;
  final int mitglieder;
  final bool leitung;
  const Gruppe({required this.id, required this.code, required this.name, this.mitglieder = 0, this.leitung = false});

  static List<Gruppe> liste(Object? v) => [
        for (final j in objekte(v))
          if (j['id'] != null)
            Gruppe(
              id: text(j['id']),
              code: text(j['code']),
              name: text(j['name']),
              mitglieder: ganz(j['mitglieder']),
              leitung: j['leitung'] == true,
            ),
      ];
}

/// `gruppe_stand(p_gruppe, p_woche)` – null, wenn man nicht Mitglied ist.
class GruppenStand {
  final String id;
  final String name;
  final String code;
  final bool leitung;
  final int mitglieder;
  final List<WochenEintrag> liste;
  const GruppenStand({
    required this.id,
    required this.name,
    required this.code,
    this.leitung = false,
    this.mitglieder = 0,
    this.liste = const [],
  });

  static GruppenStand? aus(Object? v) {
    final j = objekt(v);
    if (j == null) return null;
    return GruppenStand(
      id: text(j['id']),
      name: text(j['name']),
      code: text(j['code']),
      leitung: j['leitung'] == true,
      mitglieder: ganz(j['mitglieder']),
      liste: WochenEintrag.liste(j['liste']),
    );
  }
}

/// Zeile der Prüfungsrangliste (Server oder lokal sortiert).
class PruefEintrag {
  final int platz;
  final String name;
  final int n;
  final int ok;
  final int? schnitt;
  final int? chance;
  final bool ich;
  const PruefEintrag({
    this.platz = 0,
    required this.name,
    required this.n,
    required this.ok,
    this.schnitt,
    this.chance,
    this.ich = false,
  });

  factory PruefEintrag.aus(Map<String, dynamic> j) => PruefEintrag(
        platz: ganz(j['platz']),
        name: text(j['name']),
        n: ganz(j['n']),
        ok: ganz(j['ok']),
        schnitt: ganzOderNull(j['schnitt']),
        chance: ganzOderNull(j['chance']),
        ich: j['ich'] == true,
      );

  PruefEintrag mitPlatz(int p) =>
      PruefEintrag(platz: p, name: name, n: n, ok: ok, schnitt: schnitt, chance: chance, ich: ich);
}

/// `rangliste_pruefungen()`.
class PruefRangliste {
  final int teilnehmende;
  final PruefEintrag? ich; // eigener Stand mit Platz, ohne Namen
  final List<PruefEintrag> liste;
  const PruefRangliste({this.teilnehmende = 0, this.ich, this.liste = const []});

  factory PruefRangliste.aus(Object? v) {
    final j = objekt(v) ?? const <String, dynamic>{};
    final ich = objekt(j['ich']);
    return PruefRangliste(
      teilnehmende: ganz(j['teilnehmende']),
      ich: ich == null ? null : PruefEintrag.aus({...ich, 'ich': true}),
      liste: [for (final e in objekte(j['liste'])) PruefEintrag.aus(e)],
    );
  }
}

/// Öffentliche Karte einer Person (`profil_karte`): Freunde, Anfragen, Suche.
class ProfilKarte {
  final String pid;
  final String name;
  final int reife;
  final int serie;
  final int antworten;
  final int pruefN;
  final int pruefOk;
  final int? pruefSchnitt;
  final int? chance;

  /// 'ich', 'freund', 'angefragt' (eigene Anfrage), 'anfrage' (an mich), null.
  String? bez;

  ProfilKarte({
    required this.pid,
    required this.name,
    this.reife = 0,
    this.serie = 0,
    this.antworten = 0,
    this.pruefN = 0,
    this.pruefOk = 0,
    this.pruefSchnitt,
    this.chance,
    this.bez,
  });

  factory ProfilKarte.aus(Map<String, dynamic> j) => ProfilKarte(
        pid: text(j['pid']),
        name: text(j['name']),
        reife: ganz(j['reife']),
        serie: ganz(j['serie']),
        antworten: ganz(j['antworten']),
        pruefN: ganz(j['pruef_n']),
        pruefOk: ganz(j['pruef_ok']),
        pruefSchnitt: ganzOderNull(j['pruef_schnitt']),
        chance: ganzOderNull(j['chance']),
        bez: j['bez'] is String ? j['bez'] as String : null,
      );

  static List<ProfilKarte> liste(Object? v) => [for (final j in objekte(v)) ProfilKarte.aus(j)];
}

/// Eigenes Profil in `freunde_stand`.
class EigenesProfil {
  final String pid;
  final String name;
  String sichtbarkeit; // 'freunde' | 'alle'
  EigenesProfil({required this.pid, required this.name, required this.sichtbarkeit});
}

/// `freunde_stand(p_woche)` – null, wenn man nicht in der Rangliste ist.
class FreundeStand {
  final EigenesProfil? ich;
  final List<ProfilKarte> anfragen;
  final List<ProfilKarte> gesendet;
  final List<ProfilKarte> freunde;
  const FreundeStand({this.ich, this.anfragen = const [], this.gesendet = const [], this.freunde = const []});

  static FreundeStand? aus(Object? v) {
    final j = objekt(v);
    if (j == null) return null;
    final ich = objekt(j['ich']);
    return FreundeStand(
      ich: ich == null
          ? null
          : EigenesProfil(
              pid: text(ich['pid']),
              name: text(ich['name']),
              sichtbarkeit: ich['sichtbarkeit'] == 'alle' ? 'alle' : 'freunde',
            ),
      anfragen: ProfilKarte.liste(j['anfragen']),
      gesendet: ProfilKarte.liste(j['gesendet']),
      freunde: ProfilKarte.liste(j['freunde']),
    );
  }
}

/// `profil_ansehen(p_pid, p_name, p_woche)`. `seit`, `gemeistert`, `details`
/// und `detailsAm` gibt es nur, wenn [sichtbar].
class Profil {
  final String pid;
  final String name;
  final int reife;
  final int serie;
  final int antworten;
  final int pruefN;
  final int pruefOk;
  final int? pruefSchnitt;
  final int? chance;
  final String? bez;
  final String sichtbarkeit;
  final bool sichtbar;
  final bool adminSicht;
  final DateTime? seit;
  final int? gemeistert;
  final Map<String, dynamic> details;
  final DateTime? detailsAm;

  /// Profil gibt es nicht (mehr) oder es ließ sich nicht laden.
  final bool fehler;

  const Profil({
    this.pid = '',
    this.name = '',
    this.reife = 0,
    this.serie = 0,
    this.antworten = 0,
    this.pruefN = 0,
    this.pruefOk = 0,
    this.pruefSchnitt,
    this.chance,
    this.bez,
    this.sichtbarkeit = 'freunde',
    this.sichtbar = false,
    this.adminSicht = false,
    this.seit,
    this.gemeistert,
    this.details = const {},
    this.detailsAm,
    this.fehler = false,
  });

  static const nichtGefunden = Profil(fehler: true);

  static Profil aus(Object? v) {
    final j = objekt(v);
    if (j == null || j['pid'] == null) return nichtGefunden;
    return Profil(
      pid: text(j['pid']),
      name: text(j['name']),
      reife: ganz(j['reife']),
      serie: ganz(j['serie']),
      antworten: ganz(j['antworten']),
      pruefN: ganz(j['pruef_n']),
      pruefOk: ganz(j['pruef_ok']),
      pruefSchnitt: ganzOderNull(j['pruef_schnitt']),
      chance: ganzOderNull(j['chance']),
      bez: j['bez'] is String ? j['bez'] as String : null,
      sichtbarkeit: j['sichtbarkeit'] == 'alle' ? 'alle' : 'freunde',
      sichtbar: j['sichtbar'] == true,
      adminSicht: j['admin_sicht'] == true,
      seit: zeitpunkt(j['seit']),
      gemeistert: ganzOderNull(j['gemeistert']),
      details: objekt(j['details']) ?? const {},
      detailsAm: zeitpunkt(j['details_am']),
    );
  }
}
