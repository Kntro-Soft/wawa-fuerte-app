/// Where the caregiver's own name is kept.
///
/// OWNER: P3 (UI).
///
/// Flow 0 asks for this name **once**, optionally, and only to personalise a
/// greeting: there is no account and nobody to authenticate against (ADR-0002).
/// It is therefore not health data and it does not belong in `child_profiles`,
/// which is keyed by child and cascades on delete (ADR-0013) — a caregiver who
/// removes her only child's profile should not lose her own name with it.
///
/// It lives in its own key/value table instead. The table is created lazily on
/// first use with `CREATE TABLE IF NOT EXISTS` rather than in `_onCreate`, so
/// this feature needs no schema-version bump and no migration on phones that
/// already have a database from an earlier build.
library;

import 'package:sqflite/sqflite.dart';

abstract interface class CaregiverRepository {
  /// The stored name, or null when she never gave one. Never a placeholder:
  /// the greeting drops the name rather than inventing "Usuario".
  Future<String?> read();

  /// Stores [name]. Whitespace-only or null clears it — an empty string is not
  /// a name and must not come back as one.
  Future<void> write(String? name);
}

/// Normalises a typed name the same way in every implementation.
String? normaliseCaregiverName(String? raw) {
  final trimmed = raw?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

class InMemoryCaregiverRepository implements CaregiverRepository {
  InMemoryCaregiverRepository([String? seed])
    : _name = normaliseCaregiverName(seed);

  String? _name;

  @override
  Future<String?> read() async => _name;

  @override
  Future<void> write(String? name) async {
    _name = normaliseCaregiverName(name);
  }
}

class SqliteCaregiverRepository implements CaregiverRepository {
  SqliteCaregiverRepository(this._db);

  final Database _db;

  static const String table = 'app_settings';
  static const String _key = 'caregiver_name';

  bool _tableReady = false;

  Future<void> _ensureTable() async {
    if (_tableReady) return;
    await _db.execute(
      'CREATE TABLE IF NOT EXISTS $table ('
      'key TEXT PRIMARY KEY, '
      'value TEXT NOT NULL)',
    );
    _tableReady = true;
  }

  @override
  Future<String?> read() async {
    await _ensureTable();
    final rows = await _db.query(
      table,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return normaliseCaregiverName(rows.first['value'] as String?);
  }

  @override
  Future<void> write(String? name) async {
    await _ensureTable();
    final value = normaliseCaregiverName(name);

    if (value == null) {
      await _db.delete(table, where: 'key = ?', whereArgs: [_key]);
      return;
    }

    await _db.insert(table, {
      'key': _key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
