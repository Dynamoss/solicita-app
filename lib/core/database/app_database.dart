import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection and schema.
///
/// The [DatabaseFactory] is injected rather than referenced globally so tests
/// can open a fast in-memory database (`databaseFactoryFfi` +
/// `inMemoryDatabasePath`) while the app uses the platform default.
class AppDatabase {
  AppDatabase({required DatabaseFactory factory, required String path})
      : _factory = factory,
        _path = path;

  final DatabaseFactory _factory;
  final String _path;

  Database? _db;

  /// Cached, lazily-opened connection.
  Future<Database> get database async => _db ??= await _open();

  static const String requestsTable = 'requests';
  static const String syncQueueTable = 'sync_queue';

  Future<Database> _open() {
    return _factory.openDatabase(
      _path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $requestsTable (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT NOT NULL,
              status TEXT NOT NULL,
              category TEXT,
              priority TEXT NOT NULL,
              requester TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              pending_sync INTEGER NOT NULL DEFAULT 0
            )
          ''');

          // The offline action queue: one row per pending mutation, processed
          // FIFO (ordered by created_at) when connectivity returns.
          await db.execute('''
            CREATE TABLE $syncQueueTable (
              id TEXT PRIMARY KEY,
              type TEXT NOT NULL,
              entity_id TEXT NOT NULL,
              payload TEXT NOT NULL,
              created_at TEXT NOT NULL,
              retry_count INTEGER NOT NULL DEFAULT 0,
              last_error TEXT
            )
          ''');
        },
      ),
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
