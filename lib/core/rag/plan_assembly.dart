/// The two rules every [PlanParser] obeys, in one place.
///
/// OWNER: P2 (@jhosepmyr).
///
/// `GenerateWeeklyPlan` asks a parser for exactly seven days whose recipes all
/// come from the retrieved candidates. Two parsers now answer that contract —
/// [SimplePlanParser] over Gemma's numbered list and [QonpaniaPlanParser] over
/// the hosted agent's JSON — and the rules are identical for both, so they live
/// here rather than being reimplemented per transport. A grounding rule that
/// exists twice is a grounding rule that drifts.
library;

import '../domain/recipe.dart';
import '../domain/weekly_plan.dart';

/// Lowercases, strips accents and collapses whitespace, so a model that drops
/// the accent on "Puré" still matches the corpus entry.
String normaliseForMatching(String value) {
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

/// The candidate whose name best matches [line]: exact first, then containment
/// either way.
///
/// Containment covers the realistic failure mode where the model appends or
/// trims a few words ("Puré de papa con hígado de pollo para el almuerzo"). It
/// never falls back to "closest available recipe": no match returns null, which
/// is the behaviour that keeps invented dishes out (ADR-0005).
Recipe? bestRecipeMatch(String line, List<Recipe> candidates) {
  final needle = normaliseForMatching(line);
  if (needle.isEmpty) return null;

  for (final recipe in candidates) {
    if (normaliseForMatching(recipe.name) == needle) return recipe;
  }

  Recipe? best;
  var bestLength = 0;
  for (final recipe in candidates) {
    final name = normaliseForMatching(recipe.name);
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

/// Turns however many recipes a generation yielded into the seven days the
/// domain requires.
///
/// A short or malformed generation is padded by cycling [candidates] rather
/// than throwing: a caregiver who waited a minute for the model should get a
/// usable week, not an error — and every filler recipe is still a retrieved,
/// age-appropriate INS recipe, so nothing unsafe reaches the screen.
///
/// Throws [StateError] when [candidates] is empty, because then there is
/// nothing safe to pad with.
List<PlanDay> assembleWeek(List<Recipe> matched, List<Recipe> candidates) {
  if (candidates.isEmpty) {
    throw StateError('Cannot assemble a plan without candidate recipes.');
  }

  final week = matched.take(daysInPlan).toList();
  if (week.isEmpty) {
    week.add(candidates.first);
  }
  while (week.length < daysInPlan) {
    week.add(candidates[week.length % candidates.length]);
  }

  return [
    for (var day = 0; day < daysInPlan; day++)
      PlanDay(dayIndex: day, recipe: week[day]),
  ];
}

/// A plan is a week. Both parsers, the fake service and the prompts agree on it.
const int daysInPlan = 7;
