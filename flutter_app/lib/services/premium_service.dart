import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

/// Werbefrei-Abo (Freemium). Google Play verwaltet das Abo pro Konto und
/// synchronisiert es geräteübergreifend; der Status wird lokal gespiegelt, damit
/// die App offline sofort weiß, ob sie werbefrei ist. Quelle der Wahrheit: Play.
class PremiumService {
  static final PremiumService instance = PremiumService._();
  PremiumService._();

  static const _key = 'kvm_premium_v1';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  SharedPreferences? _prefs;

  /// Reaktiver Premium-Status fürs UI (ValueListenableBuilder).
  final ValueNotifier<bool> isPremium = ValueNotifier<bool>(false);

  /// Store erreichbar (Abo überhaupt kaufbar)?
  bool storeAvailable = false;

  /// Verfügbare Produkte (i. d. R. genau das Abo).
  final List<ProductDetails> products = [];

  bool get isPremiumNow => isPremium.value;

  /// Angezeigter Preis – echter Store-Preis, sonst Fallback.
  String get priceLabel =>
      products.isNotEmpty ? products.first.price : '5,99 €';

  Future<void> init() async {
    if (!Config.monetizationEnabled) return;
    _prefs = await SharedPreferences.getInstance();
    isPremium.value = _prefs!.getBool(_key) ?? false;

    try {
      storeAvailable = await _iap.isAvailable();
    } catch (_) {
      storeAvailable = false;
    }
    if (!storeAvailable) return;

    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (_) {});

    try {
      final resp = await _iap.queryProductDetails({Config.premiumProductId});
      products
        ..clear()
        ..addAll(resp.productDetails);
    } catch (_) {}

    // Bestehendes Abo wiederherstellen (liefert Käufe erneut über den Stream).
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    var premium = isPremium.value;
    for (final p in purchases) {
      if (p.productID != Config.premiumProductId) continue;
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        premium = true;
      }
      if (p.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(p);
        } catch (_) {}
      }
    }
    await _setPremium(premium);
  }

  Future<void> _setPremium(bool v) async {
    isPremium.value = v;
    await _prefs?.setBool(_key, v);
  }

  /// Abo starten. Gibt false zurück, wenn kein Produkt verfügbar ist
  /// (z. B. Abo in der Play Console noch nicht eingerichtet).
  Future<bool> buy() async {
    if (!storeAvailable || products.isEmpty) return false;
    final param = PurchaseParam(productDetails: products.first);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    if (!storeAvailable) return;
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  void dispose() {
    _sub?.cancel();
  }
}
