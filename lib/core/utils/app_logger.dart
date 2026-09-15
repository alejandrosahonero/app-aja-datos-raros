import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Minimal logging facade.
///
/// `print` is banned by the analyzer: it survives into release builds and slows
/// down the platform channel. Everything goes through `dart:developer`, which
/// is stripped in release mode by [kDebugMode] guards.
///
/// [error] also forwards to Sentry, the single place in the codebase that
/// touches the SDK. It is a no-op in debug ([SentryConfig]'s dsn is empty
/// there, per `bootstrap.dart`), so nothing here has to check [kReleaseMode]
/// itself — an uninitialized Sentry client silently drops the event.
abstract final class AppLogger {
  static void debug(String message, {String name = 'app'}) {
    if (!kDebugMode) return;
    developer.log(message, name: name);
  }

  static void error(
    String message, {
    String name = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    unawaited(
      Sentry.captureException(
        error ?? message,
        stackTrace: stackTrace,
        withScope: (Scope scope) => scope.setTag('logger', name),
      ),
    );
  }
}
