import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../data/kostenwesen_content.dart';
import '../../models/kostenwesen.dart';
import 'kw_lesson.dart';
import 'calc_zuschlag.dart';
import 'calc_bab.dart';
import 'calc_teilkosten.dart';
import 'calc_kosten.dart';
import 'calc_division.dart';
import 'calc_handel.dart';

class _CalcEntry {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget Function() build;
  const _CalcEntry(this.title, this.subtitle, this.icon, this.color, this.build);
}

/// Einstieg ins Modul „Betriebliches Kostenwesen": links lernen, rechts rechnen.
class KostenwesenScreen extends StatelessWidget {
  const KostenwesenScreen({super.key});

  static final List<_CalcEntry> _calcs = [
    _CalcEntry(
      'Zuschlagskalkulation',
      'Selbstkosten und Angebotspreis · vorwärts, rückwärts, Differenz',
      Icons.receipt_long,
      kPetrol,
      () => const ZuschlagCalc(),
    ),
    _CalcEntry(
      'Betriebsabrechnungsbogen',
      'Gemeinkosten verteilen und Zuschlagssätze bilden',
      Icons.grid_on,
      kOk,
      () => const BabCalc(),
    ),
    _CalcEntry(
      'Deckungsbeitrag & Break-Even',
      'Gewinnschwelle, Preisuntergrenzen, Engpassrechnung',
      Icons.trending_up,
      kDue,
      () => const TeilkostenCalc(),
    ),
    _CalcEntry(
      'Kalkulatorische Kosten',
      'Abschreibung, Zinsen, Wagnis, Maschinenstundensatz',
      Icons.precision_manufacturing_outlined,
      kAmber,
      () => const KalkKostenCalc(),
    ),
    _CalcEntry(
      'Divisions- & Äquivalenzziffern',
      'Massen- und Sortenfertigung',
      Icons.pie_chart_outline,
      const Color(0xFF3F6FB5),
      () => const DivisionCalc(),
    ),
    _CalcEntry(
      'Handelskalkulation',
      'Bezugspreis, Verkaufspreis, Handelsspanne',
      Icons.storefront_outlined,
      kErr,
      () => const HandelCalc(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: kPaper,
          title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Betriebliches Kostenwesen',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
                Text('Verstehen und rechnen',
                    style: TextStyle(fontSize: 11.5, color: kMuted)),
              ]),
          bottom: const TabBar(
            labelColor: kPetrol,
            unselectedLabelColor: kMuted,
            indicatorColor: kPetrol,
            indicatorWeight: 2.5,
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            tabs: [
              Tab(icon: Icon(Icons.menu_book_outlined, size: 20), text: 'Lernen'),
              Tab(icon: Icon(Icons.calculate_outlined, size: 20), text: 'Rechnen'),
            ],
          ),
        ),
        body: TabBarView(children: [
          _lernen(context),
          _rechnen(context),
        ]),
      ),
    );
  }

  Widget _lernen(BuildContext context) {
    var abschnitte = 0;
    for (final c in kwChapters) {
      abschnitte += c.sections.length;
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPaper, kBgTint],
            ),
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: kLine),
            boxShadow: kSoftShadow,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Von Grund auf zum Prüfungsniveau',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: kInk)),
            const SizedBox(height: 6),
            Text(
              '${kwChapters.length} Kapitel · $abschnitte Abschnitte. Die Kapitel '
              'bauen aufeinander auf: erst die Begriffe, dann die drei Stufen der '
              'Kostenrechnung, zuletzt Entscheidungen und Kennzahlen. Ohne '
              'Vorwissen lesbar.',
              style: const TextStyle(fontSize: 13, height: 1.5, color: kMuted),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < kwChapters.length; i++)
          _chapterTile(context, kwChapters[i], i + 1),
      ],
    );
  }

  Widget _chapterTile(BuildContext context, KwChapter c, int nr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kLine),
        boxShadow: kSoftShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadius),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => KwLessonScreen(chapter: c)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13)),
                child: Icon(c.icon, color: c.color, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                              color: c.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(5)),
                          child: Text('Kapitel $nr',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: c.color)),
                        ),
                        const SizedBox(width: 7),
                        Text('${c.sections.length} Abschnitte',
                            style:
                                const TextStyle(fontSize: 11, color: kMuted)),
                      ]),
                      const SizedBox(height: 4),
                      Text(c.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: kInk,
                              height: 1.2)),
                      const SizedBox(height: 2),
                      Text(c.subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: kMuted, height: 1.35)),
                    ]),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: kMuted),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _rechnen(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: kPetrolSoft,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: kPetrol.withValues(alpha: 0.25)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.table_chart_outlined, color: kPetrol, size: 20),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Rechnen im Prüfungsschema',
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: kPetrolDeep)),
                    SizedBox(height: 4),
                    Text(
                      'Die Tabellen folgen exakt dem Aufbau, den du in der '
                      'Prüfung schreibst. Zwischen- und Endsummen rechnen live '
                      'mit, den Rechenweg kannst du jederzeit aufklappen.',
                      style: TextStyle(fontSize: 12.5, height: 1.45, color: kInkSoft),
                    ),
                  ]),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        for (final c in _calcs) _calcTile(context, c),
      ],
    );
  }

  Widget _calcTile(BuildContext context, _CalcEntry c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kLine),
        boxShadow: kSoftShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadius),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => c.build())),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13)),
                child: Icon(c.icon, color: c.color, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: kInk)),
                      const SizedBox(height: 3),
                      Text(c.subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: kMuted, height: 1.35)),
                    ]),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: kMuted),
            ]),
          ),
        ),
      ),
    );
  }
}
