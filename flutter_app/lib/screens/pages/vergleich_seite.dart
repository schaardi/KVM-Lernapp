import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/app_state.dart';
import '../../widgets/ui.dart';

/// Vergleich (FR-015 3): freiwillige Wochenrangliste, Freunde und Lerngruppen
/// (FR-004, FR-010, FR-012, FR-014 7). Die Inhalte folgen im Paket „Cloud“.
class VergleichSeite extends StatelessWidget {
  const VergleichSeite({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SeitenTitel('Vergleich'),
            ValueListenableBuilder<bool?>(
              valueListenable: AppState.instance.vergleichVerfuegbar,
              builder: (context, an, _) => Karte(
                child: Text(
                  an == null ? 'Rangliste wird geladen …' : 'Die Rangliste folgt mit dem nächsten Update.',
                  style: TextStyle(fontSize: 13.5, height: 1.45, color: kMuted),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
