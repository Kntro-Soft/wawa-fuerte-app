/// In-memory [RecipeRetriever] so the UI is never blocked on the real RAG.
///
/// Mirrors the role `FakeInferenceService` plays for P1: a working seam that
/// lets P3 build every screen against real types and real behaviour.
///
/// ⚠️ **THE NUTRITIONAL FIGURES BELOW ARE SAMPLE DATA, NOT OFFICIAL VALUES.**
///
/// They are plausible round numbers for well-known Peruvian dishes, put here so
/// the coverage bar has something to compute over. They are **not** taken from
/// the INS recipe book and must not be shown to a real caregiver. The real
/// retriever (P2) reads the bundled `recetario_ins.json`, whose `ironMg` values
/// carry the citations that ADR-0005 and ADR-0012 require. Ranking here is a
/// transparent ingredient-overlap score, not cosine similarity over embeddings
/// (ADR-0006) — same contract, different implementation.
library;

import '../domain/child_profile.dart';
import '../domain/recipe.dart';
import 'recipe_retriever.dart';

class FakeRecipeRetriever implements RecipeRetriever {
  FakeRecipeRetriever();

  bool _loaded = false;

  /// Whether [load] has run. Exposed for tests.
  bool get isLoaded => _loaded;

  @override
  Future<void> load() async {
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
    final wanted = availableIngredients
        .map((i) => i.trim().toLowerCase())
        .where((i) => i.isNotEmpty)
        .toSet();

    // Age filtering is part of the contract, not an optimisation: a recipe the
    // child cannot eat must never reach the prompt.
    final eligible = sampleRecipes
        .where((r) => r.isSuitableFor(ageMonths))
        .where((r) => r.region == null || r.region == region)
        .toList();

    eligible.sort((a, b) {
      final byOverlap = _overlap(b, wanted).compareTo(_overlap(a, wanted));
      if (byOverlap != 0) return byOverlap;
      // Tie-break on iron density: this app exists to raise iron intake, so when
      // two recipes are equally cookable the more iron-dense one wins.
      final byIron = b.ironMg.compareTo(a.ironMg);
      if (byIron != 0) return byIron;
      return a.referenceCostPen.compareTo(b.referenceCostPen);
    });

    // Never return an empty list while any recipe is age-appropriate: the
    // downstream inference service throws on empty candidates, and "we found
    // nothing" is a worse answer to a caregiver than "here is what we have".
    final selected = eligible.take(topK).toList();
    return selected.isEmpty ? eligible.take(topK).toList() : selected;
  }

  static int _overlap(Recipe recipe, Set<String> wanted) {
    if (wanted.isEmpty) return 0;
    return recipe.ingredients
        .where((i) => wanted.any((w) => i.contains(w) || w.contains(i)))
        .length;
  }

  /// Sample corpus. **Not official INS data** — see the library doc.
  static const List<Recipe> sampleRecipes = <Recipe>[
    Recipe(
      id: 1,
      name: 'Segundo de sangrecita con arroz y verduras',
      ingredients: ['sangrecita', 'arroz', 'cebolla', 'zanahoria', 'ajo'],
      preparation:
          'Lava la sangrecita y córtala en cubos pequeños. '
          'Calienta una cucharada de aceite en la olla y dora la cebolla y el ajo. '
          'Agrega la sangrecita y cocina cinco minutos moviendo con cuchara de palo. '
          'Añade la zanahoria picada bien chiquita y un poco de agua. '
          'Tapa la olla y deja cocinar diez minutos a fuego bajo. '
          'Sirve con el arroz cocido y aplasta todo con el tenedor si tu wawa aún no mastica bien.',
      ironMg: 8.5,
      minAgeMonths: 6,
      referenceCostPen: 2.50,
    ),
    Recipe(
      id: 2,
      name: 'Puré de papa con hígado de pollo',
      ingredients: ['papa', 'higado de pollo', 'leche', 'cebolla'],
      preparation:
          'Sancocha dos papas medianas hasta que estén bien suaves. '
          'Mientras tanto, pica el hígado de pollo en trozos pequeños y dóralo con un poco de cebolla. '
          'Aplasta las papas calientes con el tenedor y añade un chorrito de leche. '
          'Pica muy fino el hígado ya cocido y mézclalo con el puré. '
          'Sirve tibio, nunca hirviendo.',
      ironMg: 6.2,
      minAgeMonths: 6,
      referenceCostPen: 2.20,
    ),
    Recipe(
      id: 3,
      name: 'Guiso de lentejas con arroz',
      ingredients: ['lentejas', 'arroz', 'cebolla', 'tomate', 'ajo'],
      preparation:
          'Remoja las lentejas desde la noche anterior y bota esa agua. '
          'Dora cebolla, ajo y tomate picados en la olla. '
          'Agrega las lentejas y agua hasta cubrirlas dos dedos por encima. '
          'Cocina a fuego bajo cuarenta minutos hasta que estén blanditas. '
          'Sirve con arroz. Acompaña con un vaso de limonada: la vitamina C ayuda a que el hierro se aproveche mejor.',
      ironMg: 4.8,
      minAgeMonths: 8,
      referenceCostPen: 1.80,
    ),
    Recipe(
      id: 4,
      name: 'Quinua guisada con verduras y huevo',
      ingredients: ['quinua', 'zanahoria', 'huevo', 'cebolla', 'acelga'],
      preparation:
          'Lava la quinua frotándola con las manos y enjuaga tres veces para quitarle el amargo. '
          'Cocina la quinua en agua durante quince minutos. '
          'Aparte, dora la cebolla y añade la zanahoria y la acelga picadas finito. '
          'Junta la quinua con las verduras y mueve bien. '
          'Rompe un huevo encima, tapa la olla y deja cocinar tres minutos más.',
      ironMg: 4.1,
      minAgeMonths: 8,
      referenceCostPen: 2.90,
    ),
    Recipe(
      id: 5,
      name: 'Papilla de avena con tarwi y plátano',
      ingredients: ['avena', 'tarwi', 'platano', 'leche'],
      preparation:
          'Hierve una taza de leche con dos cucharadas de avena, moviendo para que no se pegue. '
          'Muele el tarwi ya desamargado hasta que quede como una crema. '
          'Mezcla el tarwi molido con la avena cocida. '
          'Aplasta medio plátano maduro y agrégalo al final. '
          'Deja entibiar antes de dar de comer.',
      ironMg: 3.4,
      minAgeMonths: 6,
      referenceCostPen: 1.60,
    ),
    Recipe(
      id: 6,
      name: 'Estofado de pollo con papa amarilla',
      ingredients: ['pollo', 'papa', 'zanahoria', 'arveja', 'cebolla'],
      preparation:
          'Dora los trozos de pollo en la olla con un poco de aceite. '
          'Agrega cebolla y ajo picados y deja que suelten su olor. '
          'Añade la papa amarilla en cubos, la zanahoria y las arvejas. '
          'Cubre con agua y cocina treinta minutos a fuego medio. '
          'Deshuesa el pollo antes de servir a tu wawa y desmenúzalo bien.',
      ironMg: 2.6,
      minAgeMonths: 8,
      referenceCostPen: 4.20,
    ),
    Recipe(
      id: 7,
      name: 'Saltado de acelga con hígado y camote',
      ingredients: ['acelga', 'higado de res', 'camote', 'cebolla'],
      preparation:
          'Sancocha el camote y córtalo en cubos. '
          'Corta el hígado en tiras delgadas y saltéalo a fuego fuerte dos minutos por lado. '
          'Agrega la cebolla en pluma y la acelga picada. '
          'Saltea todo junto tres minutos más para que la acelga no pierda su color. '
          'Sirve con el camote al costado.',
      ironMg: 7.3,
      minAgeMonths: 12,
      referenceCostPen: 3.40,
    ),
    Recipe(
      id: 8,
      name: 'Mazamorra de quinua con manzana',
      ingredients: ['quinua', 'manzana', 'canela', 'leche'],
      preparation:
          'Lava bien la quinua y cocínala en agua veinte minutos hasta que reviente. '
          'Ralla una manzana y agrégala con un palito de canela. '
          'Añade la leche y cocina cinco minutos más sin dejar de mover. '
          'Retira la canela y sirve tibio. '
          'La manzana aporta vitamina C, que ayuda a aprovechar el hierro de la quinua.',
      ironMg: 3.0,
      minAgeMonths: 6,
      referenceCostPen: 2.10,
    ),
    Recipe(
      id: 9,
      name: 'Sopa espesa de trigo con sangrecita y zapallo',
      ingredients: ['trigo', 'sangrecita', 'zapallo', 'cebolla', 'ajo'],
      preparation:
          'Remoja el trigo la noche anterior. '
          'Hierve el trigo con el zapallo en trozos hasta que ambos estén suaves. '
          'Aparte, saltea la sangrecita picada con cebolla y ajo. '
          'Junta todo en la olla y deja hervir cinco minutos. '
          'Aplasta el zapallo dentro de la sopa para que quede espesita.',
      ironMg: 7.8,
      minAgeMonths: 9,
      referenceCostPen: 2.70,
    ),
    Recipe(
      id: 10,
      name: 'Puré de frijol con arroz y huevo sancochado',
      ingredients: ['frijol', 'arroz', 'huevo', 'cebolla', 'ajo'],
      preparation:
          'Remoja los frijoles desde la noche anterior y bota esa agua. '
          'Cocínalos en olla a presión veinticinco minutos, o en olla normal hasta que se deshagan. '
          'Aplasta los frijoles con el cucharón hasta formar un puré. '
          'Sancocha un huevo diez minutos y pícalo. '
          'Sirve el puré sobre el arroz con el huevo encima.',
      ironMg: 4.4,
      minAgeMonths: 9,
      referenceCostPen: 2.00,
    ),
  ];
}
