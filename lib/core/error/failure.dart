import 'package:equatable/equatable.dart';

/// Base class for all failures in the application.
/// Used for error handling in the domain layer.
abstract class Failure extends Equatable {
  const Failure([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];
}

/// Failure when server returns an error.
class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

/// Failure when there's no internet connection.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);
}

/// Failure when validation fails.
class ValidationFailure extends Failure {
  const ValidationFailure([super.message]);
}

/// Failure when authentication fails.
class AuthFailure extends Failure {
  const AuthFailure([super.message]);
}

/// Failure when cache operations fail.
class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}
