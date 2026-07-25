/// Retrieval over the **real** INS corpus (ADR-0005, ADR-0011).
///
/// Loads `assets/data/recetario_ins.json` through `rootBundle` and ranks by
/// ingredient overlap — deterministic retrieval, not embeddings (ADR-0006):
/// the caregiver picks from a closed checklist, so there is no free text to
/// vectorise, and 23 recipes need no index at all.
///
/// Mirrors [FakeRecipeRetriever]'s ranking so swapping one for the other never
/// changes behaviour, only the data it runs over.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/child_profile.dart';
import '../domain/recipe.dart';
import 'recipe_retriever.dart';

class InsRecipeRetriever implements RecipeRetriever {
  InsRecipeRetriever({this.assetPath = 'assets/data/recetario_ins.json'});

  final String assetPath;

  List<Recipe> _corpus = const [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  @override
  Future<void> load() async {
    if (_loaded) return;

    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final rows = decoded['recipes'] as List<dynamic>;

    _corpus = rows
        .cast<Map<String, dynamic>>()
        .map(_recipeFromJson)
        .toList(growable: false);

    if (_corpus.isEmpty) {
      // Retrieval has nothing to ground the model with (ADR-0005). Fail loudly
      // at load time rather than silently at the first empty generation.
      throw StateError('$assetPath parsed but contained no recipes.');
    }

    _loaded = true;
  }

  @override
  Future<List<Recipe>> retrieve({
    required List<String> availableIngredients,
    required double weeklyBudgetPen,
    required int ageMonths,
    required Region region,
    int topK = 5,
  }) async {
    if (!_loaded) await load();

    final wanted = availableIngredients
        .map((i) => i.trim().toLowerCase())
        .where((i) => i.isNotEmpty)
        .toSet();

    // Age filtering is part of the contract, not an optimisation: a recipe the
    // child cannot eat must never reach the prompt. Region is null on every
    // INS recipe (the book is national, ADR-0011), so it never excludes here.
    final eligible = _corpus
        .where((r) => r.isSuitableFor(ageMonths))
        .where((r) => r.region == null || r.region == region)
        .toList();

    eligible.sort((a, b) {
      final byOverlap = _overlap(b, wanted).compareTo(_overlap(a, wanted));
      if (byOverlap != 0) return byOverlap;
      // Tie-break on iron density: the app exists to raise iron intake, so
      // when two recipes are equally cookable the denser one wins.
      final byIron = b.ironMg.compareTo(a.ironMg);
      if (byIron != 0) return byIron;
      return a.referenceCostPen.compareTo(b.referenceCostPen);
    });

    // Never return empty while any recipe is age-appropriate: the inference
    // service throws on empty candidates, and "nothing matched" is a worse
    // answer to a caregiver than "here is what we have".
    final selected = eligible.take(topK).toList();
    return selected;
  }

  static int _overlap(Recipe recipe, Set<String> wanted) {
    if (wanted.isEmpty) return 0;
    return recipe.ingredients
        .where((i) => wanted.any((w) => i.contains(w) || w.contains(i)))
        .length;
  }

  static Recipe _recipeFromJson(Map<String, dynamic> row) => Recipe(
    id: row['id'] as int,
    name: row['name'] as String,
    ingredients: (row['ingredients'] as List<dynamic>).cast<String>(),
    preparation: row['preparation'] as String,
    ironMg: (row['ironMg'] as num).toDouble(),
    minAgeMonths: row['minAgeMonths'] as int,
    // ADR-0011: not an official figure, always an estimate. The retriever
    // still ranks by it (it is the only cost signal available), but nothing
    // downstream may present it as sourced.
    referenceCostPen: (row['referenceCostPen'] as num).toDouble(),
    region: _regionFromJson(row['region']),
  );

  static Region? _regionFromJson(Object? value) => switch (value) {
    'coast' => Region.coast,
    'highlands' => Region.highlands,
    'jungle' => Region.jungle,
    _ => null,
  };
}
