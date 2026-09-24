import 'dart:async';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/ui.dart';
import 'blatt.dart';
import 'melden_dienst.dart';

enum _Status { ok, fehler }

/// Dialog „Fehler melden“ (FR-008, Web `#mMelden`): Bezug mit Nummer und
/// Auszug, „Was stimmt nicht?“ als Auswahl, Beschreibung (optional), Hinweis
/// und „Meldung senden“.
class MeldenDialog extends StatefulWidget {
  final String frageId;
  final String bezug;
  final Map<String, dynamic> kontext;
  const MeldenDialog({super.key, required this.frageId, required this.bezug, this.kontext = const {}});

  @override
  State<MeldenDialog> createState() => _MeldenDialogState();
}

class _MeldenDialogState extends State<MeldenDialog> {
  final _text = TextEditingController();
  String? _art;
  bool _sendet = false;
  bool _fertig = false;
  (String, _Status)? _status;
  Timer? _zu;

  @override
  void dispose() {
    _zu?.cancel();
    _text.dispose();
    super.dispose();
  }

  /// Nummer · Auszug der Frage (160 Zeichen, dahinter „ …“, wenn gekürzt).
  /// Ist der Bezug eine kurze Angabe wie „Aufgabe 2 b)“, steht sie davor.
  String _bezugText() {
    final auszug = MeldenDienst.auszugFuer(widget.frageId, widget.bezug);
    final bezug = widget.bezug.replaceAll(RegExp(r'\s+'), ' ').trim();
    final teile = <String>[
      if (bezug.isNotEmpty && !bezug.startsWith(auszug) && !auszug.startsWith(bezug)) bezug,
      if (auszug.isNotEmpty) auszug.length >= 160 ? '$auszug …' : auszug,
    ];
    return teile.join(' · ');
  }

  Future<void> _senden() async {
    final art = _art;
    if (art == null || _sendet || _fertig) return;
    setState(() {
      _sendet = true;
      _status = null;
    });
    final dienst = MeldenDienst.instance;
    try {
      await dienst.senden(
        frageId: widget.frageId,
        art: art,
        text: _text.text,
        kontext: MeldenDienst.kontextFuer(widget.frageId, extra: widget.kontext, bezug: widget.bezug),
      );
      await dienst.merken(widget.frageId);
      if (!mounted) return;
      setState(() {
        _fertig = true;
        _status = ('Danke! Deine Meldung ist angekommen.', _Status.ok);
      });
      _zu = Timer(const Duration(milliseconds: 1400), () {
        if (mounted && ModalRoute.of(context)?.isCurrent != false) Navigator.of(context).pop();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sendet = false;
        _status = (
          MeldenDienst.istBremse(e)
              ? 'Gerade gehen zu viele Meldungen ein – bitte später noch einmal.'
              : 'Senden hat nicht geklappt. Bist du online? Bitte noch einmal versuchen.',
          _Status.fehler
        );
      });
    }
  }

  Widget _chip(String art, String text) {
    final an = _art == art;
    final r = BorderRadius.circular(999);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: an,
      button: true,
      label: text,
      excludeSemantics: true,
      child: Material(
        color: an ? kPetrol : kPaper,
        shape: RoundedRectangleBorder(borderRadius: r, side: BorderSide(color: an ? kPetrol : kLineStrong)),
        child: InkWell(
          borderRadius: r,
          onTap: _fertig ? null : () => setState(() => _art = art),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 38),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Text(text,
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: an ? Colors.white : kInk)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: kInk);
    final knopfText = _fertig ? 'Gesendet ✓' : (_sendet ? 'Wird gesendet …' : 'Meldung senden');
    final status = _status;
    final bezug = _bezugText();
    final koerper = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: kLine),
            ),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: widget.frageId,
                    style: TextStyle(fontFamily: kFontMono, fontSize: 11.5, fontWeight: FontWeight.w600, color: kInk)),
                if (bezug.isNotEmpty) TextSpan(text: ' · $bezug'),
              ]),
              style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, height: 1.45, color: kInkSoft),
            ),
          ),
          const SizedBox(height: 14),
          Text('Was stimmt nicht?', style: label),
          const SizedBox(height: 7),
          Wrap(spacing: 7, runSpacing: 7, children: [for (final (art, text) in kMeldeArten) _chip(art, text)]),
          const SizedBox(height: 15),
          Text.rich(
            TextSpan(text: 'Beschreibung ', children: [
              TextSpan(text: '· optional', style: TextStyle(fontWeight: FontWeight.w500, color: kMuted)),
            ]),
            style: label,
          ),
          const SizedBox(height: 7),
          TextField(
            controller: _text,
            enabled: !_fertig,
            minLines: 4,
            maxLines: 6,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.45, color: kInk),
            decoration: const InputDecoration(
              hintText: 'Was genau stimmt nicht? Gern mit der richtigen Angabe.',
              counterText: '',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gesendet werden die Fragennummer, deine Angaben und – falls du angemeldet bist – '
            'dein Konto für Rückfragen.',
            style: TextStyle(fontSize: 11.5, height: 1.45, color: kMuted),
          ),
          if (status != null) ...[
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              child: Text(status.$1,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: status.$2 == _Status.ok ? kOkInk : kErrInk)),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _art == null || _sendet || _fertig ? null : _senden,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700),
            ),
            child: Text(knopfText),
          ),
        ],
      ),
    );
    return Material(
      color: kPaper,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BlattKopf('Fehler melden'),
          Flexible(child: SingleChildScrollView(child: koerper)),
        ],
      ),
    );
  }
}

/// Öffnet den Dialog: auf dem Handy als Blatt von unten (Höhe nach Inhalt),
/// breit als Dialog mit 480 Breite.
Future<void> zeigeMeldenDialog(BuildContext context,
    {required String frageId, required String bezug, Map<String, dynamic> kontext = const {}}) {
  final dialog = MeldenDialog(frageId: frageId, bezug: bezug, kontext: kontext);
  if (MediaQuery.sizeOf(context).width > 560) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: dialog),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: kPaper,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: dialog,
    ),
  );
}
