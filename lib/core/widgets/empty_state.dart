/// A screen with nothing in it yet — and one obvious thing to do about that.
///
/// OWNER: P3 (UI).
///
/// An empty list with no explanation reads as breakage. Every empty state in
/// this app says three things in order: what is missing, why that is normal, and
/// the single action that fills it. No illustrations of people, no shrugging
/// mascots — just the sentence and the button.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  /// Decorative only — the title carries the meaning. Pass a `600` variant.
  final IconData icon;

  final String title;
  final String message;

  /// The one thing to do. Optional, because some empty states are reached from
  /// a screen whose CTA is already anchored at the bottom.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: 48, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.xl),
            action!,
          ],
        ],
      ),
    );
  }
}
