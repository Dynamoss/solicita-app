import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solicita_app/core/error/exceptions.dart';
import 'package:solicita_app/core/error/failures.dart';
import 'package:solicita_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:solicita_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:solicita_app/features/auth/data/models/auth_session_model.dart';
import 'package:solicita_app/features/auth/data/repositories/auth_repository_impl.dart';

class MockRemote extends Mock implements AuthRemoteDataSource {}

class MockLocal extends Mock implements AuthLocalDataSource {}

void main() {
  late MockRemote remote;
  late MockLocal local;
  late AuthRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const AuthSessionModel(token: 't', userName: 'u'),
    );
  });

  setUp(() {
    remote = MockRemote();
    local = MockLocal();
    repository = AuthRepositoryImpl(remote: remote, local: local);
  });

  group('login', () {
    test('sucesso: autentica e persiste a sessão com segurança', () async {
      const session = AuthSessionModel(token: 'abc', userName: 'Maria');
      when(() => remote.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => session);
      when(() => local.cacheSession(any())).thenAnswer((_) async {});

      final result =
          await repository.login(email: 'maria@x.com', password: '123456');

      expect(result.isRight(), isTrue);
      verify(() => local.cacheSession(session)).called(1);
    });

    test('credenciais inválidas: mapeia AuthException para AuthFailure',
        () async {
      when(() => remote.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const AuthException('Credenciais inválidas.', statusCode: 401));

      final result =
          await repository.login(email: 'x@x.com', password: 'short');

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<AuthFailure>()), (_) {});
      verifyNever(() => local.cacheSession(any()));
    });
  });

  group('currentSession', () {
    test('retorna a sessão persistida', () async {
      const session = AuthSessionModel(token: 'abc', userName: 'Maria');
      when(() => local.readSession()).thenAnswer((_) async => session);

      final result = await repository.currentSession();

      expect(result.getOrElse((_) => null), session);
    });
  });

  group('logout', () {
    test('limpa o armazenamento seguro', () async {
      when(() => local.clear()).thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result.isRight(), isTrue);
      verify(() => local.clear()).called(1);
    });
  });
}
