/// Assembles the tokens into one [ThemeData].
///
/// OWNER: P3 (UI).
///
/// Component defaults are set here rather than per-screen, so a developer who
/// writes a plain `FilledButton` gets the 64 dp, sentence-case, correctly
/// coloured button without knowing any of the rules.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final textTheme = AppTypography.textTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: appColorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.surface,

      // Elevation is off across the board. A drop shadow is a low-contrast cue
      // and it is the first thing to disappear outdoors; borders do the
      // separating instead (see AppColors.outline).
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceVariant,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          side: const BorderSide(
            color: AppColors.outline,
            width: AppSpacing.borderWidth,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          // Height is a minimum, not a fixed size: at textScaleFactor 1.5 the
          // label needs the button to grow rather than clip.
          minimumSize: const WidgetStatePropertyAll(
            Size(double.infinity, AppSpacing.ctaHeight),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.outlineVariant;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryPressed;
            }
            return AppColors.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.onSurfaceVariant;
            }
            return AppColors.onPrimary;
          }),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius),
            ),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),

      // Used for secondary, low-emphasis navigation such as "Volver al inicio".
      // Deliberately quieter than a FilledButton: on the result screen the
      // visual weight belongs to the recipes and the listen button, not to the
      // way out.
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AppSpacing.minTouchTarget),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryPressed;
            }
            return AppColors.primary;
          }),
          textStyle: WidgetStatePropertyAll(
            textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AppSpacing.minTouchTarget),
          ),
          foregroundColor: const WidgetStatePropertyAll(AppColors.onSurface),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.outline, width: AppSpacing.borderWidth),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius),
            ),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        // Hint text is visibly grey and visibly *not* a value. No field in this
        // app ships with a prefilled number — see the onboarding screen.
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: textTheme.bodyLarge,
        helperStyle: textTheme.bodySmall,
        helperMaxLines: 4,
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.error),
        errorMaxLines: 3,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: _fieldBorder(AppColors.outline, AppSpacing.borderWidth),
        enabledBorder: _fieldBorder(AppColors.outline, AppSpacing.borderWidth),
        focusedBorder: _fieldBorder(
          AppColors.primary,
          AppSpacing.selectedBorderWidth,
        ),
        errorBorder: _fieldBorder(
          AppColors.error,
          AppSpacing.selectedBorderWidth,
        ),
        focusedErrorBorder: _fieldBorder(
          AppColors.error,
          AppSpacing.selectedBorderWidth,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(
        color: AppColors.onSurface,
        size: AppSpacing.iconSize,
      ),

      // Bigger than Material's default, matching AppSpacing.minTouchTarget.
      materialTapTargetSize: MaterialTapTargetSize.padded,

      splashFactory: InkRipple.splashFactory,
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
