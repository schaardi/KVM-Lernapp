import 'package:flutter/material.dart';
import '../constants.dart';
import '../config.dart';
import '../widgets/account_sheet.dart';
import 'home_screen.dart';

/// Auswahl der Prüfungs-Kategorie (Qualifikation) – Einstieg der App.
/// Darunter folgen die Fachthemen der jeweiligen Kategorie.
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  void _open(BuildContext context, AppCategory c) {
    if (!c.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${c.name} ist bald verfügbar.')),
      );
      return;
    }
    // Aktuell trägt nur KVM Inhalte – die bestehende Fächer-/Themen-Ansicht.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          children: [
            // Kopf
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [kPaper, kBgTint],
                ),
                borderRadius: BorderRadius.circular(kRadius + 4),
                border: Border.all(color: kLine),
                boxShadow: kSoftShadow,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 50, height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [kPetrol, kPetrolDeep],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(color: Color(0x330C6C78), blurRadius: 12, offset: Offset(0, 5)),
                      ],
                    ),
                    child: const Icon(Icons.workspace_premium, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('IHK-AUFSTIEGSFORTBILDUNG',
                        style: TextStyle(color: kPetrol, fontWeight: FontWeight.w800,
                            fontSize: 10.5, letterSpacing: 1.4)),
                  ),
                  if (Config.authEnabled)
                    IconButton(
                      tooltip: 'Konto & Synchronisierung',
                      onPressed: () => showAccountSheet(context),
                      icon: const Icon(Icons.account_circle_outlined, color: kPetrol),
                    ),
                ]),
                const SizedBox(height: 16),
                const Text('Wähle deine Prüfung',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, height: 1.12, color: kInk)),
              ]),
            ),
            const SizedBox(height: 22),

            const Padding(
              padding: EdgeInsets.only(bottom: 12, left: 2),
              child: Text('Kategorien',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
            ),
            for (final c in kCategories) _categoryTile(context, c),
          ],
        ),
      ),
    );
  }

  Widget _categoryTile(BuildContext context, AppCategory c) {
    final on = c.available;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kLine),
        boxShadow: on ? kSoftShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _open(context, c),
          borderRadius: BorderRadius.circular(kRadius),
          child: Opacity(
            opacity: on ? 1 : 0.6,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(children: [
                Container(
                  width: 50, height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: c.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(c.icon, color: c.color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(
                        child: Text(c.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: kInk)),
                      ),
                      if (!on) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: kAmber.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999)),
                          child: const Text('bald',
                              style: TextStyle(color: kAmber, fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 3),
                    Text(c.subtitle, style: const TextStyle(fontSize: 12.5, color: kMuted)),
                  ]),
                ),
                const SizedBox(width: 6),
                Icon(on ? Icons.chevron_right : Icons.lock_outline, color: kMuted),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
