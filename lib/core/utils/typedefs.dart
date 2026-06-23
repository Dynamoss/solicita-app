import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';

/// Result of an async operation that can fail with a [Failure].
///
/// `Either` makes the failure path explicit in the type signature — the caller
/// is forced to handle both branches, which is a deliberate choice over throwing
/// exceptions across layers.
typedef ResultFuture<T> = Future<Either<Failure, T>>;

/// Convenience alias for operations that return nothing on success.
typedef ResultVoid = ResultFuture<void>;

/// JSON-ish map shorthand used by models/data sources.
typedef DataMap = Map<String, dynamic>;
