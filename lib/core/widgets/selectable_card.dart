/// A large, whole-surface tappable card used for every choice in the app.
///
/// OWNER: P3 (UI).
///
/// Two rules are baked in and are not overridable per call site:
///
/// **1. Selection never depends on colour alone.** `AppColors.primary` (red) and
/// `AppColors.success` (green) sit at nearly the same luminance, so to a red-green
/// colour-blind user — or to anyone whose screen is being flattened by direct
/// sun — a hue change carries no information at all. A selected card therefore
/// changes three things at once: fill, border weight (1 dp → 2 dp), and a check
/// mark that appears where there was none.
///
/// **2. The whole card is the target.** Minimum 88 dp tall, full width. Aiming
/// at a 20 dp radio button with wet hands is a different task from aiming at a
/// card, and only one of them is reliable.
///
/// Selecting also fires [HapticFeedback.selectionClick]. When the user is
/// cooking and glancing at the screen sideways, the buzz confirms the tap landed
/// before her eyes get back to it.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SelectableCard extends StatelessWidget {
  const SelectableCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
    this.leading,
    this.trailing,
    super.key,
  });

  final String label;

  /// An optional icon at the head of the card, e.g. the mountains beside
  /// "Sierra". Unlike [trailing] it is shown in **both** states, because it
  /// identifies the option rather than reporting anything about it — an icon
  /// that vanishes on selection would make the selected card look like a
  /// different card.
  ///
  /// It is decorative: [label] always says the same thing in words.
  final IconData? leading;

  /// Optional second line — a plain-language gloss, never a duplicate of
  /// [label].
  final String? description;

  final bool selected;
  final VoidCallback onTap;

  /// Extra content on the right, e.g. a colour swatch. The check mark takes
  /// precedence when [selected], so this is only shown while unselected.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primaryContainer : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          child: Container(
            // A minimum, not a height: at textScaleFactor 1.5 the card grows.
            constraints: const BoxConstraints(
              minHeight: AppSpacing.selectableCardHeight,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.outline,
                width: selected
                    ? AppSpacing.selectedBorderWidth
                    : AppSpacing.borderWidth,
              ),
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  ExcludeSemantics(
                    child: Icon(
                      leading,
                      size: AppSpacing.actionIconSize,
                      color: selected
                          ? AppColors.onPrimaryContainer
                          : AppColors.earth,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: selected
                              ? AppColors.onPrimaryContainer
                              : AppColors.onSurface,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: selected
                                ? AppColors.onPrimaryContainer
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // The third, non-chromatic selection cue.
                if (selected) ...[
                  const SizedBox(width: AppSpacing.md),
                  const Icon(
                    LucideIcons.check600,
                    size: AppSpacing.actionIconSize,
                    color: AppColors.primary,
                  ),
                ] else if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
