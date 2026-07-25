import 'package:flutter_test/flutter_test.dart';
import 'package:wawafuerte/core/domain/recipe.dart';
import 'package:wawafuerte/core/inference/inference_service.dart';
import 'package:wawafuerte/core/nutrition/plan_verification_agent.dart';
import 'package:wawafuerte/core/nutrition/table_iron_calculator.dart';

class _ScriptedInference implements InferenceService {
  _ScriptedInference(this.scriptedResponse);

  final String scriptedResponse;

  @override
  bool get isReady => true;

  @override
  ActiveInferenceMode get activeMode => ActiveInferenceMode.demo;

  @override
  Future<void> warmUp() async {}

  @override
  Future<String> generatePlanText(PlanPrompt prompt) =>
      throw UnimplementedError();

  @override
  Future<String> generateText(String prompt) async => scriptedResponse;

  @override
  Future<void> dispose() async {}
}

void main() {
  const recipes = <Recipe>[
    Recipe(
      id: 1,
      name: 'Puré de bazo con camote',
      ingredients: ['bazo', 'camote'],
      preparation: 'Sancochar y mezclar.',
      ironMg: 11.6,
      minAgeMonths: 6,
      referenceCostPen: 1.3,
    ),
  ];

  group('the model chooses the tool, the app always computes the number', () {
    test(
      'checkIronCoverage: the real calculator produces the coverage',
      () async {
        final agent = PlanVerificationAgent(
          inference: _ScriptedInference('{"function": "checkIronCoverage"}'),
          calculator: const TableIronCalculator(),
        );

        final result = await agent.verify(
          recipes: recipes,
          ageMonths: 18,
          weeklyBudgetPen: 40,
        );

        expect(result.tool, PlanTool.checkIronCoverage);
        // 11.6 mg from one recipe vs. a real published weekly requirement —
        // sourced from TableIronCalculator, not asserted by this test.
        final expected = const TableIronCalculator().coverageOf(
          recipes: recipes,
          ageMonths: 18,
        );
        expect(result.coverage.providedMg, expected.providedMg);
        expect(result.coverage.requiredMg, expected.requiredMg);
      },
    );

    test(
      'checkBudget: total cost is computed from real recipe prices',
      () async {
        final agent = PlanVerificationAgent(
          inference: _ScriptedInference('{"function": "checkBudget"}'),
          calculator: const TableIronCalculator(),
        );

        final result = await agent.verify(
          recipes: recipes,
          ageMonths: 18,
          weeklyBudgetPen: 40,
        );

        expect(result.tool, PlanTool.checkBudget);
        expect(result.budgetSummary, contains('dentro del presupuesto'));
        // Coverage is still computed regardless of which tool was chosen — the
        // UI needs it either way.
        expect(result.coverage.providedMg, greaterThan(0));
      },
    );

    test('checkBudget over budget is reported as such, not hidden', () async {
      final agent = PlanVerificationAgent(
        inference: _ScriptedInference('{"function": "checkBudget"}'),
        calculator: const TableIronCalculator(),
      );

      final result = await agent.verify(
        recipes: recipes,
        ageMonths: 18,
        weeklyBudgetPen: 1,
      );

      expect(result.budgetSummary, contains('por encima del presupuesto'));
    });
  });

  group(
    'robustness (the coverage bar must never depend on the model behaving)',
    () {
      test(
        'malformed tool-choice response falls back to iron coverage',
        () async {
          final agent = PlanVerificationAgent(
            inference: _ScriptedInference('lo siento, no entiendo'),
            calculator: const TableIronCalculator(),
          );

          final result = await agent.verify(
            recipes: recipes,
            ageMonths: 18,
            weeklyBudgetPen: 40,
          );

          expect(result.tool, PlanTool.checkIronCoverage);
          expect(result.coverage.providedMg, greaterThan(0));
        },
      );

      test('an unknown function name falls back to iron coverage', () async {
        final agent = PlanVerificationAgent(
          inference: _ScriptedInference('{"function": "deleteEverything"}'),
          calculator: const TableIronCalculator(),
        );

        final result = await agent.verify(
          recipes: recipes,
          ageMonths: 18,
          weeklyBudgetPen: 40,
        );

        expect(result.tool, PlanTool.checkIronCoverage);
      });
    },
  );

  test(
    'coverage still respects the hasOfficialRequirement guard (ADR-0012)',
    () async {
      final agent = PlanVerificationAgent(
        inference: _ScriptedInference('{"function": "checkIronCoverage"}'),
        calculator: const TableIronCalculator(),
      );

      // 3 months has no published requirement (ADR-0012) — the agent must not
      // paper over that by fabricating a denominator.
      final result = await agent.verify(
        recipes: recipes,
        ageMonths: 3,
        weeklyBudgetPen: 40,
      );

      expect(
        const TableIronCalculator().hasOfficialRequirement(3),
        isFalse,
        reason: 'This test assumes 3 months is outside the published table',
      );
      expect(result.coverage.requiredMg, 0);
    },
  );
}
