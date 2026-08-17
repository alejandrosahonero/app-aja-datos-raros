/// Tests for the deck controller state management.
///
/// The controller owns the card stack position, reveal state, and progress
/// persistence. Tests verify that state mutations happen correctly, that
/// progress survives a container rebuild, and that edge cases like exhaustion
/// are handled safely.

library;

import 'package:aja/features/facts/domain/deck_item.dart';
import 'package:aja/features/facts/domain/fact.dart';
import 'package:aja/features/facts/presentation/providers/deck_controller.dart';
import 'package:aja/features/facts/presentation/providers/facts_providers.dart';
import 'package:aja/services/billing/premium_controller.dart';
import 'package:aja/services/billing/premium_state.dart';
import 'package:aja/services/storage/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake premium controller that always returns isPremium: true.
///
/// This prevents the deck from inserting ad cards, so the tests do not depend
/// on the AdMob SDK being initialized.
class _FakePremiumController extends PremiumController {
  @override
  Future<PremiumStatus> build() async =>
      const PremiumStatus(isPremium: true, storeAvailable: false);
}

/// Helper to build a test fact with the given ID.
Fact _buildFact(String id) {
  return Fact(
    id: id,
    category: FactCategory.body,
    question: LocalizedText(es: 'Pregunta $id', en: 'Question $id'),
    answer: LocalizedText(es: 'Respuesta $id', en: 'Answer $id'),
    detail: LocalizedText(es: 'Detalle $id', en: 'Detail $id'),
    source: 'Source $id',
    sourceUrl: '',
  );
}

void main() {
  group('DeckController', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          premiumControllerProvider.overrideWith(_FakePremiumController.new),
          factsProvider.overrideWith(
            (Ref ref) async => [
              _buildFact('1'),
              _buildFact('2'),
              _buildFact('3'),
            ],
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test(
      'initial state has index 0, factsSeen 0, revealed false, not exhausted',
      () async {
        await container.read(deckControllerProvider.future);
        final DeckState state = container
            .read(deckControllerProvider)
            .requireValue;

        expect(state.index, equals(0));
        expect(state.factsSeen, equals(0));
        expect(state.revealed, isFalse);
        expect(state.isExhausted, isFalse);
      },
    );

    test('toggleReveal flips revealed state', () async {
      await container.read(deckControllerProvider.future);
      final DeckController controller = container.read(
        deckControllerProvider.notifier,
      );

      DeckState state = container.read(deckControllerProvider).requireValue;
      expect(state.revealed, isFalse);

      controller.toggleReveal();
      state = container.read(deckControllerProvider).requireValue;
      expect(state.revealed, isTrue);

      controller.toggleReveal();
      state = container.read(deckControllerProvider).requireValue;
      expect(state.revealed, isFalse);
    });

    test('next() advances index and factsSeen, and resets revealed', () async {
      await container.read(deckControllerProvider.future);
      final DeckController controller = container.read(
        deckControllerProvider.notifier,
      );

      // Reveal the card
      controller.toggleReveal();
      DeckState state = container.read(deckControllerProvider).requireValue;
      expect(state.revealed, isTrue);

      // Call next()
      final DeckItem? dismissed = await controller.next();
      state = container.read(deckControllerProvider).requireValue;

      expect(state.index, equals(1));
      expect(state.factsSeen, equals(1));
      expect(state.revealed, isFalse);
      expect(dismissed, isA<FactItem>());
    });

    test('next() returns the dismissed deck item', () async {
      await container.read(deckControllerProvider.future);
      final DeckState initialState = container
          .read(deckControllerProvider)
          .requireValue;
      final DeckItem initialCard = initialState.current!;
      final DeckController controller = container.read(
        deckControllerProvider.notifier,
      );

      final DeckItem? dismissed = await controller.next();

      expect(dismissed, equals(initialCard));
    });

    test(
      'calling next() until exhausted sets isExhausted true and returns null',
      () async {
        await container.read(deckControllerProvider.future);
        final DeckController controller = container.read(
          deckControllerProvider.notifier,
        );

        // Advance 3 times (3 facts total)
        await controller.next();
        await controller.next();
        await controller.next();

        final DeckState state = container
            .read(deckControllerProvider)
            .requireValue;
        expect(state.isExhausted, isTrue);

        // One more call should return null and not throw
        final DeckItem? result = await controller.next();
        expect(result, isNull);
      },
    );

    test('progress persists across container rebuilds', () async {
      // First container: advance by 2
      await container.read(deckControllerProvider.future);
      final DeckController controller = container.read(
        deckControllerProvider.notifier,
      );

      await controller.next();
      await controller.next();

      DeckState state = container.read(deckControllerProvider).requireValue;
      expect(state.factsSeen, equals(2));

      // Get the SharedPreferences instance
      final SharedPreferences prefs = container.read(sharedPreferencesProvider);

      // Dispose old container
      container.dispose();

      // Create new container with the SAME SharedPreferences instance
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          premiumControllerProvider.overrideWith(_FakePremiumController.new),
          factsProvider.overrideWith(
            (Ref ref) async => [
              _buildFact('1'),
              _buildFact('2'),
              _buildFact('3'),
            ],
          ),
        ],
      );

      // The new deck should start at factsSeen == 2
      await container.read(deckControllerProvider.future);
      state = container.read(deckControllerProvider).requireValue;
      expect(state.factsSeen, equals(2));
    });

    test('restart() resets index and factsSeen to 0', () async {
      await container.read(deckControllerProvider.future);
      final DeckController controller = container.read(
        deckControllerProvider.notifier,
      );

      // Advance and verify
      await controller.next();
      await controller.next();
      DeckState state = container.read(deckControllerProvider).requireValue;
      expect(state.factsSeen, equals(2));

      // Restart
      await controller.restart();
      state = container.read(deckControllerProvider).requireValue;

      expect(state.index, equals(0));
      expect(state.factsSeen, equals(0));
      expect(state.revealed, isFalse);
    });
  });
}
