import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/request_status.dart';
import '../../domain/entities/service_request.dart';

/// Data-layer representation of [ServiceRequest]. It extends the entity (so it
/// can be used anywhere one is expected) and adds three serialization seams:
///
/// * [fromJson]/[toJson] — the remote (json-server) wire format.
/// * [fromDb]/[toDb] — the local SQLite row format (snake_case columns, int bools).
class RequestModel extends ServiceRequest {
  const RequestModel({
    required super.id,
    required super.title,
    required super.description,
    required super.status,
    required super.priority,
    required super.requester,
    required super.createdAt,
    required super.updatedAt,
    super.category,
    super.pendingSync,
  });

  factory RequestModel.fromEntity(ServiceRequest e) => RequestModel(
        id: e.id,
        title: e.title,
        description: e.description,
        status: e.status,
        priority: e.priority,
        requester: e.requester,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        category: e.category,
        pendingSync: e.pendingSync,
      );

  // --- Remote (JSON) ---------------------------------------------------------

  factory RequestModel.fromJson(DataMap json) => RequestModel(
        id: json['id'].toString(),
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        status: RequestStatus.fromApi(json['status'] as String?),
        priority: RequestPriority.fromApi(json['priority'] as String?),
        requester: json['requester'] as String? ?? 'Desconhecido',
        category: json['category'] as String?,
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
      );

  DataMap toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.apiValue,
        'priority': priority.apiValue,
        'requester': requester,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  // --- Local (SQLite) --------------------------------------------------------

  factory RequestModel.fromDb(DataMap row) => RequestModel(
        id: row['id'] as String,
        title: row['title'] as String,
        description: row['description'] as String,
        status: RequestStatus.fromApi(row['status'] as String?),
        priority: RequestPriority.fromApi(row['priority'] as String?),
        requester: row['requester'] as String,
        category: row['category'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
        pendingSync: (row['pending_sync'] as int? ?? 0) == 1,
      );

  DataMap toDb() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.apiValue,
        'priority': priority.apiValue,
        'requester': requester,
        'category': category,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'pending_sync': pendingSync ? 1 : 0,
      };

  static DateTime _parseDate(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc() ?? DateTime.now().toUtc();
    }
    return DateTime.now().toUtc();
  }
}
