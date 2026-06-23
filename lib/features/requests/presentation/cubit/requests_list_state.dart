part of 'requests_list_cubit.dart';

enum ListStatus { initial, loading, loaded, loadingMore, error }

class RequestsListState extends Equatable {
  const RequestsListState({
    this.status = ListStatus.initial,
    this.items = const [],
    this.filter,
    this.page = 1,
    this.hasMore = false,
    this.errorMessage,
  });

  final ListStatus status;
  final List<ServiceRequest> items;

  /// `null` means "all statuses".
  final RequestStatus? filter;
  final int page;
  final bool hasMore;
  final String? errorMessage;

  bool get isInitialLoading =>
      status == ListStatus.loading || status == ListStatus.initial;
  bool get isEmpty => status == ListStatus.loaded && items.isEmpty;

  RequestsListState copyWith({
    ListStatus? status,
    List<ServiceRequest>? items,
    RequestStatus? filter,
    bool clearFilter = false,
    int? page,
    bool? hasMore,
    String? errorMessage,
  }) {
    return RequestsListState(
      status: status ?? this.status,
      items: items ?? this.items,
      filter: clearFilter ? null : (filter ?? this.filter),
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, filter, page, hasMore, errorMessage];
}
