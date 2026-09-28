import 'package:flutter/material.dart';

/// Brand palette "Subrayador": navy ink on cool paper, and a highlighter
/// yellow that marks the discovery (the answer) and little else.
///
/// Both [ColorScheme]s are built by hand rather than with
/// `ColorScheme.fromSeed`, which shifts every tone and would wash the yellow
/// out. Colours Material has no role for live in [AppSemanticColors].
abstract final class AppColors {
  /// Tinta — brand dark: text, app bar, share image, primary in light mode.
  static const Color ink = Color(0xFF14213D);

  /// Rotulador — highlighter accent.
  static const Color highlighter = Color(0xFFFFE14A);

  /// Papel frío — app background in light mode.
  static const Color paper = Color(0xFFE8EBEF);

  /// Folio — card surface in light mode.
  static const Color sheet = Color(0xFFFFFFFF);

  /// Grafito — secondary text.
  static const Color graphite = Color(0xFF5A6479);

  /// Noche — app background in dark mode.
  static const Color night = Color(0xFF0D1322);

  /// Card surface in dark mode.
  static const Color nightSheet = Color(0xFF172035);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFB45309);

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: ink,
    onPrimary: highlighter,
    primaryContainer: highlighter,
    onPrimaryContainer: ink,
    secondary: graphite,
    onSecondary: sheet,
    secondaryContainer: ink,
    onSecondaryContainer: highlighter,
    tertiary: Color(0xFF7A6300),
    onTertiary: sheet,
    error: Color(0xFFB3261E),
    onError: sheet,
    surface: paper,
    onSurface: ink,
    onSurfaceVariant: graphite,
    surfaceContainerLowest: sheet,
    surfaceContainerLow: sheet,
    surfaceContainer: Color(0xFFF4F6F9),
    surfaceContainerHigh: sheet,
    surfaceContainerHighest: Color(0xFFDDE2E9),
    outline: Color(0xFF8A93A6),
    outlineVariant: Color(0xFFD3D8E0),
    shadow: ink,
    surfaceTint: Colors.transparent,
    inverseSurface: ink,
    onInverseSurface: Color(0xFFEEF1F6),
    inversePrimary: highlighter,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: highlighter,
    onPrimary: ink,
    primaryContainer: Color(0xFF4A3F0A),
    onPrimaryContainer: highlighter,
    secondary: Color(0xFF9AA5BB),
    onSecondary: night,
    secondaryContainer: highlighter,
    onSecondaryContainer: ink,
    tertiary: Color(0xFFFFE98A),
    onTertiary: ink,
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    surface: night,
    onSurface: Color(0xFFEEF1F6),
    onSurfaceVariant: Color(0xFF9AA5BB),
    surfaceContainerLowest: Color(0xFF0A0F1B),
    surfaceContainerLow: nightSheet,
    surfaceContainer: Color(0xFF131B2D),
    surfaceContainerHigh: nightSheet,
    surfaceContainerHighest: Color(0xFF1E2942),
    outline: Color(0xFF55617C),
    outlineVariant: Color(0xFF26314A),
    shadow: Colors.black,
    surfaceTint: Colors.transparent,
    inverseSurface: Color(0xFFEEF1F6),
    onInverseSurface: ink,
    inversePrimary: ink,
  );
}

/// Semantic colours resolved per brightness and exposed through
/// `Theme.of(context).extension<AppSemanticColors>()`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.highlight,
    required this.onHighlight,
  });

  final Color success;
  final Color warning;

  /// The highlighter stroke behind the answer — the brand's signature mark.
  final Color highlight;
  final Color onHighlight;

  static const AppSemanticColors light = AppSemanticColors(
    success: AppColors.success,
    warning: AppColors.warning,
    highlight: AppColors.highlighter,
    onHighlight: AppColors.ink,
  );

  static const AppSemanticColors dark = AppSemanticColors(
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    highlight: Color(0xFF6B5A0C),
    onHighlight: Color(0xFFFFF4B8),
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? highlight,
    Color? onHighlight,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      highlight: highlight ?? this.highlight,
      onHighlight: onHighlight ?? this.onHighlight,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      highlight: Color.lerp(highlight, other.highlight, t) ?? highlight,
      onHighlight: Color.lerp(onHighlight, other.onHighlight, t) ?? onHighlight,
    );
  }
}
