import 'package:shared_preferences/shared_preferences.dart';

/// How a purchase ended.
sealed class PurchaseOutcome {
  const PurchaseOutcome();

  /// Short name for telemetry.
  String get name;
}

/// Paid for; [owned] is every product this install now owns.
class Purchased extends PurchaseOutcome {
  const Purchased(this.owned);

  final Set<String> owned;

  @override
  String get name => 'purchased';
}

class PurchaseCancelled extends PurchaseOutcome {
  const PurchaseCancelled();

  @override
  String get name => 'cancelled';
}

/// The store takes the payment later (cash, bank transfer, parental OK);
/// the item arrives with a later sync.
class PurchasePending extends PurchaseOutcome {
  const PurchasePending();

  @override
  String get name => 'pending';
}

/// Why a purchase failed, for the player to be told in their language.
enum PurchaseFailure { storeUnavailable, notInStore, other }

class PurchaseFailed extends PurchaseOutcome {
  const PurchaseFailed(this.message, [this.failure = PurchaseFailure.other]);

  /// The store's own words, when it gave any.
  final String message;
  final PurchaseFailure failure;

  @override
  String get name => 'failed';
}

/// Thrown when the store cannot say what this install owns.
class StoreUnavailable implements Exception {
  const StoreUnavailable();

  @override
  String toString() => 'The store is not available';
}

/// The platform store, seen from the game. Ids are store product ids.
abstract class PurchaseService {
  const PurchaseService();

  /// False when nothing can be bought on this build.
  bool get available;

  /// Localized prices of the products the store knows, by id.
  Future<Map<String, String>> prices(List<String> productIds);

  /// Everything this install owns. Throws when the store cannot tell.
  Future<Set<String>> owned();

  Future<PurchaseOutcome> buy(String productId);

  /// Asks the store for earlier purchases on this account. Throws when the
  /// store cannot tell.
  Future<Set<String>> restore();
}

/// Builds without a store key, and platforms without a store.
class UnavailablePurchaseService extends PurchaseService {
  const UnavailablePurchaseService();

  @override
  bool get available => false;

  @override
  Future<Map<String, String>> prices(List<String> productIds) async => {};

  @override
  Future<Set<String>> owned() async => throw const StoreUnavailable();

  @override
  Future<PurchaseOutcome> buy(String productId) async =>
      const PurchaseFailed('The store is not available on this build',
          PurchaseFailure.storeUnavailable);

  @override
  Future<Set<String>> restore() async => throw const StoreUnavailable();
}

/// Debug builds: everything is free and kept on the device, so the store
/// can be tried without a store account.
class DebugPurchaseService extends PurchaseService {
  DebugPurchaseService(this._prefs);

  final SharedPreferences _prefs;

  static const key = 'store.debug_purchases';

  @override
  bool get available => true;

  @override
  Future<Map<String, String>> prices(List<String> productIds) async =>
      {for (final id in productIds) id: 'FREE (debug)'};

  @override
  Future<Set<String>> owned() async => {...?_prefs.getStringList(key)};

  @override
  Future<PurchaseOutcome> buy(String productId) async {
    final owned = {...await this.owned(), productId};
    await _prefs.setStringList(key, owned.toList());
    return Purchased(owned);
  }

  @override
  Future<Set<String>> restore() => owned();
}
