import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/core/responsive/adaptive_list_view.dart';

void main() {
  testWidgets('AdaptiveListView renders ListView on narrow screen (< breakpoint)', (tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveListView(
            itemCount: 5,
            storageKey: 'narrow_key',
            breakpoint: 600,
            itemBuilder: (context, index) => Text('Item $index'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 4'), findsOneWidget);
  });

  testWidgets('AdaptiveListView renders GridView on wide screen (>= breakpoint)', (tester) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveListView(
            itemCount: 6,
            storageKey: 'wide_key',
            breakpoint: 600,
            maxExtent: 300,
            childAspectRatio: 1.2,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) => Text('GridItem $index'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    expect(find.text('GridItem 0'), findsOneWidget);
    expect(find.text('GridItem 5'), findsOneWidget);
  });
}
