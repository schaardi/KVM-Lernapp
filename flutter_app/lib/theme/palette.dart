import 'package:flutter/material.dart';

/// Farbwelt der App – dieselben Tokens wie die Web-App (`index.html`, `:root`
/// und `[data-theme="dark"]`), damit man beide Seiten nebeneinander lesen kann.
///
/// Die globalen Farbkonstanten in `constants.dart` (`kPaper`, `kInk` …) lesen
/// aus [KvmPalette.current]. Wechselt die Darstellung, setzt die App die neue
/// Palette und baut alle Widgets neu (siehe `main.dart`, `ThemeController`).
///
/// Regel aus FR-002 I: Füllungen (Buttons, aktive Chips, Badges) tragen in
/// beiden Modi weiße Schrift; Akzent-TEXT auf Flächen nimmt den *Ink*-Ton.
class KvmPalette {
  final Brightness brightness;

  // Flächen und Linien
  final Color steel; // Seite
  final Color paper; // Karte
  final Color surface;
  final Color surface2;
  final Color track;
  final Color line;
  final Color lineSoft;
  final Color lineStrong;
  final Color bgTint;

  // Text
  final Color ink;
  final Color inkSoft;
  final Color muted;

  // Akzente
  final Color petrol;
  final Color petrolDeep;
  final Color petrolSoft;
  final Color petrolLine;
  final Color petrolInk;
  final Color petrolInkDeep;
  final Color amber;
  final Color amberDeep;
  final Color amberSoft;
  final Color amberLine;
  final Color amberInk;
  final Color ok;
  final Color okSoft;
  final Color okLine;
  final Color okInk;
  final Color err;
  final Color errSoft;
  final Color errFaint;
  final Color errLine;
  final Color errInk;
  final Color plum;
  final Color plumSoft;
  final Color plumLine;
  final Color plumInk;
  final Color violet;
  final Color violetSoft;
  final Color violetInk;
  final Color blue;
  final Color blueSoft;
  final Color blueInk;
  final Color goldSoft;
  final Color goldLine;
  final Color goldInk;

  // Sonderfälle
  final Color heroFrom;
  final Color heroTo;
  final Color ctaBg;
  final Color ctaInk;
  final Color toggleOff;
  final Color disabled;
  final Color placeholder;

  /// Kartenschatten: im Dunkeln fast unsichtbar, dort tragen die Linien.
  final List<BoxShadow> shadow;

  const KvmPalette({
    required this.brightness,
    required this.steel,
    required this.paper,
    required this.surface,
    required this.surface2,
    required this.track,
    required this.line,
    required this.lineSoft,
    required this.lineStrong,
    required this.bgTint,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.petrol,
    required this.petrolDeep,
    required this.petrolSoft,
    required this.petrolLine,
    required this.petrolInk,
    required this.petrolInkDeep,
    required this.amber,
    required this.amberDeep,
    required this.amberSoft,
    required this.amberLine,
    required this.amberInk,
    required this.ok,
    required this.okSoft,
    required this.okLine,
    required this.okInk,
    required this.err,
    required this.errSoft,
    required this.errFaint,
    required this.errLine,
    required this.errInk,
    required this.plum,
    required this.plumSoft,
    required this.plumLine,
    required this.plumInk,
    required this.violet,
    required this.violetSoft,
    required this.violetInk,
    required this.blue,
    required this.blueSoft,
    required this.blueInk,
    required this.goldSoft,
    required this.goldLine,
    required this.goldInk,
    required this.heroFrom,
    required this.heroTo,
    required this.ctaBg,
    required this.ctaInk,
    required this.toggleOff,
    required this.disabled,
    required this.placeholder,
    required this.shadow,
  });

  bool get isDark => brightness == Brightness.dark;

  /// Aktuell gültige Palette (von `main.dart` gesetzt).
  static KvmPalette current = light;

  static const KvmPalette light = KvmPalette(
    brightness: Brightness.light,
    steel: Color(0xFFEDF1F3),
    paper: Color(0xFFFFFFFF),
    surface: Color(0xFFF6FAFA),
    surface2: Color(0xFFEEF4F5),
    track: Color(0xFFDDE5E8),
    line: Color(0xFFD4DCDF),
    lineSoft: Color(0xFFEEF3F4),
    lineStrong: Color(0xFFB7C3C7),
    bgTint: Color(0xFFE8EFF0),
    ink: Color(0xFF17272E),
    inkSoft: Color(0xFF33454C),
    muted: Color(0xFF5C6B72),
    petrol: Color(0xFF0C6C78),
    petrolDeep: Color(0xFF084F58),
    petrolSoft: Color(0xFFE3F0F1),
    petrolLine: Color(0xFFBCD9DD),
    petrolInk: Color(0xFF0C6C78),
    petrolInkDeep: Color(0xFF084F58),
    amber: Color(0xFFD9820A),
    amberDeep: Color(0xFFA65F00),
    amberSoft: Color(0xFFFBEFD9),
    amberLine: Color(0xFFEDD4A6),
    amberInk: Color(0xFF7A4A00),
    ok: Color(0xFF2C8A4E),
    okSoft: Color(0xFFE4F2E9),
    okLine: Color(0xFFB9DCC5),
    okInk: Color(0xFF226B3C),
    err: Color(0xFFC0472F),
    errSoft: Color(0xFFF7E6E1),
    errFaint: Color(0xFFFDF6F4),
    errLine: Color(0xFFE8BEB2),
    errInk: Color(0xFFA8391F),
    plum: Color(0xFFA2497F),
    plumSoft: Color(0xFFFBF2F8),
    plumLine: Color(0xFFE6C9DE),
    plumInk: Color(0xFF8E3A6C),
    violet: Color(0xFF6D5AE6),
    violetSoft: Color(0xFFEEEBFB),
    violetInk: Color(0xFF4C39C9),
    blue: Color(0xFF3F6FB5),
    blueSoft: Color(0xFFE6EDF8),
    blueInk: Color(0xFF2F5A99),
    goldSoft: Color(0xFFFDF8EC),
    goldLine: Color(0xFFD9C79A),
    goldInk: Color(0xFF8A6D1F),
    heroFrom: Color(0xFF0C6C78),
    heroTo: Color(0xFF08535C),
    ctaBg: Color(0xFFFFFFFF),
    ctaInk: Color(0xFF084F58),
    toggleOff: Color(0xFFC7D0D3),
    disabled: Color(0xFFA9C3C7),
    placeholder: Color(0xFF9FB3B6),
    shadow: [
      BoxShadow(color: Color(0x0F102A32), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x14102A32), blurRadius: 30, offset: Offset(0, 10)),
    ],
  );

  static const KvmPalette dark = KvmPalette(
    brightness: Brightness.dark,
    steel: Color(0xFF0B1417),
    paper: Color(0xFF132024),
    surface: Color(0xFF18282D),
    surface2: Color(0xFF1D3036),
    track: Color(0xFF263A40),
    line: Color(0xFF27393F),
    lineSoft: Color(0xFF1F3035),
    lineStrong: Color(0xFF3A5159),
    bgTint: Color(0xFF10262B),
    ink: Color(0xFFE2EBED),
    inkSoft: Color(0xFFC3D0D4),
    muted: Color(0xFF93A5AB),
    petrol: Color(0xFF0E7C89),
    petrolDeep: Color(0xFF0A5F69),
    petrolSoft: Color(0xFF123A40),
    petrolLine: Color(0xFF1F5A62),
    petrolInk: Color(0xFF6CC7D2),
    petrolInkDeep: Color(0xFFA6E1E8),
    amber: Color(0xFFD9820A),
    amberDeep: Color(0xFFA65F00),
    amberSoft: Color(0xFF35260E),
    amberLine: Color(0xFF6A4A17),
    amberInk: Color(0xFFF2BC6B),
    ok: Color(0xFF2F9455),
    okSoft: Color(0xFF142D1D),
    okLine: Color(0xFF2B5B3B),
    okInk: Color(0xFF7ED39A),
    err: Color(0xFFC8503A),
    errSoft: Color(0xFF381C17),
    errFaint: Color(0xFF2A1A17),
    errLine: Color(0xFF6B3226),
    errInk: Color(0xFFF3A08D),
    plum: Color(0xFFA2497F),
    plumSoft: Color(0xFF2B1824),
    plumLine: Color(0xFF5C2E4A),
    plumInk: Color(0xFFE3A3CB),
    violet: Color(0xFF6D5AE6),
    violetSoft: Color(0xFF221E45),
    violetInk: Color(0xFFBDB2FA),
    blue: Color(0xFF3F6FB5),
    blueSoft: Color(0xFF172538),
    blueInk: Color(0xFFA2C0F2),
    goldSoft: Color(0xFF2E2710),
    goldLine: Color(0xFF6B5B26),
    goldInk: Color(0xFFE3C77A),
    heroFrom: Color(0xFF0D5B65),
    heroTo: Color(0xFF0A3F47),
    ctaBg: Color(0xFFE6F4F6),
    ctaInk: Color(0xFF0A4B53),
    toggleOff: Color(0xFF3A4E55),
    disabled: Color(0xFF2C4A50),
    placeholder: Color(0xFF5E7378),
    shadow: [
      BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 10)),
    ],
  );
}
