import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caseya/pages/stock/stock_page.dart';

void main() {
  testWidgets('Test StockPage rendering and stateful interactions', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

    // Verify "+ Add New Stock" action chip is rendered
    final addStockChip = find.text('+ Add New Stock');
    expect(addStockChip, findsOneWidget);

    // Verify "Last updated:" text is present on inventory cards
    expect(find.textContaining('Last updated:'), findsWidgets);

    // Tap the "+ Add New Stock" action chip
    await tester.tap(addStockChip);
    await tester.pumpAndSettle();

    // Verify dialog opens with simplified title and inputs
    expect(find.text('Add New Stock'), findsOneWidget);
    expect(find.text('Select Inventory Item *'), findsOneWidget);
    expect(find.text('Select Inventory Item'), findsOneWidget);
    expect(find.text('Add Stock'), findsOneWidget);

    // Verify Cancel button works
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Verify dialog dismissed
    expect(find.text('Add New Stock'), findsNothing);

    // Reopen dialog to test stock addition with item selection
    await tester.tap(addStockChip);
    await tester.pumpAndSettle();

    // Tap dropdown to open dropdown list
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    // Select the first item from the dropdown
    final itemToSelect = find.textContaining('Lassi Cup').last;
    await tester.tap(itemToSelect);
    await tester.pumpAndSettle();

    // Enter boxes in the box input field
    final boxInput = find.widgetWithText(TextField, 'e.g. 5');
    expect(boxInput, findsOneWidget);
    await tester.enterText(boxInput, '10');
    await tester.pumpAndSettle();

    // Tap confirm button
    await tester.tap(find.text('Add Stock'));
    await tester.pumpAndSettle();

    // Verify dialog dismissed and returned to stock page
    expect(find.text('Add New Stock'), findsNothing);
    expect(find.byType(StockPage), findsOneWidget);

    // Verify card "+ Add Stock" button opens preselected dialog
    final cardAddBtn = find.text('+ Add Stock').first;
    await tester.tap(cardAddBtn);
    await tester.pumpAndSettle();
    expect(find.text('Add New Stock'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
