import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_trainer/features/init_lernen.dart';
import 'package:kvm_trainer/main.dart';
import 'package:kvm_trainer/services/app_state.dart';
import 'package:kvm_trainer/services/data_service.dart';
import 'package:kvm_trainer/theme/theme_controller.dart';
import 'package:kvm_trainer/lernen/erinnerung.dart';
import 'package:kvm_trainer/lernen/erinnerung_service.dart';
import 'package:kvm_trainer/lernen/mitteilungen.dart';
import 'package:kvm_trainer/services/startschutz.dart';
import 'package:kvm_trainer/widgets/startschutz_bericht.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Zählt, ob das Mitteilungs-Plugin gestartet wird.
class _Mitteilungen implements MitteilungsDienst {
  int gestartet = 0;
  @override
  Future<void> starten({VoidCallback? onTippen}) async => gestartet++;
  @override
  Future<bool> erlaubnisAnfragen() async => false;
  @override
  Future<void> abbrechen(Iterable<int> ids) async {}
  @override
  Future<void> planen(GeplanteErinnerung m) async {}
  @override
  Future<List<int>> geplant() async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const kanal = MethodChannel('kvm/startschutz');
  late Directory ordner;
  late List<MethodCall> aufrufe;
  late Map<String, Object?> stand;

  setUp(() {
    ordner = Directory.systemTemp.createTempSync('startschutz');
    aufrufe = [];
    stand = {
      'ordner': ordner.path,
      'sicher': true,
      'skia': false,
      'neuerBericht': true,
      'berichtVorhanden': true,
      'abgebrochenBei': 'sync',
    };
    Startschutz.debugAndroid = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(kanal, (call) async {
      aufrufe.add(call);
      switch (call.method) {
        case 'stand':
          return stand;
        case 'bericht':
          return 'Meister-Trainer – Absturzbericht\nCRASH_NATIVE libflutter.so';
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(kanal, null);
    Startschutz.debugAndroid = null;
    Startschutz.instance.debugZuruecksetzen();
    ordner.deleteSync(recursive: true);
  });

  test('laden übernimmt den Stand, Schritte landen synchron in der Datei', () async {
    final s = Startschutz.instance;
    await s.laden();
    expect(s.sicher, isTrue);
    expect(s.skia, isFalse);
    expect(s.neuerBericht, isTrue);
    expect(s.berichtVorhanden, isTrue);
    expect(s.abgebrochenBei, 'sync');

    s.schritt('daten');
    expect(File('${ordner.path}/schritt.txt').readAsStringSync(), 'daten');
    s.schritt('sync');
    expect(File('${ordner.path}/schritt.txt').readAsStringSync(), 'sync');

    await s.fertig();
    expect(File('${ordner.path}/schritt.txt').readAsStringSync(), 'fertig');
    expect(aufrufe.map((c) => c.method), containsAllInOrder(['stand', 'fertig']));
  });

  test('ohne Android (Tests, Web, Desktop) bleibt alles aus', () async {
    Startschutz.debugAndroid = false;
    final s = Startschutz.instance;
    await s.laden();
    s.schritt('daten');
    expect(s.sicher, isFalse);
    expect(aufrufe, isEmpty);
    expect(File('${ordner.path}/schritt.txt').existsSync(), isFalse);
    expect(await s.bericht(), isNull);
  });

  test('ein Fehler im Kanal verhindert den Start nicht', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(kanal, (call) async {
      throw PlatformException(code: 'kaputt');
    });
    final s = Startschutz.instance;
    await s.laden();
    await s.fertig();
    expect(s.sicher, isFalse);
    expect(await s.bericht(), isNull);
  });

  test('sicherer Modus: Lernen startet ohne Mitteilungs-Plugin', () async {
    SharedPreferences.setMockInitialValues({});
    final m = _Mitteilungen();
    ErinnerungService.instance.dienst = m;
    await initLernen(mitMitteilungen: false);
    expect(m.gestartet, 0);
    await initLernen();
    expect(m.gestartet, 1);
  });

  testWidgets('Bericht: anzeigen, kopieren, weiter', (tester) async {
    String? zwischenablage;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') zwischenablage = (call.arguments as Map)['text'] as String?;
      return null;
    });
    await Startschutz.instance.laden();
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(onPressed: () => absturzberichtZeigen(context), child: const Text('öffnen')),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('öffnen'));
    await tester.pumpAndSettle();
    expect(find.text('Sicherer Start nach Absturz'), findsOneWidget);
    expect(find.textContaining('sicheren Modus'), findsOneWidget);
    expect(find.textContaining('CRASH_NATIVE libflutter.so'), findsOneWidget);

    await tester.tap(find.text('Bericht kopieren'));
    await tester.pumpAndSettle();
    expect(zwischenablage, contains('CRASH_NATIVE'));
    expect(find.text('Kopiert ✓'), findsOneWidget);

    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Sicherer Start nach Absturz'), findsNothing);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('Konto: Hinweis im sicheren Modus, nächstes Mal normal starten', (tester) async {
    await Startschutz.instance.laden();
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: StartschutzKarte())));
    expect(find.text('Sicherer Modus'), findsOneWidget);
    expect(find.text('Bericht anzeigen'), findsOneWidget);

    await tester.tap(find.text('Nächstes Mal normal starten'));
    await tester.pumpAndSettle();
    expect(aufrufe.map((c) => c.method), contains('normal'));
    expect(find.textContaining('Beim nächsten Start lädt die App wieder alles'), findsOneWidget);
    expect(find.text('Nächstes Mal normal starten'), findsNothing);
  });

  testWidgets('Nach Absturz: erst der Bericht, dann lädt die App sicher, danach „fertig“', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final m = _Mitteilungen();
    ErinnerungService.instance.dienst = m;
    await Startschutz.instance.laden();
    await tester.runAsync(() async {
      await DataService.instance.load();
      await ThemeController.instance.load();
    });
    AppState.instance.seite = AppSeite.start;
    final schritt = File('${ordner.path}/schritt.txt');

    Future<void> laufen() async {
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 30));
      }
    }

    await tester.pumpWidget(const KvmApp());
    await laufen();
    expect(find.text('Sicherer Start nach Absturz'), findsOneWidget);
    expect(schritt.existsSync(), isFalse, reason: 'vor dem Bericht wird nichts geladen');

    await tester.tap(find.text('Weiter'));
    await laufen();
    expect(find.text('Sicherer Start nach Absturz'), findsNothing);
    expect(schritt.readAsStringSync(), 'startseite');
    expect(m.gestartet, 0, reason: 'im sicheren Modus bleiben die Mitteilungen aus');

    await tester.pump(const Duration(seconds: 4));
    expect(schritt.readAsStringSync(), 'fertig');
    expect(aufrufe.map((c) => c.method), contains('fertig'));
  });

  testWidgets('Konto: ohne Absturz kein Hinweis', (tester) async {
    stand = {'ordner': ordner.path, 'sicher': false, 'neuerBericht': false, 'berichtVorhanden': false};
    await Startschutz.instance.laden();
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: StartschutzKarte())));
    expect(find.text('Sicherer Modus'), findsNothing);
    expect(find.text('Absturzbericht'), findsNothing);
  });
}
