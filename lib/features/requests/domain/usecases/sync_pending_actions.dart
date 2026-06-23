import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/request_repository.dart';

/// Drains the offline queue. Returns the number of actions synced.
class SyncPendingActions extends UseCaseWithoutParams<int> {
  const SyncPendingActions(this._repository);

  final RequestRepository _repository;

  @override
  ResultFuture<int> call() => _repository.syncPending();
}
