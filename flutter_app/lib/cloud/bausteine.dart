import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/ui.dart';
import 'werte.dart';

/// Bausteine des Vergleichs – Aussehen wie im Web (`.vg-btn`, `.vg-kpi`,
/// `.vg-tabs`, `.vg-einladung`, `.lt-av` …).

/// Fetter Textteil in [absatz].
class F {
  final String text;
  const F(this.text);
}

/// Absatz aus Textteilen; [F] wird fett (wie `<b>` im Web).
Widget absatz(
  List<Object> teile, {
  double groesse = 13.5,
  double hoehe = 1.55,
  Color? farbe,
  Color? fettFarbe,
  TextAlign? ausrichtung,
}) {
  return Text.rich(
    TextSpan(
      style: TextStyle(fontSize: groesse, height: hoehe, color: farbe ?? kInkSoft),
      children: [
        for (final t in teile)
          t is F
              ? TextSpan(text: t.text, style: TextStyle(fontWeight: FontWeight.w700, color: fettFarbe ?? kInk))
              : TextSpan(text: '$t'),
      ],
    ),
    textAlign: ausrichtung,
  );
}

/// Einleitender Text (Web `.vg-lead`).
Widget lead(String t) => absatz([t]);

/// Leiser Hinweis (Web `.vg-hinweis`).
Widget hinweis(List<Object> teile) => absatz(teile, groesse: 11.5, hoehe: 1.5, farbe: kMuted);

/// Fehlerzeile (Web `.vg-fehler`).
Widget fehlerZeile(String t) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(t, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kErrInk)),
    );

/// Unterüberschrift über einer Liste (Web `.h-sub`): Mono, Großbuchstaben,
/// lange Titel brechen um; rechts optional ein Zusatz in Petrol.
Widget unterkopf(String t, {String? zusatz}) => Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
      child: Row(children: [
        Expanded(
          child: Text(t.toUpperCase(),
              maxLines: 2, overflow: TextOverflow.ellipsis, style: monoStyle(11, spacing: 1.3)),
        ),
        if (zusatz != null) ...[
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(zusatz,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPetrolInk)),
          ),
        ],
      ]),
    );

/// Eingabefeld im Stil der App, Platzhalter etwas kleiner (Web `.vg-form input`).
InputDecoration feldStil(String hinweis, {Widget? symbol}) => InputDecoration(
      isDense: true,
      hintText: hinweis,
      hintStyle: TextStyle(fontSize: 13.5, color: kPlaceholder),
      prefixIcon: symbol,
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
    );

/// Eingabefeld mit Knöpfen daneben – auf schmalen Bildschirmen darunter.
class FeldMitKnoepfen extends StatelessWidget {
  final Widget feld;
  final List<Widget> knoepfe;
  const FeldMitKnoepfen({super.key, required this.feld, required this.knoepfe});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth - 110.0 * knoepfe.length >= 170) {
        return Row(children: [
          Expanded(child: feld),
          for (final k in knoepfe) ...[const SizedBox(width: 8), k],
        ]);
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        feld,
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: knoepfe),
      ]);
    });
  }
}

/// Punkteliste mit petrolfarbenen Punkten (Web `.rt-list`).
class Punkte extends StatelessWidget {
  final List<List<Object>> punkte;
  const Punkte(this.punkte, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < punkte.length; i++)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(3, 8, 10, 0),
              child: Container(width: 5, height: 5, decoration: BoxDecoration(color: kPetrol, shape: BoxShape.circle)),
            ),
            Expanded(child: absatz(punkte[i])),
          ]),
        ),
    ]);
  }
}

enum KnopfArt { rand, voll, leise }

/// Knopf wie im Web: umrandet (`.vg-btn`), gefüllt (`.solid`) oder leise (`.leise`).
class VgKnopf extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final KnopfArt art;
  final Color? farbe;
  const VgKnopf(this.text, {super.key, this.onPressed, this.art = KnopfArt.rand, this.farbe});

  @override
  Widget build(BuildContext context) {
    const schrift = TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 13);
    final form = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    return switch (art) {
      KnopfArt.voll => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: kPetrol,
            foregroundColor: Colors.white,
            disabledBackgroundColor: kPetrol.withValues(alpha: 0.55),
            disabledForegroundColor: Colors.white,
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: form,
            textStyle: schrift,
          ),
          child: Text(text),
        ),
      KnopfArt.rand => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: farbe ?? kPetrolInk,
            backgroundColor: kPaper,
            side: BorderSide(color: kLineStrong),
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: form,
            textStyle: schrift,
          ),
          child: Text(text),
        ),
      KnopfArt.leise => TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: farbe ?? kMuted,
            minimumSize: const Size(0, 34),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: schrift.copyWith(fontWeight: FontWeight.w600),
          ),
          child: Text(text),
        ),
    };
  }
}

/// Kennzahl-Kachel (Web `.vg-kpi`, `.lt-kpi`) mit optionalem Balken.
class VgKpi extends StatelessWidget {
  final String wert;
  final String text;
  final double? balken;
  final double wertGroesse;
  const VgKpi({super.key, required this.wert, required this.text, this.balken, this.wertGroesse = 27});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLine),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(wert, style: dispStyle(wertGroesse, color: kPetrolInkDeep, height: 1)),
        const SizedBox(height: 5),
        Text(text, style: TextStyle(fontSize: 11.5, height: 1.4, color: kMuted)),
        if (balken != null) ...[
          const SizedBox(height: 9),
          Balken(balken!, hoehe: 5, verlauf: LinearGradient(colors: [kPetrol, kOk])),
        ],
      ]),
    );
  }
}

/// Kacheln in Reihen gleicher Höhe (Web-Grid mit [spalten] Spalten).
class KpiRaster extends StatelessWidget {
  final List<Widget> kacheln;
  final int spalten;
  final double abstand;
  const KpiRaster({super.key, required this.kacheln, required this.spalten, this.abstand = 8});

  @override
  Widget build(BuildContext context) {
    final reihen = <Widget>[];
    for (var i = 0; i < kacheln.length; i += spalten) {
      final teil = kacheln.sublist(i, (i + spalten).clamp(0, kacheln.length));
      reihen.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var j = 0; j < spalten; j++) ...[
            if (j > 0) SizedBox(width: abstand),
            Expanded(child: j < teil.length ? teil[j] : const SizedBox.shrink()),
          ],
        ]),
      ));
    }
    return Column(children: [
      for (var i = 0; i < reihen.length; i++) ...[
        if (i > 0) SizedBox(height: abstand),
        reihen[i],
      ],
    ]);
  }
}

/// Ein Reiter über der Liste (Pille).
class Reiter {
  final String label;
  final bool gewaehlt;
  final VoidCallback onTap;
  final bool gestrichelt;
  final int? zaehler;
  const Reiter(this.label, {required this.gewaehlt, required this.onTap, this.gestrichelt = false, this.zaehler});
}

/// Reiter als Pillen: waagerecht scrollbar oder – in Dialogen – umbrechend.
class ReiterLeiste extends StatelessWidget {
  final List<Reiter> reiter;
  final bool umbrechen;
  const ReiterLeiste(this.reiter, {super.key, this.umbrechen = false});

  @override
  Widget build(BuildContext context) {
    final pillen = [for (final r in reiter) _pille(r)];
    if (umbrechen) return Wrap(spacing: 6, runSpacing: 6, children: pillen);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (var i = 0; i < pillen.length; i++) ...[if (i > 0) const SizedBox(width: 6), pillen[i]],
      ]),
    );
  }

  Widget _pille(Reiter r) {
    final textFarbe = r.gewaehlt ? Colors.white : (r.gestrichelt ? kPetrolInk : kInk);
    final inhalt = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220, minHeight: 36),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(r.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textFarbe)),
          ),
          if ((r.zaehler ?? 0) > 0) ...[
            const SizedBox(width: 6),
            Zaehler(r.zaehler!),
          ],
        ]),
      ),
    );
    final strich = r.gestrichelt && !r.gewaehlt;
    Widget k = Material(
      color: r.gewaehlt ? kPetrol : kPaper,
      shape: StadiumBorder(
          side: strich ? BorderSide.none : BorderSide(color: r.gewaehlt ? kPetrol : kLineStrong)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: r.onTap, child: inhalt),
    );
    if (strich) k = CustomPaint(foregroundPainter: StrichRahmen(kLineStrong), child: k);
    return Semantics(selected: r.gewaehlt, button: true, child: k);
  }
}

/// Zähler offener Anfragen (Web `.lt-badge`).
class Zaehler extends StatelessWidget {
  final int n;
  const Zaehler(this.n, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: kAmber, borderRadius: BorderRadius.circular(9)),
      child: Text('$n', style: monoStyle(11, color: Colors.white, weight: FontWeight.w600, spacing: 0)),
    );
  }
}

/// Gestrichelter Rahmen mit runden Ecken (Web `border-style: dashed`).
class StrichRahmen extends CustomPainter {
  final Color farbe;
  final double? radius;
  const StrichRahmen(this.farbe, {this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius ?? size.height / 2)).deflate(0.5);
    final stift = Paint()
      ..color = farbe
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in (Path()..addRRect(r)).computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7) {
        canvas.drawPath(m.extractPath(d, d + 4), stift);
      }
    }
  }

  @override
  bool shouldRepaint(StrichRahmen alt) => alt.farbe != farbe || alt.radius != radius;
}

/// Band in Bernstein über den Reitern (Web `.vg-einladung`).
class Band extends StatelessWidget {
  final Widget text;
  final List<Widget> knoepfe;
  const Band({super.key, required this.text, this.knoepfe = const []});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: kAmberSoft,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: kAmberLine),
      ),
      child: Row(children: [
        Expanded(child: text),
        for (final k in knoepfe) ...[const SizedBox(width: 8), k],
      ]),
    );
  }
}

/// Leerer Kasten mit gestricheltem Rahmen (Web `.lt-leer`, `.vg-leer`).
class LeerKasten extends StatelessWidget {
  final List<Widget> kinder;
  final bool gestrichelt;
  const LeerKasten({super.key, required this.kinder, this.gestrichelt = true});

  @override
  Widget build(BuildContext context) {
    final inhalt = Container(
      width: double.infinity,
      padding: gestrichelt ? const EdgeInsets.fromLTRB(16, 18, 16, 18) : const EdgeInsets.all(12),
      decoration: gestrichelt
          ? null
          : BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: kLine)),
      child: Column(children: [
        for (var i = 0; i < kinder.length; i++) ...[if (i > 0) const SizedBox(height: 10), kinder[i]],
      ]),
    );
    if (!gestrichelt) return inhalt;
    return CustomPaint(foregroundPainter: StrichRahmen(kLineStrong, radius: 12), child: inhalt);
  }
}

/// Text in einem leeren Kasten (zentriert, leise).
Widget leerText(String t) =>
    Text(t, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.5, color: kMuted));

/// Rundes Kürzel mit Farbe aus dem Namen – Profilbilder gibt es bewusst nicht.
class Kuerzel extends StatelessWidget {
  final String name;
  final double groesse;
  const Kuerzel(this.name, {super.key, this.groesse = 38});

  @override
  Widget build(BuildContext context) {
    // Farbe wie im Web `hsl(h 40% 40%)`, in beiden Darstellungen gleich.
    final farbe = HSLColor.fromAHSL(1, farbton(name).toDouble(), 0.4, 0.4).toColor();
    return ExcludeSemantics(
      child: Container(
        width: groesse,
        height: groesse,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: farbe, shape: BoxShape.circle),
        child: Text(kuerzel(name),
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: groesse * 0.35, height: 1, letterSpacing: 0.3)),
      ),
    );
  }
}

/// Rückmeldung als Zeile über dem Inhalt (Web `.lt-meld`).
class Rueckmeldung extends StatelessWidget {
  final String text;
  final bool ok;
  const Rueckmeldung(this.text, {super.key, this.ok = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: ok ? kOkSoft : kErrSoft, borderRadius: BorderRadius.circular(10)),
      child: Semantics(
        liveRegion: true,
        child: Text(text,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: ok ? kOkInk : kErrInk)),
      ),
    );
  }
}

/// Rückfrage vor Austreten, Verlassen, Beenden (Web `confirm`).
Future<bool> bestaetigen(BuildContext context,
    {required String titel, required String text, required String ja}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titel),
      content: Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ja)),
      ],
    ),
  );
  return ok == true;
}

/// Umschalter wie „Darstellung“ im Konto (Web `.seg-ctl`).
class Umschalter<T> extends StatelessWidget {
  final List<(T, String)> werte;
  final T gewaehlt;
  final ValueChanged<T> onWahl;
  const Umschalter({super.key, required this.werte, required this.gewaehlt, required this.onWahl});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: [for (final (w, t) in werte) ButtonSegment<T>(value: w, label: Text(t))],
      selected: {gewaehlt},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onWahl(s.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: kPetrolSoft,
        selectedForegroundColor: kPetrolInkDeep,
        foregroundColor: kInkSoft,
        side: BorderSide(color: kLine),
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 12.5),
      ),
    );
  }
}
