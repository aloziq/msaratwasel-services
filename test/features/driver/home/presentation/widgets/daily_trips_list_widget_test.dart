import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:msaratwasel_services/features/driver/home/domain/entities/trip_status.dart';
import 'package:msaratwasel_services/features/driver/home/presentation/widgets/daily_trips_list.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ar');
    await initializeDateFormatting('en');
  });

  Widget createWidget({
    required List<TripStatus> trips,
    bool isArabic = true,
    bool isDark = false,
    UserRole userRole = UserRole.driver,
    Function(TripStatus)? onTripAction,
    Function(TripStatus)? onConfirm,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DailyTripsList(
            trips: trips,
            isArabic: isArabic,
            isDark: isDark,
            userRole: userRole,
            onTripAction: onTripAction ?? (_) {},
            onConfirm: onConfirm ?? (_) {},
          ),
        ),
      ),
    );
  }

  Future<void> pumpAnimations(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('DailyTripsList Widget Tests', () {
    testWidgets('1. Displays empty state message in Arabic and English', (tester) async {
      // Arabic empty state
      await tester.pumpWidget(createWidget(trips: [], isArabic: true));
      await tester.pump();
      expect(find.text('لا توجد رحلات متبقية اليوم'), findsOneWidget);

      // English empty state
      await tester.pumpWidget(createWidget(trips: [], isArabic: false));
      await tester.pump();
      expect(find.text('No more trips today'), findsOneWidget);
    });

    testWidgets('2. Sorts trips properly: active before completed, forth before back', (tester) async {
      final tripCompletedForth = const TripStatus(
        id: '1',
        type: 'forth',
        typeLabel: 'ذهاب',
        status: 'finished',
        departureTime: '07:00',
        totalStudents: 15,
        isCompleted: true,
      );
      final tripActiveBack = const TripStatus(
        id: '2',
        type: 'back',
        typeLabel: 'إياب',
        status: 'pending',
        departureTime: '13:00',
        totalStudents: 15,
        isCompleted: false,
      );
      final tripActiveForth = const TripStatus(
        id: '3',
        type: 'forth',
        typeLabel: 'ذهاب',
        status: 'in_progress',
        departureTime: '06:30',
        totalStudents: 15,
        isCompleted: false,
      );

      await tester.pumpWidget(createWidget(
        trips: [tripCompletedForth, tripActiveBack, tripActiveForth],
      ));
      await pumpAnimations(tester);

      // Expected sort:
      // Active first: tripActiveForth (forth), then tripActiveBack (back)
      // Completed last: tripCompletedForth
      final textWidgets = tester.widgetList<Text>(find.textContaining('#')).toList();
      expect(textWidgets.length, 3);
      expect(textWidgets[0].data, contains('#3'));
      expect(textWidgets[1].data, contains('#2'));
      expect(textWidgets[2].data, contains('#1'));
    });

    testWidgets('3. Pending trip renders correctly and handles onTripAction', (tester) async {
      TripStatus? actionedTrip;
      final pendingTrip = const TripStatus(
        id: '101',
        type: 'forth',
        typeLabel: 'ذهاب',
        status: 'pending',
        departureTime: '07:30',
        totalStudents: 22,
        routeName: 'Route No. 5',
      );

      // Arabic
      await tester.pumpWidget(createWidget(
        trips: [pendingTrip],
        isArabic: true,
        userRole: UserRole.driver,
        onTripAction: (trip) => actionedTrip = trip,
      ));
      await pumpAnimations(tester);

      expect(find.text('جاهز للانطلاق'), findsOneWidget);
      expect(find.text('بدء الرحلة'), findsOneWidget);
      expect(find.text('المسار رقم 5'), findsOneWidget);
      expect(find.text('وقت المغادرة'), findsOneWidget);
      expect(find.text('الطلاب'), findsOneWidget);
      expect(find.text('22'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.text('بدء الرحلة'));
      await tester.pump();
      expect(actionedTrip?.id, '101');

      // English
      await tester.pumpWidget(createWidget(
        trips: [pendingTrip],
        isArabic: false,
        userRole: UserRole.driver,
      ));
      await pumpAnimations(tester);

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Start Trip'), findsOneWidget);
      expect(find.text('Departure'), findsOneWidget);
      expect(find.text('Students'), findsOneWidget);
    });

    testWidgets('4. Awaiting confirmation trip handles driver vs assistant/fieldSupervisor roles', (tester) async {
      TripStatus? confirmedTrip;
      final awaitingTrip = const TripStatus(
        id: '202',
        type: 'back',
        typeLabel: 'إياب',
        status: 'awaiting_confirmation',
        departureTime: '13:30',
        totalStudents: 18,
      );

      // Driver role: button disabled, text 'بانتظار المشرفة'
      await tester.pumpWidget(createWidget(
        trips: [awaitingTrip],
        isArabic: true,
        userRole: UserRole.driver,
      ));
      await pumpAnimations(tester);

      expect(find.text('بانتظار التأكيد'), findsOneWidget);
      expect(find.text('بانتظار المشرفة'), findsOneWidget);
      final driverBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(driverBtn.onPressed, isNull);

      // English for driver
      await tester.pumpWidget(createWidget(
        trips: [awaitingTrip],
        isArabic: false,
        userRole: UserRole.driver,
      ));
      await pumpAnimations(tester);
      expect(find.text('Awaiting Confirmation'), findsOneWidget);
      expect(find.text('Waiting...'), findsOneWidget);

      // Assistant role: button enabled, text 'قبول وبدء التنفيذ'
      await tester.pumpWidget(createWidget(
        trips: [awaitingTrip],
        isArabic: true,
        userRole: UserRole.assistant,
        onConfirm: (trip) => confirmedTrip = trip,
      ));
      await pumpAnimations(tester);

      expect(find.text('قبول وبدء التنفيذ'), findsOneWidget);
      final assistantBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(assistantBtn.onPressed, isNotNull);

      await tester.tap(find.text('قبول وبدء التنفيذ'));
      await tester.pump();
      expect(confirmedTrip?.id, '202');

      // FieldSupervisor role in English
      await tester.pumpWidget(createWidget(
        trips: [awaitingTrip],
        isArabic: false,
        userRole: UserRole.fieldSupervisor,
      ));
      await pumpAnimations(tester);
      expect(find.text('Accept and Start'), findsOneWidget);
    });

    testWidgets('5. In progress trip displays resume action and invokes onTripAction', (tester) async {
      TripStatus? actionedTrip;
      final inProgressTrip = const TripStatus(
        id: '303',
        type: 'forth',
        typeLabel: 'ذهاب',
        status: 'in_progress',
        departureTime: '08:00',
        totalStudents: 10,
      );

      // Arabic
      await tester.pumpWidget(createWidget(
        trips: [inProgressTrip],
        isArabic: true,
        userRole: UserRole.driver,
        onTripAction: (trip) => actionedTrip = trip,
      ));
      await pumpAnimations(tester);

      expect(find.text('الرحلة قيد التشغيل'), findsOneWidget);
      expect(find.text('مواصلة الرحلة'), findsOneWidget);
      await tester.tap(find.text('مواصلة الرحلة'));
      await tester.pump();
      expect(actionedTrip?.id, '303');

      // English
      await tester.pumpWidget(createWidget(
        trips: [inProgressTrip],
        isArabic: false,
        userRole: UserRole.driver,
      ));
      await pumpAnimations(tester);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Resume Trip'), findsOneWidget);
    });

    testWidgets('6. Finished trip hides action button and displays checkCircle icon', (tester) async {
      final finishedTrip = const TripStatus(
        id: '404',
        type: 'back',
        typeLabel: 'إياب',
        status: 'finished',
        departureTime: '12:00',
        totalStudents: 25,
        isCompleted: true,
      );

      await tester.pumpWidget(createWidget(
        trips: [finishedTrip],
        isArabic: true,
      ));
      await pumpAnimations(tester);

      expect(find.text('مكتملة'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byIcon(PhosphorIconsFill.checkCircle), findsOneWidget);

      // English
      await tester.pumpWidget(createWidget(
        trips: [finishedTrip],
        isArabic: false,
      ));
      await pumpAnimations(tester);
      expect(find.text('Finished'), findsOneWidget);
    });

    testWidgets('7. Custom status fallback and null routeName', (tester) async {
      final customTrip = const TripStatus(
        id: '505',
        type: 'other',
        typeLabel: 'خاصة',
        status: 'custom_state',
        departureTime: '09:00',
        totalStudents: 5,
        routeName: null,
      );

      await tester.pumpWidget(createWidget(
        trips: [customTrip],
        isArabic: true,
      ));
      await pumpAnimations(tester);

      expect(find.text('custom_state'), findsOneWidget);
      expect(find.text('بدون مسار'), findsNothing); // routeName null hides route container
    });

    testWidgets('8. Route name localized replacements (English to Arabic & Arabic to English)', (tester) async {
      // Test getLocalizedRouteName through rendering
      final trip1 = const TripStatus(
        id: '601',
        departureTime: '07:00',
        totalStudents: 10,
        routeName: 'Route 12',
      );
      final trip2 = const TripStatus(
        id: '602',
        departureTime: '07:00',
        totalStudents: 10,
        routeName: 'مسار رقم 8',
      );

      // In Arabic: 'Route 12' becomes 'مسار 12'
      await tester.pumpWidget(createWidget(trips: [trip1], isArabic: true));
      await pumpAnimations(tester);
      expect(find.text('مسار 12'), findsOneWidget);

      // In English: 'مسار رقم 8' becomes 'Route No. 8'
      await tester.pumpWidget(createWidget(trips: [trip2], isArabic: false));
      await pumpAnimations(tester);
      expect(find.text('Route No. 8'), findsOneWidget);
    });

    testWidgets('9. Time formatting with ISO datetime and fallback parsing', (tester) async {
      final tripIso = const TripStatus(
        id: '701',
        departureTime: '2026-09-05T14:30:00.000Z',
        totalStudents: 12,
      );
      final tripFallback = const TripStatus(
        id: '702',
        departureTime: '10:15 AM',
        totalStudents: 8,
      );

      // Arabic rendering
      await tester.pumpWidget(createWidget(trips: [tripIso, tripFallback], isArabic: true));
      await pumpAnimations(tester);

      // In Arabic, AM/PM is replaced with ص/م
      expect(find.textContaining('ص'), findsWidgets);

      // English rendering
      await tester.pumpWidget(createWidget(trips: [tripIso, tripFallback], isArabic: false));
      await pumpAnimations(tester);
      expect(find.textContaining('10:15 AM'), findsOneWidget);
    });

    testWidgets('10. Renders in dark theme seamlessly', (tester) async {
      final trip = const TripStatus(
        id: '801',
        type: 'forth',
        typeLabel: 'ذهاب',
        status: 'pending',
        departureTime: '07:00',
        totalStudents: 20,
        routeName: 'المسار رقم 1',
      );

      await tester.pumpWidget(createWidget(
        trips: [trip],
        isDark: true,
      ));
      await pumpAnimations(tester);

      expect(find.byType(DailyTripsList), findsOneWidget);
      expect(find.text('جاهز للانطلاق'), findsOneWidget);
      expect(find.text('المسار رقم 1'), findsOneWidget);
    });
  });

  group('Pure helper unit tests for coverage edge cases', () {
    test('getLocalizedType coverage', () {
      expect(getLocalizedType('forth', 'ذهاب', true), 'ذهاب');
      expect(getLocalizedType('back', 'إياب', true), 'إياب');
      expect(getLocalizedType('forth', 'go', false), 'Go');
      expect(getLocalizedType('other', 'return', false), 'Return');
    });

    test('getLocalizedRouteName coverage', () {
      expect(getLocalizedRouteName(null, true), 'بدون مسار');
      expect(getLocalizedRouteName(null, false), 'No Route');
      expect(getLocalizedRouteName('Route No. 3', true), 'المسار رقم 3');
      expect(getLocalizedRouteName('Route 4', true), 'مسار 4');
      expect(getLocalizedRouteName('No. 5', true), 'رقم 5');
      expect(getLocalizedRouteName('المسار رقم 3', false), 'Route No. 3');
      expect(getLocalizedRouteName('مسار رقم 4', false), 'Route No. 4');
      expect(getLocalizedRouteName('مسار 5', false), 'Route 5');
    });
  });
}
