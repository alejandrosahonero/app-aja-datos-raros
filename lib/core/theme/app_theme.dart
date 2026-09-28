import 'package:aja/core/theme/app_colors.dart';
import 'package:aja/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Material 3 themes for the app.
///
/// Both schemes are hand-built in [AppColors]. Dynamic colour (Material You) is
/// deliberately not used: it would repaint the brand with the user's wallpaper.
/// Brand typefaces, bundled under `assets/fonts/` (OFL).
abstract final class AppFonts {
  /// Young Serif — headings, the question, the answer, the wordmark.
  static const String display = 'YoungSerif';

  /// Figtree — everything else.
  static const String body = 'Figtree';
}

abstract final class AppTheme {
  static ThemeData light([ColorScheme? dynamicScheme]) =>
      _build(dynamicScheme ?? AppColors.lightScheme, AppSemanticColors.light);

  static ThemeData dark([ColorScheme? dynamicScheme]) =>
      _build(dynamicScheme ?? AppColors.darkScheme, AppSemanticColors.dark);

  static ThemeData _build(ColorScheme scheme, AppSemanticColors semantic) {
    final ThemeData base = ThemeData(
      colorScheme: scheme,
      fontFamily: AppFonts.body,
    );
    final TextTheme texts = base.textTheme;
    // Young Serif has a single weight: headings keep the serif's own colour
    // instead of faking bold, which would smear its bracketed serifs.
    TextStyle? display(TextStyle? s) =>
        s?.copyWith(fontFamily: AppFonts.display, fontWeight: FontWeight.w400);

    return base.copyWith(
      textTheme: texts.copyWith(
        displayLarge: display(texts.displayLarge),
        displayMedium: display(texts.displayMedium),
        displaySmall: display(texts.displaySmall),
        headlineLarge: display(texts.headlineLarge),
        headlineMedium: display(texts.headlineMedium),
        headlineSmall: display(texts.headlineSmall),
        titleLarge: display(texts.titleLarge),
        labelLarge: texts.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      scaffoldBackgroundColor: scheme.surface,
      extensions: <ThemeExtension<dynamic>>[semantic],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 3,
        centerTitle: false,
        titleTextStyle: display(
          texts.titleLarge,
        )?.copyWith(color: scheme.onSurface, fontSize: 24),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: EdgeInsets.all(AppSpacing.md),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
    );
  }
}
