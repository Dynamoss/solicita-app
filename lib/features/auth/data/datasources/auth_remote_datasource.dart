import 'dart:convert';

import '../../../../core/error/exceptions.dart';
import '../models/auth_session_model.dart';

/// Mocked authentication endpoint.
///
/// The challenge explicitly allows a mocked login. This validates the
/// credentials locally and mints an opaque token, simulating what a real
/// `/auth/login` would return — so the rest of the app (secure storage, route
/// guards, the auth interceptor) is wired exactly as it would be in production.
abstract class AuthRemoteDataSource {
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl();

  static final RegExp _emailRegex = RegExp(r'^[\w.\-+]+@[\w\-]+\.[\w.\-]+$');

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    // Simulate network latency so loading states are exercised.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final normalizedEmail = email.trim().toLowerCase();
    if (!_emailRegex.hasMatch(normalizedEmail)) {
      throw const AuthException('E-mail inválido.', statusCode: 400);
    }
    if (password.length < 6) {
      throw const AuthException(
        'Credenciais inválidas.',
        statusCode: 401,
      );
    }

    final token = base64Url.encode(
      utf8.encode('$normalizedEmail:${DateTime.now().toUtc().toIso8601String()}'),
    );
    final userName = _nameFromEmail(normalizedEmail);

    return AuthSessionModel(token: token, userName: userName);
  }

  String _nameFromEmail(String email) {
    final local = email.split('@').first.replaceAll(RegExp(r'[._\-+]'), ' ');
    return local
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
