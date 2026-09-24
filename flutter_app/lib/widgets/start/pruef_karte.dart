import 'package:flutter/material.dart';
import '../../features/runde.dart';
import '../../services/answer_store.dart';
import '../../services/data_service.dart';
import '../../services/letzte_pruefung.dart';
import '../ui.dart';
import 'chance_streifen.dart';

/// Dunkle Prüfungskarte (FR-003 E.5, FR-015 2.4): Kopf öffnet die Seite
/// „Prüfungen“, darunter „Zuletzt geöffnet“ und die Bestehenschance.
class PruefKarte extends StatelessWidget {
  final VoidCallback onOeffnen;
  final bool kompakt;
  final bool breit;
  const PruefKarte({super.key, required this.onOeffnen, this.kompakt = false, this.breit = false});

  static const _hellText = Color(0xFFE9F2F3);

  @override
  Widget build(BuildContext context) {
    final anzahl = DataService.instance.cases.where((c) => c.id.startsWith('P-')).length;
    final linie = Container(height: 1, color: Colors.white.withValues(alpha: 0.12));

    final kopf = InkWell(
      onTap: onOeffnen,
      child: Padding(
        padding: EdgeInsets.fromLTRB(13, kompakt ? 9 : 12, 10, kompakt ? 9 : 12),
        child: Row(children: [
          Container(
            width: kompakt ? 36 : (breit ? 48 : 42),
            height: kompakt ? 36 : (breit ? 48 : 42),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF2A33A), Color(0xFFC96F05)]),
              boxShadow: const [BoxShadow(color: Color(0x66D9820A), blurRadius: 14, offset: Offset(0, 5))],
            ),
            child: Icon(Icons.description_outlined, color: Colors.white, size: kompakt ? 19 : 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ORIGINAL-IHK-PRÜFUNGEN',
                  maxLines: 2,
                  style: dispStyle(breit ? 21 : 18, color: Colors.white, height: 1.05)),
              if (breit) ...[
                const SizedBox(height: 3),
                Text('$anzahl Prüfungen mit amtlichen Lösungshinweisen · Rechenweg und ausfüllbare Anlagen',
                    style: TextStyle(fontSize: 12.5, height: 1.35, color: _hellText.withValues(alpha: 0.8))),
              ],
            ]),
          ),
          Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.8)),
        ]),
      ),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1C3A42), Color(0xFF10262C)]),
        boxShadow: const [BoxShadow(color: Color(0x33102A32), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Stack(children: [
        Positioned(
          right: -50,
          top: -60,
          child: IgnorePointer(
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFD9820A).withValues(alpha: 0.28),
                  const Color(0xFFD9820A).withValues(alpha: 0),
                ]),
              ),
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            kopf,
            ValueListenableBuilder(
              valueListenable: LetztePruefung.instance.stand,
              builder: (context, stand, _) {
                final fall = stand == null ? null : fallMitId(stand.id);
                if (stand == null || fall == null) return const SizedBox.shrink();
                final steps = fall.steps;
                final fertig = steps.where((s) => AnswerStore.instance.get(s.id).trim().isNotEmpty).length;
                final datum = RegExp(r'–\s*([^–]+)$').firstMatch(fall.title)?.group(1)?.trim() ?? fall.termin;
                final name = fall.sub.replaceFirst(RegExp(r'^IHK-Prüfung:\s*'), '');
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  linie,
                  Padding(
                    padding: EdgeInsets.fromLTRB(13, kompakt ? 7 : 9, 13, kompakt ? 8 : 11),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (breit)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text('ZULETZT GEÖFFNET',
                                  style: monoStyle(9.5, color: _hellText.withValues(alpha: 0.62))),
                            ),
                          Text(datum.isEmpty ? name : '$name · $datum',
                              maxLines: breit ? 3 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: breit ? 14 : 12.5, fontWeight: FontWeight.w700, color: Colors.white, height: 1.35)),
                          const SizedBox(height: 6),
                          Balken(steps.isEmpty ? 0 : fertig / steps.length,
                              hoehe: 4,
                              spur: Colors.white.withValues(alpha: 0.14),
                              farbe: const Color(0xFFFFD28F)),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () => oeffneFall(context, fall, aufgabe: stand.nr),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF123A40),
                          minimumSize: Size(0, kompakt ? 34 : 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(MediaQuery.sizeOf(context).width < 360
                              ? 'Aufgabe ${stand.nr}'
                              : 'Weiter bei Aufgabe ${stand.nr}'),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 16),
                        ]),
                      ),
                    ]),
                  ),
                ]);
              },
            ),
            ChanceStreifen(onTap: onOeffnen, kompakt: kompakt),
          ]),
        ),
      ]),
    );
  }
}
