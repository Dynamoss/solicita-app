import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ai/domain/entities/ai_suggestion.dart';
import '../../../ai/domain/usecases/suggest_request_meta.dart';
import '../../domain/entities/new_request_draft.dart';
import '../../domain/usecases/create_request.dart';

part 'create_request_state.dart';

class CreateRequestCubit extends Cubit<CreateRequestState> {
  CreateRequestCubit({
    required CreateRequest createRequest,
    required SuggestRequestMeta suggestRequestMeta,
  })  : _createRequest = createRequest,
        _suggestRequestMeta = suggestRequestMeta,
        super(const CreateRequestState());

  final CreateRequest _createRequest;
  final SuggestRequestMeta _suggestRequestMeta;

  /// Asks the AI service for a category/summary suggestion from the description.
  Future<void> suggestMeta(String description) async {
    emit(state.copyWith(status: CreateStatus.suggesting));
    final result = await _suggestRequestMeta(description);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CreateStatus.editing,
          errorMessage: failure.message,
        ),
      ),
      (suggestion) => emit(
        state.copyWith(status: CreateStatus.editing, suggestion: suggestion),
      ),
    );
  }

  Future<void> submit(NewRequestDraft draft) async {
    emit(state.copyWith(status: CreateStatus.submitting));
    final result = await _createRequest(draft);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CreateStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (created) => emit(
        state.copyWith(status: CreateStatus.success, createdId: created.id),
      ),
    );
  }
}
