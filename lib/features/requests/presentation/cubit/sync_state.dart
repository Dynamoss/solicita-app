part of 'sync_cubit.dart';

class SyncState extends Equatable {
  const SyncState({
    this.pendingCount = 0,
    this.isOnline = true,
    this.isSyncing = false,
    this.lastSyncedCount,
  });

  /// Number of actions waiting in the offline queue.
  final int pendingCount;
  final bool isOnline;
  final bool isSyncing;

  /// Result of the most recent sync run (for a transient confirmation).
  final int? lastSyncedCount;

  bool get hasPending => pendingCount > 0;

  SyncState copyWith({
    int? pendingCount,
    bool? isOnline,
    bool? isSyncing,
    int? lastSyncedCount,
  }) {
    return SyncState(
      pendingCount: pendingCount ?? this.pendingCount,
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedCount: lastSyncedCount,
    );
  }

  @override
  List<Object?> get props => [pendingCount, isOnline, isSyncing, lastSyncedCount];
}
