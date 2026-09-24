import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

/// Pflicht-Anmeldung: ohne Google-Login kein Zugang zur App.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() { _busy = true; _error = null; });
    try {
      final ok = await AuthService.instance.signInWithGoogle();
      if (ok) {
        await SyncService.instance.pullMergePush();
        // Weiterleitung übernimmt der AuthGate (reagiert auf den Auth-Status).
      }
    } catch (_) {
      _error = 'Anmeldung fehlgeschlagen. Bitte erneut versuchen.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Monogramm / Logo
              Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(color: Color(0x330D2B57), blurRadius: 18, offset: Offset(0, 8)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset('assets/branding/app_logo.png',
                      width: 76, height: 76, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 22),
              Text('Meister-Trainer',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kInk, height: 1.15)),
              const SizedBox(height: 4),
              Text('Kraftverkehr & Basisqualifikationen',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kPetrolInk)),
              const SizedBox(height: 12),
              Text(
                'Melde dich an, damit dein Lernfortschritt auf allen deinen Geräten '
                'verfügbar ist und gesichert bleibt.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kMuted, height: 1.4, fontSize: 14),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _signIn,
                  // Dunkle Fläche im hellen Modus, helle im dunklen – die Schrift
                  // nimmt jeweils die Gegenfarbe (Seitenfarbe).
                  style: FilledButton.styleFrom(
                      backgroundColor: kInk,
                      foregroundColor: kBg,
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: _busy
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kBg))
                      : const Icon(Icons.g_mobiledata, size: 28),
                  label: Text(_busy ? 'Anmelden …' : 'Mit Google anmelden',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, textAlign: TextAlign.center,
                    style: TextStyle(color: kErr, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              Text('Anmeldung erforderlich',
                  style: TextStyle(color: kMuted, fontSize: 11.5, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }
}
