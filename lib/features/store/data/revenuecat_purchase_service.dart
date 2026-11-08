import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'purchase_service.dart';

/// Google Play and the App Store through RevenueCat, which checks the
/// receipts and remembers what this install bought. Every product is a
/// one-time purchase; the game maps product ids to content itself, so no
/// RevenueCat entitlements need setting up.
class RevenueCatPurchaseService extends PurchaseService {
  RevenueCatPurchaseService(this._apiKey);

  final String _apiKey;
  Future<void>? _configured;
  final Map<String, StoreProduct> _products = {};

  Future<void> _ready() =>
      _configured ??= Purchases.configure(PurchasesConfiguration(_apiKey));

  @override
  bool get available => true;

  @override
  Future<Map<String, String>> prices(List<String> productIds) async {
    await _ready();
    final products = await Purchases.getProducts(
      productIds,
      productCategory: ProductCategory.nonSubscription,
    );
    for (final product in products) {
      _products[_baseId(product.identifier)] = product;
    }
    return {
      for (final entry in _products.entries) entry.key: entry.value.priceString,
    };
  }

  @override
  Future<Set<String>> owned() async {
    await _ready();
    return _ids(await Purchases.getCustomerInfo());
  }

  @override
  Future<PurchaseOutcome> buy(String productId) async {
    try {
      await _ready();
      if (!_products.containsKey(productId)) await prices([productId]);
      final product = _products[productId];
      if (product == null) {
        return const PurchaseFailed('This item is not in the store yet');
      }
      final result =
          await Purchases.purchase(PurchaseParams.storeProduct(product));
      return Purchased(_ids(result.customerInfo));
    } on PlatformException catch (error) {
      return switch (PurchasesErrorHelper.getErrorCode(error)) {
        PurchasesErrorCode.purchaseCancelledError => const PurchaseCancelled(),
        PurchasesErrorCode.paymentPendingError => const PurchasePending(),
        PurchasesErrorCode.productAlreadyPurchasedError =>
          Purchased(await owned()),
        _ => PurchaseFailed(error.message ?? 'The purchase did not go through'),
      };
    }
  }

  @override
  Future<Set<String>> restore() async {
    await _ready();
    return _ids(await Purchases.restorePurchases());
  }

  static Set<String> _ids(CustomerInfo info) => {
        for (final id in info.allPurchasedProductIdentifiers) _baseId(id),
      };

  /// Google may report a product as `id:option`; the game knows the id.
  static String _baseId(String id) => id.split(':').first;
}
