/// SimplePlanParser: seven days, and never a dish the model invented.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wawafuerte/core/domain/recipe.dart';
import 'package:wawafuerte/core/rag/fake_recipe_retriever.dart';
import 'package:wawafuerte/core/rag/simple_plan_parser.dart';

void main() {
  const parser = SimplePlanParser();
  final candidates = FakeRecipeRetriever.sampleRecipes.take(3).toList();

  test('parses a well-formed numbered list', () {
    final output = candidates
        .map((r) => r.name)
        .toList()
        .asMap()
        .entries
        .map((e) => '${e.key + 1}. ${e.value}')
        .join('\n');

    final days = parser.parse(output, candidates);

    expect(days, hasLength(7));
    expect(days.first.recipe.name, candidates.first.name);
    // dayIndex is 0 = Monday, matching the domain.
    expect(days.map((d) => d.dayIndex), [0, 1, 2, 3, 4, 5, 6]);
  });

  test('always returns exactly seven days, even from a short generation', () {
    final days = parser.parse('1. ${candidates.first.name}', candidates);
    expect(days, hasLength(7));
  });

  test('tolerates missing accents and extra list decoration', () {
    // "Pure de papa con higado de pollo", unaccented, with a "Día 2:" marker.
    final days = parser.parse(
      'Día 1: Segundo de sangrecita con arroz y verduras\n'
      '- Pure de papa con higado de pollo',
      candidates,
    );

    expect(days[0].recipe.name, 'Segundo de sangrecita con arroz y verduras');
    expect(days[1].recipe.name, 'Puré de papa con hígado de pollo');
  });

  // ADR-0005: the model sequences a week out of retrieved recipes. It does not
  // get to add dishes, because an invented dish carries invented nutrition.
  test('discards recipes that were never offered to the model', () {
    final days = parser.parse(
      '1. Ceviche de pota con leche de tigre\n'
      '2. ${candidates.first.name}',
      candidates,
    );

    for (final day in days) {
      expect(
        candidates.map((c) => c.id),
        contains(day.recipe.id),
        reason: 'every day must come from the retrieved candidates',
      );
    }
    expect(
      days.map((d) => d.recipe.name),
      isNot(contains('Ceviche de pota con leche de tigre')),
    );
  });

  test('throws rather than guessing when there are no candidates', () {
    expect(
      () => parser.parse('1. Lo que sea', const <Recipe>[]),
      throwsStateError,
    );
  });
}
