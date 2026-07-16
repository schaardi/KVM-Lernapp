import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

/// Konto-Sheet: Google-Login und Sync-Status. Nur relevant, wenn Login
/// konfiguriert ist (Config.authEnabled) – der Aufrufer blendet den Zugang aus,
/// wenn nicht.
void showAccountSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: kPaper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AccountSheet(),
  );
}

class _AccountSheet extends StatefulWidget {
  const _AccountSheet();
  @override
  State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() { _busy = true; _error = null; });
    try {
      final ok = await AuthService.instance.signInWithGoogle();
      if (ok) {
        await SyncService.instance.pullMergePush();
      }
    } catch (e) {
      _error = 'Anmeldung fehlgeschlagen. Bitte erneut versuchen.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    await AuthService.instance.signOut();
    // Sheet schließen -> der AuthGate zeigt wieder den Pflicht-Login.
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final signedIn = auth.isSignedIn;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: kLine, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          const Text('Konto & Synchronisierung',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kInk)),
          const SizedBox(height: 6),
          Text(
            signedIn
                ? 'Dein Lernfortschritt wird geräteübergreifend gesichert.'
                : 'Melde dich an, damit dein Lernfortschritt auf allen Geräten verfügbar ist.',
            style: const TextStyle(color: kMuted, height: 1.35),
          ),
          const SizedBox(height: 18),

          if (signedIn) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kOkSoft,
                borderRadius: BorderRadius.circular(kRadiusSm),
              ),
              child: Row(children: [
                const Icon(Icons.cloud_done_outlined, color: kOk),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(auth.displayName ?? auth.email ?? 'Angemeldet',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                    if (auth.email != null && auth.displayName != null)
                      Text(auth.email!, style: const TextStyle(fontSize: 12, color: kMuted)),
                    const Text('Fortschritt wird synchronisiert',
                        style: TextStyle(fontSize: 12, color: kOk, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _signOut,
                style: OutlinedButton.styleFrom(
                    foregroundColor: kErr, padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Abmelden'),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _signIn,
                style: FilledButton.styleFrom(
                    backgroundColor: kInk, padding: const EdgeInsets.symmetric(vertical: 15)),
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.g_mobiledata, size: 26),
                label: Text(_busy ? 'Anmelden …' : 'Mit Google anmelden'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: kErr, fontSize: 13)),
            ],
          ],
        ]),
      ),
    );
  }
}
