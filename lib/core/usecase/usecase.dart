import '../utils/typedefs.dart';

/// A single unit of business logic.
///
/// Use cases keep the presentation layer thin: a Cubit/Bloc orchestrates use
/// cases, it doesn't talk to repositories directly. This also gives each
/// business rule an isolated, trivially testable seam.
abstract class UseCase<T, Params> {
  const UseCase();

  ResultFuture<T> call(Params params);
}

/// Variant for use cases that take no input.
abstract class UseCaseWithoutParams<T> {
  const UseCaseWithoutParams();

  ResultFuture<T> call();
}

/// Placeholder for [UseCase]s whose `Params` are intentionally empty.
class NoParams {
  const NoParams();
}
