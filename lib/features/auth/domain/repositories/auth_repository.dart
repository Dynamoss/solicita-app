import '../../../../core/utils/typedefs.dart';
import '../entities/auth_session.dart';

abstract class AuthRepository {
  /// Authenticates and persists the session token securely.
  ResultFuture<AuthSession> login({
    required String email,
    required String password,
  });

  /// Clears the persisted session.
  ResultVoid logout();

  /// The persisted session, or `null` if the user is not logged in. Used on
  /// startup to decide the initial route (private vs. login).
  ResultFuture<AuthSession?> currentSession();
}
