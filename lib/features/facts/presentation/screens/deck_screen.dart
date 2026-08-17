import 'dart:async';

import 'package:aja/core/extensions/build_context_x.dart';
import 'package:aja/core/routing/app_routes.dart';
import 'package:aja/core/theme/app_spacing.dart';
import 'package:aja/core/widgets/app_loader.dart';
import 'package:aja/core/widgets/base_screen.dart';
import 'package:aja/core/widgets/empty_state.dart';
import 'package:aja/core/widgets/error_view.dart';
import 'package:aja/features/facts/domain/deck_item.dart';
import 'package:aja/features/facts/domain/fact.dart';
import 'package:aja/features/facts/presentation/providers/deck_controller.dart';
import 'package:aja/features/facts/presentation/providers/facts_providers.dart';
import 'package:aja/features/facts/presentation/providers/favorites_controller.dart';
import 'package:aja/features/facts/presentation/widgets/ad_deck_card.dart';
import 'package:aja/features/facts/presentation/widgets/fact_card.dart';
import 'package:aja/features/facts/presentation/widgets/swipe_deck.dart';
import 'package:aja/features/premium/presentation/widgets/premium_feature_dialog.dart';
import 'package:aja/services/ads/ads_providers.dart';
import 'package:aja/services/review/review_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The whole app: a stack of cards you swipe through.
///
/// `showBanner: false` on purpose. The body is one big drag surface that
/// reaches the bottom of the screen, and an anchored banner under a drag
/// gesture is the textbook accidental-click layout. The deck monetizes through
/// the in-deck ad card and the interstitial instead.
class DeckScreen extends ConsumerWidget {
  const DeckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DeckState> deck = ref.watch(deckControllerProvider);

    return BaseScreen(
      title: context.l10n.appTitle,
      showBanner: false,
      actions: <Widget>[
        const _CategoryMenu(),
        IconButton(
          onPressed: () => context.goNamed(AppRoutes.favoritesName),
          icon: const Icon(Icons.bookmarks_outlined),
          tooltip: context.l10n.favoritesTitle,
        ),
        IconButton(
          onPressed: () => context.goNamed(AppRoutes.settingsName),
          icon: const Icon(Icons.settings_outlined),
          tooltip: context.l10n.settingsTitle,
        ),
      ],
      body: deck.when(
        loading: () => const AppLoader(),
        error: (Object error, StackTrace stackTrace) => ErrorView(
          message: context.l10n.deckLoadError,
          onRetry: () => ref.invalidate(factsProvider),
        ),
        data: (DeckState state) => _DeckBody(state: state),
      ),
    );
  }
}

class _DeckBody extends ConsumerWidget {
  const _DeckBody({required this.state});

  final DeckState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isExhausted) {
      return EmptyState(
        icon: Icons.check_circle_outline,
        title: context.l10n.deckFinishedTitle,
        message: context.l10n.deckFinishedBody,
        action: FilledButton.icon(
          onPressed: () =>
              unawaited(ref.read(deckControllerProvider.notifier).restart()),
          icon: const Icon(Icons.refresh),
          label: Text(context.l10n.deckRestart),
        ),
      );
    }

    final Set<String> favorites = ref.watch(favoritesProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        children: <Widget>[
          _Progress(state: state),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: SwipeDeck(
              items: state.items,
              index: state.index,
              onSwipeLeft: () => unawaited(_next(ref)),
              onSwipeRight: () => _reveal(ref),
              onSwipeUp: () => unawaited(_toggleFavorite(context, ref)),
              hintLeft: const _SwipeBadge(
                icon: Icons.arrow_back,
                alignment: Alignment.topLeft,
              ),
              hintRight: const _SwipeBadge(
                icon: Icons.flip_to_back,
                alignment: Alignment.topRight,
              ),
              hintUp: const _SwipeBadge(
                icon: Icons.bookmark_add_outlined,
                alignment: Alignment.bottomCenter,
              ),
              builder: (BuildContext context, DeckItem item, bool isTop) =>
                  switch (item) {
                    FactItem(:final Fact fact) => FactCard(
                      fact: fact,
                      revealed: isTop && state.revealed,
                      favorited: favorites.contains(fact.id),
                      onTap: isTop ? () => _reveal(ref) : null,
                    ),
                    AdItem() => AdDeckCard(active: isTop),
                  },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DeckControls(
            state: state,
            favorited: switch (state.current) {
              FactItem(:final Fact fact) => favorites.contains(fact.id),
              _ => false,
            },
            onNext: () => unawaited(_next(ref)),
            onReveal: () => _reveal(ref),
            onFavorite: () => unawaited(_toggleFavorite(context, ref)),
          ),
        ],
      ),
    );
  }

  /// Swipe up / bookmark button.
  ///
  /// The entitlement is checked here and not in [FavoritesController] because
  /// the "no" branch has to open the paywall, which needs a context. A locked
  /// user still gets to make the gesture: that attempt is the value moment the
  /// upsell hangs off.
  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref) async {
    final DeckItem? current = state.current;
    if (current is! FactItem) return;

    if (!ref.read(canUseFavoritesProvider)) {
      await showPremiumFeatureDialog(context);
      return;
    }

    await ref.read(favoritesProvider.notifier).toggle(current.fact.id);
  }

  /// Flipping a card to read the answer is the value moment of this app, so it
  /// is the only place the review prompt is allowed to be counted from. The
  /// service's own guards (5 successes, 3 days, 120 days) decide whether
  /// anything is actually shown.
  void _reveal(WidgetRef ref) {
    final bool wasHidden = !state.revealed;
    ref.read(deckControllerProvider.notifier).toggleReveal();

    if (wasHidden && state.current is FactItem) {
      unawaited(ref.read(reviewServiceProvider).requestReviewAfterSuccess());
    }
  }

  /// One swiped card = one "value action" for the interstitial pacing. The
  /// service still enforces the 3 minute floor, so a fast reader does not get
  /// an ad every nine cards.
  Future<void> _next(WidgetRef ref) async {
    final DeckItem? dismissed = await ref
        .read(deckControllerProvider.notifier)
        .next();

    if (dismissed is FactItem) {
      await ref
          .read(adsServiceProvider)
          .registerActionAndMaybeShowInterstitial();
    }
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.state});

  final DeckState state;

  @override
  Widget build(BuildContext context) {
    final int total = state.totalFacts;
    final int current = (state.factsSeen + 1).clamp(1, total);

    return Row(
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : state.factsSeen / total,
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          context.l10n.deckProgress(current, total),
          style: context.texts.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Buttons mirroring the two swipes.
///
/// Not decoration: a drag-only interface is unusable with a screen reader or
/// switch access, and Play flags that in the accessibility scan.
class _DeckControls extends StatelessWidget {
  const _DeckControls({
    required this.state,
    required this.favorited,
    required this.onNext,
    required this.onReveal,
    required this.onFavorite,
  });

  final DeckState state;
  final bool favorited;
  final VoidCallback onNext;
  final VoidCallback onReveal;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final bool isFact = state.current is FactItem;

    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward),
            label: Text(context.l10n.deckNext),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton.icon(
            onPressed: isFact ? onReveal : null,
            icon: const Icon(Icons.flip_to_back),
            label: Text(
              state.revealed
                  ? context.l10n.deckHideAnswer
                  : context.l10n.deckShowAnswer,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Never disabled for a locked user: tapping it is how they find out the
        // feature exists and what unlocks it.
        IconButton.filledTonal(
          onPressed: isFact ? onFavorite : null,
          icon: Icon(favorited ? Icons.bookmark : Icons.bookmark_add_outlined),
          tooltip: favorited
              ? context.l10n.favoritesRemove
              : context.l10n.favoritesAdd,
        ),
      ],
    );
  }
}

/// Badge that fades in over the card while dragging.
class _SwipeBadge extends StatelessWidget {
  const _SwipeBadge({required this.icon, required this.alignment});

  final IconData icon;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: CircleAvatar(
          backgroundColor: context.colors.primary,
          foregroundColor: context.colors.onPrimary,
          child: Icon(icon),
        ),
      ),
    );
  }
}

/// Category filter. A menu instead of a chip row: chips would eat vertical
/// space that belongs to the card, and the filter is a rare action.
class _CategoryMenu extends ConsumerWidget {
  const _CategoryMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FactCategory? selected = ref.watch(categoryFilterProvider);

    return PopupMenuButton<FactCategory?>(
      icon: const Icon(Icons.filter_list),
      tooltip: context.l10n.deckCategoryTooltip,
      initialValue: selected,
      onSelected: (FactCategory? category) =>
          ref.read(categoryFilterProvider.notifier).select(category),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<FactCategory?>>[
        PopupMenuItem<FactCategory?>(child: Text(context.l10n.deckCategoryAll)),
        ...FactCategory.values.map(
          (FactCategory category) => PopupMenuItem<FactCategory?>(
            value: category,
            child: Text(category.label(context)),
          ),
        ),
      ],
    );
  }
}
