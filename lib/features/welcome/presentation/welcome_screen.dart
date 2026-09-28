import 'package:aja/core/extensions/build_context_x.dart';
import 'package:aja/core/routing/app_routes.dart';
import 'package:aja/core/theme/app_colors.dart';
import 'package:aja/core/theme/app_spacing.dart';
import 'package:aja/core/theme/app_theme.dart';
import 'package:aja/core/widgets/base_screen.dart';
import 'package:aja/features/welcome/presentation/welcome_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// First-launch screen, on the brand's dark colour (Tinta) in both themes.
///
/// Says what the app is and teaches the four gestures, which are otherwise
/// invisible. It asks for nothing (no permission, no paywall) and is shown
/// once.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  static const Color _paper = Color(0xFFF4F6FA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseScreen(
      showBanner: false,
      body: ColoredBox(
        color: AppColors.ink,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: <Widget>[
              Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(text: context.l10n.welcomeTitleLead),
                    TextSpan(
                      text: context.l10n.welcomeTitleMark,
                      style: const TextStyle(
                        color: AppColors.ink,
                        backgroundColor: AppColors.highlighter,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 38,
                  height: 1.2,
                  color: _paper,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.welcomeBody,
                style: context.texts.bodyLarge?.copyWith(
                  color: _paper.withValues(alpha: 0.8),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _Gesture(
                icon: Icons.swipe_right_alt,
                text: context.l10n.welcomeGestureRight,
              ),
              _Gesture(
                icon: Icons.swipe_left_alt,
                text: context.l10n.welcomeGestureLeft,
              ),
              _Gesture(
                icon: Icons.swipe_up_alt,
                text: context.l10n.welcomeGestureUp,
              ),
              _Gesture(
                icon: Icons.swipe_down_alt,
                text: context.l10n.welcomeGestureDown,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.highlighter,
                  foregroundColor: AppColors.ink,
                ),
                onPressed: () async {
                  await ref.read(welcomeSeenProvider.notifier).markSeen();
                  if (context.mounted) context.goNamed(AppRoutes.homeName);
                },
                child: Text(context.l10n.welcomeStart),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Gesture extends StatelessWidget {
  const _Gesture({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Icon(icon, color: AppColors.highlighter),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: context.texts.bodyLarge?.copyWith(
                color: WelcomeScreen._paper,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
