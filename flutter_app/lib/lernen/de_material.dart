import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Deutsche Beschriftungen für Kalender und Dialoge der Lernen-Bausteine.
///
/// Die App bindet `flutter_localizations` (noch) nicht ein; ohne diese Hilfe
/// zeigte die Datumsauswahl englische Monate und Wochentage. [deutsch] legt
/// die Übersetzung nur um den eigenen Baustein.
class DeMaterialLocalizations extends DefaultMaterialLocalizations {
  const DeMaterialLocalizations();

  static const LocalizationsDelegate<MaterialLocalizations> delegate = _DeDelegate();

  static const List<String> _monate = [
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
  ];
  static const List<String> _monateKurz = [
    'Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', 'Juli', 'Aug.', 'Sept.', 'Okt.', 'Nov.', 'Dez.',
  ];
  static const List<String> _tage = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
  static const List<String> _tageKurz = ['Mo.', 'Di.', 'Mi.', 'Do.', 'Fr.', 'Sa.', 'So.'];

  String _zwei(int x) => x.toString().padLeft(2, '0');

  @override
  String formatMonthYear(DateTime date) => '${_monate[date.month - 1]} ${date.year}';

  @override
  String formatFullDate(DateTime date) =>
      '${_tage[date.weekday - 1]}, ${date.day}. ${_monate[date.month - 1]} ${date.year}';

  @override
  String formatMediumDate(DateTime date) => '${_tageKurz[date.weekday - 1]}, ${date.day}. ${_monateKurz[date.month - 1]}';

  @override
  String formatShortDate(DateTime date) => '${_zwei(date.day)}.${_zwei(date.month)}.${date.year}';

  @override
  String formatCompactDate(DateTime date) => formatShortDate(date);

  @override
  String formatShortMonthDay(DateTime date) => '${date.day}. ${_monateKurz[date.month - 1]}';

  // Kürzel ab Sonntag, so erwartet es der Material-Kalender; die Woche beginnt
  // am Montag.
  @override
  List<String> get narrowWeekdays => const ['S', 'M', 'D', 'M', 'D', 'F', 'S'];

  @override
  int get firstDayOfWeekIndex => 1;

  @override
  String get previousMonthTooltip => 'Vorheriger Monat';

  @override
  String get nextMonthTooltip => 'Nächster Monat';

  @override
  String get selectYearSemanticsLabel => 'Jahr auswählen';

  @override
  String get currentDateLabel => 'Heute';

  @override
  String get selectedDateLabel => 'Ausgewählt';

  @override
  String get datePickerHelpText => 'Datum auswählen';

  @override
  String get cancelButtonLabel => 'Abbrechen';

  @override
  String get okButtonLabel => 'OK';

  @override
  String get closeButtonTooltip => 'Schließen';

  @override
  String get modalBarrierDismissLabel => 'Schließen';
}

class _DeDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _DeDelegate();
  @override
  bool isSupported(Locale locale) => true;
  // Synchron wie Flutters eigene Übersetzungen – sonst bliebe das Blatt einen
  // Frame lang leer.
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(const DeMaterialLocalizations());
  @override
  bool shouldReload(_DeDelegate old) => false;
}

/// Legt die deutschen Beschriftungen um [child].
Widget deutsch(BuildContext context, Widget child) => Localizations.override(
      context: context,
      delegates: const [DeMaterialLocalizations.delegate],
      child: child,
    );
