/// The grounded prompt, shared by every transport that can generate a plan.
///
/// OWNER: P1 (@sharvel-irigoyen) with P2.
///
/// Prompt wording is load-bearing (ADR-0005): it is the only thing standing
/// between "the model sequences the INS corpus" and "the model invents dishes
/// with invented nutrition". Two services now send a plan request — on-device
/// Gemma and the hosted agent (ADR-0015) — and the grounding must be *the same
/// text* in both, or the remote path quietly loses a guarantee the local path
/// has. Only the requested response format differs, so that is the only thing
/// callers pass in.
library;

import '../domain/child_profile.dart';
import 'inference_service.dart';

/// Builds the plan request: child context, hemoglobin branch, pantry, budget,
/// the retrieved INS recipes, and the rule that forbids anything else.
///
/// [responseFormat] is appended verbatim and is the caller's business — it must
/// describe exactly what that caller's parser can read back.
String buildGroundedPlanPrompt(
  PlanPrompt prompt, {
  required String responseFormat,
}) {
  final buffer = StringBuffer()
    ..writeln(
      'Eres un asistente nutricional del Instituto Nacional de Salud del Perú.',
    )
    ..writeln(
      'Arma un menú de 7 días para un niño de ${prompt.ageMonths} meses.',
    )
    ..writeln();

  // ADR-0007: hemoglobin is optional. Without a reading we ask for a standard
  // preventive plan; we never invent a value to fill the gap.
  if (prompt.isPersonalised) {
    buffer
      ..writeln(
        'El niño tiene un nivel de hemoglobina de ${prompt.hemoglobin} g/dL, '
        'por debajo de lo esperado para su edad.',
      )
      ..writeln('Prioriza las recetas con mayor cantidad de hierro.');
  } else {
    buffer.writeln(
      'No hay dato de hemoglobina. Arma un plan preventivo estándar '
      'apropiado para su edad.',
    );
  }

  buffer
    ..writeln()
    ..writeln('Ingredientes disponibles en casa:')
    ..writeln(prompt.availableIngredients.join(', '))
    ..writeln()
    ..writeln(
      'Presupuesto semanal: S/ ${prompt.weeklyBudgetPen.toStringAsFixed(2)}',
    )
    ..writeln()
    ..writeln('RECETAS OFICIALES DISPONIBLES:');

  for (final recipe in prompt.candidateRecipes) {
    buffer.writeln(
      '- ${recipe.name} (${recipe.ironMg.toStringAsFixed(1)} mg de hierro)',
    );
  }

  // ADR-0005: the model sequences the INS corpus, it does not invent dishes.
  buffer
    ..writeln()
    ..writeln(
      'REGLA: usa ÚNICAMENTE las recetas de la lista anterior. '
      'No inventes platos nuevos ni modifiques sus nombres.',
    )
    ..writeln(responseFormat);

  return buffer.toString();
}

/// Kept next to the builder rather than on a service, so the prompt can be
/// unit-tested and so the region reaches the prompt when we start using it.
extension PlanPromptRegion on PlanPrompt {
  String get regionLabel => switch (region) {
    Region.coast => 'costa',
    Region.highlands => 'sierra',
    Region.jungle => 'selva',
  };
}
