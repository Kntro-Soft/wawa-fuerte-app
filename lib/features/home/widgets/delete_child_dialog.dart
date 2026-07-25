/// Confirmation before erasing a child's profile.
///
/// OWNER: P3 (UI).
///
/// Deleting is **irreversible and it takes her plans with it**: in SQLite the
/// profile row cascades to `weekly_plans` and `plan_days` (ADR-0013). There is
/// no server, no backup and no undo, so the confirmation says what disappears
/// instead of asking a bare "¿Estás segura?" — a question with no content is a
/// question people answer yes to by reflex.
///
/// The destructive button carries the child's name. Reading "Sí, borrar a
/// Rosita" is a different act from tapping "Aceptar", and it is the last
/// chance to notice the wrong card was tapped.
///
/// Cancel is the *first* action listed and the roomier one to reach; the
/// destructive button is not styled to look inviting.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

Future<bool> showDeleteChildDialog(
  BuildContext context, {
  required String childName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _DeleteChildDialog(childName: childName),
  );
  return confirmed ?? false;
}

class _DeleteChildDialog extends StatelessWidget {
  const _DeleteChildDialog({required this.childName});

  final String childName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        side: const BorderSide(
          color: AppColors.error,
          width: AppSpacing.selectedBorderWidth,
        ),
      ),
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(
            child: Icon(
              LucideIcons.triangleAlert600,
              size: AppSpacing.actionIconSize,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '¿Borrar a $childName?',
              style: theme.textTheme.headlineSmall,
            ),
          ),
        ],
      ),
      content: Text(
        'Se borran sus datos y todos sus menús. No se puede recuperar.',
        style: theme.textTheme.bodyLarge,
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The way out comes first and is the plainer of the two.
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: const ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(
                    Size(double.infinity, AppSpacing.ctaHeight),
                  ),
                ),
                child: const Text('No, mejor no'),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(AppColors.error),
                  foregroundColor: WidgetStatePropertyAll(AppColors.onError),
                  minimumSize: WidgetStatePropertyAll(
                    Size(double.infinity, AppSpacing.minTouchTarget),
                  ),
                ),
                icon: const Icon(
                  LucideIcons.trash2600,
                  size: AppSpacing.actionIconSize,
                ),
                label: Text('Sí, borrar a $childName'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
