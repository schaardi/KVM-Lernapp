import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Sprachbedienung: Vorlesen (TTS) + Antwort per A/B/C/D (native Spracherkennung)
/// und freies Diktat fürs mündliche Üben. Läuft nativ auf Android (anders als
/// im Web).
class VoiceService {
  static final VoiceService instance = VoiceService._();
  VoiceService._();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  bool _ttsReady = false;
  bool _sttAvailable = false;
  bool enabled = false;

  // Laufendes Diktat (Mündlich üben)
  void Function()? _diktatEnde;
  Timer? _endeTimer;
  // Hat die laufende Aufnahme „listening“ gemeldet? Vorher eintreffende
  // Meldungen und Ergebnisse stammen noch von der vorigen Aufnahme.
  bool _diktatHoert = false;
  // Eine gerade beendete Aufnahme liefert ihre letzten Worte und „done“ noch
  // nach; bis dahin wartet eine neue kurz, sonst mischen sie sich.
  Completer<void>? _ausklang;

  Future<void> init() async {
    try {
      await _tts.setLanguage('de-DE');
      await _tts.setSpeechRate(0.5);
      await _tts.awaitSpeakCompletion(true);
      _ttsReady = true;
    } catch (_) {}
    try {
      _sttAvailable = await _stt.initialize(onStatus: _status, onError: _fehler);
    } catch (_) {
      _sttAvailable = false;
    }
  }

  bool get sttAvailable => _sttAvailable;

  /// Kann die App vorlesen?
  bool get ttsAvailable => _ttsReady;

  Future<void> speak(String text) async {
    if (!_ttsReady) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  /// Vorlesen und Zuhören beenden (auch ein laufendes Diktat).
  Future<void> stop() async {
    try {
      if (_ttsReady) await _tts.stop();
    } catch (_) {}
    await diktatBeenden();
  }

  /// Hört einmal zu und liefert den erkannten Buchstaben A/B/C/D (oder null).
  Future<void> listenLetter(void Function(String? letter) onDone) async {
    if (!_sttAvailable) {
      onDone(null);
      return;
    }
    try {
      await _stt.listen(
        listenOptions: SpeechListenOptions(partialResults: false, localeId: 'de_DE'),
        onResult: (r) {
          if (r.finalResult) {
            onDone(_parseLetter(r.recognizedWords));
          }
        },
      );
    } catch (_) {
      onDone(null);
    }
  }

  Future<void> stopListening() async {
    try {
      if (_stt.isListening) await _stt.stop();
    } catch (_) {}
  }

  /// Freies Diktat (Mündlich üben): de-DE, fortlaufend, mit Zwischenergebnissen.
  /// Pausen bis etwa 5 s gehen durch; endet die Sitzung, ruft sie [onEnde].
  /// [onText] bekommt den bisher erkannten Text dieser Sitzung und ob er
  /// endgültig ist; [onFehler] den Fehlercode (z. B. `error_permission`).
  /// Gibt `false` zurück, wenn das Zuhören nicht starten konnte.
  Future<bool> diktatStarten({
    required void Function(String text, bool endgueltig) onText,
    required void Function() onEnde,
    required void Function(String fehler) onFehler,
  }) async {
    if (!_sttAvailable) return false;
    await diktatBeenden();
    final ausklang = _ausklang;
    if (ausklang != null && !ausklang.isCompleted) {
      await ausklang.future.timeout(const Duration(milliseconds: 2500), onTimeout: () {});
    }
    _ausklang = null;
    try {
      if (_ttsReady) await _tts.stop();
    } catch (_) {}
    _diktatFehler = onFehler;
    _diktatEnde = onEnde;
    _diktatHoert = false;
    try {
      await _stt.listen(
        onResult: (r) {
          if (_diktatHoert) onText(r.recognizedWords, r.finalResult);
        },
        listenOptions: SpeechListenOptions(
          localeId: 'de_DE',
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          pauseFor: const Duration(seconds: 5),
          listenFor: const Duration(minutes: 5),
        ),
      );
      return true;
    } catch (_) {
      _diktatEnde = null;
      _diktatFehler = null;
      return false;
    }
  }

  /// Diktat beenden – die letzten Worte kommen noch als Ergebnis.
  Future<void> diktatBeenden() async {
    _endeTimer?.cancel();
    _endeTimer = null;
    _diktatEnde = null;
    _diktatFehler = null;
    try {
      if (_stt.isListening) {
        _ausklang = Completer<void>();
        await _stt.stop();
      }
    } catch (_) {}
  }

  void Function(String fehler)? _diktatFehler;

  void _status(String s) {
    if (s == SpeechToText.doneStatus) {
      final a = _ausklang;
      if (a != null && !a.isCompleted) a.complete();
    }
    if (s == SpeechToText.listeningStatus) {
      if (_diktatEnde != null) _diktatHoert = true;
      return;
    }
    if (_diktatEnde == null || !_diktatHoert) return;
    if (s == SpeechToText.doneStatus) {
      _diktatAbschliessen();
    } else if (s == SpeechToText.notListeningStatus) {
      // Kommt „done“ nicht nach, trotzdem abschließen.
      _endeTimer?.cancel();
      _endeTimer = Timer(const Duration(milliseconds: 2500), _diktatAbschliessen);
    }
  }

  void _fehler(SpeechRecognitionError e) {
    _diktatFehler?.call(e.errorMsg);
    if (e.permanent) _diktatAbschliessen();
  }

  void _diktatAbschliessen() {
    _endeTimer?.cancel();
    _endeTimer = null;
    final ende = _diktatEnde;
    _diktatEnde = null;
    _diktatFehler = null;
    ende?.call();
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
