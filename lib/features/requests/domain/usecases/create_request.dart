import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/new_request_draft.dart';
import '../entities/service_request.dart';
import '../repositories/request_repository.dart';

class CreateRequest extends UseCase<ServiceRequest, NewRequestDraft> {
  const CreateRequest(this._repository);

  final RequestRepository _repository;

  @override
  ResultFuture<ServiceRequest> call(NewRequestDraft draft) =>
      _repository.createRequest(draft);
}
