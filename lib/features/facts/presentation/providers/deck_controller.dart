import 'package:aja/features/facts/domain/deck_item.dart';
import 'package:aja/features/facts/domain/fact.dart';
import 'package:aja/features/facts/presentation/providers/facts_providers.dart';
import 'package:aja/services/billing/premium_controller.dart';
import 'package:aja/services/storage/storage_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Everything the deck needs to paint one frame.
///
/// [revealed] lives here rather than inside the card widget so the card stays a
/// pure function of the state: a swipe, a tap and a restore-from-storage all go
/// through the same path, and the flip is testable without pumping an
/// animation.
@immutable
class DeckState {
  const DeckState({
    required this.items,
    required this.index,
    required this.factsSeen,
    required this.revealed,
  });

  final List<DeckItem> items;

  /// Position of the top card. Equal to `items.length` when the deck is spent.
  final int index;

  /// Fact cards already swiped away. Persisted instead of [index] because the
  /// ad slots shift positions when the user buys premium.
  final int factsSeen;

  /// Whether the top card shows its back.
  final bool revealed;

  bool get isExhausted => index >= items.length;

  DeckItem? get current => isExhausted ? null : items[index];

  DeckState copyWith({
    List<DeckItem>? items,
    int? index,
    int? factsSeen,
    bool? revealed,
  }) => DeckState(
    items: items ?? this.items,
    index: index ?? this.index,
    factsSeen: factsSeen ?? this.factsSeen,
    revealed: revealed ?? this.revealed,
  );
}

final AsyncNotifierProvider<DeckController, DeckState> deckControllerProvider =
    AsyncNotifierProvider<DeckController, DeckState>(DeckController.new);

/// Owns the card stack: which card is on top, whether it is flipped, and how
/// far the user got.
///
/// Deliberately free of ad and review calls. Those are orchestration and belong
/// to the screen, which is the only place that knows a swipe was a real user
/// gesture rather than a state restore.
class DeckController extends AsyncNotifier<DeckState> {
  static const String _progressKeyPrefix = 'deck_facts_seen_';

  @override
  Future<DeckState> build() async {
    final List<Fact> all = await ref.watch(factsProvider.future);
    final FactCategory? category = ref.watch(categoryFilterProvider);

    // `watch`: buying premium must remove the ad slots from the deck already
    // built, not only from the next one.
    final bool isPremium = ref.watch(isPremiumProvider);

    final List<Fact> facts = category == null
        ? all
        : all.where((Fact fact) => fact.category == category).toList();

    final List<DeckItem> items = buildDeck(facts, withAds: !isPremium);

    final int factsSeen = ref
        .read(keyValueStoreProvider)
        .getInt(_progressKey(category))
        .clamp(0, facts.length);

    return DeckState(
      items: items,
      index: _indexForProgress(items, factsSeen),
      factsSeen: factsSeen,
      revealed: false,
    );
  }

  /// Right swipe / tap: show the other side of the card.
  void toggleReveal() {
    final DeckState? current = state.value;
    if (current == null || current.isExhausted) return;
    // Ad cards have no back side.
    if (current.current is! FactItem) return;

    state = AsyncData<DeckState>(current.copyWith(revealed: !current.revealed));
  }

  /// Left swipe: drop the top card and bring up the next one.
  ///
  /// Returns the item that was dismissed so the caller can decide whether it
  /// was a value moment worth counting for ads and reviews.
  Future<DeckItem?> next() async {
    final DeckState? current = state.value;
    if (current == null || current.isExhausted) return null;

    final DeckItem dismissed = current.items[current.index];
    final int factsSeen = current.factsSeen + (dismissed is FactItem ? 1 : 0);

    state = AsyncData<DeckState>(
      current.copyWith(
        index: current.index + 1,
        factsSeen: factsSeen,
        revealed: false,
      ),
    );

    await _persist(factsSeen);
    return dismissed;
  }

  /// Back to the first card of the current category.
  Future<void> restart() async {
    final DeckState? current = state.value;
    if (current == null) return;

    state = AsyncData<DeckState>(
      current.copyWith(index: 0, factsSeen: 0, revealed: false),
    );
    await _persist(0);
  }

  Future<void> _persist(int factsSeen) => ref
      .read(keyValueStoreProvider)
      .setInt(_progressKey(ref.read(categoryFilterProvider)), factsSeen);

  static String _progressKey(FactCategory? category) =>
      '$_progressKeyPrefix${category?.id ?? 'all'}';

  /// Translates "N fact cards already seen" into a position in a deck that also
  /// contains ad slots.
  static int _indexForProgress(List<DeckItem> items, int factsSeen) {
    int seen = 0;
    for (int i = 0; i < items.length; i++) {
      if (items[i] is! FactItem) continue;
      if (seen == factsSeen) return i;
      seen++;
    }
    return items.length;
  }
}
