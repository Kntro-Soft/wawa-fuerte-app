/// Schema and migrations for the on-device database.
///
/// OWNER: P4 (@Eric396).
///
/// There is no server and nothing syncs (ADR-0002): this file is the only
/// place where health data about a minor is ever written, and it writes it to
/// the phone's private app directory.
library;

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Bump this whenever [_onCreate] changes and add the matching step to
/// [_onUpgrade].
const int kDatabaseVersion = 1;

const String kDatabaseFileName = 'wawafuerte.db';

/// Children registered on this phone. A family may register several; there is
/// no limit (Flow A/E).
const String tableChildProfiles = 'child_profiles';

/// One row per generated plan. History is kept, not overwritten, so Flow D can
/// look back at the previous week.
const String tableWeeklyPlans = 'weekly_plans';

/// The seven days of a plan, including the caregiver's `prepared` tick.
const String tablePlanDays = 'plan_days';

/// Opens (creating it on first run) the app database in the default location.
Future<Database> openAppDatabase({String? fileName}) async {
  final directory = await getDatabasesPath();
  return openDatabaseAt(p.join(directory, fileName ?? kDatabaseFileName));
}

/// Opens the database at an explicit [path], or in memory when [path] is
/// [inMemoryDatabasePath]. Tests use this with `sqflite_common_ffi`.
Future<Database> openDatabaseAt(String path) {
  return openDatabase(
    path,
    version: kDatabaseVersion,
    onConfigure: _onConfigure,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );
}

Future<void> _onConfigure(Database db) async {
  // Off by default in SQLite; without it deleting a child would leave its
  // plans behind.
  await db.execute('PRAGMA foreign_keys = ON');
}

Future<void> _onCreate(Database db, int version) async {
  await db.execute('''
CREATE TABLE $tableChildProfiles (
  id              TEXT    PRIMARY KEY,
  name            TEXT    NOT NULL,
  birth_date      TEXT    NOT NULL,
  region          TEXT    NOT NULL,
  sex             TEXT,
  hemoglobin      REAL,
  hemoglobin_date TEXT
)
''');

  await db.execute('''
CREATE TABLE $tableWeeklyPlans (
  child_id    TEXT NOT NULL,
  week_start  TEXT NOT NULL,
  provided_mg REAL NOT NULL,
  required_mg REAL NOT NULL,
  PRIMARY KEY (child_id, week_start),
  FOREIGN KEY (child_id) REFERENCES $tableChildProfiles (id) ON DELETE CASCADE
)
''');

  await db.execute('''
CREATE TABLE $tablePlanDays (
  child_id                 TEXT    NOT NULL,
  week_start               TEXT    NOT NULL,
  day_index                INTEGER NOT NULL,
  prepared                 INTEGER NOT NULL DEFAULT 0,
  recipe_id                INTEGER NOT NULL,
  recipe_name              TEXT    NOT NULL,
  recipe_ingredients       TEXT    NOT NULL,
  recipe_preparation       TEXT    NOT NULL,
  recipe_iron_mg           REAL    NOT NULL,
  recipe_min_age_months    INTEGER NOT NULL,
  recipe_reference_cost_pen REAL   NOT NULL,
  recipe_region            TEXT,
  PRIMARY KEY (child_id, week_start, day_index),
  FOREIGN KEY (child_id, week_start)
    REFERENCES $tableWeeklyPlans (child_id, week_start) ON DELETE CASCADE
)
''');

  // Flow E lists every child's latest plan on the home screen.
  await db.execute(
    'CREATE INDEX idx_weekly_plans_child_week '
    'ON $tableWeeklyPlans (child_id, week_start DESC)',
  );
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  // Version 1 is the initial schema; there is nothing to migrate from yet.
  // Each future version adds its own `if (oldVersion < n)` step here.
}
