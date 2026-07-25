/// SQLite-backed repositories — the real implementations behind
/// `repositories.dart`.
///
/// OWNER: P4 (@Eric396).
///
/// `InMemoryProfileRepository` / `InMemoryPlanRepository` are the living spec:
/// these classes must behave the same way, only durably. Nothing here talks to
/// a network — there is none (ADR-0002).
library;

import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/child_profile.dart';
import '../domain/recipe.dart';
import '../domain/weekly_plan.dart';
import 'database.dart';
import 'repositories.dart';

class SqliteProfileRepository implements ProfileRepository {
  SqliteProfileRepository(this._db);

  final Database _db;

  @override
  Future<List<ChildProfile>> findAll() async {
    final rows = await _db.query(
      tableChildProfiles,
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(_profileFromRow).toList();
  }

  @override
  Future<ChildProfile?> findById(String id) async {
    final rows = await _db.query(
      tableChildProfiles,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _profileFromRow(rows.first);
  }

  @override
  Future<void> save(ChildProfile profile) async {
    // `replace` on the `id` primary key: saving the same child twice updates
    // the row instead of duplicating it.
    await _db.insert(
      tableChildProfiles,
      _profileToRow(profile),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete(tableChildProfiles, where: 'id = ?', whereArgs: [id]);
  }
}

class SqlitePlanRepository implements PlanRepository {
  SqlitePlanRepository(this._db);

  final Database _db;

  @override
  Future<WeeklyPlan?> latestFor(String childId) async {
    final planRows = await _db.query(
      tableWeeklyPlans,
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'week_start DESC',
      limit: 1,
    );
    if (planRows.isEmpty) return null;

    final planRow = planRows.first;
    final weekStart = planRow['week_start']! as String;

    final dayRows = await _db.query(
      tablePlanDays,
      where: 'child_id = ? AND week_start = ?',
      whereArgs: [childId, weekStart],
      orderBy: 'day_index ASC',
    );

    return WeeklyPlan(
      childId: childId,
      weekStart: DateTime.parse(weekStart),
      days: dayRows.map(_planDayFromRow).toList(),
      coverage: IronCoverage(
        providedMg: (planRow['provided_mg']! as num).toDouble(),
        requiredMg: (planRow['required_mg']! as num).toDouble(),
      ),
    );
  }

  @override
  Future<void> save(WeeklyPlan plan) async {
    final weekStart = plan.weekStart.toIso8601String();

    await _db.transaction((txn) async {
      // Drop the previous version of this same week first; the cascade takes
      // its days with it, so re-saving never leaves stale rows behind.
      await txn.delete(
        tableWeeklyPlans,
        where: 'child_id = ? AND week_start = ?',
        whereArgs: [plan.childId, weekStart],
      );

      await txn.insert(tableWeeklyPlans, {
        'child_id': plan.childId,
        'week_start': weekStart,
        'provided_mg': plan.coverage.providedMg,
        'required_mg': plan.coverage.requiredMg,
      });

      for (final day in plan.days) {
        await txn.insert(
          tablePlanDays,
          _planDayToRow(plan.childId, weekStart, day),
        );
      }
    });
  }

  @override
  Future<void> markPrepared({
    required String childId,
    required DateTime weekStart,
    required int dayIndex,
    required bool prepared,
  }) async {
    // No row for that child/week/day means nothing to record — same silent
    // no-op as the in-memory repository.
    await _db.update(
      tablePlanDays,
      {'prepared': prepared ? 1 : 0},
      where: 'child_id = ? AND week_start = ? AND day_index = ?',
      whereArgs: [childId, weekStart.toIso8601String(), dayIndex],
    );
  }
}

// --- Row mapping -------------------------------------------------------------

Map<String, Object?> _profileToRow(ChildProfile profile) => {
  'id': profile.id,
  'name': profile.name,
  'birth_date': profile.birthDate.toIso8601String(),
  'region': profile.region.name,
  'sex': profile.sex?.name,
  // Stays NULL when the family has no CRED booklet at hand (ADR-0007). It is
  // never defaulted to a sentinel value.
  'hemoglobin': profile.hemoglobin,
  'hemoglobin_date': profile.hemoglobinDate?.toIso8601String(),
};

ChildProfile _profileFromRow(Map<String, Object?> row) => ChildProfile(
  id: row['id']! as String,
  name: row['name']! as String,
  birthDate: DateTime.parse(row['birth_date']! as String),
  region: _enumByName(Region.values, row['region']! as String, Region.coast),
  sex: _nullableEnumByName(Sex.values, row['sex'] as String?),
  hemoglobin: (row['hemoglobin'] as num?)?.toDouble(),
  hemoglobinDate: _parseNullableDate(row['hemoglobin_date'] as String?),
);

Map<String, Object?> _planDayToRow(
  String childId,
  String weekStart,
  PlanDay day,
) => {
  'child_id': childId,
  'week_start': weekStart,
  'day_index': day.dayIndex,
  'prepared': day.prepared ? 1 : 0,
  // The recipe is snapshotted, not referenced: a plan must stay readable even
  // if the bundled INS corpus changes in a later app version.
  'recipe_id': day.recipe.id,
  'recipe_name': day.recipe.name,
  'recipe_ingredients': jsonEncode(day.recipe.ingredients),
  'recipe_preparation': day.recipe.preparation,
  'recipe_iron_mg': day.recipe.ironMg,
  'recipe_min_age_months': day.recipe.minAgeMonths,
  'recipe_reference_cost_pen': day.recipe.referenceCostPen,
  'recipe_region': day.recipe.region?.name,
};

PlanDay _planDayFromRow(Map<String, Object?> row) => PlanDay(
  dayIndex: (row['day_index']! as num).toInt(),
  prepared: (row['prepared']! as num) != 0,
  recipe: Recipe(
    id: (row['recipe_id']! as num).toInt(),
    name: row['recipe_name']! as String,
    ingredients: (jsonDecode(row['recipe_ingredients']! as String) as List)
        .cast<String>(),
    preparation: row['recipe_preparation']! as String,
    ironMg: (row['recipe_iron_mg']! as num).toDouble(),
    minAgeMonths: (row['recipe_min_age_months']! as num).toInt(),
    referenceCostPen: (row['recipe_reference_cost_pen']! as num).toDouble(),
    region: _nullableEnumByName(Region.values, row['recipe_region'] as String?),
  ),
);

DateTime? _parseNullableDate(String? value) =>
    value == null ? null : DateTime.parse(value);

T? _nullableEnumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

T _enumByName<T extends Enum>(List<T> values, String name, T fallback) =>
    _nullableEnumByName(values, name) ?? fallback;
