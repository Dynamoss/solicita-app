import 'package:equatable/equatable.dart';

/// A single page of a larger collection, plus enough metadata for the UI to
/// know whether to keep loading.
class Paginated<T> extends Equatable {
  const Paginated({
    required this.items,
    required this.page,
    required this.hasMore,
    this.total,
  });

  final List<T> items;
  final int page;

  /// Whether another page exists after this one.
  final bool hasMore;

  /// Total number of items across all pages, when the source reports it.
  final int? total;

  @override
  List<Object?> get props => [items, page, hasMore, total];
}
