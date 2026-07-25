/// The app's colour tokens.
///
/// OWNER: P3 (UI).
///
/// **Eleven tokens, light mode only.** The constraint is not minimalism for its
/// own sake — it is that every extra hue is another thing four developers can
/// use inconsistently in six hours, and another thing that can fail contrast on
/// a scratched screen in direct sunlight.
///
/// Deliberate omissions, so nobody re-adds them by reflex:
///
/// - **No blue, teal, purple, pink, or a second desaturated red.** One red, one
///   green, and greys. A second red reads as a different meaning to a user who
///   is not looking closely.
/// - **No dark mode.** It doubles the contrast surface to verify and the user
///   we are designing for is outdoors in daylight, not in bed. Backlog.
/// - **No `ColorScheme.fromSeed`.** Seeding tonal palettes from [primary] pulls
///   the red toward a muted brick: Material's tonal algorithm optimises for
///   harmony, and harmony here costs legibility. The scheme is written out by
///   hand instead.
library;

import 'package:flutter/material.dart';

/// Raw palette values. Prefer reading colours off `Theme.of(context)`; these are
/// public only so tests and the odd one-off (`warning`, which Material's
/// [ColorScheme] has no slot for) can reach them.
abstract final class AppColors {
  // --- Red: identity, primary actions, destructive emphasis. ------------------

  /// The single red. Dark enough to carry white text at ~7:1.
  static const Color primary = Color(0xFFB01B1B);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Pressed state for [primary]. A darker red rather than an opacity overlay,
  /// because overlays wash out under glare.
  static const Color primaryPressed = Color(0xFF7F1214);

  static const Color primaryContainer = Color(0xFFFFE1DE);
  static const Color onPrimaryContainer = Color(0xFF5C0F0F);

  // --- Green: success, and the iron-coverage bar. -----------------------------

  /// Doubles as `secondary`. There is no third accent hue.
  static const Color success = Color(0xFF14713D);
  static const Color onSuccess = Color(0xFFFFFFFF);

  static const Color successContainer = Color(0xFFD6F0E0);
  static const Color onSuccessContainer = Color(0xFF0B3F22);

  // --- Surfaces. --------------------------------------------------------------

  /// Pure white. The earlier `#F5F5F5` page with white cards measured 1.05:1
  /// between the two — invisible at low screen brightness outdoors. Inverting
  /// it (white page, tinted cards) buys a usable edge for free.
  static const Color surface = Color(0xFFFFFFFF);

  /// Card and input fill.
  static const Color surfaceVariant = Color(0xFFF2EFEA);

  static const Color onSurface = Color(0xFF1A1A1A);

  /// Secondary text. ~8:1 on [surface]; still comfortably readable, but clearly
  /// subordinate to [onSurface].
  static const Color onSurfaceVariant = Color(0xFF4A4A4A);

  // --- Warning: advisory, never an error. -------------------------------------

  /// Material's [ColorScheme] has no warning slot, so this one is read from
  /// [AppColors] directly. Used for "standard preventive plan" style notices —
  /// information the caregiver should see, not a failure she caused.
  static const Color warning = Color(0xFF8A5300);
  static const Color warningContainer = Color(0xFFFFF0CC);

  // --- Error. -----------------------------------------------------------------

  static const Color error = Color(0xFF8C1007);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFD9D3);
  static const Color onErrorContainer = Color(0xFF5C0F0F);

  // --- Earth accents: identity, never state. ----------------------------------
  //
  // These came later than the eleven above and they are governed by one rule:
  // **nothing here ever means anything.** They group a section, give a screen a
  // recognisable top edge, and tell one child's card from her sister's. They
  // never say "selected", "done", "wrong" or "urgent" — [primary], [success],
  // [warning] and [error] keep that job exclusively, and they keep it alone so
  // that a new hue can never be mistaken for a new meaning.
  //
  // The hues are pigments rather than screen colours: fired clay, dry earth,
  // ochre, the green of a highland field. Peru without the postcard. Still no
  // blue, no teal, no purple, and no gradient — the palette doc above stands.

  /// Deep earth brown. Headers and section rules. 9:1 on [surface].
  static const Color earth = Color(0xFF4E3524);

  /// The tinted band an earth-toned header sits on.
  static const Color earthContainer = Color(0xFFF4EADF);
  static const Color onEarthContainer = Color(0xFF3B2716);

  /// Fired clay. The warmest accent, and the one closest to [primary] — it is
  /// used for large flat areas and never for a control, so the two cannot be
  /// confused at the size where it matters. 5.4:1 on [surface].
  static const Color clay = Color(0xFF9A4A2B);

  /// Dry ochre, the same pigment family as [warning].
  static const Color ochre = Color(0xFF8A5300);

  /// Highland field green, distinctly darker and duller than [success] so the
  /// achievement green stays the only green that reports anything. 7.4:1.
  static const Color andean = Color(0xFF3F5230);

  /// Unbleached wool. Fills only; never carries text.
  static const Color sand = Color(0xFFE9DCC6);

  // --- Borders. ---------------------------------------------------------------

  /// Every card and field carries a 1 dp [outline]. A shadow is never the only
  /// separator between two surfaces: shadows are low-contrast by construction
  /// and are the first thing to disappear when the screen dims or the sun hits.
  static const Color outline = Color(0xFF8A857D);

  /// Divider-weight border, for separators inside an already-bounded surface.
  static const Color outlineVariant = Color(0xFFDDD8D1);
}

/// The explicit [ColorScheme]. Hand-written, never seeded — see the library doc.
const ColorScheme appColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.primary,
  onPrimary: AppColors.onPrimary,
  primaryContainer: AppColors.primaryContainer,
  onPrimaryContainer: AppColors.onPrimaryContainer,
  // Green is the app's only secondary. Mapping success onto `secondary` keeps
  // Material's own widgets (chips, switches) inside the palette by default.
  secondary: AppColors.success,
  onSecondary: AppColors.onSuccess,
  secondaryContainer: AppColors.successContainer,
  onSecondaryContainer: AppColors.onSuccessContainer,
  // Material insists on a tertiary. Pointing it at the green rather than
  // inventing a hue keeps the token count honest at eleven.
  tertiary: AppColors.success,
  onTertiary: AppColors.onSuccess,
  tertiaryContainer: AppColors.successContainer,
  onTertiaryContainer: AppColors.onSuccessContainer,
  error: AppColors.error,
  onError: AppColors.onError,
  errorContainer: AppColors.errorContainer,
  onErrorContainer: AppColors.onErrorContainer,
  surface: AppColors.surface,
  onSurface: AppColors.onSurface,
  surfaceContainerHighest: AppColors.surfaceVariant,
  onSurfaceVariant: AppColors.onSurfaceVariant,
  surfaceContainerHigh: AppColors.surfaceVariant,
  surfaceContainer: AppColors.surfaceVariant,
  surfaceContainerLow: AppColors.surfaceVariant,
  surfaceContainerLowest: AppColors.surface,
  outline: AppColors.outline,
  outlineVariant: AppColors.outlineVariant,
);
