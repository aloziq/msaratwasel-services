// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../features/driver/home/data/repositories/home_repository_impl.dart'
    as _i215;
import '../../features/driver/home/domain/repositories/home_repository.dart'
    as _i920;
import '../../features/driver/home/presentation/manager/driver_home_cubit.dart'
    as _i903;
import '../../features/driver/maintenance/data/repositories/maintenance_repository_impl.dart'
    as _i391;
import '../../features/driver/maintenance/domain/repositories/maintenance_repository.dart'
    as _i71;
import '../../features/driver/maintenance/presentation/manager/maintenance_cubit.dart'
    as _i736;
import '../../features/driver/route/data/repositories/route_repository_impl.dart'
    as _i973;
import '../../features/driver/route/domain/repositories/route_repository.dart'
    as _i423;
import '../../features/driver/route/presentation/manager/route_navigation_cubit.dart'
    as _i155;
import '../../features/driver/trip/data/repositories/trip_repository_impl.dart'
    as _i671;
import '../../features/driver/trip/domain/repositories/trip_repository.dart'
    as _i932;
import '../../features/driver/trip/presentation/manager/end_trip_cubit.dart'
    as _i514;
import '../../features/field_supervisor/buses/data/datasources/fleet_remote_datasource.dart'
    as _i627;
import '../../features/field_supervisor/buses/data/repositories/fleet_repository_impl.dart'
    as _i405;
import '../../features/field_supervisor/buses/domain/repositories/fleet_repository.dart'
    as _i26;
import '../../features/field_supervisor/buses/domain/usecases/get_fleet_buses_usecase.dart'
    as _i301;
import '../../features/field_supervisor/buses/presentation/cubit/fleet_tracking_cubit.dart'
    as _i877;
import '../../features/shared/auth/data/datasources/auth_local_data_source.dart'
    as _i517;
import '../../features/shared/auth/data/datasources/auth_remote_data_source.dart'
    as _i554;
import '../../features/shared/auth/data/repositories/auth_repository_impl.dart'
    as _i452;
import '../../features/shared/auth/domain/repositories/auth_repository.dart'
    as _i61;
import '../../features/shared/auth/domain/usecases/change_password_usecase.dart'
    as _i315;
import '../../features/shared/auth/domain/usecases/get_current_user_usecase.dart'
    as _i735;
import '../../features/shared/auth/domain/usecases/login_usecase.dart' as _i758;
import '../../features/shared/auth/domain/usecases/logout_usecase.dart' as _i29;
import '../../features/shared/auth/domain/usecases/reset_password_usecase.dart'
    as _i307;
import '../../features/shared/auth/domain/usecases/update_avatar_usecase.dart'
    as _i389;
import '../../features/shared/auth/presentation/cubit/auth_cubit.dart' as _i277;
import '../../features/shared/messages/data/repositories/messages_repository_impl.dart'
    as _i33;
import '../../features/shared/messages/domain/repositories/messages_repository.dart'
    as _i633;
import '../../features/shared/qr_scan/presentation/cubit/qr_scan_cubit.dart'
    as _i989;
import '../../features/teacher/attendance_history/data/datasources/attendance_history_remote_datasource.dart'
    as _i587;
import '../../features/teacher/attendance_history/data/repositories/attendance_history_repository_impl.dart'
    as _i607;
import '../../features/teacher/attendance_history/domain/repositories/attendance_history_repository.dart'
    as _i880;
import '../../features/teacher/attendance_history/domain/usecases/get_attendance_history_usecase.dart'
    as _i571;
import '../../features/teacher/reports/data/datasources/reports_remote_datasource.dart'
    as _i573;
import '../../features/teacher/reports/data/repositories/reports_repository_impl.dart'
    as _i803;
import '../../features/teacher/reports/domain/repositories/reports_repository.dart'
    as _i377;
import '../../features/teacher/students/data/datasources/students_remote_datasource.dart'
    as _i222;
import '../../features/teacher/students/data/repositories/students_repository_impl.dart'
    as _i704;
import '../../features/teacher/students/domain/repositories/students_repository.dart'
    as _i319;
import '../../features/teacher/students/domain/usecases/get_students_usecase.dart'
    as _i842;
import '../../features/teacher/students/domain/usecases/mark_attendance_usecase.dart'
    as _i307;
import '../../features/teacher/students/presentation/cubit/class_details_cubit.dart'
    as _i272;
import '../../features/teacher/teacher/data/datasources/teacher_local_datasource.dart'
    as _i70;
import '../../features/teacher/teacher/data/datasources/teacher_remote_datasource.dart'
    as _i674;
import '../../features/teacher/teacher/data/repositories/teacher_repository_impl.dart'
    as _i347;
import '../../features/teacher/teacher/domain/repositories/teacher_repository.dart'
    as _i962;
import '../../features/teacher/teacher/domain/usecases/get_teacher_classroom_usecase.dart'
    as _i499;
import '../../features/teacher/teacher/domain/usecases/get_teacher_classrooms_usecase.dart'
    as _i833;
import '../../features/teacher/teacher/presentation/cubit/teacher_cubit.dart'
    as _i998;
import '../services/fcm_service.dart' as _i928;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i928.FcmService>(() => _i928.FcmService());
    gh.lazySingleton<_i71.MaintenanceRepository>(
      () => _i391.MaintenanceRepositoryImpl(),
    );
    gh.lazySingleton<_i920.HomeRepository>(() => _i215.HomeRepositoryImpl());
    gh.lazySingleton<_i573.ReportsRemoteDataSource>(
      () => _i573.ReportsRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i674.TeacherRemoteDataSource>(
      () => _i674.TeacherRemoteDataSourceImpl(),
    );
    gh.factory<_i903.DriverHomeCubit>(
      () => _i903.DriverHomeCubit(gh<_i920.HomeRepository>()),
    );
    gh.lazySingleton<_i517.AuthLocalDataSource>(
      () => _i517.AuthLocalDataSourceImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i222.StudentsRemoteDataSource>(
      () => _i222.StudentsRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i70.TeacherLocalDataSource>(
      () => _i70.TeacherLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i932.TripRepository>(() => _i671.TripRepositoryImpl());
    gh.lazySingleton<_i587.AttendanceHistoryRemoteDataSource>(
      () => _i587.AttendanceHistoryRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i627.FleetRemoteDataSource>(
      () => _i627.FleetRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i319.StudentsRepository>(
      () => _i704.StudentsRepositoryImpl(gh<_i222.StudentsRemoteDataSource>()),
    );
    gh.lazySingleton<_i423.RouteRepository>(() => _i973.RouteRepositoryImpl());
    gh.lazySingleton<_i554.AuthRemoteDataSource>(
      () => _i554.AuthRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i633.MessagesRepository>(
      () => _i33.MessagesRepositoryImpl(),
    );
    gh.factory<_i736.MaintenanceCubit>(
      () => _i736.MaintenanceCubit(gh<_i71.MaintenanceRepository>()),
    );
    gh.lazySingleton<_i61.AuthRepository>(
      () => _i452.AuthRepositoryImpl(
        remoteDataSource: gh<_i554.AuthRemoteDataSource>(),
        localDataSource: gh<_i517.AuthLocalDataSource>(),
      ),
    );
    gh.factory<_i155.RouteNavigationCubit>(
      () => _i155.RouteNavigationCubit(gh<_i423.RouteRepository>()),
    );
    gh.lazySingleton<_i26.FleetRepository>(
      () => _i405.FleetRepositoryImpl(
        remoteDataSource: gh<_i627.FleetRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i962.TeacherRepository>(
      () => _i347.TeacherRepositoryImpl(gh<_i674.TeacherRemoteDataSource>()),
    );
    gh.lazySingleton<_i315.ChangePasswordUseCase>(
      () => _i315.ChangePasswordUseCase(gh<_i61.AuthRepository>()),
    );
    gh.lazySingleton<_i735.GetCurrentUserUseCase>(
      () => _i735.GetCurrentUserUseCase(gh<_i61.AuthRepository>()),
    );
    gh.lazySingleton<_i758.LoginUseCase>(
      () => _i758.LoginUseCase(gh<_i61.AuthRepository>()),
    );
    gh.lazySingleton<_i29.LogoutUseCase>(
      () => _i29.LogoutUseCase(gh<_i61.AuthRepository>()),
    );
    gh.lazySingleton<_i307.ResetPasswordUseCase>(
      () => _i307.ResetPasswordUseCase(gh<_i61.AuthRepository>()),
    );
    gh.lazySingleton<_i389.UpdateAvatarUseCase>(
      () => _i389.UpdateAvatarUseCase(gh<_i61.AuthRepository>()),
    );
    gh.factory<_i514.EndTripCubit>(
      () => _i514.EndTripCubit(gh<_i932.TripRepository>()),
    );
    gh.lazySingleton<_i377.ReportsRepository>(
      () => _i803.ReportsRepositoryImpl(gh<_i573.ReportsRemoteDataSource>()),
    );
    gh.lazySingleton<_i499.GetTeacherClassroomUseCase>(
      () => _i499.GetTeacherClassroomUseCase(gh<_i962.TeacherRepository>()),
    );
    gh.lazySingleton<_i833.GetTeacherClassroomsUseCase>(
      () => _i833.GetTeacherClassroomsUseCase(gh<_i962.TeacherRepository>()),
    );
    gh.lazySingleton<_i842.GetStudentsUseCase>(
      () => _i842.GetStudentsUseCase(gh<_i319.StudentsRepository>()),
    );
    gh.lazySingleton<_i307.MarkAttendanceUseCase>(
      () => _i307.MarkAttendanceUseCase(gh<_i319.StudentsRepository>()),
    );
    gh.factory<_i998.TeacherCubit>(
      () => _i998.TeacherCubit(
        getTeacherClassroomUseCase: gh<_i499.GetTeacherClassroomUseCase>(),
      ),
    );
    gh.factory<_i272.ClassDetailsCubit>(
      () => _i272.ClassDetailsCubit(
        getStudentsUseCase: gh<_i842.GetStudentsUseCase>(),
        markAttendanceUseCase: gh<_i307.MarkAttendanceUseCase>(),
      ),
    );
    gh.lazySingleton<_i880.AttendanceHistoryRepository>(
      () => _i607.AttendanceHistoryRepositoryImpl(
        gh<_i587.AttendanceHistoryRemoteDataSource>(),
      ),
    );
    gh.factory<_i989.QRScanCubit>(
      () => _i989.QRScanCubit(gh<_i307.MarkAttendanceUseCase>()),
    );
    gh.lazySingleton<_i301.GetFleetBusesUseCase>(
      () => _i301.GetFleetBusesUseCase(gh<_i26.FleetRepository>()),
    );
    gh.lazySingleton<_i277.AuthCubit>(
      () => _i277.AuthCubit(
        loginUseCase: gh<_i758.LoginUseCase>(),
        logoutUseCase: gh<_i29.LogoutUseCase>(),
        getCurrentUserUseCase: gh<_i735.GetCurrentUserUseCase>(),
        resetPasswordUseCase: gh<_i307.ResetPasswordUseCase>(),
        changePasswordUseCase: gh<_i315.ChangePasswordUseCase>(),
        updateAvatarUseCase: gh<_i389.UpdateAvatarUseCase>(),
      ),
    );
    gh.lazySingleton<_i571.GetAttendanceHistoryUseCase>(
      () => _i571.GetAttendanceHistoryUseCase(
        gh<_i880.AttendanceHistoryRepository>(),
      ),
    );
    gh.factory<_i877.FleetTrackingCubit>(
      () => _i877.FleetTrackingCubit(gh<_i301.GetFleetBusesUseCase>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
