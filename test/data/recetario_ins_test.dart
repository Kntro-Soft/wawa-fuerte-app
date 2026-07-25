/// Schema and safety checks for the bundled INS data assets.
///
/// These assets are the grounding that keeps Gemma from inventing clinical
/// content (ADR-0005), so a malformed or unsourced row is a defect, not a
/// cosmetic problem. The tests read the files straight off disk rather than
/// through `rootBundle` so they run under plain `flutter test`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wawafuerte/core/domain/child_profile.dart';
import 'package:wawafuerte/core/domain/recipe.dart';

/// Youngest age complementary feeding starts, per the INS recipe book.
const int kComplementaryFeedingStartMonths = 6;

/// Oldest age this corpus is written for, with headroom for later ranges.
const int kMaxPlausibleAgeMonths = 120;

Map<String, dynamic> _readJson(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: 'missing data asset: $path');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Region? _parseRegion(String? raw) {
  if (raw == null) return null;
  return Region.values.firstWhere(
    (r) => r.name == raw,
    orElse: () => throw FormatException('unknown region: $raw'),
  );
}

/// Builds a domain [Recipe] from a JSON row, which is what actually proves the
/// asset schema and the domain class have not drifted apart.
Recipe _toRecipe(Map<String, dynamic> json) {
  return Recipe(
    id: json['id'] as int,
    name: json['name'] as String,
    ingredients: (json['ingredients'] as List).cast<String>(),
    preparation: json['preparation'] as String,
    ironMg: (json['ironMg'] as num).toDouble(),
    minAgeMonths: json['minAgeMonths'] as int,
    referenceCostPen: (json['referenceCostPen'] as num).toDouble(),
    region: _parseRegion(json['region'] as String?),
  );
}

void main() {
  group('recetario_ins.json', () {
    late List<Map<String, dynamic>> rows;

    setUpAll(() {
      final doc = _readJson('assets/data/recetario_ins.json');
      rows = (doc['recipes'] as List).cast<Map<String, dynamic>>();
    });

    test('parses and is not empty', () {
      expect(rows, isNotEmpty);
    });

    test('every row maps onto the Recipe domain class', () {
      for (final row in rows) {
        expect(() => _toRecipe(row), returnsNormally, reason: 'row ${row['id']}');
      }
    });

    test('ids are present and unique', () {
      final ids = rows.map((r) => r['id']).toList();
      expect(ids, everyElement(isA<int>()));
      expect(ids.toSet().length, ids.length, reason: 'duplicate recipe id');
    });

    test('ironMg is present, non-null and never negative', () {
      for (final row in rows) {
        final iron = row['ironMg'];
        expect(iron, isNotNull, reason: 'recipe ${row['id']} has null ironMg');
        expect(iron, isA<num>(), reason: 'recipe ${row['id']} ironMg is not numeric');
        expect((iron as num) >= 0, isTrue,
            reason: 'recipe ${row['id']} has negative ironMg: $iron');
      }
    });

    test('ironMg stays inside a plausible per-serving range', () {
      // The richest serving in the INS book is ~11.7 mg. Anything far above that
      // means a transcription slip (a decimal comma read as a thousands
      // separator), which would silently inflate the coverage figure.
      for (final row in rows) {
        expect((row['ironMg'] as num) <= 40, isTrue,
            reason: 'recipe ${row['id']} has implausible ironMg: ${row['ironMg']}');
      }
    });

    test('minAgeMonths is at least the start of complementary feeding', () {
      for (final row in rows) {
        final age = row['minAgeMonths'] as int;
        expect(age >= kComplementaryFeedingStartMonths, isTrue,
            reason: 'recipe ${row['id']} would be served before 6 months: $age');
        expect(age <= kMaxPlausibleAgeMonths, isTrue,
            reason: 'recipe ${row['id']} has implausible minAgeMonths: $age');
      }
    });

    test('referenceCostPen is present and never negative', () {
      for (final row in rows) {
        final cost = row['referenceCostPen'];
        expect(cost, isA<num>(), reason: 'recipe ${row['id']}');
        expect((cost as num) >= 0, isTrue, reason: 'recipe ${row['id']}');
      }
    });

    test('name, preparation and ingredients are non-empty', () {
      for (final row in rows) {
        expect((row['name'] as String).trim(), isNotEmpty, reason: 'recipe ${row['id']}');
        expect((row['preparation'] as String).trim(), isNotEmpty,
            reason: 'recipe ${row['id']} has nothing for TTS to read');
        expect((row['ingredients'] as List), isNotEmpty, reason: 'recipe ${row['id']}');
      }
    });

    test('ingredients are lowercase, as the retriever matches on them', () {
      for (final row in rows) {
        for (final ingredient in (row['ingredients'] as List).cast<String>()) {
          expect(ingredient, ingredient.toLowerCase(),
              reason: 'recipe ${row['id']} ingredient not lowercase: $ingredient');
          expect(ingredient.trim(), isNotEmpty, reason: 'recipe ${row['id']}');
        }
      }
    });

    test('region is null or a valid Region name', () {
      for (final row in rows) {
        final region = row['region'] as String?;
        if (region != null) {
          expect(Region.values.map((r) => r.name), contains(region),
              reason: 'recipe ${row['id']} has unknown region: $region');
        }
      }
    });

    test('every recipe carries a source URL', () {
      for (final row in rows) {
        final source = row['source'] as String?;
        expect(source, isNotNull, reason: 'recipe ${row['id']} has no source');
        expect(source!, startsWith('http'), reason: 'recipe ${row['id']}');
      }
    });

    test('sources point at the official INS domain', () {
      for (final row in rows) {
        expect(row['source'] as String, contains('ins.gob.pe'),
            reason: 'recipe ${row['id']} is not sourced from INS');
      }
    });

    test('recipes are suitable exactly from their minimum age onwards', () {
      for (final row in rows) {
        final recipe = _toRecipe(row);
        expect(recipe.isSuitableFor(recipe.minAgeMonths), isTrue);
        expect(recipe.isSuitableFor(recipe.minAgeMonths - 1), isFalse);
      }
    });
  });

  group('ingredientes_regionales.json', () {
    late Map<String, dynamic> doc;

    setUpAll(() => doc = _readJson('assets/data/ingredientes_regionales.json'));

    test('covers every Region in the domain enum', () {
      final regions = (doc['regions'] as Map<String, dynamic>).keys.toSet();
      expect(regions, Region.values.map((r) => r.name).toSet());
    });

    test('every ingredient is well formed and sourced', () {
      final regions = doc['regions'] as Map<String, dynamic>;
      for (final entry in regions.entries) {
        final items = (entry.value as List).cast<Map<String, dynamic>>();
        expect(items, isNotEmpty, reason: 'region ${entry.key} has no ingredients');
        for (final item in items) {
          final name = item['nombre'] as String;
          expect(name.trim(), isNotEmpty, reason: entry.key);
          expect(name, name.toLowerCase(), reason: '$name is not lowercase');

          final iron = item['hierro_mg_por_100g'];
          expect(iron, isNotNull, reason: '$name has null iron');
          expect(iron, isA<num>(), reason: '$name iron is not numeric');
          expect((iron as num) >= 0, isTrue, reason: '$name has negative iron');
          // No whole food reaches 100 mg per 100 g; that would be a typo.
          expect(iron <= 100, isTrue, reason: '$name has implausible iron: $iron');

          final cost = item['costo_referencial_pen'];
          expect(cost, isA<num>(), reason: name);
          expect((cost as num) >= 0, isTrue, reason: '$name has negative cost');

          final source = item['source'] as String?;
          expect(source, isNotNull, reason: '$name has no source');
          expect(source!, startsWith('http'), reason: name);
        }
      }
    });

    test('names are unique within each region', () {
      final regions = doc['regions'] as Map<String, dynamic>;
      for (final entry in regions.entries) {
        final names = (entry.value as List)
            .cast<Map<String, dynamic>>()
            .map((i) => i['nombre'] as String)
            .toList();
        expect(names.toSet().length, names.length,
            reason: 'duplicate ingredient in region ${entry.key}');
      }
    });

    test('estimated costs are flagged as estimates, never passed off as sourced', () {
      final regions = doc['regions'] as Map<String, dynamic>;
      for (final entry in regions.entries) {
        for (final item in (entry.value as List).cast<Map<String, dynamic>>()) {
          expect(item['costo_referencial_es_estimado'], isTrue,
              reason: '${item['nombre']} claims an official cost we do not have');
        }
      }
    });
  });

  group('requerimientos_hierro.json', () {
    late List<Map<String, dynamic>> ranges;
    late Map<String, dynamic> doc;

    setUpAll(() {
      doc = _readJson('assets/data/requerimientos_hierro.json');
      ranges = (doc['ranges'] as List).cast<Map<String, dynamic>>();
    });

    test('parses and is not empty', () => expect(ranges, isNotEmpty));

    test('starts at complementary feeding and has ordered, non-overlapping ranges', () {
      expect(ranges.first['minAgeMonths'], kComplementaryFeedingStartMonths);
      for (var i = 0; i < ranges.length; i++) {
        final min = ranges[i]['minAgeMonths'] as int;
        final max = ranges[i]['maxAgeMonths'] as int;
        expect(min >= kComplementaryFeedingStartMonths, isTrue,
            reason: 'range ${ranges[i]['id']} starts before 6 months');
        expect(max > min, isTrue, reason: 'range ${ranges[i]['id']} is inverted');
        if (i > 0) {
          expect(min, (ranges[i - 1]['maxAgeMonths'] as int) + 1,
              reason: 'gap or overlap before range ${ranges[i]['id']}');
        }
      }
    });

    test('every bio-availability level has a positive daily requirement', () {
      for (final range in ranges) {
        final daily = range['dailyMg'] as Map<String, dynamic>;
        expect(daily.keys.toSet(), {'15', '12', '10', '5'},
            reason: 'range ${range['id']} is missing a bio-availability level');
        for (final entry in daily.entries) {
          expect(entry.value, isA<num>(), reason: range['id'].toString());
          expect((entry.value as num) > 0, isTrue,
              reason: 'range ${range['id']} level ${entry.key} is not positive');
        }
      }
    });

    test('lower bio-availability always demands more iron', () {
      for (final range in ranges) {
        final daily = range['dailyMg'] as Map<String, dynamic>;
        final ordered = ['15', '12', '10', '5']
            .map((k) => (daily[k] as num).toDouble())
            .toList();
        for (var i = 1; i < ordered.length; i++) {
          expect(ordered[i] > ordered[i - 1], isTrue,
              reason: 'range ${range['id']} requirements are not monotonic');
        }
      }
    });

    test('weekly is exactly seven times daily', () {
      for (final range in ranges) {
        final daily = range['dailyMg'] as Map<String, dynamic>;
        final weekly = range['weeklyMg'] as Map<String, dynamic>;
        for (final entry in daily.entries) {
          final expected = (entry.value as num).toDouble() * 7;
          expect((weekly[entry.key] as num).toDouble(), closeTo(expected, 0.05),
              reason: 'range ${range['id']} level ${entry.key}');
        }
      }
    });

    test('the default bio-availability level exists in every range', () {
      final defaultLevel = doc['defaultBioavailability'] as String;
      for (final range in ranges) {
        expect((range['dailyMg'] as Map<String, dynamic>)[defaultLevel], isNotNull,
            reason: 'range ${range['id']} lacks the default level $defaultLevel');
      }
    });

    test('every range carries a source URL', () {
      for (final range in ranges) {
        final source = range['source'] as String?;
        expect(source, isNotNull, reason: 'range ${range['id']} has no source');
        expect(source!, startsWith('http'), reason: range['id'].toString());
      }
    });

    test('an age in the infant range resolves to exactly one requirement', () {
      for (final ageMonths in [6, 11, 12, 47, 48]) {
        final matches = ranges.where((r) =>
            ageMonths >= (r['minAgeMonths'] as int) &&
            ageMonths <= (r['maxAgeMonths'] as int));
        expect(matches.length, 1, reason: 'age $ageMonths months');
      }
    });
  });

  group('cross-file consistency', () {
    test('no recipe is suitable below the youngest requirement range', () {
      final recipes = (_readJson('assets/data/recetario_ins.json')['recipes'] as List)
          .cast<Map<String, dynamic>>();
      final ranges = (_readJson('assets/data/requerimientos_hierro.json')['ranges'] as List)
          .cast<Map<String, dynamic>>();
      final youngest = ranges
          .map((r) => r['minAgeMonths'] as int)
          .reduce((a, b) => a < b ? a : b);
      for (final recipe in recipes) {
        expect((recipe['minAgeMonths'] as int) >= youngest, isTrue,
            reason: 'recipe ${recipe['id']} has no requirement range to be scored against');
      }
    });
  });
}
