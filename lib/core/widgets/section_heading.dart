/// A screen's section title, with the one icon that earns its place.
///
/// OWNER: P3 (UI).
///
/// Every screen used to open with a bare 24 sp line, which made a long scroll
/// read as one undifferentiated column of text. An icon at the head of a
/// section is the cheapest way to give a caregiver a landmark to scroll back
/// to — she remembers *the basket one*, not the third heading down.
///
/// It follows the same rule as everything else here: the icon is decorative,
/// the words carry the meaning, and the two always travel together. There is no
/// variant of this widget without a title.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    required this.icon,
    required this.title,
    this.color = AppColors.earth,
    super.key,
  });

  /// Always a `600` stroke variant — Lucide's default weight dissolves in
  /// glare (see [AppSpacing.iconSize]).
  final IconData icon;

  final String title;

  /// An earth accent by default. Never a state colour.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Icon(icon, size: AppSpacing.iconSize, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
      ],
    );
  }
}
