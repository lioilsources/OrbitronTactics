/// Keys of the release backends, passed with --dart-define at build time.
/// Each one is optional: without it that service stays off and the game
/// works as before.
///
///   flutter build appbundle \
///     --dart-define=SENTRY_DSN=https://...@o0.ingest.sentry.io/0 \
///     --dart-define=REVENUECAT_GOOGLE_KEY=goog_... \
///     --dart-define=REVENUECAT_APPLE_KEY=appl_...
class ReleaseConstants {
  const ReleaseConstants._();

  /// Crash reports. Empty: no Sentry.
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// RevenueCat public SDK keys, one per store. Empty: the store is closed
  /// (a debug build sells for free instead, see `DebugPurchaseService`).
  static const revenueCatGoogleKey =
      String.fromEnvironment('REVENUECAT_GOOGLE_KEY');
  static const revenueCatAppleKey =
      String.fromEnvironment('REVENUECAT_APPLE_KEY');
}
