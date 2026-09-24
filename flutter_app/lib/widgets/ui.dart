import 'package:flutter/material.dart';
import '../constants.dart';

/// Gemeinsame Bausteine der Startansicht – Schriften und Karten wie im Web
/// (Barlow Condensed für Überschriften, IBM Plex Mono für Labels).

const String kFontDisplay = 'BarlowCondensed';
const String kFontMono = 'IBMPlexMono';

/// Überschrift in Barlow Condensed (Web `--disp`), meist in Großbuchstaben.
TextStyle dispStyle(double size, {Color? color, FontWeight weight = FontWeight.w700, double height = 1.1}) =>
    TextStyle(
      fontFamily: kFontDisplay,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: 0.2,
      color: color ?? kInk,
    );

/// Label in IBM Plex Mono (Eyebrows, Abschnittstitel, Zähler).
TextStyle monoStyle(double size, {Color? color, FontWeight weight = FontWeight.w600, double spacing = 1.2}) =>
    TextStyle(
      fontFamily: kFontMono,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing,
      height: 1.2,
      color: color ?? kMuted,
    );

/// Gruppentitel über einer Karte: Mono 11, Großbuchstaben, rechts optional
/// ein Zusatz in Petrol (FR-003 E).
class Abschnitt extends StatelessWidget {
  final String titel;
  final String? zusatz;
  final Widget? rechts;
  final EdgeInsets padding;
  const Abschnitt(this.titel, {super.key, this.zusatz, this.rechts, this.padding = const EdgeInsets.fromLTRB(4, 18, 4, 8)});

  @override
  Widget build(BuildContext context) {
    final kopf = Text(titel.toUpperCase(), style: monoStyle(11, spacing: 1.3), maxLines: 1, overflow: TextOverflow.ellipsis);
    return Padding(
      padding: padding,
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Mit Zusatz behält die Überschrift ihre Breite; der Zusatz steht
        // rechtsbündig im Rest und kürzt notfalls mit „…“.
        if (zusatz == null)
          Expanded(child: kopf)
        else ...[
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 240), child: kopf),
          const SizedBox(width: 12),
          Expanded(
            child: Text(zusatz!,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPetrolInk)),
          ),
        ],
        if (rechts != null) rechts!,
      ]),
    );
  }
}

/// Weiße Karte mit Rahmen und weichem Schatten (Web `.hcard`).
class Karte extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  const Karte({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.radius = kRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: kLine),
        boxShadow: kSoftShadow,
      ),
      child: child,
    );
  }
}

/// Seitentitel (Display, Großbuchstaben) mit optionalem Zusatz rechts.
class SeitenTitel extends StatelessWidget {
  final String titel;
  final Widget? rechts;
  const SeitenTitel(this.titel, {super.key, this.rechts});

  @override
  Widget build(BuildContext context) {
    final breit = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Text(titel.toUpperCase(),
              style: dispStyle((breit * 0.064).clamp(24.0, 32.0), height: 1.05)),
        ),
        if (rechts != null) rechts!,
      ]),
    );
  }
}

/// Fortschrittsbalken mit runder Spur.
class Balken extends StatelessWidget {
  final double wert;
  final double hoehe;
  final Color? farbe;
  final Color? spur;
  final Gradient? verlauf;
  const Balken(this.wert, {super.key, this.hoehe = 5, this.farbe, this.spur, this.verlauf});

  @override
  Widget build(BuildContext context) {
    final w = wert.isNaN ? 0.0 : wert.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(hoehe),
      child: SizedBox(
        width: double.infinity,
        height: hoehe,
        child: Stack(children: [
          Positioned.fill(child: ColoredBox(color: spur ?? kTrack)),
          FractionallySizedBox(
            widthFactor: w,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: verlauf == null ? (farbe ?? kPetrol) : null,
                gradient: verlauf,
                borderRadius: BorderRadius.circular(hoehe),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Ampel wie im Web: unter 35 % rot, unter 70 % gelb, sonst grün.
enum Ampel { aus, rot, gelb, gruen }

Ampel ampelVon(double? r, {bool begonnen = true}) {
  if (r == null || !begonnen) return Ampel.aus;
  if (r >= 0.7) return Ampel.gruen;
  if (r >= 0.35) return Ampel.gelb;
  return Ampel.rot;
}

const Map<Ampel, String> kAmpelText = {
  Ampel.aus: 'noch nicht begonnen',
  Ampel.rot: 'Grundlagen aufbauen',
  Ampel.gelb: 'auf gutem Weg',
  Ampel.gruen: 'prüfungsreif',
};

/// Ampelpunkt (auf hellen Flächen).
Color ampelFarbe(Ampel a) => switch (a) {
      Ampel.aus => kLineStrong,
      Ampel.rot => const Color(0xFFE8604A),
      Ampel.gelb => const Color(0xFFF3B53C),
      Ampel.gruen => const Color(0xFF46C46F),
    };
