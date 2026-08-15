import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../models.dart';
import '../services/progress_service.dart';
import '../services/round_builder.dart';
import '../services/voice_service.dart';
import '../services/ad_service.dart';
import '../services/answer_store.dart';
import '../widgets/calculator.dart';
import '../widgets/drawing_pad.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final RoundMode mode;
  final List<Question> pool;
  final int fach;
  final String sub;
  const QuizScreen({
    super.key,
    required this.mode,
    required this.pool,
    required this.fach,
    required this.sub,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _idx = 0;
  bool _answered = false;
  bool _revealed = false;
  final TextEditingController _eigene = TextEditingController();
  int? _selected; // MC-Auswahlindex
  late final List<List<Opt>> _shuffled;
  late final List<bool?> _results;
  final List<Question> _wrong = [];
  final _calcCtrl = TextEditingController();

  Timer? _timer;
  int _timeLeft = 0;
  bool _voice = false;

  Question get _q => widget.pool[_idx];

  @override
  void initState() {
    super.initState();
    _shuffled = widget.pool.map((q) {
      if (q.type == 'mc') {
        final l = List<Opt>.from(q.o)..shuffle();
        return l;
      }
      return <Opt>[];
    }).toList();
    _results = List<bool?>.filled(widget.pool.length, null);
    if (widget.mode == RoundMode.sim) {
      _timeLeft = kSimSeconds;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() => _timeLeft--);
        if (_timeLeft <= 0) {
          t.cancel();
          _finish(timeUp: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _eigene.dispose();
    _timer?.cancel();
    _calcCtrl.dispose();
    VoiceService.instance.stop();
    super.dispose();
  }

  // ---- Auswertung ----
  void _finalize(bool correct) {
    setState(() {
      _answered = true;
      _results[_idx] = correct;
      if (!correct) _wrong.add(_q);
    });
    ProgressService.instance.record(_q.id, correct);
    AdService.instance.onAnswered();
    if (_voice) _speakFeedback(correct);
  }

  void _checkMc() {
    if (_answered || _selected == null) return;
    final chosen = _shuffled[_idx][_selected!];
    _finalize(chosen.ok);
  }

  double? _parseNum(String s) {
    var t = s.trim().replaceAll(RegExp(r'[^0-9.,\-]'), '');
    if (t.contains(',') && t.contains('.')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else if (t.contains(',')) {
      t = t.replaceAll(',', '.');
    }
    return double.tryParse(t);
  }

  void _checkCalc() {
    if (_answered) return;
    final v = _parseNum(_calcCtrl.text);
    final ans = _q.ans ?? double.nan;
    final tol = (ans.abs() * 0.001).clamp(0.01, double.infinity);
    final correct = v != null && (v - ans).abs() <= tol;
    _finalize(correct);
  }

  String _fmtNum(double x) {
    if (x == x.roundToDouble()) return x.toInt().toString();
    return x.toStringAsFixed(6).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '').replaceAll('.', ',');
  }

  void _next() {
    VoiceService.instance.stop();
    // An diesem natürlichen Übergang ggf. eine Interstitial-Werbung zeigen
    // (alle 10 Fragen, entfällt für Werbefrei-Nutzer).
    AdService.instance.maybeShowInterstitial();
    if (_idx == widget.pool.length - 1) {
      _finish();
    } else {
      setState(() {
        _idx++;
        _answered = false;
        _revealed = false;
        _selected = null;
        _calcCtrl.clear();
      });
      if (_voice) _speakQuestion();
    }
  }

  void _finish({bool timeUp = false}) {
    _timer?.cancel();
    if (timeUp) {
      for (var i = 0; i < widget.pool.length; i++) {
        if (_results[i] == null) {
          _results[i] = false;
          _wrong.add(widget.pool[i]);
          ProgressService.instance.record(widget.pool[i].id, false);
        }
      }
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ResultScreen(
        mode: widget.mode,
        pool: widget.pool,
        results: _results,
        wrong: _wrong,
        timeUp: timeUp,
      ),
    ));
  }

  // ---- Sprachbedienung ----
  void _toggleVoice() {
    setState(() => _voice = !_voice);
    if (_voice) {
      _speakQuestion();
    } else {
      VoiceService.instance.stop();
    }
  }

  Future<void> _speakQuestion() async {
    final v = VoiceService.instance;
    final letters = ['A', 'B', 'C', 'D'];
    var text = _q.q;
    if (_q.type == 'mc') {
      final opts = _shuffled[_idx];
      text += '. Antwortmöglichkeiten. ';
      for (var i = 0; i < opts.length; i++) {
        text += '${letters[i]}: ${opts[i].t}. ';
      }
      text += 'Sage A, B, C oder D.';
    }
    await v.speak(text);
    if (!_voice || !mounted) return;
    if (_q.type == 'mc' && v.sttAvailable) {
      v.listenLetter((letter) {
        if (!mounted || !_voice || _answered) return;
        if (letter != null) {
          final i = letters.indexOf(letter);
          if (i >= 0 && i < _shuffled[_idx].length) {
            setState(() => _selected = i);
            _checkMc();
          }
        }
      });
    }
  }

  Future<void> _speakFeedback(bool correct) async {
    var t = correct ? 'Richtig. ' : 'Leider falsch. ';
    if (_q.type == 'calc') t += 'Die Lösung ist ${_fmtNum(_q.ans ?? 0)} ${_q.unit}. ';
    if (_q.e.isNotEmpty) t += _q.e;
    await VoiceService.instance.speak(t);
  }

  @override
  Widget build(BuildContext context) {
    final last = _idx == widget.pool.length - 1;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPaper,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _timer?.cancel();
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_q.f}. ${kFachKurz[_q.f]}',
                style: const TextStyle(fontSize: 12, color: kPetrol, fontWeight: FontWeight.w700)),
            Text(
              _q.caseCtx != null
                  ? 'Teil ${_q.caseCtx!.step}/${_q.caseCtx!.total}'
                  : 'Frage ${_idx + 1}/${widget.pool.length}',
              style: const TextStyle(fontSize: 13, color: kInk),
            ),
          ],
        ),
        actions: [
          if (widget.mode == RoundMode.sim)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${(_timeLeft ~/ 60).toString().padLeft(2, '0')}:${(_timeLeft % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _timeLeft <= 120 ? kErr : kInk),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Sprachbedienung',
            icon: Icon(_voice ? Icons.mic : Icons.mic_none, color: _voice ? kDue : kMuted),
            onPressed: _toggleVoice,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _progressBar(),
          const SizedBox(height: 14),
          if (_q.caseCtx != null) _caseBanner(),
          if (_q.type == 'open')
            _openChat()
          else ...[
            Row(children: [
              _typeTag(),
              const SizedBox(width: 8),
              Expanded(child: Text(_q.sub, style: const TextStyle(color: kMuted, fontSize: 12))),
            ]),
            const SizedBox(height: 10),
            ..._taskText(),
            if (_q.tab != null) _anlage(_q.tab!),
            const SizedBox(height: 16),
            if (_q.type == 'mc') ..._mcOptions(),
            if (_q.type == 'calc') _calcInput(),
          ],
          if (_answered) _feedback(),
          const SizedBox(height: 16),
          _actions(last),
        ],
      ),
    );
  }

  Widget _progressBar() {
    return Row(
      children: List.generate(widget.pool.length, (i) {
        Color c = kLine;
        if (i == _idx) {
          c = kPetrol;
        } else if (_results[i] == true) {
          c = kOk;
        } else if (_results[i] == false) {
          c = kErr;
        }
        return Expanded(
          child: Container(
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
          ),
        );
      }),
    );
  }

  Widget _caseBanner() {
    final c = _q.caseCtx!;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF2F8),
        border: Border.all(color: const Color(0xFFE6C9DE)),
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: kSoftShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: kFachColor[5], borderRadius: BorderRadius.circular(4)),
            child: const Text('FALLAUFGABE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700, color: kInk))),
        ]),
        const SizedBox(height: 6),
        Text(c.context, style: const TextStyle(fontSize: 14, height: 1.5, color: kInk)),
      ]),
    );
  }

  /// Aufgabenkopf, Ausgangslage und Fragestellung getrennt darstellen – sonst
  /// verschwimmt bei den Original-Prüfungen alles zu einem fetten Textblock.
  List<Widget> _taskText() {
    final t = TaskParts.of(_q.q);
    final frage = Text(t.frage,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, height: 1.3, color: kInk));
    if (t.nr.isEmpty) return [frage];
    return [
      Row(children: [
        Expanded(
          child: Text(t.nr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kInk)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
              color: kPetrolSoft, borderRadius: BorderRadius.circular(20)),
          child: Text(t.pts,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kPetrolDeep)),
        ),
      ]),
      const Divider(height: 18, color: kLine),
      if (t.sit.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.only(left: 12),
          decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: kLine, width: 3))),
          child: Text(t.sit,
              style: const TextStyle(fontSize: 14, height: 1.6, color: kMuted)),
        ),
      frage,
    ];
  }

  /// Anlage (Tabelle) zur Aufgabe – waagerecht scrollbar.
  Widget _anlage(Anlage a) {
    TableRow zeile(List<String> zellen, {bool kopf = false}) => TableRow(
          decoration: kopf ? const BoxDecoration(color: Color(0xFFEEF4F5)) : null,
          children: [
            for (var i = 0; i < zellen.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                child: Text(zellen[i],
                    textAlign: i == 0 ? TextAlign.left : TextAlign.right,
                    style: TextStyle(
                        fontSize: kopf ? 11.5 : 13,
                        fontWeight: (kopf || i == 0) ? FontWeight.w700 : FontWeight.w400,
                        color: kopf ? kPetrolDeep : kInk)),
              ),
          ],
        );
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFD),
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a.titel.toUpperCase(),
            style: const TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: .8, color: kPetrol)),
        const SizedBox(height: 9),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 420),
            child: Table(
              border: TableBorder.all(color: kLine),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                if (a.kopf.isNotEmpty) zeile(a.kopf, kopf: true),
                for (final r in a.zeilen) zeile(r),
              ],
            ),
          ),
        ),
        if (a.hinweis.isNotEmpty) ...[
          const SizedBox(height: 9),
          Text(a.hinweis, style: const TextStyle(fontSize: 11.5, height: 1.45, color: kMuted)),
        ],
      ]),
    );
  }

  Widget _typeTag() {
    final (label, color) = switch (_q.type) {
      'mc' => ('Auswahlfrage', kPetrol),
      'calc' => ('Rechenaufgabe', kAmber),
      _ => ('Offene Frage', kMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  List<Widget> _mcOptions() {
    final letters = ['A', 'B', 'C', 'D', 'E'];
    final opts = _shuffled[_idx];
    return List.generate(opts.length, (i) {
      final o = opts[i];
      Color border = kLine;
      Color bg = kPaper;
      if (_answered) {
        if (o.ok) {
          border = kOk;
          bg = kOkSoft;
        } else if (_selected == i) {
          border = kErr;
          bg = kErrSoft;
        } else if (o.w != null) {
          border = const Color(0xFFE3B4A8);
          bg = const Color(0xFFFDF6F4);
        }
      } else if (_selected == i) {
        border = kPetrol;
        bg = kPetrolSoft;
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: InkWell(
          onTap: _answered ? null : () => setState(() => _selected = i),
          borderRadius: BorderRadius.circular(kRadiusSm),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border, width: 1.5),
              borderRadius: BorderRadius.circular(kRadiusSm),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      border: Border.all(color: kLine), borderRadius: BorderRadius.circular(6)),
                  child: Text(letters[i], style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 12, color: kMuted)),
                ),
                const SizedBox(width: 11),
                Expanded(child: Text(o.t, style: const TextStyle(fontSize: 14.5, color: kInk))),
              ]),
              if (_answered && !o.ok && o.w != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 6),
                  child: Container(
                    padding: const EdgeInsets.only(left: 10),
                    decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: kErr, width: 2))),
                    child: Text(o.w!, style: const TextStyle(fontSize: 12, color: kMuted, height: 1.4)),
                  ),
                ),
            ]),
          ),
        ),
      );
    });
  }

  Widget _calcInput() {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _calcCtrl,
          enabled: !_answered,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: InputDecoration(
            hintText: 'Ergebnis …',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
            isDense: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      if (_q.unit.isNotEmpty) ...[
        const SizedBox(width: 8),
        Text(_q.unit, style: const TextStyle(fontWeight: FontWeight.w700, color: kMuted)),
      ],
    ]);
  }

  static const _amberSoft = Color(0xFFFBEFD9);

  Widget _msgRole(String label, Color c) => Text(label.toUpperCase(),
      style: TextStyle(
          fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c));

  /// Offene Prüfungsaufgabe als Chat: Prüfer-Nachricht, dann – nach dem Abgeben –
  /// die eigene Antwort und die Musterlösung als Blasen.
  Widget _openChat() {
    final gespeichert = AnswerStore.instance.get(_q.id);
    if (_eigene.text != gespeichert) _eigene.text = gespeichert;
    final t = TaskParts.of(_q.q);
    final ans = gespeichert.trim();
    final w = MediaQuery.of(context).size.width;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Prüfer-Blase (eingehend)
      Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: w * 0.92),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: kPaper,
              border: Border.all(color: kLine),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(5)),
              boxShadow: kSoftShadow,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _msgRole('Prüfer', kPetrol),
              const SizedBox(height: 7),
              if (t.nr.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(t.nr,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: kInk)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: kPetrolSoft,
                            borderRadius: BorderRadius.circular(5)),
                        child: Text(t.pts,
                            style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: kPetrolDeep)),
                      ),
                      if (_q.caseCtx != null)
                        Text('Teil ${_q.caseCtx!.step}/${_q.caseCtx!.total}',
                            style:
                                const TextStyle(fontSize: 10, color: kMuted)),
                    ],
                  ),
                ),
              if (t.sit.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.only(left: 10),
                  decoration: const BoxDecoration(
                      border: Border(
                          left: BorderSide(color: Color(0xFFB7C3C7), width: 2))),
                  child: Text(t.sit,
                      style: const TextStyle(
                          fontSize: 13, height: 1.55, color: kMuted)),
                ),
              Text(t.frage,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: kInk)),
              if (_q.tab != null)
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _anlage(_q.tab!)),
              if (_q.bild != null) _bild(_q.bild!),
            ]),
          ),
        ),
      ),
      if (_revealed) ...[
        const SizedBox(height: 12),
        // Eigene Antwort (ausgehend)
        Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: w * 0.92),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: const BoxDecoration(
                color: kPetrol,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(5)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _msgRole('Deine Antwort', const Color(0xFFBFE3E6)),
                const SizedBox(height: 6),
                Text(ans.isEmpty ? '— leer abgegeben —' : ans,
                    style: TextStyle(
                        color: Colors.white,
                        height: 1.5,
                        fontSize: 14,
                        fontStyle:
                            ans.isEmpty ? FontStyle.italic : FontStyle.normal)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Musterlösung (eingehend, hervorgehoben)
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: w * 0.94),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: _amberSoft,
                border: Border.all(color: kAmber),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _msgRole('Musterlösung · nicht amtlich', const Color(0xFF7A4A00)),
                const SizedBox(height: 7),
                Text(_q.a ?? _q.e,
                    style: const TextStyle(
                        height: 1.55, color: kInk, fontSize: 14)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _exportAufgabe,
            style: OutlinedButton.styleFrom(
                foregroundColor: kPetrol,
                side: const BorderSide(color: kLine),
                padding: const EdgeInsets.symmetric(vertical: 12)),
            icon: const Icon(Icons.content_copy, size: 16),
            label: const Text('Diese Aufgabe von Claude prüfen lassen',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          ),
        ),
        if (_q.maxPoints > 0) ...[
          const SizedBox(height: 14),
          _scoreSelector(),
        ],
      ] else ...[
        const SizedBox(height: 14),
        _composer(),
      ],
    ]);
  }

  /// Selbstbewertung: erreichte Punkte antippen, damit am Ende der Prüfung ein
  /// echtes Punkte-Ergebnis herauskommt.
  Widget _scoreSelector() {
    final max = _q.maxPoints;
    final cur = AnswerStore.instance.points(_q.id);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: kPaper,
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Wie viele Punkte hättest du bekommen?',
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: kInk)),
        const SizedBox(height: 11),
        Wrap(spacing: 7, runSpacing: 7, children: [
          for (var p = 0; p <= max; p++) _scoreChip(p, cur == p),
        ]),
        const SizedBox(height: 9),
        Text(
          cur != null
              ? 'Bewertet: $cur von $max Punkten'
              : 'Vergib dir 0–$max Punkte – so zählt die Aufgabe am Ende '
                  'zum Gesamtergebnis.',
          style: const TextStyle(fontSize: 12, color: kMuted, height: 1.4),
        ),
      ]),
    );
  }

  Widget _scoreChip(int p, bool sel) {
    return InkWell(
      onTap: () => setState(() => AnswerStore.instance.setPoints(_q.id, p)),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        constraints: const BoxConstraints(minWidth: 40),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? kPetrol : Colors.white,
          border: Border.all(color: sel ? kPetrol : kLine),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text('$p',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: sel ? Colors.white : kInk)),
      ),
    );
  }

  /// Bild-Anlage (data-URI) in der Prüfer-Blase – z. B. ein Diagramm.
  Widget _bild(String uri) {
    final komma = uri.indexOf(',');
    if (!uri.startsWith('data:') || komma < 0) return const SizedBox.shrink();
    try {
      final bytes = base64Decode(uri.substring(komma + 1));
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: kLine),
                borderRadius: BorderRadius.circular(10)),
            child: Image.memory(bytes, fit: BoxFit.fitWidth, width: double.infinity),
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _composer() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 1, color: kLine),
      const SizedBox(height: 12),
      _msgRole('Deine Antwort · wie in der Prüfung', kMuted),
      const SizedBox(height: 8),
      TextField(
        controller: _eigene,
        maxLines: null,
        minLines: 4,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(fontSize: 14, height: 1.6, color: kInk),
        onChanged: (v) => AnswerStore.instance.set(_q.id, v),
        decoration: InputDecoration(
          hintText: 'Antwort schreiben …',
          hintStyle: const TextStyle(color: kMuted),
          filled: true,
          fillColor: kPaper,
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kLine)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kLine)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPetrol, width: 1.6)),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              onPressed: _openRechner,
              style: OutlinedButton.styleFrom(
                  foregroundColor: kPetrol, side: const BorderSide(color: kLine)),
              icon: const Icon(Icons.calculate_outlined, size: 17),
              label: const Text('Rechner',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            ),
            OutlinedButton.icon(
              onPressed: _openRechenblatt,
              style: OutlinedButton.styleFrom(
                  foregroundColor: kPetrol, side: const BorderSide(color: kLine)),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Rechenblatt',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            ),
          ]),
          FilledButton.icon(
            onPressed: () {
              AnswerStore.instance.set(_q.id, _eigene.text);
              setState(() => _revealed = true);
            },
            style: FilledButton.styleFrom(
                backgroundColor: kPetrol,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Senden',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    ]);
  }

  void _openRechenblatt() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kPaper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(children: [
                  Text('Rechenblatt',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: kInk)),
                ]),
              ),
              const Expanded(child: DrawingPad()),
            ]),
          ),
        ),
      ),
    );
  }

  void _openRechner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kPaper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: const SizedBox(height: 460, child: CalculatorSheet()),
        ),
      ),
    );
  }

  Future<void> _exportAufgabe() async {
    await Clipboard.setData(ClipboardData(text: AnswerStore.exportTask(_q)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aufgabe mit deiner Antwort kopiert – jetzt in einen '
            'Claude-Chat einfügen.')));
  }

  Widget _feedback() {
    final ok = _results[_idx] == true;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ok ? kOkSoft : kErrSoft,
        borderRadius: BorderRadius.circular(kRadiusSm),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(ok ? '✓ Richtig' : '✗ Leider falsch',
            style: TextStyle(fontWeight: FontWeight.w800, color: ok ? kOk : kErr, fontSize: 16)),
        const SizedBox(height: 6),
        if (_q.type == 'calc')
          Text('Lösung: ${_fmtNum(_q.ans ?? 0)} ${_q.unit}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
        if (_q.e.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_q.e, style: const TextStyle(height: 1.45, color: kInk)),
          ),
      ]),
    );
  }

  Widget _actions(bool last) {
    if (_answered) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kPetrol, padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: _next,
          child: Text(last ? 'Zum Ergebnis →' : 'Weiter →'),
        ),
      );
    }
    if (_q.type == 'mc') {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kPetrol, padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: _selected == null ? null : _checkMc,
          child: const Text('Antwort prüfen'),
        ),
      );
    }
    if (_q.type == 'calc') {
      return Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _finalize(false),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Lösung zeigen'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kPetrol, padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _calcCtrl.text.trim().isEmpty ? null : _checkCalc,
            child: const Text('Antwort prüfen'),
          ),
        ),
      ]);
    }
    // open – Senden liegt im Chat-Composer, hier erst nach dem Abgeben Bewertung
    if (!_revealed) return const SizedBox.shrink();
    // Prüfungsaufgaben mit Punkteangabe: Selbstbewertung statt Gewusst/Nicht.
    if (_q.maxPoints > 0) {
      final scored = AnswerStore.instance.points(_q.id) != null;
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: kPetrol,
              padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: scored ? _commitOpenScore : null,
          child: Text(last ? 'Zum Ergebnis →' : 'Bewertung übernehmen →'),
        ),
      );
    }
    return Row(children: [
      Expanded(
        child: OutlinedButton(
          onPressed: () => _finalize(false),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text('Nicht gewusst'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kOk, padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: () => _finalize(true),
          child: const Text('Gewusst'),
        ),
      ),
    ]);
  }

  /// Übernimmt die selbst vergebenen Punkte als Ergebnis der Aufgabe und geht
  /// weiter. Ab der Hälfte der Punkte gilt die Aufgabe als „gekonnt“.
  void _commitOpenScore() {
    final pts = AnswerStore.instance.points(_q.id);
    if (pts == null) return;
    if (!_answered) {
      final correct = pts * 2 >= _q.maxPoints;
      setState(() {
        _answered = true;
        _results[_idx] = correct;
        if (!correct) _wrong.add(_q);
      });
      ProgressService.instance.record(_q.id, correct);
      AdService.instance.onAnswered();
    }
    _next();
  }
}
