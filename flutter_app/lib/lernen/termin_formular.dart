import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/lerntage_service.dart';
import '../widgets/ui.dart';
import 'datum.dart';
import 'de_material.dart';
import 'lernplan.dart';

/// Formular „Prüfungstermin“ (FR-006) als Blatt von unten: Datumsauswahl
/// (frühestens morgen), „Speichern“, „Entfernen“ (nur mit Termin) und
/// „Abbrechen“.
Future<void> terminBearbeiten(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kPaper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => deutsch(ctx, const TerminFormular()),
  );
}

class TerminFormular extends StatefulWidget {
  const TerminFormular({super.key});
  @override
  State<TerminFormular> createState() => _TerminFormularState();
}

class _TerminFormularState extends State<TerminFormular> {
  DateTime? _wahl;
  String? _fehler;
  late final int _heute;

  @override
  void initState() {
    super.initState();
    _heute = LerntageService.heute();
    final t = Lernplan.instance.termin;
    // Ein gespeicherter Termin ist vorgewählt, solange er noch kommt.
    if (t != null && t.pruefungsTag > _heute) {
      final d = datumVonTag(t.pruefungsTag);
      _wahl = DateTime(d.year, d.month, d.day);
    }
  }

  DateTime _lokal(int tag) {
    final d = datumVonTag(tag);
    return DateTime(d.year, d.month, d.day);
  }

  void _speichern() {
    final iso = _wahl == null ? null : isoVon(tagVonLokal(_wahl!));
    final f = terminFehler(iso, heute: LerntageService.heute());
    if (f != null) {
      setState(() => _fehler = f);
      return;
    }
    Lernplan.instance.speichern(iso!);
    Navigator.pop(context);
  }

  void _entfernen() {
    Lernplan.instance.entfernen();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hatTermin = Lernplan.instance.termin != null;
    const knopfText = TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: kLine, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),
            Text('PRÜFUNGSTERMIN', style: dispStyle(20)),
            const SizedBox(height: 4),
            Text('Trag den Termin ein – die App rechnet dir ein Tagesziel bis zur Prüfungsreife aus.',
                style: TextStyle(fontSize: 13, height: 1.4, color: kMuted)),
            const SizedBox(height: 6),
            Semantics(
              label: 'Datum deiner Prüfung',
              child: Theme(
                data: Theme.of(context).copyWith(
                  datePickerTheme: DatePickerThemeData(
                    dayForegroundColor: WidgetStateProperty.resolveWith((s) {
                      if (s.contains(WidgetState.selected)) return Colors.white;
                      if (s.contains(WidgetState.disabled)) return kMuted.withValues(alpha: 0.45);
                      return kInk;
                    }),
                    dayBackgroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected) ? kPetrol : null),
                    todayForegroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected) ? Colors.white : kPetrolInk),
                    todayBackgroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected) ? kPetrol : null),
                    todayBorder: BorderSide(color: kPetrolLine),
                    weekdayStyle: monoStyle(11, color: kMuted, spacing: 0.4),
                    dayStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: _wahl,
                  firstDate: _lokal(_heute + 1),
                  lastDate: _lokal(_heute + 5 * 366),
                  currentDate: _lokal(_heute),
                  onDateChanged: (d) => setState(() {
                    _wahl = d;
                    _fehler = null;
                  }),
                ),
              ),
            ),
            if (_wahl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('Prüfung am ${datumLang(tagVonLokal(_wahl!))}',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: kPetrolInkDeep)),
              ),
            if (_fehler != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Semantics(
                  liveRegion: true,
                  child: Text(_fehler!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kErrInk)),
                ),
              ),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: kInkSoft, minimumSize: const Size(0, 44), textStyle: knopfText),
                child: const Text('Abbrechen'),
              ),
              if (hatTermin)
                OutlinedButton(
                  onPressed: _entfernen,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kErrInk,
                    side: BorderSide(color: kErrLine),
                    minimumSize: const Size(0, 44),
                    textStyle: knopfText,
                  ),
                  child: const Text('Entfernen'),
                ),
              FilledButton(
                onPressed: _speichern,
                style: FilledButton.styleFrom(
                  backgroundColor: kPetrol,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  textStyle: knopfText,
                ),
                child: const Text('Speichern'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
