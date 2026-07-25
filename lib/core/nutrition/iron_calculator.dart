/// Iron requirement and coverage arithmetic.
///
/// OWNER: P2 (@jhosepmyr).
///
/// Deliberately model-free. The coverage figure is the number a caregiver acts
/// on, so it is computed from the nutrient data attached to each INS recipe and
/// a fixed age-based requirement table — never generated (ADR-0005).
library;

import '../domain/child_profile.dart';
import '../domain/weekly_plan.dart';
import '../domain/recipe.dart';

abstract interface class IronCalculator {
  /// Weekly iron requirement in mg for a child of [ageMonths].
  ///
  /// Derived from the INS/WHO tables, which key on age — **not** on hemoglobin.
  /// This is why the app still works for families without a CRED reading
  /// (ADR-0007).
  double weeklyRequirementMg(int ageMonths, Sex? sex);

  /// Coverage the given recipes provide against that requirement.
  IronCoverage coverageOf({
    required List<Recipe> recipes,
    required int ageMonths,
    Sex? sex,
  });
}
