/// Free-text ingredient extraction, using the model already in memory.
///
/// Flow B's checklist is closed by design: the caregiver taps ingredients, she
/// does not type them. But "tengo lo que sobró del almuerzo, papa y un poco de
/// hígado" is a real thing a caregiver might type instead, and a fuzzy string
/// match cannot parse that — it needs to understand the sentence.
///
/// This is *not* the vector-embedding RAG that ADR-0006 explicitly rejected —
/// no second model, no vector store. Gemma is already loaded for the plan
/// itself; this reuses it for one extra short-lived call. Retrieval afterwards
/// is still the deterministic overlap ranking in [InsRecipeRetriever].
library;

import 'dart:convert';

import '../inference/inference_service.dart';

class IngredientExtractor {
  const IngredientExtractor(this._inference);

  final InferenceService _inference;

  /// Returns the subset of [vocabulary] mentioned in [freeText], normalised to
  /// the vocabulary's own spelling.
  ///
  /// Constrained to a closed vocabulary on purpose: the retriever only knows
  /// how to match ingredients that exist in the INS corpus, so returning an
  /// ingredient outside it would just be silently dropped downstream. Better
  /// to make that constraint explicit here than to pretend the model can name
  /// arbitrary foods.
  Future<List<String>> extract({
    required String freeText,
    required List<String> vocabulary,
  }) async {
    final trimmed = freeText.trim();
    if (trimmed.isEmpty) return const [];

    final response = await _inference.generateText(
      _buildPrompt(trimmed, vocabulary),
    );
    return _parse(response, vocabulary);
  }

  static String _buildPrompt(String freeText, List<String> vocabulary) {
    return '''
Extrae de este texto SOLO los alimentos que aparecen en la lista de vocabulario.
No agregues alimentos que no estén en la lista. No inventes nada.

Vocabulario permitido: ${vocabulary.join(', ')}

Texto de la madre: "$freeText"

Responde ÚNICAMENTE con un array JSON de strings, por ejemplo: ["papa", "huevo"]
Si no reconoces ningún alimento de la lista, responde: []
''';
  }

  /// Tolerant of the model wrapping the array in prose or a code fence — both
  /// are common even when the prompt asks for raw JSON — but never tolerant of
  /// an ingredient outside [vocabulary], which would be fabrication.
  static List<String> _parse(String response, List<String> vocabulary) {
    final match = RegExp(r'\[[\s\S]*?\]').firstMatch(response);
    if (match == null) return const [];

    List<dynamic> decoded;
    try {
      decoded = json.decode(match.group(0)!) as List<dynamic>;
    } on FormatException {
      return const [];
    }

    final allowed = {for (final v in vocabulary) v.toLowerCase().trim(): v};
    final result = <String>[];
    for (final item in decoded) {
      if (item is! String) continue;
      final canonical = allowed[item.toLowerCase().trim()];
      if (canonical != null && !result.contains(canonical)) {
        result.add(canonical);
      }
    }
    return result;
  }
}
