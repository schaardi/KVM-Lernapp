import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvm_trainer/lernen/datum.dart';
import 'package:kvm_trainer/lernen/erinnerung.dart';
import 'package:kvm_trainer/lernen/erinnerung_service.dart';
import 'package:kvm_trainer/lernen/lernplan.dart';
import 'package:kvm_trainer/lernen/mitteilungen.dart';
import 'package:kvm_trainer/services/lerntage_service.dart';

/// Lern-Erinnerung (FR-009): was wann geplant wird – ohne Plugin.
class _Attrappe implements MitteilungsDienst {
  bool erlaubt = true;
  final Map<int, GeplanteErinnerung> geplanteMitteilungen = {};
  final List<List<int>> abgebrochen = [];

  @override
  Future<void> starten({VoidCallback? onTippen}) async {}
  @override
  Future<bool> erlaubnisAnfragen() async => erlaubt;
  @override
  Future<void> abbrechen(Iterable<int> ids) async {
    abgebrochen.add(ids.toList());
    for (final id in ids) {
      geplanteMitteilungen.remove(id);
    }
  }

  @override
  Future<void> planen(GeplanteErinnerung m) async => geplanteMitteilungen[m.id] = m;
  @override
  Future<List<int>> geplant() async => geplanteMitteilungen.keys.toList()..sort();
}

void main() {
  final jetzt = DateTime(2026, 9, 24, 12, 0); // Donnerstag, Mittag
  final heute = tagVonLokal(jetzt);

  List<GeplanteErinnerung> planen({DateTime? um, bool gelernt = false, int? pruefung, String zeit = '19:00'}) {
    final z = zeitLesen(zeit)!;
    return erinnerungenPlanen(
      jetzt: um ?? jetzt,
      stunde: z.stunde,
      minute: z.minute,
      heuteGelernt: gelernt,
      textHeute: 'Text für heute',
      pruefungTag: pruefung,
    );
  }

  group('Planen', () {
    test('Heute noch nichts gelernt: sieben Tage, IDs 7001–7007', () {
      final l = planen();
      expect(l.map((m) => m.id), [7001, 7002, 7003, 7004, 7005, 7006, 7007]);
      expect(l.first.zeit, DateTime(2026, 9, 24, 19, 0));
      expect(l.last.zeit, DateTime(2026, 9, 30, 19, 0));
      expect(l.every((m) => m.titel == 'Zeit zum Lernen'), isTrue);
      expect(l.first.text, 'Text für heute');
      expect(l.skip(1).every((m) => m.text == kErinnerungFolgetage), isTrue);
      expect(kErinnerungFolgetage, 'Kurz reinschauen: Die fälligen Fragen warten, und deine Serie hält.');
    });

    test('Heute schon gelernt: keine Mitteilung heute, aber ab morgen', () {
      final l = planen(gelernt: true);
      expect(l.map((m) => m.id), [7002, 7003, 7004, 7005, 7006, 7007]);
      expect(l.first.zeit, DateTime(2026, 9, 25, 19, 0));
    });

    test('Uhrzeit heute schon vorbei: erst morgen', () {
      expect(planen(um: DateTime(2026, 9, 24, 19, 0)).first.id, 7002);
      expect(planen(um: DateTime(2026, 9, 24, 21, 30)).first.id, 7002);
      expect(planen(um: DateTime(2026, 9, 24, 18, 58)).first.id, 7001);
    });

    test('Mit Prüfungstermin nur bis zum Tag davor', () {
      expect(planen(pruefung: heute + 3).map((m) => m.id), [7001, 7002, 7003]);
      expect(planen(pruefung: heute + 1).map((m) => m.id), [7001]);
      expect(planen(pruefung: heute), isEmpty);
      expect(planen(pruefung: heute - 5), isEmpty);
      expect(planen(pruefung: heute + 30).length, 7);
    });

    test('Die Uhrzeit bleibt über den Monatswechsel gleich', () {
      final l = planen(um: DateTime(2026, 10, 29, 8, 0), zeit: '07:35');
      expect(l.map((m) => '${m.zeit.day}.${m.zeit.month}. ${m.zeit.hour}:${m.zeit.minute}'),
          ['30.10. 7:35', '31.10. 7:35', '1.11. 7:35', '2.11. 7:35', '3.11. 7:35', '4.11. 7:35']);
    });
  });

  group('Texte', () {
    test('Erste passende Zeile für heute', () {
      final pruefung = tagVon('2026-11-04');
      expect(erinnerungTextHeute(planZiel: 58, pruefungTag: pruefung, serie: 6, faellig: 12, laufendesJahr: 2026),
          'Heute dran: 58 Fragen bis zur Prüfung am 4. Nov.');
      expect(erinnerungTextHeute(planZiel: 1, pruefungTag: tagVon('2027-03-04'), serie: 0, faellig: 0, laufendesJahr: 2026),
          'Heute dran: 1 Frage bis zur Prüfung am 4. März 2027.');
      expect(erinnerungTextHeute(serie: 6, faellig: 12), 'Deine Serie: 6 Tage – ein paar Fragen, und sie hält.');
      expect(erinnerungTextHeute(planZiel: 0, pruefungTag: pruefung, serie: 1, faellig: 12),
          '12 Fragen sind heute fällig – 10 Minuten reichen.');
      expect(erinnerungTextHeute(serie: 0, faellig: 1), '1 Frage ist heute fällig – 10 Minuten reichen.');
      expect(erinnerungTextHeute(serie: 1, faellig: 0), 'Ein paar Fragen zwischendurch halten dein Wissen frisch.');
    });
  });

  group('Einstellung', () {
    test('kvm_erinnerung lesen – das Web speichert nur die Uhrzeit', () {
      final e = ErinnerungEinstellung.lesen('{"an":true,"zeit":"07:30"}');
      expect(e.an, isTrue);
      expect(e.zeit, '07:30');
      expect(ErinnerungEinstellung.lesen('{"zeit":"19:00"}').an, isFalse);
      expect(ErinnerungEinstellung.lesen('{"an":true,"zeit":"25:00"}').zeit, '19:00');
      expect(ErinnerungEinstellung.lesen(null).zeit, '19:00');
      expect(ErinnerungEinstellung.lesen('kaputt').an, isFalse);
      expect(jsonDecode(const ErinnerungEinstellung(an: true, zeit: '06:05').schreiben()), {'an': true, 'zeit': '06:05'});
    });

    test('Uhrzeit in 5-Minuten-Schritten', () {
      expect(zeitAufFuenf('07:32'), '07:30');
      expect(zeitAufFuenf('07:33'), '07:35');
      expect(zeitAufFuenf('23:58'), '00:00');
      expect(zeitAufFuenf('kaputt'), '19:00');
      expect(zeitLesen('7:30'), isNull);
    });
  });

  group('Dienst', () {
    late _Attrappe dienst;
    final er = ErinnerungService.instance;

    Future<void> starten(Map<String, Object> werte) async {
      SharedPreferences.setMockInitialValues(werte);
      await LerntageService.instance.load();
      await Lernplan.instance.load();
      dienst = _Attrappe();
      er.dienst = dienst;
      await er.load();
    }

    test('Einschalten ohne Erlaubnis: Schalter bleibt aus, Hinweis erscheint', () async {
      await starten({});
      dienst.erlaubt = false;
      expect(await er.einschalten(), isFalse);
      expect(er.an, isFalse);
      expect(er.hinweis, 'Mitteilungen sind für die App ausgeschaltet – in den Systemeinstellungen erlauben.');
      expect(await dienst.geplant(), isEmpty);
    });

    test('Einschalten plant, Ausschalten entfernt alles', () async {
      await starten({});
      expect(await er.einschalten(), isTrue);
      expect(er.an, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('kvm_erinnerung')!), {'an': true, 'zeit': '19:00'});
      await er.neuPlanen(jetzt: DateTime.now().copyWith(hour: 8, minute: 0));
      expect(await dienst.geplant(), [7001, 7002, 7003, 7004, 7005, 7006, 7007]);
      // vor jedem Planen werden alle sieben IDs gelöscht
      expect(dienst.abgebrochen.last, kErinnerungIds);
      await er.ausschalten();
      expect(await dienst.geplant(), isEmpty);
    });

    test('Nach der ersten Antwort des Tages: heute keine Erinnerung mehr', () async {
      await starten({'kvm_erinnerung': '{"an":true,"zeit":"23:55"}'});
      final morgens = DateTime.now().copyWith(hour: 0, minute: 5);
      await er.neuPlanen(jetzt: morgens);
      expect((await dienst.geplant()).first, 7001);
      LerntageService.instance.zaehlen(); // erste Antwort heute
      er.pruefen();
      await er.neuPlanen(jetzt: morgens);
      expect((await dienst.geplant()).first, 7002);
    });

    test('Neue Uhrzeit wird gespeichert und neu geplant', () async {
      await starten({'kvm_erinnerung': '{"an":true,"zeit":"19:00"}'});
      await er.zeitSetzen('06:30');
      expect(er.zeit, '06:30');
      final m = dienst.geplanteMitteilungen.values.first;
      expect((m.zeit.hour, m.zeit.minute), (6, 30));
    });

    test('Mit Prüfungstermin enden die Erinnerungen am Tag davor', () async {
      final h = LerntageService.heute();
      await starten({
        'kvm_erinnerung': '{"an":true,"zeit":"23:55"}',
        'kvm_pruefung': jsonEncode({'datum': isoVon(h + 2)}),
      });
      await er.neuPlanen(jetzt: DateTime.now().copyWith(hour: 0, minute: 5));
      expect(await dienst.geplant(), [7001, 7002]);
    });
  });
}
