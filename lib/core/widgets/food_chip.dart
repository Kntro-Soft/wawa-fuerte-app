/// A large text chip for selecting an ingredient.
///
/// OWNER: P3 (UI).
///
/// **Deliberately not an icon.** Papa, sangrecita, quinua and tarwi do not exist
/// in Lucide, Material Symbols, or any other international icon set — these are
/// Andean foods and Western icon libraries have no glyph for them. The available
/// substitutes are all worse than words:
///
/// - A generic bowl or leaf for four different ingredients teaches nothing and
///   makes four chips look interchangeable.
/// - Emoji are inconsistent across Android vendors, render at the system font
///   size (so they ignore our 28 dp floor), and read as decoration.
/// - Photographs would need sourcing, licensing and megabytes in an app that
///   already ships a >1 GB model.
///
/// So the chip *is* the word, set at `titleLarge` on a filled, bordered surface.
/// A caregiver who reads slowly still reads "sangrecita" faster than she decodes
/// an invented pictogram.
///
/// **The honest upgrade named above has now been made**: a small silhouette,
/// drawn for these specific foods in the food's own colour, sits to the left of
/// the word. See [FoodGlyph] for what it is and is not. The word did not move
/// and did not shrink — the mark is a second cue for scanning a wall of chips,
/// never a replacement for reading one.
///
/// Selection follows the same three-cue rule as [SelectableCard]: fill, 2 dp
/// border, and a check. The glyph takes no part in it — its colour is the
/// food's and never changes — so nothing about selection depends on hue.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'food_glyph.dart';

class FoodChip extends StatelessWidget {
  const FoodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.ingredient,
    super.key,
  });

  final String label;

  /// The corpus form of the name, which is what [FoodGlyph] looks up. Defaults
  /// to [label] lowercased when the caller has nothing better.
  final String? ingredient;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.successContainer : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            // Tighter than the 16 dp used elsewhere: the glyph already adds
            // width to every chip, and a pantry of fourteen items that wraps
            // to eight rows costs the caregiver more than the padding buys.
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(
                color: selected ? AppColors.success : AppColors.outline,
                width: selected
                    ? AppSpacing.selectedBorderWidth
                    : AppSpacing.borderWidth,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Which food. Never which state.
                FoodGlyph(
                  ingredient: ingredient ?? label.toLowerCase(),
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: selected
                        ? AppColors.onSuccessContainer
                        : AppColors.onSurface,
                  ),
                ),
                // Which state. The third cue, after fill and border weight.
                if (selected) ...[
                  const SizedBox(width: AppSpacing.md),
                  const Icon(
                    LucideIcons.check600,
                    size: AppSpacing.iconSize,
                    color: AppColors.success,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
