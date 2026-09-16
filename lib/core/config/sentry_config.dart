/// Crash reporting (Sentry).
///
/// Mirrors [AdConfig]'s pattern: the DSN is a single constant, gated by
/// [AppConfig.useProductionAds]'s sibling condition (`kReleaseMode`) rather
/// than an env var or flavor (CLAUDE.md §11 forbids both). An empty DSN
/// disables the SDK instead of crashing, same convention as an empty ad unit
/// id — so a debug build never reports.
abstract final class SentryConfig {
  static const String dsn =
      'https://3cebd56717d8b0053e850295e8b94a6d@o4512091394736128.ingest.de.sentry.io/4512091397161040';
}
