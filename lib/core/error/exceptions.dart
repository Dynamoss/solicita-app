/// Low-level errors thrown by data sources. They never cross the repository
/// boundary: repositories catch these and map them to [Failure]s so the domain
/// layer stays transport-agnostic.
library;

class ServerException implements Exception {
  const ServerException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException($message, statusCode: $statusCode)';
}

class CacheException implements Exception {
  const CacheException([this.message = 'Falha ao acessar os dados locais.']);

  final String message;

  @override
  String toString() => 'CacheException($message)';
}

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'AuthException($message, statusCode: $statusCode)';
}
