/// One day of the week in the result list.
///
/// OWNER: P3 (UI).
///
/// ## Recipe names are never truncated
///
/// The prototype cut them with an ellipsis: "Segundo de sangrecita con arr…".
/// Peruvian dish names carry their ingredients — that *is* the information — so
/// the truncated half is the half that tells a caregiver whether she can cook it
/// tonight. The row therefore has **no `maxLines` and no `TextOverflow`**, sits
/// at `titleLarge` (20 sp), and grows to whatever height the name needs. Two
/// lines is the common case, three is fine.
///
/// ## The day has a name
///
/// "Lunes", never "Día 1" — see `DayNames`.
///
/// ## One target per row
///
/// The whole row opens the recipe. The "Ya lo preparé" control deliberately does
/// **not** live here: a checkbox inside a tappable row means two targets a few
/// millimetres apart, and with wet hands that is a coin flip. Prepared status
/// shows here as a read-only badge and is toggled on the recipe screen, where it
/// gets a full-width control to itself.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/domain/weekly_plan.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/day_names.dart';

class RecipeRow extends StatelessWidget {
  const RecipeRow({required this.day, required this.onTap, super.key});

  final PlanDay day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      child: Material(
        color: day.prepared
            ? AppColors.successContainer
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.selectableCardHeight,
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(
                color: day.prepared ? AppColors.success : AppColors.outline,
                width: day.prepared
                    ? AppSpacing.selectedBorderWidth
                    : AppSpacing.borderWidth,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DayNames.of(day.dayIndex),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: day.prepared
                              ? AppColors.onSuccessContainer
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // No maxLines, no overflow. See the class doc.
                      Text(
                        day.recipe.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: day.prepared
                              ? AppColors.onSuccessContainer
                              : AppColors.onSurface,
                        ),
                      ),

                      if (day.prepared) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.circleCheck600,
                              size: AppSpacing.iconSize,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Ya lo preparaste',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.onSuccessContainer,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const ExcludeSemantics(
                  child: Icon(
                    LucideIcons.chevronRight600,
                    size: AppSpacing.actionIconSize,
                    color: AppColors.onSurfaceVariant,
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
