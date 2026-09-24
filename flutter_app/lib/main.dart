import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'constants.dart';
import 'services/data_service.dart';
import 'services/progress_service.dart';
import 'services/selection_service.dart';
import 'services/voice_service.dart';
import 'services/answer_store.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'services/premium_service.dart';
import 'services/lerntage_service.dart';
import 'services/letzte_pruefung.dart';
import 'theme/theme_controller.dart';
import 'features/init_cloud.dart';
import 'features/init_lernen.dart';
import 'features/init_pruefungen.dart';
import 'features/init_werkzeuge.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Config.authEnabled) {
    try {
      await Supabase.initialize(
        url: Config.supabaseUrl,
        // Supabase hat `anonKey` zugunsten von `publishableKey` abgekündigt;
        // der Wert ist derselbe (intern `publishableKey ?? anonKey`).
        publishableKey: Config.supabaseAnonKey,
      );
      AuthService.instance.ready = true;
    } catch (_) {
      AuthService.instance.ready = false; // ohne gültige Config: Offline-App
    }
  }
  await ThemeController.instance.load();
  runApp(const KvmApp());
}

class KvmApp extends StatefulWidget {
  const KvmApp({super.key});
  @override
  State<KvmApp> createState() => _KvmAppState();
}

/// Darstellung Automatisch/Hell/Dunkel (FR-002 I). Die Farbkonstanten lesen
/// aus [KvmPalette.current]; bei einem Wechsel wird die Palette getauscht und
/// jedes Element neu gebaut (wie beim Hot Reload) – ohne Zustand zu verlieren,
/// auch mitten in einer Runde.
class _KvmAppState extends State<KvmApp> with WidgetsBindingObserver {
  final _theme = ThemeController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _theme.mode.addListener(_wechsel);
    KvmPalette.current = _palette();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _theme.mode.removeListener(_wechsel);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => _wechsel();

  KvmPalette _palette() {
    final dunkel = switch (_theme.mode.value) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark,
    };
    return dunkel ? KvmPalette.dark : KvmPalette.light;
  }

  void _wechsel() {
    final neu = _palette();
    if (identical(neu, KvmPalette.current)) return;
    KvmPalette.current = neu;
    setState(() {});
    void neuBauen(Element e) {
      e.markNeedsBuild();
      e.visitChildren(neuBauen);
    }
    (context as Element).visitChildren(neuBauen);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Industriemeister Trainer',
      debugShowCheckedModeBanner: false,
      theme: themaFuer(KvmPalette.current),
      // Große Systemschrift ja, aber so begrenzt, dass die Startseite ohne
      // Scrollen und ohne Überlauf bleibt.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: child!,
      ),
      home: const _Boot(),
    );
  }
}

/// Material-Theme aus der aktuellen Palette (Schrift Inter wie im Web).
ThemeData themaFuer(KvmPalette p) {
  final scheme = ColorScheme.fromSeed(seedColor: p.petrol, brightness: p.brightness).copyWith(
    primary: p.petrol,
    onPrimary: Colors.white,
    secondary: p.amber,
    onSecondary: Colors.white,
    surface: p.paper,
    onSurface: p.ink,
    onSurfaceVariant: p.muted,
    surfaceContainerLowest: p.paper,
    surfaceContainerLow: p.paper,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surface2,
    surfaceContainerHighest: p.surface2,
    outline: p.lineStrong,
    outlineVariant: p.line,
    error: p.err,
    onError: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: p.steel,
    canvasColor: p.paper,
    dividerColor: p.line,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: p.paper,
      foregroundColor: p.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: p.paper,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
        side: BorderSide(color: p.line),
      ),
    ),
    dialogTheme: DialogThemeData(backgroundColor: p.paper, surfaceTintColor: Colors.transparent),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.paper, surfaceTintColor: Colors.transparent),
    popupMenuTheme: PopupMenuThemeData(color: p.paper, surfaceTintColor: Colors.transparent),
    chipTheme: ChipThemeData(
      backgroundColor: p.paper,
      side: BorderSide(color: p.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: p.inkSoft),
    ),
    textTheme: const TextTheme().apply(bodyColor: p.ink, displayColor: p.ink),
    iconTheme: IconThemeData(color: p.inkSoft),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.petrol,
        foregroundColor: Colors.white,
        disabledBackgroundColor: p.disabled,
        disabledForegroundColor: Colors.white70,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.petrolInk,
        side: BorderSide(color: p.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: p.petrolInk)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      hintStyle: TextStyle(color: p.placeholder),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusSm), borderSide: BorderSide(color: p.line)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusSm), borderSide: BorderSide(color: p.petrol, width: 1.6)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? null : p.toggleOff),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? null : Colors.white),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.paper,
      indicatorColor: p.petrolSoft,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: s.contains(WidgetState.selected) ? p.petrolInkDeep : p.muted)),
      iconTheme: WidgetStateProperty.resolveWith((s) =>
          IconThemeData(size: 23, color: s.contains(WidgetState.selected) ? p.petrolInkDeep : p.muted)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.petrol, linearTrackColor: p.track),
  );
}

class _Boot extends StatefulWidget {
  const _Boot();
  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  late final Future<void> _init;

  @override
  void initState() {
    super.initState();
    _init = _load();
  }

  Future<void> _load() async {
    await DataService.instance.load();
    await SelectionService.instance.load();
    await ProgressService.instance.load();
    await VoiceService.instance.init();
    await AnswerStore.instance.init();
    await LerntageService.instance.load();
    await LetztePruefung.instance.load();
    // Cloud-Sync anbinden; bei bestehender Sitzung Stand zusammenführen.
    if (Config.authEnabled && AuthService.instance.ready) {
      SyncService.instance.attach();
      if (AuthService.instance.isSignedIn) {
        await SyncService.instance.pullMergePush();
      }
    }
    // Die Pakete starten ihre Dienste (Prüfungsergebnisse, Cloud, Lernplan,
    // Werkzeuge). Ein Fehler in einem Paket darf den Start nicht verhindern.
    for (final init in [initPruefungen, initLernen, initWerkzeuge, initCloud]) {
      try {
        await init();
      } catch (_) {}
    }
    // Werbe-/Billing-SDK NICHT blockierend initialisieren: ein langsames oder
    // fehlendes SDK (z. B. ohne Google-Play-Dienste) darf den App-Start niemals
    // aufhalten. Premium-Status und Werbung aktualisieren sich reaktiv.
    unawaited(_initMonetization());
  }

  Future<void> _initMonetization() async {
    if (!Config.monetizationEnabled) return;
    // Nur den Abo-Status vorbereiten (leichtgewichtig, gekapselt). Das Werbe-SDK
    // initialisiert sich selbst erst spät bei Bedarf – nie beim App-Start.
    try {
      await PremiumService.instance.init();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _init,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator(color: kPetrol)),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(child: Text('Fehler beim Laden:\n${snap.error}')),
          );
        }
        return const AuthGate();
      },
    );
  }
}

/// Anmelde-Schranke: Login ist Pflicht. Ohne Anmeldung -> LoginScreen,
/// nach Anmeldung -> App. Reagiert live auf An-/Abmeldungen.
/// Sicherheitsnetz: ist Auth nicht konfiguriert/initialisiert, wird nicht
/// ausgesperrt (App bliebe nutzbar statt „gebrickt").
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Config.authEnabled || !AuthService.instance.ready) {
      return const HomeScreen();
    }
    return StreamBuilder<AuthState>(
      stream: AuthService.instance.onAuthChange,
      builder: (context, _) {
        return AuthService.instance.isSignedIn
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}
