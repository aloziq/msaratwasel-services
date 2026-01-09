import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  AuthCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.resetPasswordUseCase,
  }) : super(AuthInitial());

  Future<void> checkAuthStatus() async {
    final result = await getCurrentUserUseCase(NoParams());
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> login({
    required String id,
    required String password,
    required UserRole role,
  }) async {
    emit(AuthLoading());
    final result = await loginUseCase(
      LoginParams(id: id, password: password, role: role),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message ?? 'حدث خطأ غير متوقع')),
      (user) {
        // Validate that user's actual role matches the selected role
        if (user.role != role) {
          emit(AuthError('يرجى اختيار الدور الصحيح للدخول'));
          return;
        }
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> logout() async {
    emit(AuthLoading());
    final result = await logoutUseCase(NoParams());
    result.fold(
      (failure) => emit(AuthError(failure.message ?? 'حدث خطأ غير متوقع')),
      (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> resetPassword(String id) async {
    emit(AuthLoading());
    final result = await resetPasswordUseCase(ResetPasswordParams(id: id));
    result.fold(
      (failure) => emit(AuthError(failure.message ?? 'حدث خطأ غير متوقع')),
      (_) => emit(AuthPasswordResetSent()),
    );
  }
}
