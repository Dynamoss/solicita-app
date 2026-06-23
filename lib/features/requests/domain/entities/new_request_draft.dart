import 'request_status.dart';

/// User-provided input for creating a request. Separate from [ServiceRequest]
/// because the id/timestamps/status are assigned by the system, not the form.
class NewRequestDraft {
  const NewRequestDraft({
    required this.title,
    required this.description,
    required this.priority,
    required this.requester,
    this.category,
  });

  final String title;
  final String description;
  final RequestPriority priority;
  final String requester;
  final String? category;
}
