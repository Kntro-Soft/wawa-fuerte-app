/// Hybrid inference service: tries primary (e.g. Qonpania hosted API) and falls back
/// seamlessly to secondary (on-device Gemma or Fake) if primary fails or is offline.
library;

import 'inference_service.dart';

class HybridInferenceService implements InferenceService {
  HybridInferenceService({required this.primary, required this.fallback});

  final InferenceService primary;
  final InferenceService fallback;

  @override
  bool get isReady => primary.isReady || fallback.isReady;

  @override
  ActiveInferenceMode get activeMode =>
      primary.isReady ? primary.activeMode : fallback.activeMode;

  @override
  Future<void> warmUp() async {
    try {
      await primary.warmUp();
    } catch (_) {}

    try {
      await fallback.warmUp();
    } catch (_) {}
  }

  @override
  Future<String> generatePlanText(PlanPrompt prompt) async {
    try {
      return await primary.generatePlanText(prompt);
    } catch (_) {
      return await fallback.generatePlanText(prompt);
    }
  }

  @override
  Future<String> generateText(String prompt) async {
    try {
      return await primary.generateText(prompt);
    } catch (_) {
      return await fallback.generateText(prompt);
    }
  }

  @override
  Future<void> dispose() async {
    await primary.dispose();
    await fallback.dispose();
  }
}
