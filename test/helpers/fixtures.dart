import 'package:solicita_app/features/requests/data/models/request_model.dart';
import 'package:solicita_app/features/requests/domain/entities/request_status.dart';

/// Builds a [RequestModel] with sensible defaults for tests.
RequestModel buildRequest({
  String id = 'r1',
  String title = 'Título de teste',
  String description = 'Descrição de teste suficientemente longa.',
  RequestStatus status = RequestStatus.open,
  RequestPriority priority = RequestPriority.medium,
  String requester = 'Fulano',
  String? category,
  bool pendingSync = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = createdAt ?? DateTime.utc(2026, 1, 1, 12);
  return RequestModel(
    id: id,
    title: title,
    description: description,
    status: status,
    priority: priority,
    requester: requester,
    category: category,
    createdAt: now,
    updatedAt: updatedAt ?? now,
    pendingSync: pendingSync,
  );
}
