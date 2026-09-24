import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../features/melden.dart';
import '../lernen/erinnerung_service.dart';
import '../lernen/uebernahme.dart';
import '../models.dart';
import '../widgets/anlage_bild.dart';
import '../widgets/ui.dart';
import '../widgets/werkzeug_dock.dart';
import '../services/progress_service.dart';
import '../services/round_builder.dart';
import '../services/voice_service.dart';
import '../services/ad_service.dart';
import '../services/answer_store.dart';
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

  // Ausgangssituation: bei Teil 1 offen, danach zu – außer der Nutzer hat sie
  // selbst auf- oder zugeklappt (Web `ctxOpen`/`ctxTouched`).
  bool _ctxOffen = true;
  bool _ctxBeruehrt = false;

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
    _zaehlen(_q, correct);
    AdService.instance.onAnswered();
    if (_voice) _speakFeedback(correct);
  }

  /// Lernstand und Lerntag zählen; nach der ersten Antwort des Tages plant die
  /// Lern-Erinnerung neu (heute keine mehr).
  void _zaehlen(Question q, bool correct) {
    ProgressService.instance.record(q.id, correct);
    ErinnerungService.instance.pruefen();
  }

  void _checkMc() {
    if (_answered || _selected == null) return;
    final chosen = _shuffled[_idx][_selected!];
    _finalize(chosen.ok);
  }

  void _checkCalc() {
    if (_answered) return;
    final v = zahlLesen(_calcCtrl.text);
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
        if (!_ctxBeruehrt) _ctxOffen = false;
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
          _zaehlen(widget.pool[i], false);
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

  // ---- Werkzeug-Dock: „Übernehmen“ ins aktive Antwortfeld ----

  /// Ziel für Rechner und Formelbuch: das Ergebnisfeld der Rechenfrage oder
  /// die offene Antwort – `null`, solange kein Antwortfeld offen ist.
  void Function(String text)? get _uebernahmeZiel {
    if (_q.type == 'calc' && !_answered) return _inErgebnisfeld;
    if (_q.type == 'open' && !_revealed) return _inAntwort;
    return null;
  }

  void _inErgebnisfeld(String text) {
    if (!mounted || _answered || _q.type != 'calc') return;
    final wert = inErgebnisfeld(text);
    if (wert == null) {
      _inZwischenablage(text);
      return;
    }
    setState(() => _calcCtrl.value = TextEditingValue(text: wert, selection: TextSelection.collapsed(offset: wert.length)));
  }

  void _inAntwort(String text) {
    if (!mounted || _revealed || _q.type != 'open') return;
    final sel = _eigene.selection;
    final r = inAntwort(_eigene.text, text, start: sel.isValid ? sel.start : null, ende: sel.isValid ? sel.end : null);
    AnswerStore.instance.set(_q.id, r.text);
    setState(() => _eigene.value = TextEditingValue(text: r.text, selection: TextSelection.collapsed(offset: r.cursor)));
  }

  /// Eine Formelvorlage passt nicht ins Ergebnisfeld – sie geht wie im Web
  /// ohne passendes Antwortfeld in die Zwischenablage.
  Future<void> _inZwischenablage(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Die Vorlage passt nicht ins Ergebnisfeld – sie liegt jetzt in der Zwischenablage.')));
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

  bool get _istPruefung => _q.caseCtx != null && _q.id.startsWith('P-');

  @override
  Widget build(BuildContext context) {
    final last = _idx == widget.pool.length - 1;
    final tastatur = MediaQuery.viewInsetsOf(context).bottom > 0;
    final fach = _istPruefung ? _q.sub.replaceFirst(RegExp(r'^IHK-Prüfung:\s*'), '') : '${_q.f}. ${kFachKurz[_q.f]}';
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        shape: Border(bottom: BorderSide(color: kLine)),
        title: Row(children: [
          _iconKnopf(Icons.close, 'Runde beenden', () {
            _timer?.cancel();
            Navigator.pop(context);
          }),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(fach.toUpperCase(),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: monoStyle(10, color: kPetrolInk, spacing: 1)),
              const SizedBox(height: 2),
              Text(
                _q.caseCtx != null ? 'Teil ${_q.caseCtx!.step}/${_q.caseCtx!.total}' : 'Frage ${_idx + 1}/${widget.pool.length}',
                style: monoStyle(12.5, color: kInk, weight: FontWeight.w600, spacing: 0),
              ),
            ]),
          ),
          if (widget.mode == RoundMode.sim) _uhr(),
        ]),
      ),
      body: Column(children: [
        _progressBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              if (_q.caseCtx != null) _caseBanner(),
              if (_q.type == 'open')
                _openChat()
              else ...[
                _metaZeile(),
                const SizedBox(height: 10),
                ..._taskText(),
                for (final t in _q.tabsEffektiv) _anlage(t),
                const SizedBox(height: 16),
                if (_q.type == 'mc') ..._mcOptions(),
                if (_q.type == 'calc') _calcInput(),
              ],
              if (_answered) _feedback(),
              const SizedBox(height: 16),
              _actions(last),
            ],
          ),
        ),
      ]),
      // Das Dock reserviert seinen Platz und verdeckt nie „Weiter“; solange
      // die Tastatur offen ist, tritt es zurück.
      bottomNavigationBar: tastatur
          ? null
          : WerkzeugDock(onUebernehmen: _uebernahmeZiel, onSprache: _toggleVoice, spracheAktiv: _voice),
    );
  }

  Widget _iconKnopf(IconData icon, String tip, VoidCallback onTap) => Tooltip(
        message: tip,
        child: Semantics(
          button: true,
          label: tip,
          excludeSemantics: true,
          child: Material(
            color: kPaper,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: kLineStrong)),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 19, color: kMuted)),
            ),
          ),
        ),
      );

  /// Restzeit der Prüfungssimulation (die letzten zwei Minuten rot).
  Widget _uhr() {
    final knapp = _timeLeft <= 120;
    final m = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_timeLeft % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: knapp ? kErrSoft : kPetrolSoft,
        border: Border.all(color: knapp ? kErrLine : kPetrolLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$m:$s', style: monoStyle(14, color: knapp ? kErrInk : kPetrolInkDeep, spacing: 0)),
    );
  }

  /// Fortschritt der Runde: aktuell petrol, richtig grün, falsch rot.
  Widget _progressBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(color: kSurface, border: Border(bottom: BorderSide(color: kLine))),
      child: Row(
        children: List.generate(widget.pool.length, (i) {
          var c = kTrack;
          if (i == _idx) {
            c = kPetrol;
          } else if (_results[i] == true) {
            c = kOk;
          } else if (_results[i] == false) {
            c = kErr;
          }
          return Expanded(
            child: Container(
              height: 6,
              margin: EdgeInsets.only(right: i == widget.pool.length - 1 ? 0 : 3),
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
            ),
          );
        }),
      ),
    );
  }

  /// Ausgangssituation der Fallaufgabe bzw. Prüfung – einklappbar.
  Widget _caseBanner() {
    final c = _q.caseCtx!;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: kPlumSoft,
        border: Border.all(color: kPlumLine),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
          button: true,
          expanded: _ctxOffen,
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => setState(() {
              _ctxOffen = !_ctxOffen;
              _ctxBeruehrt = true;
            }),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
              child: Wrap(spacing: 9, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: kPlum, borderRadius: BorderRadius.circular(4)),
                  child: Text(_istPruefung ? 'IHK-PRÜFUNG' : 'FALLAUFGABE',
                      style: monoStyle(10, color: Colors.white, spacing: 0.8)),
                ),
                Text(c.title.toUpperCase(), style: dispStyle(15)),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 3, 6, 3),
                  decoration: BoxDecoration(
                    color: kPaper,
                    border: Border.all(color: kPlumLine),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('AUSGANGSSITUATION', style: monoStyle(10, color: kPlumInk, spacing: 0.6)),
                    Icon(_ctxOffen ? Icons.arrow_drop_up : Icons.arrow_drop_down, size: 18, color: kPlumInk),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        if (_ctxOffen)
          Container(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: kPlumLine))),
            child: Text(c.context, style: TextStyle(fontSize: 13.5, height: 1.55, color: kInk)),
          ),
      ]),
    );
  }

  /// Fragetyp, Themenbereich und rechts „Fehler melden“.
  Widget _metaZeile() {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      _typeTag(),
      const SizedBox(width: 8),
      Expanded(
        child: Text(_istPruefung ? '' : _q.sub,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: monoStyle(10, color: kMuted, spacing: 0.6)),
      ),
      _melden(),
    ]);
  }

  Widget _melden() => MeldenKnopf(frageId: _q.id, bezug: _q.q, kontext: const {'modus': 'scrQuiz'}, kompakt: true);

  /// Aufgabenkopf, Ausgangslage und Fragestellung getrennt darstellen – sonst
  /// verschwimmt bei den Original-Prüfungen alles zu einem fetten Textblock.
  List<Widget> _taskText() {
    final t = TaskParts.of(_q);
    final frage = Text(t.frage, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600, height: 1.45, color: kInk));
    if (t.nr.isEmpty) return [frage];
    return [
      Row(children: [
        Expanded(child: Text(t.nr.toUpperCase(), style: dispStyle(20))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: kPetrolSoft,
            border: Border.all(color: kPetrolLine),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(t.pts, style: monoStyle(11, color: kPetrolInkDeep, weight: FontWeight.w600, spacing: 0.4)),
        ),
      ]),
      Divider(height: 18, color: kLine),
      if (t.sit.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: kLineStrong, width: 3))),
          child: Text(t.sit, style: TextStyle(fontSize: 14, height: 1.6, color: kMuted)),
        ),
      frage,
    ];
  }

  /// Anlage (Tabelle) zur Aufgabe – waagerecht scrollbar.
  Widget _anlage(Anlage a) {
    TableRow zeile(List<String> zellen, {bool kopf = false}) => TableRow(
          decoration: kopf ? BoxDecoration(color: kSurface2) : null,
          children: [
            for (var i = 0; i < zellen.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                child: Text(zellen[i],
                    textAlign: i == 0 ? TextAlign.left : TextAlign.right,
                    style: TextStyle(
                        fontSize: kopf ? 11.5 : 13,
                        fontWeight: (kopf || i == 0) ? FontWeight.w700 : FontWeight.w400,
                        color: kopf ? kPetrolInkDeep : kInk)),
              ),
          ],
        );
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a.titel.toUpperCase(), style: monoStyle(10.5, color: kPetrolInk, spacing: 0.8)),
        const SizedBox(height: 9),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 380),
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
          Text(a.hinweis, style: TextStyle(fontSize: 11.5, height: 1.45, color: kMuted)),
        ],
      ]),
    );
  }

  /// Typ-Tag: Auswahl petrol, Rechnen blau, offen amber.
  Widget _typeTag() {
    final (label, flaeche, text) = switch (_q.type) {
      'mc' => ('Auswahlfrage', kPetrolSoft, kPetrolInkDeep),
      'calc' => ('Rechenaufgabe', kBlueSoft, kBlueInk),
      _ => ('Offene Frage', kAmberSoft, kAmberInk),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: flaeche, borderRadius: BorderRadius.circular(12)),
      child: Text(label.toUpperCase(), style: monoStyle(10.5, color: text, spacing: 1)),
    );
  }

  /// Antwortoptionen: Der Buchstabe färbt sich mit dem Zustand, die
  /// Begründung steht bündig unter dem Optionstext (FR-002 D).
  List<Widget> _mcOptions() {
    const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    final opts = _shuffled[_idx];
    return List.generate(opts.length, (i) {
      final o = opts[i];
      final gewaehlt = _selected == i;
      var rahmen = kLineStrong;
      var flaeche = kPaper;
      Color? badge; // gefüllter Buchstabe
      var badgeRand = kLineStrong;
      var badgeText = kMuted;
      var blass = false;
      if (_answered) {
        if (o.ok) {
          rahmen = kOk;
          flaeche = kOkSoft;
          badge = kOk;
        } else if (gewaehlt) {
          rahmen = kErr;
          flaeche = kErrSoft;
          badge = kErr;
        } else if (o.w != null) {
          rahmen = kErrLine;
          flaeche = kErrFaint;
          badgeRand = kErrLine;
          badgeText = kErrInk;
        } else {
          blass = true;
        }
      } else if (gewaehlt) {
        rahmen = kPetrol;
        flaeche = kPetrolSoft;
        badge = kPetrol;
      }
      final begruendung = _answered && !o.ok && o.w != null;
      final zustand = !_answered
          ? (gewaehlt ? ', gewählt' : '')
          : (o.ok ? ', richtig' : (gewaehlt ? ', gewählt, falsch' : ''));
      return Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Opacity(
          opacity: blass ? 0.5 : 1,
          child: Semantics(
            button: !_answered,
            selected: gewaehlt,
            label: 'Antwort ${letters[i]}$zustand',
            child: Material(
              color: flaeche,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: rahmen, width: 1.5),
              ),
              child: InkWell(
                onTap: _answered ? null : () => setState(() => _selected = i),
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 25,
                          margin: const EdgeInsets.only(top: 1),
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: badge,
                            border: Border.all(color: badge ?? badgeRand),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(letters[i],
                              style: monoStyle(12, color: badge != null ? Colors.white : badgeText, spacing: 0)),
                        ),
                        const SizedBox(width: 11),
                        Expanded(child: Text(o.t, style: TextStyle(fontSize: 14.5, height: 1.4, color: kInk))),
                      ]),
                      if (begruendung)
                        Container(
                          margin: const EdgeInsets.only(top: 6, left: 36),
                          padding: const EdgeInsets.only(left: 11),
                          decoration: BoxDecoration(border: Border(left: BorderSide(color: kErr, width: 2))),
                          child: Text(o.w!,
                              style: TextStyle(fontSize: 12.5, height: 1.45, color: gewaehlt ? kInkSoft : kMuted)),
                        ),
                    ]),
                  ),
                ),
              ),
            ),
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
          textAlign: TextAlign.right,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          style: monoStyle(18, color: kInk, weight: FontWeight.w500, spacing: 0),
          decoration: InputDecoration(
            hintText: 'Ergebnis …',
            filled: true,
            fillColor: kPaper,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kLineStrong, width: 1.5)),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kLine, width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPetrol, width: 1.5)),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (_calcCtrl.text.trim().isNotEmpty) _checkCalc();
          },
        ),
      ),
      if (_q.unit.isNotEmpty) ...[
        const SizedBox(width: 10),
        Text(_q.unit, style: dispStyle(20, color: kMuted)),
      ],
    ]);
  }

  Widget _msgRole(String label, Color c) =>
      Text(label.toUpperCase(), style: monoStyle(9.5, color: c, weight: FontWeight.w700, spacing: 1.1));

  /// Offene Prüfungsaufgabe als Chat: Prüfer-Nachricht, dann – nach dem Abgeben –
  /// die eigene Antwort und die Musterlösung als Blasen.
  Widget _openChat() {
    final gespeichert = AnswerStore.instance.get(_q.id);
    if (_eigene.text != gespeichert) _eigene.text = gespeichert;
    final t = TaskParts.of(_q);
    final ans = gespeichert.trim();
    final w = MediaQuery.sizeOf(context).width;

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
              // Offene Fragen zeigen keinen Fragekopf – der Melde-Knopf steht
              // deshalb in der Kopfzeile der Prüfer-Nachricht.
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 24),
                child: Row(children: [
                  Expanded(child: _msgRole('Prüfer', kPetrolInk)),
                  _melden(),
                ]),
              ),
              const SizedBox(height: 7),
              if (t.nr.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(t.nr, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kInk)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: kPetrolSoft, borderRadius: BorderRadius.circular(5)),
                        child: Text(t.pts,
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kPetrolInkDeep)),
                      ),
                      if (_q.caseCtx != null)
                        Text('Teil ${_q.caseCtx!.step}/${_q.caseCtx!.total}', style: TextStyle(fontSize: 10, color: kMuted)),
                    ],
                  ),
                ),
              if (t.sit.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(border: Border(left: BorderSide(color: kLineStrong, width: 2))),
                  child: Text(t.sit, style: TextStyle(fontSize: 13, height: 1.55, color: kMuted)),
                ),
              Text(t.frage, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.5, color: kInk)),
              for (final t in _q.tabsEffektiv) Padding(padding: const EdgeInsets.only(top: 10), child: _anlage(t)),
              _bild(_q.bildEffektiv),
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
              decoration: BoxDecoration(
                color: kPetrol,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(5)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _msgRole('Deine Antwort', Colors.white.withValues(alpha: 0.78)),
                const SizedBox(height: 6),
                Text(ans.isEmpty ? '— leer abgegeben —' : ans,
                    style: TextStyle(
                        color: Colors.white,
                        height: 1.5,
                        fontSize: 14,
                        fontStyle: ans.isEmpty ? FontStyle.italic : FontStyle.normal)),
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
                color: kAmberSoft,
                border: Border.all(color: kAmber),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _msgRole(_q.amtlich ? 'Amtliche Lösungshinweise · IHK' : 'Musterlösung · nicht amtlich', kAmberInk),
                const SizedBox(height: 7),
                Text(_q.a ?? _q.e, style: TextStyle(height: 1.55, color: kInk, fontSize: 14)),
                _bild(_q.bildL, fallbackTitel: 'Lösungsskizze der IHK'),
                if (_q.vo != null && _q.vo!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Text('VO-Bezug: ${_q.vo}',
                        style: TextStyle(fontSize: 11.5, color: kAmberInk, fontWeight: FontWeight.w600)),
                  ),
                if (_q.bewertung.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('Punkteverteilung: ${_q.bewertung.join(' + ')} Punkte',
                        style: TextStyle(fontSize: 11.5, color: kAmberInk, fontWeight: FontWeight.w600)),
                  ),
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
                foregroundColor: kPetrolInk,
                side: BorderSide(color: kLine),
                padding: const EdgeInsets.symmetric(vertical: 12)),
            icon: const Icon(Icons.content_copy, size: 16),
            label: const Text('Diese Aufgabe von Claude prüfen lassen',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 12.5)),
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
        Text('Wie viele Punkte hättest du bekommen?',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kInk)),
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
          style: TextStyle(fontSize: 12, color: kMuted, height: 1.4),
        ),
      ]),
    );
  }

  Widget _scoreChip(int p, bool sel) {
    return InkWell(
      onTap: () => setState(() => AnswerStore.instance.setPoints(_q.id, p)),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? kPetrol : kPaper,
          border: Border.all(color: sel ? kPetrol : kLineStrong),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text('$p', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: sel ? Colors.white : kInk)),
      ),
    );
  }

  /// Bildanlage in der Prüfer- oder Lösungsblase – z. B. ein Diagramm.
  ///
  /// [ref] ist der Schlüssel in anlagen.json. Die Darstellung samt Vollbild
  /// und Zoom steckt in [AnlageBild], damit das Aufgabenblatt dieselbe nutzt.
  Widget _bild(String? ref, {String fallbackTitel = 'Anlage zur Aufgabe'}) =>
      AnlageBild(ref, fallbackTitel: fallbackTitel);

  /// Eingabe der offenen Antwort. Rechner, Rechenblatt und Formelbuch liegen
  /// im Werkzeug-Dock; „Übernehmen“ schreibt hierher.
  Widget _composer() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Divider(height: 1, color: kLine),
      const SizedBox(height: 12),
      _msgRole('Deine Antwort · wie in der Prüfung', kMuted),
      const SizedBox(height: 8),
      TextField(
        controller: _eigene,
        maxLines: null,
        minLines: 4,
        keyboardType: TextInputType.multiline,
        style: TextStyle(fontSize: 14, height: 1.6, color: kInk),
        onChanged: (v) => AnswerStore.instance.set(_q.id, v),
        decoration: InputDecoration(
          hintText: 'Antwort schreiben …',
          filled: true,
          fillColor: kPaper,
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kLine)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kLine)),
          focusedBorder:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPetrol, width: 1.6)),
        ),
      ),
      const SizedBox(height: 10),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: () {
            AnswerStore.instance.set(_q.id, _eigene.text);
            FocusScope.of(context).unfocus();
            setState(() => _revealed = true);
          },
          style: FilledButton.styleFrom(
              backgroundColor: kPetrol,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 13.5)),
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text('Senden'),
        ),
      ),
    ]);
  }

  Future<void> _exportAufgabe() async {
    await Clipboard.setData(ClipboardData(text: AnswerStore.exportTask(_q)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aufgabe mit deiner Antwort kopiert – jetzt in einen '
            'Claude-Chat einfügen.')));
  }

  /// Rückmeldung nach der Antwort: Rahmen und Titel in den Ink-Tönen.
  Widget _feedback() {
    final ok = _results[_idx] == true;
    final text = TextStyle(fontSize: 14, height: 1.45, color: kInk);
    final erklaerung = _q.type == 'open' && ok ? 'Gut. ${_q.e}'.trim() : _q.e;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: ok ? kOkSoft : kErrSoft,
          border: Border.all(color: ok ? kOkLine : kErrLine),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(
            label: ok ? 'Richtig' : 'Leider falsch',
            excludeSemantics: true,
            child: Row(children: [
              Icon(ok ? Icons.check_rounded : Icons.close_rounded, size: 19, color: ok ? kOkInk : kErrInk),
              const SizedBox(width: 6),
              Text(ok ? 'RICHTIG' : 'LEIDER FALSCH', style: dispStyle(17, color: ok ? kOkInk : kErrInk)),
            ]),
          ),
          const SizedBox(height: 5),
          if (_q.type == 'calc')
            Text('Lösung: ${_fmtNum(_q.ans ?? 0)}${_q.unit.isNotEmpty ? ' ${_q.unit}' : ''}',
                style: text.copyWith(fontWeight: FontWeight.w700)),
          if (erklaerung.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: _q.type == 'calc' ? 6 : 0),
              child: Text(erklaerung, style: text),
            ),
        ]),
      ),
    );
  }

  ButtonStyle _primaer() => FilledButton.styleFrom(
        backgroundColor: kPetrol,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
      );

  /// „Nicht gewusst“ rot, „Gewusst“ grün – beide als helle Fläche (Web `.btn-no`/`.btn-ok`).
  ButtonStyle _getoent(Color rand, Color flaeche, Color text) => OutlinedButton.styleFrom(
        foregroundColor: text,
        backgroundColor: flaeche,
        side: BorderSide(color: rand, width: 1.5),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14.5, fontWeight: FontWeight.w600),
      );

  /// Knopftext mit Pfeil wie „Jetzt lernen →“ (Pfeil als Symbol, damit er in
  /// jeder Schrift gleich aussieht).
  Widget _mitPfeil(String text) => Semantics(
        label: '$text →',
        excludeSemantics: true,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(text)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 18),
        ]),
      );

  Widget _actions(bool last) {
    if (_answered) {
      return FilledButton(style: _primaer(), onPressed: _next, child: _mitPfeil(last ? 'Zum Ergebnis' : 'Weiter'));
    }
    if (_q.type == 'mc') {
      return FilledButton(
        style: _primaer(),
        onPressed: _selected == null ? null : _checkMc,
        child: const Text('Antwort prüfen'),
      );
    }
    if (_q.type == 'calc') {
      return Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _finalize(false),
            style: _getoent(kErr, kErrSoft, kErrInk),
            child: const Text('Lösung zeigen'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            style: _primaer(),
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
      return FilledButton(
        style: _primaer(),
        onPressed: scored ? _commitOpenScore : null,
        child: _mitPfeil(last ? 'Zum Ergebnis' : 'Bewertung übernehmen'),
      );
    }
    return Row(children: [
      Expanded(
        child: OutlinedButton(
          onPressed: () => _finalize(false),
          style: _getoent(kErr, kErrSoft, kErrInk),
          child: const Text('Nicht gewusst'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: OutlinedButton(
          onPressed: () => _finalize(true),
          style: _getoent(kOk, kOkSoft, kOkInk),
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
      _zaehlen(_q, correct);
      AdService.instance.onAnswered();
    }
    _next();
  }
}
