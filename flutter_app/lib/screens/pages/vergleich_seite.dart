import 'package:flutter/material.dart';
import '../../cloud/vergleich_dienst.dart';
import '../../cloud/vergleich_inhalt.dart';
import '../../constants.dart';
import '../../services/app_state.dart';
import '../../widgets/ui.dart';

/// Vergleich (FR-015 3): freiwillige Wochenrangliste, Freunde und Lerngruppen
/// (FR-004, FR-010, FR-012, FR-014 7). Titel rechts „x dabei“.
class VergleichSeite extends StatelessWidget {
  const VergleichSeite({super.key});

  @override
  Widget build(BuildContext context) {
    final d = VergleichDienst.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([d, AppState.instance.vergleichVerfuegbar]),
      builder: (context, _) {
        final scope = vergleichScope(d);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SeitenTitel(
                  'Vergleich',
                  rechts: scope == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(scope,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPetrolInk)),
                        ),
                ),
                const VergleichInhalt(),
              ]),
            ),
          ),
        );
      },
    );
  }
}
