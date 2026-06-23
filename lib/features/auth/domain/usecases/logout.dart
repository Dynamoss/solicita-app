import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/typedefs.dart';
import '../repositories/auth_repository.dart';

class Logout extends UseCaseWithoutParams<void> {
  const Logout(this._repository);

  final AuthRepository _repository;

  @override
  ResultVoid call() => _repository.logout();
}
