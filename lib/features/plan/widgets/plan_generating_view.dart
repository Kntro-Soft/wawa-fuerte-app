/// The full-screen "we are working on it" state.
///
/// OWNER: P3 (UI).
///
/// The prototype had no such state. On a low-end Android handset, on-device
/// Gemma takes **tens of seconds**, and a screen that does not move for that
/// long has crashed as far as the user is concerned.
///
/// Five decisions, all aimed at that:
///
/// 1. **Full screen.** Nothing else is on it, so there is nothing else to tap
///    and nothing that looks stuck.
/// 2. **Continuous motion.** An indeterminate animation, not a progress bar —
///    we genuinely cannot predict how long inference will take, and a fake
///    percentage that stalls at 80 % is worse than no percentage. The steam
///    rising off the pot is the same idea drawn rather than spun: as long as it
///    moves, the phone is working.
/// 3. **The copy names a duration.** "puede tardar un minutito" turns an
///    unexplained wait into an expected one. Vague reassurance ("Cargando…")
///    does not.
/// 4. **The wait is company, not silence.** A line under the pot changes every
///    few seconds: what the app is doing, and one thing worth knowing about iron
///    while she waits. It is deliberately **not** a progress narration — these
///    lines are on a timer, not on the model, and none of them claims that
///    anything is nearly finished. Telling someone "ya casi" when her phone has
///    another forty seconds to go is how an app loses her trust exactly once.
/// 5. **No retry, no cancel, no back.** Offering a way to restart during the
///    slowest operation in the app is offering a way to run two of them at once
///    on a phone already at its limit. The way out is waiting, and the wakelock
///    held by `PlanController` makes sure the screen is still on when it ends.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class PlanGeneratingView extends StatefulWidget {
  const PlanGeneratingView({required this.childName, super.key});

  final String childName;

  /// Long enough to be read once, unhurried, by someone who reads slowly.
  static const Duration messageInterval = Duration(seconds: 7);

  /// The lines that keep her company. They cycle rather than stopping on the
  /// last one: a very slow phone must not arrive at a screen that has gone
  /// still. None of them may claim the wait is nearly over — see decision 4.
  static const List<String> messages = <String>[
    'Estamos buscando entre las recetas del Ministerio de Salud.',
    'Escogemos las que tienen más hierro y usan lo que tienes en casa.',
    'Un dato: servir la comida con limonada o naranja ayuda a que el cuerpo '
        'aproveche mejor el hierro.',
    'El teléfono está trabajando. Puedes dejarlo un ratito y volver.',
  ];

  @override
  State<PlanGeneratingView> createState() => _PlanGeneratingViewState();
}

class _PlanGeneratingViewState extends State<PlanGeneratingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  Timer? _messageTimer;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _messageTimer = Timer.periodic(PlanGeneratingView.messageInterval, (_) {
      if (!mounted) return;
      setState(() => _messageIndex++);
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const messages = PlanGeneratingView.messages;

    return Semantics(
      liveRegion: true,
      label: 'Estamos armando el menú. Puede tardar un minuto.',
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: SizedBox(
                width: 120,
                height: 104,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) => CustomPaint(
                    painter: _SimmeringPotPainter(_animation.value),
                  ),
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

            // A second, linear motion cue, in case the steam is missed at a
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

            // The changing line. It cross-fades rather than cutting, so a
            // caregiver reading mid-sentence is not left wondering what she
            // missed.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                messages[_messageIndex % messages.length],
                key: ValueKey<int>(_messageIndex % messages.length),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              'Es el menú de ${widget.childName}.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// A clay pot on the fire, with steam coming off it.
///
/// Drawn rather than spun. A spinner is the same shape in every app already on
/// the phone and says only "something is happening somewhere"; a pot says *your
/// food is being worked on*, which is what is actually true. Three wisps rise,
/// fade and restart on a loop, so the motion never stops and never pretends to
/// measure anything.
class _SimmeringPotPainter extends CustomPainter {
  _SimmeringPotPainter(this.t);

  /// 0 → 1, looping.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- Steam: three wisps, offset in phase. -------------------------------
    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final x = w * (0.34 + 0.16 * i);
      final rise = h * 0.34 * phase;
      // In at the start, out at the end, never fully solid — because steam.
      final opacity = (phase < 0.5 ? phase * 2 : (1 - phase) * 2) * 0.55;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.onSurfaceVariant.withValues(alpha: opacity);

      final top = h * 0.38 - rise;
      final path = Path()
        ..moveTo(x, h * 0.40 - rise)
        ..quadraticBezierTo(x + 7, top - 6, x, top - 14)
        ..quadraticBezierTo(x - 7, top - 22, x, top - 30);
      canvas.drawPath(path, paint);
    }

    // --- The pot. -----------------------------------------------------------
    final body = Paint()..color = AppColors.clay;
    final rim = Paint()..color = AppColors.earth;

    // Handles first, so the body overlaps them cleanly.
    final handle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = AppColors.earth;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.20, h * 0.64), radius: h * 0.11),
      math.pi * 0.35,
      math.pi * 1.3,
      false,
      handle,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.80, h * 0.64), radius: h * 0.11),
      -math.pi * 0.65,
      math.pi * 1.3,
      false,
      handle,
    );

    // Narrower at the foot than at the rim, the way a cooking pot is.
    final pot = Path()
      ..moveTo(w * 0.20, h * 0.52)
      ..lineTo(w * 0.80, h * 0.52)
      ..lineTo(w * 0.70, h * 0.94)
      ..lineTo(w * 0.30, h * 0.94)
      ..close();
    canvas.drawPath(pot, body);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.44, w * 0.70, h * 0.10),
        const Radius.circular(4),
      ),
      rim,
    );
  }

  @override
  bool shouldRepaint(covariant _SimmeringPotPainter oldDelegate) =>
      oldDelegate.t != t;
}
