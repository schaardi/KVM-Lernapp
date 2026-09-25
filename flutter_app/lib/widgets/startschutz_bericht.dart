import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../services/startschutz.dart';
import 'ui.dart';

/// Was im sicheren Modus fehlt – für Dialog und Konto-Seite.
const String kSichererModusText =
    'Die App läuft im sicheren Modus: ohne Anmeldung und Cloud, Vorlesen, Erinnerungen und Werbung. '
    'Dein Lernstand auf diesem Gerät bleibt erhalten.';

/// Zeigt den Absturzbericht (einmal nach dem Start und über die Konto-Seite).
Future<void> absturzberichtZeigen(BuildContext context) {
  return showDialog<void>(context: context, builder: (_) => const _BerichtDialog());
}

class _BerichtDialog extends StatefulWidget {
  const _BerichtDialog();

  @override
  State<_BerichtDialog> createState() => _BerichtDialogState();
}

/// Lange Berichte (Systemprotokoll) nur gekürzt anzeigen – Kopieren und
/// Teilen nehmen immer den ganzen Text.
String _anzeige(String? text) {
  if (text == null) return 'Kein Bericht vorhanden.';
  const grenze = 12000;
  if (text.length <= grenze) return text;
  return '${text.substring(0, grenze)}\n… (gekürzt – „Bericht kopieren“ und „Teilen“ enthalten alles)';
}

class _BerichtDialogState extends State<_BerichtDialog> {
  final _schutz = Startschutz.instance;
  late final Future<String?> _bericht = _schutz.bericht();
  bool _kopiert = false;

  Future<void> _kopieren(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) setState(() => _kopiert = true);
  }

  @override
  Widget build(BuildContext context) {
    final sicher = _schutz.sicher;
    return AlertDialog(
      // Kleine Bildschirme und große Schrift: lieber scrollen als abschneiden.
      scrollable: true,
      title: Text(sicher ? 'Sicherer Start nach Absturz' : 'Absturzbericht'),
      content: SizedBox(
        width: 520,
        child: FutureBuilder<String?>(
          future: _bericht,
          builder: (context, snap) {
            final text = snap.data;
            return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(
                sicher
                    ? 'Die App ist zuletzt abgestürzt. Damit du weiterlernen kannst, läuft sie jetzt im sicheren '
                        'Modus: ohne Anmeldung und Cloud, Vorlesen, Erinnerungen und Werbung. Dein Lernstand auf '
                        'diesem Gerät bleibt erhalten.'
                    : 'Die App ist zuletzt abgestürzt oder wurde vom System beendet.',
                style: TextStyle(fontSize: 14, height: 1.45, color: kInkSoft),
              ),
              const SizedBox(height: 8),
              Text(
                'Tippe auf „Bericht kopieren“ und schick den Text weiter – damit lässt sich die Ursache finden.',
                style: TextStyle(fontSize: 14, height: 1.45, color: kInkSoft, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(kRadiusSm),
                  border: Border.all(color: kLine),
                ),
                child: snap.connectionState != ConnectionState.done
                    ? const Padding(
                        padding: EdgeInsets.all(18),
                        child: Center(child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4))),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(10),
                        child: SelectableText(
                          _anzeige(text),
                          style: monoStyle(10.5, weight: FontWeight.w500, spacing: 0, color: kInk),
                        ),
                      ),
              ),
            ]);
          },
        ),
      ),
      actions: [
        FutureBuilder<String?>(
          future: _bericht,
          builder: (context, snap) {
            final text = snap.data;
            return Wrap(alignment: WrapAlignment.end, spacing: 4, children: [
              TextButton(
                onPressed: text == null ? null : () => _schutz.teilen(text),
                child: const Text('Teilen'),
              ),
              TextButton(
                onPressed: text == null ? null : () => _kopieren(text),
                child: Text(_kopiert ? 'Kopiert ✓' : 'Bericht kopieren'),
              ),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Weiter')),
            ]);
          },
        ),
      ],
    );
  }
}

/// Hinweis auf der Konto-Seite: sicherer Modus aktiv bzw. Bericht vorhanden.
class StartschutzKarte extends StatefulWidget {
  const StartschutzKarte({super.key});

  @override
  State<StartschutzKarte> createState() => _StartschutzKarteState();
}

class _StartschutzKarteState extends State<StartschutzKarte> {
  final _schutz = Startschutz.instance;
  bool _normalGewaehlt = false;

  Future<void> _normal() async {
    await _schutz.normalStarten();
    if (!mounted) return;
    setState(() => _normalGewaehlt = true);
  }

  Future<void> _loeschen() async {
    await _schutz.berichtLoeschen();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_schutz.sicher && !_schutz.berichtVorhanden) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kAmberSoft,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: kAmberLine),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_schutz.sicher ? 'Sicherer Modus' : 'Absturzbericht',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kAmberInk)),
          const SizedBox(height: 6),
          Text(
            _normalGewaehlt
                ? 'Beim nächsten Start lädt die App wieder alles. Stürzt sie erneut ab, startet sie danach wieder sicher.'
                : _schutz.sicher
                    ? '$kSichererModusText Grund war ein Absturz.'
                    : 'Die App ist zuletzt abgestürzt. Den Bericht kannst du kopieren und weiterschicken.',
            style: TextStyle(fontSize: 13.5, height: 1.45, color: kInkSoft),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (_schutz.berichtVorhanden)
              OutlinedButton(onPressed: () => absturzberichtZeigen(context), child: const Text('Bericht anzeigen')),
            if (_schutz.sicher && !_normalGewaehlt)
              OutlinedButton(onPressed: _normal, child: const Text('Nächstes Mal normal starten')),
            if (!_schutz.sicher && _schutz.berichtVorhanden)
              TextButton(onPressed: _loeschen, child: const Text('Bericht löschen')),
          ]),
        ]),
      ),
    );
  }
}
