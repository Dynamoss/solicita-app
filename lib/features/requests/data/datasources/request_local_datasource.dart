import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/request_status.dart';
import '../models/request_model.dart';
import '../models/sync_action_model.dart';

/// Local persistence: the request cache plus the offline action queue.
abstract class RequestLocalDataSource {
  Future<List<RequestModel>> getCachedRequests({
    required int page,
    required int limit,
    RequestStatus? status,
  });

  Future<int> countCached({RequestStatus? status});

  Future<RequestModel?> getCachedById(String id);

  /// Upserts a batch (used to refresh the cache from a remote page).
  Future<void> cacheRequests(List<RequestModel> requests);

  Future<void> upsertRequest(RequestModel request);

  Future<void> deleteRequest(String id);

  // --- offline queue ---
  Future<void> enqueue(SyncActionModel action);

  Future<List<SyncActionModel>> getQueue();

  Future<void> removeFromQueue(String actionId);

  Future<void> updateQueueItem(SyncActionModel action);

  Future<int> queueCount();
}

class RequestLocalDataSourceImpl implements RequestLocalDataSource {
  RequestLocalDataSourceImpl(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  @override
  Future<List<RequestModel>> getCachedRequests({
    required int page,
    required int limit,
    RequestStatus? status,
  }) async {
    try {
      final db = await _db;
      final rows = await db.query(
        AppDatabase.requestsTable,
        where: status != null ? 'status = ?' : null,
        whereArgs: status != null ? [status.apiValue] : null,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: (page - 1) * limit,
      );
      return rows.map(RequestModel.fromDb).toList();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<int> countCached({RequestStatus? status}) async {
    try {
      final db = await _db;
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM ${AppDatabase.requestsTable}'
        '${status != null ? ' WHERE status = ?' : ''}',
        status != null ? [status.apiValue] : null,
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<RequestModel?> getCachedById(String id) async {
    try {
      final db = await _db;
      final rows = await db.query(
        AppDatabase.requestsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return RequestModel.fromDb(rows.first);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> cacheRequests(List<RequestModel> requests) async {
    try {
      final db = await _db;
      final batch = db.batch();
      for (final r in requests) {
        batch.insert(
          AppDatabase.requestsTable,
          r.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> upsertRequest(RequestModel request) async {
    try {
      final db = await _db;
      await db.insert(
        AppDatabase.requestsTable,
        request.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> deleteRequest(String id) async {
    try {
      final db = await _db;
      await db.delete(
        AppDatabase.requestsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> enqueue(SyncActionModel action) async {
    try {
      final db = await _db;
      await db.insert(
        AppDatabase.syncQueueTable,
        action.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<List<SyncActionModel>> getQueue() async {
    try {
      final db = await _db;
      // FIFO: oldest action first so mutations replay in the order they happened.
      final rows = await db.query(
        AppDatabase.syncQueueTable,
        orderBy: 'created_at ASC',
      );
      return rows.map(SyncActionModel.fromDb).toList();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> removeFromQueue(String actionId) async {
    try {
      final db = await _db;
      await db.delete(
        AppDatabase.syncQueueTable,
        where: 'id = ?',
        whereArgs: [actionId],
      );
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> updateQueueItem(SyncActionModel action) async {
    try {
      final db = await _db;
      await db.update(
        AppDatabase.syncQueueTable,
        action.toDb(),
        where: 'id = ?',
        whereArgs: [action.id],
      );
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<int> queueCount() async {
    try {
      final db = await _db;
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM ${AppDatabase.syncQueueTable}',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
