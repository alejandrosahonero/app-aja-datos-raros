import 'dart:math';

import 'package:aja/features/facts/domain/deck_item.dart';
import 'package:aja/features/facts/domain/fact.dart';
import 'package:aja/features/facts/presentation/providers/facts_providers.dart';
import 'package:aja/services/billing/premium_controller.dart';
import 'package:aja/services/storage/key_value_store.dart';
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
  static const String _seedKeyPrefix = 'deck_shuffle_seed_';

  /// Seed meaning "leave the catalogue alone".
  ///
  /// The first run through a category is the curated order: the file is
  /// interleaved by hand so the categories rotate, and shuffling that on a
  /// user's very first session throws away the only editorial control there is
  /// over which question they meet first. Only [restart] shuffles.
  static const int _curatedOrder = 0;

  @override
  Future<DeckState> build() async {
    final List<Fact> all = await ref.watch(factsProvider.future);
    final FactCategory? category = ref.watch(categoryFilterProvider);

    // `watch`: buying premium must remove the ad slots from the deck already
    // built, not only from the next one.
    final bool isPremium = ref.watch(isPremiumProvider);
    final KeyValueStore store = ref.read(keyValueStoreProvider);

    return _deckFor(
      all: all,
      category: category,
      isPremium: isPremium,
      seed: store.getInt(_seedKey(category)),
      factsSeen: store.getInt(_progressKey(category)),
    );
  }

  /// Builds the deck for one (category, seed, progress) triple.
  ///
  /// Shared by [build] and [restart] so a restarted deck cannot drift from a
  /// rebuilt one: the same seed must always produce the same order, otherwise
  /// buying premium mid-deck would reshuffle the cards under the user.
  DeckState _deckFor({
    required List<Fact> all,
    required FactCategory? category,
    required bool isPremium,
    required int seed,
    required int factsSeen,
  }) {
    final List<Fact> facts = category == null
        ? all
        : all.where((Fact fact) => fact.category == category).toList();

    final List<Fact> ordered = seed == _curatedOrder
        ? facts
        : (List<Fact>.of(facts)..shuffle(Random(seed)));

    final List<DeckItem> items = buildDeck(ordered, withAds: !isPremium);
    final int seen = factsSeen.clamp(0, ordered.length);

    return DeckState(
      items: items,
      index: _indexForProgress(items, seen),
      factsSeen: seen,
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

  /// Back to the first card of the current category, **in a new order**.
  ///
  /// A reshuffle rather than a rewind: somebody who reaches the end and presses
  /// restart is asking for more, and handing them the same 87 cards in the same
  /// sequence answers that with "no". The seed is persisted so the new order
  /// survives closing the app — a deck that reshuffles itself every time the
  /// screen rebuilds would lose the user's place instead of keeping it.
  Future<void> restart() async {
    if (state.value == null) return;

    final FactCategory? category = ref.read(categoryFilterProvider);
    final KeyValueStore store = ref.read(keyValueStoreProvider);
    final int seed = _nextSeed(store.getInt(_seedKey(category)));

    await store.setInt(_seedKey(category), seed);
    await _persist(0);

    state = AsyncData<DeckState>(
      _deckFor(
        // Already resolved and cached; this does not hit the asset again.
        all: await ref.read(factsProvider.future),
        category: category,
        isPremium: ref.read(isPremiumProvider),
        seed: seed,
        factsSeen: 0,
      ),
    );
  }

  /// A seed that is neither the curated order nor the one just used, so
  /// "restart" always visibly changes something.
  static int _nextSeed(int previous) {
    final Random random = Random();
    int seed = previous;
    while (seed == previous || seed == _curatedOrder) {
      seed = random.nextInt(0x7FFFFFFF);
    }
    return seed;
  }

  Future<void> _persist(int factsSeen) => ref
      .read(keyValueStoreProvider)
      .setInt(_progressKey(ref.read(categoryFilterProvider)), factsSeen);

  static String _progressKey(FactCategory? category) =>
      '$_progressKeyPrefix${category?.id ?? 'all'}';

  static String _seedKey(FactCategory? category) =>
      '$_seedKeyPrefix${category?.id ?? 'all'}';

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
