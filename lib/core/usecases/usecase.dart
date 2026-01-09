import 'package:dartz/dartz.dart';

import '../error/failure.dart';

/// Base class for all use cases in the application.
///
/// [T] is the return type of the use case.
/// [Params] is the parameter type that the use case accepts.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Used when a use case doesn't require any parameters.
class NoParams {
  const NoParams();
}
