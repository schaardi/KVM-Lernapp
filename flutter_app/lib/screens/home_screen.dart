// Die Seiten werden bei jeder Änderung des App-Zustands neu gebaut – daher
// bewusst ohne `const`.
// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../constants.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../widgets/ui.dart';
import 'pages/konto_seite.dart';
import 'pages/lernen_seite.dart';
import 'pages/pruefungen_seite.dart';
import 'pages/start_seite.dart';
import 'pages/vergleich_seite.dart';

/// Startansicht mit fünf Seiten unter einer Navigation (FR-015): unten auf dem
/// Handy, oben ab 900 dp. Android-Zurück führt von einer Unterseite nach Start.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _Ziel {
  final AppSeite seite;
  final IconData icon;
  final IconData iconAktiv;
  final String label;
  const _Ziel(this.seite, this.icon, this.iconAktiv, this.label);
}

const _ziele = [
  _Ziel(AppSeite.start, Icons.home_outlined, Icons.home, 'Start'),
  _Ziel(AppSeite.lernen, Icons.menu_book_outlined, Icons.menu_book, 'Lernen'),
  _Ziel(AppSeite.pruefungen, Icons.assignment_turned_in_outlined, Icons.assignment_turned_in, 'Prüfungen'),
  _Ziel(AppSeite.vergleich, Icons.emoji_events_outlined, Icons.emoji_events, 'Vergleich'),
  _Ziel(AppSeite.konto, Icons.person_outline, Icons.person, 'Konto'),
];

class _HomeScreenState extends State<HomeScreen> {
  final _st = AppState.instance;

  @override
  void initState() {
    super.initState();
    // Erstes Basisfach mit Fragen vorwählen.
    final counts = DataService.instance.fachCounts();
    if ((counts[_st.fach] ?? 0) == 0) {
      for (var f = 1; f <= 5; f++) {
        if ((counts[f] ?? 0) > 0) {
          _st.fach = f;
          break;
        }
      }
    }
    _st.addListener(_neu);
    _st.vergleichVerfuegbar.addListener(_vergleichGeaendert);
    _st.vergleichHinweis.addListener(_neu);
    _vergleichPruefen();
  }

  @override
  void dispose() {
    _st.removeListener(_neu);
    _st.vergleichVerfuegbar.removeListener(_vergleichGeaendert);
    _st.vergleichHinweis.removeListener(_neu);
    super.dispose();
  }

  void _neu() {
    if (mounted) setState(() {});
  }

  void _vergleichGeaendert() {
    if (_st.vergleichVerfuegbar.value == false && _st.seite == AppSeite.vergleich) {
      _st.geheZu(AppSeite.start);
    }
    _neu();
  }

  /// Gibt es die Rangliste (docs/supabase-rangliste.sql)? Sonst entfällt der
  /// Reiter „Vergleich“.
  Future<void> _vergleichPruefen() async {
    if (!Config.authEnabled || !AuthService.instance.ready) {
      _st.vergleichVerfuegbar.value = false;
      return;
    }
    try {
      await Supabase.instance.client.rpc('rangliste_info');
      _st.vergleichVerfuegbar.value = true;
    } catch (_) {
      _st.vergleichVerfuegbar.value = false;
    }
  }

  List<_Ziel> get _sichtbar =>
      _ziele.where((z) => z.seite != AppSeite.vergleich || _st.vergleichVerfuegbar.value != false).toList();

  Widget _seite(AppSeite s) => switch (s) {
        AppSeite.start => StartSeite(),
        AppSeite.lernen => LernenSeite(),
        AppSeite.pruefungen => PruefungenSeite(),
        AppSeite.vergleich => VergleichSeite(),
        AppSeite.konto => KontoSeite(),
      };

  Widget _symbol(_Ziel z, bool aktiv) {
    final icon = Icon(aktiv ? z.iconAktiv : z.icon);
    if (z.seite != AppSeite.vergleich) return icon;
    return Badge(
      isLabelVisible: _st.vergleichHinweis.value,
      smallSize: 9,
      backgroundColor: kAmber,
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final breit = MediaQuery.sizeOf(context).width >= 900;
    final ziele = _sichtbar;
    final aktiv = ziele.indexWhere((z) => z.seite == _st.seite);
    final index = aktiv < 0 ? 0 : aktiv;
    // Alle Seiten bleiben erhalten (Zustand, Scrollposition); sichtbar ist eine.
    final stapel = IndexedStack(
      index: AppSeite.values.indexOf(ziele[index].seite),
      children: [for (final s in AppSeite.values) _seite(s)],
    );

    return PopScope(
      canPop: _st.seite == AppSeite.start,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _st.geheZu(AppSeite.start);
      },
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          bottom: false,
          child: breit
              ? Column(children: [
                  _obenLeiste(ziele, index),
                  Expanded(child: stapel),
                ])
              : stapel,
        ),
        bottomNavigationBar: breit
            ? null
            : NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (i) => _st.geheZu(ziele[i].seite),
                backgroundColor: kPaper,
                indicatorColor: kPetrolSoft,
                surfaceTintColor: Colors.transparent,
                height: 64,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  for (var i = 0; i < ziele.length; i++)
                    NavigationDestination(
                      icon: _symbol(ziele[i], false),
                      selectedIcon: _symbol(ziele[i], true),
                      label: ziele[i].label,
                      tooltip: ziele[i].seite == AppSeite.vergleich && _st.vergleichHinweis.value
                          ? 'Vergleich – eine Einladung oder Anfrage wartet'
                          : ziele[i].label,
                    ),
                ],
              ),
      ),
    );
  }

  /// Ab 900 dp: schwebende Pillenleiste oben mit dem Namen links.
  Widget _obenLeiste(List<_Ziel> ziele, int index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: kPaper,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: kLine),
            boxShadow: kSoftShadow,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
              child: Text('MEISTER FÜR KRAFTVERKEHR', style: dispStyle(16)),
            ),
            for (var i = 0; i < ziele.length; i++)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Material(
                  color: i == index ? kPetrolSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: () => _st.geheZu(ziele[i].seite),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconTheme(
                          data: IconThemeData(size: 19, color: i == index ? kPetrolInkDeep : kMuted),
                          child: _symbol(ziele[i], i == index),
                        ),
                        const SizedBox(width: 8),
                        Text(ziele[i].label,
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: i == index ? kPetrolInkDeep : kMuted)),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
