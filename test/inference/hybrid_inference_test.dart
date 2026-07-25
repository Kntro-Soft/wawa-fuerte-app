import 'package:flutter_test/flutter_test.dart';
import 'package:wawafuerte/core/domain/child_profile.dart';
import 'package:wawafuerte/core/inference/fake_inference_service.dart';
import 'package:wawafuerte/core/inference/hybrid_inference_service.dart';
import 'package:wawafuerte/core/inference/inference_service.dart';
import 'package:wawafuerte/core/domain/recipe.dart';

class FailingInferenceService implements InferenceService {
  @override
  bool get isReady => true;

  @override
  Future<void> warmUp() async {
    throw Exception('Network unreachable');
  }

  @override
  Future<String> generatePlanText(PlanPrompt prompt) async {
    throw Exception('Network timeout');
  }

  @override
  Future<String> generateText(String prompt) async {
    throw Exception('Network timeout');
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  test(
    'HybridInferenceService falls back to secondary when primary fails',
    () async {
      final primary = FailingInferenceService();
      final fallback = FakeInferenceService();

      final hybrid = HybridInferenceService(
        primary: primary,
        fallback: fallback,
      );
      await hybrid.warmUp();

      const prompt = PlanPrompt(
        candidateRecipes: [
          Recipe(
            id: 1,
            name: 'Sangrecita con papa',
            ingredients: ['sangrecita', 'papa'],
            preparation: 'Paso 1...',
            ironMg: 8.5,
            minAgeMonths: 6,
            referenceCostPen: 4.5,
          ),
        ],
        ageMonths: 12,
        region: Region.highlands,
        availableIngredients: ['sangrecita'],
        weeklyBudgetPen: 30,
      );

      final text = await hybrid.generatePlanText(prompt);
      expect(text, contains('Sangrecita con papa'));
    },
  );
}
