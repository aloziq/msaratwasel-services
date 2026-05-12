import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:msaratwasel_services/core/error/failure.dart';
import 'package:msaratwasel_services/core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class UpdateFcmTokenUseCase implements UseCase<void, String> {
  final AuthRepository repository;

  UpdateFcmTokenUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String fcmToken) async {
    return await repository.updateFcmToken(fcmToken);
  }
}
