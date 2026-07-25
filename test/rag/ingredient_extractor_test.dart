import 'package:flutter_test/flutter_test.dart';
import 'package:wawafuerte/core/inference/inference_service.dart';
import 'package:wawafuerte/core/rag/ingredient_extractor.dart';

/// A scripted [InferenceService] so the extractor's parsing is tested against
/// controlled model output, instead of a live model that would make these
/// tests flaky and slow.
class _ScriptedInference implements InferenceService {
  _ScriptedInference(this.scriptedResponse);

  final String scriptedResponse;
  String? lastPrompt;

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
  Future<String> generateText(String prompt) async {
    lastPrompt = prompt;
    return scriptedResponse;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  const vocabulary = ['papa', 'huevo', 'lentejas', 'sangrecita', 'quinua'];

  test('empty text short-circuits without calling the model', () async {
    final inference = _ScriptedInference('["papa"]');
    final extractor = IngredientExtractor(inference);

    final result = await extractor.extract(
      freeText: '   ',
      vocabulary: vocabulary,
    );

    expect(result, isEmpty);
    expect(
      inference.lastPrompt,
      isNull,
      reason: 'An empty message is not worth a model call',
    );
  });

  test('parses a clean JSON array response', () async {
    final inference = _ScriptedInference('["papa", "huevo"]');
    final extractor = IngredientExtractor(inference);

    final result = await extractor.extract(
      freeText: 'tengo papa y huevo',
      vocabulary: vocabulary,
    );

    expect(result, ['papa', 'huevo']);
  });

  test('tolerates the model wrapping the array in prose', () async {
    final inference = _ScriptedInference(
      'Claro, aquí tienes: ["lentejas", "quinua"] — espero que ayude.',
    );
    final extractor = IngredientExtractor(inference);

    final result = await extractor.extract(
      freeText: 'me sobró lentejita y quinua',
      vocabulary: vocabulary,
    );

    expect(result, ['lentejas', 'quinua']);
  });

  group('grounding (never invent an ingredient outside the vocabulary)', () {
    test('an ingredient outside the vocabulary is silently dropped', () async {
      final inference = _ScriptedInference('["papa", "pollo a la brasa"]');
      final extractor = IngredientExtractor(inference);

      final result = await extractor.extract(
        freeText: 'tengo papa y pollo a la brasa',
        vocabulary: vocabulary,
      );

      expect(result, ['papa']);
    });

    test(
      'a completely malformed response yields no ingredients, not a crash',
      () async {
        final inference = _ScriptedInference(
          'lo siento, no puedo ayudar con eso',
        );
        final extractor = IngredientExtractor(inference);

        final result = await extractor.extract(
          freeText: 'que tengo hoy',
          vocabulary: vocabulary,
        );

        expect(result, isEmpty);
      },
    );

    test(
      'an explicit empty array is respected as "nothing recognised"',
      () async {
        final inference = _ScriptedInference('[]');
        final extractor = IngredientExtractor(inference);

        final result = await extractor.extract(
          freeText: 'no sé qué tengo',
          vocabulary: vocabulary,
        );

        expect(result, isEmpty);
      },
    );
  });

  test('duplicates in the model response are collapsed', () async {
    final inference = _ScriptedInference('["papa", "papa", "PAPA"]');
    final extractor = IngredientExtractor(inference);

    final result = await extractor.extract(
      freeText: 'papa, papa y más papa',
      vocabulary: vocabulary,
    );

    expect(result, ['papa']);
  });

  test('the prompt is grounded to the exact vocabulary supplied', () async {
    final inference = _ScriptedInference('[]');
    final extractor = IngredientExtractor(inference);

    await extractor.extract(freeText: 'algo', vocabulary: vocabulary);

    for (final item in vocabulary) {
      expect(inference.lastPrompt, contains(item));
    }
    expect(inference.lastPrompt, contains('No inventes'));
  });
}
