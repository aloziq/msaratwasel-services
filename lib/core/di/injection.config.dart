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

import '../../features/driver/data/repositories/driver_mock_repository.dart'
    as _i557;
import '../../features/driver/domain/repositories/driver_repository.dart'
    as _i1037;
import '../../features/driver/presentation/manager/driver_home_cubit.dart'
    as _i524;
import '../../features/driver/presentation/manager/end_trip_cubit.dart'
    as _i632;
import '../../features/driver/presentation/manager/maintenance_cubit.dart'
    as _i637;
import '../../features/driver/presentation/manager/route_navigation_cubit.dart'
    as _i51;
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
import '../../features/shared/auth/domain/usecases/get_current_user_usecase.dart'
    as _i735;
import '../../features/shared/auth/domain/usecases/login_usecase.dart' as _i758;
import '../../features/shared/auth/domain/usecases/logout_usecase.dart' as _i29;
import '../../features/shared/auth/domain/usecases/reset_password_usecase.dart'
    as _i307;
import '../../features/shared/auth/presentation/cubit/auth_cubit.dart' as _i277;
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
    gh.lazySingleton<_i1037.DriverRepository>(
      () => _i557.DriverMockRepository(),
    );
    gh.lazySingleton<_i517.AuthLocalDataSource>(
      () => _i517.AuthLocalDataSourceImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i70.TeacherLocalDataSource>(
      () => _i70.TeacherLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i319.StudentsRepository>(
      () => _i704.StudentsRepositoryImpl(),
    );
    gh.lazySingleton<_i962.TeacherRepository>(
      () => _i347.TeacherRepositoryImpl(gh<_i70.TeacherLocalDataSource>()),
    );
    gh.lazySingleton<_i627.FleetRemoteDataSource>(
      () => _i627.MockFleetRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i554.AuthRemoteDataSource>(
      () => _i554.AuthRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i61.AuthRepository>(
      () => _i452.AuthRepositoryImpl(
        remoteDataSource: gh<_i554.AuthRemoteDataSource>(),
        localDataSource: gh<_i517.AuthLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i26.FleetRepository>(
      () => _i405.FleetRepositoryImpl(
        remoteDataSource: gh<_i627.FleetRemoteDataSource>(),
      ),
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
    gh.factory<_i524.DriverHomeCubit>(
      () => _i524.DriverHomeCubit(gh<_i1037.DriverRepository>()),
    );
    gh.factory<_i632.EndTripCubit>(
      () => _i632.EndTripCubit(gh<_i1037.DriverRepository>()),
    );
    gh.factory<_i637.MaintenanceCubit>(
      () => _i637.MaintenanceCubit(gh<_i1037.DriverRepository>()),
    );
    gh.factory<_i51.RouteNavigationCubit>(
      () => _i51.RouteNavigationCubit(gh<_i1037.DriverRepository>()),
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
    gh.lazySingleton<_i277.AuthCubit>(
      () => _i277.AuthCubit(
        loginUseCase: gh<_i758.LoginUseCase>(),
        logoutUseCase: gh<_i29.LogoutUseCase>(),
        getCurrentUserUseCase: gh<_i735.GetCurrentUserUseCase>(),
        resetPasswordUseCase: gh<_i307.ResetPasswordUseCase>(),
      ),
    );
    gh.factory<_i272.ClassDetailsCubit>(
      () => _i272.ClassDetailsCubit(
        getStudentsUseCase: gh<_i842.GetStudentsUseCase>(),
        markAttendanceUseCase: gh<_i307.MarkAttendanceUseCase>(),
      ),
    );
    gh.lazySingleton<_i301.GetFleetBusesUseCase>(
      () => _i301.GetFleetBusesUseCase(gh<_i26.FleetRepository>()),
    );
    gh.factory<_i877.FleetTrackingCubit>(
      () => _i877.FleetTrackingCubit(gh<_i301.GetFleetBusesUseCase>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
