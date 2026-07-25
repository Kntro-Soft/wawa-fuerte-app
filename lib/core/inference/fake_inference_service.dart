/// Stand-in for Gemma so the other three developers are never blocked.
///
/// This is the default implementation during development (ADR-0004). It also
/// doubles as the contingency: if the native path fails on the day, the app
/// still demos with a canned plan instead of not running at all.
library;

import 'inference_service.dart';

class FakeInferenceService implements InferenceService {
  FakeInferenceService({this.latency = const Duration(milliseconds: 600)});

  /// Simulated generation time, so the UI's loading state gets exercised.
  final Duration latency;

  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  ActiveInferenceMode get activeMode => ActiveInferenceMode.demo;

  @override
  Future<void> warmUp() async {
    await Future<void>.delayed(latency);
    _ready = true;
  }

  @override
  Future<String> generatePlanText(PlanPrompt prompt) async {
    await Future<void>.delayed(latency);

    // Cycle through whatever the retriever offered, so the fake still reflects
    // the real corpus and the real age filter rather than hardcoded dishes.
    if (prompt.candidateRecipes.isEmpty) {
      throw StateError('No candidate recipes were provided to the model.');
    }

    final buffer = StringBuffer();
    for (var day = 0; day < 7; day++) {
      final recipe =
          prompt.candidateRecipes[day % prompt.candidateRecipes.length];
      buffer.writeln('${day + 1}. ${recipe.name}');
    }
    return buffer.toString();
  }

  @override
  Future<String> generateText(String prompt) async {
    await Future<void>.delayed(latency);
    // No model to actually reason with here — echo the input back so callers
    // relying on this in tests get a deterministic, non-empty response.
    return prompt;
  }

  @override
  Future<void> dispose() async {
    _ready = false;
  }
}
