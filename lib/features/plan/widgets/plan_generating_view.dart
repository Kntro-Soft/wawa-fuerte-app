/// The full-screen "we are working on it" state.
///
/// OWNER: P3 (UI).
///
/// The prototype had no such state. On a low-end Android handset, on-device
/// Gemma takes **tens of seconds**, and a screen that does not move for that
/// long has crashed as far as the user is concerned.
///
/// Four decisions, all aimed at that:
///
/// 1. **Full screen.** Nothing else is on it, so there is nothing else to tap
///    and nothing that looks stuck.
/// 2. **Continuous motion.** An indeterminate animation, not a progress bar —
///    we genuinely cannot predict how long inference will take, and a fake
///    percentage that stalls at 80 % is worse than no percentage.
/// 3. **The copy names a duration.** "puede tardar un minutito" turns an
///    unexplained wait into an expected one. Vague reassurance ("Cargando…")
///    does not.
/// 4. **No retry, no cancel, no back.** Offering a way to restart during the
///    slowest operation in the app is offering a way to run two of them at once
///    on a phone already at its limit. The way out is waiting, and the wakelock
///    held by `PlanController` makes sure the screen is still on when it ends.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class PlanGeneratingView extends StatefulWidget {
  const PlanGeneratingView({required this.childName, super.key});

  final String childName;

  @override
  State<PlanGeneratingView> createState() => _PlanGeneratingViewState();
}

class _PlanGeneratingViewState extends State<PlanGeneratingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      liveRegion: true,
      label: 'Estamos armando el menú. Puede tardar un minuto.',
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A slowly rotating pot. Motion is the message: as long as it
            // turns, the phone is working.
            ExcludeSemantics(
              child: RotationTransition(
                turns: _animation,
                child: const Icon(
                  LucideIcons.loaderCircle600,
                  size: 72,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Estamos armando el menú de tu wawa…',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Puede tardar un minutito. Deja el teléfono encendido, '
              'no lo cierres.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // A second, linear motion cue, in case the rotation is missed at a
            // glance from across the kitchen.
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: const LinearProgressIndicator(
                minHeight: 12,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Estamos escogiendo las comidas de ${widget.childName} '
              'con lo que tienes en casa.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
