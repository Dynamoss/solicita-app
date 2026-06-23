import 'dart:convert';

import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/sync_action.dart';

/// SQLite (de)serialization for a queued [SyncAction]. The [payload] map is
/// stored as a JSON string in a single TEXT column.
class SyncActionModel extends SyncAction {
  const SyncActionModel({
    required super.id,
    required super.type,
    required super.entityId,
    required super.payload,
    required super.createdAt,
    super.retryCount,
    super.lastError,
  });

  factory SyncActionModel.fromEntity(SyncAction a) => SyncActionModel(
        id: a.id,
        type: a.type,
        entityId: a.entityId,
        payload: a.payload,
        createdAt: a.createdAt,
        retryCount: a.retryCount,
        lastError: a.lastError,
      );

  factory SyncActionModel.fromDb(DataMap row) => SyncActionModel(
        id: row['id'] as String,
        type: SyncActionType.fromValue(row['type'] as String),
        entityId: row['entity_id'] as String,
        payload: jsonDecode(row['payload'] as String) as DataMap,
        createdAt: DateTime.parse(row['created_at'] as String),
        retryCount: row['retry_count'] as int? ?? 0,
        lastError: row['last_error'] as String?,
      );

  DataMap toDb() => {
        'id': id,
        'type': type.value,
        'entity_id': entityId,
        'payload': jsonEncode(payload),
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
        'last_error': lastError,
      };
}
