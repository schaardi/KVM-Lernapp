import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../models.dart';
import '../services/data_service.dart';
import '../services/round_builder.dart';
import 'quiz_screen.dart';

/// Übersicht der Original-IHK-Prüfungen: gezielt auswählbar statt zufällig
/// aus dem Fallaufgaben-Bestand gezogen.
class PruefungenScreen extends StatelessWidget {
  const PruefungenScreen({super.key});

  static const _monate = {
    'Januar': 1, 'Februar': 2, 'März': 3, 'April': 4, 'Mai': 5, 'Juni': 6,
    'Juli': 7, 'August': 8, 'September': 9, 'Oktober': 10, 'November': 11,
    'Dezember': 12,
  };

  /// Prüfungen tragen die Kennung "P-…"; alle übrigen Fälle bleiben außen vor.
  List<CaseStudy> _pruefungen() =>
      DataService.instance.cases.where((c) => c.id.startsWith('P-')).toList();

  String _bereich(CaseStudy c) {
    final m = RegExp(r'^IHK-Prüfung (.+?) – ').firstMatch(c.title);
    if (m != null) return m.group(1)!;
    return c.sub.replaceFirst('IHK-Prüfung: ', '');
  }

  String _datum(CaseStudy c) {
    final m = RegExp(r'– (.+)$').firstMatch(c.title);
    return m?.group(1) ?? '';
  }

  int _sortWert(CaseStudy c) {
    final m = RegExp(r'(\d{1,2})\.\s*(\S+)\s*(\d{4})').firstMatch(_datum(c));
    if (m == null) return 0;
    return int.parse(m.group(3)!) * 10000 +
        (_monate[m.group(2)] ?? 0) * 100 +
        int.parse(m.group(1)!);
  }

  String? _punkte(CaseStudy c) =>
      RegExp(r'(\d+)\s*Punkte insgesamt').firstMatch(c.context)?.group(1);

  /// Prüfungstermin (Frühjahr/Herbst JJJJ) für die Gruppierung.
  String _termin(CaseStudy c) {
    if (c.termin.isNotEmpty) return c.termin;
    final m = RegExp(r'(\d{1,2})\.\s*(\S+)\s*(\d{4})').firstMatch(_datum(c));
    if (m == null) return _bereich(c);
    final mon = _monate[m.group(2)] ?? 0;
    return '${mon <= 6 ? 'Frühjahr' : 'Herbst'} ${m.group(3)}';
  }

  /// Vollständiger Prüfauftrag für eine KI – identisch zur Web-Fassung.
  String _exportText(CaseStudy c) {
    final amtlich = c.steps.any((s) => s.amtlich);
    final b = StringBuffer()
      ..writeln('PRÜFAUFTRAG')
      ..writeln()
      ..writeln('Du bist erfahrener Prüfer und Dozent für die Fortbildung '
          '"Geprüfte/-r Meister/-in für Kraftverkehr (IHK)". Unten steht eine '
          'Original-Prüfungsaufgabe der IHK sowie zu jeder Teilaufgabe '
          '${amtlich ? 'der amtliche Lösungshinweis der IHK.' : 'eine Musterlösung, die NICHT von der IHK stammt, sondern nachträglich erarbeitet wurde.'}')
      ..writeln()
      ..writeln(amtlich
          ? 'Prüfe je Teilaufgabe knapp und gib eine Punkteempfehlung:'
          : 'Prüfe jede Musterlösung und antworte je Teilaufgabe knapp:')
      ..writeln('- Bewertung: korrekt / teilweise korrekt / fehlerhaft')
      ..writeln('- Fachliche Fehler konkret benennen (falsche Aussage, falsche '
          'Rechnung, veraltete Rechtsgrundlage) - oder "keine".')
      ..writeln('- Vollständigkeit: Reicht der Umfang für die angegebene '
          'Punktzahl? Faustregel: etwa 2 Punkte je verlangtem Element.')
      ..writeln('- Ergänzung: Was würde ein Prüfer zusätzlich erwarten?')
      ..writeln()
      ..writeln('Achte besonders auf: (1) Rechenaufgaben eigenständig nachrechnen '
          'und Abweichungen mit eigenem Rechenweg nennen; (2) Rechtsgrundlagen auf '
          'Aktualität prüfen (ArbSchG, ArbZG, StVO, StVZO, BetrVG, DGUV, '
          'VO (EG) 561/2006, VO (EU) 165/2014, BKrFQG, GGVSEB/ADR, '
          'DIN EN ISO 9001); (3) Behördenbezeichnungen (BALM, früher BAG).')
      ..writeln()
      ..writeln('==============================')
      ..writeln(c.title)
      ..writeln('==============================')
      ..writeln()
      ..writeln('AUSGANGSSITUATION')
      ..writeln(c.context)
      ..writeln();
    for (final s in c.steps) {
      final teile = s.q.split('\n\n');
      b
        ..writeln('------------------------------')
        ..writeln(teile.isNotEmpty ? teile.first : '')
        ..writeln()
        ..writeln(teile.skip(1).join('\n\n'))
        ..writeln()
        ..writeln(s.amtlich
            ? 'AMTLICHER LÖSUNGSHINWEIS (IHK):'
            : 'MUSTERLÖSUNG (zu prüfen):')
        ..writeln(s.a ?? '');
      if (s.vo != null && s.vo!.isNotEmpty) {
        b.writeln('VO-Bezug: ${s.vo}');
      }
      if (s.bewertung.isNotEmpty) {
        b.writeln('Punkteverteilung: ${s.bewertung.join(' + ')} Punkte');
      }
      if (s.e.isNotEmpty) {
        b
          ..writeln()
          ..writeln('Merksatz: ${s.e}');
      }
      b.writeln();
    }
    b
      ..writeln('==============================')
      ..writeln('Ende. Nenne abschließend, welche Teilaufgaben überarbeitet '
          'werden müssen.');
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final alle = _pruefungen()..sort((a, b) => _sortWert(b) - _sortWert(a));
    // Nach Prüfungstermin gruppieren (Frühjahr/Herbst JJJJ), je Termin FT + OK.
    final gruppen = <String, List<CaseStudy>>{};
    for (final c in alle) {
      gruppen.putIfAbsent(_termin(c), () => []).add(c);
    }
    // Termine bereits durch die Sortierung von `alle` chronologisch (neueste zuerst).
    final termine = gruppen.keys.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPaper,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Original-IHK-Prüfungen',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
          Text('${alle.length} Prüfung${alle.length == 1 ? '' : 'en'} verfügbar',
              style: const TextStyle(fontSize: 11.5, color: kMuted)),
        ]),
      ),
      body: SafeArea(
        child: alle.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Text(
                    'Es sind noch keine Original-Prüfungen hinterlegt.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kMuted, fontSize: 14),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                children: [
                  const Text(
                    'Echte Prüfungsaufgaben aus dem Handlungsspezifischen Teil. '
                    'Jede enthält die vollständige Ausgangssituation und alle '
                    'Teilaufgaben mit ihrer offiziellen Punktzahl. Formuliere '
                    'deine Antwort selbst und decke danach die amtlichen '
                    'Lösungshinweise auf.',
                    style: TextStyle(fontSize: 13, height: 1.55, color: kMuted),
                  ),
                  const SizedBox(height: 18),
                  for (final t in termine) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(t.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: kPetrolDeep)),
                    ),
                    for (final c in gruppen[t]!) _kachel(context, c),
                    const SizedBox(height: 12),
                  ],
                  _hinweis(),
                ],
              ),
      ),
    );
  }

  Widget _kachel(BuildContext context, CaseStudy c) {
    final punkte = _punkte(c);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kLine),
        boxShadow: kSoftShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Text(_bereich(c),
                style: const TextStyle(
                    fontSize: 15.5, fontWeight: FontWeight.w800, color: kInk)),
          ),
          if (punkte != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: kPetrolSoft, borderRadius: BorderRadius.circular(6)),
              child: Text('$punkte Punkte',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: kPetrolDeep)),
            ),
        ]),
        const SizedBox(height: 4),
        Text('${_datum(c)} · ${c.steps.length} Teilaufgaben · 180 Minuten',
            style: const TextStyle(fontSize: 12, color: kMuted)),
        const SizedBox(height: 11),
        Row(children: [
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => QuizScreen(
                  mode: RoundMode.cases,
                  pool: c.asPool(),
                  fach: c.f,
                  sub: c.sub,
                ),
              )),
              style: FilledButton.styleFrom(
                  backgroundColor: kPetrol,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              child: const Text('Prüfung starten',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _exportText(c)));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Prüfung mit Musterlösungen kopiert – jetzt in eine KI einfügen.')));
              },
              style: OutlinedButton.styleFrom(
                  foregroundColor: kPetrol,
                  side: const BorderSide(color: kLine),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              child: const Text('Für KI kopieren',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _hinweis() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: kAmber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(kRadiusSm),
        border: const Border(left: BorderSide(color: kAmber, width: 3)),
      ),
      child: const Text(
        'Zu den Lösungen: Hinterlegt sind die amtlichen Lösungshinweise der IHK '
        'zur jeweiligen Prüfung, samt VO-Bezug und – wo angegeben – der '
        'Punkteverteilung. Mit „Für KI kopieren" erhältst du die komplette '
        'Prüfung samt Lösungshinweisen als Text; füge ihn in eine KI deiner '
        'Wahl ein, um deine eigene Antwort bewerten zu lassen.',
        style: TextStyle(fontSize: 12.5, height: 1.5, color: kInkSoft),
      ),
    );
  }
}
