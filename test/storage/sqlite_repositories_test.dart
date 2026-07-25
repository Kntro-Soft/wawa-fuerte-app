/// Storage tests. They run through `sqflite_common_ffi`, so `flutter test` on a
/// laptop or in CI exercises the real SQLite engine with no emulator and no
/// handset attached.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wawafuerte/core/domain/child_profile.dart';
import 'package:wawafuerte/core/domain/recipe.dart';
import 'package:wawafuerte/core/domain/weekly_plan.dart';
import 'package:wawafuerte/core/storage/database.dart';
import 'package:wawafuerte/core/storage/sqlite_repositories.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late SqliteProfileRepository profiles;
  late SqlitePlanRepository plans;

  setUp(() async {
    db = await openDatabaseAt(inMemoryDatabasePath);
    profiles = SqliteProfileRepository(db);
    plans = SqlitePlanRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SqliteProfileRepository', () {
    test('saves a profile and reads it back whole', () async {
      await profiles.save(_child(id: 'c1', name: 'Luana'));

      final found = await profiles.findById('c1');

      expect(found, isNotNull);
      expect(found!.name, 'Luana');
      expect(found.birthDate, DateTime(2024, 3, 15));
      expect(found.region, Region.highlands);
      expect(found.sex, Sex.female);
      expect(found.hemoglobin, 10.4);
      expect(found.hemoglobinDate, DateTime(2026, 5, 2));
    });

    test('findById returns null for an unknown child', () async {
      expect(await profiles.findById('nope'), isNull);
    });

    test('stores several children and lists them all', () async {
      await profiles.save(_child(id: 'c1', name: 'Luana'));
      await profiles.save(_child(id: 'c2', name: 'Mateo'));
      await profiles.save(_child(id: 'c3', name: 'Nayra'));

      final all = await profiles.findAll();

      expect(all, hasLength(3));
      expect(all.map((c) => c.id), containsAll(<String>['c1', 'c2', 'c3']));
    });

    // ADR-0007: hemoglobin is optional everywhere and must never block.
    test('persists a profile with no hemoglobin as NULL', () async {
      await profiles.save(
        ChildProfile(
          id: 'c-no-cred',
          name: 'Sin carné',
          birthDate: DateTime(2025, 1, 20),
          region: Region.jungle,
        ),
      );

      final found = await profiles.findById('c-no-cred');

      expect(found, isNotNull);
      expect(found!.hemoglobin, isNull);
      expect(found.hemoglobinDate, isNull);
      expect(found.hasHemoglobin, isFalse);
      expect(found.sex, isNull);
      expect(found.name, 'Sin carné');
      expect(found.region, Region.jungle);

      final rows = await db.query(
        tableChildProfiles,
        where: 'id = ?',
        whereArgs: ['c-no-cred'],
      );
      expect(rows.single['hemoglobin'], isNull);
    });

    test('saving the same id twice updates instead of duplicating', () async {
      await profiles.save(_child(id: 'c1', name: 'Luana'));
      await profiles.save(
        _child(
          id: 'c1',
          name: 'Luana',
        ).copyWith(name: 'Luana M.', hemoglobin: 11.9),
      );

      final all = await profiles.findAll();

      expect(all, hasLength(1));
      expect(all.single.name, 'Luana M.');
      expect(all.single.hemoglobin, 11.9);
    });

    test('an updated profile can drop its hemoglobin back to null', () async {
      await profiles.save(_child(id: 'c1', name: 'Luana'));
      await profiles.save(
        ChildProfile(
          id: 'c1',
          name: 'Luana',
          birthDate: DateTime(2024, 3, 15),
          region: Region.highlands,
        ),
      );

      expect((await profiles.findById('c1'))!.hemoglobin, isNull);
    });

    test('delete removes the child', () async {
      await profiles.save(_child(id: 'c1', name: 'Luana'));

      await profiles.delete('c1');

      expect(await profiles.findById('c1'), isNull);
      expect(await profiles.findAll(), isEmpty);
    });
  });

  group('SqlitePlanRepository', () {
    final weekStart = DateTime(2026, 7, 20);

    setUp(() async {
      await profiles.save(_child(id: 'c1', name: 'Luana'));
    });

    test('latestFor returns null when the child has no plan', () async {
      expect(await plans.latestFor('c1'), isNull);
    });

    test('saves a plan and reads back its 7 days and coverage', () async {
      await plans.save(_plan(childId: 'c1', weekStart: weekStart));

      final found = await plans.latestFor('c1');

      expect(found, isNotNull);
      expect(found!.childId, 'c1');
      expect(found.weekStart, weekStart);
      expect(found.days, hasLength(7));
      expect(found.days.map((d) => d.dayIndex), [0, 1, 2, 3, 4, 5, 6]);
      expect(found.coverage.providedMg, 27.5);
      expect(found.coverage.requiredMg, 35);
      expect(found.coverage.meetsTarget, isFalse);

      final day3 = found.days[3];
      expect(day3.recipe.name, 'Sangrecita día 3');
      expect(day3.recipe.ingredients, ['sangrecita', 'arroz', 'zanahoria']);
      expect(day3.recipe.ironMg, closeTo(3.5, 1e-9));
      expect(day3.recipe.region, Region.highlands);
      expect(day3.prepared, isFalse);
    });

    test(
      're-saving the same week replaces it without duplicating days',
      () async {
        await plans.save(_plan(childId: 'c1', weekStart: weekStart));
        await plans.save(
          _plan(childId: 'c1', weekStart: weekStart, providedMg: 31),
        );

        final found = await plans.latestFor('c1');

        expect(found!.days, hasLength(7));
        expect(found.coverage.providedMg, 31);
        expect(await db.query(tablePlanDays), hasLength(7));
      },
    );

    test(
      'latestFor returns the most recent week when history exists',
      () async {
        await plans.save(
          _plan(childId: 'c1', weekStart: DateTime(2026, 7, 13)),
        );
        await plans.save(_plan(childId: 'c1', weekStart: weekStart));

        final found = await plans.latestFor('c1');

        expect(found!.weekStart, weekStart);
        // The older week is kept for the Flow D follow-up, not overwritten.
        expect(await db.query(tableWeeklyPlans), hasLength(2));
      },
    );

    test('findAllFor returns all historical plans for a child ordered DESC', () async {
      final week1 = DateTime(2026, 7, 6);
      final week2 = DateTime(2026, 7, 13);
      final week3 = DateTime(2026, 7, 20);

      await plans.save(_plan(childId: 'c1', weekStart: week1));
      await plans.save(_plan(childId: 'c1', weekStart: week3));
      await plans.save(_plan(childId: 'c1', weekStart: week2));

      final all = await plans.findAllFor('c1');

      expect(all, hasLength(3));
      expect(all[0].weekStart, week3);
      expect(all[1].weekStart, week2);
      expect(all[2].weekStart, week1);
    });

    test('plans of different children do not mix', () async {
      await profiles.save(_child(id: 'c2', name: 'Mateo'));
      await plans.save(_plan(childId: 'c1', weekStart: weekStart));

      expect(await plans.latestFor('c2'), isNull);
      expect(await plans.latestFor('c1'), isNotNull);
    });

    test('markPrepared changes only the given day and persists it', () async {
      await plans.save(_plan(childId: 'c1', weekStart: weekStart));

      await plans.markPrepared(
        childId: 'c1',
        weekStart: weekStart,
        dayIndex: 2,
        prepared: true,
      );

      final found = await plans.latestFor('c1');
      expect(found!.days[2].prepared, isTrue);
      expect(found.preparedCount, 1);
      expect(
        found.days.where((d) => d.dayIndex != 2).every((d) => !d.prepared),
        isTrue,
      );
    });

    test('markPrepared can untick a day again', () async {
      await plans.save(_plan(childId: 'c1', weekStart: weekStart));

      await plans.markPrepared(
        childId: 'c1',
        weekStart: weekStart,
        dayIndex: 5,
        prepared: true,
      );
      await plans.markPrepared(
        childId: 'c1',
        weekStart: weekStart,
        dayIndex: 5,
        prepared: false,
      );

      expect((await plans.latestFor('c1'))!.preparedCount, 0);
    });

    test('markPrepared on an unknown week is a silent no-op', () async {
      await plans.save(_plan(childId: 'c1', weekStart: weekStart));

      await plans.markPrepared(
        childId: 'c1',
        weekStart: DateTime(2026, 1, 5),
        dayIndex: 0,
        prepared: true,
      );

      expect((await plans.latestFor('c1'))!.preparedCount, 0);
    });

    test('deleting a child takes their plans with it', () async {
      await plans.save(_plan(childId: 'c1', weekStart: weekStart));

      await profiles.delete('c1');

      expect(await plans.latestFor('c1'), isNull);
      expect(await db.query(tablePlanDays), isEmpty);
    });
  });

  test('data survives closing and reopening the database', () async {
    final path = '${await databaseFactory.getDatabasesPath()}/reopen_test.db';
    await databaseFactory.deleteDatabase(path);

    var handle = await openDatabaseAt(path);
    await SqliteProfileRepository(handle).save(_child(id: 'c1', name: 'Luana'));
    await SqlitePlanRepository(
      handle,
    ).save(_plan(childId: 'c1', weekStart: DateTime(2026, 7, 20)));
    await handle.close();

    handle = await openDatabaseAt(path);
    addTearDown(() async {
      await handle.close();
      await databaseFactory.deleteDatabase(path);
    });

    expect(await SqliteProfileRepository(handle).findAll(), hasLength(1));
    expect(await SqlitePlanRepository(handle).latestFor('c1'), isNotNull);
  });
}

ChildProfile _child({required String id, required String name}) => ChildProfile(
  id: id,
  name: name,
  birthDate: DateTime(2024, 3, 15),
  region: Region.highlands,
  sex: Sex.female,
  hemoglobin: 10.4,
  hemoglobinDate: DateTime(2026, 5, 2),
);

WeeklyPlan _plan({
  required String childId,
  required DateTime weekStart,
  double providedMg = 27.5,
}) => WeeklyPlan(
  childId: childId,
  weekStart: weekStart,
  days: [
    for (var i = 0; i < 7; i++)
      PlanDay(
        dayIndex: i,
        recipe: Recipe(
          id: 100 + i,
          name: 'Sangrecita día $i',
          ingredients: const ['sangrecita', 'arroz', 'zanahoria'],
          preparation: 'Saltear la sangrecita y servir con arroz.',
          ironMg: 3.5,
          minAgeMonths: 6,
          referenceCostPen: 2.5,
          region: Region.highlands,
        ),
      ),
  ],
  coverage: IronCoverage(providedMg: providedMg, requiredMg: 35),
);
