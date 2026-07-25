/// An inline notice: advisory, or an error the user can act on.
///
/// OWNER: P3 (UI).
///
/// The tone distinction matters and ADR-0007 names it explicitly: a caregiver
/// with no CRED booklet has not made a mistake, so "no hemoglobin reading" is
/// [NoticeTone.advice] — framed as *this can be more precise later* — and never
/// styled like a failure. [NoticeTone.problem] is reserved for things that
/// actually went wrong, such as the model failing to generate.
///
/// Both tones carry an icon **and** a heading in words, because the two
/// container colours are close in luminance by design.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum NoticeTone { advice, problem }

class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    required this.title,
    required this.message,
    this.tone = NoticeTone.advice,
    this.action,
    super.key,
  });

  final String title;
  final String message;
  final NoticeTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (background, foreground, icon) = switch (tone) {
      NoticeTone.advice => (
        AppColors.warningContainer,
        AppColors.warning,
        LucideIcons.info600,
      ),
      NoticeTone.problem => (
        AppColors.errorContainer,
        AppColors.error,
        LucideIcons.triangleAlert600,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: foreground, width: AppSpacing.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(icon, size: AppSpacing.iconSize, color: foreground),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: theme.textTheme.bodyLarge),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
