/// Route paths and names.
///
/// Never type a path literal at a call site: use these constants so a rename is
/// a single edit and deep links stay consistent with the Android intent filter
/// declared in `AndroidManifest.xml`.
abstract final class AppRoutes {
  /// The card deck. It is the whole app, so it sits at the root.
  static const String homePath = '/';
  static const String homeName = 'deck';

  static const String settingsPath = '/settings';
  static const String settingsName = 'settings';

  /// Paywall. Reachable by deep link so a campaign can land directly on it.
  static const String paywallPath = '/premium';
  static const String paywallName = 'premium';
}
