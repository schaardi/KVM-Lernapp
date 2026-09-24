import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../theme/palette.dart';
import 'erinnerung.dart';

/// Schnittstelle zu den lokalen Mitteilungen des Geräts. Die App nutzt
/// [LokaleMitteilungen]; Tests setzen eine eigene Umsetzung ein.
abstract class MitteilungsDienst {
  /// Einmal beim Start; [onTippen] läuft, wenn eine Mitteilung angetippt wird.
  Future<void> starten({VoidCallback? onTippen});

  /// Fragt die Erlaubnis an (Android 13+: `POST_NOTIFICATIONS`).
  /// `true` = Mitteilungen dürfen erscheinen.
  Future<bool> erlaubnisAnfragen();

  /// Entfernt geplante Mitteilungen.
  Future<void> abbrechen(Iterable<int> ids);

  /// Plant eine Mitteilung (ungefähre Zeit, eine Viertelstunde Spielraum).
  Future<void> planen(GeplanteErinnerung m);

  /// IDs der geplanten Mitteilungen (`pendingNotificationRequests`).
  Future<List<int>> geplant();
}

/// Ohne Plattform (Tests, Desktop, Web): tut nichts.
class KeineMitteilungen implements MitteilungsDienst {
  const KeineMitteilungen();
  @override
  Future<void> starten({VoidCallback? onTippen}) async {}
  @override
  Future<bool> erlaubnisAnfragen() async => false;
  @override
  Future<void> abbrechen(Iterable<int> ids) async {}
  @override
  Future<void> planen(GeplanteErinnerung m) async {}
  @override
  Future<List<int>> geplant() async => const [];
}

/// Android über `flutter_local_notifications`: Kanal `lernen` („Lern-Erinnerung“,
/// Wichtigkeit Standard), keine exakten Alarme (`inexactAllowWhileIdle`).
///
/// Die Zeitpunkte kommen als absolute Zeit (UTC): Die Ortszeit samt
/// Sommerzeit rechnet Dart aus dem Gerät (`DateTime(j, m, t, h, min)`), so
/// braucht es weder Zeitzonen-Datenbank noch ein Plugin für den Zonennamen.
class LokaleMitteilungen implements MitteilungsDienst {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  AndroidFlutterLocalNotificationsPlugin? _android;

  /// Nur auf Android – sonst (Tests, Desktop, Web) bleibt alles aus.
  static bool get unterstuetzt => !kIsWeb && Platform.isAndroid;

  bool get _bereit => _android != null;

  @override
  Future<void> starten({VoidCallback? onTippen}) async {
    if (!unterstuetzt || _bereit) return;
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_lernen')),
      onDidReceiveNotificationResponse: (_) => onTippen?.call(),
    );
    _android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  }

  @override
  Future<bool> erlaubnisAnfragen() async {
    final a = _android;
    if (a == null) return false;
    // Unter Android 12 und älter gibt es keine Nachfrage (null) – dann zählt,
    // ob Mitteilungen in den Systemeinstellungen an sind.
    final ok = await a.requestNotificationsPermission();
    if (ok == false) return false;
    return await a.areNotificationsEnabled() ?? true;
  }

  @override
  Future<void> abbrechen(Iterable<int> ids) async {
    final a = _android;
    if (a == null) return;
    for (final id in ids) {
      await a.cancel(id: id);
    }
  }

  @override
  Future<void> planen(GeplanteErinnerung m) async {
    final a = _android;
    if (a == null) return;
    await a.zonedSchedule(
      id: m.id,
      title: m.titel,
      body: m.text,
      scheduledDate: tz.TZDateTime.from(m.zeit, tz.UTC),
      notificationDetails: AndroidNotificationDetails(
        'lernen',
        'Lern-Erinnerung',
        channelDescription: 'Tägliche Erinnerung zum Lernen zur gewählten Uhrzeit.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: 'ic_stat_lernen',
        color: KvmPalette.light.petrol,
        styleInformation: BigTextStyleInformation(m.text),
      ),
      scheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<List<int>> geplant() async {
    final a = _android;
    if (a == null) return const [];
    final l = await a.pendingNotificationRequests();
    return [for (final r in l) r.id];
  }
}
