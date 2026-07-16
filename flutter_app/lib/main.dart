import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'constants.dart';
import 'services/data_service.dart';
import 'services/progress_service.dart';
import 'services/voice_service.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'screens/category_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Config.authEnabled) {
    try {
      await Supabase.initialize(
        url: Config.supabaseUrl,
        anonKey: Config.supabaseAnonKey,
      );
      AuthService.instance.ready = true;
    } catch (_) {
      AuthService.instance.ready = false; // ohne gültige Config: Offline-App
    }
  }
  runApp(const KvmApp());
}

class KvmApp extends StatelessWidget {
  const KvmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KVM-Trainer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPetrol,
          primary: kPetrol,
          surface: kPaper,
        ),
        scaffoldBackgroundColor: kBg,
        splashFactory: InkSparkle.splashFactory,
        cardTheme: CardThemeData(
          elevation: 0,
          color: kPaper,
          surfaceTintColor: Colors.transparent,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadius),
            side: const BorderSide(color: kLine),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: kPaper,
          side: const BorderSide(color: kLine),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kInkSoft),
        ),
        textTheme: const TextTheme().apply(bodyColor: kInk, displayColor: kInk),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: kLine),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const _Boot(),
    );
  }
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
    await ProgressService.instance.load();
    await VoiceService.instance.init();
    // Cloud-Sync anbinden; bei bestehender Sitzung Stand zusammenführen.
    if (Config.authEnabled && AuthService.instance.ready) {
      SyncService.instance.attach();
      if (AuthService.instance.isSignedIn) {
        await SyncService.instance.pullMergePush();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _init,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: kPetrol)),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(child: Text('Fehler beim Laden:\n${snap.error}')),
          );
        }
        return const CategoryScreen();
      },
    );
  }
}
