import 'dart:math' as math;

import 'package:aja/core/config/app_config.dart';
import 'package:aja/features/facts/domain/deck_item.dart';
import 'package:flutter/material.dart';

/// Tinder-style card stack.
///
/// Cards sit one behind the other; only the top one reacts to touch. Each
/// direction does something different on purpose:
///
/// * **right** — flips the card over to its answer. The card springs back to
///   the centre, it is not dismissed.
/// * **left** — throws the card away and brings the next one up.
/// * **up** — saves the card to favourites. Like the flip, it springs back:
///   saving a card is not a reason to stop reading it.
///
/// Down is deliberately unbound, so an imprecise upward flick that ends up
/// going the other way does nothing instead of firing the wrong action.
///
/// The widget owns nothing but the gesture: it reports every direction upwards
/// and re-reads what to paint from [items]/[index]. That is what keeps the deck
/// state (position, flip) in the controller and testable.
class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    required this.items,
    required this.index,
    required this.builder,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onSwipeUp,
    super.key,
    this.hintLeft,
    this.hintRight,
    this.hintUp,
  });

  final List<DeckItem> items;

  /// Position of the top card inside [items].
  final int index;

  final Widget Function(BuildContext context, DeckItem item, bool isTop)
  builder;

  /// Dismiss the top card.
  final VoidCallback onSwipeLeft;

  /// Flip the top card.
  final VoidCallback onSwipeRight;

  /// Save the top card to favourites.
  final VoidCallback onSwipeUp;

  /// Overlays that fade in while dragging, so the three directions are
  /// discoverable without a tutorial.
  final Widget? hintLeft;
  final Widget? hintRight;
  final Widget? hintUp;

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  )..addListener(_onSettleTick);

  Animation<Offset>? _settle;

  /// Live finger offset of the top card, in logical pixels.
  Offset _drag = Offset.zero;

  /// True while the card is flying off screen; the gesture is ignored until it
  /// lands so a fast second swipe cannot skip two cards at once.
  bool _dismissing = false;

  @override
  void didUpdateWidget(SwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The dismissed card is parked off screen until the parent actually
    // advances. Snapping it back to the centre the moment the animation ends
    // would flash the old card for one frame, because the controller updates
    // the index on the next build and not synchronously.
    if (widget.index != oldWidget.index ||
        widget.items.length != oldWidget.items.length) {
      _drag = Offset.zero;
      _dismissing = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSettleTick() {
    final Animation<Offset>? settle = _settle;
    if (settle == null) return;
    setState(() => _drag = settle.value);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dismissing || _controller.isAnimating) return;
    setState(() => _drag += details.delta);
  }

  void _onPanEnd(DragEndDetails details, Size size) {
    if (_dismissing || _controller.isAnimating) return;

    final Offset velocity = details.velocity.pixelsPerSecond;

    // The dominant axis decides which action the drag was: a gesture that moved
    // 200 px up and 60 px left is an upward swipe, not a dismissal.
    if (_drag.dy.abs() > _drag.dx.abs()) {
      final bool up =
          -_drag.dy > size.height * AppConfig.deckSwipeUpThreshold ||
          -velocity.dy > AppConfig.deckSwipeVelocity;

      if (up) widget.onSwipeUp();
      // Saving does not consume the card, and downward is unbound, so either
      // way the card returns to the centre.
      _settleBack();
      return;
    }

    final bool committed =
        _drag.dx.abs() > size.width * AppConfig.deckSwipeThreshold ||
        velocity.dx.abs() > AppConfig.deckSwipeVelocity;

    if (!committed) {
      _settleBack();
      return;
    }

    if (_drag.dx.isNegative) {
      _dismiss(size.width);
    } else {
      // Right means "turn the card over", so it comes back to the centre and
      // the flip animation takes it from there.
      widget.onSwipeRight();
      _settleBack();
    }
  }

  void _settleBack() => _animate(Offset.zero, dismiss: false);

  void _dismiss(double width) =>
      _animate(Offset(-width * 1.6, _drag.dy), dismiss: true);

  void _animate(Offset target, {required bool dismiss}) {
    _settle = Tween<Offset>(begin: _drag, end: target).animate(
      CurvedAnimation(
        parent: _controller,
        curve: dismiss ? Curves.easeIn : Curves.easeOutBack,
      ),
    );
    _dismissing = dismiss;

    _controller
      ..value = 0
      ..forward().whenComplete(() {
        if (!mounted) return;
        _settle = null;

        if (dismiss) {
          // `_drag` stays at the off screen target on purpose; didUpdateWidget
          // resets it once the next card is on top.
          widget.onSwipeLeft();
          return;
        }

        setState(() => _drag = Offset.zero);
      });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = constraints.biggest;

        // Painted back to front: the last child of a Stack is on top, and the
        // top card must be the one that receives the gesture.
        final List<Widget> cards = <Widget>[];
        final int last = math.min(
          widget.index + AppConfig.deckVisibleCards,
          widget.items.length,
        );

        for (int i = last - 1; i >= widget.index; i--) {
          final DeckItem item = widget.items[i];
          final int depth = i - widget.index;
          cards.add(
            depth == 0
                ? _buildTopCard(context, item, size)
                : _buildBackCard(context, item, depth),
          );
        }

        return Stack(fit: StackFit.expand, children: cards);
      },
    );
  }

  Widget _buildTopCard(BuildContext context, DeckItem item, Size size) {
    final bool vertical = _drag.dy.abs() > _drag.dx.abs();

    // Only the dominant axis lights a hint up, so the user never sees "next"
    // and "save" fading in at the same time.
    final double progress = vertical
        ? 0
        : (_drag.dx / (size.width * AppConfig.deckSwipeThreshold)).clamp(
            -1.0,
            1.0,
          );
    final double upProgress = vertical
        ? (-_drag.dy / (size.height * AppConfig.deckSwipeUpThreshold)).clamp(
            0.0,
            1.0,
          )
        : 0;

    return GestureDetector(
      key: ValueKey<String>(item.key),
      behavior: HitTestBehavior.opaque,
      onPanUpdate: _onPanUpdate,
      onPanEnd: (DragEndDetails details) => _onPanEnd(details, size),
      child: Transform.translate(
        offset: _drag,
        child: Transform.rotate(
          // Pivot below the card so it tilts like a real card being pulled off
          // a stack instead of spinning around its middle.
          origin: const Offset(0, 320),
          angle: progress * 0.12,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              widget.builder(context, item, true),
              if (widget.hintLeft != null)
                _Hint(opacity: math.max(0, -progress), child: widget.hintLeft!),
              if (widget.hintRight != null)
                _Hint(opacity: math.max(0, progress), child: widget.hintRight!),
              if (widget.hintUp != null)
                _Hint(opacity: upProgress, child: widget.hintUp!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackCard(BuildContext context, DeckItem item, int depth) {
    // Cards behind peek out from under the top one. They never animate on
    // their own, hence the const-friendly static transform.
    return Transform.translate(
      key: ValueKey<String>(item.key),
      offset: Offset(0, depth * 12.0),
      child: Transform.scale(
        scale: 1 - depth * 0.04,
        child: IgnorePointer(child: widget.builder(context, item, false)),
      ),
    );
  }
}

/// Fades a hint badge in as the drag approaches the commit threshold.
class _Hint extends StatelessWidget {
  const _Hint({required this.opacity, required this.child});

  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: child),
    );
  }
}
