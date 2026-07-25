/// One day's recipe: ingredients, steps, listen, and "Ya lo preparé".
///
/// OWNER: P3 (UI).
///
/// ## What the listen button reads
///
/// **The preparation steps — not the title.** The prototype spoke the dish name,
/// which is the one thing already legible on screen in 20 sp and the one thing
/// a caregiver does not need read to her. The steps are what she cannot hold in
/// her head with her hands in a pot, so those are what the button plays.
///
/// ## Why the "Ya lo preparé" control is here
///
/// It is a full-width, 56 dp-plus control with a word on it, on the screen the
/// caregiver is already looking at when she finishes cooking. In the prototype
/// it was an unlabelled grey circle inside each row of the week list — small,
/// nameless, and a second touch target inside a target that already did
/// something else. Ticking it turns the control green **and** swaps in a check
/// **and** changes the words, because red and green are near-identical in
/// luminance and colour alone would carry no information (see `SelectableCard`).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/route_arguments.dart';
import '../../core/domain/recipe.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/day_names.dart';
import '../../core/widgets/food_glyph.dart';
import '../../core/widgets/listen_button.dart';
import '../../core/widgets/section_heading.dart';
import '../plan/plan_controller.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({required this.arguments, super.key});

  final RecipeArguments arguments;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  PlanController get _controller => widget.arguments.controller;

  @override
  void initState() {
    super.initState();
    _configureTts();
  }

  Future<void> _configureTts() async {
    try {
      // Peruvian Spanish where the device has it. If the voice is missing the
      // call throws and the platform falls back to its default locale — the
      // button must still work, so the failure is swallowed.
      await _tts.setLanguage('es-PE');
      // Slower than default: these are instructions being followed in real
      // time, not prose being skimmed.
      await _tts.setSpeechRate(0.42);
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
    } catch (_) {
      // TTS unavailable on this device or platform. Nothing to tell the user
      // until she presses the button.
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleSpeech(Recipe recipe) async {
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }

    setState(() => _speaking = true);
    try {
      // The steps. Never the title.
      await _tts.speak(recipe.preparation);
    } catch (_) {
      if (mounted) setState(() => _speaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final plan = _controller.plan;
        if (plan == null) return const Scaffold(body: SizedBox.shrink());

        final day = plan.days.firstWhere(
          (d) => d.dayIndex == widget.arguments.dayIndex,
          orElse: () => plan.days.first,
        );
        final recipe = day.recipe;

        return Scaffold(
          appBar: AppBar(title: Text(DayNames.of(day.dayIndex))),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                // Full name, no truncation, no ellipsis.
                Text(recipe.name, style: theme.textTheme.headlineLarge),
                const SizedBox(height: AppSpacing.xl),

                // The listen button sits above the steps, not buried under
                // them: the user who needs it most is the one least likely to
                // read to the bottom to find it.
                ListenButton(
                  isSpeaking: _speaking,
                  onPressed: () => _toggleSpeech(recipe),
                ),
                const SizedBox(height: AppSpacing.xxl),

                const SectionHeading(
                  icon: LucideIcons.shoppingBasket600,
                  title: 'Qué necesitas',
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final ingredient in recipe.ingredients) ...[
                  _IngredientLine(ingredient: ingredient),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.xl),

                const SectionHeading(
                  icon: LucideIcons.cookingPot600,
                  title: 'Cómo se prepara',
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final (index, step) in _steps(recipe).indexed) ...[
                  _StepLine(number: index + 1, text: step),
                  const SizedBox(height: AppSpacing.lg),
                ],
                const SizedBox(height: AppSpacing.xl),

                _PreparedToggle(
                  prepared: day.prepared,
                  onChanged: (value) => _controller.setPrepared(
                    dayIndex: day.dayIndex,
                    prepared: value,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Splits the preparation blob into sentences so each step gets its own line
  /// and its own number. The corpus stores steps as one paragraph; a wall of
  /// text is unusable while cooking.
  static List<String> _steps(Recipe recipe) {
    return recipe.preparation
        .split(RegExp(r'(?<=\.)\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

class _IngredientLine extends StatelessWidget {
  const _IngredientLine({required this.ingredient});

  final String ingredient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Was a green check, which is the app's "done" mark and meant nothing
        // here — an ingredient list is not a list of things achieved. The
        // silhouette says *which food* instead, in the food's own colour.
        FoodGlyph(ingredient: ingredient),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            // Corpus form is lowercase; capitalise for reading only.
            ingredient.isEmpty
                ? ingredient
                : ingredient[0].toUpperCase() + ingredient.substring(1),
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A numbered marker, not a bullet: while cooking, "I was on 4" is a
        // place you can come back to and a dot is not.
        Container(
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Text(
            '$number',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
      ],
    );
  }
}

class _PreparedToggle extends StatelessWidget {
  const _PreparedToggle({required this.prepared, required this.onChanged});

  final bool prepared;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      checked: prepared,
      child: Material(
        color: prepared ? AppColors.successContainer : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(!prepared);
          },
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSpacing.ctaHeight),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(
                color: prepared ? AppColors.success : AppColors.outline,
                width: prepared
                    ? AppSpacing.selectedBorderWidth
                    : AppSpacing.borderWidth,
              ),
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    prepared
                        ? LucideIcons.squareCheck600
                        : LucideIcons.square600,
                    size: AppSpacing.actionIconSize,
                    color: prepared ? AppColors.success : AppColors.outline,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    // One label in both states. It names the control, and the
                    // box + fill + border say whether it is ticked — a label
                    // that changes wording would make the same control look
                    // like two different ones.
                    'Ya lo preparé',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: prepared
                          ? AppColors.onSuccessContainer
                          : AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
