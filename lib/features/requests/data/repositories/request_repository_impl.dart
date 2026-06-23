import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/new_request_draft.dart';
import '../../domain/entities/request_status.dart';
import '../../domain/entities/service_request.dart';
import '../../domain/entities/sync_action.dart';
import '../../domain/repositories/request_repository.dart';
import '../datasources/request_local_datasource.dart';
import '../datasources/request_remote_datasource.dart';
import '../models/request_model.dart';
import '../models/sync_action_model.dart';

/// Offline-first orchestration over the remote API and the local cache/queue.
///
/// Design decisions (expanded in the README):
///  * The **local cache is the single source of truth** the UI reads from. The
///    remote is treated as a sync target, so the screen renders identically
///    online and offline.
///  * Writes are **optimistic**: they hit the cache immediately, enqueue a
///    [SyncAction], and try to push right away when online. If the push fails
///    (or we're offline) the action stays queued and [syncPending] replays it
///    later, FIFO.
class RequestRepositoryImpl implements RequestRepository {
  RequestRepositoryImpl({
    required RequestRemoteDataSource remote,
    required RequestLocalDataSource local,
    required NetworkInfo networkInfo,
    Uuid? uuid,
  })  : _remote = remote,
        _local = local,
        _networkInfo = networkInfo,
        _uuid = uuid ?? const Uuid();

  final RequestRemoteDataSource _remote;
  final RequestLocalDataSource _local;
  final NetworkInfo _networkInfo;
  final Uuid _uuid;

  final StreamController<int> _pendingController =
      StreamController<int>.broadcast();

  static const int _limit = AppConfig.pageSize;

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  @override
  ResultFuture<Paginated<ServiceRequest>> getRequests({
    required int page,
    RequestStatus? status,
  }) async {
    try {
      if (await _networkInfo.isConnected) {
        try {
          final remotePage = await _remote.fetchRequests(
            page: page,
            limit: _limit,
            status: status,
          );
          // Refresh the cache with the freshly fetched page.
          await _local.cacheRequests(remotePage.items);
          final items = await _local.getCachedRequests(
            page: page,
            limit: _limit,
            status: status,
          );
          return Right(
            Paginated(
              items: items,
              page: page,
              hasMore: page * _limit < remotePage.total,
              total: remotePage.total,
            ),
          );
        } on ServerException {
          // Remote unavailable mid-session: degrade gracefully to cache.
          return _cachedPage(page: page, status: status);
        }
      }
      return _cachedPage(page: page, status: status);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<Either<Failure, Paginated<ServiceRequest>>> _cachedPage({
    required int page,
    RequestStatus? status,
  }) async {
    final items = await _local.getCachedRequests(
      page: page,
      limit: _limit,
      status: status,
    );
    final total = await _local.countCached(status: status);
    return Right(
      Paginated(
        items: items,
        page: page,
        hasMore: page * _limit < total,
        total: total,
      ),
    );
  }

  @override
  ResultFuture<ServiceRequest> getRequestById(String id) async {
    try {
      if (await _networkInfo.isConnected) {
        try {
          final remote = await _remote.fetchById(id);
          await _local.upsertRequest(remote);
          return Right(remote);
        } on ServerException {
          // fall through to cache
        }
      }
      final cached = await _local.getCachedById(id);
      if (cached != null) return Right(cached);
      return const Left(CacheFailure('Solicitação não encontrada no cache.'));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Writes (optimistic + queued)
  // ---------------------------------------------------------------------------

  @override
  ResultFuture<ServiceRequest> createRequest(NewRequestDraft draft) async {
    try {
      final now = DateTime.now().toUtc();
      final model = RequestModel(
        id: _uuid.v4(),
        title: draft.title,
        description: draft.description,
        status: RequestStatus.open,
        priority: draft.priority,
        requester: draft.requester,
        category: draft.category,
        createdAt: now,
        updatedAt: now,
        pendingSync: true,
      );

      await _local.upsertRequest(model);
      await _local.enqueue(
        SyncActionModel(
          id: _uuid.v4(),
          type: SyncActionType.create,
          entityId: model.id,
          payload: model.toJson(),
          createdAt: now,
        ),
      );
      await _emitPending();

      // Best-effort immediate push; safe to fail (stays queued).
      await _tryFlushQueue();

      final synced = await _local.getCachedById(model.id);
      return Right(synced ?? model);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<ServiceRequest> updateStatus({
    required String id,
    required RequestStatus status,
  }) async {
    try {
      final current = await _local.getCachedById(id);
      if (current == null) {
        return const Left(CacheFailure('Solicitação não encontrada.'));
      }

      final updated = RequestModel.fromEntity(
        current.copyWith(
          status: status,
          updatedAt: DateTime.now().toUtc(),
          pendingSync: true,
        ),
      );
      await _local.upsertRequest(updated);
      await _local.enqueue(
        SyncActionModel(
          id: _uuid.v4(),
          type: SyncActionType.updateStatus,
          entityId: id,
          payload: {
            'status': status.apiValue,
            'updatedAt': updated.updatedAt.toIso8601String(),
          },
          createdAt: DateTime.now().toUtc(),
        ),
      );
      await _emitPending();

      await _tryFlushQueue();

      final result = await _local.getCachedById(id);
      return Right(result ?? updated);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Sync queue
  // ---------------------------------------------------------------------------

  @override
  ResultFuture<int> syncPending() async {
    try {
      if (!await _networkInfo.isConnected) {
        return const Left(NetworkFailure());
      }
      final synced = await _drainQueue();
      return Right(synced);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Push as many queued actions as possible without surfacing errors. Used by
  /// the write paths so a create/update tries to sync immediately when online.
  Future<void> _tryFlushQueue() async {
    if (await _networkInfo.isConnected) {
      try {
        await _drainQueue();
      } catch (_) {
        // ignored: actions remain queued for the next attempt
      }
    }
  }

  /// Core queue processor. Replays actions FIFO; a network error aborts the run
  /// (no point continuing offline), other errors mark the item and move on.
  Future<int> _drainQueue() async {
    final queue = await _local.getQueue();
    var syncedCount = 0;

    for (final action in queue) {
      try {
        await _processAction(action);
        await _local.removeFromQueue(action.id);
        syncedCount++;
      } on ServerException catch (e) {
        final isConnectivity = e.statusCode == null;
        await _local.updateQueueItem(
          SyncActionModel.fromEntity(
            action.copyWith(
              retryCount: action.retryCount + 1,
              lastError: e.message,
            ),
          ),
        );
        if (isConnectivity) break; // lost connection — stop, retry later
      }
    }

    await _emitPending();
    return syncedCount;
  }

  Future<void> _processAction(SyncAction action) async {
    switch (action.type) {
      case SyncActionType.create:
        final synced = await _remote.create(RequestModel.fromJson(action.payload));
        await _local.upsertRequest(
          RequestModel.fromEntity(synced.copyWith(pendingSync: false)),
        );
      case SyncActionType.updateStatus:
        final synced = await _remote.updateStatus(
          id: action.entityId,
          status: RequestStatus.fromApi(action.payload['status'] as String?),
          updatedAt: DateTime.parse(action.payload['updatedAt'] as String),
        );
        await _local.upsertRequest(
          RequestModel.fromEntity(synced.copyWith(pendingSync: false)),
        );
    }
  }

  @override
  ResultFuture<int> pendingCount() async {
    try {
      return Right(await _local.queueCount());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<int> watchPendingCount() => _pendingController.stream;

  Future<void> _emitPending() async {
    if (_pendingController.isClosed) return;
    _pendingController.add(await _local.queueCount());
  }

  /// Releases the broadcast controller. Call on app teardown / in tests.
  Future<void> dispose() => _pendingController.close();
}
