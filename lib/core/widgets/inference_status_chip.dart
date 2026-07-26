/// The always-visible "which engine is answering" indicator.
///
/// It lives in the app shell rather than on one screen, because the answer can
/// change at any moment — a caregiver walks out of Wi-Fi range mid-flow — and a
/// status that is only true on the screen where it happens to be drawn is worse
/// than no status at all.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../inference/inference_service.dart';
import '../theme/app_spacing.dart';

class InferenceStatusChip extends StatelessWidget {
  const InferenceStatusChip({required this.mode, super.key});

  final ActiveInferenceMode mode;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (mode) {
      // Deliberately not the brand red or the success green: this is telemetry
      // about the app, not an action or an achievement, and it must not compete
      // with either.
      ActiveInferenceMode.cloud => (
        const Color(0xFF1B4D7A),
        Colors.white,
        LucideIcons.cloud,
      ),
      ActiveInferenceMode.gemma => (
        const Color(0xFF14713D),
        Colors.white,
        LucideIcons.smartphone,
      ),
      ActiveInferenceMode.demo => (
        const Color(0xFFFFF0CC),
        const Color(0xFF8A5300),
        LucideIcons.triangleAlert,
      ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(mode),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The icon never travels alone — the label is the accessible
            // signal and the icon is the redundant one, not the reverse.
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
            Text(
              mode.label,
              style: TextStyle(
                color: foreground,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
