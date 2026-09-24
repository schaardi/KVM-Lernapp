import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants.dart';
import '../features/melden.dart';
import '../lernen/erinnerung_service.dart';
import '../lernen/muendlich_logik.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../services/lerntage_service.dart';
import '../services/progress_service.dart';
import '../services/round_builder.dart';
import '../services/voice_service.dart';
import '../widgets/ui.dart';

/// Mündliche Prüfung üben (FR-011): Die Frage wird vorgelesen, man antwortet
/// frei per Sprache (oder in Stichpunkten), danach kommen die Musterlösung und
/// die Begriffe daraus, die in der Antwort vorkamen – als Hilfe, nicht als
/// Bewertung. Zum Schluss bewertet man sich selbst; der Lernstand zählt wie im
/// Web: „Gewusst“ richtig, „Nicht gewusst“ falsch, „Teilweise“ nur den Lerntag.
class MuendlichScreen extends StatefulWidget {
  final List<Question> pool;
  final int fach;
  final String sub;

  /// Vorlesen und Spracherkennung; ohne Angabe die des Geräts.
  final MuendlichSprache? sprache;
  const MuendlichScreen({super.key, required this.pool, required this.fach, required this.sub, this.sprache});

  @override
  State<MuendlichScreen> createState() => _MuendlichScreenState();
}

enum _Phase { frage, hoeren, gehoert, loesung }

/// Vorlesen und Diktat fürs mündliche Üben – in der App der [VoiceService],
/// in Tests eine Attrappe.
abstract class MuendlichSprache {
  /// Gibt es eine Spracherkennung? Sonst Stichpunkte statt Mikrofon.
  bool get erkennung;

  /// Kann vorgelesen werden? Sonst entfällt „Nochmal vorlesen“.
  bool get vorlesen;

  Future<void> sprechen(String text);
  Future<void> stop();
  Future<bool> diktatStarten({
    required void Function(String text, bool endgueltig) onText,
    required void Function() onEnde,
    required void Function(String fehler) onFehler,
  });
  Future<void> diktatBeenden();
}

class _GeraeteSprache implements MuendlichSprache {
  const _GeraeteSprache();
  VoiceService get _v => VoiceService.instance;
  @override
  bool get erkennung => _v.sttAvailable;
  @override
  bool get vorlesen => _v.ttsAvailable;
  @override
  Future<void> sprechen(String text) => _v.speak(text);
  @override
  Future<void> stop() => _v.stop();
  @override
  Future<bool> diktatStarten({
    required void Function(String text, bool endgueltig) onText,
    required void Function() onEnde,
    required void Function(String fehler) onFehler,
  }) =>
      _v.diktatStarten(onText: onText, onEnde: onEnde, onFehler: onFehler);
  @override
  Future<void> diktatBeenden() => _v.diktatBeenden();
}

/// Hinweis ohne Mikrofonrecht.
const String kKeinMikrofon =
    'Kein Zugriff aufs Mikrofon – erlaube es in den Systemeinstellungen oder schreib deine Antwort unten.';

class _MuendlichScreenState extends State<MuendlichScreen> {
  late final MuendlichSprache _voice = widget.sprache ?? const _GeraeteSprache();
  final _ctrl = TextEditingController();
  int _idx = 0;
  _Phase _phase = _Phase.frage;
  String _basis = ''; // Text vor der laufenden Aufnahme („Weiter sprechen“)
  String _sitzung = ''; // erkannt in der laufenden Aufnahme
  bool _endgueltig = false;
  bool _nachtrag = false; // späte Ergebnisse dürfen das Feld noch füllen
  String? _fehler;
  String _antwort = '';
  late final List<bool?> _results;
  final List<Question> _wrong = [];

  bool get _stt => _voice.erkennung;
  Question get _q => widget.pool[_idx];

  @override
  void initState() {
    super.initState();
    _results = List<bool?>.filled(widget.pool.length, null);
    WidgetsBinding.instance.addPostFrameCallback((_) => _vorlesen());
  }

  @override
  void dispose() {
    _voice.stop();
    _ctrl.dispose();
    super.dispose();
  }

  void _vorlesen() {
    if (mounted) _voice.sprechen(_q.q);
  }

  String _gesamt() => [_basis, _sitzung].where((s) => s.trim().isNotEmpty).join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  // ---- Zuhören ----
  Future<void> _hoeren() async {
    _basis = _ctrl.text.trim();
    _sitzung = '';
    _endgueltig = false;
    _nachtrag = false;
    setState(() {
      _fehler = null;
      _phase = _Phase.hoeren;
    });
    final ok = await _voice.diktatStarten(
      onText: (text, endgueltig) {
        if (!mounted) return;
        setState(() {
          _sitzung = text;
          _endgueltig = endgueltig;
        });
        // Nach „Fertig“ kommen die letzten Worte noch nach.
        if (_phase == _Phase.gehoert && _nachtrag) _feldSetzen(_gesamt());
      },
      onEnde: () {
        if (mounted && _phase == _Phase.hoeren) _zuGehoert();
      },
      onFehler: (f) {
        if (!mounted) return;
        if (f.contains('permission') || f.contains('not-allowed')) setState(() => _fehler = kKeinMikrofon);
      },
    );
    if (!ok && mounted && _phase == _Phase.hoeren) _zuGehoert();
  }

  void _feldSetzen(String t) {
    _ctrl.value = TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }

  void _zuGehoert() {
    _feldSetzen(_gesamt());
    _nachtrag = true;
    setState(() => _phase = _Phase.gehoert);
  }

  void _fertig() {
    _voice.diktatBeenden();
    _zuGehoert();
  }

  void _ohneMikrofon() {
    _feldSetzen(_gesamt());
    setState(() => _phase = _Phase.gehoert);
  }

  void _loesen() {
    _antwort = _ctrl.text.trim();
    _nachtrag = false;
    _voice.stop();
    setState(() => _phase = _Phase.loesung);
  }

  // ---- Selbstcheck ----
  void _bewerten(int wert) {
    final q = _q;
    _results[_idx] = wert == 2;
    if (wert == 2) {
      ProgressService.instance.record(q.id, true);
    } else {
      _wrong.add(q);
      if (wert == 0) {
        ProgressService.instance.record(q.id, false);
      } else {
        // „Teilweise“: Box bleibt, nur der Lerntag zählt.
        LerntageService.instance.zaehlen();
      }
    }
    ErinnerungService.instance.pruefen();
    if (_idx >= widget.pool.length - 1) {
      _voice.stop();
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => MuendlichErgebnis(
          pool: widget.pool,
          results: List.of(_results),
          wrong: List.of(_wrong),
          fach: widget.fach,
          sub: widget.sub,
          sprache: widget.sprache,
        ),
      ));
      return;
    }
    setState(() {
      _idx++;
      _phase = _Phase.frage;
      _basis = '';
      _sitzung = '';
      _antwort = '';
      _fehler = null;
      _nachtrag = false;
      _ctrl.clear();
    });
    _vorlesen();
  }

  void _beenden() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final q = _q;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        _voice.stop();
        AppState.instance.refresh();
      },
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kSurface,
          automaticallyImplyLeading: false,
          titleSpacing: 12,
          shape: Border(bottom: BorderSide(color: kLine)),
          title: Row(children: [
            _iconKnopf(Icons.close, 'Übung beenden', _beenden),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('${kFachKurz[q.f] ?? ''} · mündlich'.toUpperCase(),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: monoStyle(10, color: kPetrolInk, spacing: 1)),
                const SizedBox(height: 2),
                Text('Frage ${_idx + 1}/${widget.pool.length}',
                    style: monoStyle(12.5, color: kInk, weight: FontWeight.w600, spacing: 0)),
              ]),
            ),
          ]),
        ),
        body: Column(children: [
          _protokoll(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _meta(q),
                      const SizedBox(height: 10),
                      Text(q.q, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600, height: 1.45, color: kInk)),
                      if (_voice.vorlesen) _nochmal(),
                      SizedBox(height: _voice.vorlesen ? 6 : 14),
                      ..._bereich(q),
                      const SizedBox(height: 16),
                      _aktionen(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
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

  /// Fortschrittspunkte: aktuell petrol, gewusst grün, sonst rot.
  Widget _protokoll() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(color: kSurface, border: Border(bottom: BorderSide(color: kLine))),
      child: Row(children: [
        for (var i = 0; i < widget.pool.length; i++)
          Expanded(
            child: Container(
              height: 6,
              margin: EdgeInsets.only(right: i == widget.pool.length - 1 ? 0 : 3),
              decoration: BoxDecoration(
                color: i == _idx
                    ? kPetrol
                    : (_results[i] == true ? kOk : (_results[i] == false ? kErr : kTrack)),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _meta(Question q) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: kVioletSoft, borderRadius: BorderRadius.circular(12)),
        child: Text('FACHGESPRÄCH', style: monoStyle(10.5, color: kVioletInk, spacing: 1)),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(q.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: monoStyle(10, color: kMuted, spacing: 0.6)),
      ),
      MeldenKnopf(frageId: q.id, bezug: q.q, kontext: const {'modus': 'scrOral'}, kompakt: true),
    ]);
  }

  Widget _nochmal() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _vorlesen,
        style: TextButton.styleFrom(
          foregroundColor: kVioletInk,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          minimumSize: const Size(0, 36),
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.volume_up_outlined, size: 17),
        label: const Text('Nochmal vorlesen'),
      ),
    );
  }

  Widget _label(String t, {Color? farbe}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t.toUpperCase(), style: monoStyle(12, color: farbe ?? kMuted, weight: FontWeight.w700, spacing: 1)),
      );

  Widget _hinweis(String t, {bool warnung = false}) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Semantics(
          liveRegion: warnung,
          child: Text(t, style: TextStyle(fontSize: 12.5, height: 1.5, color: warnung ? kErrInk : kMuted)),
        ),
      );

  Widget _feld({String? platzhalter}) {
    return TextField(
      controller: _ctrl,
      minLines: 4,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      style: TextStyle(fontSize: 15, height: 1.5, color: kInk),
      onChanged: (_) => _nachtrag = false,
      decoration: InputDecoration(
        hintText: platzhalter,
        hintStyle: TextStyle(color: kPlaceholder),
        filled: true,
        fillColor: kPaper,
        contentPadding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kLineStrong)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kViolet, width: 1.6)),
      ),
    );
  }

  Widget _transkript(Widget inhalt) => Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: kSurface,
          border: Border.all(color: kLine),
          borderRadius: BorderRadius.circular(12),
        ),
        child: inhalt,
      );

  List<Widget> _bereich(Question q) {
    switch (_phase) {
      case _Phase.frage:
        if (_stt) {
          return [
            _hinweis('Antworte frei und vollständig, wie im Fachgespräch vor dem Prüfungsausschuss. '
                'Tippe auf „Fertig“, wenn du fertig bist.'),
          ];
        }
        return [
          _label('Deine Antwort · Stichpunkte'),
          _feld(platzhalter: 'Sprich laut und notiere hier Stichpunkte – oder decke direkt auf.'),
          _hinweis('Spracherkennung gibt es auf diesem Gerät nicht.'),
        ];
      case _Phase.hoeren:
        final zw = _endgueltig ? '' : _sitzung;
        final fest = _endgueltig ? _gesamt() : _basis;
        final basis = TextStyle(fontSize: 15, height: 1.55, color: kInk);
        return [
          _HoerBand(farbe: kVioletInk, flaeche: kVioletSoft, rand: Color.lerp(kVioletSoft, kViolet, 0.25)!),
          const SizedBox(height: 10),
          Semantics(
            liveRegion: true,
            child: _transkript(fest.isEmpty && zw.isEmpty
                ? Text('…', style: basis.copyWith(color: kMuted, fontStyle: FontStyle.italic))
                : Text.rich(TextSpan(style: basis, children: [
                    if (fest.isNotEmpty) TextSpan(text: fest),
                    if (fest.isNotEmpty && zw.isNotEmpty) const TextSpan(text: ' '),
                    if (zw.isNotEmpty) TextSpan(text: zw, style: TextStyle(color: kMuted, fontStyle: FontStyle.italic)),
                  ]))),
          ),
          if (_fehler != null) _hinweis(_fehler!, warnung: true),
        ];
      case _Phase.gehoert:
        return [
          _label(_stt ? 'Deine Antwort · bei Hörfehlern einfach korrigieren' : 'Deine Antwort'),
          _feld(),
          if (_fehler != null) _hinweis(_fehler!, warnung: true),
        ];
      case _Phase.loesung:
        return _loesung(q);
    }
  }

  List<Widget> _loesung(Question q) {
    final quelle = begriffeQuelle(q);
    final begr = begriffe(quelle);
    final treffer = begr.where((w) => begriffGetroffen(w, _antwort)).toList();
    final loesungText = TextStyle(fontSize: 14.5, height: 1.55, color: kInk);
    return [
      _label('Deine Antwort'),
      _transkript(_antwort.isEmpty
          ? Text('— keine Antwort notiert —', style: TextStyle(fontSize: 15, color: kMuted, fontStyle: FontStyle.italic))
          : Text(_antwort, style: TextStyle(fontSize: 15, height: 1.55, color: kInk))),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
        decoration: BoxDecoration(
          color: kOkSoft,
          border: Border.all(color: kOkLine),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label(q.type == 'open' ? 'Musterlösung' : 'Richtige Antwort', farbe: kOkInk),
          if (q.type == 'mc') ...[
            Text(richtigeOption(q), style: loesungText.copyWith(fontWeight: FontWeight.w600)),
            if (q.e.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(q.e, style: loesungText),
            ],
          ] else
            Text(muendlichLoesung(q), style: loesungText),
        ]),
      ),
      if (begr.isNotEmpty) ...[
        const SizedBox(height: 12),
        _antwort.isEmpty
            ? Text('Darauf kommt es an:', style: TextStyle(fontSize: 12.5, color: kInkSoft))
            : Text.rich(
                TextSpan(style: TextStyle(fontSize: 12.5, height: 1.45, color: kInkSoft), children: [
                  const TextSpan(text: 'Begriffe aus der Lösung in deiner Antwort: '),
                  TextSpan(
                      text: '${treffer.length} von ${begr.length}',
                      style: TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                  const TextSpan(text: ' – ein Hinweis, keine Bewertung.'),
                ]),
              ),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final w in begr) _begriff(w, treffer.contains(w)),
        ]),
      ],
    ];
  }

  Widget _begriff(String w, bool ja) => Semantics(
        label: ja ? '$w – in deiner Antwort' : w,
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: ja ? kOkSoft : kPaper,
            border: Border.all(color: ja ? kOk : kLineStrong),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (ja) ...[
              Icon(Icons.check, size: 13, color: kOkInk),
              const SizedBox(width: 3),
            ],
            Text(w, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ja ? kOkInk : kMuted)),
          ]),
        ),
      );

  ButtonStyle _primaer() => FilledButton.styleFrom(
        backgroundColor: kPetrol,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
      );

  ButtonStyle _getoent(Color rand, Color flaeche, Color text, {double seitlich = 10, double schrift = 14.5}) =>
      OutlinedButton.styleFrom(
        foregroundColor: text,
        backgroundColor: flaeche,
        side: BorderSide(color: rand, width: 1.5),
        minimumSize: const Size(0, 48),
        padding: EdgeInsets.symmetric(horizontal: seitlich),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontFamily: 'Inter', fontSize: schrift, fontWeight: FontWeight.w600),
      );

  Widget _aktionen() {
    switch (_phase) {
      case _Phase.frage:
        if (!_stt) {
          return FilledButton(onPressed: _loesen, style: _primaer(), child: const Text('Lösung zeigen'));
        }
        return Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _hoeren,
              style: _primaer(),
              icon: const Icon(Icons.mic, size: 19),
              label: const Text('Antworten'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: _ohneMikrofon,
              style: _getoent(kLineStrong, kPaper, kPetrolInk),
              child: const Text('Ohne Mikrofon'),
            ),
          ),
        ]);
      case _Phase.hoeren:
        return FilledButton(onPressed: _fertig, style: _primaer(), child: const Text('Fertig'));
      case _Phase.gehoert:
        return Row(children: [
          if (_stt) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _hoeren,
                style: _getoent(kLineStrong, kPaper, kPetrolInk),
                child: const Text('Weiter sprechen'),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(child: FilledButton(onPressed: _loesen, style: _primaer(), child: const Text('Lösung zeigen'))),
        ]);
      case _Phase.loesung:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Wie gut war deine Antwort?', style: TextStyle(fontSize: 12.5, height: 1.5, color: kMuted)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _bewerten(0),
                style: _getoent(kErr, kErrSoft, kErrInk, seitlich: 4, schrift: 14),
                child: const Text('Nicht gewusst', textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _bewerten(1),
                style: _getoent(kAmber, kAmberSoft, kAmberInk, seitlich: 4, schrift: 14),
                child: const Text('Teilweise', textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _bewerten(2),
                style: _getoent(kOk, kOkSoft, kOkInk, seitlich: 4, schrift: 14),
                child: const Text('Gewusst', textAlign: TextAlign.center),
              ),
            ),
          ]),
        ]);
    }
  }
}

/// Band „Ich höre zu …“ mit pulsierendem Punkt.
class _HoerBand extends StatefulWidget {
  final Color farbe;
  final Color flaeche;
  final Color rand;
  const _HoerBand({required this.farbe, required this.flaeche, required this.rand});

  @override
  State<_HoerBand> createState() => _HoerBandState();
}

class _HoerBandState extends State<_HoerBand> with SingleTickerProviderStateMixin {
  late final AnimationController _puls =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();

  @override
  void dispose() {
    _puls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: widget.flaeche,
        border: Border.all(color: widget.rand),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        AnimatedBuilder(
          animation: _puls,
          builder: (_, __) {
            // wie Web `vpulse`: groß und blass in der Mitte des Takts
            final t = math.sin(_puls.value * math.pi);
            return Transform.scale(
              scale: 1 + 0.6 * t,
              child: Opacity(
                opacity: 1 - 0.65 * t,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(color: widget.farbe, shape: BoxShape.circle),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        Text('Ich höre zu …', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: widget.farbe)),
      ]),
    );
  }
}

/// Ergebnis „Mündlich üben“: „3 von 10 richtig“ und die Aufschlüsselung nach
/// Themenbereichen – eigener Bildschirm des Pakets „Lernen“.
class MuendlichErgebnis extends StatelessWidget {
  final List<Question> pool;
  final List<bool?> results;
  final List<Question> wrong;
  final int fach;
  final String sub;
  final MuendlichSprache? sprache;
  const MuendlichErgebnis({
    super.key,
    required this.pool,
    required this.results,
    required this.wrong,
    required this.fach,
    required this.sub,
    this.sprache,
  });

  void _zurStartseite(BuildContext context) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    AppState.instance.geheZu(AppSeite.start);
  }

  void _neu(BuildContext context, List<Question> neuerPool) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => MuendlichScreen(pool: neuerPool, fach: fach, sub: sub, sprache: sprache),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final total = pool.length;
    final right = results.where((r) => r == true).length;
    final pct = total == 0 ? 0 : (right / total * 100).round();
    final ring = pct >= 80 ? kOk : (pct >= 50 ? kPetrol : kAmber);
    final fehler = <Question>[];
    for (final q in wrong) {
      if (!fehler.contains(q)) fehler.add(q);
    }
    final subs = <String>[];
    for (final q in pool) {
      if (!subs.contains(q.sub)) subs.add(q.sub);
    }
    subs.sort((a, b) => subOrderIndex(a).compareTo(subOrderIndex(b)));

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) AppState.instance.refresh();
      },
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  Center(
                    child: SizedBox(
                      width: 112,
                      height: 112,
                      child: Stack(alignment: Alignment.center, children: [
                        SizedBox(
                          width: 104,
                          height: 104,
                          child: CircularProgressIndicator(
                            value: pct / 100,
                            strokeWidth: 9,
                            strokeCap: StrokeCap.round,
                            backgroundColor: kTrack,
                            color: ring,
                          ),
                        ),
                        Text('$pct %', style: dispStyle(26)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(child: Text('MÜNDLICH ÜBEN', style: dispStyle(26))),
                  const SizedBox(height: 6),
                  Center(
                    child: Text.rich(
                      TextSpan(style: TextStyle(fontSize: 14.5, color: kMuted), children: [
                        TextSpan(text: '$right', style: TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                        const TextSpan(text: ' von '),
                        TextSpan(text: '$total', style: TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                        const TextSpan(text: ' richtig'),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (subs.isNotEmpty)
                    Karte(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, left: 2),
                          child: Text('Nach Themenbereich',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kInk)),
                        ),
                        for (final s in subs) _zeile(s),
                      ]),
                    ),
                  const SizedBox(height: 20),
                  if (fehler.isNotEmpty) ...[
                    OutlinedButton(
                      onPressed: () => _neu(context, RoundBuilder.gemischt(fehler)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kAmberInk,
                        backgroundColor: kAmberSoft,
                        side: BorderSide(color: kAmber, width: 1.5),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      child: Text('Nur Fehler wiederholen (${fehler.length})'),
                    ),
                    const SizedBox(height: 10),
                  ],
                  FilledButton(
                    onPressed: () {
                      final k = muendlichKandidaten(fach, sub);
                      if (k.length < kMuendlichMindestens) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Für diesen Bereich gibt es noch keine passenden Fragen fürs Fachgespräch.')));
                        return;
                      }
                      _neu(context, muendlichPool(k));
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: kPetrol,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Neue Runde starten'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => _zurStartseite(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kInk,
                      side: BorderSide(color: kLineStrong),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Zur Startseite'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _zeile(String s) {
    final idx = [for (var i = 0; i < pool.length; i++) if (pool[i].sub == s) i];
    final r = idx.where((i) => results[i] == true).length;
    final p = idx.isEmpty ? 0 : (r / idx.length * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(s, style: TextStyle(fontWeight: FontWeight.w600, color: kInk))),
          const SizedBox(width: 8),
          Text('$r/${idx.length} · $p %', style: monoStyle(12, color: kMuted, spacing: 0)),
        ]),
        const SizedBox(height: 5),
        Balken(p / 100, hoehe: 6, farbe: p >= 50 ? kOk : kAmber),
      ]),
    );
  }
}
