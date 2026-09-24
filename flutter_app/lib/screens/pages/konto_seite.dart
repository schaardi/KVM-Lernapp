import 'package:flutter/material.dart';
import '../../config.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../services/premium_service.dart';
import '../../theme/theme_controller.dart';
import '../../version.dart';
import '../../widgets/konto/erinnerung_block.dart';
import '../../widgets/premium_sheet.dart';
import '../../widgets/ui.dart';

/// Konto & Einstellungen (FR-015 3): Anmeldung, Darstellung, Lern-Erinnerung
/// und die Quellen-Fußnote (nur hier).
class KontoSeite extends StatelessWidget {
  const KontoSeite({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SeitenTitel('Konto & Einstellungen'),
            Karte(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (Config.authEnabled && AuthService.instance.ready) const _KontoZeile(),
                if (Config.monetizationEnabled) ...[
                  const SizedBox(height: 10),
                  const _WerbefreiZeile(),
                ],
                const Abschnitt('Darstellung', padding: EdgeInsets.fromLTRB(2, 16, 2, 8)),
                const _DarstellungWahl(),
                const SizedBox(height: 14),
                Divider(height: 1, color: kLineSoft),
                const ErinnerungBlock(),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 0),
              child: Text(
                'Übungsfragen eigenständig formuliert, orientiert am DIHK-Rahmenplan und an '
                'Krause/Krause (Kiehl). Rechtsstände und veränderliche Werte (z. B. Beiträge) '
                'Stand 2025, ohne Gewähr.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, height: 1.5, color: kMuted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Version $kAppVersion',
                  textAlign: TextAlign.center, style: monoStyle(10.5, spacing: 0.4)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _KontoZeile extends StatefulWidget {
  const _KontoZeile();
  @override
  State<_KontoZeile> createState() => _KontoZeileState();
}

class _KontoZeileState extends State<_KontoZeile> {
  bool _busy = false;

  Future<void> _abmelden() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abmelden?'),
        content: const Text('Dein Fortschritt bleibt lokal auf diesem Gerät.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Abmelden')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    await AuthService.instance.signOut();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final name = auth.displayName ?? auth.email ?? 'angemeldet';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLine),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: kBlue, borderRadius: BorderRadius.circular(11)),
          child: const Icon(Icons.cloud_done_outlined, color: Colors.white, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: kInk)),
            const SizedBox(height: 2),
            Text('Fortschritt wird geräteübergreifend gesichert.',
                style: TextStyle(fontSize: 12.5, height: 1.35, color: kMuted)),
          ]),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: _busy ? null : _abmelden,
          style: TextButton.styleFrom(foregroundColor: kErrInk),
          child: const Text('Abmelden'),
        ),
      ]),
    );
  }
}

class _WerbefreiZeile extends StatelessWidget {
  const _WerbefreiZeile();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PremiumService.instance.isPremium,
      builder: (context, premium, _) => Material(
        color: premium ? kOkSoft : kPetrolSoft,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => showPremiumSheet(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Icon(premium ? Icons.verified : Icons.block_flipped, size: 20, color: premium ? kOkInk : kPetrolInk),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  premium ? 'Werbefrei aktiv – Abo verwalten' : 'Werbefrei lernen für ${PremiumService.instance.priceLabel}/Monat',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: premium ? kOkInk : kPetrolInkDeep),
                ),
              ),
              Icon(Icons.chevron_right, color: premium ? kOkInk : kPetrolInk, size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}

class _DarstellungWahl extends StatelessWidget {
  const _DarstellungWahl();

  @override
  Widget build(BuildContext context) {
    final tc = ThemeController.instance;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: tc.mode,
      builder: (context, mode, _) => SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(value: ThemeMode.system, label: Text('Automatisch')),
          ButtonSegment(value: ThemeMode.light, label: Text('Hell')),
          ButtonSegment(value: ThemeMode.dark, label: Text('Dunkel')),
        ],
        selected: {mode},
        showSelectedIcon: false,
        onSelectionChanged: (s) => tc.set(s.first),
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: kPetrolSoft,
          selectedForegroundColor: kPetrolInkDeep,
          foregroundColor: kInkSoft,
          side: BorderSide(color: kLine),
          textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}
