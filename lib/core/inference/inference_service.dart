/// On-device text generation with Gemma.
///
/// OWNER: P1 (@sharvel-irigoyen).
///
/// Everything behind this interface is native and device-bound: real inference
/// runs on a physical Android phone and cannot be validated on a simulator or
/// emulator (ADR-0003, ADR-0004). That is exactly why the seam exists — the
/// other three developers work against [FakeInferenceService] and never wait
/// for the model.
library;

import '../domain/child_profile.dart';
import '../domain/recipe.dart';

/// Identifies which engine is actively serving requests.
enum ActiveInferenceMode {
  /// Remote hosted API / Cloud agent (ADR-0015).
  cloud('Nube'),

  /// On-device Gemma SLM (ADR-0004).
  gemma('Gemma'),

  /// Canned mock fallback during testing or offline without model weights.
  demo('Demo');

  const ActiveInferenceMode(this.label);
  final String label;
}

abstract interface class InferenceService {
  /// Whether the model is loaded and can serve a request.
  bool get isReady;

  /// Whether the model weights are currently downloading.
  bool get isDownloading;

  /// Download progress from 0 to 100 if downloading, null otherwise.
  int? get downloadProgress;

  /// The active execution mode (cloud, gemma, or demo).
  ActiveInferenceMode get activeMode;

  /// Loads the model into memory. Slow — call it once, off the critical path.
  Future<void> warmUp();

  /// Generates the raw plan text from a grounded prompt.
  ///
  /// Returns model output verbatim; parsing into a [WeeklyPlan] is the caller's
  /// job, so a malformed generation fails in one known place.
  Future<String> generatePlanText(PlanPrompt prompt);

  /// Generic single-turn generation for anything that is not a weekly plan —
  /// extracting ingredients from free text, orchestrating a function call.
  /// Returns model output verbatim; the caller parses it.
  Future<String> generateText(String prompt);

  /// Releases native resources.
  Future<void> dispose();
}

/// Everything the model is allowed to see, assembled by the caller.
///
/// The model never receives raw user data — only this, built from retrieved
/// INS recipes plus the child's age band.
class PlanPrompt {
  const PlanPrompt({
    required this.candidateRecipes,
    required this.ageMonths,
    required this.region,
    required this.availableIngredients,
    required this.weeklyBudgetPen,
    this.hemoglobin,
  });

  /// Recipes retrieved from the INS corpus. The model composes a week from
  /// these; it does not invent dishes (ADR-0005).
  final List<Recipe> candidateRecipes;

  final int ageMonths;
  final Region region;
  final List<String> availableIngredients;
  final double weeklyBudgetPen;

  /// Null when the caregiver has no CRED reading (ADR-0007). Prompt builders
  /// must branch on this: with a value, ask the model to prioritise iron
  /// density; without one, ask for a standard preventive plan for the age.
  final double? hemoglobin;

  bool get isPersonalised => hemoglobin != null;
}
