import 'package:aja/services/storage/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the one-time welcome screen has been dismissed.
///
/// Synchronous on purpose: prefs are already loaded in `bootstrap`, so the
/// router can decide the first route without a loading frame.
final NotifierProvider<WelcomeController, bool> welcomeSeenProvider =
    NotifierProvider<WelcomeController, bool>(WelcomeController.new);

class WelcomeController extends Notifier<bool> {
  static const String storageKey = 'welcome_seen';

  @override
  bool build() => ref.watch(keyValueStoreProvider).getBool(storageKey);

  Future<void> markSeen() async {
    state = true;
    await ref.read(keyValueStoreProvider).setBool(storageKey, value: true);
  }
}
