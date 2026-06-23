import 'package:equatable/equatable.dart';

/// Base type for all expected, recoverable error states surfaced to the
/// domain/presentation layers.
///
/// Using a sealed hierarchy lets the presentation layer exhaustively switch on
/// the concrete failure (e.g. show an "offline" banner for [NetworkFailure])
/// while keeping the domain free of framework/transport concerns.
sealed class Failure extends Equatable {
  const Failure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String toString() => '$runtimeType($message, statusCode: $statusCode)';
}

/// The remote source returned an unexpected/error response.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

/// A local persistence (cache/queue) operation failed.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Falha ao acessar os dados locais.']);
}

/// The device is offline. Distinguished from [ServerFailure] so the UI can
/// react differently (e.g. fall back to cache, queue the action).
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

/// Authentication/authorization problem (invalid credentials, expired token).
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.statusCode});
}

/// Input did not pass business validation.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Catch-all for anything not anticipated above.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Ocorreu um erro inesperado.']);
}
