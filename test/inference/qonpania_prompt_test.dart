/// The remote path must not be a weaker path (ADR-0005, ADR-0015).
///
/// The grounding block is shared with Gemma by construction; these tests are
/// what stops someone "simplifying" the remote prompt later and quietly handing
/// a hosted model permission to invent dishes.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wawafuerte/core/domain/child_profile.dart';
import 'package:wawafuerte/core/domain/recipe.dart';
import 'package:wawafuerte/core/inference/gemma_inference_service.dart';
import 'package:wawafuerte/core/inference/inference_service.dart';
import 'package:wawafuerte/core/inference/qonpania_inference_service.dart';

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
  ];

  PlanPrompt promptWith({double? hemoglobin}) => PlanPrompt(
    candidateRecipes: recipes,
    ageMonths: 18,
    region: Region.highlands,
    availableIngredients: const ['papa', 'sangrecita'],
    weeklyBudgetPen: 40,
    hemoglobin: hemoglobin,
  );

  test('the grounding is identical to the on-device prompt', () {
    final remote = QonpaniaInferenceService.buildPrompt(promptWith());
    final local = GemmaInferenceService.buildPrompt(promptWith());

    // Everything up to the response format is the same text, not merely the
    // same intent.
    const rule = 'REGLA: usa ÚNICAMENTE las recetas de la lista anterior.';
    expect(
      remote.substring(0, remote.indexOf(rule)),
      local.substring(0, local.indexOf(rule)),
    );
  });

  test('the candidate recipes and the child context reach the agent', () {
    final text = QonpaniaInferenceService.buildPrompt(promptWith());

    expect(text, contains('Puré de papa con sangrecita'));
    expect(text, contains('18 meses'));
    expect(text, contains('40.00'));
    expect(text, contains('No inventes'));
  });

  test('hemoglobin stays optional (ADR-0007)', () {
    expect(
      QonpaniaInferenceService.buildPrompt(promptWith()),
      contains('plan preventivo estándar'),
    );
    expect(
      QonpaniaInferenceService.buildPrompt(promptWith(hemoglobin: 9.8)),
      allOf(contains('9.8'), contains('Prioriza')),
    );
  });

  test('the requested format is the JSON envelope the parser reads', () {
    final text = QonpaniaInferenceService.buildPrompt(promptWith());

    expect(text, contains('menu_semanal'));
    expect(text, contains('titulo_plato'));
    // The verbatim-title instruction is what makes iron grounding possible.
    expect(text, contains('EXACTO'));
  });
}
