import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'inventory_item_model.dart';
import '../core/utils/formatters.dart';

/// Represents a single daily row in the date-wise monthly store ledger
class StockLedgerDayRow {
  final DateTime date;
  final String dateDisplay; // e.g. '01 Oct 2026' or '01/10/2026'
  final String particulars;
  final double previousStock; // opening stock of that day
  final double receiptQty; // inward stock added on that day
  final double issuedQty; // stock consumed by production on that day
  final double balanceStock; // closing stock = previousStock + receiptQty - issuedQty
  final List<InwardStockEntry> inwardEntries;
  final List<StockDeductionEntry> deductionEntries;

  const StockLedgerDayRow({
    required this.date,
    required this.dateDisplay,
    required this.particulars,
    required this.previousStock,
    required this.receiptQty,
    required this.issuedQty,
    required this.balanceStock,
    this.inwardEntries = const [],
    this.deductionEntries = const [],
  });

  bool get hasActivity => receiptQty > 0.0001 || issuedQty > 0.0001;
}

/// Result of monthly ledger computation containing rows and totals
class MonthlyStockLedgerResult {
  final InventoryItemModel item;
  final DateTime month;
  final double openingStock;
  final double totalReceipts;
  final double totalIssues;
  final double closingStock;
  final List<StockLedgerDayRow> rows;

  const MonthlyStockLedgerResult({
    required this.item,
    required this.month,
    required this.openingStock,
    required this.totalReceipts,
    required this.totalIssues,
    required this.closingStock,
    required this.rows,
  });

  /// Generates clean CSV content for export or printing
  String toCsv() {
    final buffer = StringBuffer();
    final monthStr = DateFormat('MMMM yyyy').format(month);
    buffer.writeln('CASEYA PLANT INVENTORY & STORE LEDGER');
    buffer.writeln('Material:,"${item.name}"');
    buffer.writeln('Category:,"${item.category}"');
    buffer.writeln('Base Unit:,"${item.baseUnit}"');
    buffer.writeln('Period:,"$monthStr"');
    buffer.writeln('Opening Stock:,"${Formatters.formatSmart(openingStock)} ${item.baseUnit}"');
    buffer.writeln('Total Received:,"${Formatters.formatSmart(totalReceipts)} ${item.baseUnit}"');
    buffer.writeln('Total Issues:,"${Formatters.formatSmart(totalIssues)} ${item.baseUnit}"');
    buffer.writeln('Closing Balance:,"${Formatters.formatSmart(closingStock)} ${item.baseUnit}"');
    buffer.writeln();
    buffer.writeln('Date,Particulars,Previous Stock,Received Quantity,Issued Quantity,Balance in Stock,Unit');

    for (final r in rows) {
      final safeParticulars = r.particulars.replaceAll('"', '""');
      buffer.writeln(
        '${r.dateDisplay},"$safeParticulars",${r.previousStock.toStringAsFixed(2)},${r.receiptQty.toStringAsFixed(2)},${r.issuedQty.toStringAsFixed(2)},${r.balanceStock.toStringAsFixed(2)},${item.baseUnit}',
      );
    }

    buffer.writeln(
      'TOTAL,"Summary Total",${openingStock.toStringAsFixed(2)},${totalReceipts.toStringAsFixed(2)},${totalIssues.toStringAsFixed(2)},${closingStock.toStringAsFixed(2)},${item.baseUnit}',
    );

    return buffer.toString();
  }

  /// Generates a professional, beautifully styled binary XLSX (Excel) workbook
  List<int> toXlsx() {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'Stock Ledger');
    final sheet = excel['Stock Ledger'];

    final monthStr = DateFormat('MMMM yyyy').format(month);
    final netMovement = totalReceipts - totalIssues;

    // Helper to apply style to an entire row of cells
    void styleRow(int rowIdx, List<CellStyle> styles) {
      for (int c = 0; c < styles.length; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx)).cellStyle = styles[c];
      }
    }

    // Helper to apply a uniform style across all 7 columns in a row
    void styleUniformRow(int rowIdx, CellStyle style) {
      for (int c = 0; c < 7; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx)).cellStyle = style;
      }
    }

    // -------------------------------------------------------------
    // DESIGN SYSTEM STYLES (Tailored color palette & typography)
    // -------------------------------------------------------------
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 13,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#0F172A'), // Slate 900
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final subtitleStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#E2E8F0'), // Slate 200
      backgroundColorHex: ExcelColor.fromHexString('#1E293B'), // Slate 800
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final kpiLabelStyle = CellStyle(
      bold: true,
      fontSize: 9,
      fontColorHex: ExcelColor.fromHexString('#475569'), // Slate 600
      backgroundColorHex: ExcelColor.fromHexString('#F1F5F9'), // Slate 100
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final kpiOpeningStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#0369A1'), // Sky 700
      backgroundColorHex: ExcelColor.fromHexString('#E0F2FE'), // Sky 100
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final kpiReceivedStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#15803D'), // Green 700
      backgroundColorHex: ExcelColor.fromHexString('#DCFCE7'), // Green 100
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final kpiIssuedStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#BE123C'), // Rose 700
      backgroundColorHex: ExcelColor.fromHexString('#FFE4E6'), // Rose 100
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final kpiBalanceStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#6D28D9'), // Purple 700
      backgroundColorHex: ExcelColor.fromHexString('#EDE9FE'), // Purple 100
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final kpiMovementStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#B45309'), // Amber 700
      backgroundColorHex: ExcelColor.fromHexString('#FEF3C7'), // Amber 100
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final kpiStatusStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#15803D'),
      backgroundColorHex: ExcelColor.fromHexString('#F0FDF4'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final kpiCodeStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#334155'),
      backgroundColorHex: ExcelColor.fromHexString('#F8FAFC'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final headerStandardStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1E293B'), // Slate 800
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final headerReceivedStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#047857'), // Emerald 700
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final headerIssuedStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#B91C1C'), // Red 700
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final headerBalanceStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#1E3A8A'), // Blue 900
      backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Row 0: Title Banner
    sheet.appendRow([
      TextCellValue('CASEYA DAIRY PLANT • DATE-WISE STORE & INVENTORY LEDGER'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);
    styleUniformRow(0, titleStyle);

    // Row 1: Subtitle Info
    sheet.appendRow([
      TextCellValue('Material: ${item.name} (${item.category}) | Period: $monthStr | Unit: ${item.baseUnit}'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);
    styleUniformRow(1, subtitleStyle);

    // Row 2: KPI Labels
    sheet.appendRow([
      TextCellValue('Opening Stock'),
      TextCellValue('Total Received'),
      TextCellValue('Total Issued'),
      TextCellValue('Closing Balance'),
      TextCellValue('Net Movement'),
      TextCellValue('Status'),
      TextCellValue('Item ID'),
    ]);
    styleUniformRow(2, kpiLabelStyle);

    // Row 3: KPI Values
    sheet.appendRow([
      DoubleCellValue(openingStock),
      DoubleCellValue(totalReceipts),
      DoubleCellValue(totalIssues),
      DoubleCellValue(closingStock),
      DoubleCellValue(netMovement),
      TextCellValue(item.status.toUpperCase()),
      TextCellValue(item.id),
    ]);
    styleRow(3, [
      kpiOpeningStyle,
      kpiReceivedStyle,
      kpiIssuedStyle,
      kpiBalanceStyle,
      kpiMovementStyle,
      kpiStatusStyle,
      kpiCodeStyle,
    ]);

    // Row 4: Spacer row
    sheet.appendRow([
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);

    // Row 5: Table Column Headers
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Particulars / Store Activity'),
      TextCellValue('Previous Stock (${item.baseUnit})'),
      TextCellValue('Received Qty (+${item.baseUnit})'),
      TextCellValue('Issued Qty (-${item.baseUnit})'),
      TextCellValue('Balance Stock (${item.baseUnit})'),
      TextCellValue('Base Unit'),
    ]);
    styleRow(5, [
      headerStandardStyle,
      headerStandardStyle,
      headerStandardStyle,
      headerReceivedStyle,
      headerIssuedStyle,
      headerBalanceStyle,
      headerStandardStyle,
    ]);

    // Row 6 onwards: Daily Records
    int currentRowIdx = 6;
    for (final r in rows) {
      final isEven = (currentRowIdx % 2 == 0);
      final bgHex = isEven ? '#FFFFFF' : '#F8FAFC';

      final dateStyle = CellStyle(
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString('#334155'),
        backgroundColorHex: ExcelColor.fromHexString(bgHex),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final partStyle = CellStyle(
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString('#0F172A'),
        backgroundColorHex: ExcelColor.fromHexString(bgHex),
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      );

      final prevStyle = CellStyle(
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString('#475569'),
        backgroundColorHex: ExcelColor.fromHexString(bgHex),
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      final recStyle = (r.receiptQty > 0)
          ? CellStyle(
              bold: true,
              fontSize: 10,
              fontColorHex: ExcelColor.fromHexString('#15803D'), // Green 700
              backgroundColorHex: ExcelColor.fromHexString('#DCFCE7'), // Green 100
              horizontalAlign: HorizontalAlign.Right,
              verticalAlign: VerticalAlign.Center,
            )
          : CellStyle(
              fontSize: 10,
              fontColorHex: ExcelColor.fromHexString('#94A3B8'),
              backgroundColorHex: ExcelColor.fromHexString(bgHex),
              horizontalAlign: HorizontalAlign.Right,
              verticalAlign: VerticalAlign.Center,
            );

      final issStyle = (r.issuedQty > 0)
          ? CellStyle(
              bold: true,
              fontSize: 10,
              fontColorHex: ExcelColor.fromHexString('#BE123C'), // Rose 700
              backgroundColorHex: ExcelColor.fromHexString('#FFE4E6'), // Rose 100
              horizontalAlign: HorizontalAlign.Right,
              verticalAlign: VerticalAlign.Center,
            )
          : CellStyle(
              fontSize: 10,
              fontColorHex: ExcelColor.fromHexString('#94A3B8'),
              backgroundColorHex: ExcelColor.fromHexString(bgHex),
              horizontalAlign: HorizontalAlign.Right,
              verticalAlign: VerticalAlign.Center,
            );

      final balStyle = CellStyle(
        bold: true,
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString('#0F172A'),
        backgroundColorHex: ExcelColor.fromHexString(isEven ? '#F1F5F9' : '#E2E8F0'),
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      final unitStyle = CellStyle(
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString('#64748B'),
        backgroundColorHex: ExcelColor.fromHexString(bgHex),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      sheet.appendRow([
        TextCellValue(r.dateDisplay),
        TextCellValue(r.particulars),
        DoubleCellValue(r.previousStock),
        DoubleCellValue(r.receiptQty),
        DoubleCellValue(r.issuedQty),
        DoubleCellValue(r.balanceStock),
        TextCellValue(item.baseUnit),
      ]);

      styleRow(currentRowIdx, [
        dateStyle,
        partStyle,
        prevStyle,
        recStyle,
        issStyle,
        balStyle,
        unitStyle,
      ]);

      currentRowIdx++;
    }

    // Spacer row
    sheet.appendRow([
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);
    currentRowIdx++;

    // Total Row (High-contrast obsidian theme)
    final totalLabelStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#0F172A'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final totalPartStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#0F172A'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    final totalOpeningStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#BAE6FD'), // Sky 200
      backgroundColorHex: ExcelColor.fromHexString('#0F172A'),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    final totalRecStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#86EFAC'), // Green 300
      backgroundColorHex: ExcelColor.fromHexString('#0F172A'),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    final totalIssStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#FDA4AF'), // Rose 300
      backgroundColorHex: ExcelColor.fromHexString('#0F172A'),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    final totalBalStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#FEF08A'), // Yellow 200
      backgroundColorHex: ExcelColor.fromHexString('#0F172A'),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    final totalUnitStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#E2E8F0'),
      backgroundColorHex: ExcelColor.fromHexString('#0F172A'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    sheet.appendRow([
      TextCellValue('TOTAL'),
      TextCellValue('Monthly Summary Total'),
      DoubleCellValue(openingStock),
      DoubleCellValue(totalReceipts),
      DoubleCellValue(totalIssues),
      DoubleCellValue(closingStock),
      TextCellValue(item.baseUnit),
    ]);
    styleRow(currentRowIdx, [
      totalLabelStyle,
      totalPartStyle,
      totalOpeningStyle,
      totalRecStyle,
      totalIssStyle,
      totalBalStyle,
      totalUnitStyle,
    ]);

    // Set Column Widths for comfortable readability
    sheet.setColumnWidth(0, 16.0); // Date
    sheet.setColumnWidth(1, 38.0); // Particulars
    sheet.setColumnWidth(2, 22.0); // Previous Stock
    sheet.setColumnWidth(3, 24.0); // Received Qty
    sheet.setColumnWidth(4, 24.0); // Issued Qty
    sheet.setColumnWidth(5, 24.0); // Balance Stock
    sheet.setColumnWidth(6, 14.0); // Unit

    return excel.save() ?? [];
  }
}

/// Helper methods to calculate month-wise material ledger
class StockLedgerCalculator {
  static DateTime? parseAnyDate(String s) {
    s = s.trim();
    if (s.isEmpty) return null;

    // Clean any trailing time or timezone components e.g. "2026-08-15 10:30 AM" or "2026-08-15T00:00:00.000Z"
    final cleanDatePart = s.split(' ').first.split('T').first.trim();

    try {
      final dt = DateTime.parse(cleanDatePart);
      return DateTime(dt.year, dt.month, dt.day);
    } catch (_) {}
    try {
      final dt = DateTime.parse(s);
      return DateTime(dt.year, dt.month, dt.day);
    } catch (_) {}

    // Handle delimited patterns: - or /
    for (final delimiter in ['-', '/']) {
      if (cleanDatePart.contains(delimiter)) {
        final parts = cleanDatePart.split(delimiter);
        if (parts.length == 3) {
          final p0 = int.tryParse(parts[0]);
          final p1 = int.tryParse(parts[1]);
          final p2 = int.tryParse(parts[2]);
          // Case: yyyy-M-d or yyyy/M/d
          if (p0 != null && p1 != null && p2 != null) {
            if (p0 >= 2000 && p1 >= 1 && p1 <= 12 && p2 >= 1 && p2 <= 31) {
              return DateTime(p0, p1, p2);
            }
            // Case: d-M-yyyy or d/M/yyyy
            if (p2 >= 2000 && p1 >= 1 && p1 <= 12 && p0 >= 1 && p0 <= 31) {
              return DateTime(p2, p1, p0);
            }
          }
        }
      }
    }

    const formats = [
      'yyyy-MM-dd',
      'yyyy-M-d',
      'dd MMM yyyy',
      'd MMM yyyy',
      'dd-MMM-yyyy',
      'd-MMM-yyyy',
      'dd/MM/yyyy',
      'd/M/yyyy',
      'dd-MM-yyyy',
      'd-M-yyyy',
      'yyyy/MM/dd',
      'yyyy/M/d',
      'MM/dd/yyyy',
      'M/d/yyyy',
    ];

    for (final fmt in formats) {
      try {
        final dt = DateFormat(fmt).parseStrict(cleanDatePart);
        return DateTime(dt.year, dt.month, dt.day);
      } catch (_) {}
      try {
        final dt = DateFormat(fmt).parse(cleanDatePart);
        return DateTime(dt.year, dt.month, dt.day);
      } catch (_) {}
    }

    return null;
  }

  static bool isSameDay(DateTime dt, String dateStr) {
    final parsed = parseAnyDate(dateStr);
    if (parsed == null) return false;
    return dt.year == parsed.year && dt.month == parsed.month && dt.day == parsed.day;
  }

  static bool isBeforeMonth(DateTime monthStart, String dateStr) {
    final parsed = parseAnyDate(dateStr);
    if (parsed == null) return false;
    final parsedStart = DateTime(parsed.year, parsed.month, 1);
    return parsedStart.isBefore(DateTime(monthStart.year, monthStart.month, 1));
  }

  /// Calculates all historical activity rows (across all months) for an item
  static MonthlyStockLedgerResult calculateAllActivityLedger({
    required InventoryItemModel item,
    required List<InwardStockEntry> inwardLedger,
    required List<StockDeductionEntry> deductionLedger,
  }) {
    // Gather all unique dates for this item
    final Set<String> uniqueIsoDates = {};
    for (final e in inwardLedger) {
      if (e.itemId == item.id) {
        final dt = parseAnyDate(e.date);
        if (dt != null) {
          uniqueIsoDates.add(DateFormat('yyyy-MM-dd').format(dt));
        }
      }
    }
    for (final d in deductionLedger) {
      if (d.inventoryItemId == item.id) {
        final dt = parseAnyDate(d.date);
        if (dt != null) {
          uniqueIsoDates.add(DateFormat('yyyy-MM-dd').format(dt));
        }
      }
    }

    final sortedDates = uniqueIsoDates.map((s) => parseAnyDate(s)!).toList()
      ..sort((a, b) => a.compareTo(b));

    double currentRunningStock = item.initialTotalQty;
    double totalReceipts = 0.0;
    double totalIssues = 0.0;
    final List<StockLedgerDayRow> rows = [];

    if (sortedDates.isEmpty) {
      final now = DateTime.now();
      final dayDate = DateTime(now.year, now.month, 1);
      rows.add(StockLedgerDayRow(
        date: dayDate,
        dateDisplay: DateFormat('dd/MM/yyyy').format(dayDate),
        particulars: 'Opening Balance (No activity recorded yet)',
        previousStock: item.initialTotalQty,
        receiptQty: 0.0,
        issuedQty: 0.0,
        balanceStock: item.initialTotalQty,
      ));
    } else {
      for (final dayDate in sortedDates) {
        final dayDisplay = DateFormat('dd/MM/yyyy').format(dayDate);
        final dayInward = inwardLedger.where((e) => e.itemId == item.id && isSameDay(dayDate, e.date)).toList();
        final dayDeductions = deductionLedger.where((d) => d.inventoryItemId == item.id && isSameDay(dayDate, d.date)).toList();

        double dayReceiptQty = 0.0;
        for (final inEntry in dayInward) {
          dayReceiptQty += inEntry.quantity;
        }

        double dayIssuedQty = 0.0;
        for (final outEntry in dayDeductions) {
          dayIssuedQty += outEntry.quantityDeducted;
        }

        final double dayPreviousStock = currentRunningStock;
        final double dayBalance = (dayPreviousStock + dayReceiptQty) - dayIssuedQty > 0
            ? (dayPreviousStock + dayReceiptQty) - dayIssuedQty
            : 0.0;

        currentRunningStock = dayBalance;
        totalReceipts += dayReceiptQty;
        totalIssues += dayIssuedQty;

        String particulars;
        if (dayInward.isNotEmpty && dayDeductions.isNotEmpty) {
          final productNames = dayDeductions.map((e) => e.productName).toSet().toList();
          final prodSummary = productNames.length > 2
              ? '${productNames.take(2).join(', ')} +${productNames.length - 2}'
              : productNames.join(', ');
          particulars = prodSummary.isNotEmpty ? 'Received & Issued ($prodSummary)' : 'Received & Issued';
        } else if (dayInward.isNotEmpty) {
          if (dayInward.length > 1) {
            particulars = 'Received (${dayInward.length} receipts)';
          } else {
            final entry = dayInward.first;
            final notesPart = (entry.notes.isNotEmpty && entry.notes.length <= 20) ? ' (${entry.notes})' : '';
            particulars = 'Received$notesPart';
          }
        } else if (dayDeductions.isNotEmpty) {
          final productNames = dayDeductions.map((e) => e.productName).toSet().toList();
          final prodSummary = productNames.length > 2
              ? '${productNames.take(2).join(', ')} +${productNames.length - 2}'
              : productNames.join(', ');
          particulars = prodSummary.isNotEmpty ? 'Issued for $prodSummary' : 'Issued for Production';
        } else {
          particulars = 'Opening Balance';
        }

        rows.add(StockLedgerDayRow(
          date: dayDate,
          dateDisplay: dayDisplay,
          particulars: particulars,
          previousStock: dayPreviousStock,
          receiptQty: dayReceiptQty,
          issuedQty: dayIssuedQty,
          balanceStock: dayBalance,
          inwardEntries: dayInward,
          deductionEntries: dayDeductions,
        ));
      }
    }

    return MonthlyStockLedgerResult(
      item: item,
      month: sortedDates.isNotEmpty ? sortedDates.last : DateTime.now(),
      openingStock: item.initialTotalQty,
      totalReceipts: totalReceipts,
      totalIssues: totalIssues,
      closingStock: currentRunningStock,
      rows: rows,
    );
  }

  /// Calculates the complete month's date-wise store ledger for an item
  static MonthlyStockLedgerResult calculateMonthlyLedger({
    required InventoryItemModel item,
    required DateTime month,
    required List<InwardStockEntry> inwardLedger,
    required List<StockDeductionEntry> deductionLedger,
  }) {
    final monthStart = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // 1. Calculate Month Opening Stock
    // Base is item.initialTotalQty. Prior receipts add, prior issues subtract.
    double priorReceipts = 0.0;
    for (final e in inwardLedger) {
      if (e.itemId == item.id && isBeforeMonth(monthStart, e.date)) {
        priorReceipts += e.quantity;
      }
    }

    double priorIssues = 0.0;
    for (final d in deductionLedger) {
      if (d.inventoryItemId == item.id && isBeforeMonth(monthStart, d.date)) {
        priorIssues += d.quantityDeducted;
      }
    }

    final double openingStock = (item.initialTotalQty + priorReceipts) - priorIssues > 0
        ? (item.initialTotalQty + priorReceipts) - priorIssues
        : 0.0;

    // 2. Iterate each day in the month from 1 to daysInMonth
    final List<StockLedgerDayRow> rows = [];
    double currentRunningStock = openingStock;
    double monthTotalReceipts = 0.0;
    double monthTotalIssues = 0.0;

    for (int d = 1; d <= daysInMonth; d++) {
      final dayDate = DateTime(month.year, month.month, d);
      final dayDisplay = DateFormat('dd/MM/yyyy').format(dayDate);

      // Find inward entries on this date
      final dayInward = inwardLedger.where((e) => e.itemId == item.id && isSameDay(dayDate, e.date)).toList();
      double dayReceiptQty = 0.0;
      for (final inEntry in dayInward) {
        dayReceiptQty += inEntry.quantity;
      }

      // Find deduction entries on this date
      final dayDeductions = deductionLedger.where((d) => d.inventoryItemId == item.id && isSameDay(dayDate, d.date)).toList();
      double dayIssuedQty = 0.0;
      for (final outEntry in dayDeductions) {
        dayIssuedQty += outEntry.quantityDeducted;
      }

      // Previous Stock of this date is current running balance
      final double dayPreviousStock = currentRunningStock;

      // Balance of this date = Previous Stock + Receipts - Issues
      final double dayBalance = (dayPreviousStock + dayReceiptQty) - dayIssuedQty > 0
          ? (dayPreviousStock + dayReceiptQty) - dayIssuedQty
          : 0.0;

      // Update running stock for next date
      currentRunningStock = dayBalance;

      monthTotalReceipts += dayReceiptQty;
      monthTotalIssues += dayIssuedQty;

      // Construct Particulars (clean, concise store ledger format)
      String particulars;
      if (dayInward.isNotEmpty && dayDeductions.isNotEmpty) {
        final productNames = dayDeductions.map((e) => e.productName).toSet().toList();
        final prodSummary = productNames.length > 2
            ? '${productNames.take(2).join(', ')} +${productNames.length - 2}'
            : productNames.join(', ');
        particulars = prodSummary.isNotEmpty ? 'Received & Issued ($prodSummary)' : 'Received & Issued';
      } else if (dayInward.isNotEmpty) {
        if (dayInward.length > 1) {
          particulars = 'Received (${dayInward.length} receipts)';
        } else {
          final entry = dayInward.first;
          final notesPart = (entry.notes.isNotEmpty && entry.notes.length <= 20) ? ' (${entry.notes})' : '';
          particulars = 'Received$notesPart';
        }
      } else if (dayDeductions.isNotEmpty) {
        final productNames = dayDeductions.map((e) => e.productName).toSet().toList();
        final prodSummary = productNames.length > 2
            ? '${productNames.take(2).join(', ')} +${productNames.length - 2}'
            : productNames.join(', ');
        particulars = prodSummary.isNotEmpty ? 'Issued for $prodSummary' : 'Issued for Production';
      } else if (d == 1) {
        particulars = 'Opening Balance';
      } else {
        particulars = 'Balance c/f';
      }

      rows.add(StockLedgerDayRow(
        date: dayDate,
        dateDisplay: dayDisplay,
        particulars: particulars,
        previousStock: dayPreviousStock,
        receiptQty: dayReceiptQty,
        issuedQty: dayIssuedQty,
        balanceStock: dayBalance,
        inwardEntries: dayInward,
        deductionEntries: dayDeductions,
      ));
    }

    final double closingStock = currentRunningStock;

    return MonthlyStockLedgerResult(
      item: item,
      month: month,
      openingStock: openingStock,
      totalReceipts: monthTotalReceipts,
      totalIssues: monthTotalIssues,
      closingStock: closingStock,
      rows: rows,
    );
  }
}
