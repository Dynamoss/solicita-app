import 'package:flutter_test/flutter_test.dart';
import 'package:solicita_app/core/database/app_database.dart';
import 'package:solicita_app/features/requests/data/datasources/request_local_datasource.dart';
import 'package:solicita_app/features/requests/data/models/sync_action_model.dart';
import 'package:solicita_app/features/requests/domain/entities/request_status.dart';
import 'package:solicita_app/features/requests/domain/entities/sync_action.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/fixtures.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase db;
  late RequestLocalDataSourceImpl local;

  setUp(() {
    db = AppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    local = RequestLocalDataSourceImpl(db);
  });

  tearDown(() => db.close());

  group('cache', () {
    test('pagina por created_at desc com limite e offset', () async {
      for (var i = 0; i < 25; i++) {
        await local.upsertRequest(
          buildRequest(id: 'r$i', createdAt: DateTime.utc(2026, 1, 1, 0, i)),
        );
      }

      final page1 = await local.getCachedRequests(page: 1, limit: 10);
      final page2 = await local.getCachedRequests(page: 2, limit: 10);
      final page3 = await local.getCachedRequests(page: 3, limit: 10);

      expect(page1, hasLength(10));
      expect(page2, hasLength(10));
      expect(page3, hasLength(5));
      // Newest first.
      expect(page1.first.id, 'r24');
      // No overlap across pages.
      expect(page1.first.createdAt.isAfter(page2.first.createdAt), isTrue);
    });

    test('countCached respeita o filtro de status', () async {
      await local.upsertRequest(buildRequest(id: 'a', status: RequestStatus.open));
      await local.upsertRequest(
        buildRequest(id: 'b', status: RequestStatus.resolved),
      );

      expect(await local.countCached(), 2);
      expect(await local.countCached(status: RequestStatus.resolved), 1);
    });
  });

  group('fila de sincronização', () {
    SyncActionModel action(String id, int minute) => SyncActionModel(
          id: id,
          type: SyncActionType.create,
          entityId: 'e$id',
          payload: const {'k': 'v'},
          createdAt: DateTime.utc(2026, 1, 1, 0, minute),
        );

    test('getQueue retorna em ordem FIFO (created_at asc)', () async {
      await local.enqueue(action('terceiro', 3));
      await local.enqueue(action('primeiro', 1));
      await local.enqueue(action('segundo', 2));

      final queue = await local.getQueue();

      expect(queue.map((a) => a.id), ['primeiro', 'segundo', 'terceiro']);
    });

    test('removeFromQueue e queueCount', () async {
      await local.enqueue(action('a', 1));
      await local.enqueue(action('b', 2));
      expect(await local.queueCount(), 2);

      await local.removeFromQueue('a');

      expect(await local.queueCount(), 1);
      expect((await local.getQueue()).single.id, 'b');
    });
  });
}
