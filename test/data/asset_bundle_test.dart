import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The other data tests read the JSON straight off disk with `dart:io`, which
/// proves the files parse but *not* that they ship inside the app. If the
/// `assets:` block in `pubspec.yaml` is missing or misspelled, those tests stay
/// green while the app throws at startup on a real handset.
///
/// These tests go through `rootBundle`, which is the same path the app uses at
/// runtime, so a bundling mistake fails here instead of during the demo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const dataAssets = <String>[
    'assets/data/recetario_ins.json',
    'assets/data/ingredientes_regionales.json',
    'assets/data/requerimientos_hierro.json',
  ];

  for (final asset in dataAssets) {
    test('$asset is bundled and parses as JSON', () async {
      final raw = await rootBundle.loadString(asset);
      expect(raw, isNotEmpty, reason: '$asset is bundled but empty');

      final decoded = json.decode(raw);
      expect(
        decoded,
        anyOf(isA<Map<String, dynamic>>(), isA<List<dynamic>>()),
        reason: '$asset must decode to an object or an array',
      );
    });
  }

  test('the recipe corpus is not empty once bundled', () async {
    final raw = await rootBundle.loadString('assets/data/recetario_ins.json');
    final decoded = json.decode(raw);

    // Tolerate either a bare list or an object wrapping one, so this test does
    // not have to be rewritten if the envelope changes.
    final recipes = decoded is List
        ? decoded
        : (decoded as Map<String, dynamic>).values
              .whereType<List<dynamic>>()
              .first;

    expect(
      recipes,
      isNotEmpty,
      reason: 'Retrieval has nothing to ground the model with (ADR-0005)',
    );
  });
}
