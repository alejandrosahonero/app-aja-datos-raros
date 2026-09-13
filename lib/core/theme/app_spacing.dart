/// Spacing and radius tokens.
///
/// Hard-coded paddings scattered across widgets are the main source of visual
/// drift between screens; always use a token.
abstract final class AppSpacing {
  /// Below this a gap stops reading as intentional and starts reading as a
  /// layout bug. Reserved for spots that were deliberately squeezed to their
  /// limit — the deck's chips/banner/cards stack — not a general-purpose
  /// small gap; reach for [xs] first.
  static const double hairline = 2;

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double pill = 999;
}
