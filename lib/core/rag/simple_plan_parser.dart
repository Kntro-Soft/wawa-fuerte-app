/// Parses the model's numbered list into seven [PlanDay]s.
///
/// OWNER: P2 (@jhosepmyr).
///
/// The contract from `GenerateWeeklyPlan` is strict and deliberately so: exactly
/// seven days, and **every recipe must come from `candidates`**. The model is
/// allowed to sequence a week; it is not allowed to invent a dish. Matching by
/// name against the candidate list is what enforces that (ADR-0005) — a line the
/// model hallucinated simply finds no match and is dropped.
///
/// Matching and the seven-day rule live in `plan_assembly.dart`, shared with
/// `QonpaniaPlanParser`. What belongs to *this* parser is only the shape of the
/// text it reads, as produced by `FakeInferenceService` and asked of Gemma:
///
/// ```
/// 1. Segundo de sangrecita con arroz y verduras
/// 2. Puré de papa con hígado de pollo
/// ...
/// ```
library;

import '../domain/generate_weekly_plan.dart';
import '../domain/recipe.dart';
import '../domain/weekly_plan.dart';
import 'plan_assembly.dart';

class SimplePlanParser implements PlanParser {
  const SimplePlanParser();

  /// Leading "1.", "1)", "Día 1:", "- " and similar list decoration.
  static final RegExp _leadingMarker = RegExp(
    r'^\s*(?:d[ií]a\s*)?\d+\s*[\.\)\:\-]\s*|^\s*[-*•]\s*',
    caseSensitive: false,
  );

  @override
  List<PlanDay> parse(String modelOutput, List<Recipe> candidates) {
    if (candidates.isEmpty) {
      throw StateError('Cannot parse a plan without candidate recipes.');
    }

    final matched = <Recipe>[];
    for (final rawLine in modelOutput.split('\n')) {
      final line = rawLine.replaceFirst(_leadingMarker, '').trim();
      if (line.isEmpty) continue;

      final recipe = bestRecipeMatch(line, candidates);
      if (recipe != null) matched.add(recipe);
      if (matched.length == daysInPlan) break;
    }

    return assembleWeek(matched, candidates);
  }
}
