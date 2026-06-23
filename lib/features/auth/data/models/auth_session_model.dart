import '../../domain/entities/auth_session.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({required super.token, required super.userName});

  factory AuthSessionModel.fromEntity(AuthSession s) =>
      AuthSessionModel(token: s.token, userName: s.userName);
}
