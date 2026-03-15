import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/update_avatar_usecase.dart';
import 'auth_state.dart';

@lazySingleton
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final ChangePasswordUseCase changePasswordUseCase;
  final UpdateAvatarUseCase updateAvatarUseCase;

  AuthCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.resetPasswordUseCase,
    required this.changePasswordUseCase,
    required this.updateAvatarUseCase,
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
    required UserRole selectedRole, // للـ UI فقط - السيرفر يحدد الـ role الحقيقي
  }) async {
    emit(AuthLoading());
    final result = await loginUseCase(
      LoginParams(id: id, password: password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message ?? 'حدث خطأ غير متوقع')),
      (user) {
        // السيرفر هو المرجع الوحيد للـ role الحقيقي.
        // التوجيه يتم تلقائياً عبر _guardRoute في AppRouter بناءً على user.role.
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> logout() async {
    emit(AuthLoading());
    final result = await logoutUseCase(NoParams());
    result.fold(
      (failure) => emit(AuthUnauthenticated()), // نخرج حتى لو كان هناك خطأ
      (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> resetPassword(String id) async {
    emit(AuthLoading());
    final result = await resetPasswordUseCase(ResetPasswordParams(id: id));
    result.fold(
      (failure) =>
          emit(AuthError(failure.message ?? 'An unexpected error occurred')),
      (_) => emit(AuthPasswordResetSent()),
    );
  }

  Future<void> updateAvatar(String imagePath) async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      final result = await updateAvatarUseCase(imagePath);
      result.fold(
        (failure) => emit(AuthError(failure.message ?? 'فشل تحديث الصورة')),
        (newAvatarUrl) {
          final updatedUser = currentState.user.copyWith(avatar: newAvatarUrl);
          emit(AuthAuthenticated(updatedUser));
        },
      );
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final result = await changePasswordUseCase(ChangePasswordParams(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    ));
    
    return result.fold(
      (failure) {
        emit(AuthError(failure.message ?? 'فشل تغيير كلمة السر'));
        return false;
      },
      (_) => true,
    );
  }
}
