/// Ergonomic minimums and spacing steps.
///
/// OWNER: P3 (UI).
///
/// Every number here sits **above** the Material minimum, on purpose. Material's
/// 48 dp target assumes a dry index finger, a clean screen and a user paying
/// attention. Our user is cooking: hands wet or busy, screen scratched, sun on
/// the glass, a child in the room. The extra millimetres are the cheapest
/// accuracy we can buy.
library;

abstract final class AppSpacing {
  // --- Spacing steps. ---------------------------------------------------------

  static const double xs = 4;
  static const double sm = 8;

  /// Minimum gap between two independent touch targets. Below this, a slip
  /// lands on the neighbour instead of missing harmlessly.
  static const double md = 12;

  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Standard horizontal page inset.
  static const double screenPadding = 16;

  // --- Touch targets. ---------------------------------------------------------

  /// Absolute floor for anything tappable, in both axes.
  static const double minTouchTarget = 56;

  /// Primary call to action: full-bleed minus [screenPadding] on each side.
  static const double ctaHeight = 64;

  /// A selectable card. The **whole** card is the target, never a small control
  /// inside it — aiming at a checkbox is harder than aiming at a card.
  static const double selectableCardHeight = 88;

  /// The listen (TTS) button. The single largest control in the app, because it
  /// is the way in for a caregiver who cannot read the steps.
  static const double audioButtonSize = 64;

  /// Text fields. Roomy enough that the numeric keyboard's own hit targets are
  /// not the tightest thing on screen.
  static const double fieldHeight = 64;

  // --- Icons. -----------------------------------------------------------------

  /// Minimum icon size. Lucide is a thin-stroke set; below this it dissolves in
  /// glare. Always use the `600` stroke variants (e.g. `LucideIcons.check600`).
  static const double iconSize = 28;

  /// Icons that are themselves the action.
  static const double actionIconSize = 32;

  // --- Borders. ---------------------------------------------------------------

  /// Resting border on cards and fields.
  static const double borderWidth = 1;

  /// Border on a *selected* card. Selection is signalled by three simultaneous
  /// changes — fill, this thicker border, and a check mark — because [AppColors]
  /// red and green sit at nearly the same luminance. A colour-blind user, or a
  /// sighted one under a glare that flattens saturation, would see no difference
  /// from hue alone.
  static const double selectedBorderWidth = 2;

  static const double radius = 12;
  static const double radiusLarge = 16;
}
