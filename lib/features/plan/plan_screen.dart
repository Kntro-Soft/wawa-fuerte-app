/// The plan route: form → generating → result, on one screen (Flow B + D).
///
/// OWNER: P3 (UI).
///
/// These were three destinations in the prototype and are one here, because they
/// are one task: *get this week's menu*. Pushing a route for the loading state
/// and another for the result puts a back button between a caregiver and the
/// plan she just waited a minute for, and makes "back" mean "regenerate".
/// Switching on [PlanStatus] inside a single route keeps the mental model at
/// one screen that changes.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/route_arguments.dart';
import '../../app/routes.dart';
import '../../app/providers.dart';
import '../../core/inference/inference_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/andean_band.dart';
import '../../core/widgets/food_chip.dart';
import '../../core/widgets/iron_coverage_bar.dart';
import '../../core/widgets/notice_banner.dart';
import '../../core/widgets/section_heading.dart';
import 'pantry_options.dart';
import 'plan_controller.dart';
import 'widgets/plan_generating_view.dart';
import 'widgets/recipe_row.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlanController>();
    final generating = controller.status == PlanStatus.generating;

    return PopScope(
      // While the model is running there is nothing to go back to and no way to
      // cancel it cleanly, so the gesture is simply inert.
      canPop: !generating,
      child: Scaffold(
        appBar: AppBar(
          title: Text(controller.child.name),
          // No back arrow mid-generation, matching PopScope.
          automaticallyImplyLeading: !generating,
          actions: [
            if (!generating) const _InferenceStatusChip(),
          ],
        ),
        body: SafeArea(
          child: switch (controller.status) {
            PlanStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            PlanStatus.editing => const _PlanForm(),
            PlanStatus.generating => PlanGeneratingView(
              childName: controller.child.name,
            ),
            PlanStatus.ready => const _PlanResult(),
            PlanStatus.failed => const _PlanFailed(),
          },
        ),
        bottomNavigationBar: switch (controller.status) {
          // Anchored CTA on the form only. The generating state must offer no
          // button at all, and the result screen's actions live in its list.
          PlanStatus.editing => SafeArea(
            minimum: const EdgeInsets.all(AppSpacing.screenPadding),
            child: FilledButton(
              onPressed: controller.canGenerate ? controller.generate : null,
              // Not "Generar receta": this produces seven days, not one recipe.
              child: const Text('Crear el menú de la semana'),
            ),
          ),
          _ => null,
        },
      ),
    );
  }
}

// --- Form -------------------------------------------------------------------

class _PlanForm extends StatefulWidget {
  const _PlanForm();

  @override
  State<_PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends State<_PlanForm> {
  /// Owned by the widget, not rebuilt per frame: tapping a shortcut has to push
  /// its value *into* the field, so the field needs an identity that survives
  /// the rebuild the tap causes.
  final TextEditingController _budgetField = TextEditingController();

  @override
  void dispose() {
    _budgetField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlanController>();
    final theme = Theme.of(context);
    final pantry = PantryOptions.forRegion(controller.child.region);

    // Mirror controller → field only when they actually differ, so typing is
    // never interrupted and a shortcut tap is reflected immediately.
    if (_budgetField.text != controller.budgetText) {
      _budgetField.value = TextEditingValue(
        text: controller.budgetText,
        selection: TextSelection.collapsed(
          offset: controller.budgetText.length,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // ADR-0007: no reading is not an error and is never styled as one.
        if (controller.isPreventivePlan) ...[
          const NoticeBanner(
            title: 'Menú preventivo',
            message:
                'Armaremos un menú según la edad de tu wawa. Si más adelante '
                'tienes su carné a la mano, podemos afinarlo mejor.',
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        const SectionHeading(
          icon: LucideIcons.shoppingBasket600,
          title: '¿Qué tienes en casa?',
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Toca lo que tienes. El menú usará recetas que incluyan esos ingredientes.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Ingredients are words on chips, not icons: papa, sangrecita, quinua
        // and tarwi have no glyph in any icon set. See FoodChip.
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final ingredient in pantry)
              FoodChip(
                ingredient: ingredient,
                label: PantryOptions.label(ingredient),
                selected: controller.selectedIngredients.contains(ingredient),
                onTap: () => controller.toggleIngredient(ingredient),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        TextField(
          onChanged: controller.setOtherIngredients,
          style: theme.textTheme.bodyLarge,
          decoration: const InputDecoration(
            hintText: '¿Tienes algo más? Escríbelo aquí',
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        const SectionHeading(
          icon: LucideIcons.wallet600,
          title: '¿Cuánto puedes gastar esta semana?',
        ),
        const SizedBox(height: AppSpacing.lg),

        // Three taps instead of a typed number. Writing on a phone keyboard
        // while cooking is expensive; tapping is close to free.
        Row(
          children: [
            for (final soles in PlanController.budgetShortcuts) ...[
              Expanded(
                child: _BudgetShortcut(
                  soles: soles,
                  selected: controller.budgetText == '$soles',
                  onTap: () => controller.selectBudgetShortcut(soles),
                ),
              ),
              if (soles != PlanController.budgetShortcuts.last)
                const SizedBox(width: AppSpacing.md),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        TextField(
          // Empty by default, like every other numeric field in this app.
          controller: _budgetField,
          onChanged: controller.setBudgetText,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          style: theme.textTheme.titleLarge,
          decoration: InputDecoration(
            // The currency lives in the field, so the number she types is just
            // a number and the unit is never in doubt.
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.sm,
              ),
              child: Text('S/', style: theme.textTheme.titleLarge),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            hintText: 'O escribe otro monto',
          ),
        ),
      ],
    );
  }
}

class _BudgetShortcut extends StatelessWidget {
  const _BudgetShortcut({
    required this.soles,
    required this.selected,
    required this.onTap,
  });

  final int soles;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primaryContainer : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.outline,
                width: selected
                    ? AppSpacing.selectedBorderWidth
                    : AppSpacing.borderWidth,
              ),
            ),
            child: Text(
              'S/$soles',
              style: theme.textTheme.titleLarge?.copyWith(
                color: selected
                    ? AppColors.onPrimaryContainer
                    : AppColors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Result -----------------------------------------------------------------

class _PlanResult extends StatelessWidget {
  const _PlanResult();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlanController>();
    final plan = controller.plan;
    final theme = Theme.of(context);

    if (plan == null) return const SizedBox.shrink();

    final ageMonths = controller.child.ageMonthsAt(DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Text(
          'El menú de ${controller.child.name}',
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        const AndeanBand(),
        const SizedBox(height: AppSpacing.xl),

        // The loudest thing on the screen, and deliberately above the recipes:
        // it is the answer, they are the working. Guards
        // `hasOfficialRequirement` internally — see IronCoverageBar.
        IronCoverageBar(coverage: plan.coverage, ageMonths: ageMonths),
        const SizedBox(height: AppSpacing.lg),

        if (controller.isPreventivePlan) ...[
          const NoticeBanner(
            title: 'Menú preventivo estándar',
            message:
                'Este menú está armado según la edad de tu wawa. Agrega el '
                'dato de su carné cuando lo tengas y podremos afinarlo.',
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        const SectionHeading(
          icon: LucideIcons.calendarDays600,
          title: 'Las comidas de la semana',
        ),
        const SizedBox(height: AppSpacing.lg),

        // Seven big rows, each opening a recipe with its listen button.
        for (final day in plan.days) ...[
          RecipeRow(
            day: day,
            onTap: () => Navigator.of(context).pushNamed(
              Routes.recipe,
              arguments: RecipeArguments(
                controller: controller,
                dayIndex: day.dayIndex,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        const SizedBox(height: AppSpacing.lg),

        // "Volver al inicio" is a secondary link, not the loudest button on the
        // screen. In the prototype it was a full-width filled button below the
        // list, which made leaving look like the intended next step.
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(
              context,
            ).popUntil(ModalRoute.withName(Routes.home)),
            child: const Text('Volver al inicio'),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Secondary action: generate a fresh plan for this week. Placed below
        // "Volver al inicio" so it is reachable but not the obvious next tap.
        Center(
          child: TextButton(
            onPressed: context.read<PlanController>().regenerate,
            child: Text(
              'Generar nuevo menú esta semana',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        Center(
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(
              Routes.planHistory,
              arguments: PlanHistoryArguments(child: controller.child),
            ),
            icon: const Icon(
              LucideIcons.history600,
              size: AppSpacing.iconSize,
            ),
            label: const Text('Ver historial de menús pasados'),
          ),
        ),
      ],
    );
  }
}

// --- Failure ----------------------------------------------------------------

class _PlanFailed extends StatelessWidget {
  const _PlanFailed();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlanController>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        NoticeBanner(
          tone: NoticeTone.problem,
          title: 'No se pudo armar el menú',
          message:
              controller.errorMessage ??
              'Algo salió mal. Vuelve a intentarlo en un momento.',
          // Retry exists here and nowhere else: never during generation.
          action: FilledButton.icon(
            onPressed: controller.retry,
            icon: const Icon(
              LucideIcons.rotateCcw600,
              size: AppSpacing.actionIconSize,
            ),
            label: const Text('Volver a intentar'),
          ),
        ),
      ],
    );
  }
}

// --- Inference status chip --------------------------------------------------

class _InferenceStatusChip extends StatelessWidget {
  const _InferenceStatusChip();

  @override
  Widget build(BuildContext context) {
    final isRealModel = gemmaModelPath.isNotEmpty;
    final isReady = context.watch<InferenceService>().isReady;
    
    final (label, color) = isRealModel
        ? isReady
            ? ('Gemma', AppColors.success)
            : ('Cargando...', AppColors.warning)  
        : ('Demo', AppColors.warning);
    
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
        backgroundColor: color,
        side: BorderSide.none,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
