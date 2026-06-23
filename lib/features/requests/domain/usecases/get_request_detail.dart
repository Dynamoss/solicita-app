import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/service_request.dart';
import '../repositories/request_repository.dart';

class GetRequestDetail extends UseCase<ServiceRequest, String> {
  const GetRequestDetail(this._repository);

  final RequestRepository _repository;

  @override
  ResultFuture<ServiceRequest> call(String id) =>
      _repository.getRequestById(id);
}
