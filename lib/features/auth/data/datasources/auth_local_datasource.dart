import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/error/exceptions.dart';
import '../models/auth_session_model.dart';

/// Persists the session token in the platform secure store (Keychain /
/// EncryptedSharedPreferences) — the "armazenamento seguro do token" requirement.
abstract class AuthLocalDataSource {
  Future<void> cacheSession(AuthSessionModel session);
  Future<AuthSessionModel?> readSession();
  Future<void> clear();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user_name';

  @override
  Future<void> cacheSession(AuthSessionModel session) async {
    try {
      await _storage.write(key: _tokenKey, value: session.token);
      await _storage.write(key: _userKey, value: session.userName);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<AuthSessionModel?> readSession() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null || token.isEmpty) return null;
      final userName = await _storage.read(key: _userKey) ?? 'Usuário';
      return AuthSessionModel(token: token, userName: userName);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
