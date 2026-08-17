import 'dart:async';

import 'package:aja/core/extensions/build_context_x.dart';
import 'package:aja/core/routing/app_routes.dart';
import 'package:aja/core/theme/app_spacing.dart';
import 'package:aja/core/utils/app_logger.dart';
import 'package:aja/features/facts/presentation/widgets/deck_card_shell.dart';
import 'package:aja/services/ads/ads_providers.dart';
import 'package:aja/services/ads/ads_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// The ad slot of the deck, shaped like any other card.
///
/// Two rules are baked in and must not be relaxed:
///
/// * The creative is only requested once the card is actually **on top**
///   ([active]). Cards waiting behind the top one are 95 % covered, and
///   rendering an ad nobody can see is exactly what AdMob counts as an invalid
///   impression.
/// * The "Ad" label is always painted. A native-looking ad without a label is a
///   deceptive-ads rejection.
///
/// When nothing fills — no consent, no inventory, no configured unit — the card
/// falls back to a quiet "remove ads" pitch instead of a blank rectangle. That
/// keeps the deck rhythm intact and puts the paywall right after a value
/// moment, which is where the guide wants it.
class AdDeckCard extends ConsumerStatefulWidget {
  const AdDeckCard({required this.active, super.key});

  final bool active;

  @override
  ConsumerState<AdDeckCard> createState() => _AdDeckCardState();
}

class _AdDeckCardState extends ConsumerState<AdDeckCard> {
  /// 300x250. Big enough to read as a card rather than a strip, and the size
  /// with the deepest inventory after the anchored banner.
  static const AdSize _size = AdSize.mediumRectangle;

  BannerAd? _banner;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) unawaited(_load());
  }

  @override
  void didUpdateWidget(AdDeckCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) unawaited(_load());
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final AdsService ads = ref.read(adsServiceProvider);
    if (_loading || _banner != null || !ads.canShowBanner) return;

    _loading = true;
    final BannerAd banner = BannerAd(
      size: _size,
      adUnitId: ads.bannerAdUnitId,
      request: ads.buildRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _banner = ad as BannerAd;
            _loading = false;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          AppLogger.debug('Deck ad load failed: $error', name: 'ads');
          ad.dispose();
          _loading = false;
        },
      ),
    );

    await banner.load();
  }

  @override
  Widget build(BuildContext context) {
    // The SDK may still have been initializing when this card was built.
    ref.listen<bool>(adsInitializedProvider, (bool? previous, bool next) {
      if (next && widget.active) unawaited(_load());
    });

    final BannerAd? banner = _banner;

    return DeckCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _AdLabel(),
          const Spacer(),
          Center(
            child: banner == null
                ? const _RemoveAdsPitch()
                : SizedBox(
                    width: _size.width.toDouble(),
                    height: _size.height.toDouble(),
                    child: AdWidget(ad: banner),
                  ),
          ),
          const Spacer(flex: 2),
          Row(
            children: <Widget>[
              Icon(
                Icons.swipe_left_alt,
                size: 18,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.deckHintNext,
                  style: context.texts.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdLabel extends StatelessWidget {
  const _AdLabel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          context.l10n.adLabel,
          style: context.texts.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Shown when no creative could be loaded.
class _RemoveAdsPitch extends StatelessWidget {
  const _RemoveAdsPitch();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.block, size: 40, color: context.colors.primary),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.l10n.paywallHeadline,
          textAlign: TextAlign.center,
          style: context.texts.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: () => context.goNamed(AppRoutes.paywallName),
          child: Text(context.l10n.settingsRemoveAds),
        ),
      ],
    );
  }
}
