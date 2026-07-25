/// The one place where all four modules meet.
///
/// Pure Dart: no Flutter, no device, no network. It can therefore be tested
/// with `flutter test` on any machine — which matters because the macOS
/// developer cannot validate real Gemma inference at all (ADR-0003).
library;

import '../inference/inference_service.dart';
import '../nutrition/iron_calculator.dart';
import '../rag/recipe_retriever.dart';
import '../storage/repositories.dart';
import 'child_profile.dart';
import 'recipe.dart';
import 'weekly_plan.dart';

/// Turns "here is what I have and what I can spend" into a saved [WeeklyPlan].
class GenerateWeeklyPlan {
  const GenerateWeeklyPlan({
    required this.retriever,
    required this.inference,
    required this.calculator,
    required this.plans,
    required this.parser,
  });

  final RecipeRetriever retriever; // P2
  final InferenceService inference; // P1
  final IronCalculator calculator; // P2
  final PlanRepository plans; // P4
  final PlanParser parser; // P2

  Future<WeeklyPlan> call({
    required ChildProfile child,
    required List<String> availableIngredients,
    required double weeklyBudgetPen,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final ageMonths = child.ageMonthsAt(today);

    // 1. Ground the request in the INS corpus before the model sees anything.
    final candidates = await retriever.retrieve(
      availableIngredients: availableIngredients,
      weeklyBudgetPen: weeklyBudgetPen,
      ageMonths: ageMonths,
      region: child.region,
    );

    // 2. Let the model sequence a week out of those recipes only.
    final text = await inference.generatePlanText(
      PlanPrompt(
        candidateRecipes: candidates,
        ageMonths: ageMonths,
        region: child.region,
        availableIngredients: availableIngredients,
        weeklyBudgetPen: weeklyBudgetPen,
        hemoglobin: child.hemoglobin, // null is a supported case (ADR-0007)
      ),
    );

    final days = parser.parse(text, candidates);

    // 3. Coverage is arithmetic over real recipe data, not model output.
    final coverage = calculator.coverageOf(
      recipes: days.map((d) => d.recipe).toList(),
      ageMonths: ageMonths,
      sex: child.sex,
    );

    final plan = WeeklyPlan(
      childId: child.id,
      weekStart: _mondayOf(today),
      days: days,
      coverage: coverage,
    );

    await plans.save(plan);
    return plan;
  }

  static DateTime _mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
}

/// Maps raw model text onto the recipes that were actually offered to it.
///
/// Kept separate so a malformed generation fails in one known place instead of
/// halfway through the use case.
abstract interface class PlanParser {
  /// Must return exactly seven days, and every [PlanDay.recipe] must come from
  /// [candidates] — never a recipe the model invented.
  List<PlanDay> parse(String modelOutput, List<Recipe> candidates);
}
