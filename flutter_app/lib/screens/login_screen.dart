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
              // Monogramm
              Container(
                width: 76, height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [kPetrol, kPetrolDeep],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(color: Color(0x330C6C78), blurRadius: 18, offset: Offset(0, 8)),
                  ],
                ),
                child: const Icon(Icons.workspace_premium, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 22),
              const Text('KVM-Trainer',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kInk)),
              const SizedBox(height: 8),
              const Text(
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
                  style: FilledButton.styleFrom(
                      backgroundColor: kInk, padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.g_mobiledata, size: 28),
                  label: Text(_busy ? 'Anmelden …' : 'Mit Google anmelden',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, textAlign: TextAlign.center,
                    style: const TextStyle(color: kErr, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              const Text('Anmeldung erforderlich',
                  style: TextStyle(color: kMuted, fontSize: 11.5, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }
}
