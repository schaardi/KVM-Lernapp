import 'package:flutter/material.dart';

/// Einstieg „Mündlich üben“ (FR-011) – von der Startseite (Kachel) und der
/// Seite „Lernen“ (Moduskarte). Die Umsetzung folgt im Paket „Lernen“.
Future<void> starteMuendlich(BuildContext context) async {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Mündlich üben kommt mit dem nächsten Update.')));
}
