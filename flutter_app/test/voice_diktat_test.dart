import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_trainer/services/voice_service.dart';

/// Diktat fürs mündliche Üben (FR-011): Die Spracherkennung wird über ihren
/// Methodenkanal nachgestellt. Geprüft wird, dass Meldungen einer vorigen
/// Aufnahme die neue nicht beenden oder überschreiben.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const kanal = 'plugin.csdcorp.com/speech_to_text';
  final bote = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final aufrufe = <String>[];

  setUpAll(() async {
    bote.setMockMethodCallHandler(const MethodChannel(kanal), (call) async {
      aufrufe.add(call.method);
      return switch (call.method) {
        'initialize' || 'listen' || 'has_permission' => true,
        _ => null,
      };
    });
    bote.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async => 1);
    await VoiceService.instance.init();
  });

  Future<void> vomGeraet(String methode, Object? wert) async {
    await bote.handlePlatformMessage(
        kanal, const StandardMethodCodec().encodeMethodCall(MethodCall(methode, wert)), (_) {});
  }

  String ergebnis(String text, {bool endgueltig = false}) => jsonEncode({
        'alternates': [
          {'recognizedWords': text, 'recognizedPhrases': null, 'confidence': 0.9},
        ],
        'resultType': endgueltig ? 2 : 0,
      });

  test('Diktat: Mitschrift, Ende der Sitzung, keine Meldungen der vorigen Aufnahme', () async {
    expect(VoiceService.instance.sttAvailable, isTrue);
    final texte = <String>[];
    var enden = 0;

    Future<bool> starten(String nr) => VoiceService.instance.diktatStarten(
          onText: (t, fertig) => texte.add('$nr${fertig ? '!' : '~'}$t'),
          onEnde: () => enden++,
          onFehler: (_) {},
        );

    // Erste Aufnahme endet von selbst (Pause) → „Gehört“
    expect(await starten('1'), isTrue);
    expect(aufrufe, contains('listen'));
    await vomGeraet('notifyStatus', 'listening');
    await vomGeraet('textRecognition', ergebnis('Boden'));
    await vomGeraet('textRecognition', ergebnis('Boden und Arbeit', endgueltig: true));
    await vomGeraet('notifyStatus', 'notListening');
    await vomGeraet('notifyStatus', 'done');
    expect(texte, ['1~Boden', '1!Boden und Arbeit']);
    expect(enden, 1);

    // Zweite Aufnahme („Weiter sprechen“), mit „Fertig“ beendet: die letzten
    // Worte kommen noch an, ein Ende wird nicht mehr gemeldet.
    texte.clear();
    expect(await starten('2'), isTrue);
    await vomGeraet('notifyStatus', 'listening');
    await vomGeraet('textRecognition', ergebnis('und Kapital'));
    await VoiceService.instance.diktatBeenden();
    expect(aufrufe.last, 'stop');

    // Gleich wieder „Weiter sprechen“: Die neue Aufnahme wartet, bis die
    // vorige ausgeklungen ist – ihr Ende beendet die neue nicht.
    final dritte = starten('3');
    await vomGeraet('textRecognition', ergebnis('und Kapital sind', endgueltig: true));
    await vomGeraet('notifyStatus', 'notListening');
    await vomGeraet('notifyStatus', 'done');
    expect(await dritte, isTrue);
    expect(texte, ['2~und Kapital', '2!und Kapital sind']);
    expect(enden, 1);
    await vomGeraet('notifyStatus', 'listening');
    await vomGeraet('textRecognition', ergebnis('Produktionsfaktoren'));
    expect(texte.last, '3~Produktionsfaktoren');
    await vomGeraet('notifyStatus', 'notListening');
    await vomGeraet('textRecognition', ergebnis('Produktionsfaktoren', endgueltig: true));
    await vomGeraet('notifyStatus', 'done');
    expect(enden, 2);
  });

  test('Kein Mikrofonrecht: Fehler kommt an und beendet die Sitzung', () async {
    final fehler = <String>[];
    var enden = 0;
    await VoiceService.instance.diktatStarten(
      onText: (_, __) {},
      onEnde: () => enden++,
      onFehler: fehler.add,
    );
    await vomGeraet('notifyError', jsonEncode({'errorMsg': 'error_permission', 'permanent': true}));
    expect(fehler, ['error_permission']);
    expect(enden, 1);
  });
}
