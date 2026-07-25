import 'package:flutter_test/flutter_test.dart';
import 'package:wawafuerte/core/domain/child_profile.dart';
import 'package:wawafuerte/core/domain/recipe.dart';
import 'package:wawafuerte/core/inference/gemma_inference_service.dart';
import 'package:wawafuerte/core/inference/inference_service.dart';

/// Prompt wording is load-bearing (ADR-0005): it is what keeps the model
/// sequencing the INS corpus instead of inventing dishes. These tests cover it
/// without loading a 557 MB model, so they run in CI and on any machine.
void main() {
  const recipes = <Recipe>[
    Recipe(
      id: 1,
      name: 'Puré de papa con sangrecita',
      ingredients: ['papa', 'sangrecita'],
      preparation: 'Sancochar la papa. Freír la sangrecita.',
      ironMg: 4.2,
      minAgeMonths: 6,
      referenceCostPen: 2.5,
    ),
    Recipe(
      id: 2,
      name: 'Guiso de lentejitas',
      ingredients: ['lentejas', 'zanahoria'],
      preparation: 'Remojar las lentejas.',
      ironMg: 3.1,
      minAgeMonths: 8,
      referenceCostPen: 1.8,
    ),
  ];

  PlanPrompt promptWith({double? hemoglobin}) => PlanPrompt(
    candidateRecipes: recipes,
    ageMonths: 18,
    region: Region.highlands,
    availableIngredients: const ['papa', 'sangrecita', 'lentejas'],
    weeklyBudgetPen: 40,
    hemoglobin: hemoglobin,
  );

  group('grounding in the INS corpus', () {
    test('every candidate recipe reaches the prompt', () {
      final text = GemmaInferenceService.buildPrompt(promptWith());

      for (final recipe in recipes) {
        expect(
          text,
          contains(recipe.name),
          reason: 'The model cannot pick a recipe it never saw',
        );
      }
    });

    test('the prompt forbids inventing dishes', () {
      final text = GemmaInferenceService.buildPrompt(promptWith());

      expect(text, contains('ÚNICAMENTE'));
      expect(text, contains('No inventes'));
    });

    test(
      'the requested output format is the numbered list the parser expects',
      () {
        final text = GemmaInferenceService.buildPrompt(promptWith());

        expect(text, contains('7 líneas numeradas'));
      },
    );
  });

  group('hemoglobin is optional (ADR-0007)', () {
    test('with a reading, the prompt states it and asks for iron density', () {
      final text = GemmaInferenceService.buildPrompt(
        promptWith(hemoglobin: 9.8),
      );

      expect(text, contains('9.8'));
      expect(text, contains('Prioriza'));
    });

    test('without a reading, it asks for a standard preventive plan', () {
      final text = GemmaInferenceService.buildPrompt(promptWith());

      expect(text, contains('plan preventivo estándar'));
    });

    test('without a reading, no hemoglobin figure is invented', () {
      final text = GemmaInferenceService.buildPrompt(promptWith());

      expect(
        text.contains('g/dL'),
        isFalse,
        reason: 'A fabricated reading would put a wrong premise under the plan',
      );
    });
  });

  group('child context', () {
    test('the age in months reaches the prompt', () {
      final text = GemmaInferenceService.buildPrompt(promptWith());

      expect(text, contains('18 meses'));
    });

    test('the available ingredients and the budget reach the prompt', () {
      final text = GemmaInferenceService.buildPrompt(promptWith());

      expect(text, contains('papa'));
      expect(text, contains('40.00'));
    });
  });
}
