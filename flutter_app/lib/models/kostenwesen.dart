import 'package:flutter/material.dart';

/// Datenmodell für das Lernmodul „Betriebliches Kostenwesen".

class KwFormula {
  final String name;
  final String formula;
  final String? note;
  const KwFormula(this.name, this.formula, {this.note});
}

class KwExample {
  final String task;
  final List<String> steps;
  final String result;
  const KwExample({required this.task, required this.steps, required this.result});
}

class KwSection {
  final String title;

  /// Erklärtext in Alltagssprache.
  final String body;

  /// Kernpunkte als Aufzählung.
  final List<String> bullets;

  /// Rechenschema, zeilenweise (wird monospace dargestellt).
  final List<String> scheme;

  final List<KwFormula> formulas;
  final KwExample? example;

  /// Merksatz – das, was sitzen muss.
  final String? merke;

  /// Typische Falle in der Prüfung.
  final String? falle;

  const KwSection({
    required this.title,
    this.body = '',
    this.bullets = const [],
    this.scheme = const [],
    this.formulas = const [],
    this.example,
    this.merke,
    this.falle,
  });
}

class KwChapter {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<KwSection> sections;
  const KwChapter({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.sections,
  });
}
