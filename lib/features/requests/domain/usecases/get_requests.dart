import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/request_status.dart';
import '../entities/service_request.dart';
import '../repositories/request_repository.dart';

class GetRequests extends UseCase<Paginated<ServiceRequest>, GetRequestsParams> {
  const GetRequests(this._repository);

  final RequestRepository _repository;

  @override
  ResultFuture<Paginated<ServiceRequest>> call(GetRequestsParams params) =>
      _repository.getRequests(page: params.page, status: params.status);
}

class GetRequestsParams extends Equatable {
  const GetRequestsParams({required this.page, this.status});

  final int page;
  final RequestStatus? status;

  @override
  List<Object?> get props => [page, status];
}
