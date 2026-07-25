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
/// It lives in the shared key/value table instead — see [KeyValueStore], which
/// owns the lazy table creation.
library;

import 'package:sqflite/sqflite.dart';

import 'key_value_store.dart';

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
  SqliteCaregiverRepository(Database db) : this.store(SqliteKeyValueStore(db));

  /// Takes the store directly, so `main()` can share one instance with the
  /// device reference and a test can back it with [InMemoryKeyValueStore].
  SqliteCaregiverRepository.store(this._store);

  final KeyValueStore _store;

  static const String key = 'caregiver_name';

  @override
  Future<String?> read() async =>
      normaliseCaregiverName(await _store.read(key));

  /// Normalising on the way in *and* on the way out is deliberate: a row
  /// written by an earlier build could still hold whitespace.
  @override
  Future<void> write(String? name) =>
      _store.write(key, normaliseCaregiverName(name));
}
