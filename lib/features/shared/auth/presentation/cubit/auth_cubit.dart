import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/update_avatar_usecase.dart';
import '../../domain/usecases/update_fcm_token_usecase.dart';
import '../../../../../core/services/reverb_service.dart';
import '../../../../../core/services/fcm_service.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../config/routes/app_router.dart';
import 'auth_state.dart';

@lazySingleton
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final ChangePasswordUseCase changePasswordUseCase;
  final UpdateAvatarUseCase updateAvatarUseCase;
  final UpdateFcmTokenUseCase updateFcmTokenUseCase;
  final AuthRepository authRepository;

  ReverbService? _reverbService;
  ReverbService? get reverbService => _reverbService;

  AuthCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.resetPasswordUseCase,
    required this.changePasswordUseCase,
    required this.updateAvatarUseCase,
    required this.updateFcmTokenUseCase,
    required this.authRepository,
  }) : super(AuthInitial());

  Future<void> checkAuthStatus() async {
    final result = await getCurrentUserUseCase(NoParams());
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) {
        emit(AuthAuthenticated(user));
        _initReverbAndFcm(user);
        // Re-fetch the user profile in the background so the cached `name`
        // always matches the current Accept-Language locale (e.g., if user
        // logged in under English but the app is now set to Arabic).
        refreshUserProfile();
      },
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
        emit(AuthAuthenticated(user));
        _initReverbAndFcm(user);
      },
    );
  }

  void _initReverbAndFcm(UserEntity user) async {
    // 1. Register FCM Token
    final fcmToken = await getIt<FcmService>().getToken();
    if (fcmToken != null) {
      await updateFcmTokenUseCase(fcmToken);
    }

    // 2. Initialize Reverb
    _reverbService?.dispose();
    _reverbService = ReverbService(
      userId: int.parse(user.id),
      dio: ApiClient.instance,
      onMessageReceived: (data) {
        // Handle foreground notifications or Reverb messages if needed
      },
    );
    _reverbService!.connect();
  }



  Future<void> logout() async {
    emit(AuthLoading());
    
    // Stop background location updates immediately on logout
    LocationService.stop();
    
    // Delete the local FCM token from Firebase
    await getIt<FcmService>().deleteToken();

    final result = await logoutUseCase(NoParams());
    result.fold(
      (failure) => _handleLogoutSuccess(),
      (_) => _handleLogoutSuccess(),
    );
  }

  void _handleLogoutSuccess() {
    _reverbService?.dispose();
    _reverbService = null;
    emit(AuthUnauthenticated());
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

  /// Re-fetches the user profile from the server using the current Accept-Language header.
  /// Call this after changing the app language so the cached name updates to the new locale.
  Future<void> refreshUserProfile() async {
    final result = await authRepository.refreshUserProfile();
    result.fold(
      (_) {/* silently ignore failures — UI will still work with cached data */},
      (updatedUser) {
        if (state is AuthAuthenticated) {
          emit(AuthAuthenticated(updatedUser));
        }
      },
    );
  }

  void forceLogout() {
    LocationService.stop();
    getIt<FcmService>().deleteToken();
    _handleLogoutSuccess();
  }
}

