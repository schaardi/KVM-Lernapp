import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Startschutz (Android): merkt sich den laufenden Startschritt in einer Datei
/// – die übersteht auch einen harten Absturz – und erfährt vom nativen Teil
/// (`Startschutz.kt`), ob der letzte Lauf abgestürzt ist.
///
/// Nach einem Absturz beim Start läuft die App im sicheren Modus: ohne
/// Anmeldung und Cloud, Vorlesen, Erinnerungen und Werbung. Der Lernstand auf
/// dem Gerät bleibt davon unberührt. Den Bericht zeigt die App einmal nach
/// dem Start und danach auf der Konto-Seite.
class Startschutz {
  Startschutz._();
  static final Startschutz instance = Startschutz._();

  static const _kanal = MethodChannel('kvm/startschutz');

  /// Tests schalten den Android-Teil hiermit ein.
  @visibleForTesting
  static bool? debugAndroid;

  static bool get _android => debugAndroid ?? (!kIsWeb && Platform.isAndroid);

  String? _ordner;

  /// Sicherer Modus in diesem Lauf.
  bool sicher = false;

  /// Zeichnet mit Skia statt Impeller (nach einem nativen Absturz).
  bool skia = false;

  /// Beim Start neu erkannter Bericht – einmal anzeigen.
  bool neuerBericht = false;

  /// Gibt es einen gespeicherten Bericht (Konto-Seite)?
  bool berichtVorhanden = false;

  /// Schritt, bei dem der letzte Start abbrach.
  String? abgebrochenBei;

  /// Läuft der Startschutz (nur Android mit nativem Teil)?
  bool get aktiv => _ordner != null;

  /// Liest den Stand vom nativen Teil – als Erstes in `main()`.
  Future<void> laden() async {
    if (!_android) return;
    try {
      final m = await _kanal.invokeMapMethod<String, Object?>('stand');
      if (m == null) return;
      _ordner = m['ordner'] as String?;
      sicher = m['sicher'] == true;
      skia = m['skia'] == true;
      neuerBericht = m['neuerBericht'] == true;
      berichtVorhanden = m['berichtVorhanden'] == true;
      abgebrochenBei = m['abgebrochenBei'] as String?;
    } catch (_) {}
  }

  /// Tests: alles zurück auf Anfang.
  @visibleForTesting
  void debugZuruecksetzen() {
    _ordner = null;
    sicher = false;
    skia = false;
    neuerBericht = false;
    berichtVorhanden = false;
    abgebrochenBei = null;
  }

  /// Merkt sich den Schritt, der gerade startet – synchron, damit ein
  /// Absturz direkt danach ihn nicht verliert.
  void schritt(String name) {
    final o = _ordner;
    if (o == null) return;
    try {
      File('$o/schritt.txt').writeAsStringSync(name);
    } catch (_) {}
  }

  /// Der Start ist durch (die Startseite steht seit ein paar Sekunden).
  Future<void> fertig() async {
    if (!_android) return;
    schritt('fertig');
    try {
      await _kanal.invokeMethod<void>('fertig');
    } catch (_) {}
  }

  /// Gespeicherter Bericht samt Systemprotokoll (oder `null`).
  Future<String?> bericht() async {
    if (!_android) return null;
    try {
      return await _kanal.invokeMethod<String>('bericht');
    } catch (_) {
      return null;
    }
  }

  /// Beim nächsten Start wieder alles laden.
  Future<void> normalStarten() async {
    if (!_android) return;
    try {
      await _kanal.invokeMethod<void>('normal');
    } catch (_) {}
  }

  Future<void> berichtLoeschen() async {
    if (!_android) return;
    berichtVorhanden = false;
    try {
      await _kanal.invokeMethod<void>('berichtLoeschen');
    } catch (_) {}
  }

  /// Teilen-Menü des Systems (E-Mail, Messenger …).
  Future<void> teilen(String text) async {
    if (!_android) return;
    try {
      await _kanal.invokeMethod<void>('teilen', {'text': text});
    } catch (_) {}
  }
}
