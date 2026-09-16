import 'dart:math' as math;

import 'package:aja/core/extensions/build_context_x.dart';
import 'package:aja/features/goals/domain/rank.dart';
import 'package:flutter/material.dart';

/// Name and icon for each rank, kept out of the domain the same way
/// `FactCategory`'s label is: the enum is a threshold table, not a widget.
extension RankStyle on Rank {
  /// The name shared by a rank's three tiers, with no numeral — what [label]
  /// shows on its own for Oráculo, which never got split into tiers, and what
  /// the progress screen's ladder shows for a family the user has not reached
  /// any tier of yet (§3.8: the ladder always lists the six names; a numbered
  /// tier only replaces one once actually reached).
  String familyLabel(BuildContext context) => switch (this) {
    Rank.curiousI ||
    Rank.curiousII ||
    Rank.curiousIII => context.l10n.rankCurious,
    Rank.inquisitiveI ||
    Rank.inquisitiveII ||
    Rank.inquisitiveIII => context.l10n.rankInquisitive,
    Rank.knowItAllI ||
    Rank.knowItAllII ||
    Rank.knowItAllIII => context.l10n.rankKnowItAll,
    Rank.scholarI ||
    Rank.scholarII ||
    Rank.scholarIII => context.l10n.rankScholar,
    Rank.encyclopediaI ||
    Rank.encyclopediaII ||
    Rank.encyclopediaIII => context.l10n.rankEncyclopedia,
    Rank.oracle => context.l10n.rankOracle,
  };

  /// I, II or III within a family; null for Oráculo, which has only one tier
  /// and so nothing to count. Roman numerals rather than a localized word:
  /// they read the same in every language this app ships, so no `.arb` entry
  /// is needed just to number a tier.
  String? get _tier => switch (this) {
    Rank.curiousI ||
    Rank.inquisitiveI ||
    Rank.knowItAllI ||
    Rank.scholarI ||
    Rank.encyclopediaI => 'I',
    Rank.curiousII ||
    Rank.inquisitiveII ||
    Rank.knowItAllII ||
    Rank.scholarII ||
    Rank.encyclopediaII => 'II',
    Rank.curiousIII ||
    Rank.inquisitiveIII ||
    Rank.knowItAllIII ||
    Rank.scholarIII ||
    Rank.encyclopediaIII => 'III',
    Rank.oracle => null,
  };

  /// "Curioso II", or plain "Oráculo" at the top of the ladder.
  String label(BuildContext context) {
    final String family = familyLabel(context);
    final String? tier = _tier;
    return tier == null ? family : '$family $tier';
  }

  /// Reads as a climb even with the labels covered: a single idea, then a
  /// question, then a mind, then study, then a library, then the thing itself.
  /// Shared by a family's three tiers on purpose — the icon marks which idea
  /// the user is on, not which third of it they have cleared; the numeral in
  /// [label] already carries that.
  IconData get icon => switch (this) {
    Rank.curiousI ||
    Rank.curiousII ||
    Rank.curiousIII => Icons.emoji_objects_outlined,
    Rank.inquisitiveI ||
    Rank.inquisitiveII ||
    Rank.inquisitiveIII => Icons.psychology_alt_outlined,
    Rank.knowItAllI ||
    Rank.knowItAllII ||
    Rank.knowItAllIII => Icons.psychology_outlined,
    Rank.scholarI || Rank.scholarII || Rank.scholarIII => Icons.school_outlined,
    Rank.encyclopediaI ||
    Rank.encyclopediaII ||
    Rank.encyclopediaIII => Icons.auto_stories_outlined,
    Rank.oracle => Icons.auto_awesome,
  };
}

/// "How rare is this rank?" — deliberately an **estimate**, never a measured
/// statistic.
///
/// This app has no backend, no accounts, and no analytics pipeline (§3.5,
/// §3.6: every network touchpoint that exists was chosen to avoid exactly
/// that), so it has never counted how many real installs reached any rank and
/// has no way to. What [RankRarity.estimatedRarityPercent] returns instead is
/// a hand-picked curve, not a fitted one: days needed to reach a rank at the
/// ~11 points/perfect-day pace documented in CLAUDE.md §3.8, run through an
/// assumed 40%-of-remaining-players-lost-per-week decay — a plausible shape
/// for a daily-habit app, chosen for a believable curve, not measured from
/// this app's own users or anyone else's.
///
/// Zero data collection either way: nothing here reads or sends anything, it
/// only does arithmetic on [Rank.minPoints], which is already a compile-time
/// constant. See CLAUDE.md §3.8 for why this exists instead of a real
/// percentile.
extension RankRarity on Rank {
  static const double _avgPointsPerPerfectDay = 11;
  static const double _weeklyRetention = 0.6;

  double get estimatedRarityPercent {
    final double weeks = (minPoints / _avgPointsPerPerfectDay) / 7;
    return 100 * math.pow(_weeklyRetention, weeks).toDouble();
  }

  /// The sentence for the progress screen, phrased as "estimado" on purpose —
  /// see the extension doc for why this must never read as a measured claim.
  ///
  /// Below 1% comes back as its own string rather than a rounded number: a
  /// measured statistic would show "0.04%", and printing that much precision
  /// on a number nobody measured is what would make this feel like a real
  /// (and fabricated) statistic instead of an honest estimate.
  String rarityLabel(BuildContext context) {
    final double percent = estimatedRarityPercent;
    return percent < 1
        ? context.l10n.goalsRarityBelowOne
        : context.l10n.goalsRarityApprox(percent.round());
  }
}
