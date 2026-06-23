import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class GetCurrentSession extends UseCaseWithoutParams<AuthSession?> {
  const GetCurrentSession(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<AuthSession?> call() => _repository.currentSession();
}
