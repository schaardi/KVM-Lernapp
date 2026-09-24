import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/ui.dart';

/// Gemeinsame Bausteine von Aufgabenblatt, Prüfungsliste und Ergebnis.

/// Art eines Zielfelds für „Übernehmen“ (FR-005 D): bestimmt Beschriftung
/// und Zahlformat.
enum FeldArt { antwort, rechenweg, tabelle }

/// Das zuletzt fokussierte Eingabefeld im Aufgabenblatt – Ziel für
/// „Übernehmen“ aus Rechner und Formelbuch (FR-002 C, FR-005 D).
/// [gespeichert] sichert eine Änderung von außen und rechnet neu.
class AktivesFeld {
  final TextEditingController controller;
  final VoidCallback gespeichert;

  /// Teilaufgabe, zu der das Feld gehört (für die Rückmeldung „Aufgabe 1 a)“).
  final String? teilId;
  final FeldArt art;

  /// Zeile im Rechenweg (1 = „Z1“).
  final int? zeile;
  const AktivesFeld(this.controller, this.gespeichert, {this.teilId, this.art = FeldArt.antwort, this.zeile});

  /// Dasselbe Feld, einer Teilaufgabe zugeordnet.
  AktivesFeld fuer(String? teil) => AktivesFeld(controller, gespeichert, teilId: teil, art: art, zeile: zeile);

  /// Beschriftung des Rechner-Knopfs „Übernehmen <Ziel>“ wie im Web
  /// (`rkZielText`).
  String get ziel => switch (art) {
        FeldArt.rechenweg =>
          '${leereRechnung ? 'Rechnung in den Rechenweg' : 'in den Rechenweg'}${zeile != null ? ' · Z$zeile' : ''}',
        FeldArt.tabelle => 'in die Tabelle',
        FeldArt.antwort => 'in deine Antwort',
      };

  /// Leere Rechenweg-Zeile: Dort gehört die ganze Rechnung hin („4.400 ÷ 22“),
  /// nicht nur das Ergebnis – der Rechenweg rechnet sie nach.
  bool get leereRechnung => art == FeldArt.rechenweg && controller.text.trim().isEmpty;

  /// Text an der Schreibmarke einsetzen; davor ein Leerzeichen, wenn dort
  /// weder Leerraum noch „(“ steht. In Tabellen ohne Tausenderpunkt und mit
  /// einfachem Minus. Danach leuchtet das Feld kurz auf.
  void einsetzen(String text) {
    if (art == FeldArt.tabelle) text = tabellenWert(text);
    final v = controller.value;
    final sel = v.selection.isValid ? v.selection : TextSelection.collapsed(offset: v.text.length);
    final vor = v.text.substring(0, sel.start);
    final t = (vor.isNotEmpty && !RegExp(r'[\s(]$').hasMatch(vor)) ? ' $text' : text;
    controller.value = v.replaced(sel, t).copyWith(
          selection: TextSelection.collapsed(offset: sel.start + t.length),
        );
    gespeichert();
    aufleuchten(controller);
  }
}

/// Zahl für eine Tabellenzelle: „1.234,5“ → „1234,5“, „−3“ → „-3“ (Web
/// `rkFmt(v, true)`).
String tabellenWert(String text) {
  final t = text.trim().replaceAll('−', '-');
  return RegExp(r'^-?\d{1,3}(\.\d{3})+(,\d+)?$').hasMatch(t) ? t.replaceAll('.', '') : t;
}

/// Feld, das nach „Übernehmen“ kurz aufleuchten soll (Web `calc-flash`).
final ValueNotifier<TextEditingController?> aufleuchtenFeld = ValueNotifier(null);

void aufleuchten(TextEditingController c) {
  aufleuchtenFeld.value = null;
  aufleuchtenFeld.value = c;
}

/// Ring um ein Eingabefeld, der nach „Übernehmen“ 1,4 s lang ausblendet; das
/// Feld rückt dabei in den sichtbaren Bereich – auf dem Handy über den unten
/// angedockten Rechner.
class Aufleuchten extends StatefulWidget {
  final TextEditingController controller;
  final double radius;
  final Widget child;
  const Aufleuchten({super.key, required this.controller, this.radius = 10, required this.child});

  @override
  State<Aufleuchten> createState() => _AufleuchtenState();
}

class _AufleuchtenState extends State<Aufleuchten> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    aufleuchtenFeld.addListener(_pruefen);
  }

  @override
  void dispose() {
    aufleuchtenFeld.removeListener(_pruefen);
    _a.dispose();
    super.dispose();
  }

  void _pruefen() {
    if (aufleuchtenFeld.value != widget.controller || !mounted) return;
    _a.forward(from: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _insBild();
    });
  }

  void _insBild() {
    final box = context.findRenderObject() as RenderBox?;
    // Die senkrechte Seite, nicht der waagerechte Scroller einer Tabelle.
    var s = Scrollable.maybeOf(context);
    while (s != null && s.position.axis == Axis.horizontal) {
      s = Scrollable.maybeOf(s.context);
    }
    final sicht = s?.context.findRenderObject() as RenderBox?;
    if (box == null || sicht == null || !box.attached || !sicht.attached) return;
    final oben = box.localToGlobal(Offset.zero, ancestor: sicht).dy;
    final handy = MediaQuery.sizeOf(context).width < 640;
    final grenze = sicht.size.height * (handy ? 0.4 : 1) - 12;
    if (oben < 8 || oben + box.size.height > grenze) {
      Scrollable.ensureVisible(context,
          alignment: handy ? 0.12 : 0.4, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _a,
        builder: (context, kind) {
          final t = Curves.easeOut.transform(_a.value);
          final an = _a.isAnimating && t < 1;
          return DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: an ? [BoxShadow(color: kPetrol.withValues(alpha: 1 - t), spreadRadius: 3)] : null,
            ),
            child: kind,
          );
        },
        child: widget.child,
      );
}

/// Nachfrage wie `confirm()` im Web: Titel, Text, Bestätigen/Abbrechen.
Future<bool> nachfragen(
  BuildContext context, {
  required String titel,
  String? text,
  String ja = 'OK',
  String nein = 'Abbrechen',
  bool gefaehrlich = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titel),
      content: text == null ? null : Text(text, style: TextStyle(color: kInkSoft, height: 1.45)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(nein)),
        FilledButton(
          style: gefaehrlich ? FilledButton.styleFrom(backgroundColor: kErr) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ja),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Kleine Pille (Punkte, Status) mit Rahmen.
class Pille extends StatelessWidget {
  final String text;
  final Color grund;
  final Color rand;
  final Color schrift;
  final bool mono;
  final double groesse;
  final EdgeInsets padding;
  const Pille(
    this.text, {
    super.key,
    required this.grund,
    required this.rand,
    required this.schrift,
    this.mono = true,
    this.groesse = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: grund,
        border: Border.all(color: rand),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: mono
              ? monoStyle(groesse, color: schrift, weight: FontWeight.w700, spacing: 0).copyWith(height: 1.3)
              : TextStyle(fontSize: groesse, fontWeight: FontWeight.w600, color: schrift, height: 1.2)),
    );
  }
}

/// Kopfzeile eines Blocks in Mono-Großbuchstaben („DEINE ANTWORT“).
Text kopfLabel(String text, {Color? farbe, double groesse = 10.5}) =>
    Text(text.toUpperCase(), style: monoStyle(groesse, color: farbe ?? kMuted, weight: FontWeight.w700, spacing: 0.9));

/// Selbstbewertung einer Teilaufgabe (FR-003 C.7, Web `scoreHTML`): bis 12
/// Punkte eine durchgehende Knopfleiste, darüber ein Schieberegler.
class PunkteWahl extends StatefulWidget {
  final int max;
  final int? wert;
  final ValueChanged<int> onWahl;
  const PunkteWahl({super.key, required this.max, required this.wert, required this.onWahl});

  @override
  State<PunkteWahl> createState() => _PunkteWahlState();
}

class _PunkteWahlState extends State<PunkteWahl> {
  double? _zieht; // Schieberegler: angezeigter Wert, bevor er gesetzt ist

  @override
  Widget build(BuildContext context) {
    final max = widget.max;
    final cur = widget.wert;
    final anzeige = _zieht?.round() ?? cur;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: kopfLabel('Deine Punkte', groesse: 10)),
          Text(anzeige == null ? 'noch nicht bewertet' : '$anzeige von $max',
              style: monoStyle(13,
                  color: anzeige == null ? kMuted : kInk,
                  weight: anzeige == null ? FontWeight.w600 : FontWeight.w700,
                  spacing: 0)),
        ]),
        const SizedBox(height: 9),
        if (max <= 12) _knoepfe(max, cur) else _regler(max, cur),
        const SizedBox(height: 8),
        Text(
          cur != null
              ? 'Zählt so im Gesamtergebnis – ändern jederzeit möglich.'
              : 'Vergleiche mit dem Lösungshinweis und vergib dir 0–$max Punkte.',
          style: TextStyle(fontSize: 11.5, height: 1.45, color: kMuted),
        ),
      ]),
    );
  }

  Widget _knoepfe(int max, int? cur) {
    return LayoutBuilder(builder: (context, c) {
      final n = max + 1;
      final breite = ((c.maxWidth - 4 * (n - 1)) / n).clamp(0.0, 60.0);
      return Row(children: [
        for (var p = 0; p <= max; p++) ...[
          if (p > 0) const SizedBox(width: 4),
          SizedBox(
            width: breite,
            height: 40,
            child: Semantics(
              button: true,
              selected: cur == p,
              label: '$p von $max Punkten',
              child: Material(
                color: cur == p ? kPetrol : (cur != null && p < cur ? kPetrolSoft : kPaper),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: cur == p ? kPetrol : (cur != null && p < cur ? kPetrolLine : kLineStrong)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => widget.onWahl(p),
                  child: Center(
                    child: Text('$p',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: cur == p ? Colors.white : (cur != null && p < cur ? kPetrolInkDeep : kInk))),
                  ),
                ),
              ),
            ),
          ),
        ],
      ]);
    });
  }

  Widget _regler(int max, int? cur) {
    return Column(children: [
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: kPetrol,
          inactiveTrackColor: kTrack,
          thumbColor: kPetrol,
          overlayColor: kPetrol.withValues(alpha: 0.12),
          showValueIndicator: ShowValueIndicator.never,
          trackHeight: 4,
        ),
        child: Slider(
          min: 0,
          max: max.toDouble(),
          divisions: max,
          value: (_zieht ?? (cur ?? 0).toDouble()).clamp(0, max.toDouble()),
          semanticFormatterCallback: (v) => '${v.round()} von $max Punkten',
          onChanged: (v) => setState(() => _zieht = v),
          onChangeEnd: (v) {
            setState(() => _zieht = null);
            widget.onWahl(v.round());
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (final t in ['0', '${(max / 2).round()}', '$max'])
            Text(t, style: monoStyle(10.5, color: kMuted, weight: FontWeight.w600, spacing: 0)),
        ]),
      ),
    ]);
  }
}
