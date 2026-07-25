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
/// an invented pictogram. If time allows later, the honest upgrade is flat
/// vector illustrations drawn for these specific foods — never stock photos.
///
/// Selection follows the same three-cue rule as [SelectableCard]: fill, 2 dp
/// border, and a check.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class FoodChip extends StatelessWidget {
  const FoodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
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
                if (selected) ...[
                  const Icon(
                    LucideIcons.check600,
                    size: AppSpacing.iconSize,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: selected
                        ? AppColors.onSuccessContainer
                        : AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
