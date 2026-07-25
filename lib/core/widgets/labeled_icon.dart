/// An icon that cannot be shown without its label.
///
/// OWNER: P3 (UI).
///
/// **No icon in this app appears alone.** Icon literacy is learned, and the
/// glyphs that feel universal to a developer (a gear, a floppy disk, a speaker)
/// are not universal to someone who has used a smartphone for messaging and
/// little else. Making the label a required constructor argument is the cheapest
/// way to stop a bare icon reaching the screen.
///
/// The icon is decorative here — [ExcludeSemantics] hides it from TalkBack so
/// the label is announced once, not twice.
library;

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

enum LabeledIconLayout { horizontal, vertical }

class LabeledIcon extends StatelessWidget {
  const LabeledIcon({
    required this.icon,
    required this.label,
    this.layout = LabeledIconLayout.horizontal,
    this.color,
    this.size = AppSpacing.iconSize,
    this.labelStyle,
    super.key,
  });

  /// Always pass a `600` stroke variant (`LucideIcons.check600`). Lucide's
  /// default weight is drawn for screens indoors.
  final IconData icon;

  /// Never empty, never a duplicate of nearby text that the user would then
  /// have to read twice.
  final String label;

  final LabeledIconLayout layout;
  final Color? color;
  final double size;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.onSurface;
    final text = Text(
      label,
      style: (labelStyle ?? Theme.of(context).textTheme.labelLarge)?.copyWith(
        color: resolved,
      ),
      // No maxLines and no ellipsis: a clipped label is a label the user cannot
      // act on. If it needs two lines it takes two lines.
      textAlign: layout == LabeledIconLayout.vertical
          ? TextAlign.center
          : TextAlign.left,
    );
    final glyph = ExcludeSemantics(
      child: Icon(icon, size: size, color: resolved),
    );

    return switch (layout) {
      LabeledIconLayout.horizontal => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          glyph,
          const SizedBox(width: AppSpacing.md),
          Flexible(child: text),
        ],
      ),
      LabeledIconLayout.vertical => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          glyph,
          const SizedBox(height: AppSpacing.xs),
          text,
        ],
      ),
    };
  }
}
