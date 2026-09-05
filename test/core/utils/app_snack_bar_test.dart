import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/core/utils/app_snack_bar.dart';

void main() {
  testWidgets('AppSnackBar displays error, warning, success, info messages and titles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () => AppSnackBar.showError(context, 'خطأ فادح', title: 'تنبيه خطأ'),
                  child: const Text('Show Error'),
                ),
                ElevatedButton(
                  onPressed: () => AppSnackBar.showWarning(context, 'تحذير هام', title: 'تنبيه تحذير'),
                  child: const Text('Show Warning'),
                ),
                ElevatedButton(
                  onPressed: () => AppSnackBar.showSuccess(context, 'تمت العملية بنجاح', title: 'نجاح'),
                  child: const Text('Show Success'),
                ),
                ElevatedButton(
                  onPressed: () => AppSnackBar.showInfo(context, 'معلومة إضافية'),
                  child: const Text('Show Info'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 1. Show Error
    await tester.tap(find.text('Show Error'));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 750)); // Allow snackbar to appear

    expect(find.text('تنبيه خطأ'), findsOneWidget);
    expect(find.text('خطأ فادح'), findsOneWidget);

    // 2. Show Warning (replaces current snackbar)
    await tester.tap(find.text('Show Warning'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.text('تنبيه تحذير'), findsOneWidget);
    expect(find.text('تحذير هام'), findsOneWidget);

    // 3. Show Success
    await tester.tap(find.text('Show Success'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.text('نجاح'), findsOneWidget);
    expect(find.text('تمت العملية بنجاح'), findsOneWidget);

    // 4. Show Info (without title)
    await tester.tap(find.text('Show Info'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.text('معلومة إضافية'), findsOneWidget);
  });
}
