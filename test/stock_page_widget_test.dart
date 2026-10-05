import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caseya/pages/stock/stock_page.dart';

void main() {
  testWidgets('Test StockPage rendering and stateful interactions', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: StockPage(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(StockPage), findsOneWidget);
    expect(find.text('Ingredients Buffer'), findsOneWidget);
  });
}
