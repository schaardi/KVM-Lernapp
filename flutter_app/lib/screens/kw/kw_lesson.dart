import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/kostenwesen.dart';

/// Kapitelansicht: Erklärung, Merksätze, Formeln, Beispiel, Prüfungsfalle.
class KwLessonScreen extends StatelessWidget {
  final KwChapter chapter;
  const KwLessonScreen({super.key, required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPaper,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(chapter.title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
          Text('${chapter.sections.length} Abschnitte',
              style: const TextStyle(fontSize: 11.5, color: kMuted)),
        ]),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
          itemCount: chapter.sections.length,
          itemBuilder: (_, i) => _section(chapter.sections[i], i + 1),
        ),
      ),
    );
  }

  Widget _section(KwSection s, int nr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kLine),
        boxShadow: kSoftShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 26, height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: chapter.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8)),
            child: Text('$nr',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: chapter.color)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(s.title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: kInk)),
          ),
        ]),
        if (s.body.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(s.body,
              style: const TextStyle(fontSize: 14.5, height: 1.6, color: kInkSoft)),
        ],
        if (s.bullets.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final b in s.bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 10),
                  child: Container(
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                        color: chapter.color, shape: BoxShape.circle),
                  ),
                ),
                Expanded(
                  child: Text(b,
                      style: const TextStyle(
                          fontSize: 13.5, height: 1.5, color: kInkSoft)),
                ),
              ]),
            ),
        ],
        if (s.scheme.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: kBgTint,
              borderRadius: BorderRadius.circular(kRadiusSm),
              border: Border.all(color: kLine),
            ),
            child: Text(
              s.scheme.join('\n'),
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  height: 1.65,
                  color: kInk),
            ),
          ),
        ],
        if (s.formulas.isNotEmpty) ...[
          const SizedBox(height: 14),
          for (final f in s.formulas)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPetrolSoft.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(kRadiusSm),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: kPetrolDeep,
                        letterSpacing: 0.2)),
                const SizedBox(height: 4),
                Text(f.formula,
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        color: kInk)),
                if (f.note != null) ...[
                  const SizedBox(height: 4),
                  Text(f.note!,
                      style: const TextStyle(
                          fontSize: 12, color: kMuted, height: 1.4)),
                ],
              ]),
            ),
        ],
        if (s.merke != null) ...[
          const SizedBox(height: 6),
          _box(Icons.push_pin_outlined, 'Merke', s.merke!, kOk),
        ],
        if (s.example != null) ...[
          const SizedBox(height: 6),
          _example(s.example!),
        ],
        if (s.falle != null) ...[
          const SizedBox(height: 6),
          _box(Icons.warning_amber_rounded, 'Prüfungsfalle', s.falle!, kErr),
        ],
      ]),
    );
  }

  Widget _box(IconData icon, String title, String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(kRadiusSm),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 3),
            Text(text,
                style: const TextStyle(
                    fontSize: 13.5, height: 1.5, color: kInkSoft)),
          ]),
        ),
      ]),
    );
  }

  Widget _example(KwExample e) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBgTint.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(kRadiusSm),
        border: Border.all(color: kLine),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.edit_note, size: 19, color: chapter.color),
          const SizedBox(width: 8),
          Text('Beispiel',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: chapter.color)),
        ]),
        const SizedBox(height: 8),
        Text(e.task,
            style: const TextStyle(
                fontSize: 13.5, height: 1.5, color: kInk, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        for (final s in e.steps)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('→ ', style: TextStyle(color: kMuted, fontSize: 13)),
              Expanded(
                child: Text(s,
                    style: const TextStyle(
                        fontSize: 13, height: 1.5, color: kInkSoft)),
              ),
            ]),
          ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: kOkSoft,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(e.result,
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w800, color: kOk)),
        ),
      ]),
    );
  }
}
