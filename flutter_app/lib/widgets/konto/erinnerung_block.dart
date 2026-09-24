import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../lernen/erinnerung.dart';
import '../../lernen/erinnerung_service.dart';
import '../ui.dart';

/// „Lern-Erinnerung“ im Konto (FR-009): Schalter und Uhrzeit (Standard 19:00,
/// Schritte 5 min). Einschalten fragt unter Android 13+ erst jetzt nach der
/// Erlaubnis; bei Ablehnung bleibt der Schalter aus.
class ErinnerungBlock extends StatefulWidget {
  const ErinnerungBlock({super.key});

  @override
  State<ErinnerungBlock> createState() => _ErinnerungBlockState();
}

class _ErinnerungBlockState extends State<ErinnerungBlock> {
  final _er = ErinnerungService.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _er.addListener(_neu);
  }

  @override
  void dispose() {
    _er.removeListener(_neu);
    super.dispose();
  }

  void _neu() {
    if (mounted) setState(() {});
  }

  Future<void> _schalten(bool an) async {
    setState(() => _busy = true);
    try {
      if (an) {
        await _er.einschalten();
      } else {
        await _er.ausschalten();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _zeitWaehlen() async {
    final z = zeitLesen(zeitAufFuenf(_er.zeit))!;
    var wahl = DateTime(2000, 1, 1, z.stunde, z.minute);
    final neu = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: kPaper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: kLine, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),
            Text('UHRZEIT DER ERINNERUNG', style: dispStyle(20)),
            SizedBox(
              height: 190,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: kPalette.brightness,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 22, color: kInk),
                  ),
                ),
                child: Semantics(
                  label: 'Uhrzeit der täglichen Lern-Erinnerung',
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    minuteInterval: 5,
                    initialDateTime: wahl,
                    onDateTimeChanged: (d) => wahl = d,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, zeitText(wahl.hour, wahl.minute)),
              style: FilledButton.styleFrom(
                backgroundColor: kPetrol,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700),
              ),
              child: const Text('Übernehmen'),
            ),
          ]),
        ),
      ),
    );
    if (neu != null && neu != _er.zeit) await _er.zeitSetzen(neu);
  }

  @override
  Widget build(BuildContext context) {
    final an = _er.an;
    final hinweis = _er.hinweis;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Abschnitt('Lern-Erinnerung', padding: EdgeInsets.fromLTRB(2, 16, 2, 8)),
      Row(children: [
        Expanded(
          child: Text('Tägliche Mitteilung um',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: an ? kInk : kInkSoft)),
        ),
        Semantics(
          button: true,
          label: 'Uhrzeit der täglichen Lern-Erinnerung: ${_er.zeit} Uhr',
          excludeSemantics: true,
          child: OutlinedButton(
            onPressed: _busy ? null : _zeitWaehlen,
            style: OutlinedButton.styleFrom(
              foregroundColor: kInk,
              side: BorderSide(color: kLineStrong),
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.schedule, size: 17, color: kPetrolInk),
              const SizedBox(width: 6),
              Text(_er.zeit),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          label: 'Lern-Erinnerung',
          child: Switch(value: an, onChanged: _busy ? null : _schalten),
        ),
      ]),
      const SizedBox(height: 6),
      Text(
        'Täglich zur gewählten Uhrzeit als Mitteilung – bis zum Tag vor deiner Prüfung, wenn du einen Termin '
        'eingetragen hast. Hast du an dem Tag schon gelernt, bleibt sie aus.',
        style: TextStyle(fontSize: 11.5, height: 1.45, color: kMuted),
      ),
      if (hinweis != null) ...[
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
            decoration: BoxDecoration(
              color: kAmberSoft,
              border: Border.all(color: kAmberLine),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(hinweis, style: TextStyle(fontSize: 12.5, height: 1.4, color: kAmberInk, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    ]);
  }
}
