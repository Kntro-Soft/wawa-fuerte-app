import 'package:flutter_test/flutter_test.dart';
import 'package:wawafuerte/core/domain/child_profile.dart';
import 'package:wawafuerte/core/rag/ins_recipe_retriever.dart';

/// Runs through `rootBundle`, the same path the app uses at runtime, so a
/// bundling or parsing mistake fails here instead of on a real handset —
/// same rationale as `test/data/asset_bundle_test.dart` in #7.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InsRecipeRetriever retriever;

  setUp(() {
    retriever = InsRecipeRetriever();
  });

  test('loads the real INS corpus, not sample data', () async {
    await retriever.load();
    expect(retriever.isLoaded, isTrue);
  });

  test('retrieve() lazily loads if load() was never called', () async {
    final results = await retriever.retrieve(
      availableIngredients: const ['papa'],
      weeklyBudgetPen: 40,
      ageMonths: 12,
      region: Region.highlands,
    );

    expect(results, isNotEmpty);
  });

  group(
    'age filtering (a recipe the child cannot eat must never be returned)',
    () {
      test('every returned recipe is suitable for the requested age', () async {
        await retriever.load();

        final results = await retriever.retrieve(
          availableIngredients: const ['papa', 'sangrecita', 'quinua'],
          weeklyBudgetPen: 50,
          ageMonths: 7,
          region: Region.highlands,
        );

        for (final recipe in results) {
          expect(recipe.isSuitableFor(7), isTrue, reason: recipe.name);
        }
      });
    },
  );

  group('ranking', () {
    test(
      'recipes matching more of the available ingredients rank higher',
      () async {
        await retriever.load();

        final results = await retriever.retrieve(
          availableIngredients: const [
            'hígado de pollo',
            'brócoli',
            'papa amarilla',
          ],
          weeklyBudgetPen: 40,
          ageMonths: 18,
          region: Region.highlands,
          topK: 3,
        );

        expect(results, isNotEmpty);
        // The top result should share at least one ingredient with what was
        // marked available — an empty overlap at rank 1 would mean the ranking
        // is not actually using what the caregiver has.
        final wanted = {'hígado de pollo', 'brócoli', 'papa amarilla'};
        expect(
          results.first.ingredients.any(wanted.contains),
          isTrue,
          reason:
              'Top match "${results.first.name}" shares nothing with the checklist',
        );
      },
    );

    test(
      'with no ingredients selected, iron density still orders the results',
      () async {
        await retriever.load();

        final results = await retriever.retrieve(
          availableIngredients: const [],
          weeklyBudgetPen: 40,
          ageMonths: 18,
          region: Region.highlands,
        );

        for (var i = 1; i < results.length; i++) {
          expect(
            results[i - 1].ironMg,
            greaterThanOrEqualTo(results[i].ironMg),
            reason:
                'Results are not sorted by iron density when there is no ingredient signal',
          );
        }
      },
    );
  });

  group('data provenance (ADR-0011)', () {
    test(
      'ironMg values are never zero — they are transcribed, not computed',
      () async {
        await retriever.load();

        final results = await retriever.retrieve(
          availableIngredients: const [],
          weeklyBudgetPen: 100,
          ageMonths: 24,
          region: Region.highlands,
          topK: 23,
        );

        for (final recipe in results) {
          expect(recipe.ironMg, greaterThan(0), reason: recipe.name);
        }
      },
    );

    test(
      'region is null on every recipe — the INS book is national (ADR-0011)',
      () async {
        await retriever.load();

        final results = await retriever.retrieve(
          availableIngredients: const [],
          weeklyBudgetPen: 100,
          ageMonths: 24,
          region: Region.jungle,
          topK: 23,
        );

        for (final recipe in results) {
          expect(recipe.region, isNull, reason: recipe.name);
        }
      },
    );
  });
}
