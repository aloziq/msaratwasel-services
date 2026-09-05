import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

import 'package:msaratwasel_services/config/theme/theme_controller.dart';
import 'package:msaratwasel_services/config/settings/settings_controller.dart';
import 'package:msaratwasel_services/core/services/direction_service.dart';
import 'package:msaratwasel_services/core/presentation/extensions/user_role_extension.dart';
import 'package:msaratwasel_services/features/shared/auth/domain/entities/user_entity.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. ThemeController & ThemeProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('load sets system mode when no preference stored', () async {
      final controller = ThemeController();
      await controller.load();
      expect(controller.mode, ThemeMode.system);
    });

    test('load recovers stored light and dark modes', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final controller = ThemeController();
      await controller.load();
      expect(controller.mode, ThemeMode.dark);

      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final lightController = ThemeController();
      await lightController.load();
      expect(lightController.mode, ThemeMode.light);
    });

    test('setMode updates mode, notifies listeners and persists value', () async {
      final controller = ThemeController();
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.setMode(ThemeMode.dark);
      expect(controller.mode, ThemeMode.dark);
      expect(notifyCount, 1);

      // Setting same mode should not notify again
      await controller.setMode(ThemeMode.dark);
      expect(notifyCount, 1);

      await controller.setMode(ThemeMode.light);
      expect(controller.mode, ThemeMode.light);
      expect(notifyCount, 2);

      await controller.setMode(ThemeMode.system);
      expect(controller.mode, ThemeMode.system);
      expect(notifyCount, 3);
    });

    testWidgets('ThemeProvider provides controller to widget tree', (tester) async {
      final controller = ThemeController();
      late ThemeController retrievedController;

      await tester.pumpWidget(
        ThemeProvider(
          controller: controller,
          child: Builder(
            builder: (context) {
              retrievedController = ThemeProvider.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(retrievedController, equals(controller));
    });

    testWidgets('ThemeProvider.of throws FlutterError when provider is missing', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(
              () => ThemeProvider.of(context),
              throwsA(isA<FlutterError>()),
            );
            return const SizedBox();
          },
        ),
      );
    });
  });

  group('2. SettingsController & SettingsProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('load defaults to system locale and 1.0 font scale', () async {
      final controller = SettingsController();
      await controller.load();
      expect(controller.locale, isNull);
      expect(controller.isSystemLocale, isTrue);
      expect(controller.fontScale, 1.0);
    });

    test('load restores saved locale and clamped font scale', () async {
      SharedPreferences.setMockInitialValues({
        'app_locale': 'en',
        'app_font_scale': 1.3,
      });

      final controller = SettingsController();
      await controller.load();
      expect(controller.locale, const Locale('en'));
      expect(controller.isSystemLocale, isFalse);
      expect(controller.fontScale, 1.3);

      // Test font scale clamping (below 0.8 clamped to 0.8, above 1.4 clamped to 1.4)
      SharedPreferences.setMockInitialValues({
        'app_locale': 'system',
        'app_font_scale': 2.5,
      });
      final clampedController = SettingsController();
      await clampedController.load();
      expect(clampedController.fontScale, 1.4);
      expect(clampedController.isSystemLocale, isTrue);
    });

    test('setFontScale clamps value and persists', () async {
      final controller = SettingsController();
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.setFontScale(1.2);
      expect(controller.fontScale, 1.2);
      expect(notifyCount, 1);

      // Setting same scale should not trigger notification
      await controller.setFontScale(1.2);
      expect(notifyCount, 1);

      await controller.setFontScale(0.5); // Should clamp to 0.8
      expect(controller.fontScale, 0.8);
      expect(notifyCount, 2);

      await controller.setFontScale(1.8); // Should clamp to 1.4
      expect(controller.fontScale, 1.4);
      expect(notifyCount, 3);
    });

    test('setLocale updates locale and notifies listeners safely without auth service', () async {
      final controller = SettingsController();
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.setLocale(const Locale('ar'));
      expect(controller.locale, const Locale('ar'));
      expect(notifyCount, 1);

      // Setting same locale is a no-op
      await controller.setLocale(const Locale('ar'));
      expect(notifyCount, 1);

      await controller.setLocale(null); // Back to system
      expect(controller.locale, isNull);
      expect(controller.isSystemLocale, isTrue);
      expect(notifyCount, 2);
    });

    testWidgets('SettingsProvider provides controller to tree or throws if missing', (tester) async {
      final controller = SettingsController();
      late SettingsController retrieved;

      await tester.pumpWidget(
        SettingsProvider(
          controller: controller,
          child: Builder(
            builder: (context) {
              retrieved = SettingsProvider.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(retrieved, equals(controller));

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(
              () => SettingsProvider.of(context),
              throwsA(isA<FlutterError>()),
            );
            return const SizedBox();
          },
        ),
      );
    });
  });

  group('3. DirectionService Tests', () {
    test('clearCache empties in-memory directions cache', () {
      final service = DirectionService();
      expect(() => service.clearCache(), returnsNormally);
    });
  });

  group('4. UserRoleExtension (UserRoleX) Tests', () {
    testWidgets('getDisplayName returns localized role names', (tester) async {
      late String driverName;
      late String assistantName;
      late String supervisorName;
      late String teacherName;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: Builder(
            builder: (context) {
              driverName = UserRole.driver.getDisplayName(context);
              assistantName = UserRole.assistant.getDisplayName(context);
              supervisorName = UserRole.fieldSupervisor.getDisplayName(context);
              teacherName = UserRole.teacher.getDisplayName(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(driverName.isNotEmpty, isTrue);
      expect(assistantName.isNotEmpty, isTrue);
      expect(supervisorName.isNotEmpty, isTrue);
      expect(teacherName.isNotEmpty, isTrue);
    });
  });
}
