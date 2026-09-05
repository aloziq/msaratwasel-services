import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:msaratwasel_services/config/settings/settings_controller.dart';
import 'package:msaratwasel_services/config/theme/app_theme.dart';
import 'package:msaratwasel_services/config/theme/theme_controller.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/domain/entities/fleet_bus.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/presentation/cubit/fleet_tracking_cubit.dart';
import 'package:msaratwasel_services/features/field_supervisor/buses/presentation/screens/buses_list_screen.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_cubit.dart';
import 'package:msaratwasel_services/features/shared/auth/presentation/cubit/auth_state.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class _FakeFleetTrackingCubit extends Cubit<FleetTrackingState>
    implements FleetTrackingCubit {
  _FakeFleetTrackingCubit(super.initialState);

  bool loadFleetCalled = false;
  String? selectedId;
  bool clearSelectionCalled = false;

  @override
  Future<void> loadFleet() async {
    loadFleetCalled = true;
  }

  @override
  void selectBus(String busId) {
    selectedId = busId;
    if (state is FleetTrackingLoaded) {
      final cur = state as FleetTrackingLoaded;
      emit(cur.copyWith(selectedBusId: busId));
    }
  }

  @override
  void clearSelection() {
    clearSelectionCalled = true;
    if (state is FleetTrackingLoaded) {
      final cur = state as FleetTrackingLoaded;
      emit(cur.copyWith(clearSelection: true));
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  _FakeAuthCubit()
      : super(
          const AuthAuthenticated(
            UserEntity(
              id: 'sup_1',
              name: 'المشرف',
              role: UserRole.fieldSupervisor,
              token: 'tok_sup',
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeController themeController;
  late SettingsController settingsController;
  late _FakeAuthCubit authCubit;
  late _FakeFleetTrackingCubit fleetCubit;

  final sampleBuses = [
    FleetBus(
      id: 'bus_1',
      name: 'حافلة 101',
      driverName: 'سالم السائق',
      supervisorName: 'فاطمة المشرفة',
      schoolName: 'مدرسة الأمل',
      driverPhone: '0551111111',
      route: 'مسار 1',
      lat: 23.5880,
      lng: 58.3829,
      speedKmh: 40.0,
      studentsOnBoard: 12,
      status: FleetBusStatus.active,
      updatedAt: DateTime(2026, 9, 5),
    ),
    FleetBus(
      id: 'bus_2',
      name: 'حافلة 102',
      driverName: 'خالد السائق',
      supervisorName: 'مريم المشرفة',
      schoolName: 'مدرسة المجد',
      driverPhone: '0552222222',
      route: 'مسار 2',
      lat: 23.5900,
      lng: 58.3850,
      speedKmh: 0.0,
      studentsOnBoard: 0,
      status: FleetBusStatus.stopped,
      updatedAt: DateTime(2026, 9, 5),
    ),
    FleetBus(
      id: 'bus_3',
      name: 'حافلة 103',
      driverName: 'فهد السائق',
      supervisorName: 'نورة المشرفة',
      schoolName: 'مدرسة النور',
      driverPhone: '0553333333',
      route: 'مسار 3',
      lat: 23.6000,
      lng: 58.3900,
      speedKmh: 0.0,
      studentsOnBoard: 0,
      status: FleetBusStatus.maintenance,
      updatedAt: DateTime(2026, 9, 5),
    ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    if (!GetIt.I.isRegistered<SharedPreferences>()) {
      GetIt.I.registerSingleton<SharedPreferences>(prefs);
    }

    themeController = ThemeController();
    await themeController.load();
    settingsController = SettingsController();
    await settingsController.load();

    authCubit = _FakeAuthCubit();
    fleetCubit = _FakeFleetTrackingCubit(FleetTrackingInitial());

    if (GetIt.I.isRegistered<FleetTrackingCubit>()) {
      GetIt.I.unregister<FleetTrackingCubit>();
    }
    GetIt.I.registerFactory<FleetTrackingCubit>(() => fleetCubit);
  });

  tearDown(() {
    if (GetIt.I.isRegistered<FleetTrackingCubit>()) {
      GetIt.I.unregister<FleetTrackingCubit>();
    }
    authCubit.close();
    fleetCubit.close();
  });

  Widget buildTestScreen({ThemeData? theme}) {
    return ThemeProvider(
      controller: themeController,
      child: SettingsProvider(
        controller: settingsController,
        child: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: MaterialApp(
            theme: theme ?? AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ar'),
            home: const BusesListScreen(),
          ),
        ),
      ),
    );
  }

  group('BusesListScreen Widget Tests', () {
    testWidgets('1. Shows loading indicator when state is FleetTrackingLoading or Initial', (tester) async {
      fleetCubit.emit(FleetTrackingLoading());

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(fleetCubit.loadFleetCalled, isTrue);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('2. Shows error message when state is FleetTrackingError', (tester) async {
      fleetCubit.emit(const FleetTrackingError('تعذر تحميل بيانات الأسطول'));

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      expect(find.text('تعذر تحميل بيانات الأسطول'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('3. Renders GoogleMap, header, and stats row when FleetTrackingLoaded', (tester) async {
      fleetCubit.emit(const FleetTrackingLoaded([]));

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Verify Google Map is present
      expect(find.byType(GoogleMap), findsOneWidget);

      // Verify stats chips (all 0 for empty fleet)
      expect(find.text('0'), findsNWidgets(3));

      // Verify header action buttons (menu, my_location)
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);

      // Tap location button to trigger _fitAllBuses
      await tester.tap(find.byIcon(Icons.my_location_rounded));
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('4. Displays _BusDetailSheet when selectedBus is present', (tester) async {
      fleetCubit.emit(FleetTrackingLoaded([sampleBuses.first], selectedBusId: 'bus_1'));

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      // Verify bus details in bottom sheet
      expect(find.text('حافلة 101'), findsOneWidget);
      expect(find.text('سالم السائق'), findsOneWidget);
      expect(find.text('فاطمة المشرفة'), findsOneWidget);
      expect(find.text('مدرسة الأمل'), findsOneWidget);
      expect(find.text('تتبع الحافلة الآن'), findsOneWidget);

      // Tap close button on the sheet
      final closeBtn = find.byIcon(Icons.close_rounded);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pump();

      expect(fleetCubit.clearSelectionCalled, isTrue);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('5. Renders correctly in Dark Mode with stopped bus selected', (tester) async {
      fleetCubit.emit(FleetTrackingLoaded([sampleBuses[1]], selectedBusId: 'bus_2'));

      await tester.pumpWidget(buildTestScreen(theme: AppTheme.dark));
      await tester.pump();

      expect(find.text('حافلة 102'), findsOneWidget);
      expect(find.text('خالد السائق'), findsOneWidget);
      expect(find.text('مريم المشرفة'), findsOneWidget);
      expect(find.text('مدرسة المجد'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('6. Renders maintenance bus status in _BusDetailSheet', (tester) async {
      fleetCubit.emit(FleetTrackingLoaded([sampleBuses[2]], selectedBusId: 'bus_3'));

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();

      expect(find.text('حافلة 103'), findsOneWidget);
      expect(find.text('فهد السائق'), findsOneWidget);
      expect(find.text('نورة المشرفة'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
