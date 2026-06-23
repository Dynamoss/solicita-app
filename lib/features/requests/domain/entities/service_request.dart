import 'package:equatable/equatable.dart';

import 'request_status.dart';

/// Core domain entity: a tracked service request / support ticket.
///
/// Pure data with value equality — no JSON, no framework. The data layer's
/// `RequestModel` extends this to add serialization.
class ServiceRequest extends Equatable {
  const ServiceRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.requester,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.pendingSync = false,
  });

  final String id;
  final String title;
  final String description;
  final RequestStatus status;
  final RequestPriority priority;
  final String requester;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// AI-suggested (or user-chosen) category. Optional.
  final String? category;

  /// `true` while the row exists only locally and is waiting in the sync queue.
  /// Drives the "not yet synced" badge in the UI.
  final bool pendingSync;

  ServiceRequest copyWith({
    String? id,
    String? title,
    String? description,
    RequestStatus? status,
    RequestPriority? priority,
    String? requester,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    bool? pendingSync,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      requester: requester ?? this.requester,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        priority,
        requester,
        createdAt,
        updatedAt,
        category,
        pendingSync,
      ];
}
