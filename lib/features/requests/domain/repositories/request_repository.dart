import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/new_request_draft.dart';
import '../entities/request_status.dart';
import '../entities/service_request.dart';

/// The domain's view of request storage. Implemented in the data layer, which
/// hides the offline-first orchestration (remote + cache + sync queue) behind
/// these methods.
abstract class RequestRepository {
  /// A page of requests, optionally filtered by [status].
  ///
  /// Offline-first contract: when online it refreshes the local cache from the
  /// remote; when offline (or the remote fails) it serves the cache so the app
  /// stays usable.
  ResultFuture<Paginated<ServiceRequest>> getRequests({
    required int page,
    RequestStatus? status,
  });

  /// A single request by id (cache-aware).
  ResultFuture<ServiceRequest> getRequestById(String id);

  /// Creates a request. Always succeeds locally (optimistic) and enqueues a
  /// sync action; the remote write happens immediately when online, or later
  /// via [syncPending] when it isn't.
  ResultFuture<ServiceRequest> createRequest(NewRequestDraft draft);

  /// Changes a request's status with the same optimistic/offline semantics as
  /// [createRequest].
  ResultFuture<ServiceRequest> updateStatus({
    required String id,
    required RequestStatus status,
  });

  /// Drains the offline queue against the remote. Returns how many actions were
  /// synced successfully.
  ResultFuture<int> syncPending();

  /// Current number of queued actions.
  ResultFuture<int> pendingCount();

  /// Live count of queued actions, for the "pending sync" UI banner.
  Stream<int> watchPendingCount();
}
