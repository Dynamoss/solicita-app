import 'package:equatable/equatable.dart';

import '../../../../core/utils/typedefs.dart';

/// The kind of mutation captured while offline.
enum SyncActionType {
  create('create'),
  updateStatus('update_status');

  const SyncActionType(this.value);

  final String value;

  static SyncActionType fromValue(String value) =>
      SyncActionType.values.firstWhere((t) => t.value == value);
}

/// One queued, not-yet-synced mutation.
///
/// This is the unit the [SyncManager] drains FIFO when connectivity returns —
/// the literal "fila local de sincronização" the challenge calls its heart.
class SyncAction extends Equatable {
  const SyncAction({
    required this.id,
    required this.type,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final SyncActionType type;

  /// Id of the [ServiceRequest] this action mutates.
  final String entityId;

  /// The data to send to the remote (e.g. the full request for `create`, or the
  /// new status for `updateStatus`).
  final DataMap payload;

  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  SyncAction copyWith({int? retryCount, String? lastError}) => SyncAction(
        id: id,
        type: type,
        entityId: entityId,
        payload: payload,
        createdAt: createdAt,
        retryCount: retryCount ?? this.retryCount,
        lastError: lastError ?? this.lastError,
      );

  @override
  List<Object?> get props =>
      [id, type, entityId, payload, createdAt, retryCount, lastError];
}
