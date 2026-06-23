import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solicita_app/core/network/network_info.dart';
import 'package:solicita_app/features/requests/domain/repositories/request_repository.dart';
import 'package:solicita_app/features/requests/domain/usecases/sync_pending_actions.dart';
import 'package:solicita_app/features/requests/presentation/cubit/sync_cubit.dart';

class MockSyncPendingActions extends Mock implements SyncPendingActions {}

class MockRepository extends Mock implements RequestRepository {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockSyncPendingActions syncPending;
  late MockRepository repository;
  late MockNetworkInfo network;
  late StreamController<int> pendingController;
  late StreamController<bool> connectivityController;

  setUp(() {
    syncPending = MockSyncPendingActions();
    repository = MockRepository();
    network = MockNetworkInfo();
    pendingController = StreamController<int>.broadcast();
    connectivityController = StreamController<bool>.broadcast();

    when(() => repository.watchPendingCount())
        .thenAnswer((_) => pendingController.stream);
    when(() => network.onConnectivityChanged)
        .thenAnswer((_) => connectivityController.stream);
  });

  tearDown(() {
    pendingController.close();
    connectivityController.close();
  });

  SyncCubit build() => SyncCubit(
        syncPendingActions: syncPending,
        repository: repository,
        networkInfo: network,
      );

  test('init carrega contagem pendente e status de conexão', () async {
    when(() => repository.pendingCount()).thenAnswer((_) async => const Right(3));
    when(() => network.isConnected).thenAnswer((_) async => true);

    final cubit = build();
    await cubit.init();

    expect(cubit.state.pendingCount, 3);
    expect(cubit.state.isOnline, isTrue);
    await cubit.close();
  });

  test('sincroniza automaticamente quando a conexão retorna com fila pendente',
      () async {
    when(() => repository.pendingCount()).thenAnswer((_) async => const Right(2));
    when(() => network.isConnected).thenAnswer((_) async => false);
    when(() => syncPending()).thenAnswer((_) async => const Right(2));

    final cubit = build();
    await cubit.init();
    expect(cubit.state.isOnline, isFalse);

    // Connection comes back.
    connectivityController.add(true);
    await Future<void>.delayed(Duration.zero);

    verify(() => syncPending()).called(1);
    expect(cubit.state.lastSyncedCount, 2);
    await cubit.close();
  });

  test('não sincroniza ao reconectar se não há ações pendentes', () async {
    when(() => repository.pendingCount()).thenAnswer((_) async => const Right(0));
    when(() => network.isConnected).thenAnswer((_) async => false);

    final cubit = build();
    await cubit.init();

    connectivityController.add(true);
    await Future<void>.delayed(Duration.zero);

    verifyNever(() => syncPending());
    await cubit.close();
  });
}
