/// Retrieval over the INS recipe corpus.
///
/// OWNER: P2 (@jhosepmyr).
///
/// Embeddings are precomputed and shipped as an asset; similarity is cosine,
/// computed in memory over a corpus of tens of recipes (ADR-0006). Nothing here
/// touches the network or the model.
library;

import '../domain/child_profile.dart';
import '../domain/recipe.dart';

abstract interface class RecipeRetriever {
  /// Loads the corpus and its embeddings. Call once at startup.
  Future<void> load();

  /// Returns the [topK] recipes best matching what the family actually has.
  ///
  /// Results must already be filtered to recipes suitable for [ageMonths] —
  /// an unsuitable recipe should never reach the prompt.
  Future<List<Recipe>> retrieve({
    required List<String> availableIngredients,
    required double weeklyBudgetPen,
    required int ageMonths,
    required Region region,
    int topK = 5,
  });
}
