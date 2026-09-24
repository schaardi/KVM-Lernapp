import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvm_trainer/lernen/datum.dart';
import 'package:kvm_trainer/lernen/lernplan.dart';
import 'package:kvm_trainer/widgets/ui.dart' show Ampel;

/// Prüfungstermin und Lernplan (FR-006): Rechnung, Statuszeile und Datum
/// mit den Referenzwerten aus APP_FEATURE_REQUESTS.md.
void main() {
  // Ein fester Tag: Donnerstag, 24. September 2026.
  final heute = tagVon('2026-09-24');
  PruefungsTermin termin(int inTagen) => PruefungsTermin(datum: isoVon(heute + inTagen));

  group('Rechnung', () {
    test('Referenzfall: 3.666 Fragen, kein Fortschritt, 42 Tage → 7.699 nötig, Tagesziel 245', () {
      final r = planRechnen(termin(42), PlanEingabe(heute: heute, n: 3666));
      expect(r.stand.tage, 42);
      expect(r.stand.noetig, 7699);
      expect(r.stand.quote, 0.75);
      expect(r.stand.ziel, 245);
      expect(r.stand.prognose, isNull);
      // festgelegt und zu speichern
      expect(r.termin.tag, heute);
      expect(r.termin.n, 3666);
      expect(r.termin.ziel, 245);
    });

    test('Das Tagesziel bleibt am selben Tag – auch wenn gelernt wurde', () {
      final erster = planRechnen(termin(42), PlanEingabe(heute: heute, n: 3666)).termin;
      // Drei Antworten später (und sogar viel mehr Fortschritt): „Heute 3 / 245“.
      final r = planRechnen(erster, PlanEingabe(heute: heute, n: 3666, summeBoxen: 900, geschafft: 3));
      expect(r.stand.ziel, 245);
      expect(r.stand.geschafft, 3);
      expect(identical(r.termin, erster), isTrue, reason: 'nichts neu zu speichern');
    });

    test('Neu festgelegt am nächsten Tag und bei geänderter Fächerwahl', () {
      final erster = planRechnen(termin(42), PlanEingabe(heute: heute, n: 3666)).termin;
      final morgen = planRechnen(erster, PlanEingabe(heute: heute + 1, n: 3666, summeBoxen: 900));
      expect(morgen.termin.tag, heute + 1);
      // noetig = ⌈7.698,6 − 900⌉ = 6.799; ⌈6.799 ÷ 0,75 ÷ 41⌉ = 222
      expect(morgen.stand.ziel, 222);
      // Kraftverkehr abgewählt: 2.726 aktive Fragen
      final ohneFach5 = planRechnen(erster, PlanEingabe(heute: heute, n: 2726));
      expect(ohneFach5.termin.n, 2726);
      expect(ohneFach5.stand.noetig, 5725);
      expect(ohneFach5.stand.ziel, (5725 / 0.75 / 42).ceil());
    });

    test('Trefferquote: unter 30 Antworten 0,75, sonst begrenzt auf 0,5–0,95', () {
      double quote(int r, int f) =>
          planRechnen(termin(42), PlanEingabe(heute: heute, n: 3666, richtig: r, falsch: f)).stand.quote;
      expect(quote(20, 9), 0.75);
      expect(quote(100, 0), 0.95);
      expect(quote(10, 90), 0.5);
      expect(quote(60, 20), 0.75);
      expect(quote(80, 20), 0.8);
    });

    test('Nichts mehr nötig: Tagesziel = heute fällige Fragen', () {
      final r = planRechnen(termin(10), PlanEingabe(heute: heute, n: 100, summeBoxen: 300, faellig: 12));
      expect(r.stand.noetig, 0);
      expect(r.stand.ziel, 12);
    });

    test('Am Prüfungstag und danach kein Tagesziel', () {
      expect(planRechnen(termin(0), PlanEingabe(heute: heute, n: 3666)).stand.ziel, 0);
      expect(planRechnen(termin(-3), PlanEingabe(heute: heute, n: 3666)).stand.tage, -3);
      expect(planRechnen(termin(-3), PlanEingabe(heute: heute, n: 3666)).stand.ziel, 0);
    });

    test('Prognose aus dem Tempo der letzten sieben Tage', () {
      // Ø 400 Fragen am Tag: heute + ⌈7.699 ÷ (400 · 0,75)⌉ = heute + 26
      final schnell = planRechnen(termin(42), PlanEingabe(heute: heute, n: 3666, woche: 2800)).stand;
      expect(schnell.tempo, 400);
      expect(schnell.prognose, heute + 26);
      // Ø 20: heute + ⌈7.699 ÷ 15⌉ = heute + 514
      final langsam = planRechnen(termin(42), PlanEingabe(heute: heute, n: 3666, woche: 140)).stand;
      expect(langsam.prognose, heute + 514);
      // Unter einer Frage am Tag keine Prognose
      expect(planRechnen(termin(42), PlanEingabe(heute: heute, n: 3666, woche: 6)).stand.prognose, isNull);
    });
  });

  group('Statuszeile', () {
    PlanStand stand({int n = 3666, int woche = 0, int geschafft = 0, int summe = 0, int faellig = 0, int tage = 42}) =>
        planRechnen(termin(tage),
                PlanEingabe(heute: heute, n: n, woche: woche, geschafft: geschafft, summeBoxen: summe, faellig: faellig))
            .stand;

    test('Im Plan mit Ø 400 Fragen am Tag', () {
      final s = planStatus(stand(woche: 2800), laufendesJahr: 2026);
      expect(s.ampel, Ampel.gruen);
      expect(s.text,
          'Im Plan: Mit Ø 400 Fragen am Tag bist du am 20. Okt. prüfungsreif (70 %). Setz Schwerpunkte, z. B. mit „Schwächen üben“.');
    });

    test('Rückstand mit Ø 20 Fragen am Tag (rot bei Tagesziel über 120)', () {
      final s = planStatus(stand(woche: 140), laufendesJahr: 2026);
      expect(s.ampel, Ampel.rot);
      expect(s.text, startsWith('Rückstand: Mit Ø 20 Fragen am Tag wärst du erst am 20. Feb. 2028 prüfungsreif. '));
      expect(s.text, contains('Mit dem Tagesziel klappt es bis zur Prüfung.'));
      expect(s.text, endsWith('Setz Schwerpunkte, z. B. mit „Schwächen üben“.'));
      // auf sehr niedrigen Bildschirmen ohne den Zusatz
      expect(planStatus(stand(woche: 140), laufendesJahr: 2026, schwerpunkte: false).text,
          endsWith('Mit dem Tagesziel klappt es bis zur Prüfung.'));
    });

    test('Rückstand gelb bei Tagesziel bis 120', () {
      // 500 Fragen, 30 Tage: nötig 1.050, Ziel ⌈1.050 ÷ 0,75 ÷ 30⌉ = 47; Ø 3 → Prognose nach dem Termin
      final s = planStatus(stand(n: 500, tage: 30, woche: 21), laufendesJahr: 2026);
      expect(s.ampel, Ampel.gelb);
      expect(s.text, startsWith('Rückstand: Mit Ø 3 Fragen am Tag'));
    });

    test('Tagesziel geschafft', () {
      final s = planStatus(stand(n: 500, tage: 30, geschafft: 47));
      expect(s.ampel, Ampel.gruen);
      expect(s.text, 'Tagesziel geschafft – stark! Morgen geht es weiter.');
    });

    test('Ziel erreicht – mit und ohne fällige Fragen', () {
      expect(planStatus(stand(n: 100, summe: 300, faellig: 5)).text,
          'Ziel erreicht: 70 % prüfungsreif. Halte den Stand mit den fälligen Fragen.');
      expect(planStatus(stand(n: 100, summe: 300)).text,
          'Ziel erreicht: 70 % prüfungsreif. Heute ist nichts fällig – probier eine Original-Prüfung.');
    });

    test('Ohne Tempo nach Tagesziel eingestuft', () {
      // 58 am Tag: gut machbar
      final gut = planStatus(stand(n: 1000, tage: 49));
      expect(gut.ampel, Ampel.gruen);
      expect(gut.text, 'Gut machbar: Mit 58 Fragen am Tag bist du bis zur Prüfung zu 70 % prüfungsreif.');
      // 112 am Tag: sportlich
      final sportlich = planStatus(stand(n: 1000, tage: 25));
      expect(sportlich.ampel, Ampel.gelb);
      expect(sportlich.text, startsWith('Sportlich: Mit 112 Fragen am Tag'));
      // 245 am Tag: sehr knapp, mit Schwerpunkt-Tipp
      final knapp = planStatus(stand());
      expect(knapp.ampel, Ampel.rot);
      expect(knapp.text,
          'Sehr knapp: Mit 245 Fragen am Tag bist du bis zur Prüfung zu 70 % prüfungsreif. Setz Schwerpunkte, z. B. mit „Schwächen üben“.');
    });
  });

  group('Datum und Speicher', () {
    test('Datumsformate wie im Web', () {
      expect(datumLang(tagVon('2026-11-04')), 'Mi., 4. Nov. 2026');
      expect(datumKurz(tagVon('2026-10-28'), laufendesJahr: 2026), '28. Okt.');
      expect(datumKurz(tagVon('2027-04-15'), laufendesJahr: 2026), '15. Apr. 2027');
      expect(datumKurz(tagVon('2026-09-15'), laufendesJahr: 2026), '15. Sept.');
      expect(isoVon(tagVon('2026-11-04')), '2026-11-04');
      expect(tagVonLokal(DateTime(2026, 11, 4, 23, 30)), tagVon('2026-11-04'));
    });

    test('Formularfehler wie im Web', () {
      expect(terminFehler(null, heute: heute), 'Bitte ein Datum wählen.');
      expect(terminFehler('4.11.2026', heute: heute), 'Bitte ein Datum wählen.');
      expect(terminFehler(isoVon(heute), heute: heute), 'Der Termin muss in der Zukunft liegen.');
      expect(terminFehler(isoVon(heute + 1), heute: heute), isNull);
    });

    test('kvm_pruefung lesen und schreiben', () {
      final t = PruefungsTermin.lesen('{"datum":"2026-11-04","tag":20719,"n":3666,"ziel":245}')!;
      expect(t.datum, '2026-11-04');
      expect(t.ziel, 245);
      expect(PruefungsTermin.lesen(t.schreiben())!.n, 3666);
      expect(PruefungsTermin.lesen('{"datum":"morgen"}'), isNull);
      expect(PruefungsTermin.lesen('kaputt'), isNull);
      expect(const PruefungsTermin(datum: '2026-11-04').schreiben(), '{"datum":"2026-11-04"}');
    });

    test('Lernplan speichert den Termin und das einmal je Tag festgelegte Ziel', () async {
      SharedPreferences.setMockInitialValues({});
      final plan = Lernplan.instance;
      await plan.load();
      expect(plan.termin, isNull);
      plan.speichern(isoVon(heute + 42));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(Lernplan.schluessel), '{"datum":"${isoVon(heute + 42)}"}');
      final stand = plan.rechnen(heute: heute)!;
      expect(stand.tage, 42);
      expect(PruefungsTermin.lesen(prefs.getString(Lernplan.schluessel))!.tag, heute);
      plan.entfernen();
      expect(prefs.getString(Lernplan.schluessel), isNull);
      expect(plan.rechnen(heute: heute), isNull);
    });
  });
}
