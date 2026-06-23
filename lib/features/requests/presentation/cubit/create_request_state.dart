part of 'create_request_cubit.dart';

enum CreateStatus { editing, suggesting, submitting, success, error }

class CreateRequestState extends Equatable {
  const CreateRequestState({
    this.status = CreateStatus.editing,
    this.suggestion,
    this.createdId,
    this.errorMessage,
  });

  final CreateStatus status;
  final AiSuggestion? suggestion;
  final String? createdId;
  final String? errorMessage;

  bool get isSuggesting => status == CreateStatus.suggesting;
  bool get isSubmitting => status == CreateStatus.submitting;

  CreateRequestState copyWith({
    CreateStatus? status,
    AiSuggestion? suggestion,
    String? createdId,
    String? errorMessage,
  }) {
    return CreateRequestState(
      status: status ?? this.status,
      suggestion: suggestion ?? this.suggestion,
      createdId: createdId ?? this.createdId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, suggestion, createdId, errorMessage];
}
