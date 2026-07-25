/// A screen with nothing in it yet — and one obvious thing to do about that.
///
/// OWNER: P3 (UI).
///
/// An empty list with no explanation reads as breakage. Every empty state in
/// this app says three things in order: what is missing, why that is normal, and
/// the single action that fills it. No illustrations of people, no shrugging
/// mascots — just the sentence and the button.
///
/// It should still feel like somebody is talking to her, though, so the block
/// sits on a warm tinted panel with its icon on a sand disc rather than being a
/// grey glyph floating above grey text. Warmth here is not decoration: an empty
/// Home is the first thing a new user sees, and "nothing here yet" and
/// "something went wrong" look identical when both are grey.
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.earthContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        // A border, not a shadow: shadows are the first thing to disappear
        // outdoors (see AppColors.outline).
        border: Border.all(
          color: AppColors.outlineVariant,
          width: AppSpacing.borderWidth,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.sand,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.earth),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onEarthContainer,
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
