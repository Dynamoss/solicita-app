import 'package:equatable/equatable.dart';

/// An authenticated session: the bearer [token] (persisted securely) and a
/// display [userName].
class AuthSession extends Equatable {
  const AuthSession({required this.token, required this.userName});

  final String token;
  final String userName;

  @override
  List<Object?> get props => [token, userName];
}
