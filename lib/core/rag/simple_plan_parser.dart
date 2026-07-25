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
/// Expected shape, as produced by `FakeInferenceService` and asked of Gemma:
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

      final recipe = _bestMatch(line, candidates);
      if (recipe != null) matched.add(recipe);
      if (matched.length == 7) break;
    }

    // The plan is always seven days. A short or malformed generation is padded
    // by cycling the candidates rather than throwing: a caregiver who waited a
    // minute for the model should get a usable week, not an error — and every
    // filler recipe is still a retrieved, age-appropriate INS recipe, so nothing
    // unsafe reaches the screen.
    if (matched.isEmpty) {
      matched.add(candidates.first);
    }
    while (matched.length < 7) {
      matched.add(candidates[matched.length % candidates.length]);
    }

    return [
      for (var day = 0; day < 7; day++)
        PlanDay(dayIndex: day, recipe: matched[day]),
    ];
  }

  /// Exact name match first, then containment either way.
  ///
  /// Containment covers the realistic failure mode where the model appends or
  /// trims a few words ("Puré de papa con hígado de pollo para el almuerzo").
  /// It never falls back to "closest available recipe": no match means the line
  /// is discarded, which is the behaviour that keeps invented dishes out.
  static Recipe? _bestMatch(String line, List<Recipe> candidates) {
    final needle = _normalise(line);
    if (needle.isEmpty) return null;

    for (final recipe in candidates) {
      if (_normalise(recipe.name) == needle) return recipe;
    }

    Recipe? best;
    var bestLength = 0;
    for (final recipe in candidates) {
      final name = _normalise(recipe.name);
      if (name.isEmpty) continue;
      if (needle.contains(name) || name.contains(needle)) {
        // Prefer the longest match, so "arroz" does not beat a full dish name.
        if (name.length > bestLength) {
          best = recipe;
          bestLength = name.length;
        }
      }
    }
    return best;
  }

  /// Lowercases, strips accents and collapses whitespace, so a model that drops
  /// the accent on "Puré" still matches the corpus entry.
  static String _normalise(String value) {
    const accented = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const plain = 'aaaaaeeeeiiiiooooouuuunc';

    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final index = accented.indexOf(char);
      buffer.write(index >= 0 ? plain[index] : char);
    }

    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
