import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../util/format.dart';
import '../widgets/ui.dart';
import 'bausteine.dart';
import 'lernende_blatt.dart';
import 'modelle.dart';
import 'rangliste_tabelle.dart';
import 'vergleich_dienst.dart';
import 'werte.dart';

/// Rangliste einer Lerngruppe (FR-010, Web `grAnsichtHTML`): Liste wie die
/// große Rangliste, darunter Code, „Einladen“ und „Gruppe verlassen“.
class GruppenAnsicht extends StatelessWidget {
  final VergleichDienst d;
  const GruppenAnsicht({super.key, required this.d});

  @override
  Widget build(BuildContext context) {
    final g = d.gstand;
    if (g == null) return lead('Gruppe wird geladen …');
    final pm = d.pruefModus;
    final titel = '${g.name} · ${fmtN(g.mitglieder)} ${g.mitglieder == 1 ? 'Mitglied' : 'Mitglieder'} · '
        '${pm ? 'Prüfungen' : kwText(d.kw)}';
    final oeffner = profilOeffner(context, d);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      unterkopf(titel),
      if (pm) ...[
        RanglisteTabelle(
          pruefung: true,
          zeilen: [
            for (final e in pruefSortiert([
              for (final m in g.liste)
                PruefEintrag(
                    name: m.name, n: m.pruefN, ok: m.pruefOk, schnitt: m.pruefSchnitt, chance: m.chance, ich: m.ich),
            ]))
              TabellenZeile.pruef(e),
          ],
          onName: oeffner,
        ),
        const SizedBox(height: 6),
        hinweis([kPruefFussnote]),
      ] else
        RanglisteTabelle(zeilen: [for (final e in g.liste) TabellenZeile.woche(e)], onName: oeffner),
      if (g.mitglieder < 2) ...[
        const SizedBox(height: 6),
        hinweis(['Noch bist du allein in der Gruppe. Lade die anderen aus deinem Kurs mit dem Code ein.']),
      ],
      const SizedBox(height: 10),
      _GruppenFuss(key: ValueKey(g.id), d: d, g: g),
    ]);
  }
}

class _GruppenFuss extends StatefulWidget {
  final VergleichDienst d;
  final GruppenStand g;
  const _GruppenFuss({super.key, required this.d, required this.g});

  @override
  State<_GruppenFuss> createState() => _GruppenFussState();
}

class _GruppenFussState extends State<_GruppenFuss> {
  String? _meld;
  bool _busy = false;

  /// In der App ohne Teilen-Dialog: Text und Link in die Zwischenablage.
  Future<void> _einladen() async {
    final e = einladungFuer(widget.g);
    try {
      await Clipboard.setData(ClipboardData(text: '${e.text}\n${e.link}'));
      if (mounted) setState(() => _meld = 'Einladung kopiert – einfach in euren Chat einfügen.');
    } catch (_) {
      if (mounted) setState(() => _meld = 'Link: ${e.link}');
    }
  }

  Future<void> _verlassen() async {
    final ok = await bestaetigen(context,
        titel: 'Gruppe verlassen?', text: 'Du kannst später mit dem Code wieder beitreten.', ja: 'Gruppe verlassen');
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    await widget.d.gruppeVerlassen();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Code '),
              TextSpan(
                  text: widget.g.code,
                  style: monoStyle(13, color: kInk, weight: FontWeight.w600, spacing: 1.2)),
            ]),
            style: TextStyle(fontSize: 12.5, color: kMuted),
          ),
        ),
        VgKnopf('Einladen', onPressed: _einladen),
        VgKnopf('Gruppe verlassen', art: KnopfArt.leise, onPressed: _busy ? null : _verlassen),
      ]),
      if (_meld != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Semantics(
            liveRegion: true,
            child: Text(_meld!, style: TextStyle(fontSize: 12, color: kOkInk)),
          ),
        ),
    ]);
  }
}

/// Formular „+ Gruppe“ (Web `grFormHTML`): mit Code beitreten oder gründen.
class GruppenFormular extends StatefulWidget {
  const GruppenFormular({super.key});

  @override
  State<GruppenFormular> createState() => _GruppenFormularState();
}

class _Gross extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue alt, TextEditingValue neu) =>
      neu.copyWith(text: neu.text.toUpperCase());
}

class _GruppenFormularState extends State<GruppenFormular> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  bool _busy = false;
  String? _fehler;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _los(Future<String?> Function() aufruf) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _fehler = null;
    });
    final f = await aufruf();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _fehler = f;
    });
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kInk)),
      );

  @override
  Widget build(BuildContext context) {
    final d = VergleichDienst.instance;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _label('Mit Code beitreten'),
      FeldMitKnoepfen(
        feld: TextField(
          controller: _code,
          enabled: !_busy,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
            LengthLimitingTextInputFormatter(9),
            _Gross(),
          ],
          onSubmitted: (_) => _los(() => d.gruppeBeitreten(_code.text)),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kInk),
          decoration: feldStil('z. B. K7M2QX'),
        ),
        knoepfe: [
          VgKnopf('Beitreten',
              art: KnopfArt.voll, onPressed: _busy ? null : () => _los(() => d.gruppeBeitreten(_code.text))),
        ],
      ),
      const SizedBox(height: 12),
      _label('Neue Gruppe gründen'),
      FeldMitKnoepfen(
        feld: TextField(
          controller: _name,
          enabled: !_busy,
          inputFormatters: [LengthLimitingTextInputFormatter(40)],
          onSubmitted: (_) => _los(() => d.gruppeGruenden(_name.text)),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kInk),
          decoration: feldStil('Name, z. B. Meisterkurs Herbst 2026'),
        ),
        knoepfe: [
          VgKnopf('Gründen', onPressed: _busy ? null : () => _los(() => d.gruppeGruenden(_name.text))),
        ],
      ),
      if (_fehler != null) fehlerZeile(_fehler!),
      const SizedBox(height: 8),
      Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
        hinweis([
          'In der Gruppe seht ihr euch gegenseitig mit Spitzname, Antworten dieser Woche und Prüfungsreife – '
              'wie in der großen Rangliste. Wer den Code hat, kann beitreten. ',
        ]),
        VgKnopf('Abbrechen', art: KnopfArt.leise, onPressed: d.gformUmschalten),
      ]),
    ]);
  }
}
