# 0013. Local persistence schema for profiles and plans

- Status: Accepted
- Date: 2026-07-25
- Deciders: Kntro-Soft team

## Context

Everything the app stores stays on the phone (ADR-0002), and what it stores is health data about
minors: children's names, dates of birth and — when the family has the CRED booklet at hand —
hemoglobin readings. SQLite is already a dependency of the retrieval layer (ADR-0006), so the
question is not *which engine* but *what shape* the data takes.

Three things about the domain constrain the schema:

- A family registers **several children with no limit** (Flow A/E), so profiles are a plain table
  keyed by the child's id, never a single-row "current child".
- **Hemoglobin is optional and never blocking** (ADR-0007). The column has to accept NULL rather
  than default to `0`, `-1` or any other sentinel that code could mistake for a reading.
- Flow D looks *back* at the previous week ("cumpliste 5 de 7 recetas la semana pasada"), so plans
  are history, not a single current value, and the per-day `prepared` tick has to survive the app
  being closed.

The awkward part is the recipe inside each plan day. Recipes come from the bundled INS corpus,
which is a build-time asset (ADR-0006) with its own integer ids — it is not a table the app writes
to and it changes when a new app version ships.

## Decision

Three tables, defined in `lib/core/storage/database.dart`:

```sql
child_profiles(id PK, name, birth_date, region, sex, hemoglobin, hemoglobin_date)
weekly_plans(child_id, week_start, provided_mg, required_mg,
             PRIMARY KEY (child_id, week_start))
plan_days(child_id, week_start, day_index, prepared, recipe_* …,
          PRIMARY KEY (child_id, week_start, day_index))
```

- **`hemoglobin` and `hemoglobin_date` are nullable columns** and are written as SQL `NULL` when
  absent. No sentinel value, no default.
- **Plans are keyed by `(child_id, week_start)`, so history accumulates.** `latestFor` is
  `ORDER BY week_start DESC LIMIT 1`. Saving a plan for a week that already exists replaces that
  week only. This is a superset of `InMemoryPlanRepository`, which keeps one plan per child; the
  in-memory version remains the behavioural spec for everything else.
- **Each plan day snapshots its recipe** (name, ingredients as a JSON array, preparation, iron,
  minimum age, cost, region) instead of holding a foreign key into the asset corpus.
- **Dates and enums are stored as text** — ISO-8601 for dates, the Dart enum `name` for `region`
  and `sex` — so a database dumped during the demo is readable without the app.
- **`PRAGMA foreign_keys = ON` is set on every open**, with `ON DELETE CASCADE` from profile to
  plans to days: deleting a child erases their health data completely, in one statement.

## Consequences

- A plan generated today still renders after an app update that reworks the recipe corpus, because
  it carries its own copy of what was actually recommended. Denormalisation is the price; the
  volume is seven rows per child per week, which is nothing.
- Correcting a recipe in the corpus does **not** retroactively fix plans already generated. That is
  the intended reading: a past plan is a record of what the caregiver was told, not a live view.
- Flow D gets the previous week for free, and `prepared` ticks are durable — `markPrepared` is a
  single-row `UPDATE`, so ticking one day cannot disturb another.
- Storing dates as text means comparisons are lexicographic. ISO-8601 sorts correctly, but any
  future date arithmetic must go through Dart, not SQL.
- The schema starts at version 1 with an `onUpgrade` hook already wired, so the first migration
  after the demo does not need to restructure how the database is opened.
- Tests run against the same schema through `sqflite_common_ffi`, so `flutter test` verifies real
  SQL — including the NULL hemoglobin path — on a laptop, with no emulator and no handset.
