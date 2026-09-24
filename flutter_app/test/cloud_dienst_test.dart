import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvm_trainer/cloud/vergleich_dienst.dart';
import 'package:kvm_trainer/cloud/werte.dart';
import 'package:kvm_trainer/services/app_state.dart';
import 'package:kvm_trainer/services/data_service.dart';
import 'package:kvm_trainer/services/lerntage_service.dart';
import 'package:kvm_trainer/services/progress_service.dart';
import 'package:kvm_trainer/services/pruef_stat.dart';
import 'package:kvm_trainer/services/selection_service.dart';
import 'cloud/test_server.dart';

/// Vergleich: Zustandswechsel des Dienstes mit der Test-Attrappe statt Supabase.

TestServer _server({bool dabei = true}) {
  final s = TestServer();
  s.andere.addAll([
    TestPerson('Cora', reife: 64, antworten: 312, serie: 5),
    TestPerson('Bert', reife: 40, antworten: 120, serie: 2),
    TestPerson('Anna', reife: 81),
  ]);
  if (dabei) s.ich = TestPerson('Lkw_Profi', pid: 'pid-ich', reife: 50, antworten: 80, serie: 3);
  return s;
}

/// Alle Antworten der Attrappe abwarten (sie antwortet über Mikrotasks).
Future<void> _tick() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final d = VergleichDienst.instance;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await DataService.instance.load();
    await SelectionService.instance.load();
    await ProgressService.instance.load();
    await LerntageService.instance.load();
  });

  setUp(() => pruefStatistik = () => PruefStatistik.leer);

  test('Ohne SQL-Skript bleibt der Vergleich verborgen – ohne Fehler und ohne weitere Aufrufe', () async {
    final s = _server()..fehlt.add('rangliste_stand');
    d.testStart(s);
    await d.laden(erzwingen: true);
    expect(d.verfuegbar, isFalse);
    expect(AppState.instance.vergleichVerfuegbar.value, isFalse);
    expect(AppState.instance.vergleichHinweis.value, isFalse);
    expect(s.namen, ['rangliste_stand']);
    // höchstens alle 30 s neu laden
    await d.laden();
    expect(s.namen, ['rangliste_stand']);
  });

  test('Beitritt: Name geprüft, Serverfehler als Text, danach dabei', () async {
    final s = _server(dabei: false);
    d.testStart(s);
    await d.laden(erzwingen: true);
    expect(d.verfuegbar, isTrue);
    expect(AppState.instance.vergleichVerfuegbar.value, isTrue);
    expect(d.dabei, isFalse);
    expect(d.leuteOk, isTrue); // freunde_stand antwortet (null): Profile eingerichtet
    expect(s.namen, isNot(contains('gruppen_meine'))); // Gruppen erst nach dem Beitritt
    expect(s.letzte('rangliste_stand'), {'p_woche': isoWoche(DateTime.now())});

    expect(await d.spitznameSpeichern('ab'), kTextNameRegel);
    expect(s.anzahl('rangliste_melden'), 0);
    expect(await d.spitznameSpeichern('cora'), 'Dieser Spitzname ist schon vergeben.');
    s.gesperrt = true;
    expect(await d.spitznameSpeichern('Lkw_Profi'), 'Dein Konto ist für Rangliste, Gruppen und Freunde gesperrt.');
    s.gesperrt = false;
    s.offline = true;
    expect(await d.spitznameSpeichern('Lkw_Profi'), 'Keine Verbindung – bitte später noch einmal.');
    s.offline = false;

    expect(await d.spitznameSpeichern('  Lkw   Profi '), isNull);
    final w = s.letzte('rangliste_melden')!;
    expect(w['p_name'], 'Lkw Profi');
    expect(w['p_woche'], isoWoche(DateTime.now()));
    expect(d.dabei, isTrue);
    expect(d.stand!.name, 'Lkw Profi');
    expect(d.gruppenOk, isTrue);
    expect(d.pruefOk, isTrue);
  });

  test('Dabei: fehlende Skripte für Gruppen, Profile und Prüfungen blenden nur diese Teile aus', () async {
    final s = _server()..fehlt.addAll(['gruppen_meine', 'freunde_stand', 'rangliste_pruefungen']);
    d.testStart(s);
    await d.laden(erzwingen: true);
    expect(d.verfuegbar, isTrue);
    expect(d.dabei, isTrue);
    expect([d.gruppenOk, d.leuteOk, d.pruefOk], [false, false, false]);
    expect(s.anzahl('profil_melden'), 0);
  });

  test('Freundschaftsanfrage: Hinweispunkt am Reiter, Annehmen, Punkt weg', () async {
    final s = _server();
    final cora = s.andere.first;
    s.anfragenAnMich.add(cora.pid);
    d.testStart(s);
    await d.laden(erzwingen: true);
    expect(d.fstand!.anfragen.single.name, 'Cora');
    expect(AppState.instance.vergleichHinweis.value, isTrue);
    expect(s.anzahl('profil_melden'), 1); // einmal nach dem ersten freunde_stand

    d.lernendeOeffnen();
    expect(d.lt.tab, 'freunde');
    await _tick();
    expect(s.anzahl('profil_melden'), 2); // beim Öffnen der Übersicht
    await d.freundAktion('annehmen', cora.pid, 'Cora');
    expect(s.letzte('freund_antworten'), {'p_pid': cora.pid, 'p_annehmen': true});
    expect(d.lt.meld, 'Ihr seid jetzt befreundet.');
    expect(d.lt.meldOk, isTrue);
    expect(d.fstand!.anfragen, isEmpty);
    expect(d.fstand!.freunde.single.name, 'Cora');
    expect(AppState.instance.vergleichHinweis.value, isFalse);
  });

  test('Lernende: Suche, Anfrage, Profile mit und ohne Sichtbarkeit, Fehlertexte', () async {
    final s = _server();
    s.andere.add(TestPerson('Lkw-Profi', sichtbarkeit: 'alle', gemeistert: 150, details: {'tage': 12}));
    d.testStart(s);
    await d.laden(erzwingen: true);
    d.lernendeOeffnen();
    expect(d.lt.tab, 'alle'); // keine Freunde, keine Anfragen
    await _tick();
    expect(d.lt.liste!.length, 4);
    expect(d.lt.gesamt, 4);

    d.sucheSetzen('lkw');
    await _tick();
    expect(d.lt.liste!.single.name, 'Lkw-Profi');
    expect(s.letzte('leute_suche'), {'p_suche': 'lkw', 'p_seite': 0, 'p_woche': isoWoche(DateTime.now())});

    await d.freundAktion('anfragen', 'pid-lkw-profi', 'Lkw-Profi');
    expect(d.lt.meld, 'Anfrage an Lkw-Profi gesendet.');
    expect(d.lt.liste!.single.bez, 'angefragt');
    expect(d.fstand!.gesendet.single.name, 'Lkw-Profi');

    await d.profilAnsehen(name: 'Cora');
    expect(s.letzte('profil_ansehen'), {'p_pid': null, 'p_name': 'Cora', 'p_woche': isoWoche(DateTime.now())});
    expect(d.lt.profil!.name, 'Cora');
    expect(d.lt.profil!.sichtbar, isFalse);
    expect(d.lt.profil!.details, isEmpty);

    await d.profilAnsehen(pid: 'pid-lkw-profi');
    expect(d.lt.profil!.sichtbar, isTrue);
    expect(d.lt.profil!.gemeistert, 150);
    expect(d.lt.profil!.details['tage'], 12);
    d.profilSchliessen();
    expect(d.lt.profil, isNull);

    await d.profilAnsehen(pid: 'gibt-es-nicht');
    expect(d.lt.profil!.fehler, isTrue);

    s.fehler['freund_anfragen'] = 'P0004';
    await d.freundAktion('anfragen', 'pid-cora', 'Cora');
    expect(d.lt.meld, 'Du hast gerade sehr viele offene Anfragen – warte, bis einige beantwortet sind.');
    expect(d.lt.meldOk, isFalse);
    expect(d.lt.laeuft, isEmpty);
  });

  test('Sichtbarkeit: sofort umgestellt, bei Fehler zurückgenommen', () async {
    final s = _server();
    d.testStart(s);
    await d.laden(erzwingen: true);
    await d.sichtbarkeitSetzen('alle');
    expect(s.ich!.sichtbarkeit, 'alle');
    expect(d.fstand!.ich!.sichtbarkeit, 'alle');
    expect(d.lt.meld, 'Alle Lernenden sehen jetzt deinen Lernstand je Fach.');
    s.fehler['profil_sichtbarkeit'] = 'XX000';
    await d.sichtbarkeitSetzen('freunde');
    expect(d.fstand!.ich!.sichtbarkeit, 'alle');
    expect(d.lt.meld, 'Speichern hat nicht geklappt – bitte später noch einmal.');
    expect(d.lt.meldOk, isFalse);
  });

  test('Lerngruppe: Name zu kurz, gründen, falscher Code, beitreten, verlassen', () async {
    final s = _server();
    d.testStart(s);
    await d.laden(erzwingen: true);
    expect(d.gruppen, isEmpty);
    d.gformUmschalten();
    expect(d.gform, isTrue);

    expect(await d.gruppeGruenden('ab'), 'Der Gruppenname braucht 3–40 Zeichen.');
    expect(s.anzahl('gruppe_gruenden'), 0);
    expect(await d.gruppeGruenden('  Meisterkurs Herbst 2026  '), isNull);
    expect(s.letzte('gruppe_gruenden'), {'p_name': 'Meisterkurs Herbst 2026'});
    expect(d.gform, isFalse);
    expect(d.gruppen.single.name, 'Meisterkurs Herbst 2026');
    expect(d.ansicht, d.gruppen.single.id);
    expect(d.gstand!.mitglieder, 1);
    expect(d.gstand!.code, 'K7M2QX');

    expect(await d.gruppeBeitreten('abc'), 'Der Code hat 6 Zeichen.');
    expect(await d.gruppeBeitreten('zz zz zz'), 'Keine Gruppe mit diesem Code gefunden.');
    expect(s.letzte('gruppe_beitreten'), {'p_code': 'ZZZZZZ'});

    s.gruppen.add(TestGruppe('g-fremd', 'HB4TNE', 'IHK Köln', [s.andere[0], s.andere[1]]));
    expect(await d.gruppeBeitreten('hb4tne'), isNull);
    expect(d.ansicht, 'g-fremd');
    expect(d.gstand!.mitglieder, 3);
    expect([for (final e in d.gstand!.liste) e.name], ['Cora', 'Bert', 'Lkw_Profi']);
    expect(d.gstand!.liste.last.ich, isTrue);
    expect(s.letzte('gruppe_stand'), {'p_gruppe': 'g-fremd', 'p_woche': isoWoche(DateTime.now())});

    // Reiter „Alle“ und zurück zur Gruppe
    await d.waehleAnsicht(null);
    expect(d.gstand, isNull);
    await d.waehleAnsicht('g-fremd');
    expect(d.gstand!.name, 'IHK Köln');

    await d.gruppeVerlassen();
    expect(s.letzte('gruppe_verlassen'), {'p_gruppe': 'g-fremd'});
    expect(d.ansicht, isNull);
    expect([for (final g in d.gruppen) g.name], ['Meisterkurs Herbst 2026']);
  });

  test('Prüfungen: ohne gewertete Prüfung wird nichts gemeldet', () async {
    final s = _server();
    d.testStart(s);
    await d.laden(erzwingen: true);
    expect(s.namen, isNot(contains('pruefungen_melden')));
    expect(s.namen, contains('rangliste_pruefungen'));
    expect(d.pruefOk, isTrue);
    expect(d.pstand!.liste, isEmpty);
  });

  test('Prüfungen: einmal je Sitzung vor der Prüfungsrangliste melden, danach das Profil mit pr/pc', () async {
    pruefStatistik = () => const PruefStatistik(n: 2, ok: 1, schnitt: 58, bereiche: {
          'RE': PruefBereichStat(kurz: 'Recht', n: 1, ok: 1, schnitt: 70, chance: 0.886),
          'BW': PruefBereichStat(kurz: 'BWL', n: 1, ok: 0, schnitt: 45, chance: 0.395),
        });
    final s = _server();
    d.testStart(s);
    await d.laden(erzwingen: true);
    final i = s.namen.indexOf('pruefungen_melden');
    expect(i, greaterThanOrEqualTo(0));
    expect(s.namen.indexOf('rangliste_pruefungen'), greaterThan(i));
    expect(s.letzte('pruefungen_melden'), {'p_n': 2, 'p_ok': 1, 'p_schnitt': 58, 'p_chance': null});
    expect(d.pstand!.ich!.platz, 1);
    expect(d.pstand!.liste.single.name, 'Lkw_Profi');
    final details = s.letzte('profil_melden')!['p_details'] as Map;
    expect(details['pr'], {
      'RE': {'n': 1, 'ok': 1, 's': 70, 'c': 89},
      'BW': {'n': 1, 'ok': 0, 's': 45, 'c': 40},
    });
    expect(details['pc'], {'bq': null, 'hq': null, 'g': null});

    await d.laden(erzwingen: true);
    expect(s.anzahl('pruefungen_melden'), 1);
    await d.pruefWerteMelden(); // neue Ergebnisse (pruefStand) → erneut
    expect(s.anzahl('pruefungen_melden'), 2);
  });

  test('pruefungen_melden fehlt: kein Umschalter, zurück auf „Diese Woche“', () async {
    pruefStatistik = () => const PruefStatistik(n: 1, ok: 1, schnitt: 80);
    final s = _server()..fehlt.add('pruefungen_melden');
    d.testStart(s);
    d.modus = RanglistenModus.pruef;
    await d.laden(erzwingen: true);
    expect(d.pruefOk, isFalse);
    expect(d.modus, RanglistenModus.woche);
    expect(d.pruefModus, isFalse);
    expect(s.namen, isNot(contains('rangliste_pruefungen')));
  });

  test('Umschalter „Prüfungen“ und Austreten', () async {
    final s = _server();
    d.testStart(s);
    await d.laden(erzwingen: true);
    await d.waehleModus(RanglistenModus.pruef);
    expect(d.pruefModus, isTrue);
    expect(await d.austreten(), isTrue);
    expect(s.ich, isNull);
    expect(d.dabei, isFalse);
    expect(d.modus, RanglistenModus.woche);
    expect(d.stand!.teilnehmende, 3);
  });

  test('Kontowechsel und Abmelden setzen alles zurück', () async {
    final s = _server();
    d.testStart(s);
    await d.laden(erzwingen: true);
    await d.waehleAnsicht('freunde');
    expect(d.ansicht, 'freunde');

    s.konto = 'konto-anders';
    d.kontoPruefen();
    expect(d.stand, isNull);
    expect(d.ansicht, isNull);
    await _tick();
    expect(d.stand, isNotNull);
    expect(d.verfuegbar, isTrue);

    s.bereit = false;
    d.kontoPruefen();
    expect(d.stand, isNull);
    expect(d.verfuegbar, isNull);
    expect(AppState.instance.vergleichVerfuegbar.value, isNull);
    expect(AppState.instance.vergleichHinweis.value, isFalse);
  });

  testWidgets('Werte melden: 4 s nach der letzten Antwort, danach das Profil', (tester) async {
    final s = _server();
    d.testStart(s);
    await d.laden(erzwingen: true);
    final vorher = s.anzahl('profil_melden');
    d.meldenSpaeter();
    await tester.pump(const Duration(seconds: 3));
    d.meldenSpaeter(); // nächste Antwort: die Uhr beginnt neu
    await tester.pump(const Duration(seconds: 3));
    expect(s.anzahl('rangliste_melden'), 0);
    await tester.pump(const Duration(seconds: 2));
    expect(s.anzahl('rangliste_melden'), 1);
    expect(s.letzte('rangliste_melden')!['p_name'], 'Lkw_Profi');
    expect(s.anzahl('profil_melden'), vorher + 1);
  });
}
