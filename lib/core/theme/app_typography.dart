/// The app's type scale: one family, seven roles.
///
/// OWNER: P3 (UI).
///
/// **Lexend**, everywhere. It was drawn against reading-proficiency research
/// rather than for style, its letterforms are wide and unambiguous at small
/// optical sizes, and — the reason it matters here — the app's reader may be
/// decoding words letter by letter rather than recognising them whole.
///
/// Hard rules, enforced by every constant below:
///
/// - **Nothing below 15 sp.** The body default is 18 sp, not Material's 14 sp.
/// - **Nothing below weight 400.** Lexend's lighter cuts vanish in sunlight.
/// - **Nothing in ALL CAPS.** Capitals flatten a word's ascender/descender
///   silhouette, and that silhouette is exactly the cue a non-fluent reader
///   leans on. Material sets `letterSpacing` on `labelLarge` for uppercase
///   buttons; we zero it out and keep sentence case.
/// - **Always left-aligned.** Centred text gives every line a different starting
///   x, so the eye has to hunt for the next line.
/// - **No fixed heights around text.** Everything must survive
///   `textScaleFactor` 1.5× — see `AppSpacing` for the layout side of this.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  /// Line height for headings. Tight enough to hold a title together as one
  /// object, loose enough for Lexend's tall x-height.
  static const double _headingHeight = 1.2;

  /// Line height for running text. Generous: extra leading is the cheapest
  /// legibility win there is, and it also gives 1.5× scaling room to grow into.
  static const double _bodyHeight = 1.4;

  static TextTheme textTheme() {
    const color = AppColors.onSurface;

    return GoogleFonts.lexendTextTheme(
      const TextTheme(
        // Wordmark and the single biggest number on a screen.
        displayLarge: TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w700,
          height: _headingHeight,
          color: color,
        ),
        // Screen titles.
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: _headingHeight,
          color: color,
        ),
        // Section questions inside the onboarding scroll.
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: _headingHeight,
          color: color,
        ),
        // Recipe names and card titles. Never truncated — see RecipeRow.
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: _headingHeight,
          color: color,
        ),
        // The default. Everything that is not explicitly something else.
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: _bodyHeight,
          color: color,
        ),
        bodyMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: _bodyHeight,
          color: color,
        ),
        // Button and icon-pair labels. As large as a card title: a label the
        // user must hit is not less important than the text next to it.
        labelLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: _headingHeight,
          // Zeroed on purpose: Material's default spacing exists for uppercase
          // buttons, which this app does not have.
          letterSpacing: 0,
          color: color,
        ),
        // The floor. Captions, helper text, units. 15 sp / weight 500 — the
        // extra weight compensates for the smaller size outdoors.
        bodySmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: _bodyHeight,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
