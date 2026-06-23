import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_info.dart';
import '../../domain/repositories/request_repository.dart';
import '../../domain/usecases/sync_pending_actions.dart';

part 'sync_state.dart';

/// App-wide coordinator for the offline queue.
///
/// Responsibilities:
///  * expose the live pending-count for the UI banner,
///  * track online/offline status,
///  * **automatically flush the queue when connectivity returns** — the
///    automatic part of "processar ações pendentes quando a conexão retornar".
class SyncCubit extends Cubit<SyncState> {
  SyncCubit({
    required SyncPendingActions syncPendingActions,
    required RequestRepository repository,
    required NetworkInfo networkInfo,
  })  : _syncPendingActions = syncPendingActions,
        _repository = repository,
        _networkInfo = networkInfo,
        super(const SyncState());

  final SyncPendingActions _syncPendingActions;
  final RequestRepository _repository;
  final NetworkInfo _networkInfo;

  StreamSubscription<int>? _pendingSub;
  StreamSubscription<bool>? _connectivitySub;

  /// Wires up the reactive subscriptions. Called once after construction.
  Future<void> init() async {
    final pending = await _repository.pendingCount();
    final online = await _networkInfo.isConnected;
    emit(state.copyWith(
      pendingCount: pending.getOrElse((_) => 0),
      isOnline: online,
    ));

    _pendingSub = _repository.watchPendingCount().listen(
          (count) => emit(state.copyWith(pendingCount: count)),
        );

    _connectivitySub = _networkInfo.onConnectivityChanged.listen((online) {
      emit(state.copyWith(isOnline: online));
      if (online && state.pendingCount > 0) {
        sync();
      }
    });
  }

  /// Manually trigger a sync (also used by the banner's "sync now" action).
  Future<void> sync() async {
    if (state.isSyncing) return;
    emit(state.copyWith(isSyncing: true));
    final result = await _syncPendingActions();
    result.fold(
      (_) => emit(state.copyWith(isSyncing: false)),
      (synced) => emit(state.copyWith(isSyncing: false, lastSyncedCount: synced)),
    );
  }

  @override
  Future<void> close() {
    _pendingSub?.cancel();
    _connectivitySub?.cancel();
    return super.close();
  }
}
