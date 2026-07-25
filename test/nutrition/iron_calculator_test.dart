/// Tests for [TableIronCalculator].
///
/// The expected numbers here are transcribed from the official sources, not
/// from the implementation. If a test fails, check the table against the source
/// before changing the test — see ADR-0012.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wawafuerte/core/domain/child_profile.dart';
import 'package:wawafuerte/core/domain/recipe.dart';
import 'package:wawafuerte/core/nutrition/iron_calculator.dart';
import 'package:wawafuerte/core/nutrition/table_iron_calculator.dart';

/// Floating-point slack. The requirement figures have one decimal, so anything
/// tighter than this would be testing IEEE-754 rather than the table.
const double _epsilon = 1e-9;

Recipe _recipe(double ironMg, {int id = 1, int minAgeMonths = 6}) => Recipe(
  id: id,
  name: 'Receta $id',
  ingredients: const ['sangrecita'],
  preparation: 'Cocinar.',
  ironMg: ironMg,
  minAgeMonths: minAgeMonths,
  referenceCostPen: 2.5,
);

void main() {
  const calculator = TableIronCalculator();

  group('weeklyRequirementMg — official table', () {
    // INS «Requerimientos nutricionales», column HIERRO (mg/día), sub-column
    // 10% (Moderada) — identical to FAO/WHO chapter 13 Table 40, p. 197.
    // https://alimentacionsaludable.ins.gob.pe/ninos-y-ninas/requerimientos-nutricionales
    // https://www.fao.org/4/y2809e/y2809e13.pdf
    const dailyByBand = <String, ({int from, int to, double mg})>{
      'FAO/WHO 0.5–1 years': (from: 6, to: 11, mg: 9.3),
      'FAO/WHO 1–3 years': (from: 12, to: 47, mg: 5.8),
      'FAO/WHO 4–6 years': (from: 48, to: 83, mg: 6.3),
      'FAO/WHO 7–10 years': (from: 84, to: 131, mg: 8.9),
    };

    dailyByBand.forEach((label, band) {
      test('$label: ${band.from}–${band.to} months is ${band.mg} mg/day', () {
        for (final ageMonths in [band.from, band.to]) {
          expect(
            calculator.dailyRequirementMg(ageMonths),
            closeTo(band.mg, _epsilon),
            reason: 'daily requirement at $ageMonths months',
          );
          expect(
            calculator.weeklyRequirementMg(ageMonths, null),
            closeTo(band.mg * 7, _epsilon),
            reason: 'weekly requirement at $ageMonths months',
          );
        }
      });
    });

    test('bands are contiguous across the whole supported range', () {
      for (
        var ageMonths = TableIronCalculator.minSupportedAgeMonths;
        ageMonths <= TableIronCalculator.maxSupportedAgeMonths;
        ageMonths++
      ) {
        expect(
          calculator.hasOfficialRequirement(ageMonths),
          isTrue,
          reason: 'no band covers $ageMonths months',
        );
        expect(calculator.weeklyRequirementMg(ageMonths, null), greaterThan(0));
      }
    });

    test('covers the whole 6–59 month target population', () {
      for (var ageMonths = 6; ageMonths <= 59; ageMonths++) {
        expect(calculator.hasOfficialRequirement(ageMonths), isTrue);
      }
    });

    test('weekly requirement is exactly seven daily requirements', () {
      for (final ageMonths in [6, 11, 12, 18, 47, 48, 59, 83, 84, 131]) {
        expect(
          calculator.weeklyRequirementMg(ageMonths, null),
          closeTo(calculator.dailyRequirementMg(ageMonths) * 7, _epsilon),
        );
      }
    });
  });

  group('ages without an official figure', () {
    test('under 6 months has no published dietary requirement', () {
      for (final ageMonths in [0, 1, 5]) {
        expect(
          calculator.hasOfficialRequirement(ageMonths),
          isFalse,
          reason: '$ageMonths months must not claim an official figure',
        );
        expect(calculator.weeklyRequirementMg(ageMonths, null), 0);
      }
    });

    test('age 0 returns 0 rather than throwing', () {
      expect(calculator.weeklyRequirementMg(0, null), 0);
      expect(
        () => calculator.coverageOf(recipes: const [], ageMonths: 0),
        returnsNormally,
      );
    });

    test('negative ages are treated as unsupported, not as a crash', () {
      expect(calculator.hasOfficialRequirement(-1), isFalse);
      expect(calculator.weeklyRequirementMg(-1, null), 0);
    });

    test(
      'above 10 years there is no sex-neutral figure, so none is invented',
      () {
        for (final ageMonths in [132, 200, 1200]) {
          expect(calculator.hasOfficialRequirement(ageMonths), isFalse);
          expect(calculator.weeklyRequirementMg(ageMonths, null), 0);
        }
      },
    );

    test('a zero requirement yields 0% instead of a division blow-up', () {
      final coverage = calculator.coverageOf(
        recipes: [_recipe(5.0)],
        ageMonths: 2,
      );

      expect(coverage.requiredMg, 0);
      expect(coverage.percent, 0);
    });
  });

  group('sex is optional and never changes the result', () {
    test('null sex works — the profile field is nullable', () {
      expect(calculator.weeklyRequirementMg(18, null), closeTo(40.6, _epsilon));
    });

    test('every Sex value gives the same requirement as null', () {
      for (final ageMonths in [6, 18, 36, 59, 90]) {
        final baseline = calculator.weeklyRequirementMg(ageMonths, null);
        for (final sex in Sex.values) {
          expect(
            calculator.weeklyRequirementMg(ageMonths, sex),
            closeTo(baseline, _epsilon),
            reason: 'sex must not alter the requirement below 11 years',
          );
        }
      }
    });

    test('coverageOf accepts a null sex', () {
      final coverage = calculator.coverageOf(
        recipes: [_recipe(4.0)],
        ageMonths: 18,
      );

      expect(coverage.providedMg, closeTo(4.0, _epsilon));
      expect(coverage.requiredMg, closeTo(40.6, _epsilon));
    });
  });

  group('coverageOf', () {
    test('an empty recipe list covers 0%', () {
      final coverage = calculator.coverageOf(
        recipes: const [],
        ageMonths: 18,
        sex: Sex.female,
      );

      expect(coverage.providedMg, 0);
      expect(coverage.requiredMg, closeTo(40.6, _epsilon));
      expect(coverage.percent, 0);
      expect(coverage.meetsTarget, isFalse);
    });

    test('provided iron is the sum of the servings', () {
      final coverage = calculator.coverageOf(
        recipes: [
          _recipe(1.5, id: 1),
          _recipe(2.25, id: 2),
          _recipe(0.25, id: 3),
        ],
        ageMonths: 18,
      );

      expect(coverage.providedMg, closeTo(4.0, _epsilon));
    });

    test('percentage is provided/required x 100', () {
      // 6–11 months: 9.3 mg/day x 7 = 65.1 mg/week. Half of that is 50%.
      final coverage = calculator.coverageOf(
        recipes: [_recipe(65.1 / 2)],
        ageMonths: 9,
      );

      expect(coverage.percent, closeTo(50.0, 1e-6));
      expect(coverage.meetsTarget, isFalse);
    });

    test('meetsTarget flips exactly at 100%', () {
      final exactlyEnough = calculator.coverageOf(
        recipes: [_recipe(40.6)],
        ageMonths: 18,
      );

      expect(exactlyEnough.percent, closeTo(100.0, 1e-6));
      expect(exactlyEnough.meetsTarget, isTrue);
    });

    test('percent is clamped at 999 for absurd surpluses', () {
      final coverage = calculator.coverageOf(
        recipes: [_recipe(100000.0)],
        ageMonths: 18,
      );

      expect(coverage.percent, 999);
      expect(coverage.meetsTarget, isTrue);
    });

    test('a surplus below the clamp is reported as-is', () {
      // Twice the weekly requirement must read 200%, not be capped at 100.
      final coverage = calculator.coverageOf(
        recipes: [_recipe(40.6 * 2)],
        ageMonths: 18,
      );

      expect(coverage.percent, closeTo(200.0, 1e-6));
    });

    test(
      'recipes below the child age are still summed — this is arithmetic',
      () {
        // Filtering by suitability is the retriever's job (P2 RAG), not the
        // calculator's. The calculator must not silently drop data.
        final coverage = calculator.coverageOf(
          recipes: [_recipe(3.0, minAgeMonths: 24)],
          ageMonths: 8,
        );

        expect(coverage.providedMg, closeTo(3.0, _epsilon));
      },
    );
  });

  group('realistic case: 18-month-old with a full 7-day plan', () {
    // FAO/WHO 1–3 years band at 10% bioavailability: 5.8 mg/day.
    const dailyMg = 5.8;
    const weeklyMg = dailyMg * 7; // 40.6 mg/week.

    final week = <Recipe>[
      _recipe(4.2, id: 1), // sangrecita
      _recipe(3.1, id: 2), // lentejas con arroz
      _recipe(5.6, id: 3), // hígado de pollo
      _recipe(2.8, id: 4), // puré de espinaca
      _recipe(6.0, id: 5), // bazo guisado
      _recipe(3.9, id: 6), // pescado con quinua
      _recipe(4.4, id: 7), // relleno de sangrecita
    ]; // total = 30.0 mg

    test('the seven servings total 30.0 mg of iron', () {
      final coverage = calculator.coverageOf(
        recipes: week,
        ageMonths: 18,
        sex: Sex.male,
      );

      expect(week, hasLength(7));
      expect(coverage.providedMg, closeTo(30.0, 1e-9));
    });

    test('the weekly requirement is 40.6 mg', () {
      expect(
        calculator.weeklyRequirementMg(18, Sex.male),
        closeTo(weeklyMg, _epsilon),
      );
    });

    test('coverage is 73.89% and falls short of the target', () {
      final coverage = calculator.coverageOf(
        recipes: week,
        ageMonths: 18,
        sex: Sex.male,
      );

      // 30.0 / 40.6 x 100 = 73.8916256...
      expect(coverage.percent, closeTo(73.891625, 1e-5));
      expect(coverage.meetsTarget, isFalse);
    });

    test(
      'the same plan is computed identically without a sex or hemoglobin',
      () {
        // ADR-0007: a child with no CRED reading gets the same age-based figure.
        final withSex = calculator.coverageOf(
          recipes: week,
          ageMonths: 18,
          sex: Sex.male,
        );
        final withoutSex = calculator.coverageOf(recipes: week, ageMonths: 18);

        expect(withoutSex.providedMg, closeTo(withSex.providedMg, _epsilon));
        expect(withoutSex.requiredMg, closeTo(withSex.requiredMg, _epsilon));
        expect(withoutSex.percent, closeTo(withSex.percent, _epsilon));
      },
    );

    test('a ChildProfile born 18 months ago lands in the same band', () {
      final now = DateTime(2026, 7, 25);
      final child = ChildProfile(
        id: 'c1',
        name: 'Wawa',
        birthDate: DateTime(2025, 1, 25),
        region: Region.highlands,
        // hemoglobin deliberately absent — ADR-0007.
      );

      expect(child.ageMonthsAt(now), 18);
      expect(
        calculator.weeklyRequirementMg(child.ageMonthsAt(now), child.sex),
        closeTo(weeklyMg, _epsilon),
      );
    });
  });

  test('satisfies the IronCalculator interface', () {
    const IronCalculator asInterface = TableIronCalculator();

    expect(asInterface.weeklyRequirementMg(18, null), closeTo(40.6, _epsilon));
    expect(asInterface.coverageOf(recipes: const [], ageMonths: 18).percent, 0);
  });
}
