/// Reads the hosted agent's JSON envelope into seven [PlanDay]s (ADR-0015).
///
/// OWNER: P2 (@jhosepmyr).
///
/// The agent returns a whole plan, not a list of names:
///
/// ```json
/// {
///   "mensaje_motivacional": "…",
///   "menu_semanal": [
///     {"dia": 1, "titulo_plato": "…", "ingredientes": [{"nombre": "Papa", "cantidad": "1 unidad"}],
///      "preparacion": ["Sancocha la papa.", "…"]}
///   ]
/// }
/// ```
///
/// ## What is trusted, and what is not
///
/// The agent is trusted to **sequence and describe** — which dish on which day,
/// in what quantities, with what steps. It is not trusted with a single
/// nutritional figure. So each day is matched back against the retrieved INS
/// candidates by `titulo_plato`, and:
///
/// - **matched** → the INS [Recipe] is used, carrying its transcribed `ironMg`
///   and reference cost (ADR-0011). This is the normal path: the prompt hands
///   the agent the candidate names and tells it to copy them verbatim.
/// - **unmatched** → the day still reaches the screen, with the agent's own
///   ingredients and steps, but `ironMg: 0`. Its iron is genuinely *unknown*,
///   and the corpus notes are explicit that "under-stating iron is the safe
///   direction for a child-nutrition app". A guessed figure would land straight
///   in the coverage bar a caregiver acts on.
///
/// `meta_hierro_cubierta_porcentaje` is read from the payload and **discarded**.
/// Coverage is arithmetic over sourced data (ADR-0005, ADR-0012); a model's
/// opinion of its own plan is not evidence.
library;

import 'dart:convert';

import '../domain/generate_weekly_plan.dart';
import '../domain/recipe.dart';
import '../domain/weekly_plan.dart';
import 'plan_assembly.dart';
import 'simple_plan_parser.dart';

class QonpaniaPlanParser implements PlanParser {
  const QonpaniaPlanParser({this.fallback = const SimplePlanParser()});

  /// Used when the response is not the JSON envelope at all.
  ///
  /// A strict-JSON prompt is a strong constraint, not a guarantee, and the
  /// fallback already knows how to find recipe names in free prose — so a
  /// chatty answer degrades to a plain INS week instead of to an error screen.
  final PlanParser fallback;

  /// Iron for a dish that is not in the corpus: none, because none is known.
  static const double _unknownIronMg = 0;

  /// Cost for a dish that is not in the corpus. The INS book publishes no
  /// prices either (ADR-0011), so this was always an estimate; zero keeps an
  /// ungrounded dish from inventing one.
  static const double _unknownCostPen = 0;

  @override
  List<PlanDay> parse(String modelOutput, List<Recipe> candidates) {
    if (candidates.isEmpty) {
      throw StateError('Cannot parse a plan without candidate recipes.');
    }

    final menu = _menuFrom(modelOutput);
    if (menu == null || menu.isEmpty) {
      return fallback.parse(modelOutput, candidates);
    }

    final recipes = <Recipe>[];
    for (final entry in menu) {
      final recipe = _recipeFrom(entry, candidates);
      if (recipe != null) recipes.add(recipe);
      if (recipes.length == daysInPlan) break;
    }

    // Short weeks are padded from the candidates, exactly as on the Gemma path.
    return assembleWeek(recipes, candidates);
  }

  // --- Envelope --------------------------------------------------------------

  /// The `menu_semanal` array, ordered by `dia`, or null when this is not the
  /// envelope.
  ///
  /// Tolerant of the agent wrapping the object in prose or a ```json fence —
  /// both happen even when the prompt asks for raw JSON.
  static List<Map<String, dynamic>>? _menuFrom(String output) {
    final start = output.indexOf('{');
    final end = output.lastIndexOf('}');
    if (start < 0 || end <= start) return null;

    Object? decoded;
    try {
      decoded = jsonDecode(output.substring(start, end + 1));
    } on FormatException {
      return null;
    }

    if (decoded is! Map<String, dynamic>) return null;
    final menu = decoded['menu_semanal'];
    if (menu is! List) return null;

    final entries = menu.whereType<Map<String, dynamic>>().toList()
      ..sort((a, b) => _dayNumber(a).compareTo(_dayNumber(b)));
    return entries;
  }

  /// `dia` is 1-based in the payload. A missing or unparseable one sorts last
  /// rather than colliding with day 1.
  static int _dayNumber(Map<String, dynamic> entry) {
    final raw = entry['dia'];
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? daysInPlan + 1;
    return daysInPlan + 1;
  }

  // --- One day ---------------------------------------------------------------

  static Recipe? _recipeFrom(
    Map<String, dynamic> entry,
    List<Recipe> candidates,
  ) {
    final title = (entry['titulo_plato'] as Object?)?.toString().trim() ?? '';
    if (title.isEmpty) return null;

    // The grounded path: the agent copied a candidate name, so the day inherits
    // that recipe's sourced nutrition instead of the agent's description.
    final matched = bestRecipeMatch(title, candidates);
    if (matched != null) return matched;

    return Recipe(
      // Negative, so an agent-authored dish can never be mistaken for INS
      // recipe #N — the corpus ids are all positive. Derived from the day
      // rather than a counter so parsing is deterministic. It is snapshotted
      // into `plan_days` like any other recipe, so the plan still reads back.
      id: -_dayNumber(entry),
      name: title,
      ingredients: _ingredients(entry['ingredientes']),
      preparation: _preparation(entry['preparacion']),
      ironMg: _unknownIronMg,
      // The retriever already filtered candidates by the child's age; this dish
      // is off-corpus, so claiming an age floor for it would be a clinical
      // assertion we have no basis for. Zero asserts nothing.
      minAgeMonths: 0,
      referenceCostPen: _unknownCostPen,
    );
  }

  /// `[{"nombre": "Papa", "cantidad": "1 unidad mediana"}]` → `["Papa (1 unidad
  /// mediana)"]`, matching the flat `List<String>` the domain and the recipe
  /// screen already use.
  static List<String> _ingredients(Object? raw) {
    if (raw is! List) return const [];

    final result = <String>[];
    for (final item in raw) {
      if (item is String) {
        if (item.trim().isNotEmpty) result.add(item.trim());
        continue;
      }
      if (item is! Map<String, dynamic>) continue;

      final name = (item['nombre'] as Object?)?.toString().trim() ?? '';
      if (name.isEmpty) continue;

      final amount = (item['cantidad'] as Object?)?.toString().trim() ?? '';
      result.add(amount.isEmpty ? name : '$name ($amount)');
    }
    return result;
  }

  /// Steps are joined into the single string [Recipe.preparation] holds — which
  /// is also what TTS reads aloud, so they are separated by sentence-ending
  /// punctuation rather than newlines.
  static String _preparation(Object? raw) {
    if (raw is String) return raw.trim();
    if (raw is! List) return '';

    return raw
        .whereType<Object>()
        .map((step) => step.toString().trim())
        .where((step) => step.isNotEmpty)
        .map((step) => step.endsWith('.') ? step : '$step.')
        .join(' ');
  }
}
