/// The weekly iron coverage readout.
///
/// OWNER: P3 (UI), against P2's arithmetic.
///
/// This is the one number a caregiver may actually change her cooking over, so
/// two rules govern it.
///
/// **1. The raw milligrams are shown, not just the percentage.** "27 mg de los
/// 35 mg de la semana · 78 %" says where the number came from; "78 %" alone is
/// an opaque score. ADR-0005 keeps this figure out of the model's hands
/// precisely because it must be checkable, and a percentage with no numerator
/// is not checkable.
///
/// **2. `hasOfficialRequirement` is consulted before any percentage is drawn.**
/// This is the sharp edge ADR-0012 leaves behind: outside the published age
/// bands `requiredMg` is 0, which makes `IronCoverage.percent` return 0 and —
/// far worse — makes `meetsTarget` return `true`, because `0 >= 0`. Rendering
/// that unguarded would tell the mother of a three-month-old that her baby had
/// met his weekly iron target. The widget shows a plain explanatory notice in
/// that case and no number at all.
///
/// The bar is green ([AppColors.success]). Coverage is progress, not an alarm;
/// red is reserved for actions and errors.
///
/// **3. It is the loudest thing on the result screen.** The percentage is set
/// at `displayLarge` — the size otherwise reserved for the wordmark — because
/// this is the answer to the question the caregiver opened the app with, and
/// everything else on the screen is the working. Earlier the whole card sat at
/// body weight and competed with seven recipe rows for attention; a caregiver
/// glancing at her phone across a kitchen could not tell at a distance whether
/// the week had gone well.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../domain/weekly_plan.dart';
import '../nutrition/table_iron_calculator.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class IronCoverageBar extends StatelessWidget {
  const IronCoverageBar({
    required this.coverage,
    required this.ageMonths,
    this.calculator = const TableIronCalculator(),
    super.key,
  });

  final IronCoverage coverage;

  /// The child's age at the time the plan was generated. Drives the guard.
  final int ageMonths;

  final TableIronCalculator calculator;

  @override
  Widget build(BuildContext context) {
    // THE GUARD. Nothing numeric is rendered above this line.
    if (!calculator.hasOfficialRequirement(ageMonths)) {
      return const _NoOfficialRequirementNotice();
    }

    final theme = Theme.of(context);
    final provided = coverage.providedMg;
    final required = coverage.requiredMg;
    final percent = coverage.percent;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: AppColors.success,
          width: AppSpacing.selectedBorderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ExcludeSemantics(
                child: Icon(
                  LucideIcons.droplet600,
                  size: AppSpacing.iconSize,
                  color: AppColors.onSuccessContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Hierro de la semana',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.onSuccessContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // The headline. Big enough to read from across the kitchen, which is
          // where the phone usually is while the pot is on.
          Text(
            '${percent.round()} %',
            style: theme.textTheme.displayLarge?.copyWith(
              color: AppColors.onSuccessContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // The working, directly under the answer. A percentage with no
          // numerator is not checkable, and ADR-0005 keeps this figure out of
          // the model's hands precisely so that it can be checked.
          Text(
            '${_mg(provided)} mg de los ${_mg(required)} mg de la semana',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSuccessContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            child: LinearProgressIndicator(
              // Clamped at 1.0 so an over-target week still reads as a full
              // bar rather than overflowing.
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: 20,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Never colour-only: the outcome is spelled out in words as well.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                coverage.meetsTarget
                    ? LucideIcons.circleCheck600
                    : LucideIcons.info600,
                size: AppSpacing.iconSize,
                color: AppColors.onSuccessContainer,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  coverage.meetsTarget
                      ? 'Este menú cubre el hierro que tu wawa necesita esta semana.'
                      : 'Este menú se queda un poco corto. Sirve las comidas con '
                            'limonada o naranja: ayuda a aprovechar mejor el hierro.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSuccessContainer,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// One decimal, comma separator — the decimal mark used in Peru.
  static String _mg(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');
}

/// Shown instead of a percentage when no official requirement exists for the
/// child's age. See ADR-0012.
class _NoOfficialRequirementNotice extends StatelessWidget {
  const _NoOfficialRequirementNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(
          color: AppColors.warning,
          width: AppSpacing.borderWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.info600,
            size: AppSpacing.iconSize,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Todavía no podemos calcular el hierro',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Para la edad de tu wawa no hay una cantidad de hierro '
                  'publicada por el Ministerio de Salud. Conversa con la posta '
                  'sobre su alimentación.',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
