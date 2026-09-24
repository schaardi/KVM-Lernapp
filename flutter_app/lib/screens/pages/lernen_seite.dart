import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../features/muendlich.dart';
import '../../features/runde.dart';
import '../../services/app_state.dart';
import '../../services/data_service.dart';
import '../../services/progress_service.dart';
import '../../services/round_builder.dart';
import '../../services/selection_service.dart';
import '../../util/format.dart';
import '../../widgets/ui.dart';

/// Lernen (FR-015 3): „Dein Lernweg“ durch die Fächer und „Üben“ mit den
/// Übungsarten im gewählten Fach und fachübergreifend (FR-003 E.3/E.4).
class LernenSeite extends StatelessWidget {
  const LernenSeite({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppState.instance;
    final data = DataService.instance;
    final counts = data.fachCounts();
    final subs = data.subsOfFach(st.fach);
    final scope = st.sub == '*' ? '${kFachKurz[st.fach]} – alle Bereiche' : st.sub;
    final w = MediaQuery.sizeOf(context).width;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SeitenTitel('Lernen'),
            const Abschnitt('Dein Lernweg', zusatz: '4 fix + 1 wählbar', padding: EdgeInsets.fromLTRB(4, 2, 4, 8)),
            Karte(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _Lernweg(
                  facher: const [...SelectionService.baseFacher, ...SelectionService.zusatzFacher],
                  counts: counts,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
                  child: Text(
                    'Die vier Basisqualifikationen sind immer dabei. Die Fachrichtung Kraftverkehr '
                    'schaltest du mit dem Schalter zu oder ab – sie zählt dann bei „Alle Themen“, '
                    'Fortschritt und Prüfungsreife mit.',
                    style: TextStyle(fontSize: 12, height: 1.4, color: kMuted),
                  ),
                ),
              ]),
            ),
            Abschnitt('Üben', zusatz: 'Im gewählten Fach · $scope'),
            Karte(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Themenbereich', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kInkSoft)),
                const SizedBox(height: 8),
                _BereichChips(subs: subs, horizontal: w < 600),
                const SizedBox(height: 14),
                _Modus(
                  icon: Icons.menu_book_outlined,
                  farbe: kPetrol,
                  tag: 'Training',
                  titel: st.sub == '*' ? 'Alle Bereiche' : st.sub,
                  text: '$kRoundLen Fragen mit sofortiger Auswertung und Erklärung. Neue Fragen werden bevorzugt.',
                  onTap: () => starteRunde(context, RoundMode.train),
                ),
                _Modus(
                  icon: Icons.gps_fixed,
                  farbe: kAmber,
                  tag: 'Fokus',
                  titel: 'Schwächen üben',
                  text: 'Gezielt die Fragen, die du noch nicht kannst oder zuletzt falsch hattest.',
                  onTap: () => starteRunde(context, RoundMode.weak),
                ),
                _Modus(
                  icon: Icons.timer_outlined,
                  farbe: const Color(0xFF33474E),
                  tag: 'Klausur',
                  titel: 'Prüfungssimulation',
                  text: '$kSimLen Fragen aus dem ganzen Fach · 60 Minuten · bestanden ab 50 %.',
                  onTap: () => starteRunde(context, RoundMode.sim),
                ),
                _Modus(
                  icon: Icons.mic_none,
                  farbe: kViolet,
                  tag: 'Mündlich',
                  titel: 'Fachgespräch üben',
                  text: '10 Fragen werden vorgelesen – du antwortest frei per Sprache, danach Musterlösung und Selbstcheck.',
                  onTap: () => starteMuendlich(context),
                ),
                const SizedBox(height: 6),
                Text('Fachübergreifend', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kInkSoft)),
                const SizedBox(height: 8),
                _Modus(
                  icon: Icons.shuffle,
                  farbe: kPetrolDeep,
                  tag: 'Alle Fächer',
                  titel: 'Alle Themen üben',
                  text: '$kRoundLen gemischte Fragen quer durch alle Fächer und Themenbereiche.',
                  onTap: () => starteRunde(context, RoundMode.all),
                ),
                _Modus(
                  icon: Icons.work_outline,
                  farbe: kPlum,
                  tag: 'Fall',
                  titel: 'Fallaufgaben',
                  text: 'Handlungssituation mit mehreren verketteten Teilaufgaben – wie im echten IHK-Prüfungsformat.',
                  onTap: () => starteFallaufgabe(context),
                  letzte: true,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Die Fächer als Stationen an einer gestrichelten Linie (FR-003 E.3).
class _Lernweg extends StatelessWidget {
  final List<int> facher;
  final Map<int, int> counts;
  const _Lernweg({required this.facher, required this.counts});

  @override
  Widget build(BuildContext context) {
    final st = AppState.instance;
    final prog = ProgressService.instance;
    final sel = SelectionService.instance;
    return Stack(children: [
      Positioned(
        left: 25,
        top: 26,
        bottom: 26,
        child: CustomPaint(size: const Size(2, double.infinity), painter: _Strichlinie(kLineStrong)),
      ),
      Column(children: [
        for (final f in facher)
          Builder(builder: (context) {
            final n = counts[f] ?? 0;
            final zusatz = SelectionService.zusatzFacher.contains(f);
            final an = sel.isFachActive(f);
            final gewaehlt = an && st.fach == f;
            final reife = n == 0 ? 0.0 : prog.fachReife(f);
            final gesehen = n > 0 && DataService.instance.forFach(f).any((q) => (prog.get(q.id)?.seen ?? 0) > 0);
            final amp = ampelVon(reife, begonnen: gesehen);
            final gemeistert = prog.fachMastered(f);
            return Opacity(
              opacity: an ? 1 : 0.55,
              child: Material(
                color: gewaehlt ? kPetrolSoft : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: gewaehlt ? kPetrolLine : Colors.transparent),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: n == 0
                      ? null
                      : () {
                          if (!an) {
                            sel.toggle(f);
                          }
                          st.waehleFach(f);
                        },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 8, 8, 8),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: kFachColor[f],
                          shape: BoxShape.circle,
                          border: Border.all(color: gewaehlt ? kPetrolSoft : kPaper, width: 4),
                        ),
                        child: Text('$f',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(kFach[f]!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: kInk, height: 1.25)),
                          const SizedBox(height: 3),
                          Row(children: [
                            Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(color: ampelFarbe(amp), shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                n > 0 ? '${kAmpelText[amp]} · ${fmtN(gemeistert)}/${fmtN(n)} gemeistert' : 'in Vorbereitung',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: kMuted),
                              ),
                            ),
                            if (zusatz) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: kPlumSoft,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: kPlumLine),
                                ),
                                child: Text('FACHRICHTUNG', style: monoStyle(8.5, color: kPlumInk, spacing: 0.6)),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 6),
                          Balken(reife, hoehe: 5, farbe: kFachColor[f]),
                        ]),
                      ),
                      const SizedBox(width: 10),
                      if (zusatz)
                        Switch(
                          value: an,
                          activeThumbColor: kFachColor[f],
                          onChanged: n == 0
                              ? null
                              : (_) {
                                  sel.toggle(f);
                                  if (!sel.isFachActive(f) && st.fach == f) {
                                    st.waehleFach(1);
                                  } else {
                                    st.refresh();
                                  }
                                },
                        )
                      else
                        Text(fmtProzent(reife),
                            style: monoStyle(14, color: kInkSoft, weight: FontWeight.w600, spacing: 0)),
                    ]),
                  ),
                ),
              ),
            );
          }),
      ]),
    ]);
  }
}

class _Strichlinie extends CustomPainter {
  final Color farbe;
  _Strichlinie(this.farbe);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = farbe
      ..strokeWidth = 2;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(1, y), Offset(1, (y + 6).clamp(0, size.height)), p);
      y += 11;
    }
  }

  @override
  bool shouldRepaint(_Strichlinie old) => old.farbe != farbe;
}

class _BereichChips extends StatelessWidget {
  final List<String> subs;
  final bool horizontal;
  const _BereichChips({required this.subs, required this.horizontal});

  @override
  Widget build(BuildContext context) {
    final st = AppState.instance;
    final chips = [
      _chip('Alle Bereiche', '*', st),
      for (final s in subs) _chip(s, s, st),
    ];
    if (!horizontal) return Wrap(spacing: 8, runSpacing: 8, children: chips);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  Widget _chip(String label, String wert, AppState st) {
    final n = DataService.instance.forScope(st.fach, wert).length;
    final gewaehlt = st.sub == wert;
    return ChoiceChip(
      label: Text('$label · ${fmtN(n)}'),
      selected: gewaehlt,
      showCheckmark: false,
      onSelected: (_) => st.waehleBereich(wert),
      selectedColor: kPetrol,
      backgroundColor: kPaper,
      labelStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: gewaehlt ? Colors.white : kInkSoft),
      side: BorderSide(color: gewaehlt ? kPetrol : kLine),
    );
  }
}

class _Modus extends StatelessWidget {
  final IconData icon;
  final Color farbe;
  final String tag;
  final String titel;
  final String text;
  final VoidCallback onTap;
  final bool letzte;
  const _Modus({
    required this.icon,
    required this.farbe,
    required this.tag,
    required this.titel,
    required this.text,
    required this.onTap,
    this.letzte = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: letzte ? 0 : 8),
      child: Material(
        color: kPaper,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kLineStrong.withValues(alpha: 0.7)),
            ),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: farbe, borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: kSurface2, borderRadius: BorderRadius.circular(5)),
                      child: Text(tag.toUpperCase(), style: monoStyle(9, color: kInkSoft, spacing: 0.6)),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(titel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(text, style: TextStyle(fontSize: 12.5, height: 1.35, color: kMuted)),
                ]),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: kMuted),
            ]),
          ),
        ),
      ),
    );
  }
}
