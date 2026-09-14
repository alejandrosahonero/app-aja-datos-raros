import 'package:aja/core/extensions/build_context_x.dart';
import 'package:aja/core/routing/app_routes.dart';
import 'package:aja/core/theme/app_spacing.dart';
import 'package:aja/core/widgets/base_screen.dart';
import 'package:aja/core/widgets/section_card.dart';
import 'package:aja/features/goals/domain/goals_state.dart';
import 'package:aja/features/goals/domain/rank.dart';
import 'package:aja/features/goals/presentation/providers/goals_controller.dart';
import 'package:aja/features/goals/presentation/widgets/rank_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Where the goal and the ranks are explained in full.
///
/// A screen of its own rather than a panel on the deck: all of this is worth
/// reading exactly once a day, and the deck cannot afford the height. Reached
/// from the ring in the app bar and from a row in Settings.
///
/// `showBanner: false`: this screen is the reward for a session, and framing a
/// rank-up with an ad is the cheapest possible way to spend it.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoalsState goals = ref.watch(goalsControllerProvider);

    return BaseScreen(
      title: context.l10n.goalsTitle,
      leading: IconButton(
        onPressed: () => context.canPop()
            ? context.pop()
            : context.goNamed(AppRoutes.homeName),
        icon: const Icon(Icons.arrow_back),
      ),
      showBanner: false,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          _RankHeader(goals: goals),
          const SizedBox(height: AppSpacing.lg),
          _TodayCard(goals: goals),
          const SizedBox(height: AppSpacing.md),
          _RankLadder(held: goals.rank),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.goalsHowItWorks,
            style: context.texts.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// The badge, the name and the bar to the next rank.
class _RankHeader extends StatelessWidget {
  const _RankHeader({required this.goals});

  final GoalsState goals;

  @override
  Widget build(BuildContext context) {
    final Rank rank = goals.rank;
    final int? toNext = rank.pointsTo(goals.points);

    return Column(
      children: <Widget>[
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: context.colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            rank.icon,
            size: 48,
            color: context.colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(rank.label(context), style: context.texts.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.goalsPoints(goals.points),
          style: context.texts.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: rank.progressTo(goals.points),
            minHeight: 8,
            backgroundColor: context.colors.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          // Measured from this rank's floor, not from zero: a single bar for
          // the whole ladder would sit near empty for weeks.
          toNext == null
              ? context.l10n.goalsMaxRank
              : context.l10n.goalsNextRank(toNext, rank.next!.label(context)),
          textAlign: TextAlign.center,
          style: context.texts.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        // Skipped at the very first tier: everybody is there on day one, so
        // "estimated: ~100%" would be noise, not a fact worth telling anyone.
        if (rank != Rank.curiousI) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            rank.rarityLabel(context),
            textAlign: TextAlign.center,
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.goals});

  final GoalsState goals;

  @override
  Widget build(BuildContext context) {
    final Color color = goals.isComplete
        ? context.semanticColors.success
        : context.colors.primary;

    return SectionCard(
      title: context.l10n.goalsTodayTitle,
      icon: Icons.today_outlined,
      children: <Widget>[
        Row(
          children: <Widget>[
            SizedBox.square(
              dimension: 56,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  CircularProgressIndicator(
                    value: goals.progress,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: context.colors.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  if (goals.isComplete)
                    Icon(Icons.check_rounded, color: color, size: 26),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.l10n.goalsTodayProgress(
                      goals.learned.clamp(0, goals.target),
                      goals.target,
                    ),
                    style: context.texts.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    goals.isComplete
                        ? context.l10n.goalsTodayDone(goals.target)
                        : context.l10n.goalsTodayPending(goals.remaining),
                    style: context.texts.bodySmall?.copyWith(
                      color: goals.isComplete
                          ? color
                          : context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The whole ladder, so the next rank is a thing the user can aim at rather
/// than a surprise.
///
/// Always exactly six medallions — one per **named** rank, never sixteen.
/// A family not reached yet shows its bare name with no numeral: "Preguntón
/// I" is not a real destination to aim at, "Preguntón" is. Once the user has
/// actually reached a tier inside a family, that family's medallion switches
/// to the specific tier — its own or, once the user has moved past the whole
/// family, the last one reached (`III`), which is the peak that family ever
/// showed the user and stays claimed after moving on.
class _RankLadder extends StatelessWidget {
  const _RankLadder({required this.held});

  final Rank held;

  /// Curioso .. Oráculo.
  static final int _familyCount = Rank.oracle.family + 1;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.l10n.goalsRankLadder,
      icon: Icons.military_tech_outlined,
      children: <Widget>[
        // A Wrap, not a horizontal list: all six have to be on screen at
        // once, with nothing to scroll to find the rest of the ladder. It
        // reflows into two or three rows depending on width and text scale
        // instead of assuming a fixed row count.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: <Widget>[
            for (int family = 0; family < _familyCount; family++)
              _RankMedallion(family: family, held: held),
          ],
        ),
      ],
    );
  }
}

/// One rank's spot on the ladder: a big icon, its name below, its point
/// threshold below that.
class _RankMedallion extends StatelessWidget {
  const _RankMedallion({required this.family, required this.held});

  /// Which of the six named ranks this medallion represents.
  final int family;

  final Rank held;

  static const double _diameter = 64;

  @override
  Widget build(BuildContext context) {
    final List<Rank> tiers = Rank.values
        .where((Rank rank) => rank.family == family)
        .toList(growable: false);
    final Rank first = tiers.first;
    final Rank last = tiers.last;

    final bool isCurrentFamily = family == held.family;
    final bool isPastFamily = family < held.family;
    final bool isReached = isCurrentFamily || isPastFamily;

    // Still climbing this family: show the exact tier held. Already moved on:
    // show the last tier this family ever paid out, which is the one that was
    // actually earned before leaving it behind. Not reached at all: `first`
    // only lends its icon here, never its numeral — see `familyLabel` below.
    final Rank display = isCurrentFamily ? held : (isPastFamily ? last : first);

    final Color iconColor = isReached
        ? context.colors.onPrimaryContainer
        : context.colors.onSurfaceVariant;

    return SizedBox(
      width: 88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: _diameter,
            height: _diameter,
            decoration: BoxDecoration(
              color: isReached
                  ? context.colors.primaryContainer
                  : context.colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(display.icon, size: 30, color: iconColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isReached ? display.label(context) : display.familyLabel(context),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.texts.labelMedium?.copyWith(
              fontWeight: isCurrentFamily ? FontWeight.w700 : null,
              color: isReached ? null : context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs / 2),
          Text(
            context.l10n.goalsRankPointsShort(display.minPoints),
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
