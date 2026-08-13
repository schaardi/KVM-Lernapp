import 'package:flutter/material.dart';
import '../constants.dart';

// ─────────────────────────── Zahlen: parsen & formatieren ───────────────────

/// Deutsche Eingaben robust lesen: „1.234,56", „1234,56", „1234.56", „ 12 ".
double? parseDe(String s) {
  var t = s.trim();
  if (t.isEmpty) return null;
  t = t.replaceAll(RegExp(r'[^0-9,.\-]'), '');
  if (t.isEmpty || t == '-') return null;
  final hasComma = t.contains(',');
  final dots = '.'.allMatches(t).length;
  if (hasComma) {
    // Komma ist das Dezimaltrennzeichen, Punkte sind Tausenderpunkte.
    t = t.replaceAll('.', '').replaceAll(',', '.');
  } else if (dots > 1) {
    t = t.replaceAll('.', ''); // nur Tausenderpunkte
  }
  return double.tryParse(t);
}

/// Wert eines Feldes oder 0 – für Rechnungen, in denen Leerfelder 0 bedeuten.
double v(TextEditingController c) => parseDe(c.text) ?? 0;

/// Deutsche Zahlformatierung mit Tausenderpunkt.
String fmtNum(double x, {int dec = 2}) {
  if (x.isNaN || x.isInfinite) return '–';
  final neg = x < 0;
  final s = x.abs().toStringAsFixed(dec);
  final parts = s.split('.');
  final buf = StringBuffer();
  final ip = parts[0];
  for (var i = 0; i < ip.length; i++) {
    if (i > 0 && (ip.length - i) % 3 == 0) buf.write('.');
    buf.write(ip[i]);
  }
  final out = parts.length > 1 ? '${buf.toString()},${parts[1]}' : buf.toString();
  return neg ? '−$out' : out;
}

String fmtEur(double x) => '${fmtNum(x)} €';
String fmtPct(double x) => '${fmtNum(x)} %';

// ─────────────────────────── Bausteine ──────────────────────────────────────

/// Karte für einen Rechenabschnitt.
class CalcCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  const CalcCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kLine),
        boxShadow: kSoftShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w800, color: kInk)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: const TextStyle(fontSize: 12, color: kMuted, height: 1.3)),
              ],
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

/// Kompaktes Zahlenfeld – rechtsbündig wie im Kalkulationsschema.
class NumField extends StatelessWidget {
  final TextEditingController controller;
  final String? suffix;
  final String? hint;
  final double width;
  final VoidCallback onChanged;
  const NumField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.suffix,
    this.hint,
    this.width = 108,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: kInk),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint ?? '0',
          hintStyle: const TextStyle(color: kMuted, fontWeight: FontWeight.w400),
          suffixText: suffix,
          suffixStyle: const TextStyle(fontSize: 12, color: kMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          filled: true,
          fillColor: kBgTint.withValues(alpha: 0.55),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kLine),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kPetrol, width: 1.6),
          ),
        ),
      ),
    );
  }
}

/// Zeile im Kalkulationsschema: Operator · Bezeichnung · (%-Feld) · Wert.
///
/// [field] ersetzt die Wertspalte durch ein Eingabefeld, [percent] blendet
/// zusätzlich ein schmales Prozentfeld davor ein.
class SchemeLine extends StatelessWidget {
  final String op;
  final String label;
  final Widget? percent;
  final Widget? field;
  final double? value;

  /// Ersetzt die formatierte Euro-Ausgabe (z. B. für Prozent- oder Mengenwerte).
  final String? display;
  final bool total;
  final bool sub;
  final Color? accent;
  final String? note;

  const SchemeLine({
    super.key,
    this.op = '',
    required this.label,
    this.percent,
    this.field,
    this.value,
    this.display,
    this.total = false,
    this.sub = false,
    this.accent,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final strong = total || sub;
    final color = accent ?? (total ? kPetrolDeep : kInk);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: strong
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: kLine, width: 1.2)))
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            child: Text(op,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: op == '=' ? kPetrol : kMuted)),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 13.5,
                      height: 1.25,
                      fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
                      color: color)),
              if (note != null)
                Text(note!,
                    style: const TextStyle(fontSize: 11, color: kMuted, height: 1.3)),
            ]),
          ),
          if (percent != null) ...[
            const SizedBox(width: 6),
            percent!,
          ],
          const SizedBox(width: 8),
          if (field != null)
            field!
          else
            SizedBox(
              width: 108,
              child: Text(
                display ?? (value == null ? '–' : fmtEur(value!)),
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: total ? 15 : 14,
                    fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                    color: color),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ergebnis-Kachel für Kennzahlen.
class ResultTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? hint;
  const ResultTile({
    super.key,
    required this.label,
    required this.value,
    this.color = kPetrol,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(kRadiusSm),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11.5, color: kMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: color, height: 1.05)),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint!, style: const TextStyle(fontSize: 11, color: kMuted)),
        ],
      ]),
    );
  }
}

/// Hinweis-/Merkkasten.
class InfoBox extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final String? title;
  const InfoBox({
    super.key,
    required this.text,
    this.icon = Icons.lightbulb_outline,
    this.color = kPetrol,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(kRadiusSm),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (title != null) ...[
              Text(title!,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13, color: color)),
              const SizedBox(height: 3),
            ],
            Text(text,
                style: const TextStyle(fontSize: 13, height: 1.45, color: kInkSoft)),
          ]),
        ),
      ]),
    );
  }
}

/// Umschalter für Rechenrichtungen (z. B. vorwärts / rückwärts / Differenz).
class ModeSwitch extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const ModeSwitch({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kBgTint,
        borderRadius: BorderRadius.circular(kRadiusSm),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final on = i == index;
          return Expanded(
            child: Material(
              color: on ? kPetrol : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => onChanged(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: on ? Colors.white : kInkSoft),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Aufklappbarer Rechenweg.
class StepsPanel extends StatelessWidget {
  final List<String> steps;
  final String title;
  const StepsPanel({super.key, required this.steps, this.title = 'Rechenweg'});

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kLine),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: const Icon(Icons.functions, color: kPetrol, size: 20),
          title: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14, color: kInk)),
          children: [
            for (final s in steps)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('· ', style: TextStyle(color: kMuted)),
                  Expanded(
                    child: Text(s,
                        style: const TextStyle(
                            fontSize: 13, height: 1.45, color: kInkSoft)),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

/// „Beispiel laden"-Knopf.
class ExampleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  const ExampleButton({
    super.key,
    required this.onPressed,
    this.label = 'Beispiel laden',
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
          foregroundColor: kPetrol, padding: const EdgeInsets.symmetric(horizontal: 8)),
      icon: const Icon(Icons.auto_fix_high, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

/// Gerüst für alle Rechner: Titel, Scrollfläche, „Leeren"-Aktion.
class CalcScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback onReset;
  const CalcScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPaper,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
          Text(subtitle, style: const TextStyle(fontSize: 11.5, color: kMuted)),
        ]),
        actions: [
          IconButton(
            tooltip: 'Eingaben leeren',
            onPressed: onReset,
            icon: const Icon(Icons.backspace_outlined, color: kMuted, size: 20),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
          children: children,
        ),
      ),
    );
  }
}
