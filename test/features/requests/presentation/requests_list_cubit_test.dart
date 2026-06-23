import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solicita_app/core/error/failures.dart';
import 'package:solicita_app/core/utils/paginated.dart';
import 'package:solicita_app/features/requests/domain/entities/service_request.dart';
import 'package:solicita_app/features/requests/domain/usecases/get_requests.dart';
import 'package:solicita_app/features/requests/presentation/cubit/requests_list_cubit.dart';

import '../../../helpers/fixtures.dart';

class MockGetRequests extends Mock implements GetRequests {}

void main() {
  late MockGetRequests getRequests;

  setUpAll(() => registerFallbackValue(const GetRequestsParams(page: 1)));
  setUp(() => getRequests = MockGetRequests());

  Paginated<ServiceRequest> page(List<String> ids, {required bool hasMore}) =>
      Paginated(
        items: ids.map((id) => buildRequest(id: id)).toList(),
        page: 1,
        hasMore: hasMore,
      );

  blocTest<RequestsListCubit, RequestsListState>(
    'load emite [loading, loaded] com itens',
    build: () {
      when(() => getRequests(any()))
          .thenAnswer((_) async => Right(page(['a', 'b'], hasMore: false)));
      return RequestsListCubit(getRequests);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<RequestsListState>()
          .having((s) => s.status, 'status', ListStatus.loading),
      isA<RequestsListState>()
          .having((s) => s.status, 'status', ListStatus.loaded)
          .having((s) => s.items.length, 'items', 2),
    ],
  );

  blocTest<RequestsListCubit, RequestsListState>(
    'load com falha emite estado de erro',
    build: () {
      when(() => getRequests(any()))
          .thenAnswer((_) async => const Left(NetworkFailure()));
      return RequestsListCubit(getRequests);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<RequestsListState>()
          .having((s) => s.status, 'status', ListStatus.loading),
      isA<RequestsListState>()
          .having((s) => s.status, 'status', ListStatus.error),
    ],
  );

  blocTest<RequestsListCubit, RequestsListState>(
    'loadMore acrescenta a próxima página sem duplicar ids',
    build: () {
      when(() => getRequests(any())).thenAnswer((inv) async {
        final params = inv.positionalArguments[0] as GetRequestsParams;
        return params.page == 1
            ? Right(page(['a', 'b'], hasMore: true))
            : Right(
                Paginated(
                  items: [buildRequest(id: 'b'), buildRequest(id: 'c')],
                  page: 2,
                  hasMore: false,
                ),
              );
      });
      return RequestsListCubit(getRequests);
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
    },
    verify: (cubit) {
      expect(cubit.state.items.map((e) => e.id), ['a', 'b', 'c']);
      expect(cubit.state.page, 2);
      expect(cubit.state.hasMore, isFalse);
    },
  );

  blocTest<RequestsListCubit, RequestsListState>(
    'loadMore não faz nada quando não há mais páginas',
    build: () {
      when(() => getRequests(any()))
          .thenAnswer((_) async => Right(page(['a'], hasMore: false)));
      return RequestsListCubit(getRequests);
    },
    act: (cubit) async {
      await cubit.load();
      clearInteractions(getRequests);
      await cubit.loadMore();
    },
    verify: (_) => verifyNever(() => getRequests(any())),
  );
}
