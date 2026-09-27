import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caseya/main.dart';

void main() {
  testWidgets('CASEYA application launch smoke test', (WidgetTester tester) async {
    // Setup mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Set standard desktop view size for plant control room UI
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: CaseyaApp(),
      ),
    );

    // Settle animation and layout
    await tester.pumpAndSettle();

    // Verify brand and dashboard presence
    expect(find.text('CASEYA'), findsWidgets);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Product Calculator'), findsWidgets);
    expect(find.text('Milk Standardization'), findsWidgets);
    expect(find.text('Boiler Fuel'), findsWidgets);
  });
}
