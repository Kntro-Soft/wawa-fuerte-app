// OWNER: P3 (UI) — usa la base de datos existente
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class AppSettingsRepository {
  AppSettingsRepository({Database? database, this.inMemory = false})
    : _db = database;

  final Database? _db;
  Database? _lazyDb;
  final bool inMemory;
  final Map<String, String> _fakeDb = {};

  /// Abre la base de datos separada `wawa_settings.db`
  static Future<AppSettingsRepository> open() async {
    final directory = await getDatabasesPath();
    final db = await openDatabase(
      p.join(directory, 'wawa_settings.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
    return AppSettingsRepository(database: db);
  }

  Future<Database> _getDb() async {
    if (_db != null) return _db;
    if (_lazyDb != null) return _lazyDb!;

    // Fallback: Lazy load si no se pasó ni se inicializó
    if (inMemory) {
      _lazyDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
        },
      );
      return _lazyDb!;
    }

    final directory = await getDatabasesPath();
    _lazyDb = await openDatabase(
      p.join(directory, 'wawa_settings.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
    return _lazyDb!;
  }

  Future<String?> getCaregiverName() async {
    if (inMemory && _db == null && _lazyDb == null)
      return _fakeDb['caregiverName'];
    final db = await _getDb();
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['caregiverName'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final name = rows.first['value'] as String?;
    return name?.trim().isEmpty == true ? null : name?.trim();
  }

  Future<void> setCaregiverName(String name) async {
    if (inMemory && _db == null && _lazyDb == null) {
      if (name.trim().isEmpty) {
        _fakeDb.remove('caregiverName');
      } else {
        _fakeDb['caregiverName'] = name.trim();
      }
      return;
    }
    final db = await _getDb();
    if (name.trim().isEmpty) {
      await db.delete(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['caregiverName'],
      );
      return;
    }
    await db.insert('app_settings', {
      'key': 'caregiverName',
      'value': name.trim(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
