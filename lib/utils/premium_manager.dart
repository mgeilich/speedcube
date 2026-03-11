import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// A service to manage premium subscription state and In-App Purchases.
class PremiumManager extends ChangeNotifier {
  static final PremiumManager _instance = PremiumManager._internal();
  factory PremiumManager() => _instance;
  PremiumManager._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  bool _isPremium = false;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;

  static const String _kPremiumKey = 'premium_unlocked';
  static const String _kSubscriptionId = 'speedcube_pro_yearly';

  /// Whether the user has unlocked premium features.
  bool get isPremium => _isPremium;
  
  /// The list of available products from the store.
  List<ProductDetails> get products => _products;

  /// Whether the store is available.
  bool get isAvailable => _isAvailable;

  /// Initialize IAP and load purchase history.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_kPremiumKey) ?? false;
    notifyListeners();

    _isAvailable = await _iap.isAvailable();
    if (_isAvailable) {
      // Listen to purchase updates
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription.cancel(),
        onError: (error) => debugPrint('IAP Error: $error'),
      );
      
      // Load products
      await loadProducts();
    }
  }

  /// Load product details from the App Store/Play Store.
  Future<void> loadProducts() async {
    const ids = {_kSubscriptionId};
    final response = await _iap.queryProductDetails(ids);
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }
    _products = response.productDetails;
    notifyListeners();
  }

  /// Start the purchase flow.
  Future<void> buyPremium() async {
    // Debug override for simulator screenshots
    if (kDebugMode) {
      debugPrint('DEBUG: Instantly unlocking premium for simulator testing.');
      await _unlockPremium();
      return;
    }

    if (_products.isEmpty) await loadProducts();
    if (_products.isEmpty) return;

    final productDetails = _products.firstWhere(
      (p) => p.id == _kSubscriptionId,
      orElse: () => _products.first,
    );

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restore previous purchases.
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _unlockPremium();
      }
      
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _unlockPremium() async {
    _isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPremiumKey, true);
    notifyListeners();
  }

  /// Reset premium status (for testing/demo purposes).
  Future<void> reset() async {
    _isPremium = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPremiumKey, false);
    notifyListeners();
  }

  /// Logic for gating features.
  bool canAccessFeature(String featureId) {
    if (isPremium) return true;

    const gatedFeatures = [
      'ar_scan',
      'advanced_scramble',
      'lbl_solver',
      'detailed_explanations'
    ];
    return !gatedFeatures.contains(featureId);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
