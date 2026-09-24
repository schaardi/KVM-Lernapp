import 'package:flutter/material.dart';

/// Streifen „Bestehenschance“ in der Prüfungskarte der Startseite (FR-014 5).
/// Die Umsetzung folgt im Paket „Prüfungen“.
class ChanceStreifen extends StatelessWidget {
  final bool kompakt;
  final VoidCallback onTap;
  const ChanceStreifen({super.key, required this.onTap, this.kompakt = false});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
