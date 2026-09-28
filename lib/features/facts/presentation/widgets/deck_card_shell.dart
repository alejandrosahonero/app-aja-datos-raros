import 'package:aja/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Common frame for everything the deck renders.
///
/// Ad cards use the exact same shell as content cards — that is what makes the
/// ad slot feel native — but they always carry a visible "Ad" label, which is
/// both an AdMob policy requirement and the thing that keeps the app out of the
/// "deceptive ads" bucket in review.
class DeckCardShell extends StatelessWidget {
  const DeckCardShell({
    required this.child,
    super.key,
    this.color,
    this.elevation = 6,
  });

  final Widget child;
  final Color? color;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: color ?? theme.colorScheme.surfaceContainerHigh,
      elevation: elevation,
      // No M3 tint: it mixes the primary into the card, which turned the
      // white sheet grey (navy tint) and the dark one khaki (yellow tint).
      // Depth comes from the shadow alone.
      surfaceTintColor: Colors.transparent,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}
