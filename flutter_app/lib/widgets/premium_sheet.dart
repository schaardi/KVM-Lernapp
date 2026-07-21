import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/premium_service.dart';

/// Werbefrei-Abo-Sheet: Vorteile, Preis, Kauf/Wiederherstellen und Status.
void showPremiumSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: kPaper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _PremiumSheet(),
  );
}

class _PremiumSheet extends StatefulWidget {
  const _PremiumSheet();
  @override
  State<_PremiumSheet> createState() => _PremiumSheetState();
}

class _PremiumSheetState extends State<_PremiumSheet> {
  bool _busy = false;
  String? _msg;

  Future<void> _buy() async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final ok = await PremiumService.instance.buy();
      if (!ok && mounted) {
        _msg = 'Das Abo ist derzeit nicht verfügbar. Bitte später erneut '
            'versuchen (das Produkt muss in der Play Console eingerichtet sein).';
      }
    } catch (_) {
      _msg = 'Kauf konnte nicht gestartet werden. Bitte erneut versuchen.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    await PremiumService.instance.restore();
    if (mounted) {
      setState(() {
        _busy = false;
        _msg = PremiumService.instance.isPremiumNow
            ? null
            : 'Kein aktives Abo gefunden.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = PremiumService.instance;
    return SafeArea(
      child: ValueListenableBuilder<bool>(
        valueListenable: svc.isPremium,
        builder: (context, premium, _) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                          color: kLine, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: kPetrol.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(premium ? Icons.verified : Icons.block_flipped,
                        color: kPetrol),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(premium ? 'Werbefrei aktiv' : 'Werbefrei lernen',
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800, color: kInk)),
                  ),
                ]),
                const SizedBox(height: 14),

                if (premium) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: kOkSoft, borderRadius: BorderRadius.circular(kRadiusSm)),
                    child: const Row(children: [
                      Icon(Icons.check_circle, color: kOk),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Dein Abo ist aktiv – du lernst ohne Werbung. Danke!',
                            style: TextStyle(color: kInk, height: 1.35)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Verwalten oder kündigen kannst du das Abo jederzeit im Google '
                    'Play Store unter „Zahlungen und Abos".',
                    style: TextStyle(color: kMuted, fontSize: 12.5, height: 1.35),
                  ),
                ] else ...[
                  _benefit(Icons.block, 'Keine Werbung mehr – volle Konzentration.'),
                  _benefit(Icons.all_inclusive, 'Alle Fächer, Fallaufgaben & Werkzeuge.'),
                  _benefit(Icons.event_available, 'Jederzeit kündbar über Google Play.'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _buy,
                      style: FilledButton.styleFrom(
                          backgroundColor: kPetrol,
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: _busy
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Werbefrei für ${svc.priceLabel}/Monat',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      onPressed: _busy ? null : _restore,
                      style: TextButton.styleFrom(foregroundColor: kMuted),
                      child: const Text('Käufe wiederherstellen'),
                    ),
                  ),
                ],

                if (_msg != null) ...[
                  const SizedBox(height: 6),
                  Text(_msg!, style: const TextStyle(color: kErr, fontSize: 13, height: 1.35)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _benefit(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(icon, size: 20, color: kPetrol),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 14, color: kInk, height: 1.3))),
        ]),
      );
}
