import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../services/progress_service.dart';
import '../services/pruef_stat.dart';
import 'modelle.dart';
import 'quelle.dart';
import 'werte.dart';

/// Rangliste „Diese Woche“ oder „Prüfungen“ (FR-014 7).
enum RanglistenModus { woche, pruef }

/// Zustand des Dialogs „Lernende“ (Web `lt`).
class LernendeZustand {
  String tab = 'freunde'; // 'freunde' | 'alle' | 'profil'
  String suche = '';
  int seite = 0;
  List<ProfilKarte>? liste;
  int gesamt = 0;
  bool laedt = false;
  Profil? profil;
  bool profilLaedt = false;
  String meld = '';
  bool meldOk = false;

  /// Personen (pid), für die gerade eine Freundschaftsaktion läuft.
  final Set<String> laeuft = {};

  void zuruecksetzen() {
    laeuft.clear();
    tab = 'freunde';
    suche = '';
    seite = 0;
    liste = null;
    gesamt = 0;
    laedt = false;
    profil = null;
    profilLaedt = false;
    meld = '';
    meldOk = false;
  }
}

/// Vergleich mit anderen (FR-004, FR-010, FR-012, FR-014 7): Wochenrangliste,
/// Lerngruppen, Freunde und Profile über Supabase – Verhalten wie im Web
/// (`vgLaden`, `grLaden`, `ltStandLaden`, `pruefStandLaden` …).
///
/// Fehlt eine Datenbankfunktion (SQL-Skript nicht eingespielt), bleibt die
/// Teilfunktion still verborgen. Die Datenquelle ist austauschbar ([quelle]),
/// damit Tests und Screenshots ohne Supabase laufen.
class VergleichDienst extends ChangeNotifier {
  VergleichDienst._();
  static final VergleichDienst instance = VergleichDienst._();

  CloudQuelle quelle = const SupabaseQuelle();

  // ---- Zustand (Web `vg`) ----
  /// null = noch nicht geladen, true = Rangliste eingerichtet, false = nicht.
  bool? verfuegbar;
  RanglisteStand? stand;

  /// Spitzname ändern (Formular statt Liste).
  bool bearbeiten = false;

  bool? gruppenOk;
  List<Gruppe> gruppen = const [];

  /// Reiter: null = Alle, 'freunde', sonst die ID einer Gruppe.
  String? ansicht;
  GruppenStand? gstand;

  /// Formular „+ Gruppe“ offen.
  bool gform = false;

  bool? leuteOk;
  FreundeStand? fstand;

  RanglistenModus modus = RanglistenModus.woche;
  PruefRangliste? pstand;
  bool? pruefOk;

  final LernendeZustand lt = LernendeZustand();

  // ---- intern ----
  static const _pause = Duration(seconds: 30); // höchstens alle 30 s laden
  bool _gestartet = false;
  bool _laedt = false;
  bool _nochmal = false;
  bool _meldenNachLaden = false;
  bool _profilGemeldet = false;
  bool _pruefGemeldet = false;
  DateTime _zuletzt = DateTime(2000);
  int _gen = 0; // steigt bei Kontowechsel – späte Antworten verfallen
  int _profilAnfrage = 0;
  String? _konto;
  Timer? _meldeT;
  Timer? _pruefT;
  SharedPreferences? _prefs;

  bool get dabei => stand?.dabei == true;
  bool get pruefModus => modus == RanglistenModus.pruef && pruefOk == true;
  bool get anfragenOffen => leuteOk == true && (fstand?.anfragen.isNotEmpty ?? false);
  bool get _gruppeGewaehlt => ansicht != null && ansicht != 'freunde';
  String get woche => isoWoche(DateTime.now());
  int get kw => kwNummer(woche);

  // -------------------------------------------------------------------------
  // Start und Anmeldung

  /// Beim App-Start (aus `initCloud`): Stand laden und Werte melden, danach
  /// bei jeder Anmeldung, nach Antworten, nach neuen Prüfungsergebnissen und
  /// beim Öffnen der Seiten. Blockiert den Start nicht.
  Future<void> starten() async {
    if (_gestartet || !Config.authEnabled || !AuthService.instance.ready) return;
    _gestartet = true;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {}
    // Nach jeder gespeicherten Antwort melden – dort, wo auch der Sync anstößt.
    final vorher = ProgressService.instance.onChanged;
    ProgressService.instance.onChanged = () {
      vorher?.call();
      meldenSpaeter();
    };
    pruefStand.addListener(_pruefGeaendert);
    AppState.instance.addListener(_appGeaendert);
    // Anmelden, Abmelden, Kontowechsel (läuft so lange wie die App).
    try {
      AuthService.instance.onAuthChange.listen((_) => kontoPruefen(), onError: (_) {});
    } catch (_) {}
    kontoPruefen();
  }

  /// Anmeldung oder Kontowechsel: alles zurücksetzen und frisch laden.
  void kontoPruefen() {
    final k = quelle.bereit ? quelle.konto : null;
    if (k == _konto) return;
    _konto = k;
    _zuruecksetzen();
    if (k == null) {
      _mitteilen();
      return;
    }
    _meldenNachLaden = true;
    _imHintergrund(() => laden(erzwingen: true));
  }

  /// Läuft ohne Warten; ein unerwarteter Fehler darf die App nicht stören.
  void _imHintergrund(Future<void> Function() arbeit) {
    unawaited(Future<void>.sync(arbeit).catchError((Object _) {}));
  }

  void _zuruecksetzen() {
    _gen++;
    _meldeT?.cancel();
    _pruefT?.cancel();
    _laedt = false;
    _nochmal = false;
    _meldenNachLaden = false;
    _zuletzt = DateTime(2000);
    verfuegbar = null;
    stand = null;
    bearbeiten = false;
    gruppenOk = null;
    gruppen = const [];
    ansicht = null;
    gstand = null;
    gform = false;
    leuteOk = null;
    fstand = null;
    _profilGemeldet = false;
    modus = RanglistenModus.woche;
    pstand = null;
    pruefOk = null;
    _pruefGemeldet = false;
    lt.zuruecksetzen();
  }

  /// Für Tests: Anfangszustand mit anderer Datenquelle.
  @visibleForTesting
  void testStart(CloudQuelle q) {
    quelle = q;
    _konto = q.bereit ? q.konto : null;
    _zuruecksetzen();
  }

  /// Seite gewechselt oder Runde beendet (Web `renderHomeExtras`, `seiteZeigen`):
  /// neu laden, höchstens alle 30 s.
  void _appGeaendert() {
    if (!quelle.bereit) return;
    scheduleMicrotask(() => _imHintergrund(laden));
  }

  void _mitteilen() {
    final app = AppState.instance;
    app.vergleichVerfuegbar.value = verfuegbar;
    app.vergleichHinweis.value = verfuegbar == true && anfragenOffen;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Laden

  /// Stand der Rangliste, danach Gruppen, Freunde und Prüfungsrangliste.
  Future<void> laden({bool erzwingen = false}) async {
    if (!quelle.bereit) return;
    if (_laedt) {
      if (erzwingen) _nochmal = true;
      return;
    }
    if (!erzwingen && verfuegbar != null && DateTime.now().difference(_zuletzt) < _pause) return;
    _laedt = true;
    final gen = _gen;
    try {
      final r = await quelle.rpc('rangliste_stand', {'p_woche': woche});
      if (gen != _gen) return;
      stand = RanglisteStand.aus(r);
      verfuegbar = true;
    } on CloudFehler {
      if (gen != _gen) return;
      verfuegbar = false;
    } finally {
      if (gen == _gen) {
        _laedt = false;
        _zuletzt = DateTime.now();
      }
    }
    _mitteilen();
    if (verfuegbar == true) {
      if (_meldenNachLaden) {
        _meldenNachLaden = false;
        meldenSpaeter();
      }
      await Future.wait([_gruppenLaden(gen), _freundeLaden(gen), _pruefStandLaden(gen)]);
      if (gen != _gen) return;
      _mitteilen();
    }
    if (_nochmal && gen == _gen) {
      _nochmal = false;
      await laden(erzwingen: true);
    }
  }

  Future<void> _gruppenLaden(int gen) async {
    if (!quelle.bereit || !dabei) return;
    try {
      final r = await quelle.rpc('gruppen_meine');
      if (gen != _gen) return;
      gruppenOk = true;
      gruppen = Gruppe.liste(r);
      if (_gruppeGewaehlt && !gruppen.any((g) => g.id == ansicht)) {
        ansicht = null;
        gstand = null;
      }
      if (_gruppeGewaehlt) await _gruppeStandLaden(gen);
    } on CloudFehler {
      if (gen != _gen) return;
      gruppenOk = false;
      gruppen = const [];
      if (_gruppeGewaehlt) {
        ansicht = null;
        gstand = null;
      }
    }
  }

  Future<void> _gruppeStandLaden(int gen) async {
    final id = ansicht;
    if (id == null || id == 'freunde') return;
    try {
      final r = await quelle.rpc('gruppe_stand', {'p_gruppe': id, 'p_woche': woche});
      if (gen != _gen || ansicht != id) return;
      gstand = GruppenStand.aus(r);
    } on CloudFehler {
      if (gen != _gen || ansicht != id) return;
      gstand = null;
    }
  }

  Future<void> _freundeLaden(int gen) async {
    if (!quelle.bereit) return;
    try {
      final r = await quelle.rpc('freunde_stand', {'p_woche': woche});
      if (gen != _gen) return;
      leuteOk = true;
      fstand = FreundeStand.aus(r);
      if (fstand != null && !_profilGemeldet) {
        _profilGemeldet = true;
        _profilMelden();
      }
    } on CloudFehler catch (e) {
      if (gen != _gen) return;
      leuteOk = false;
      if (!e.netz) fstand = null;
      if (ansicht == 'freunde') ansicht = null;
    }
  }

  /// Prüfungsrangliste; beim ersten Laden je Sitzung vorher den eigenen Stand melden.
  Future<void> _pruefStandLaden(int gen) async {
    if (!quelle.bereit || !dabei || pruefOk == false) return;
    if (!_pruefGemeldet) {
      _pruefGemeldet = true;
      await _pruefWerteMelden();
      if (gen != _gen || pruefOk == false) return;
    }
    try {
      final r = await quelle.rpc('rangliste_pruefungen');
      if (gen != _gen) return;
      pruefOk = true;
      pstand = PruefRangliste.aus(r);
    } on CloudFehler catch (e) {
      if (gen != _gen || e.netz) return; // ohne Verbindung bleibt der Stand
      pruefOk = false;
      pstand = null;
      modus = RanglistenModus.woche;
    }
  }

  // -------------------------------------------------------------------------
  // Melden

  PruefStatistik _statistik() {
    try {
      return pruefStatistik();
    } catch (_) {
      return PruefStatistik.leer;
    }
  }

  /// Details fürs Profil aus dem aktuellen Lernstand.
  Map<String, dynamic> details() => profilDetails(
        st: _statistik(),
        echt: echtAusErgebnissen(_prefs?.getString('kvm_pruef_erg')),
        mitHQ: mitHandlungsspezifisch(),
      );

  /// Entprellt 4 s nach jeder gespeicherten Antwort – nur, wenn man dabei ist.
  void meldenSpaeter() {
    if (!quelle.bereit || !dabei) return;
    _meldeT?.cancel();
    _meldeT = Timer(const Duration(seconds: 4), () => _imHintergrund(ranglisteMelden));
  }

  /// Eigene Werte an die Rangliste, danach das Profil.
  Future<void> ranglisteMelden() async {
    final name = stand?.name;
    if (!quelle.bereit || !dabei || name == null) return;
    final gen = _gen;
    try {
      await quelle.rpc('rangliste_melden', ranglisteWerte(name));
    } on CloudFehler {
      return;
    }
    if (gen != _gen) return;
    _zuletzt = DateTime(2000); // nächstes Laden holt den neuen Stand
    _profilMelden();
  }

  void _pruefGeaendert() {
    if (!quelle.bereit || !dabei) return;
    _pruefT?.cancel();
    _pruefT = Timer(const Duration(milliseconds: 1500), () {
      _imHintergrund(() async {
        await _pruefWerteMelden();
        _zuletzt = DateTime(2000);
      });
    });
  }

  /// Prüfungsergebnisse an die Rangliste (`pruefungen_melden`), danach das Profil.
  @visibleForTesting
  Future<void> pruefWerteMelden() => _pruefWerteMelden();

  Future<void> _pruefWerteMelden() async {
    if (!quelle.bereit || !dabei || pruefOk == false) return;
    final w = pruefWerte(_statistik());
    if (w == null) return;
    final gen = _gen;
    try {
      await quelle.rpc('pruefungen_melden', w);
    } on CloudFehler catch (e) {
      if (gen == _gen && e.fehlt) {
        pruefOk = false;
        modus = RanglistenModus.woche;
        _mitteilen();
      }
      return;
    }
    if (gen != _gen) return;
    _profilMelden();
  }

  void _profilMelden() {
    if (!quelle.bereit || leuteOk != true || !dabei) return;
    _imHintergrund(() => quelle.rpc('profil_melden', {'p_details': details()}));
  }

  // -------------------------------------------------------------------------
  // Beitreten, Spitzname, Austreten

  /// Beitreten bzw. Spitzname ändern. Gibt einen Fehlertext zurück oder null.
  Future<String?> spitznameSpeichern(String eingabe) async {
    final name = spitznameAus(eingabe);
    if (!kSpitznameMuster.hasMatch(name)) return kTextNameRegel;
    final gen = _gen;
    try {
      await quelle.rpc('rangliste_melden', ranglisteWerte(name));
    } on CloudFehler catch (e) {
      return beitrittsFehler(e.code, netz: e.netz);
    } catch (_) {
      return kTextNichtGeklappt;
    }
    if (gen != _gen) return null;
    bearbeiten = false;
    await laden(erzwingen: true);
    return null;
  }

  void bearbeitenStarten() {
    bearbeiten = true;
    _mitteilen();
  }

  void bearbeitenAbbrechen() {
    bearbeiten = false;
    _mitteilen();
  }

  /// Austreten löscht den Eintrag (samt Gruppen, Profil und Freundschaften).
  Future<bool> austreten() async {
    final gen = _gen;
    try {
      await quelle.rpc('rangliste_austreten');
    } on CloudFehler {
      return false;
    }
    if (gen != _gen) return true;
    ansicht = null;
    gstand = null;
    gform = false;
    fstand = null;
    modus = RanglistenModus.woche;
    pstand = null;
    _profilGemeldet = false;
    _pruefGemeldet = false;
    lt.zuruecksetzen();
    await laden(erzwingen: true);
    return true;
  }

  // -------------------------------------------------------------------------
  // Reiter, Umschalter

  /// Reiter wählen: null = Alle, 'freunde' oder eine Gruppe.
  Future<void> waehleAnsicht(String? id) async {
    gform = false;
    ansicht = id;
    gstand = null;
    _mitteilen();
    final gen = _gen;
    if (id == 'freunde') {
      await _freundeLaden(gen);
    } else if (id != null) {
      await _gruppeStandLaden(gen);
    }
    if (gen == _gen) _mitteilen();
  }

  void gformUmschalten() {
    gform = !gform;
    _mitteilen();
  }

  Future<void> waehleModus(RanglistenModus m) async {
    modus = m;
    _mitteilen();
    if (m == RanglistenModus.pruef && ansicht == null) {
      final gen = _gen;
      await _pruefStandLaden(gen);
      if (gen == _gen) _mitteilen();
    }
  }

  // -------------------------------------------------------------------------
  // Lerngruppen

  Future<String?> gruppeBeitreten(String eingabe) async {
    final code = eingabe.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (code.length != 6) return 'Der Code hat 6 Zeichen.';
    return _gruppeNach(() => quelle.rpc('gruppe_beitreten', {'p_code': code}));
  }

  Future<String?> gruppeGruenden(String eingabe) async {
    final name = eingabe.trim();
    if (name.length < 3 || name.length > 40) return kGruppenFehler['23514'];
    return _gruppeNach(() => quelle.rpc('gruppe_gruenden', {'p_name': name}));
  }

  /// Nach Beitritt oder Gründung ist die Gruppe gewählt.
  Future<String?> _gruppeNach(Future<dynamic> Function() aufruf) async {
    final gen = _gen;
    Object? r;
    try {
      r = await aufruf();
    } on CloudFehler catch (e) {
      return kGruppenFehler[e.code] ?? kTextNichtGeklappt;
    }
    if (gen != _gen) return null;
    final id = objekt(r)?['id'];
    gform = false;
    ansicht = id == null ? null : '$id';
    gstand = null;
    await _gruppenLaden(gen);
    if (gen == _gen) _mitteilen();
    return null;
  }

  Future<void> gruppeVerlassen() async {
    final id = ansicht;
    if (id == null || id == 'freunde') return;
    final gen = _gen;
    try {
      await quelle.rpc('gruppe_verlassen', {'p_gruppe': id});
    } on CloudFehler {
      // wie im Web: trotzdem zurück zu „Alle“ und die Gruppen neu laden
    }
    if (gen != _gen) return;
    ansicht = null;
    gstand = null;
    await _gruppenLaden(gen);
    if (gen == _gen) _mitteilen();
  }

  // -------------------------------------------------------------------------
  // Lernende, Freunde, Profile

  /// Dialog „Lernende“ öffnen: „Freunde“, wenn es Freunde oder Anfragen gibt,
  /// sonst „Alle“; auf Wunsch gleich ein Profil.
  void lernendeOeffnen({String? tab, String? profilPid, String? profilName}) {
    if (!quelle.bereit || leuteOk != true) return;
    final fs = fstand;
    lt.tab = tab ?? (((fs?.anfragen.isNotEmpty ?? false) || (fs?.freunde.isNotEmpty ?? false)) ? 'freunde' : 'alle');
    lt.meld = '';
    lt.profil = null;
    lt.profilLaedt = false;
    _mitteilen();
    _freundeNeu();
    if (lt.tab == 'alle') _imHintergrund(leuteSuchen);
    if (profilPid != null || profilName != null) {
      _imHintergrund(() => profilAnsehen(pid: profilPid, name: profilName));
    }
    _profilMelden();
  }

  void _freundeNeu() {
    final gen = _gen;
    _imHintergrund(() async {
      await _freundeLaden(gen);
      if (gen == _gen) _mitteilen();
    });
  }

  void lernendeTab(String tab) {
    lt.tab = tab;
    lt.meld = '';
    lt.profil = null;
    lt.profilLaedt = false;
    _mitteilen();
    if (tab == 'alle') {
      _imHintergrund(leuteSuchen);
    } else {
      _freundeNeu();
    }
  }

  void sucheSetzen(String s) {
    if (s == lt.suche) return;
    lt.suche = s;
    _imHintergrund(leuteSuchen);
  }

  /// Alle anderen in der Rangliste, aktivste der Woche zuerst, 30 je Seite.
  Future<void> leuteSuchen({bool mehr = false}) async {
    final seite = mehr ? lt.seite + 1 : 0;
    final suche = lt.suche;
    final gen = _gen;
    lt.laedt = true;
    _mitteilen();
    try {
      final r = await quelle.rpc('leute_suche', {'p_suche': suche, 'p_seite': seite, 'p_woche': woche});
      if (gen != _gen || suche != lt.suche) return;
      final d = objekt(r) ?? const <String, dynamic>{};
      lt.seite = seite;
      lt.gesamt = ganz(d['gesamt']);
      lt.liste = [if (mehr) ...?lt.liste, ...ProfilKarte.liste(d['liste'])];
    } on CloudFehler catch (e) {
      if (gen != _gen || suche != lt.suche) return;
      if (!e.netz) {
        lt.meldOk = false;
        lt.meld = kLeuteFehler[e.code] ?? 'Die Liste lässt sich gerade nicht laden.';
      }
      lt.liste ??= [];
    }
    lt.laedt = false;
    _mitteilen();
  }

  /// Profil über pid oder Spitzname.
  Future<void> profilAnsehen({String? pid, String? name}) async {
    final gen = _gen;
    final nr = ++_profilAnfrage;
    lt.profil = null;
    lt.profilLaedt = true;
    lt.meld = '';
    _mitteilen();
    Profil p;
    try {
      p = Profil.aus(await quelle.rpc('profil_ansehen', {'p_pid': pid, 'p_name': name, 'p_woche': woche}));
    } on CloudFehler {
      p = Profil.nichtGefunden;
    }
    if (gen != _gen || nr != _profilAnfrage || !lt.profilLaedt) return;
    lt.profil = p;
    lt.profilLaedt = false;
    _mitteilen();
  }

  void profilSchliessen() {
    _profilAnfrage++;
    lt.profil = null;
    lt.profilLaedt = false;
    lt.meld = '';
    _mitteilen();
  }

  /// Freundschaft: art = anfragen | annehmen | ablehnen | zurueck | entfernen.
  Future<void> freundAktion(String art, String pid, String name) async {
    if (lt.laeuft.contains(pid)) return;
    final gen = _gen;
    lt.meld = '';
    lt.laeuft.add(pid);
    _mitteilen();
    Object? r;
    try {
      r = switch (art) {
        'anfragen' => await quelle.rpc('freund_anfragen', {'p_pid': pid}),
        'annehmen' || 'ablehnen' =>
          await quelle.rpc('freund_antworten', {'p_pid': pid, 'p_annehmen': art == 'annehmen'}),
        _ => await quelle.rpc('freund_entfernen', {'p_pid': pid}),
      };
    } on CloudFehler catch (e) {
      if (gen != _gen) return;
      lt.laeuft.remove(pid);
      lt.meldOk = false;
      lt.meld = kLeuteFehler[e.code] ?? kTextNichtGeklappt;
      _mitteilen();
      return;
    }
    if (gen != _gen) return;
    final bez = art == 'anfragen'
        ? (r is String && r.isNotEmpty ? r : 'angefragt')
        : (art == 'annehmen' ? 'freund' : null);
    for (final k in lt.liste ?? const <ProfilKarte>[]) {
      if (k.pid == pid) k.bez = bez;
    }
    lt.meldOk = true;
    lt.meld = (art == 'annehmen' || bez == 'freund')
        ? 'Ihr seid jetzt befreundet.'
        : (art == 'anfragen' ? 'Anfrage an $name gesendet.' : '');
    await Future.wait([
      _freundeLaden(gen),
      if (lt.profil?.pid == pid) _profilNeu(pid, gen),
    ]);
    if (gen != _gen) return;
    lt.laeuft.remove(pid);
    _mitteilen();
  }

  Future<void> _profilNeu(String pid, int gen) async {
    try {
      final p = Profil.aus(await quelle.rpc('profil_ansehen', {'p_pid': pid, 'p_name': null, 'p_woche': woche}));
      if (gen == _gen && !p.fehler && lt.profil?.pid == pid) lt.profil = p;
    } on CloudFehler {
      // alter Stand bleibt
    }
  }

  /// Wer sieht den Lernstand je Fach: 'freunde' oder 'alle'.
  Future<void> sichtbarkeitSetzen(String s) async {
    final ich = fstand?.ich;
    if (ich == null || ich.sichtbarkeit == s) return;
    final alt = ich.sichtbarkeit;
    ich.sichtbarkeit = s;
    lt.meld = '';
    _mitteilen();
    final gen = _gen;
    try {
      await quelle.rpc('profil_sichtbarkeit', {'p_wert': s});
    } on CloudFehler {
      if (gen != _gen) return;
      ich.sichtbarkeit = alt;
      lt.meldOk = false;
      lt.meld = 'Speichern hat nicht geklappt – bitte später noch einmal.';
      _mitteilen();
      return;
    }
    if (gen != _gen) return;
    lt.meldOk = true;
    lt.meld = s == 'alle'
        ? 'Alle Lernenden sehen jetzt deinen Lernstand je Fach.'
        : 'Deinen Lernstand je Fach sehen jetzt nur noch Freunde.';
    _mitteilen();
  }
}
