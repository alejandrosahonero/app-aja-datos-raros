import 'package:aja/core/extensions/build_context_x.dart';
import 'package:aja/features/goals/domain/rank.dart';
import 'package:flutter/material.dart';

/// Name and icon for each rank, kept out of the domain the same way
/// `FactCategory`'s label is: the enum is a threshold table, not a widget.
extension RankStyle on Rank {
  /// The name shared by a rank's three tiers — what [label] shows on its own
  /// for Oráculo, which never got split into tiers.
  String _family(BuildContext context) => switch (this) {
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
    final String family = _family(context);
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
