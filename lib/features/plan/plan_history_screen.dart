/// Plan History screen: lists past weekly plans for a child (Flow D / Histórico).
///
/// OWNER: P3 (UI).
library;

import "package:flutter/material.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:provider/provider.dart";

import "../../app/route_arguments.dart";
import "../../app/routes.dart";
import "../../core/domain/weekly_plan.dart";
import "../../core/theme/app_colors.dart";
import "../../core/theme/app_spacing.dart";
import "../../core/widgets/andean_band.dart";
import "../../core/widgets/empty_state.dart";
import "../../core/widgets/spanish_date.dart";
import "plan_history_controller.dart";

class PlanHistoryScreen extends StatelessWidget {
  const PlanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlanHistoryController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Historial de ${controller.child.name}"),
      ),
      body: SafeArea(
        child: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : controller.isEmpty
                ? EmptyState(
                    icon: LucideIcons.history600,
                    title: "Aún no hay historial de menús",
                    message:
                        "Aquí se guardarán los menús semanales pasados de "
                        "${controller.child.name} conforme los vayas generando.",
                  )
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    children: [
                      Text(
                        "Menús anteriores",
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const AndeanBand(),
                      const SizedBox(height: AppSpacing.lg),
                      for (final plan in controller.history)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _HistoryWeekCard(
                            plan: plan,
                            onTap: () => Navigator.of(context).pushNamed(
                              Routes.planHistoryDetail,
                              arguments: PlanHistoryDetailArguments(
                                plan: plan,
                                child: controller.child,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _HistoryWeekCard extends StatelessWidget {
  const _HistoryWeekCard({
    required this.plan,
    required this.onTap,
  });

  final WeeklyPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: AppColors.outline,
          width: AppSpacing.borderWidth,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Semana del ${spanishDate(plan.weekStart)}",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const ExcludeSemantics(
                      child: Icon(
                        LucideIcons.chevronRight600,
                        size: AppSpacing.actionIconSize,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const ExcludeSemantics(
                      child: Icon(
                        LucideIcons.shieldCheck600,
                        size: AppSpacing.iconSize,
                        color: AppColors.earth,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        "${plan.coverage.percent.toStringAsFixed(0)}% de hierro cubierto",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const ExcludeSemantics(
                      child: Icon(
                        LucideIcons.cookingPot600,
                        size: AppSpacing.iconSize,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        "${plan.preparedCount} de 7 comidas preparadas",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
