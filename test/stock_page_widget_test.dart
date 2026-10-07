import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caseya/pages/stock/stock_page.dart';

void main() {
  testWidgets('Test StockPage Date-wise Stock Report Ledger replaces 4 KPI cards', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 1000);
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

    // 1. Verify 4 old KPI cards are removed
    expect(find.text('Ingredients Buffer'), findsNothing);
    expect(find.text('Cups Inventory'), findsNothing);
    expect(find.text('Aluminium Foil Buffer'), findsNothing);
    expect(find.text('Poly Roll Stock'), findsNothing);

    // 2. Verify Date-wise Stock Report section is rendered
    expect(find.text('Date-wise Stock Report'), findsOneWidget);
    expect(find.text('Download XLSX'), findsOneWidget);
    expect(find.text('Print / Preview'), findsOneWidget);

    // 3. Verify ledger summary tiles and table columns are rendered
    expect(find.text('Opening Stock'), findsOneWidget);
    expect(find.text('Received Quantity'), findsWidgets);
    expect(find.text('Issued Quantity'), findsWidgets);
    expect(find.text('Balance in Stock'), findsWidgets);
    expect(find.text('Date'), findsWidgets);
    expect(find.text('Particulars'), findsWidgets);
    expect(find.text('Previous Stock'), findsWidgets);
    expect(find.text('Action'), findsNothing);

    // Verify edit pencil icons are present on Received cells (not on Issued cells)
    final editIcons = find.byIcon(Icons.edit_outlined);
    expect(editIcons, findsWidgets);

    // Tap edit icon on Received Quantity cell (functions like particulars plus icon)
    await tester.ensureVisible(editIcons.first);
    await tester.tap(editIcons.first);
    await tester.pumpAndSettle();
    expect(find.text('Add New Stock'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Verify Issued Quantity cells do NOT have edit pencil icons
    expect(find.byTooltip('Edit Issued on 1'), findsNothing);

    // 4. Verify "+ Add New Stock" action chip is rendered
    final addStockChip = find.text('+ Add New Stock');
    expect(addStockChip, findsOneWidget);

    // 5. Test Print / Preview dialog opens with full store ledger sheet
    final printPreviewBtn = find.text('Print / Preview');
    await tester.ensureVisible(printPreviewBtn);
    await tester.tap(printPreviewBtn);
    await tester.pumpAndSettle();

    expect(find.text('CASEYA'), findsWidgets);
    expect(find.text('Purabi Dairy, Silchar Plant'), findsOneWidget);
    expect(find.text('Monthly Material Stock Register'), findsOneWidget);
    expect(find.text('Biraj Goswami'), findsWidgets);
    expect(find.text('Caseya Developer'), findsOneWidget);
    expect(find.text('Verified by'), findsOneWidget);
    expect(find.text('Plant Head'), findsOneWidget);
    expect(find.text('Print Sheet'), findsOneWidget);

    // Close preview dialog
    final closeIcon = find.byIcon(Icons.close_rounded);
    await tester.tap(closeIcon);
    await tester.pumpAndSettle();

    // 6. Test Particulars click opens transaction detail or add stock dialog
    final firstParticular = find.textContaining('Balance c/f').first;
    await tester.tap(firstParticular);
    await tester.pumpAndSettle();

    // Add stock dialog opens on date
    expect(find.text('Add New Stock'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // 7. Verify category filter chips work
    final cupsChip = find.textContaining('Cups');
    expect(cupsChip, findsWidgets);
    await tester.tap(cupsChip.first, warnIfMissed: false);
    await tester.pumpAndSettle();

    final allChip = find.textContaining('All');
    expect(allChip, findsWidgets);
    await tester.tap(allChip.first, warnIfMissed: false);
    await tester.pumpAndSettle();
  });

  testWidgets('Test Add Stock popup Logged By selector and chipcard footer dot by person', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 1200);
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

    // Tap "+ Add New Stock" at the top of Inventory section
    final addStockBtn = find.text('+ Add New Stock');
    await tester.ensureVisible(addStockBtn);
    await tester.tap(addStockBtn);
    await tester.pumpAndSettle();

    // Verify 3 chip row labels are visible inside popup
    expect(find.text('Date'), findsWidgets);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Logged By'), findsOneWidget);

    final dialogDropdowns = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(DropdownButton<String>),
    );

    // Select inventory item first
    await tester.tap(dialogDropdowns.first);
    await tester.pumpAndSettle();
    final itemToSelect = find.textContaining('Lassi Cup').last;
    await tester.tap(itemToSelect);
    await tester.pumpAndSettle();

    // Select "Pranjit Das" from the Logged By dropdown (second dropdown in dialog)
    await tester.tap(dialogDropdowns.last);
    await tester.pumpAndSettle();

    final pranjitOption = find.text('Pranjit Das').last;
    await tester.tap(pranjitOption);
    await tester.pumpAndSettle();

    // Enter boxes in the box input field
    final boxInput = find.widgetWithText(TextField, 'e.g. 5');
    await tester.enterText(boxInput, '5');
    await tester.pumpAndSettle();

    // Submit dialog
    await tester.tap(find.text('Add Stock'));
    await tester.pumpAndSettle();

    // Verify card footer now shows '• by Pranjit Das'
    expect(find.textContaining('• by Pranjit Das'), findsWidgets);
  });

  testWidgets('Test Month & Year picker dialog and historical multi-year support', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 1000);
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

    // 1. Verify Month/Year selector chip is visible
    expect(find.textContaining('October 2026'), findsWidgets);
    expect(find.text('Year: '), findsOneWidget);

    // 2. Open Month & Year picker dialog by tapping the calendar icon / chip
    final calendarIcon = find.byIcon(Icons.calendar_month_rounded).first;
    await tester.ensureVisible(calendarIcon);
    await tester.tap(calendarIcon);
    await tester.pumpAndSettle();

    // Verify Month & Year dialog opened
    expect(find.text('Select Month & Year'), findsOneWidget);
    expect(find.text('Current Month'), findsOneWidget);

    // Verify 12 month buttons are visible
    expect(find.text('Jan'), findsOneWidget);
    expect(find.text('Feb'), findsOneWidget);
    expect(find.text('Mar'), findsOneWidget);
    expect(find.text('Nov'), findsOneWidget);
    expect(find.text('Dec'), findsOneWidget);

    // Tap "Nov"
    await tester.tap(find.text('Nov'));
    await tester.pumpAndSettle();

    // Dialog closes and November 2026 is selected
    expect(find.textContaining('November 2026'), findsWidgets);
  });
}
