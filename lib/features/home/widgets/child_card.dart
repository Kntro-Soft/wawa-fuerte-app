/// One registered child on the Home list.
///
/// OWNER: P3 (UI).
///
/// ## Why the card has two halves
///
/// It carries three actions, and they are not equals. Opening the week is what
/// a caregiver came here to do; editing and deleting happen once in a while.
/// Putting a pencil and a bin inside a row that is itself tappable would make
/// three targets a few millimetres apart — the mistake `RecipeRow` documents
/// for the same reason.
///
/// So the upper block is one large target that opens the week, a rule separates
/// it, and the two administrative actions sit below with 56 dp each, 12 dp
/// apart, **each with its word beside its icon**. Nothing here is a bare glyph.
///
/// ## The medallion
///
/// A child is identified by the initial of her name on a coloured disc. A
/// caregiver who reads slowly can tell three cards apart by shape and colour
/// before she has finished reading any of the names — and once she has, the two
/// cues agree.
///
/// The colours come from [AppColors]' earth accents and cycle by position, so
/// they mean **nothing**: not status, not urgency, not order of importance. The
/// signalling colours — red, green, ochre — stay out of the cycle so that the
/// two systems can never be confused.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/domain/child_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class ChildCard extends StatelessWidget {
  const ChildCard({
    required this.child,
    required this.planSummary,
    required this.planIcon,
    required this.accentIndex,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final ChildProfile child;
  final String planSummary;

  /// The mark beside [planSummary]. The sentence says everything on its own;
  /// this is a second cue for a caregiver scanning three cards, and it never
  /// appears without its sentence.
  final IconData planIcon;

  /// Position in the list. Only picks the medallion colour.
  final int accentIndex;

  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Identity only, never state. See the class doc.
  static const List<Color> _accents = <Color>[
    AppColors.earth,
    AppColors.clay,
    AppColors.andean,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accents[accentIndex % _accents.length];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: AppColors.outline,
          width: AppSpacing.borderWidth,
        ),
      ),
      child: Column(
        children: [
          // --- The week. One target, the size of the block. -------------------
          Semantics(
            button: true,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLarge),
                ),
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: AppSpacing.selectableCardHeight,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      _Medallion(name: child.name, color: accent),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Names are never truncated — see RecipeRow for the
                            // same rule applied to dishes.
                            Text(child.name, style: theme.textTheme.titleLarge),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ExcludeSemantics(
                                  child: Icon(
                                    planIcon,
                                    size: 20,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    planSummary,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
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
          ),

          const Divider(height: 1, color: AppColors.outlineVariant),

          // --- The two rare actions, well apart from the big one. -------------
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _CardAction(
                    icon: LucideIcons.pencil600,
                    label: 'Editar',
                    semanticLabel: 'Editar los datos de ${child.name}',
                    color: AppColors.onSurface,
                    onTap: onEdit,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _CardAction(
                    icon: LucideIcons.trash2600,
                    label: 'Borrar',
                    semanticLabel: 'Borrar a ${child.name}',
                    color: AppColors.error,
                    onTap: onDelete,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Medallion extends StatelessWidget {
  const _Medallion({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '' : trimmed.characters.first;

    return ExcludeSemantics(
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Text(
          initial.toUpperCase(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// One of the card's two administrative actions.
///
/// Icon **and** word, always: the bin glyph in particular is one a user has to
/// have been taught, and this is the one action in the app that cannot be
/// undone.
class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: AppSpacing.iconSize, color: color),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
