import 'package:flutter/material.dart';
import 'constants.dart';
import 'services/data_service.dart';
import 'services/progress_service.dart';
import 'services/voice_service.dart';
import 'screens/home_screen.dart';

void main() {
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
        ),
        scaffoldBackgroundColor: const Color(0xFFEDF1F3),
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
        return const HomeScreen();
      },
    );
  }
}
