import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    return await repository.login(
      id: params.id,
      password: params.password,
      role: params.role,
    );
  }
}

class LoginParams extends Equatable {
  final String id;
  final String password;
  final UserRole role;

  const LoginParams({
    required this.id,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [id, password, role];
}
