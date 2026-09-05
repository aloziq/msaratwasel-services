import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:msaratwasel_services/features/shared/qr_scan/presentation/cubit/qr_scan_cubit.dart';
import 'package:msaratwasel_services/features/shared/qr_scan/presentation/cubit/qr_scan_state.dart';
import 'package:msaratwasel_services/features/shared/qr_scan/presentation/screens/qr_scan_screen.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

class _FakeQRScanCubit extends Cubit<QRScanState> implements QRScanCubit {
  String? lastScannedCode;
  String? lastAttendanceStudentId;
  String? lastAttendanceClassId;
  String? lastSmartTripCode;
  int onCodeScannedCount = 0;
  int markAttendanceCount = 0;
  int markSmartTripCount = 0;
  int resetCount = 0;

  _FakeQRScanCubit([QRScanState? initial]) : super(initial ?? QRScanInitial());

  @override
  void onCodeScanned(String code) {
    onCodeScannedCount++;
    lastScannedCode = code;
    emit(QRScanSuccess(code));
  }

  @override
  Future<void> markAttendanceViaQr(String studentId, String classId) async {
    markAttendanceCount++;
    lastAttendanceStudentId = studentId;
    lastAttendanceClassId = classId;
  }

  @override
  Future<void> markSmartTripAttendanceViaQr(String code) async {
    markSmartTripCount++;
    lastSmartTripCode = code;
  }

  void reset() {
    resetCount++;
    emit(QRScanInitial());
  }

  void emitState(QRScanState state) => emit(state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeQRScanCubit cubit;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    cubit = _FakeQRScanCubit();
    if (GetIt.I.isRegistered<QRScanCubit>()) {
      GetIt.I.unregister<QRScanCubit>();
    }
    GetIt.I.registerFactory<QRScanCubit>(() => cubit);
  });

  tearDown(() {
    cubit.close();
    if (GetIt.I.isRegistered<QRScanCubit>()) {
      GetIt.I.unregister<QRScanCubit>();
    }
  });

  Widget buildTestWidget({
    String? classId,
    bool isTripMode = false,
    GoRouter? router,
  }) {
    final effectiveRouter = router ??
        GoRouter(
          initialLocation: '/qr-scan',
          routes: [
            GoRoute(
              path: '/qr-scan',
              builder: (context, state) => QRScanScreen(
                classId: classId,
                isTripMode: isTripMode,
              ),
            ),
          ],
        );

    return MaterialApp.router(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: effectiveRouter,
    );
  }

  group('QRScanScreen Comprehensive Widget Tests', () {
    testWidgets('1. Mounts and displays scanner, overlay frame, and torch control', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(QRScanScreen), findsOneWidget);
      expect(find.byType(MobileScanner), findsOneWidget);
      expect(find.text(l10n.scanAttendance), findsOneWidget);
      expect(find.byIcon(Icons.flash_off), findsOneWidget);
    });

    testWidgets('2. General scan mode invokes onCodeScanned and pops with code on success', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? poppedResult;
      final router = GoRouter(
        initialLocation: '/root',
        routes: [
          GoRoute(
            path: '/root',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  poppedResult = await context.push<String>('/qr-scan');
                },
                child: const Text('OpenScan'),
              ),
            ),
          ),
          GoRoute(
            path: '/qr-scan',
            builder: (context, state) => const QRScanScreen(),
          ),
        ],
      );

      await tester.pumpWidget(buildTestWidget(router: router));
      await tester.pump();

      // Open QRScanScreen
      await tester.tap(find.text('OpenScan'));
      await tester.pumpAndSettle();
      expect(find.byType(QRScanScreen), findsOneWidget);

      // Simulate scan detection
      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect?.call(
        BarcodeCapture(barcodes: [Barcode(rawValue: 'ABC-123')]),
      );
      await tester.pump();

      expect(cubit.onCodeScannedCount, 1);
      expect(cubit.lastScannedCode, 'ABC-123');

      // Allow pop delay (1 second)
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(poppedResult, 'ABC-123');
      expect(find.byType(QRScanScreen), findsNothing);
    });

    testWidgets('3. Class mode invokes markAttendanceViaQr with studentId and classId', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget(classId: 'cls_grade_4'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect?.call(
        BarcodeCapture(barcodes: [Barcode(rawValue: 'STU-777')]),
      );
      await tester.pump();

      expect(cubit.markAttendanceCount, 1);
      expect(cubit.lastAttendanceStudentId, 'STU-777');
      expect(cubit.lastAttendanceClassId, 'cls_grade_4');

      // Drain cooldown timer
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('4. Consecutive duplicate scans are ignored (debounced)', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget(classId: 'cls_grade_4'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));

      // First scan
      scanner.onDetect?.call(
        BarcodeCapture(barcodes: [Barcode(rawValue: 'STU-888')]),
      );
      await tester.pump();
      expect(cubit.markAttendanceCount, 1);

      // Reset isProcessing in widget to test debounce logic specifically
      // Second scan with same code immediately
      scanner.onDetect?.call(
        BarcodeCapture(barcodes: [Barcode(rawValue: 'STU-888')]),
      );
      await tester.pump();
      expect(cubit.markAttendanceCount, 1); // Remains 1, debounced!

      // Drain cooldown timer
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('5. Trip mode rejects FRONT and BACK bus codes with warning', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget(isTripMode: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));

      // Scan FRONT bus code
      scanner.onDetect?.call(
        BarcodeCapture(barcodes: [Barcode(rawValue: 'BUS_FRONT_DOOR')]),
      );
      await tester.pump();

      expect(cubit.markSmartTripCount, 0);
      expect(find.text('هذا كود الحافلة وليس كود طالب.'), findsOneWidget);

      // Dismiss snackbar
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
      await tester.pump(const Duration(milliseconds: 300));

      // Scan BACK bus code
      scanner.onDetect?.call(
        BarcodeCapture(barcodes: [Barcode(rawValue: 'BUS_BACK_DOOR')]),
      );
      await tester.pump();

      expect(cubit.markSmartTripCount, 0);
      expect(find.text('هذا كود الحافلة وليس كود طالب.'), findsOneWidget);

      // Drain cooldown timer
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('6. Trip mode invokes markSmartTripAttendanceViaQr on valid student QR', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget(isTripMode: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      scanner.onDetect?.call(
        BarcodeCapture(barcodes: [Barcode(rawValue: 'STUDENT_OM_555')]),
      );
      await tester.pump();

      expect(cubit.markSmartTripCount, 1);
      expect(cubit.lastSmartTripCode, 'STUDENT_OM_555');

      // Drain cooldown timer
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('7. QRScanAttendanceSuccess displays green snackbar and resets', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget(classId: 'cls_1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      cubit.emitState(const QRScanAttendanceSuccess('std_99'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining(l10n.attendanceMarked), findsOneWidget);
      expect(find.textContaining('std_99'), findsOneWidget);

      // Advance timer for 2 seconds to verify auto-reset
      await tester.pump(const Duration(seconds: 3));
      expect(cubit.resetCount, 1);
    });

    testWidgets('8. QRScanTripSuccess displays status and details snackbar', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget(isTripMode: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      cubit.emitState(
        const QRScanTripSuccess(
          studentName: 'فيصل الهنائي',
          newStatus: 'صعود',
          message: 'تم تسجيل الصعود بنجاح',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('فيصل الهنائي'), findsOneWidget);
      expect(find.textContaining('صعود'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(cubit.resetCount, 1);
    });

    testWidgets('9. QRScanTripError displays error message and resets', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget(isTripMode: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      cubit.emitState(const QRScanTripError('لا يوجد باص مخصص'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('لا يوجد باص مخصص'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(cubit.resetCount, 1);
    });

    testWidgets('10. QRScanError displays error message and resets', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget(isTripMode: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      cubit.emitState(const QRScanError('كود غير صالح'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('كود غير صالح'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(cubit.resetCount, 1);
    });
  });
}
