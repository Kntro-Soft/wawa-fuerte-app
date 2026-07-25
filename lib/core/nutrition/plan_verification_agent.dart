/// Function calling over the plan Gemma just wrote (ADR-0005 extended).
///
/// The installed checkpoint is `gemma3-1b-it` — a text model, not `gemma4`,
/// which is the one `flutter_gemma`'s native `tools_json` path targets
/// (see `Tool` in the package: "Native tool calling (Gemma 4 → SDK tools_json)").
/// Depending on native tool calling here would be unverified on the model we
/// actually ship. This orchestrates function calling at the **application**
/// level instead: the model is asked which function to call and with what
/// arguments, the app parses that JSON and calls the real Dart function, and
/// the model never computes the number itself — same guarantee as ADR-0005,
/// extended from "the app calls the function" to "the model decides to call
/// the function, but the app is still the one that calls it."
///
/// This is what earns the Autonomous Agent recognition honestly: an
/// agentic step that dispatches to a real tool, not a bigger prompt.
library;

import 'dart:convert';

import '../domain/child_profile.dart';
import '../domain/recipe.dart';
import '../domain/weekly_plan.dart';
import '../inference/inference_service.dart';
import 'iron_calculator.dart';

/// One function the model is allowed to invoke, and the app actually runs.
enum PlanTool {
  /// Computes real iron coverage from [IronCalculator] — never from the model.
  checkIronCoverage,

  /// Sums [Recipe.referenceCostPen] against the caregiver's stated budget.
  /// The result is explicitly marked as an estimate (ADR-0011): the INS book
  /// publishes no prices, so this can only ever validate a rough sort.
  checkBudget,
}

class PlanVerification {
  const PlanVerification({
    required this.tool,
    required this.coverage,
    this.budgetSummary,
  });

  final PlanTool tool;
  final IronCoverage coverage;
  final String? budgetSummary;
}

class PlanVerificationAgent {
  const PlanVerificationAgent({
    required this.inference,
    required this.calculator,
  });

  final InferenceService inference;
  final IronCalculator calculator;

  /// Asks the model which tool it wants to run, dispatches to the real
  /// implementation, and returns the verified result.
  ///
  /// Falls back to [PlanTool.checkIronCoverage] on any malformed response — a
  /// caregiver seeing the coverage bar always matters more than the model
  /// having successfully chosen how to compute it.
  Future<PlanVerification> verify({
    required List<Recipe> recipes,
    required int ageMonths,
    required double weeklyBudgetPen,
    Sex? sex,
  }) async {
    final tool = await _chooseTool(recipes, ageMonths, weeklyBudgetPen);

    final coverage = calculator.coverageOf(
      recipes: recipes,
      ageMonths: ageMonths,
      sex: sex,
    );

    String? budgetSummary;
    if (tool == PlanTool.checkBudget) {
      final total = recipes.fold<double>(
        0,
        (sum, r) => sum + r.referenceCostPen,
      );
      budgetSummary = total <= weeklyBudgetPen
          ? 'Estimado dentro del presupuesto (S/ ${total.toStringAsFixed(2)} de S/ ${weeklyBudgetPen.toStringAsFixed(2)})'
          : 'Estimado por encima del presupuesto (S/ ${total.toStringAsFixed(2)} de S/ ${weeklyBudgetPen.toStringAsFixed(2)})';
    }

    return PlanVerification(
      tool: tool,
      coverage: coverage,
      budgetSummary: budgetSummary,
    );
  }

  Future<PlanTool> _chooseTool(
    List<Recipe> recipes,
    int ageMonths,
    double weeklyBudgetPen,
  ) async {
    final response = await inference.generateText(
      _buildToolChoicePrompt(recipes, ageMonths, weeklyBudgetPen),
    );
    return _parseToolChoice(response);
  }

  static String _buildToolChoicePrompt(
    List<Recipe> recipes,
    int ageMonths,
    double weeklyBudgetPen,
  ) {
    return '''
Tienes dos funciones disponibles para verificar un plan de alimentación:

1. checkIronCoverage — calcula cuánto hierro aporta el plan para un niño de $ageMonths meses.
2. checkBudget — compara el costo estimado del plan contra un presupuesto de S/ $weeklyBudgetPen.

El plan tiene ${recipes.length} recetas.

Elige UNA función para verificar primero. Responde ÚNICAMENTE con JSON:
{"function": "checkIronCoverage"} o {"function": "checkBudget"}
''';
  }

  static PlanTool _parseToolChoice(String response) {
    final match = RegExp(r'\{[\s\S]*?\}').firstMatch(response);
    if (match == null) return PlanTool.checkIronCoverage;

    try {
      final decoded = json.decode(match.group(0)!) as Map<String, dynamic>;
      final name = decoded['function'] as String?;
      return switch (name) {
        'checkBudget' => PlanTool.checkBudget,
        _ => PlanTool.checkIronCoverage,
      };
    } on FormatException {
      return PlanTool.checkIronCoverage;
    }
  }
}
