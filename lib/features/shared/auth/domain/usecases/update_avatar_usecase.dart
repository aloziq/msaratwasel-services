import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class UpdateAvatarUseCase implements UseCase<String, String> {
  final AuthRepository repository;

  UpdateAvatarUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(String imagePath) async {
    return await repository.updateAvatar(imagePath);
  }
}
