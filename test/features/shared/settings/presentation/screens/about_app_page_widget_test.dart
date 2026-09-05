import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:msaratwasel_services/features/shared/settings/presentation/screens/about_app_page.dart';
import 'package:msaratwasel_services/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  Widget buildWidget({bool isDark = false, Locale locale = const Locale('ar')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const AboutAppPage(),
    );
  }

  Future<void> pumpAnimations(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
  }

  group('AboutAppPage Comprehensive Widget Tests', () {
    testWidgets('1. Mounts and displays app branding, version, and section cards in Arabic', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await pumpAnimations(tester);

      expect(find.byType(AboutAppPage), findsOneWidget);
      expect(find.text(l10n.aboutApp), findsWidgets);
      expect(find.text(l10n.appName), findsOneWidget);
      expect(find.textContaining('2.0.0'), findsOneWidget);
      expect(find.text(l10n.aboutCompanyTitle), findsOneWidget);
      expect(find.text(l10n.aboutCompany), findsOneWidget);
      expect(find.text(l10n.developedBy), findsOneWidget);
      expect(find.text('Silicon Apex (SA)'), findsOneWidget);
      expect(find.byIcon(FontAwesomeIcons.circleInfo), findsOneWidget);
      expect(find.byIcon(FontAwesomeIcons.building), findsOneWidget);
      expect(find.byIcon(Icons.code_rounded), findsOneWidget);
    });

    testWidgets('2. Renders in dark theme with dark shadows and borders', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget(isDark: true));
      await pumpAnimations(tester);

      expect(find.byType(AboutAppPage), findsOneWidget);
      expect(find.text('Silicon Apex (SA)'), findsOneWidget);
    });

    testWidgets('3. Renders in English locale properly', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final enL10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.pumpWidget(buildWidget(locale: const Locale('en')));
      await pumpAnimations(tester);

      expect(find.text(enL10n.aboutApp), findsWidgets);
      expect(find.text(enL10n.aboutCompanyTitle), findsOneWidget);
      expect(find.text(enL10n.developedBy), findsOneWidget);
    });
  });
}
