/// The app's small key/value corner: settings that are neither health data nor
/// worth a table of their own.
///
/// OWNER: P4 (@Eric396).
///
/// The caregiver's name lived here first, with the table handling inlined in
/// `SqliteCaregiverRepository`. The device reference the hosted agent keys on
/// (ADR-0015) needs exactly the same storage, so the table handling moved here
/// rather than being written a second time — two copies of a lazy
/// `CREATE TABLE IF NOT EXISTS` is two chances to disagree about the schema.
///
/// Nothing in here is health data about a minor: that lives in `child_profiles`
/// and never leaves the device (ADR-0013).
library;

import 'package:sqflite/sqflite.dart';

abstract interface class KeyValueStore {
  /// The stored value, or null when the key was never written.
  Future<String?> read(String key);

  /// Stores [value] under [key]. A null [value] deletes the key.
  Future<void> write(String key, String? value);
}

class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, String>? seed]) : _values = {...?seed};

  final Map<String, String> _values;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      _values.remove(key);
      return;
    }
    _values[key] = value;
  }
}

class SqliteKeyValueStore implements KeyValueStore {
  SqliteKeyValueStore(this._db);

  final Database _db;

  static const String table = 'app_settings';

  bool _tableReady = false;

  /// Created lazily with `CREATE TABLE IF NOT EXISTS` rather than in the
  /// database's `_onCreate`, so adding a setting needs no schema-version bump
  /// and no migration on phones that already have a database from an earlier
  /// build.
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
  Future<String?> read(String key) async {
    await _ensureTable();
    final rows = await _db.query(
      table,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<void> write(String key, String? value) async {
    await _ensureTable();

    if (value == null) {
      await _db.delete(table, where: 'key = ?', whereArgs: [key]);
      return;
    }

    await _db.insert(table, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
