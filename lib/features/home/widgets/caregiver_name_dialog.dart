/// The one place the caregiver's own name can be seen and changed.
///
/// OWNER: P3 (UI).
///
/// **A dialog, not a screen, and not a fifth route.** It is one optional field
/// whose only job is a greeting (Flow 0 — there is no account and nobody to
/// authenticate against, ADR-0002). The old build gave it a whole screen; a
/// whole screen for a salutation is what the onboarding rewrite removed. A
/// settings *screen* would be worse still: one field does not justify a
/// destination, and every extra destination is another place a caregiver can
/// get lost.
///
/// Returns the typed name, or **null when she cancelled** — which is a
/// different thing from an empty string, and empty clears the name.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

Future<String?> showCaregiverNameDialog(
  BuildContext context, {
  String? currentName,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CaregiverNameDialog(currentName: currentName),
  );
}

class _CaregiverNameDialog extends StatefulWidget {
  const _CaregiverNameDialog({this.currentName});

  final String? currentName;

  @override
  State<_CaregiverNameDialog> createState() => _CaregiverNameDialogState();
}

class _CaregiverNameDialogState extends State<_CaregiverNameDialog> {
  late final TextEditingController _field = TextEditingController(
    // Prefilling here is right, and it is not the hemoglobin case: this is a
    // name she typed herself, shown back so she can correct it. Nothing is
    // computed from it and no plan is scored against it.
    text: widget.currentName ?? '',
  );

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        side: const BorderSide(
          color: AppColors.outline,
          width: AppSpacing.borderWidth,
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
      title: Text('¿Cómo te llamamos?', style: theme.textTheme.headlineSmall),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solo lo usamos para saludarte. Puedes dejarlo vacío.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _field,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: theme.textTheme.titleLarge,
            decoration: const InputDecoration(hintText: 'Tu nombre'),
          ),
        ],
      ),
      // Stacked and full width rather than two small links in a corner: these
      // are the same 56 dp targets as everywhere else in the app.
      actions: [
        SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_field.text),
                icon: const Icon(
                  LucideIcons.check600,
                  size: AppSpacing.actionIconSize,
                ),
                label: const Text('Guardar'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: const ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(
                    Size(double.infinity, AppSpacing.minTouchTarget),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
