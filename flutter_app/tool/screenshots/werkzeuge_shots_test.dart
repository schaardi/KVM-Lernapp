// Screenshots des Pakets „Werkzeuge“ (Rechner, Dock, Formelbuch, Rechenblatt,
// Fehler melden, Gefahrgut) – zum Prüfen von Layout, Schriften und
// Dunkelmodus ohne Gerät (nicht Teil der normalen Test-Suite):
//   flutter test --update-goldens tool/screenshots/werkzeuge_shots_test.dart
// Schreibt PNGs nach tool/screenshots/goldens/ (nicht eingecheckt).
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvm_trainer/constants.dart';
import 'package:kvm_trainer/main.dart' show themaFuer;
import 'package:kvm_trainer/services/data_service.dart';
import 'package:kvm_trainer/werkzeuge/rechner_modell.dart';
import 'package:kvm_trainer/widgets/drawing_pad.dart';
import 'package:kvm_trainer/widgets/werkzeug_dock.dart';

// Helfer wie in tool/screenshots/shots_test.dart.
Future<void> _schriften() async {
  Future<void> lade(String family, List<String> files) async {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
    }
    await l.load();
  }

  final root = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  final mf = '$root/bin/cache/artifacts/material_fonts';
  await lade('Inter', [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
  await lade('BarlowCondensed', ['assets/fonts/BarlowCondensed-SemiBold.ttf', 'assets/fonts/BarlowCondensed-Bold.ttf']);
  await lade('IBMPlexMono', ['assets/fonts/IBMPlexMono-Medium.ttf', 'assets/fonts/IBMPlexMono-SemiBold.ttf']);
  await lade('MaterialIcons', ['$mf/MaterialIcons-Regular.otf']);
  await lade('Roboto', ['$mf/Roboto-Regular.ttf', '$mf/Roboto-Medium.ttf', '$mf/Roboto-Bold.ttf']);
}

Future<void> _foto(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 400));
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

/// Probeseite wie eine Rechenfrage im Quiz: Aufgabe, Ergebnisfeld, Dock.
class _Probe extends StatefulWidget {
  const _Probe();
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  final _ergebnis = TextEditingController();
  bool _sprache = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kostenrechnung')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: kPaper, borderRadius: BorderRadius.circular(kRadius), border: Border.all(color: kLine)),
          child: Text(
            'Ein Auftrag verursacht Fixkosten von 4.400 € und wird auf 22 Lose verteilt. '
            'Berechnen Sie die Fixkosten je Los. Runden Sie auf zwei Nachkommastellen.',
            style: TextStyle(fontSize: 15, height: 1.5, color: kInk),
          ),
        ),
        const SizedBox(height: 14),
        TextField(controller: _ergebnis, decoration: const InputDecoration(labelText: 'Ergebnis')),
        const SizedBox(height: 300),
        FilledButton(onPressed: () {}, child: const Text('Antwort prüfen')),
      ]),
      bottomNavigationBar: WerkzeugDock(
        onUebernehmen: (t) => _ergebnis.text = t,
        onSprache: () => setState(() => _sprache = !_sprache),
        spracheAktiv: _sprache,
      ),
    );
  }
}

Future<void> _app(WidgetTester tester, Size groesse, {bool dunkel = false, double dpr = 2, Widget home = const _Probe()}) async {
  debugDisableShadows = false;
  tester.view.physicalSize = groesse * dpr;
  tester.view.devicePixelRatio = dpr;
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  await tester.runAsync(() async {
    await _schriften();
    await DataService.instance.load();
    await RechnerModell.instance.laden();
  });
  // ignore: invalid_use_of_visible_for_testing_member
  RechnerModell.instance.zuruecksetzen();
  KvmPalette.current = dunkel ? KvmPalette.dark : KvmPalette.light;
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: themaFuer(KvmPalette.current),
    home: home,
  ));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Am Ende jedes Tests: Schatten-Schalter und Palette zurück (die
/// Testumgebung prüft das direkt nach dem Testkörper).
void _aufraeumen() {
  debugDisableShadows = true;
  KvmPalette.current = KvmPalette.light;
}

void _tippe(String folge) => RechnerModell.instance.tasten(folge.split(' ').where((k) => k.isNotEmpty));

void main() {
  const handy = Size(390, 844);
  const klein = Size(360, 740);
  const breit = Size(1024, 768);

  testWidgets('Dock und Rechner – Handy hell', (tester) async {
    await _app(tester, handy);
    await _foto(tester, 'wz_handy_1_dock');
    await tester.tap(find.text('Rechner'));
    await tester.pump(const Duration(milliseconds: 300));
    _tippe('4 4 0 0 ÷ 2 2 =');
    _tippe('1 0 zeit − 6 zeit 4 5 =');
    _tippe('2 π =');
    _tippe('1 2 3 4 5 ÷ 1 0 + ( 2');
    await _foto(tester, 'wz_handy_2_rechner');
    await tester.tap(find.byTooltip('Tasten einklappen'));
    await _foto(tester, 'wz_handy_3_eingeklappt');
    _aufraeumen();
  });

  testWidgets('Dock und Rechner – Handy dunkel', (tester) async {
    await _app(tester, handy, dunkel: true);
    await _foto(tester, 'wz_dunkel_1_dock');
    await tester.tap(find.text('Rechner'));
    await tester.pump(const Duration(milliseconds: 300));
    _tippe('inv sin 0 , 5 =');
    _tippe('5 + =');
    await _foto(tester, 'wz_dunkel_2_rechner');
    _aufraeumen();
  });

  testWidgets('Rechner – klein', (tester) async {
    await _app(tester, klein);
    await tester.tap(find.text('Rechner'));
    await tester.pump(const Duration(milliseconds: 300));
    _tippe('1 0 zeit − 6 zeit 4 5 =');
    _tippe('1 2 3 4 5 ÷ 1 0 =');
    await _foto(tester, 'wz_klein_1_rechner');
    _aufraeumen();
  });

  testWidgets('Rechner – breit schwebend', (tester) async {
    await _app(tester, breit, dpr: 1.25);
    await tester.tap(find.text('Rechner'));
    await tester.pump(const Duration(milliseconds: 300));
    _tippe('2 0 0 + 1 9 % =');
    _tippe('inv');
    await _foto(tester, 'wz_breit_1_rechner');
    _aufraeumen();
  });

  testWidgets('Formelbuch und Rechenblatt – klein', (tester) async {
    await _app(tester, klein);
    await tester.tap(find.text('Formeln'));
    await tester.pump(const Duration(milliseconds: 600));
    await _foto(tester, 'wz_klein_2_formelbuch');
    await tester.ensureVisible(find.text('Beispiel').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Beispiel').first);
    await tester.pump(const Duration(milliseconds: 300));
    await _foto(tester, 'wz_klein_3_formelbuch_beispiel');
    await tester.ensureVisible(find.text('Vorlage ins Antwortfeld').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Vorlage ins Antwortfeld').first);
    await tester.pump(const Duration(milliseconds: 300));
    await _foto(tester, 'wz_klein_4_formelbuch_vorlage');
    Navigator.of(tester.element(find.text('FORMELBUCH'))).pop();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Blatt'));
    await tester.pump(const Duration(milliseconds: 600));
    final flaeche = tester.getRect(find.byType(DrawingPad));
    final g = await tester.startGesture(flaeche.center - const Offset(80, 40));
    for (var i = 0; i < 12; i++) {
      await g.moveBy(const Offset(12, 6));
    }
    await g.up();
    await _foto(tester, 'wz_klein_5_rechenblatt');
    _aufraeumen();
  });

  testWidgets('Formelbuch – Handy dunkel', (tester) async {
    await _app(tester, handy, dunkel: true);
    await tester.tap(find.text('Formeln'));
    await tester.pump(const Duration(milliseconds: 600));
    await _foto(tester, 'wz_dunkel_3_formelbuch');
    _aufraeumen();
  });
}
