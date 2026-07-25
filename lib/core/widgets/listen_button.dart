/// The "Escuchar" button: 64 × 64 dp of icon, plus the word.
///
/// OWNER: P3 (UI).
///
/// This is the app's core accessibility affordance, not a convenience. A
/// caregiver who does not read fluently, or whose hands are covered in flour,
/// gets the preparation steps through this button or not at all. It is therefore
/// the largest control in the app and it is never reduced to a bare speaker
/// glyph — the speaker icon is one of the most misread symbols there is, so the
/// word "Escuchar" sits beside it always.
///
/// What it reads aloud is the **preparation steps**, never the recipe title. The
/// title is already on screen in 20 sp; the steps are the part the user cannot
/// hold in her head while cooking.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ListenButton extends StatelessWidget {
  const ListenButton({
    required this.onPressed,
    this.isSpeaking = false,
    super.key,
  });

  final VoidCallback onPressed;

  /// While speaking, the same control stops playback. One button, two states —
  /// a separate stop button would be one more thing to find.
  final bool isSpeaking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = isSpeaking ? 'Detener' : 'Escuchar';

    return Semantics(
      button: true,
      label: isSpeaking
          ? 'Detener la lectura de los pasos'
          : 'Escuchar los pasos de la receta',
      child: Material(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onPressed();
          },
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.audioButtonSize,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(
                color: AppColors.primary,
                width: AppSpacing.selectedBorderWidth,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    isSpeaking ? LucideIcons.x600 : LucideIcons.volume2600,
                    size: AppSpacing.audioButtonSize / 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  child: ExcludeSemantics(
                    child: Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
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
