import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config.dart';
import '../constants.dart';
import 'premium_service.dart';

/// Interstitial-Werbung (Freemium): nach je [kAdEveryQuestions] beantworteten
/// Fragen eine Vollbild-Anzeige an einem natürlichen Übergang – außer für
/// Premium-/Werbefrei-Nutzer. Fehler beim Laden/Anzeigen blockieren nie das Quiz.
class AdService {
  static final AdService instance = AdService._();
  AdService._();

  bool _ready = false;
  bool _loading = false;
  InterstitialAd? _interstitial;
  int _answered = 0;

  bool get _active =>
      Config.monetizationEnabled && !PremiumService.instance.isPremiumNow;

  Future<void> init() async {
    if (!Config.monetizationEnabled) return;
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
  }

  /// Nach jeder beantworteten Frage aufrufen.
  void onAnswered() {
    if (!_active) return;
    _answered++;
  }

  /// An einem natürlichen Übergang (z. B. „Weiter") aufrufen.
  void maybeShowInterstitial() {
    if (!_active) return;
    if (_answered < kAdEveryQuestions) return;
    final ad = _interstitial;
    if (ad == null) {
      _load(); // fürs nächste Mal vorbereiten; dieser Übergang bleibt werbefrei
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
    ad.show();
  }
}
