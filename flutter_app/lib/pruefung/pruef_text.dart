import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../constants.dart';
import '../widgets/ui.dart';

/// Prüfungstexte strukturiert darstellen (FR-003 A, Web `rtHTML`).
///
/// Die Texte liegen als Klartext vor: Tabellenzeilen als „a | b | c“ (leere
/// Zellen halten ihre Spalte), jede Rechnung auf eigener Zeile, Aufzählungen
/// mit „–“. [ptBloecke] zerlegt sie Zeile für Zeile in Blöcke – Tabellen,
/// Listen, Rechenblöcke, Hinweise, Beschriftungen und Absätze –, [PruefText]
/// zeichnet sie. Die Regeln sind dieselben wie im Web.

/// Ein Block des Prüfungstexts. [abstand]: davor stand eine Leerzeile.
sealed class PtBlock {
  final bool abstand;
  const PtBlock(this.abstand);
}

class PtAbsatz extends PtBlock {
  final String text;
  const PtAbsatz(this.text, super.abstand);
}

/// Eine einzelne Tabellenzeile mit langen Zellen: Fließtext mit „ · “.
class PtZellenAbsatz extends PtBlock {
  final List<String> zellen;
  const PtZellenAbsatz(this.zellen, super.abstand);
}

class PtTabelle extends PtBlock {
  /// Alle Zeilen, auf gleiche Spaltenzahl aufgefüllt (mit Kopf, falls [kopf]).
  final List<List<String>> zeilen;
  final bool kopf;

  /// Je Spalte: überwiegend Zahlen – rechtsbündig, ohne Umbruch.
  final List<bool> zahlSpalte;

  /// Zwei Spalten ohne Kopf: Werteliste („Strecke | 10 km“).
  final bool werteliste;
  const PtTabelle(this.zeilen, this.kopf, this.zahlSpalte, this.werteliste, super.abstand);

  int get spalten => zeilen.isEmpty ? 0 : zeilen.first.length;
  List<List<String>> get koerper => kopf ? zeilen.sublist(1) : zeilen;
}

class PtListe extends PtBlock {
  final List<String> punkte;
  const PtListe(this.punkte, super.abstand);
}

class PtRechenblock extends PtBlock {
  final List<String> zeilen;
  const PtRechenblock(this.zeilen, super.abstand);
}

class PtHinweis extends PtBlock {
  final String praefix;
  final String text;
  const PtHinweis(this.praefix, this.text, super.abstand);
}

class PtBeschriftung extends PtBlock {
  final String text;
  const PtBeschriftung(this.text, super.abstand);
}

// ───────────────────────────── Regeln ─────────────────────────────

final _ptZeile = RegExp(r'\s\|\s|^\|\s|\s\|$');
final _ptZahl = RegExp(r'^[−–+-]?\s?\(?\s?\d');
final _ptKasten = RegExp(r'^[☐□○◯]$');
final _ptListe = RegExp(r'^\s*(?:[–•▪■◦]|-(?=\s))\s+');
final _ptHinweis = RegExp(r'^(?:Hinweise?(?:\s+(?:für|an|zur|zum)\s+[^:]{2,40})?|Achtung|Beachte|Merke)\s*:\s*');
final _ptBeschriftung = RegExp(r'^[^=|]{2,90}:\s*$');
final _ptKlammer = RegExp(r'\([^()]*\)');
final _ptWort = RegExp(r'(?:^|[\s„])[a-zäöüß]{4,}');
final _ptErgebnis = RegExp(r'^\s*([−–+-]?\s?\d(?:[^=();,]|,(?=\d))*)');
final _ptRechenzeichen = RegExp(r'\s[+−–·÷×:/-]\s');

/// Punkteangaben in Klammern („(2 Punkte)“) – werden zur kleinen Marke.
final ptPunkte = RegExp(r'\((?=[^()]*\bPunkte?\b)[^()]{1,160}\)');

bool ptIstTabellenzeile(String l) => _ptZeile.hasMatch(l);
List<String> ptZellen(String l) => l.split('|').map((z) => z.trim()).toList();

/// Zahlzelle: beginnt mit einer Ziffer (auch „−3“, „(2“), höchstens 32 Zeichen.
bool ptIstZahl(String z) => z.length <= 32 && _ptZahl.hasMatch(z);

/// Rechenzeile: hat ein „=“ (oder „⇒“) und ist kein Satz – ein Satz hat viele
/// längere kleingeschriebene Wörter. Klammerzusätze zählen nicht mit.
bool ptIstRechnung(String l) {
  if (!(l.contains('=') || l.contains('⇒')) || l.length > 240) return false;
  return _ptWort.allMatches(l.replaceAll(_ptKlammer, ' ')).length <= 5;
}

/// Eine Rechenzeile, zerlegt für die Anzeige: das Ergebnis hinter dem letzten
/// „=“ wird hervorgehoben – Zahl samt Einheit, bis zu Komma, Semikolon oder
/// Klammer. Steht dahinter noch eine Rechnung, ist es kein Ergebnis.
({String vor, String? ergebnis, String nach}) ptRechnung(String l) {
  final i = l.lastIndexOf('=');
  if (i > 0) {
    final rest = l.substring(i + 1);
    final m = _ptErgebnis.firstMatch(rest);
    if (m != null && m.group(1)!.trim().length <= 40 && !_ptRechenzeichen.hasMatch(m.group(1)!)) {
      return (
        vor: l.substring(0, i + 1),
        ergebnis: m.group(1)!.trim(),
        nach: rest.substring(m.group(0)!.length).replaceFirst(RegExp(r'^\s*(?=[(])'), ' '),
      );
    }
  }
  return (vor: l, ergebnis: null, nach: '');
}

/// Kopfzeile: nur Beschriftungen, darunter Zahlen. Zweispaltige Listen
/// („Strecke | 10 km“) haben keinen Kopf – außer alle Werte darunter sind
/// Zahlen und der Kopf keine. [zeilen] sind schon aufgefüllt.
bool ptKopf(List<List<String>> zeilen, int n) {
  if (zeilen.length < 2) return false;
  final k = zeilen.first.where((z) => z.isNotEmpty).toList();
  if (k.length < 2) return false;
  // Leeres Eckfeld über der Beschriftungsspalte: die Zeile trägt Spaltenköpfe
  // (auch Jahreszahlen oder eine Skala „++ | + | 0 | −“).
  if (zeilen.first.first.isEmpty && k.length == n - 1) return true;
  if (k.any(ptIstZahl)) return false;
  final rest = zeilen.sublist(1);
  // Formular zum Ausfüllen: darunter ist nur die erste Spalte beschriftet,
  // die übrigen Felder sind leer oder Ankreuzkästchen (Checkliste, Matrix).
  if (n >= 3 && rest.every((r) => r.skip(1).every((z) => z.isEmpty || _ptKasten.hasMatch(z)))) return true;
  if (n >= 3) return rest.any((r) => r.skip(1).any(ptIstZahl));
  return zeilen.length >= 3 && rest.every((r) => ptIstZahl(r.length > 1 ? r[1] : ''));
}

PtTabelle _ptTabelle(List<List<String>> roh, bool abstand) {
  var n = 0;
  for (final r in roh) {
    if (r.length > n) n = r.length;
  }
  // Kurze Zeilen hinter der Beschriftung auffüllen: der Wert bleibt so in der
  // letzten Spalte, wo die übrigen Werte stehen.
  final zeilen = [
    for (final r in roh)
      r.length >= n ? r : [r.first, for (var k = r.length; k < n; k++) '', ...r.skip(1)],
  ];
  final kopf = ptKopf(zeilen, n);
  final koerper = kopf ? zeilen.sublist(1) : zeilen;
  final zahl = <bool>[];
  for (var c = 0; c < n; c++) {
    var g = 0, z = 0;
    for (final r in koerper) {
      if (r[c].isNotEmpty) {
        g++;
        if (ptIstZahl(r[c])) z++;
      }
    }
    zahl.add(c > 0 && g > 0 && z >= g * 0.6);
  }
  return PtTabelle(zeilen, kopf, zahl, !kopf && n == 2, abstand);
}

/// Zerlegt einen Prüfungstext in Blöcke (Web `rtHTML`).
List<PtBlock> ptBloecke(String? text) {
  final z = (text ?? '').replaceAll('\r', '').split('\n');
  final b = <PtBlock>[];
  var abstand = false;
  var i = 0;
  bool nimm() {
    final a = abstand;
    abstand = false;
    return a;
  }

  while (i < z.length) {
    final l = z[i];
    if (l.trim().isEmpty) {
      abstand = b.isNotEmpty;
      i++;
      continue;
    }
    if (ptIstTabellenzeile(l)) {
      final zeilen = <List<String>>[];
      while (i < z.length && ptIstTabellenzeile(z[i])) {
        zeilen.add(ptZellen(z[i]));
        i++;
      }
      // Eine einzelne Zeile mit langen Zellen ist Fließtext mit Trennstrich.
      if (zeilen.length == 1 && zeilen.first.any((c) => c.length > 60)) {
        b.add(PtZellenAbsatz(zeilen.first.where((c) => c.isNotEmpty).toList(), nimm()));
        continue;
      }
      b.add(_ptTabelle(zeilen, nimm()));
      continue;
    }
    if (_ptListe.hasMatch(l)) {
      final punkte = <String>[];
      while (i < z.length && _ptListe.hasMatch(z[i])) {
        punkte.add(z[i].replaceFirst(_ptListe, ''));
        i++;
      }
      b.add(PtListe(punkte, nimm()));
      continue;
    }
    if (ptIstRechnung(l)) {
      final zeilen = <String>[];
      while (i < z.length &&
          z[i].trim().isNotEmpty &&
          !ptIstTabellenzeile(z[i]) &&
          !_ptListe.hasMatch(z[i]) &&
          ptIstRechnung(z[i])) {
        zeilen.add(z[i]);
        i++;
      }
      b.add(PtRechenblock(zeilen, nimm()));
      continue;
    }
    final h = _ptHinweis.firstMatch(l);
    if (h != null) {
      b.add(PtHinweis(h.group(0)!.trim(), l.substring(h.group(0)!.length), nimm()));
      i++;
      continue;
    }
    if (_ptBeschriftung.hasMatch(l)) {
      b.add(PtBeschriftung(l.trim(), nimm()));
      i++;
      continue;
    }
    b.add(PtAbsatz(l, nimm()));
    i++;
  }
  return b;
}

/// Der Text aller Blöcke ohne Gestaltung – zum Prüfen, dass beim Zerlegen
/// nichts verloren geht (außer den Aufzählungszeichen und Tabellenstrichen).
String ptKlartext(List<PtBlock> bloecke) {
  final o = StringBuffer();
  for (final b in bloecke) {
    switch (b) {
      case PtAbsatz(:final text):
        o.writeln(text);
      case PtZellenAbsatz(:final zellen):
        o.writeln(zellen.join(' '));
      case PtTabelle(:final zeilen):
        for (final r in zeilen) {
          o.writeln(r.join(' '));
        }
      case PtListe(:final punkte):
        for (final p in punkte) {
          o.writeln(p);
        }
      case PtRechenblock(:final zeilen):
        for (final r in zeilen) {
          final t = ptRechnung(r);
          o.writeln('${t.vor} ${t.ergebnis ?? ''}${t.nach}');
        }
      case PtHinweis(:final praefix, :final text):
        o.writeln('$praefix $text');
      case PtBeschriftung(:final text):
        o.writeln(text);
    }
  }
  return o.toString();
}

// ───────────────────────────── Darstellung ─────────────────────────────

/// Text mit Punkte-Marken: „(2 Punkte)“ wird zur kleinen Goldmarke ohne
/// Klammern.
List<InlineSpan> ptInline(String s, TextStyle stil) {
  final out = <InlineSpan>[];
  var pos = 0;
  for (final m in ptPunkte.allMatches(s)) {
    if (m.start > pos) out.add(TextSpan(text: s.substring(pos, m.start)));
    out.add(WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: _PunkteMarke(m.group(0)!.substring(1, m.group(0)!.length - 1), (stil.fontSize ?? 14) * 0.74),
    ));
    pos = m.end;
  }
  if (pos < s.length) out.add(TextSpan(text: s.substring(pos)));
  return out;
}

class _PunkteMarke extends StatelessWidget {
  final String text;
  final double groesse;
  const _PunkteMarke(this.text, this.groesse);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: kGoldSoft,
        border: Border.all(color: kGoldLine),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: monoStyle(groesse, color: kGoldInk, weight: FontWeight.w600, spacing: 0.1).copyWith(height: 1.4)),
    );
  }
}

/// Eine Zeile eines Rechenblocks: Ergebnis hinter dem letzten „=“ fett.
Widget ptRechenzeile(String zeile, TextStyle stil) {
  final t = ptRechnung(zeile);
  return Text.rich(TextSpan(style: stil, children: [
    ...ptInline(t.vor, stil),
    if (t.ergebnis != null) ...[
      const TextSpan(text: ' '),
      TextSpan(text: t.ergebnis, style: TextStyle(fontWeight: FontWeight.w700, color: kPetrolInkDeep)),
      ...ptInline(t.nach, stil),
    ],
  ]));
}

/// Rechenblock: Fläche mit Petrol-Linie links, Ziffern tabellarisch.
class PtRechenkasten extends StatelessWidget {
  final List<String> zeilen;
  final TextStyle stil;
  const PtRechenkasten(this.zeilen, this.stil, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = stil.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border(left: BorderSide(color: kPetrolLine, width: 3)),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < zeilen.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          ptRechenzeile(zeilen[i], s),
        ],
      ]),
    );
  }
}

/// Prüfungstext als Tabellen, Listen, Rechenblöcke und Absätze. [stil] ist
/// die Grundschrift (Größe, Gewicht, Farbe, Zeilenhöhe); Tabellen setzen sich
/// davon in normaler Stärke ab.
class PruefText extends StatelessWidget {
  final String text;
  final TextStyle? stil;
  const PruefText(this.text, {super.key, this.stil});

  @override
  Widget build(BuildContext context) {
    final basis = TextStyle(fontSize: 14, height: 1.6, color: kInk, fontWeight: FontWeight.w400).merge(stil);
    final em = basis.fontSize ?? 14;
    final bloecke = ptBloecke(text);
    final kinder = <Widget>[];
    for (final b in bloecke) {
      if (kinder.isNotEmpty) kinder.add(SizedBox(height: em * (b.abstand ? 1.05 : 0.6)));
      kinder.add(_block(context, b, basis, em));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: kinder);
  }

  Widget _block(BuildContext context, PtBlock b, TextStyle basis, double em) {
    switch (b) {
      case PtAbsatz(:final text):
        return Text.rich(TextSpan(style: basis, children: ptInline(text, basis)));
      case PtZellenAbsatz(:final zellen):
        final teile = <InlineSpan>[];
        for (var i = 0; i < zellen.length; i++) {
          if (i > 0) teile.add(TextSpan(text: '  ·  ', style: TextStyle(color: kMuted)));
          teile.addAll(ptInline(zellen[i], basis));
        }
        return Text.rich(TextSpan(style: basis, children: teile));
      case PtBeschriftung(:final text):
        final s = basis.copyWith(fontWeight: FontWeight.w600, color: kInk);
        return Text.rich(TextSpan(style: s, children: ptInline(text, s)));
      case PtHinweis(:final praefix, :final text):
        final s = basis.copyWith(fontSize: em * 0.94, height: 1.55, color: kInkSoft);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
          decoration: BoxDecoration(
            color: kAmberSoft,
            border: Border(left: BorderSide(color: kAmber, width: 3)),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
          ),
          child: Text.rich(TextSpan(style: s, children: [
            TextSpan(text: '$praefix ', style: TextStyle(fontWeight: FontWeight.w700, color: kAmberInk)),
            ...ptInline(text, s),
          ])),
        );
      case PtListe(:final punkte):
        final punkt = em * 0.36;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < punkte.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : em * 0.28),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: em * 1.15,
                  child: Padding(
                    padding: EdgeInsets.only(left: em * 0.18, top: (basis.height ?? 1.6) * em / 2 - punkt / 2),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        width: punkt,
                        height: punkt,
                        decoration: BoxDecoration(color: kPetrol, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
                Expanded(child: Text.rich(TextSpan(style: basis, children: ptInline(punkte[i], basis)))),
              ]),
            ),
        ]);
      case PtRechenblock(:final zeilen):
        return PtRechenkasten(zeilen, basis);
      case PtTabelle():
        return _PtTabellenAnsicht(b, basis);
    }
  }
}

class _PtTabellenAnsicht extends StatelessWidget {
  final PtTabelle t;
  final TextStyle basis;
  const _PtTabellenAnsicht(this.t, this.basis);

  @override
  Widget build(BuildContext context) {
    final fs = (basis.fontSize ?? 14) * 0.92;
    final zelle = basis.copyWith(
      fontSize: fs,
      height: 1.45,
      fontWeight: FontWeight.w400,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final kopfStil = zelle.copyWith(fontSize: fs * 0.9, fontWeight: FontWeight.w700, color: kPetrolInkDeep);
    // Auf dem Handy dürfen die Werte einer zweispaltigen Liste umbrechen.
    final handy = MediaQuery.sizeOf(context).width < 560;

    Widget inhalt(String z, int c, {required bool kopf}) {
      final kasten = !kopf && _ptKasten.hasMatch(z);
      final zahl = t.zahlSpalte[c] && !(handy && t.werteliste);
      var s = kopf ? kopfStil : zelle;
      if (!kopf && t.werteliste) {
        s = c == 0 ? s.copyWith(color: kInkSoft) : s.copyWith(fontWeight: FontWeight.w600, color: kInk);
      }
      if (kasten) s = s.copyWith(color: kMuted);
      final text = Text.rich(
        TextSpan(style: s, children: ptInline(z, s)),
        textAlign: kasten ? TextAlign.center : (zahl ? TextAlign.right : TextAlign.left),
        softWrap: !zahl,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: (handy && t.werteliste && c > 0 && t.zahlSpalte[c])
            ? ConstrainedBox(constraints: BoxConstraints(minWidth: fs * 3.8), child: text)
            : text,
      );
    }

    final zeilen = <TableRow>[];
    for (var r = 0; r < t.zeilen.length; r++) {
      final kopf = t.kopf && r == 0;
      final k = t.kopf ? r - 1 : r; // Index im Tabellenkörper
      zeilen.add(TableRow(
        decoration: kopf
            ? BoxDecoration(color: kSurface2, border: Border(bottom: BorderSide(color: kLine)))
            : (k.isOdd ? BoxDecoration(color: kSurface) : null),
        children: [for (var c = 0; c < t.spalten; c++) inhalt(t.zeilen[r][c], c, kopf: kopf)],
      ));
    }

    return LayoutBuilder(builder: (context, c) {
      final breite = c.maxWidth.isFinite ? c.maxWidth : 400.0;
      return Container(
        decoration: BoxDecoration(
          color: kPaper,
          border: Border.all(color: kLine),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _TabellenBreite(
              verfuegbar: math.max(0, breite - 2),
              mindestens: math.min(breite - 2, 280),
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                defaultVerticalAlignment: TableCellVerticalAlignment.top,
                border: TableBorder(horizontalInside: BorderSide(color: kLineSoft)),
                children: zeilen,
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Breite nach Inhalt, höchstens die verfügbare Breite – die Spalten brechen
/// dann um. Reicht auch die schmalste Anordnung nicht, wird die Tabelle so
/// breit wie nötig und scrollt waagerecht (Web `width: fit-content`).
class _TabellenBreite extends SingleChildRenderObjectWidget {
  final double verfuegbar;
  final double mindestens;
  const _TabellenBreite({required this.verfuegbar, required this.mindestens, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTabellenBreite(verfuegbar, mindestens);

  @override
  void updateRenderObject(BuildContext context, _RenderTabellenBreite renderObject) {
    renderObject
      ..verfuegbar = verfuegbar
      ..mindestens = mindestens;
  }
}

class _RenderTabellenBreite extends RenderProxyBox {
  double _verfuegbar;
  double _mindestens;
  _RenderTabellenBreite(this._verfuegbar, this._mindestens);

  set verfuegbar(double v) {
    if (v == _verfuegbar) return;
    _verfuegbar = v;
    markNeedsLayout();
  }

  set mindestens(double v) {
    if (v == _mindestens) return;
    _mindestens = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final kind = child;
    if (kind == null) {
      size = constraints.smallest;
      return;
    }
    final schmal = kind.getMinIntrinsicWidth(double.infinity);
    final max = math.max(_verfuegbar, schmal);
    kind.layout(BoxConstraints(minWidth: math.min(_mindestens, max), maxWidth: max), parentUsesSize: true);
    size = constraints.constrain(kind.size);
  }
}
