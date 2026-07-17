import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config.dart';
import '../constants.dart';
import 'premium_service.dart';

/// Interstitial-Werbung (Freemium). Das Werbe-SDK wird bewusst **nicht** beim
/// App-Start initialisiert, sondern erst kurz bevor die erste Werbung fällig
/// wird. So kann das SDK den Start niemals blockieren oder zum Absturz bringen.
/// Alle Aufrufe sind gekapselt – Werbefehler bleiben ohne Folgen fürs Quiz.
class AdService {
  static final AdService instance = AdService._();
  AdService._();

  bool _initStarted = false;
  bool _ready = false;
  bool _loading = false;
  InterstitialAd? _interstitial;
  int _answered = 0;

  bool get _active =>
      Config.monetizationEnabled && !PremiumService.instance.isPremiumNow;

  /// Initialisiert das Werbe-SDK genau einmal – erst bei tatsächlichem Bedarf,
  /// nie beim App-Start.
  Future<void> _ensureInit() async {
    if (_initStarted || !Config.monetizationEnabled) return;
    _initStarted = true;
    try {
      await MobileAds.instance.initialize();
      _ready = true;
      _load();
    } catch (_) {
      _ready = false;
    }
  }

  void _load() {
    if (!_ready || _loading || _interstitial != null) return;
    _loading = true;
    try {
      InterstitialAd.load(
        adUnitId: Config.admobInterstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitial = ad;
            _loading = false;
          },
          onAdFailedToLoad: (_) {
            _interstitial = null;
            _loading = false;
          },
        ),
      );
    } catch (_) {
      _loading = false;
    }
  }

  /// Nach jeder beantworteten Frage aufrufen.
  void onAnswered() {
    if (!_active) return;
    _answered++;
    // Kurz vor der Schwelle das SDK vorbereiten – nie beim App-Start.
    if (!_initStarted && _answered >= kAdEveryQuestions - 2) {
      _ensureInit();
    }
  }

  /// An einem natürlichen Übergang (z. B. „Weiter") aufrufen.
  void maybeShowInterstitial() {
    if (!_active) return;
    if (_answered < kAdEveryQuestions) return;
    if (!_initStarted) {
      _ensureInit(); // beim nächsten Übergang steht die Werbung bereit
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      _load();
      return;
    }
    _answered = 0;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _load();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _load();
      },
    );
    try {
      ad.show();
    } catch (_) {}
  }
}
