import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/request_status.dart';
import '../../domain/entities/service_request.dart';
import '../../domain/usecases/get_request_detail.dart';
import '../../domain/usecases/update_request_status.dart';

part 'request_detail_state.dart';

class RequestDetailCubit extends Cubit<RequestDetailState> {
  RequestDetailCubit({
    required GetRequestDetail getRequestDetail,
    required UpdateRequestStatus updateRequestStatus,
  })  : _getRequestDetail = getRequestDetail,
        _updateRequestStatus = updateRequestStatus,
        super(const RequestDetailState());

  final GetRequestDetail _getRequestDetail;
  final UpdateRequestStatus _updateRequestStatus;

  String? _id;

  /// Reloads the request previously opened with [load]. Used by the error retry.
  Future<void> reload() async {
    if (_id != null) await load(_id!);
  }

  Future<void> load(String id) async {
    _id = id;
    emit(state.copyWith(status: DetailStatus.loading));
    final result = await _getRequestDetail(id);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DetailStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (request) => emit(
        state.copyWith(status: DetailStatus.loaded, request: request),
      ),
    );
  }

  Future<void> changeStatus(RequestStatus status) async {
    final current = state.request;
    if (current == null || current.status == status) return;

    emit(state.copyWith(status: DetailStatus.updating));
    final result = await _updateRequestStatus(
      UpdateRequestStatusParams(id: current.id, status: status),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DetailStatus.loaded,
          errorMessage: failure.message,
        ),
      ),
      (updated) => emit(
        state.copyWith(status: DetailStatus.loaded, request: updated),
      ),
    );
  }
}
