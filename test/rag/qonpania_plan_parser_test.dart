/// QonpaniaPlanParser: seven days, and never a fabricated iron figure.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wawafuerte/core/domain/recipe.dart';
import 'package:wawafuerte/core/rag/fake_recipe_retriever.dart';
import 'package:wawafuerte/core/rag/qonpania_plan_parser.dart';

void main() {
  const parser = QonpaniaPlanParser();
  final candidates = FakeRecipeRetriever.sampleRecipes.take(3).toList();

  /// The envelope the agent is prompted for, with one entry per title given.
  String envelope(List<String> titles, {int? firstDay}) => jsonEncode({
    'mensaje_motivacional': '¡Hola María!',
    'meta_hierro_cubierta_porcentaje': 100,
    'menu_semanal': [
      for (var i = 0; i < titles.length; i++)
        {
          'dia': (firstDay ?? 1) + i,
          'titulo_plato': titles[i],
          'ingredientes': [
            {'nombre': 'Papa', 'cantidad': '1 unidad mediana'},
            {'nombre': 'Sangrecita', 'cantidad': '2 cucharadas'},
          ],
          'preparacion': ['Sancocha la papa', 'Sirve tibio y con amor.'],
        },
    ],
  });

  group('grounding in the INS corpus (ADR-0005)', () {
    test('a title copied from the candidates keeps its sourced iron', () {
      final days = parser.parse(envelope([candidates.first.name]), candidates);

      expect(days.first.recipe.id, candidates.first.id);
      expect(days.first.recipe.ironMg, candidates.first.ironMg);
    });

    test('matching survives dropped accents and extra words', () {
      final days = parser.parse(
        envelope(['Pure de papa con higado de pollo para el almuerzo']),
        candidates,
      );

      expect(days.first.recipe.name, 'Puré de papa con hígado de pollo');
    });

    test('an off-corpus dish still reaches the screen, but with zero iron', () {
      final days = parser.parse(
        envelope(['Ceviche de pota con leche de tigre']),
        candidates,
      );

      final invented = days.first.recipe;
      expect(invented.name, 'Ceviche de pota con leche de tigre');
      expect(
        invented.ironMg,
        0,
        reason:
            'its iron is unknown, and a guess would land in the coverage bar',
      );
      expect(
        invented.id,
        isNegative,
        reason: 'it must never be mistaken for an INS recipe id',
      );
    });

    test('the agent’s own coverage claim never becomes iron', () {
      // The payload claims 100% coverage over a week of dishes that are not in
      // the corpus. Nothing in the parsed output carries that claim, so the
      // calculator sums seven zeroes — an honest "we cannot vouch for this"
      // rather than the agent's self-assessment.
      final days = parser.parse(
        envelope(List.generate(7, (i) => 'Plato inventado ${i + 1}')),
        candidates,
      );

      expect(days, hasLength(7));
      expect(days.every((d) => d.recipe.ironMg == 0), isTrue);
    });
  });

  group('the envelope', () {
    test('always yields seven days, padded from the candidates', () {
      final days = parser.parse(envelope([candidates.first.name]), candidates);

      expect(days, hasLength(7));
      expect(days.map((d) => d.dayIndex), [0, 1, 2, 3, 4, 5, 6]);
      for (final day in days.skip(1)) {
        expect(candidates.map((c) => c.id), contains(day.recipe.id));
      }
    });

    test('orders by "dia" rather than by array position', () {
      final payload = jsonDecode(envelope([])) as Map<String, dynamic>;
      payload['menu_semanal'] = [
        {'dia': 2, 'titulo_plato': candidates[1].name},
        {'dia': 1, 'titulo_plato': candidates[0].name},
      ];

      final days = parser.parse(jsonEncode(payload), candidates);

      expect(days[0].recipe.name, candidates[0].name);
      expect(days[1].recipe.name, candidates[1].name);
    });

    test('ingredients are flattened to "nombre (cantidad)"', () {
      final days = parser.parse(
        envelope(['Ceviche de pota con leche de tigre']),
        candidates,
      );

      expect(days.first.recipe.ingredients, [
        'Papa (1 unidad mediana)',
        'Sangrecita (2 cucharadas)',
      ]);
    });

    test('preparation steps are joined into one readable string for TTS', () {
      final days = parser.parse(
        envelope(['Ceviche de pota con leche de tigre']),
        candidates,
      );

      expect(
        days.first.recipe.preparation,
        'Sancocha la papa. Sirve tibio y con amor.',
      );
    });

    test('tolerates a code fence and prose around the JSON', () {
      final days = parser.parse(
        'Claro, aquí tienes el menú:\n'
        '```json\n${envelope([candidates.first.name])}\n```\n'
        '¡Espero que le guste!',
        candidates,
      );

      expect(days.first.recipe.id, candidates.first.id);
    });
  });

  group('degrading instead of failing', () {
    test('a plain numbered list falls back to the simple parser', () {
      final days = parser.parse(
        '1. ${candidates.first.name}\n2. ${candidates[1].name}',
        candidates,
      );

      expect(days, hasLength(7));
      expect(days[0].recipe.id, candidates.first.id);
      expect(days[1].recipe.id, candidates[1].id);
    });

    test('an unusable response still produces a week of INS recipes', () {
      final days = parser.parse('lo siento, no puedo ayudarte', candidates);

      expect(days, hasLength(7));
      for (final day in days) {
        expect(candidates.map((c) => c.id), contains(day.recipe.id));
      }
    });

    test('no candidates is a programming error, not a degraded plan', () {
      expect(
        () => parser.parse(envelope([candidates.first.name]), const <Recipe>[]),
        throwsStateError,
      );
    });
  });
}
