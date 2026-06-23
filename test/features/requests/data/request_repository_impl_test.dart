import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solicita_app/core/database/app_database.dart';
import 'package:solicita_app/core/error/exceptions.dart';
import 'package:solicita_app/core/error/failures.dart';
import 'package:solicita_app/core/network/network_info.dart';
import 'package:solicita_app/features/requests/data/datasources/request_local_datasource.dart';
import 'package:solicita_app/features/requests/data/datasources/request_remote_datasource.dart';
import 'package:solicita_app/features/requests/data/models/request_model.dart';
import 'package:solicita_app/features/requests/data/repositories/request_repository_impl.dart';
import 'package:solicita_app/features/requests/domain/entities/new_request_draft.dart';
import 'package:solicita_app/features/requests/domain/entities/request_status.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/fixtures.dart';

class MockRemote extends Mock implements RequestRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

/// The repository is tested against a REAL in-memory SQLite cache/queue (only
/// the remote and connectivity are mocked). This exercises the actual
/// offline-first + sync-queue behavior end to end — the heart of the challenge.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    registerFallbackValue(buildRequest());
  });

  late AppDatabase db;
  late RequestLocalDataSourceImpl local;
  late MockRemote remote;
  late MockNetworkInfo network;
  late RequestRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    local = RequestLocalDataSourceImpl(db);
    remote = MockRemote();
    network = MockNetworkInfo();
    repository = RequestRepositoryImpl(
      remote: remote,
      local: local,
      networkInfo: network,
    );
  });

  tearDown(() async {
    await repository.dispose();
    await db.close();
  });

  const draft = NewRequestDraft(
    title: 'Sem acesso ao sistema',
    description: 'Não consigo logar com minha senha.',
    priority: RequestPriority.high,
    requester: 'Maria',
  );

  group('createRequest', () {
    test('offline: persiste no cache como pendente e enfileira a ação',
        () async {
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repository.createRequest(draft);

      expect(result.isRight(), isTrue);
      final created = result.getOrElse((_) => throw Exception());
      expect(created.pendingSync, isTrue);
      expect(created.status, RequestStatus.open);

      // Cached and queued.
      final cached = await local.getCachedById(created.id);
      expect(cached, isNotNull);
      expect(cached!.pendingSync, isTrue);
      expect(await local.queueCount(), 1);

      // Never tried to hit the network.
      verifyNever(() => remote.create(any()));
    });

    test('online: envia ao remoto, limpa a fila e marca como sincronizado',
        () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.create(any()))
          .thenAnswer((inv) async => inv.positionalArguments[0] as RequestModel);

      final result = await repository.createRequest(draft);
      final created = result.getOrElse((_) => throw Exception());

      verify(() => remote.create(any())).called(1);
      expect(await local.queueCount(), 0);
      final cached = await local.getCachedById(created.id);
      expect(cached!.pendingSync, isFalse);
    });

    test('online mas remoto falha: mantém na fila para sincronizar depois',
        () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.create(any()))
          .thenThrow(const ServerException('500', statusCode: 500));

      final result = await repository.createRequest(draft);

      expect(result.isRight(), isTrue); // optimistic success
      expect(await local.queueCount(), 1);
      final created = result.getOrElse((_) => throw Exception());
      final cached = await local.getCachedById(created.id);
      expect(cached!.pendingSync, isTrue);
    });
  });

  group('updateStatus', () {
    test('offline: atualiza cache e enfileira ação de status', () async {
      // Seed a synced request first.
      await local.upsertRequest(buildRequest(id: 'r1'));
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repository.updateStatus(
        id: 'r1',
        status: RequestStatus.resolved,
      );

      expect(result.isRight(), isTrue);
      final cached = await local.getCachedById('r1');
      expect(cached!.status, RequestStatus.resolved);
      expect(cached.pendingSync, isTrue);
      expect(await local.queueCount(), 1);
    });
  });

  group('syncPending', () {
    test('offline: retorna NetworkFailure sem tocar no remoto', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repository.syncPending();

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<NetworkFailure>()), (_) {});
    });

    test('drena a fila FIFO ao reconectar e sincroniza todas as ações',
        () async {
      // Create two requests while offline.
      when(() => network.isConnected).thenAnswer((_) async => false);
      await repository.createRequest(draft);
      await repository.createRequest(draft);
      expect(await local.queueCount(), 2);

      // Reconnect and sync.
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => remote.create(any()))
          .thenAnswer((inv) async => inv.positionalArguments[0] as RequestModel);

      final result = await repository.syncPending();

      expect(result.getOrElse((_) => -1), 2);
      expect(await local.queueCount(), 0);
      verify(() => remote.create(any())).called(2);
    });
  });

  group('getRequests', () {
    test('online: busca no remoto, popula o cache e retorna a página',
        () async {
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(
        () => remote.fetchRequests(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => (items: [buildRequest(id: 'r1')], total: 1));

      final result = await repository.getRequests(page: 1);

      final page = result.getOrElse((_) => throw Exception());
      expect(page.items, hasLength(1));
      expect(page.hasMore, isFalse);
      // Cached for offline use.
      expect(await local.getCachedById('r1'), isNotNull);
    });

    test('offline: serve a partir do cache', () async {
      await local.cacheRequests([buildRequest(id: 'a'), buildRequest(id: 'b')]);
      when(() => network.isConnected).thenAnswer((_) async => false);

      final result = await repository.getRequests(page: 1);

      final page = result.getOrElse((_) => throw Exception());
      expect(page.items, hasLength(2));
      verifyNever(
        () => remote.fetchRequests(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          status: any(named: 'status'),
        ),
      );
    });

    test('online com falha no remoto: degrada para o cache', () async {
      await local.cacheRequests([buildRequest(id: 'a')]);
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(
        () => remote.fetchRequests(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          status: any(named: 'status'),
        ),
      ).thenThrow(const ServerException('timeout'));

      final result = await repository.getRequests(page: 1);

      final page = result.getOrElse((_) => throw Exception());
      expect(page.items, hasLength(1));
    });
  });
}
