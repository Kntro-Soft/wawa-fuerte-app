/// Detail screen for a historical weekly plan (Flow D / Histórico).
///
/// OWNER: P3 (UI).
library;

import "package:flutter/material.dart";
import "package:flutter_tts/flutter_tts.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";

import "../../app/route_arguments.dart";
import "../../core/domain/recipe.dart";
import "../../core/theme/app_colors.dart";
import "../../core/theme/app_spacing.dart";
import "../../core/widgets/andean_band.dart";
import "../../core/widgets/day_names.dart";
import "../../core/widgets/food_glyph.dart";
import "../../core/widgets/iron_coverage_bar.dart";
import "../../core/widgets/listen_button.dart";
import "../../core/widgets/section_heading.dart";
import "../../core/widgets/spanish_date.dart";
import "widgets/recipe_row.dart";

class PlanHistoryDetailScreen extends StatelessWidget {
  const PlanHistoryDetailScreen({required this.arguments, super.key});

  final PlanHistoryDetailArguments arguments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = arguments.plan;
    final child = arguments.child;
    final ageMonths = child.ageMonthsAt(plan.weekStart);

    return Scaffold(
      appBar: AppBar(title: Text("Semana del ${spanishDate(plan.weekStart)}")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Text("Menú de ${child.name}", style: theme.textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "Semana del ${spanishDate(plan.weekStart)}",
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const AndeanBand(),
            const SizedBox(height: AppSpacing.xl),
            IronCoverageBar(coverage: plan.coverage, ageMonths: ageMonths),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  const ExcludeSemantics(
                    child: Icon(
                      LucideIcons.circleCheck600,
                      color: AppColors.success,
                      size: AppSpacing.iconSize,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      "Se prepararon ${plan.preparedCount} de 7 comidas en esta semana",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeading(
              icon: LucideIcons.calendarDays600,
              title: "Las comidas de la semana",
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final day in plan.days) ...[
              RecipeRow(
                day: day,
                onTap: () =>
                    _showRecipeModal(context, day.recipe, day.dayIndex),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }

  void _showRecipeModal(BuildContext context, Recipe recipe, int dayIndex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          _HistoricalRecipeModal(recipe: recipe, dayIndex: dayIndex),
    );
  }
}

class _HistoricalRecipeModal extends StatefulWidget {
  const _HistoricalRecipeModal({required this.recipe, required this.dayIndex});

  final Recipe recipe;
  final int dayIndex;

  @override
  State<_HistoricalRecipeModal> createState() => _HistoricalRecipeModalState();
}

class _HistoricalRecipeModalState extends State<_HistoricalRecipeModal> {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _configureTts();
  }

  Future<void> _configureTts() async {
    try {
      await _tts.setLanguage("es-PE");
      await _tts.setSpeechRate(0.42);
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleSpeech() async {
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }

    setState(() => _speaking = true);
    try {
      await _tts.speak(widget.recipe.preparation);
    } catch (_) {
      if (mounted) setState(() => _speaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = widget.recipe;
    final steps = recipe.preparation
        .split(RegExp(r"(?<=\.)\s+"))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: ListView(
        children: [
          Row(
            children: [
              Text(
                DayNames.of(widget.dayIndex),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.x600),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(recipe.name, style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.lg),
          ListenButton(isSpeaking: _speaking, onPressed: _toggleSpeech),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeading(
            icon: LucideIcons.shoppingBasket600,
            title: "Qué necesitas",
          ),
          const SizedBox(height: AppSpacing.md),
          for (final ingredient in recipe.ingredients) ...[
            Row(
              children: [
                FoodGlyph(ingredient: ingredient),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    ingredient.isEmpty
                        ? ingredient
                        : ingredient[0].toUpperCase() + ingredient.substring(1),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.xl),
          const SectionHeading(
            icon: LucideIcons.cookingPot600,
            title: "Cómo se prepara",
          ),
          const SizedBox(height: AppSpacing.md),
          for (final (index, step) in steps.indexed) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Text(
                    "${index + 1}",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(step, style: theme.textTheme.bodyLarge)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
