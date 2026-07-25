/// One question in the onboarding scroll.
///
/// OWNER: P3 (UI).
///
/// The old build spread these across several screens joined by a segmented
/// progress bar. The bar was removed along with the screens: it measured how
/// much was left of a wizard, which is a problem it created itself. One scroll
/// answers the same question — how much is left — with the scrollbar, and it
/// lets a caregiver go back to an earlier answer without losing what she typed.
///
/// Every question is a heading in plain Spanish followed by its control. The
/// heading is a real question ("¿Qué edad tiene?"), not a field label ("Edad"),
/// because a question tells you what to do and a label only names a box.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class QuestionSection extends StatelessWidget {
  const QuestionSection({
    required this.question,
    required this.child,
    this.help,
    this.optional = false,
    super.key,
  });

  final String question;

  /// Plain-language explanation. Used where a word on the card is not enough —
  /// most importantly on the hemoglobin question, where the honest help text is
  /// "look for this box in the booklet", not a definition.
  final String? help;

  /// Marks the question as skippable **in words**, not with a subtle style
  /// difference. "(opcional)" in the heading is read; a lighter grey is not.
  final bool optional;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          optional ? '$question (opcional)' : question,
          style: theme.textTheme.headlineSmall,
        ),
        if (help != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            help!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        child,
      ],
    );
  }
}
