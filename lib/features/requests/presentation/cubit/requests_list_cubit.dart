import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/request_status.dart';
import '../../domain/entities/service_request.dart';
import '../../domain/usecases/get_requests.dart';

part 'requests_list_state.dart';

/// Drives the requests list: initial load, status filter, infinite-scroll
/// pagination and pull-to-refresh.
class RequestsListCubit extends Cubit<RequestsListState> {
  RequestsListCubit(this._getRequests) : super(const RequestsListState());

  final GetRequests _getRequests;

  /// Initial load / pull-to-refresh. Always resets to page 1.
  Future<void> load({bool refresh = false}) async {
    if (!refresh) emit(state.copyWith(status: ListStatus.loading));

    final result = await _getRequests(
      GetRequestsParams(page: 1, status: state.filter),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ListStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (data) => emit(
        state.copyWith(
          status: ListStatus.loaded,
          items: data.items,
          page: 1,
          hasMore: data.hasMore,
        ),
      ),
    );
  }

  /// Loads the next page and appends (de-duplicated by id).
  Future<void> loadMore() async {
    if (state.status == ListStatus.loadingMore || !state.hasMore) return;

    emit(state.copyWith(status: ListStatus.loadingMore));
    final nextPage = state.page + 1;

    final result = await _getRequests(
      GetRequestsParams(page: nextPage, status: state.filter),
    );

    result.fold(
      // On a paging error keep what we have and just stop the spinner.
      (_) => emit(state.copyWith(status: ListStatus.loaded)),
      (data) {
        final merged = _mergeById(state.items, data.items);
        emit(
          state.copyWith(
            status: ListStatus.loaded,
            items: merged,
            page: nextPage,
            hasMore: data.hasMore,
          ),
        );
      },
    );
  }

  /// Switches the status filter and reloads from page 1.
  Future<void> changeFilter(RequestStatus? filter) async {
    if (filter == state.filter) return;
    emit(
      state.copyWith(
        filter: filter,
        clearFilter: filter == null,
        items: const [],
        page: 1,
      ),
    );
    await load();
  }

  List<ServiceRequest> _mergeById(
    List<ServiceRequest> current,
    List<ServiceRequest> incoming,
  ) {
    final seen = {for (final r in current) r.id};
    return [
      ...current,
      ...incoming.where((r) => !seen.contains(r.id)),
    ];
  }
}
