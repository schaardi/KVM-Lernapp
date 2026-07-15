import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Sprachbedienung: Vorlesen (TTS) + Antwort per A/B/C/D (native Spracherkennung).
/// Läuft nativ auf Android (anders als im Web).
class VoiceService {
  static final VoiceService instance = VoiceService._();
  VoiceService._();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  bool _ttsReady = false;
  bool _sttAvailable = false;
  bool enabled = false;

  Future<void> init() async {
    try {
      await _tts.setLanguage('de-DE');
      await _tts.setSpeechRate(0.5);
      await _tts.awaitSpeakCompletion(true);
      _ttsReady = true;
    } catch (_) {}
    try {
      _sttAvailable = await _stt.initialize();
    } catch (_) {
      _sttAvailable = false;
    }
  }

  bool get sttAvailable => _sttAvailable;

  Future<void> speak(String text) async {
    if (!_ttsReady) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    if (_stt.isListening) await _stt.stop();
  }

  /// Hört einmal zu und liefert den erkannten Buchstaben A/B/C/D (oder null).
  Future<void> listenLetter(void Function(String? letter) onDone) async {
    if (!_sttAvailable) {
      onDone(null);
      return;
    }
    await _stt.listen(
      listenOptions: SpeechListenOptions(partialResults: false, localeId: 'de_DE'),
      onResult: (r) {
        if (r.finalResult) {
          onDone(_parseLetter(r.recognizedWords));
        }
      },
    );
  }

  Future<void> stopListening() async {
    if (_stt.isListening) await _stt.stop();
  }

  String? _parseLetter(String text) {
    final t = text.toLowerCase().trim();
    final m = RegExp(r'\b([a-d])\b').firstMatch(t);
    if (m != null) return m.group(1)!.toUpperCase();
    final first = t.replaceAll(RegExp(r'[^a-zäöü0-9]'), ' ').trim().split(RegExp(r'\s+')).first;
    const map = {
      'a': 'A', 'ah': 'A', 'anton': 'A',
      'b': 'B', 'be': 'B', 'bee': 'B', 'berta': 'B',
      'c': 'C', 'ce': 'C', 'zeh': 'C', 'cäsar': 'C', 'see': 'C',
      'd': 'D', 'de': 'D', 'dee': 'D', 'dora': 'D',
      '1': 'A', 'eins': 'A', '2': 'B', 'zwei': 'B', '3': 'C', 'drei': 'C', '4': 'D', 'vier': 'D',
    };
    if (map.containsKey(first)) return map[first];
    if (first.isNotEmpty && 'abcd'.contains(first[0])) return first[0].toUpperCase();
    return null;
  }
}
