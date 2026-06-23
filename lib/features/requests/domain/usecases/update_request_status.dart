import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/request_status.dart';
import '../entities/service_request.dart';
import '../repositories/request_repository.dart';

class UpdateRequestStatus
    extends UseCase<ServiceRequest, UpdateRequestStatusParams> {
  const UpdateRequestStatus(this._repository);

  final RequestRepository _repository;

  @override
  ResultFuture<ServiceRequest> call(UpdateRequestStatusParams params) =>
      _repository.updateStatus(id: params.id, status: params.status);
}

class UpdateRequestStatusParams extends Equatable {
  const UpdateRequestStatusParams({required this.id, required this.status});

  final String id;
  final RequestStatus status;

  @override
  List<Object?> get props => [id, status];
}
