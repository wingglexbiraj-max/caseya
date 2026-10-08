import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/stock_ledger_exporter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/metric_card.dart';
import '../../models/inventory_item_model.dart';
import '../../models/stock_ledger_entry_model.dart';
import '../../models/boiler_record.dart';
import '../../models/dg_hsd_record.dart';
import '../../providers/inventory_stock_provider.dart';
import '../../providers/boiler_provider.dart';
import '../../providers/dg_hsd_provider.dart';
import '../../providers/production_provider.dart';
import '../../providers/navigation_provider.dart';

enum ReportSection {
  stock,
  boiler,
  dg,
}

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  ReportSection _selectedSection = ReportSection.stock;

  // Stock Ledger State
  DateTime _selectedLedgerMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String? _selectedLedgerItemId;
  bool _showAllMonthDays = true;
  bool _isExporting = false;

  // Boiler Report State
  DateTime _selectedBoilerMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _showAllBoilerDays = true;

  // DG Report State
  DateTime _selectedDgMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _showAllDgDays = true;

  static const Map<String, List<Map<String, String>>> _interrelatedMaterials = {
    'cup_lassi_200': [
      {'id': 'foil_blue_80', 'name': 'Alum Foil (Blue) 80gm', 'reason': '1:1 Foil lid for Lassi 200 ml'},
    ],
    'foil_blue_80': [
      {'id': 'cup_lassi_200', 'name': 'Lassi Cup (200ml)', 'reason': '1:1 Cup for Lassi 200 ml'},
      {'id': 'cup_p80', 'name': 'P80 Cup (Plain Curd 80g)', 'reason': 'Shared Foil for P80 Cup'},
    ],
    'cup_s80': [
      {'id': 'foil_pink_80', 'name': 'Alum Foil (Pink) 80gm', 'reason': '1:1 Foil lid for S80'},
      {'id': 'serving_wooden_spoon', 'name': 'Wooden Spoon', 'reason': '1:1 Spoon for S80'},
    ],
    'foil_pink_80': [
      {'id': 'cup_s80', 'name': 'S80 Cup (Sweet Curd 80g)', 'reason': '1:1 Cup for Sweet Curd 80g'},
    ],
    'pouch_film_500': [
      {'id': 'crate_milk_12', 'name': 'Milk Crate (12 Pkts)', 'reason': '12 Pouches per Milk Crate'},
    ],
  };

  void _prevMonth() {
    setState(() {
      _selectedLedgerMonth = DateTime(_selectedLedgerMonth.year, _selectedLedgerMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedLedgerMonth = DateTime(_selectedLedgerMonth.year, _selectedLedgerMonth.month + 1, 1);
    });
  }

  void _pickMonth(BuildContext context) {
    _showMonthYearPickerDialog(
      context,
      initialMonth: _selectedLedgerMonth,
      onSelected: (m) => setState(() => _selectedLedgerMonth = m),
    );
  }

  void _showMonthYearPickerDialog(
    BuildContext context, {
    required DateTime initialMonth,
    required ValueChanged<DateTime> onSelected,
  }) {
    int activeYear = initialMonth.year;
    final now = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Flexible(
                                  child: Text(
                                    'Select Month & Year',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: AppFontWeights.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                            onPressed: () => Navigator.of(ctx).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Year Selector Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded),
                              onPressed: activeYear > 2020
                                  ? () => setDialogState(() => activeYear--)
                                  : null,
                              tooltip: 'Previous Year',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: activeYear,
                                icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: AppFontWeights.bold,
                                  color: AppColors.primary,
                                ),
                                items: [
                                  for (int y = 2020; y <= 2035; y++)
                                    DropdownMenuItem<int>(
                                      value: y,
                                      child: Text('$y'),
                                    ),
                                ],
                                onChanged: (newY) {
                                  if (newY != null) {
                                    setDialogState(() => activeYear = newY);
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded),
                              onPressed: activeYear < 2035
                                  ? () => setDialogState(() => activeYear++)
                                  : null,
                              tooltip: 'Next Year',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 12-Month Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 2.2,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final monthNum = index + 1;
                          final monthDate = DateTime(activeYear, monthNum, 1);
                          final monthLabel = DateFormat('MMM').format(monthDate);
                          final isSelected = initialMonth.year == activeYear && initialMonth.month == monthNum;
                          final isCurrent = now.year == activeYear && now.month == monthNum;

                          return InkWell(
                            onTap: () {
                              onSelected(DateTime(activeYear, monthNum, 1));
                              Navigator.of(ctx).pop();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : isCurrent
                                        ? AppColors.primary.withValues(alpha: 0.10)
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : isCurrent
                                          ? AppColors.primary.withValues(alpha: 0.5)
                                          : AppColors.cardBorder,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    monthLabel,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isSelected ? AppFontWeights.bold : AppFontWeights.medium,
                                      color: isSelected
                                          ? Colors.white
                                          : isCurrent
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                  ] else if (isCurrent) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Quick Jump Shortcuts: Current Month & Close
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.today_rounded, size: 16),
                            label: const Text('Current Month', style: TextStyle(fontSize: 12, fontWeight: AppFontWeights.semiBold)),
                            onPressed: () {
                              onSelected(DateTime(now.year, now.month, 1));
                              Navigator.of(ctx).pop();
                            },
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Close', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMonthYearSelector({
    required BuildContext context,
    required DateTime selectedMonth,
    required ValueChanged<DateTime> onMonthChanged,
  }) {
    final prevMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    final prevMonthName = DateFormat('MMM yyyy').format(prevMonth);
    final nextMonthName = DateFormat('MMM yyyy').format(nextMonth);
    final currentMonthName = DateFormat('MMMM yyyy').format(selectedMonth);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Year Dropdown
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Year: ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: AppFontWeights.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder, width: 1.1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedMonth.year,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 18),
                  isDense: true,
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  items: [
                    for (int y = 2020; y <= 2035; y++)
                      DropdownMenuItem<int>(
                        value: y,
                        child: Text(
                          '$y',
                          style: const TextStyle(fontSize: 12.5, fontWeight: AppFontWeights.bold),
                        ),
                      ),
                  ],
                  onChanged: (newY) {
                    if (newY != null) {
                      onMonthChanged(DateTime(newY, selectedMonth.month, 1));
                    }
                  },
                ),
              ),
            ),
          ],
        ),

        // Month Selector with Prev / Next & Picker Dialog
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 38),
              tooltip: 'Previous Month ($prevMonthName)',
              onPressed: () => onMonthChanged(prevMonth),
            ),
            InkWell(
              onTap: () {
                _showMonthYearPickerDialog(
                  context,
                  initialMonth: selectedMonth,
                  onSelected: onMonthChanged,
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder, width: 1.1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 15, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      currentMonthName,
                      style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 38),
              tooltip: 'Next Month ($nextMonthName)',
              onPressed: () => onMonthChanged(nextMonth),
            ),
          ],
        ),
      ],
    );
  }

  void _exportLedgerXlsx(MonthlyStockLedgerResult result) {
    if (_isExporting) return;
    _isExporting = true;

    try {
      final monthStr = DateFormat('MMMM_yyyy').format(result.month);
      final filename = 'Stock_Ledger_${result.item.id}_$monthStr.xlsx';
      downloadLedgerXlsx(filename, result.toXlsx());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Exported ${result.item.name} stock ledger ($filename)'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      Future.delayed(const Duration(milliseconds: 1500), () {
        _isExporting = false;
      });
    }
  }

  void _exportBoilerCsv(List<_BoilerReportRow> rows) {
    final buffer = StringBuffer();
    buffer.writeln('Date,Time,Opening Level (CM),Closing Level (CM),Level Difference (CM),Fuel Consumption (L),Running Hours (Hrs),Fuel Burnrate (L/hr),Fuel Top-up (L)');
    for (final r in rows) {
      if (r.hasActivity && r.record != null) {
        final rec = r.record!;
        final double levelDiff = rec.openingCm - rec.closingCm;
        final double fuel = levelDiff > 0 ? ((levelDiff * 900.0) / 70.0) : (rec.calculatedLevelConsumption > 0 ? rec.calculatedLevelConsumption : 0.0);
        final double burnRate = rec.runningHours > 0 ? (fuel / rec.runningHours) : 0.0;
        buffer.writeln('${rec.date},${rec.time},${rec.openingCm},${rec.closingCm},$levelDiff,${fuel.toStringAsFixed(2)},${rec.runningHours},${burnRate.toStringAsFixed(2)},${rec.fuelTopUp}');
      } else {
        buffer.writeln('${r.date},,,,,,,,');
      }
    }
    final filename = 'Boiler_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    downloadLedgerCsv(filename, buffer.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Exported Boiler Report ($filename)'),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportDgCsv(List<_DgReportRow> rows) {
    final buffer = StringBuffer();
    buffer.writeln('Date,Time,Start %,End %,Energy Generated (kWh),Total Fuel Consumed (L),Shift Running Hours (Hrs),Level After Top-up (L),Fuel Added (L),Consumption Rate (L/hr)');
    for (final r in rows) {
      if (r.hasActivity && r.record != null) {
        final rec = r.record!;
        final double fuel = rec.fuelConsumption > 0 ? rec.fuelConsumption : (((rec.startPercentage - rec.endPercentage) / 100.0 * 380.0) + rec.fuelAdded);
        final double openingL = (rec.startPercentage / 100.0) * 380.0;
        final double fuelAfterTopUp = openingL + rec.fuelAdded;
        final double burnRate = rec.runningHours > 0 ? (fuel / rec.runningHours) : (rec.consumptionPerHour > 0 ? rec.consumptionPerHour : 0.0);
        buffer.writeln('${rec.date},${rec.time},${rec.startPercentage},${rec.endPercentage},${rec.kwh},${fuel.toStringAsFixed(2)},${rec.runningHours},${rec.fuelAdded > 0 ? fuelAfterTopUp.toStringAsFixed(1) : ''},${rec.fuelAdded},${burnRate.toStringAsFixed(2)}');
      } else {
        buffer.writeln('${r.date},,,,,,,,,');
      }
    }
    final filename = 'DG_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    downloadLedgerCsv(filename, buffer.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Exported DG Report ($filename)'),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final stockState = ref.watch(inventoryStockProvider);
    final boilerState = ref.watch(boilerProvider);
    final dgState = ref.watch(dgHsdProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24,
          vertical: 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chip Tab Bar Navigation
            _buildReportChipTabBar(stockState, boilerState, dgState, isMobile),
            const SizedBox(height: 20),

            // Active Report Section View
            if (_selectedSection == ReportSection.stock)
              _buildDateWiseStockReportSection(
                context: context,
                isMobile: isMobile,
                stockState: stockState,
              )
            else if (_selectedSection == ReportSection.boiler)
              _buildBoilerReportSection(
                context: context,
                isMobile: isMobile,
                boilerState: boilerState,
              )
            else if (_selectedSection == ReportSection.dg)
              _buildDgReportSection(
                context: context,
                isMobile: isMobile,
                dgState: dgState,
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chip Catalogue Navigation
  // ---------------------------------------------------------------------------
  Widget _buildReportChipTabBar(
    InventoryStockState stockState,
    BoilerState boilerState,
    DgHsdState dgState,
    bool isMobile,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading Outside Chips with Circular Icon Background
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer.withValues(alpha: 0.8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Reports Catalogue',
                style: TextStyle(
                  fontSize: AppTextSizes.subheading,
                  fontWeight: AppFontWeights.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Clean Chip Tabs (No Icons, No Numbers, Increased Text Size)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ReportCatalogueChip(
                label: 'Inventory Report',
                isSelected: _selectedSection == ReportSection.stock,
                onTap: () {
                  setState(() {
                    _selectedSection = ReportSection.stock;
                  });
                },
              ),
              _ReportCatalogueChip(
                label: 'Boiler Report',
                isSelected: _selectedSection == ReportSection.boiler,
                onTap: () {
                  setState(() {
                    _selectedSection = ReportSection.boiler;
                  });
                },
              ),
              _ReportCatalogueChip(
                label: 'DG Report',
                isSelected: _selectedSection == ReportSection.dg,
                onTap: () {
                  setState(() {
                    _selectedSection = ReportSection.dg;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. DATE-WISE STOCK REPORT SECTION
  // ---------------------------------------------------------------------------
  Widget _buildDateWiseStockReportSection({
    required BuildContext context,
    required bool isMobile,
    required InventoryStockState stockState,
  }) {
    final allItems = stockState.allItems;
    if (allItems.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: const [
                Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text('No inventory materials loaded yet.', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    final navHighlightDate = ref.watch(stockLedgerHighlightDateProvider);

    final currentItem = (allItems.any((i) => i.id == _selectedLedgerItemId))
        ? allItems.firstWhere((i) => i.id == _selectedLedgerItemId)
        : allItems.first;

    final MonthlyStockLedgerResult ledgerResult = StockLedgerCalculator.calculateMonthlyLedger(
      item: currentItem,
      month: _selectedLedgerMonth,
      inwardLedger: stockState.inwardLedger,
      deductionLedger: stockState.deductionLedger,
    );

    final displayedRows = _showAllMonthDays
        ? ledgerResult.rows
        : ledgerResult.rows.where((r) =>
            r.hasActivity ||
            r.date.day == 1 ||
            (navHighlightDate != null &&
                r.date.year == navHighlightDate.year &&
                r.date.month == navHighlightDate.month &&
                r.date.day == navHighlightDate.day)
          ).toList();

    final prevMonth = DateTime(_selectedLedgerMonth.year, _selectedLedgerMonth.month - 1, 1);
    final nextMonth = DateTime(_selectedLedgerMonth.year, _selectedLedgerMonth.month + 1, 1);
    final prevMonthName = DateFormat('MMM yyyy').format(prevMonth);
    final nextMonthName = DateFormat('MMM yyyy').format(nextMonth);
    final currentMonthName = DateFormat('MMMM yyyy').format(_selectedLedgerMonth);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Title & Action Buttons (Print Preview & Export XLSX)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              final titleWidget = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inventory Report',
                          style: TextStyle(
                            fontSize: AppTextSizes.subheading,
                            fontWeight: AppFontWeights.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Material Store Ledger for $currentMonthName',
                          style: const TextStyle(
                            fontSize: AppTextSizes.caption,
                            color: AppColors.textSecondary,
                            fontWeight: AppFontWeights.medium,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actionsWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text('Print / Preview', style: TextStyle(fontSize: 12, fontWeight: AppFontWeights.semiBold)),
                    onPressed: () => _showPrintableLedgerDialog(context, ledgerResult),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Download XLSX', style: TextStyle(fontSize: 12, fontWeight: AppFontWeights.semiBold)),
                    onPressed: () => _exportLedgerXlsx(ledgerResult),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 10),
                    actionsWidget,
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleWidget),
                  actionsWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // 2. Control Toolbar: Material Selection, Year, Month Navigation, Days Filter
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final materialSelector = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Material:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: AppFontWeights.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder, width: 1.1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currentItem.id,
                          isDense: true,
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 18),
                          items: allItems.map((item) {
                            return DropdownMenuItem<String>(
                              value: item.id,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(item.icon, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: AppFontWeights.semiBold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${item.baseUnit})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: AppFontWeights.regular,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedLedgerItemId = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                );

                final yearSelector = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Year: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: AppFontWeights.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder, width: 1.1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedLedgerMonth.year,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 18),
                          isDense: true,
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          items: [
                            for (int y = 2020; y <= 2035; y++)
                              DropdownMenuItem<int>(
                                value: y,
                                child: Text(
                                  '$y',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: AppFontWeights.bold),
                                ),
                              ),
                          ],
                          onChanged: (newY) {
                            if (newY != null) {
                              setState(() {
                                _selectedLedgerMonth = DateTime(newY, _selectedLedgerMonth.month, 1);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                );

                final monthSelector = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 38),
                      tooltip: 'Previous Month ($prevMonthName)',
                      onPressed: _prevMonth,
                    ),
                    InkWell(
                      onTap: () => _pickMonth(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder, width: 1.1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 15, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              currentMonthName,
                              style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.bold),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 38),
                      tooltip: 'Next Month ($nextMonthName)',
                      onPressed: _nextMonth,
                    ),
                  ],
                );

                final daysFilterChips = Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: Text('All Month Days (${ledgerResult.rows.length})', style: const TextStyle(fontSize: 11)),
                      selected: _showAllMonthDays,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _showAllMonthDays ? Colors.white : AppColors.textPrimary,
                        fontWeight: AppFontWeights.bold,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _showAllMonthDays = true;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text(
                        'Activity Only (${ledgerResult.rows.where((r) => r.hasActivity).length})',
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: !_showAllMonthDays,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: !_showAllMonthDays ? Colors.white : AppColors.textPrimary,
                        fontWeight: AppFontWeights.bold,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _showAllMonthDays = false;
                          });
                        }
                      },
                    ),
                  ],
                );

                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        materialSelector,
                        yearSelector,
                        monthSelector,
                      ],
                    ),
                    daysFilterChips,
                  ],
                );
              },
            ),
          ),
          () {
            final related = _interrelatedMaterials[currentItem.id] ?? [];
            if (related.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Interrelated Packaging:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: AppFontWeights.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: related.map((rel) {
                          final relItem = allItems.where((i) => i.id == rel['id']).firstOrNull;
                          final stockStr = relItem != null
                              ? ' • Stock: ${Formatters.formatSmart(relItem.remainingQty)} ${relItem.baseUnit}'
                              : '';
                          return ActionChip(
                            backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.5),
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
                            avatar: const Icon(Icons.swap_horiz_rounded, size: 14, color: AppColors.primary),
                            label: Text(
                              '${rel['name']}$stockStr (${rel['reason']})',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedLedgerItemId = rel['id'];
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }(),
          const SizedBox(height: 14),

          // 3. Monthly Summary Strip (4 Cards)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final cardOpening = MetricCard(
                title: 'Opening Stock',
                value: Formatters.formatSmart(ledgerResult.openingStock),
                unit: currentItem.baseUnit,
                subtitle: 'B/F from $prevMonthName',
                icon: Icons.flag_rounded,
                iconColor: Colors.black.withValues(alpha: 0.60),
                iconBgColor: Colors.black.withValues(alpha: 0.06),
                cardBgColor: const Color(0xFFEFF6FF),
              );

              final cardReceipt = MetricCard(
                title: 'Received Quantity',
                value: '+${Formatters.formatSmart(ledgerResult.totalReceipts)}',
                unit: currentItem.baseUnit,
                subtitle: 'Added inward receipts',
                icon: Icons.input_rounded,
                iconColor: Colors.black.withValues(alpha: 0.60),
                iconBgColor: Colors.black.withValues(alpha: 0.06),
                cardBgColor: const Color(0xFFECFDF5),
              );

              final cardIssued = MetricCard(
                title: 'Issued Quantity',
                value: '−${Formatters.formatSmart(ledgerResult.totalIssues)}',
                unit: currentItem.baseUnit,
                subtitle: 'From Production & Batches',
                icon: Icons.output_rounded,
                iconColor: Colors.black.withValues(alpha: 0.60),
                iconBgColor: Colors.black.withValues(alpha: 0.06),
                cardBgColor: const Color(0xFFFFFBEB),
              );

              final cardBalance = MetricCard(
                title: 'Balance in Stock',
                value: Formatters.formatSmart(ledgerResult.closingStock),
                unit: currentItem.baseUnit,
                subtitle: 'C/F to $nextMonthName',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: Colors.black.withValues(alpha: 0.60),
                iconBgColor: Colors.black.withValues(alpha: 0.06),
                cardBgColor: const Color(0xFFF5F3FF),
              );

              if (isWide) {
                return IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(child: cardOpening),
                      const SizedBox(width: 10),
                      Expanded(child: cardReceipt),
                      const SizedBox(width: 10),
                      Expanded(child: cardIssued),
                      const SizedBox(width: 10),
                      Expanded(child: cardBalance),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(child: cardOpening),
                        const SizedBox(width: 10),
                        Expanded(child: cardReceipt),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(child: cardIssued),
                        const SizedBox(width: 10),
                        Expanded(child: cardBalance),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // 4. Ledger Table with exact 6 columns
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = constraints.maxWidth < 1050 ? 1050.0 : constraints.maxWidth;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Table(
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      border: const TableBorder(
                        horizontalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(1.35),
                        1: FlexColumnWidth(2.65),
                        2: FlexColumnWidth(1.4),
                        3: FlexColumnWidth(1.45),
                        4: FlexColumnWidth(1.45),
                        5: FlexColumnWidth(1.5),
                      },
                      children: [
                        // Table Header
                        const TableRow(
                          decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                          children: [
                            _LedgerHeaderCell('Date'),
                            _LedgerHeaderCell('Particulars'),
                            _LedgerHeaderCell('Previous Stock'),
                            _LedgerHeaderCell('Received Quantity'),
                            _LedgerHeaderCell('Issued Quantity'),
                            _LedgerHeaderCell('Balance in Stock'),
                          ],
                        ),

                        // Ledger Data Rows
                        ...displayedRows.map((r) {
                          final isToday = r.date.year == DateTime.now().year &&
                              r.date.month == DateTime.now().month &&
                              r.date.day == DateTime.now().day;
                          final hasReceipt = r.receiptQty > 0;
                          final hasIssue = r.issuedQty > 0;

                          Color rowBg = Colors.white;
                          if (isToday) {
                            rowBg = AppColors.primaryContainer.withValues(alpha: 0.28);
                          } else if (r.hasActivity) {
                            rowBg = const Color(0xFFFAFAFA);
                          }

                          return TableRow(
                            decoration: BoxDecoration(color: rowBg),
                            children: [
                              // Date Cell
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isToday)
                                        Container(
                                          margin: const EdgeInsets.only(right: 5),
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      Text(
                                        r.dateDisplay,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isToday ? AppFontWeights.bold : AppFontWeights.medium,
                                          color: isToday ? AppColors.primary : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Particulars Cell
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                child: Center(
                                  child: InkWell(
                                    onTap: () => _showDayParticularsDetailDialog(context, r, currentItem, allItems),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              r.particulars,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: r.hasActivity ? AppFontWeights.semiBold : AppFontWeights.regular,
                                                color: r.hasActivity ? AppColors.textPrimary : AppColors.textMuted,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            r.hasActivity ? Icons.info_outline_rounded : Icons.add_circle_outline_rounded,
                                            size: 13,
                                            color: r.hasActivity ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Previous Stock Cell
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${Formatters.formatSmart(r.previousStock)} ${currentItem.baseUnit}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: AppFontWeights.medium,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Received Quantity Cell
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                child: InkWell(
                                  onTap: () => _showEditReceivedDialog(context, r, currentItem, allItems),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (hasReceipt)
                                          Flexible(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                '+${Formatters.formatSmart(r.receiptQty)} ${currentItem.baseUnit}',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: AppFontWeights.bold,
                                                  color: Color(0xFF16A34A),
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          const Text('—', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                        const SizedBox(width: 6),
                                        Tooltip(
                                          message: hasReceipt
                                              ? 'Edit or Erase Received Stock on ${r.dateDisplay}'
                                              : 'Add / Record Received Stock on ${r.dateDisplay}',
                                          child: const Padding(
                                            padding: EdgeInsets.all(2),
                                            child: Icon(
                                              Icons.edit_outlined,
                                              size: 13.5,
                                              color: Color(0xFF16A34A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Issued Quantity Cell
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                child: InkWell(
                                  onTap: () => _showEditIssuedDialog(context, r, currentItem, allItems),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (hasIssue)
                                          Flexible(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                '−${Formatters.formatSmart(r.issuedQty)} ${currentItem.baseUnit}',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: AppFontWeights.bold,
                                                  color: Color(0xFFDC2626),
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          const Text('—', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                        const SizedBox(width: 6),
                                        Tooltip(
                                          message: hasIssue
                                              ? 'Edit or Erase Issued Stock on ${r.dateDisplay}'
                                              : 'Record / Edit Issued Stock on ${r.dateDisplay}',
                                          child: const Padding(
                                            padding: EdgeInsets.all(2),
                                            child: Icon(
                                              Icons.edit_outlined,
                                              size: 13.5,
                                              color: Color(0xFFDC2626),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Balance in Stock Cell
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${Formatters.formatSmart(r.balanceStock)} ${currentItem.baseUnit}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: AppFontWeights.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),

                        // Total Summary Footer Row
                        TableRow(
                          decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'TOTAL',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Monthly Summary ($currentMonthName)',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 11.5),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${Formatters.formatSmart(ledgerResult.openingStock)} ${currentItem.baseUnit}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '+${Formatters.formatSmart(ledgerResult.totalReceipts)} ${currentItem.baseUnit}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12, color: Color(0xFF16A34A)),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '−${Formatters.formatSmart(ledgerResult.totalIssues)} ${currentItem.baseUnit}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12, color: Color(0xFFDC2626)),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${Formatters.formatSmart(ledgerResult.closingStock)} ${currentItem.baseUnit}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12, color: AppColors.primary),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. BOILER REPORT SECTION
  // ---------------------------------------------------------------------------
  Widget _buildBoilerReportSection({
    required BuildContext context,
    required bool isMobile,
    required BoilerState boilerState,
  }) {
    final currentMonthName = DateFormat('MMMM yyyy').format(_selectedBoilerMonth);

    // Filter by Selected Month & Year
    final monthRecords = boilerState.allRecords.where((r) {
      final dt = DateTime.tryParse(r.date);
      if (dt == null) return false;
      return dt.year == _selectedBoilerMonth.year && dt.month == _selectedBoilerMonth.month;
    }).toList();

    // Group records by calendar date
    final Map<String, List<BoilerRecord>> recordsByDate = {};
    for (final rec in monthRecords) {
      recordsByDate.putIfAbsent(rec.date, () => []).add(rec);
    }

    final int daysInMonth = DateTime(_selectedBoilerMonth.year, _selectedBoilerMonth.month + 1, 0).day;
    final List<_BoilerReportRow> allRows = [];
    for (int d = 1; d <= daysInMonth; d++) {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(_selectedBoilerMonth.year, _selectedBoilerMonth.month, d));
      final dayRecords = recordsByDate[dateStr];
      if (dayRecords != null && dayRecords.isNotEmpty) {
        for (final rec in dayRecords) {
          allRows.add(_BoilerReportRow(
            date: dateStr,
            time: rec.time,
            record: rec,
            hasActivity: true,
          ));
        }
      } else {
        allRows.add(_BoilerReportRow(
          date: dateStr,
          time: '',
          record: null,
          hasActivity: false,
        ));
      }
    }

    final displayRows = _showAllBoilerDays
        ? allRows
        : allRows.where((r) => r.hasActivity).toList();

    // Boiler formula for level fuel consumption: ((Opening CM - Closing CM) × 900) ÷ 70
    double computeFuelConsumption(BoilerRecord r) {
      final double diff = r.openingCm - r.closingCm;
      if (diff > 0) {
        return (diff * 900.0) / 70.0;
      }
      return r.calculatedLevelConsumption > 0 ? r.calculatedLevelConsumption : 0.0;
    }

    final double totalFuel = monthRecords.fold(0.0, (sum, r) => sum + computeFuelConsumption(r));
    final double totalHours = monthRecords.fold(0.0, (sum, r) => sum + r.runningHours);
    final double avgBurnRate = totalHours > 0 ? (totalFuel / totalHours) : 0.0;
    final double totalTopUp = monthRecords.fold(0.0, (sum, r) => sum + r.fuelTopUp);
    final double totalLevelDiff = monthRecords.fold(0.0, (sum, r) => sum + (r.openingCm - r.closingCm));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              final titleWidget = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Boiler Report',
                          style: TextStyle(
                            fontSize: AppTextSizes.subheading,
                            fontWeight: AppFontWeights.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Daily fuel burn, level drops & hourly consumption for $currentMonthName (${monthRecords.length} logs)',
                          style: const TextStyle(
                            fontSize: AppTextSizes.caption,
                            color: AppColors.textSecondary,
                            fontWeight: AppFontWeights.medium,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actionsWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD97706),
                      side: const BorderSide(color: Color(0xFFD97706)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text('Print Preview', style: TextStyle(fontSize: 12, fontWeight: AppFontWeights.semiBold)),
                    onPressed: () => _showPrintableBoilerDialog(context, displayRows, totalFuel, totalHours, avgBurnRate),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Export CSV', style: TextStyle(fontSize: 12, fontWeight: AppFontWeights.semiBold)),
                    onPressed: () => _exportBoilerCsv(displayRows),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 10),
                    actionsWidget,
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleWidget),
                  actionsWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Controls & Filters Bar: Month & Year Selector + Days Filter Chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final monthYearSelector = _buildMonthYearSelector(
                  context: context,
                  selectedMonth: _selectedBoilerMonth,
                  onMonthChanged: (m) => setState(() => _selectedBoilerMonth = m),
                );

                final daysFilterChips = Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: Text('All Month Days ($daysInMonth)', style: const TextStyle(fontSize: 11)),
                      selected: _showAllBoilerDays,
                      selectedColor: const Color(0xFFD97706),
                      labelStyle: TextStyle(
                        color: _showAllBoilerDays ? Colors.white : AppColors.textPrimary,
                        fontWeight: AppFontWeights.bold,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _showAllBoilerDays = true;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text(
                        'Activity Only (${monthRecords.length})',
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: !_showAllBoilerDays,
                      selectedColor: const Color(0xFFD97706),
                      labelStyle: TextStyle(
                        color: !_showAllBoilerDays ? Colors.white : AppColors.textPrimary,
                        fontWeight: AppFontWeights.bold,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _showAllBoilerDays = false;
                          });
                        }
                      },
                    ),
                  ],
                );

                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    monthYearSelector,
                    daysFilterChips,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // 4 Metric Cards Strip
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final cardFuel = MetricCard(
                title: 'Total Fuel Consumed',
                value: Formatters.formatSmart(totalFuel),
                unit: 'Litres',
                subtitle: 'Formula: ((Open - Close) × 900) ÷ 70',
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFD97706),
                iconBgColor: const Color(0xFFFEF3C7),
                cardBgColor: const Color(0xFFFFFBEB),
              );
              final cardHours = MetricCard(
                title: 'Total Running Hours',
                value: Formatters.formatSmart(totalHours),
                unit: 'Hours',
                subtitle: 'Active boiler operating time',
                icon: Icons.access_time_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFEFF6FF),
                cardBgColor: const Color(0xFFEFF6FF),
              );
              final cardRate = MetricCard(
                title: 'Avg Fuel Burnrate',
                value: Formatters.formatSmart(avgBurnRate),
                unit: 'L/hr',
                subtitle: 'Overall fuel consumption rate',
                icon: Icons.speed_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBgColor: const Color(0xFFDCFCE7),
                cardBgColor: const Color(0xFFECFDF5),
              );
              final cardTopUp = MetricCard(
                title: 'Total Fuel Top-up',
                value: Formatters.formatSmart(totalTopUp),
                unit: 'Litres',
                subtitle: 'Refueled into day tank',
                icon: Icons.add_circle_outline_rounded,
                iconColor: const Color(0xFF7C3AED),
                iconBgColor: const Color(0xFFEDE9FE),
                cardBgColor: const Color(0xFFF5F3FF),
              );

              if (isWide) {
                return IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(child: cardFuel),
                      const SizedBox(width: 10),
                      Expanded(child: cardHours),
                      const SizedBox(width: 10),
                      Expanded(child: cardRate),
                      const SizedBox(width: 10),
                      Expanded(child: cardTopUp),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(child: cardFuel),
                        const SizedBox(width: 10),
                        Expanded(child: cardHours),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(child: cardRate),
                        const SizedBox(width: 10),
                        Expanded(child: cardTopUp),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Table / Empty State
          if (displayRows.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.local_fire_department_outlined, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No Boiler Activity for $currentMonthName',
                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Records submitted in the Boiler Shift Register for this month will automatically appear here.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth < 1000 ? 1000.0 : constraints.maxWidth;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.cardBorder, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Table(
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        border: const TableBorder(
                          horizontalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(1.3), // Date / Time
                          1: FlexColumnWidth(1.2), // Opening Level
                          2: FlexColumnWidth(1.2), // Closing Level
                          3: FlexColumnWidth(1.2), // Level Difference
                          4: FlexColumnWidth(1.4), // Fuel Consumption
                          5: FlexColumnWidth(1.1), // Running Hours
                          6: FlexColumnWidth(1.3), // Fuel Burnrate
                          7: FlexColumnWidth(1.2), // Fuel Top-up
                        },
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                            children: [
                              _LedgerHeaderCell('Date / Time'),
                              _LedgerHeaderCell('Opening Level'),
                              _LedgerHeaderCell('Closing Level'),
                              _LedgerHeaderCell('Level Difference'),
                              _LedgerHeaderCell('Fuel Consumption'),
                              _LedgerHeaderCell('Running Hours'),
                              _LedgerHeaderCell('Fuel Burnrate'),
                              _LedgerHeaderCell('Fuel Top-up'),
                            ],
                          ),
                          ...displayRows.map((r) {
                            if (r.hasActivity && r.record != null) {
                              final rec = r.record!;
                              final double levelDiff = rec.openingCm - rec.closingCm;
                              final double fuel = computeFuelConsumption(rec);
                              final double burnRate = rec.runningHours > 0 ? (fuel / rec.runningHours) : 0.0;

                              return TableRow(
                                children: [
                                  // 1. Date (below time)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            rec.date,
                                            style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            rec.time.isNotEmpty ? rec.time : '—',
                                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // 2. Opening Level
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: Text(
                                        '${Formatters.formatSmart(rec.openingCm)} CM',
                                        style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.medium),
                                      ),
                                    ),
                                  ),
                                  // 3. Closing Level
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: Text(
                                        '${Formatters.formatSmart(rec.closingCm)} CM',
                                        style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.medium),
                                      ),
                                    ),
                                  ),
                                  // 4. Level Difference
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: Text(
                                        '${Formatters.formatSmart(levelDiff)} CM',
                                        style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  // 5. Fuel Consumption (formula from boiler page)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: Text(
                                        '${Formatters.formatSmart(fuel)} L',
                                        style: const TextStyle(
                                          fontWeight: AppFontWeights.bold,
                                          fontSize: 12.5,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // 6. Running Hours
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: Text(
                                        '${Formatters.formatSmart(rec.runningHours)} Hrs',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  // 7. Fuel Burnrate
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: Text(
                                        rec.runningHours > 0 ? '${Formatters.formatDecimal(burnRate)} L/hr' : '—',
                                        style: const TextStyle(fontWeight: AppFontWeights.semiBold, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  // 8. Fuel Top-up
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: Text(
                                        rec.fuelTopUp > 0 ? '${Formatters.formatSmart(rec.fuelTopUp)} L' : '—',
                                        style: TextStyle(
                                          fontWeight: rec.fuelTopUp > 0 ? AppFontWeights.bold : AppFontWeights.regular,
                                          fontSize: 12,
                                          color: rec.fuelTopUp > 0 ? const Color(0xFF7C3AED) : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: Text(
                                        r.date,
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Center(child: Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Center(child: Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Center(child: Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Center(child: Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Center(child: Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Center(child: Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Center(child: Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))),
                                ],
                              );
                            }
                          }),
                          // Total Summary Row
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFFEF3C7)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Center(
                                  child: Text(
                                    'TOTAL (${monthRecords.length})',
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 11.5, color: Color(0xFF92400E)),
                                  ),
                                ),
                              ),
                              const Padding(padding: EdgeInsets.all(8), child: Center(child: Text('—'))),
                              const Padding(padding: EdgeInsets.all(8), child: Center(child: Text('—'))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Center(
                                  child: Text(
                                    '${Formatters.formatSmart(totalLevelDiff)} CM',
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12, color: Color(0xFF92400E)),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Center(
                                  child: Text(
                                    '${Formatters.formatSmart(totalFuel)} L',
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12.5, color: Color(0xFFD97706)),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Center(
                                  child: Text(
                                    '${Formatters.formatSmart(totalHours)} Hrs',
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12, color: Color(0xFF92400E)),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Center(
                                  child: Text(
                                    '${Formatters.formatDecimal(avgBurnRate)} L/hr',
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12, color: Color(0xFF92400E)),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Center(
                                  child: Text(
                                    '${Formatters.formatSmart(totalTopUp)} L',
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12, color: Color(0xFF7C3AED)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. DG REPORT SECTION
  // ---------------------------------------------------------------------------
  Widget _buildDgReportSection({
    required BuildContext context,
    required bool isMobile,
    required DgHsdState dgState,
  }) {
    final currentMonthName = DateFormat('MMMM yyyy').format(_selectedDgMonth);

    // Filter by Selected Month & Year
    final monthRecords = dgState.allRecords.where((r) {
      final dt = DateTime.tryParse(r.date);
      if (dt == null) return false;
      return dt.year == _selectedDgMonth.year && dt.month == _selectedDgMonth.month;
    }).toList();

    // Group records by calendar date
    final Map<String, List<DgHsdRecord>> recordsByDate = {};
    for (final rec in monthRecords) {
      recordsByDate.putIfAbsent(rec.date, () => []).add(rec);
    }

    final int daysInMonth = DateTime(_selectedDgMonth.year, _selectedDgMonth.month + 1, 0).day;
    final List<_DgReportRow> allRows = [];
    for (int d = 1; d <= daysInMonth; d++) {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(_selectedDgMonth.year, _selectedDgMonth.month, d));
      final dayRecords = recordsByDate[dateStr];
      if (dayRecords != null && dayRecords.isNotEmpty) {
        for (final rec in dayRecords) {
          allRows.add(_DgReportRow(
            date: dateStr,
            time: rec.time,
            record: rec,
            hasActivity: true,
          ));
        }
      } else {
        allRows.add(_DgReportRow(
          date: dateStr,
          time: '',
          record: null,
          hasActivity: false,
        ));
      }
    }

    final displayRows = _showAllDgDays
        ? allRows
        : allRows.where((r) => r.hasActivity).toList();

    // DG calculation formula helper from DG HSD page
    double computeDgConsumption(DgHsdRecord r) {
      if (r.fuelConsumption > 0) return r.fuelConsumption;
      final openingL = (r.startPercentage / 100.0) * AppConstants.DG_TANK_CAPACITY;
      final closingL = (r.endPercentage / 100.0) * AppConstants.DG_TANK_CAPACITY;
      final consumed = openingL + r.fuelAdded - closingL;
      return consumed > 0 ? consumed : 0.0;
    }

    double computeConsumptionRate(DgHsdRecord r) {
      final fuel = computeDgConsumption(r);
      if (r.runningHours > 0) {
        return fuel / r.runningHours;
      }
      return r.consumptionPerHour > 0 ? r.consumptionPerHour : 0.0;
    }

    final double totalHsd = monthRecords.fold(0.0, (sum, r) => sum + computeDgConsumption(r));
    final double totalKwh = monthRecords.fold(0.0, (sum, r) => sum + r.kwh);
    final double totalHours = monthRecords.fold(0.0, (sum, r) => sum + r.runningHours);
    final double totalFuelAdded = monthRecords.fold(0.0, (sum, r) => sum + r.fuelAdded);
    final double avgConsumptionRate = totalHours > 0 ? (totalHsd / totalHours) : 0.0;
    final double avgEfficiency = totalHsd > 0 ? (totalKwh / totalHsd) : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              final titleWidget = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.electric_bolt_rounded, color: Color(0xFF2563EB), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DG Report',
                          style: TextStyle(
                            fontSize: AppTextSizes.subheading,
                            fontWeight: AppFontWeights.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Daily fuel consumption, power generation (kWh) & efficiency for $currentMonthName (${monthRecords.length} logs)',
                          style: const TextStyle(
                            fontSize: AppTextSizes.caption,
                            color: AppColors.textSecondary,
                            fontWeight: AppFontWeights.medium,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actionsWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text('Print Preview', style: TextStyle(fontSize: 12, fontWeight: AppFontWeights.semiBold)),
                    onPressed: () => _showPrintableDgDialog(context, displayRows, totalHsd, totalKwh, totalHours, avgEfficiency),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Export CSV', style: TextStyle(fontSize: 12, fontWeight: AppFontWeights.semiBold)),
                    onPressed: () => _exportDgCsv(displayRows),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 10),
                    actionsWidget,
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleWidget),
                  actionsWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Controls & Filters Bar: Month & Year Selector + Days Filter Chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final monthYearSelector = _buildMonthYearSelector(
                  context: context,
                  selectedMonth: _selectedDgMonth,
                  onMonthChanged: (m) => setState(() => _selectedDgMonth = m),
                );

                final daysFilterChips = Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: Text('All Month Days ($daysInMonth)', style: const TextStyle(fontSize: 11)),
                      selected: _showAllDgDays,
                      selectedColor: const Color(0xFF2563EB),
                      labelStyle: TextStyle(
                        color: _showAllDgDays ? Colors.white : AppColors.textPrimary,
                        fontWeight: AppFontWeights.bold,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _showAllDgDays = true;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: Text(
                        'Activity Only (${monthRecords.length})',
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: !_showAllDgDays,
                      selectedColor: const Color(0xFF2563EB),
                      labelStyle: TextStyle(
                        color: !_showAllDgDays ? Colors.white : AppColors.textPrimary,
                        fontWeight: AppFontWeights.bold,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _showAllDgDays = false;
                          });
                        }
                      },
                    ),
                  ],
                );

                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    monthYearSelector,
                    daysFilterChips,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // 4 Metric Cards Strip
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final cardHsd = MetricCard(
                title: 'Total Fuel Consumed',
                value: Formatters.formatSmart(totalHsd),
                unit: 'Litres',
                subtitle: 'HSD diesel fuel consumed',
                icon: Icons.local_gas_station_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFEFF6FF),
                cardBgColor: const Color(0xFFEFF6FF),
              );
              final cardKwh = MetricCard(
                title: 'Energy Generated',
                value: Formatters.formatSmart(totalKwh),
                unit: 'kWh',
                subtitle: 'Electrical power output',
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFFD97706),
                iconBgColor: const Color(0xFFFEF3C7),
                cardBgColor: const Color(0xFFFFFBEB),
              );
              final cardHours = MetricCard(
                title: 'Shift Running Hours',
                value: Formatters.formatSmart(totalHours),
                unit: 'Hours',
                subtitle: 'Active generator operating time',
                icon: Icons.timer_rounded,
                iconColor: const Color(0xFF7C3AED),
                iconBgColor: const Color(0xFFEDE9FE),
                cardBgColor: const Color(0xFFF5F3FF),
              );
              final cardRate = MetricCard(
                title: 'Avg Consumption Rate',
                value: Formatters.formatDecimal(avgConsumptionRate),
                unit: 'L/hr',
                subtitle: 'Average hourly burn rate',
                icon: Icons.speed_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBgColor: const Color(0xFFDCFCE7),
                cardBgColor: const Color(0xFFECFDF5),
              );

              if (isWide) {
                return IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(child: cardHsd),
                      const SizedBox(width: 10),
                      Expanded(child: cardKwh),
                      const SizedBox(width: 10),
                      Expanded(child: cardHours),
                      const SizedBox(width: 10),
                      Expanded(child: cardRate),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(child: cardHsd),
                        const SizedBox(width: 10),
                        Expanded(child: cardKwh),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(child: cardHours),
                        const SizedBox(width: 10),
                        Expanded(child: cardRate),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Table / Empty State
          if (displayRows.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.electric_bolt_outlined, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No DG Activity for $currentMonthName',
                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Records submitted in the DG HSD Fuel Register for this month will automatically appear here.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth < 1000 ? 1000.0 : constraints.maxWidth;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.cardBorder, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Table(
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        border: const TableBorder(
                          horizontalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(1.3), // Date / Time
                          1: FlexColumnWidth(1.0), // Start %
                          2: FlexColumnWidth(1.0), // End %
                          3: FlexColumnWidth(1.3), // Energy Generated (kWh)
                          4: FlexColumnWidth(1.3), // Total Fuel Consumed (L)
                          5: FlexColumnWidth(1.2), // Shift Running Hours
                          6: FlexColumnWidth(1.6), // Level after Topup / Fuel Added
                          7: FlexColumnWidth(1.3), // Consumption Rate
                        },
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                            children: [
                              _LedgerHeaderCell('Date / Time'),
                              _LedgerHeaderCell('Start %'),
                              _LedgerHeaderCell('End %'),
                              _LedgerHeaderCell('Energy Generated'),
                              _LedgerHeaderCell('Total Fuel Consumed'),
                              _LedgerHeaderCell('Shift Running Hours'),
                              _LedgerHeaderCell('Level after Top-up'),
                              _LedgerHeaderCell('Consumption Rate'),
                            ],
                          ),
                          ...displayRows.map((r) {
                            if (r.hasActivity && r.record != null) {
                              final rec = r.record!;
                              final double fuel = computeDgConsumption(rec);
                              final double burnRate = computeConsumptionRate(rec);
                              final double openingL = (rec.startPercentage / 100.0) * AppConstants.DG_TANK_CAPACITY;
                              final double fuelAfterTopUp = openingL + rec.fuelAdded;
                              final double pctAfterTopUp = (fuelAfterTopUp / AppConstants.DG_TANK_CAPACITY) * 100.0;

                              return TableRow(
                                children: [
                                  // 1. Date (below give time)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(rec.date, style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12)),
                                          const SizedBox(height: 2),
                                          Text(rec.time.isNotEmpty ? rec.time : '—', style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // 2. Start %
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: Text(
                                        '${Formatters.formatSmart(rec.startPercentage)}%',
                                        style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.medium),
                                      ),
                                    ),
                                  ),
                                  // 3. End %
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: Text(
                                        '${Formatters.formatSmart(rec.endPercentage)}%',
                                        style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.medium),
                                      ),
                                    ),
                                  ),
                                  // 4. Energy Generated (kWh)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: Text(
                                        '${Formatters.formatSmart(rec.kwh)} kWh',
                                        style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12, color: Color(0xFFD97706)),
                                      ),
                                    ),
                                  ),
                                  // 5. Total Fuel Consumed
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: Text(
                                        '${Formatters.formatSmart(fuel)} L',
                                        style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12.5, color: Color(0xFF2563EB)),
                                      ),
                                    ),
                                  ),
                                  // 6. Shift Running Hours
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: Text(
                                        '${Formatters.formatSmart(rec.runningHours)} Hrs',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  // 7. Level after Topup or Fuel Added
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: rec.fuelAdded > 0
                                          ? Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${Formatters.formatDecimal(pctAfterTopUp)}% (${Formatters.formatSmart(fuelAfterTopUp)} L)',
                                                  style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 11.5, color: Color(0xFF2563EB)),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '+${Formatters.formatSmart(rec.fuelAdded)} L Added',
                                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF16A34A), fontWeight: AppFontWeights.medium),
                                                ),
                                              ],
                                            )
                                          : const Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                    ),
                                  ),
                                  // 8. Consumption Rate (Formula from DG HSD page)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: Text(
                                        rec.runningHours > 0 ? '${Formatters.formatDecimal(burnRate)} L/hr' : '—',
                                        style: const TextStyle(fontWeight: AppFontWeights.semiBold, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    child: Center(
                                      child: Text(
                                        r.date,
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Center(child: Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Center(child: Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Center(child: Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Center(child: Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Center(child: Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Center(child: Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Center(child: Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))),
                                ],
                              );
                            }
                          }),
                          // Total summary row
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFDBEAFE)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Center(
                                  child: Text(
                                    'TOTAL (${monthRecords.length})',
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 11.5, color: Color(0xFF1E40AF)),
                                  ),
                                ),
                              ),
                              const Padding(padding: EdgeInsets.all(8), child: Center(child: Text('—'))),
                              const Padding(padding: EdgeInsets.all(8), child: Center(child: Text('—'))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Center(
                                  child: Text(
                                    '${Formatters.formatSmart(totalKwh)} kWh',
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12, color: Color(0xFFD97706)),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Center(
                                  child: Text(
                                    '${Formatters.formatSmart(totalHsd)} L',
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12.5, color: Color(0xFF2563EB)),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Center(
                                  child: Text(
                                    '${Formatters.formatSmart(totalHours)} Hrs',
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12, color: Color(0xFF1E40AF)),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Center(
                                  child: Text(
                                    totalFuelAdded > 0 ? '+${Formatters.formatSmart(totalFuelAdded)} L Added' : '—',
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 11.5, color: Color(0xFF15803D)),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Center(
                                  child: Text(
                                    '${Formatters.formatDecimal(avgConsumptionRate)} L/hr',
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12, color: Color(0xFF1E40AF)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PRINTABLE DIALOGS
  // ---------------------------------------------------------------------------
  void _showPrintableBoilerDialog(
    BuildContext context,
    List<_BoilerReportRow> rows,
    double totalFuel,
    double totalHours,
    double avgBurnRate,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960, maxHeight: 780),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.print_rounded, color: Color(0xFFD97706), size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Boiler Report',
                                style: TextStyle(fontSize: AppTextSizes.subheading, fontWeight: AppFontWeights.bold),
                              ),
                              Text('CASEYA • Purabi Dairy, Silchar Plant', style: TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.print_rounded, size: 16),
                            label: const Text('Print Sheet'),
                            onPressed: () {
                              printLedger();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✓ Triggered print sheet in browser.'), backgroundColor: AppColors.primary, duration: Duration(seconds: 2)),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Center(
                              child: Text('CASEYA\nPurabi Dairy, Silchar Plant\nBoiler Report', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildPrintableSummaryItem('Total Fuel Burned', '${Formatters.formatSmart(totalFuel)} Litres'),
                                  _buildPrintableSummaryItem('Total Operating Time', '${Formatters.formatSmart(totalHours)} Hours'),
                                  _buildPrintableSummaryItem('Avg Burn Rate', '${Formatters.formatSmart(avgBurnRate)} L/hr'),
                                  _buildPrintableSummaryItem('Logs Count', '${rows.where((r) => r.hasActivity).length} Entries'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Table(
                              border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 1),
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                                  children: [
                                    _PrintTableHeader('Date / Time'),
                                    _PrintTableHeader('Opening Level'),
                                    _PrintTableHeader('Closing Level'),
                                    _PrintTableHeader('Level Diff'),
                                    _PrintTableHeader('Fuel Consumption'),
                                    _PrintTableHeader('Running Hours'),
                                    _PrintTableHeader('Fuel Burnrate'),
                                    _PrintTableHeader('Fuel Top-up'),
                                  ],
                                ),
                                ...rows.map((r) {
                                  if (r.hasActivity && r.record != null) {
                                    final rec = r.record!;
                                    final double levelDiff = rec.openingCm - rec.closingCm;
                                    final double fuel = levelDiff > 0 ? ((levelDiff * 900.0) / 70.0) : (rec.calculatedLevelConsumption > 0 ? rec.calculatedLevelConsumption : 0.0);
                                    final double burnRate = rec.runningHours > 0 ? (fuel / rec.runningHours) : 0.0;
                                    return TableRow(
                                      children: [
                                        _PrintTableCell('${rec.date}${rec.time.isNotEmpty ? '\n${rec.time}' : ''}', isBold: true),
                                        _PrintTableCell('${Formatters.formatSmart(rec.openingCm)} CM'),
                                        _PrintTableCell('${Formatters.formatSmart(rec.closingCm)} CM'),
                                        _PrintTableCell('${Formatters.formatSmart(levelDiff)} CM', isBold: true),
                                        _PrintTableCell('${Formatters.formatSmart(fuel)} L', isBold: true, color: const Color(0xFFD97706)),
                                        _PrintTableCell('${Formatters.formatSmart(rec.runningHours)} Hrs'),
                                        _PrintTableCell(rec.runningHours > 0 ? '${Formatters.formatDecimal(burnRate)} L/hr' : '—'),
                                        _PrintTableCell(rec.fuelTopUp > 0 ? '${Formatters.formatSmart(rec.fuelTopUp)} L' : '—'),
                                      ],
                                    );
                                  } else {
                                    return TableRow(
                                      children: [
                                        _PrintTableCell(r.date, isBold: true),
                                        const _PrintTableCell('—'),
                                        const _PrintTableCell('—'),
                                        const _PrintTableCell('—'),
                                        const _PrintTableCell('—'),
                                        const _PrintTableCell('—'),
                                        const _PrintTableCell('—'),
                                        const _PrintTableCell('—'),
                                      ],
                                    );
                                  }
                                }),
                              ],
                            ),
                            const SizedBox(height: 36),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: const [
                                _PrintSignature(name: 'Biraj Goswami', title: 'Boiler Incharge'),
                                _PrintSignature(title: 'Verified by'),
                                _PrintSignature(title: 'Plant Head'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPrintableDgDialog(
    BuildContext context,
    List<_DgReportRow> rows,
    double totalHsd,
    double totalKwh,
    double totalHours,
    double avgEfficiency,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960, maxHeight: 780),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.print_rounded, color: Color(0xFF2563EB), size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DG Report',
                                style: TextStyle(fontSize: AppTextSizes.subheading, fontWeight: AppFontWeights.bold),
                              ),
                              Text('CASEYA • Purabi Dairy, Silchar Plant', style: TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.print_rounded, size: 16),
                            label: const Text('Print Sheet'),
                            onPressed: () {
                              printLedger();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✓ Triggered print sheet in browser.'), backgroundColor: AppColors.primary, duration: Duration(seconds: 2)),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Center(
                              child: Text('CASEYA\nPurabi Dairy, Silchar Plant\nDG Report', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildPrintableSummaryItem('Total Fuel Consumed', '${Formatters.formatSmart(totalHsd)} Litres'),
                                  _buildPrintableSummaryItem('Energy Generated', '${Formatters.formatSmart(totalKwh)} kWh'),
                                  _buildPrintableSummaryItem('Running Time', '${Formatters.formatSmart(totalHours)} Hours'),
                                  _buildPrintableSummaryItem('Logs Count', '${rows.where((r) => r.hasActivity).length} Entries'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Table(
                              border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 1),
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                                  children: [
                                    _PrintTableHeader('Date / Time'),
                                    _PrintTableHeader('Start %'),
                                    _PrintTableHeader('End %'),
                                    _PrintTableHeader('Energy (kWh)'),
                                    _PrintTableHeader('Fuel Consumed'),
                                    _PrintTableHeader('Running Hours'),
                                    _PrintTableHeader('Level After Top-up'),
                                    _PrintTableHeader('Burn Rate'),
                                  ],
                                ),
                                ...rows.map((r) {
                                  if (r.hasActivity && r.record != null) {
                                    final rec = r.record!;
                                    final double fuel = rec.fuelConsumption > 0 ? rec.fuelConsumption : (((rec.startPercentage - rec.endPercentage) / 100.0 * 380.0) + rec.fuelAdded);
                                    final double burnRate = rec.runningHours > 0 ? (fuel / rec.runningHours) : (rec.consumptionPerHour > 0 ? rec.consumptionPerHour : 0.0);
                                    final double openingL = (rec.startPercentage / 100.0) * 380.0;
                                    final double fuelAfterTopUp = openingL + rec.fuelAdded;
                                    final double pctAfterTopUp = (fuelAfterTopUp / 380.0) * 100.0;

                                    return TableRow(
                                      children: [
                                        _PrintTableCell('${rec.date}${rec.time.isNotEmpty ? '\n${rec.time}' : ''}', isBold: true),
                                        _PrintTableCell('${Formatters.formatSmart(rec.startPercentage)}%'),
                                        _PrintTableCell('${Formatters.formatSmart(rec.endPercentage)}%'),
                                        _PrintTableCell('${Formatters.formatSmart(rec.kwh)} kWh', isBold: true, color: const Color(0xFFD97706)),
                                        _PrintTableCell('${Formatters.formatSmart(fuel)} L', isBold: true, color: const Color(0xFF2563EB)),
                                        _PrintTableCell('${Formatters.formatSmart(rec.runningHours)} Hrs'),
                                        _PrintTableCell(rec.fuelAdded > 0 ? '${Formatters.formatDecimal(pctAfterTopUp)}%\n(+${Formatters.formatSmart(rec.fuelAdded)}L)' : '—'),
                                        _PrintTableCell(rec.runningHours > 0 ? '${Formatters.formatDecimal(burnRate)} L/hr' : '—'),
                                      ],
                                    );
                                  } else {
                                    return TableRow(
                                      children: [
                                        _PrintTableCell(r.date, isBold: true),
                                        const _PrintTableCell('—'),
                                        const _PrintTableCell('—'),
                                        const _PrintTableCell('—'),
                                        const _PrintTableCell('—'),
                                        const _PrintTableCell('—'),
                                        const _PrintTableCell('—'),
                                        const _PrintTableCell('—'),
                                      ],
                                    );
                                  }
                                }),
                              ],
                            ),
                            const SizedBox(height: 36),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: const [
                                _PrintSignature(name: 'Biraj Goswami', title: 'Electrical Supervisor'),
                                _PrintSignature(title: 'Verified by'),
                                _PrintSignature(title: 'Plant Head'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPrintableLedgerDialog(BuildContext context, MonthlyStockLedgerResult result) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final currentMonthName = DateFormat('MMMM yyyy').format(result.month);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960, maxHeight: 780),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.print_rounded, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Store Ledger: ${result.item.name}',
                                    style: const TextStyle(
                                      fontSize: AppTextSizes.subheading,
                                      fontWeight: AppFontWeights.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'CASEYA • Purabi Dairy, Silchar Plant • $currentMonthName',
                                    style: const TextStyle(
                                      fontSize: AppTextSizes.caption,
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Export XLSX'),
                            onPressed: () => _exportLedgerXlsx(result),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.print_rounded, size: 16),
                            label: const Text('Print Sheet'),
                            onPressed: () {
                              printLedger();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Triggered print sheet in browser.'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 14),
                            Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text('CASEYA', style: TextStyle(fontWeight: AppFontWeights.bold, fontSize: 18, letterSpacing: 1.5, color: Color(0xFF0F172A)), textAlign: TextAlign.center),
                                  const SizedBox(height: 3),
                                  const Text('Purabi Dairy, Silchar Plant', style: TextStyle(fontWeight: AppFontWeights.bold, fontSize: 14, color: Color(0xFF334155)), textAlign: TextAlign.center),
                                  const SizedBox(height: 3),
                                  const Text('Monthly Material Stock Register', style: TextStyle(fontWeight: AppFontWeights.semiBold, fontSize: 12.5, color: AppColors.textSecondary, letterSpacing: 0.5), textAlign: TextAlign.center),
                                  const SizedBox(height: 4),
                                  Text('$currentMonthName • ${result.item.name}', style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.medium, color: AppColors.textPrimary), textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildPrintableSummaryItem('Opening Stock', '${Formatters.formatSmart(result.openingStock)} ${result.item.baseUnit}'),
                                  _buildPrintableSummaryItem('Received Quantity', '+${Formatters.formatSmart(result.totalReceipts)} ${result.item.baseUnit}'),
                                  _buildPrintableSummaryItem('Issued Quantity', '−${Formatters.formatSmart(result.totalIssues)} ${result.item.baseUnit}'),
                                  _buildPrintableSummaryItem('Closing Balance', '${Formatters.formatSmart(result.closingStock)} ${result.item.baseUnit}'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Table(
                              border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 1),
                              columnWidths: const {
                                0: FixedColumnWidth(95),
                                1: FlexColumnWidth(3),
                                2: FixedColumnWidth(120),
                                3: FixedColumnWidth(115),
                                4: FixedColumnWidth(115),
                                5: FixedColumnWidth(125),
                              },
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                                  children: [
                                    _PrintTableHeader('Date'),
                                    _PrintTableHeader('Particulars'),
                                    _PrintTableHeader('Previous Stock'),
                                    _PrintTableHeader('Received Qty'),
                                    _PrintTableHeader('Issued Qty'),
                                    _PrintTableHeader('Balance in Stock'),
                                  ],
                                ),
                                ...result.rows.map((r) {
                                  final bg = r.hasActivity ? const Color(0xFFF0FDF4) : Colors.white;
                                  return TableRow(
                                    decoration: BoxDecoration(color: bg),
                                    children: [
                                      _PrintTableCell(r.dateDisplay, isBold: true),
                                      _PrintTableCell(r.particulars),
                                      _PrintTableCell('${Formatters.formatSmart(r.previousStock)} ${result.item.baseUnit}'),
                                      _PrintTableCell(r.receiptQty > 0 ? '+${Formatters.formatSmart(r.receiptQty)} ${result.item.baseUnit}' : '—', color: r.receiptQty > 0 ? const Color(0xFF16A34A) : null),
                                      _PrintTableCell(r.issuedQty > 0 ? '−${Formatters.formatSmart(r.issuedQty)} ${result.item.baseUnit}' : '—', color: r.issuedQty > 0 ? const Color(0xFFDC2626) : null),
                                      _PrintTableCell('${Formatters.formatSmart(r.balanceStock)} ${result.item.baseUnit}', isBold: true, color: AppColors.primary),
                                    ],
                                  );
                                }),
                                TableRow(
                                  decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                                  children: [
                                    const _PrintTableCell('TOTAL', isBold: true),
                                    const _PrintTableCell('Monthly Summary', isBold: true),
                                    _PrintTableCell('${Formatters.formatSmart(result.openingStock)} ${result.item.baseUnit}', isBold: true),
                                    _PrintTableCell('+${Formatters.formatSmart(result.totalReceipts)} ${result.item.baseUnit}', isBold: true, color: const Color(0xFF16A34A)),
                                    _PrintTableCell('−${Formatters.formatSmart(result.totalIssues)} ${result.item.baseUnit}', isBold: true, color: const Color(0xFFDC2626)),
                                    _PrintTableCell('${Formatters.formatSmart(result.closingStock)} ${result.item.baseUnit}', isBold: true, color: AppColors.primary),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: const [
                                _PrintSignature(name: 'Biraj Goswami', title: 'Caseya Developer'),
                                _PrintSignature(title: 'Verified by'),
                                _PrintSignature(title: 'Plant Head'),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrintableSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: AppFontWeights.medium)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: AppFontWeights.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  void _showDayParticularsDetailDialog(
    BuildContext context,
    StockLedgerDayRow row,
    InventoryItemModel item,
    List<InventoryItemModel> allItems,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Particulars: ${row.dateDisplay}',
                      style: const TextStyle(
                        fontSize: AppTextSizes.subheading,
                        fontWeight: AppFontWeights.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${item.name} (${item.category})',
                      style: const TextStyle(
                        fontSize: AppTextSizes.caption,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Previous Stock (Day Opening)', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                            Text('${Formatters.formatSmart(row.previousStock)} ${item.baseUnit}', style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Day Closing Balance', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                            Text('${Formatters.formatSmart(row.balanceStock)} ${item.baseUnit}', style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13, color: AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.input_rounded, size: 16, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Text(
                        'Material Inward Receipts (+${Formatters.formatSmart(row.receiptQty)} ${item.baseUnit})',
                        style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (row.inwardEntries.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('No material received on this day.', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                    )
                  else
                    ...row.inwardEntries.map((e) {
                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _showEditReceivedDialog(context, row, item, allItems);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '+${Formatters.formatSmart(e.quantity)} ${e.unit} (${Formatters.formatSmart(e.packages)} packages)',
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12.5, color: Color(0xFF16A34A)),
                                  ),
                                  Row(
                                    children: [
                                      Text(e.time, style: const TextStyle(fontSize: 11, fontWeight: AppFontWeights.medium, color: AppColors.textSecondary)),
                                      const SizedBox(width: 5),
                                      const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF16A34A)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Logged by: ${e.loggedBy}${e.notes.isNotEmpty ? ' • Note: ${e.notes}' : ''}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.output_rounded, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 6),
                      Text(
                        'Material Issued for Production (−${Formatters.formatSmart(row.issuedQty)} ${item.baseUnit})',
                        style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13, color: Color(0xFFD97706)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (row.deductionEntries.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('No production usage / issues recorded on this day.', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                    )
                  else
                    ...row.deductionEntries.map((d) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.productName, style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12)),
                                  Text('Batch #${d.batchNo} • ${d.source}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text('−${Formatters.formatSmart(d.quantityDeducted)} ${d.unit}', style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12.5, color: Color(0xFFD97706))),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFDC2626)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.edit_note_rounded, size: 16),
              label: const Text('Adjust Issue'),
              onPressed: () {
                Navigator.pop(ctx);
                _showEditIssuedDialog(context, row, item, allItems);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showEditReceivedDialog(
    BuildContext context,
    StockLedgerDayRow row,
    InventoryItemModel currentItem,
    List<InventoryItemModel> allItems,
  ) {
    final existingEntry = row.inwardEntries.isNotEmpty ? row.inwardEntries.first : null;
    final initialQty = row.receiptQty > 0 ? Formatters.formatSmart(row.receiptQty) : '';
    final initialPackages = (existingEntry != null && existingEntry.packages > 0)
        ? Formatters.formatSmart(existingEntry.packages)
        : (currentItem.itemsPerPackage > 0 && row.receiptQty > 0
            ? Formatters.formatSmart(row.receiptQty / currentItem.itemsPerPackage)
            : '');
    final initialNotes = existingEntry?.notes ?? '';
    final initialLoggedBy = existingEntry?.loggedBy.isNotEmpty == true
        ? existingEntry!.loggedBy
        : ProductionState.authorizedPersonsList.first;

    final qtyController = TextEditingController(text: initialQty);
    final packagesController = TextEditingController(text: initialPackages);
    final notesController = TextEditingController(text: initialNotes);
    String selectedPerson = ProductionState.authorizedPersonsList.contains(initialLoggedBy)
        ? initialLoggedBy
        : ProductionState.authorizedPersonsList.first;

    bool isUpdatingFromQty = false;
    bool isUpdatingFromPackages = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: Color(0xFF16A34A), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.receiptQty > 0 ? 'Edit / Erase Received Stock' : 'Record Received Stock',
                          style: const TextStyle(fontSize: 16, fontWeight: AppFontWeights.bold),
                        ),
                        Text(
                          '${currentItem.name} • ${row.dateDisplay}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: AppFontWeights.medium),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(dialogCtx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF16A34A)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Packaging: 1 ${currentItem.packagingUnit.toLowerCase().replaceAll(RegExp(r's$'), '')} = ${Formatters.formatSmart(currentItem.itemsPerPackage)} ${currentItem.baseUnit}',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF15803D), fontWeight: AppFontWeights.medium),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Packages / Boxes input
                      Text(
                        'Number of ${currentItem.packagingUnit}',
                        style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: packagesController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'e.g. 5',
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (packagesController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.cancel_rounded, size: 16, color: AppColors.textMuted),
                                  onPressed: () {
                                    packagesController.clear();
                                    qtyController.clear();
                                    setDialogState(() {});
                                  },
                                  tooltip: 'Clear',
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  padding: EdgeInsets.zero,
                                ),
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(currentItem.packagingUnit, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          if (isUpdatingFromQty) {
                            setDialogState(() {});
                            return;
                          }
                          isUpdatingFromPackages = true;
                          final pkg = double.tryParse(val.trim()) ?? 0.0;
                          final qty = pkg * currentItem.itemsPerPackage;
                          qtyController.text = qty > 0 ? Formatters.formatSmart(qty) : '';
                          isUpdatingFromPackages = false;
                          setDialogState(() {});
                        },
                      ),
                      const SizedBox(height: 12),

                      // Total Quantity in baseUnit
                      Text(
                        'Received Quantity (${currentItem.baseUnit})',
                        style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: qtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'e.g. 10000',
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (qtyController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.cancel_rounded, size: 16, color: AppColors.textMuted),
                                  onPressed: () {
                                    qtyController.clear();
                                    packagesController.clear();
                                    setDialogState(() {});
                                  },
                                  tooltip: 'Clear',
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  padding: EdgeInsets.zero,
                                ),
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(currentItem.baseUnit, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          if (isUpdatingFromPackages) {
                            setDialogState(() {});
                            return;
                          }
                          isUpdatingFromQty = true;
                          final q = double.tryParse(val.trim()) ?? 0.0;
                          if (currentItem.itemsPerPackage > 0) {
                            final pkg = q / currentItem.itemsPerPackage;
                            packagesController.text = pkg > 0 ? Formatters.formatSmart(pkg) : '';
                          }
                          isUpdatingFromQty = false;
                          setDialogState(() {});
                        },
                      ),
                      const SizedBox(height: 12),

                      // Logged By dropdown
                      const Text(
                        'Received By / Authorized Person',
                        style: TextStyle(fontSize: 12, fontWeight: AppFontWeights.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder, width: 1.1),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedPerson,
                            isExpanded: true,
                            items: ProductionState.authorizedPersonsList.map((p) {
                              return DropdownMenuItem<String>(
                                value: p,
                                child: Text(p, style: const TextStyle(fontSize: 12.5)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedPerson = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Notes / Supplier
                      const Text(
                        'Notes / Supplier / Challan',
                        style: TextStyle(fontSize: 12, fontWeight: AppFontWeights.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Invoice #2041 / Supplier delivery',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (row.receiptQty > 0)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Erase / Clear Received'),
                    onPressed: () async {
                      final dateStr = DateFormat('yyyy-MM-dd').format(row.date);
                      Navigator.pop(dialogCtx);
                      await ref.read(inventoryStockProvider.notifier).setOrUpdateInwardStock(
                        itemId: currentItem.id,
                        quantity: 0.0,
                        packages: 0.0,
                        date: dateStr,
                        time: DateFormat('hh:mm a').format(DateTime.now()),
                        loggedBy: selectedPerson,
                        notes: '',
                      );
                      if (mounted) setState(() {});
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Erased received stock on ${row.dateDisplay}'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                OutlinedButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Save Received'),
                  onPressed: () async {
                    final q = double.tryParse(qtyController.text.trim()) ?? 0.0;
                    final pkg = double.tryParse(packagesController.text.trim()) ??
                        (currentItem.itemsPerPackage > 0 ? q / currentItem.itemsPerPackage : 0.0);
                    final dateStr = DateFormat('yyyy-MM-dd').format(row.date);
                    final timeStr = DateFormat('hh:mm a').format(DateTime.now());

                    Navigator.pop(dialogCtx);
                    await ref.read(inventoryStockProvider.notifier).setOrUpdateInwardStock(
                      itemId: currentItem.id,
                      quantity: q,
                      packages: pkg,
                      date: dateStr,
                      time: timeStr,
                      loggedBy: selectedPerson,
                      notes: notesController.text.trim(),
                    );
                    if (mounted) setState(() {});
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(q > 0
                            ? '✓ Updated received stock for ${currentItem.name}: ${Formatters.formatSmart(q)} ${currentItem.baseUnit} (${row.dateDisplay})'
                            : '✓ Erased/Cleared received stock for ${currentItem.name} (${row.dateDisplay})'),
                        backgroundColor: const Color(0xFF16A34A),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditIssuedDialog(
    BuildContext context,
    StockLedgerDayRow row,
    InventoryItemModel currentItem,
    List<InventoryItemModel> allItems,
  ) {
    final initialQty = row.issuedQty > 0 ? Formatters.formatSmart(row.issuedQty) : '';
    final initialNotes = row.deductionEntries.isNotEmpty
        ? row.deductionEntries.map((d) => d.productName).join(', ')
        : 'Production usage';
    final qtyController = TextEditingController(text: initialQty);
    final notesController = TextEditingController(text: initialNotes);
    String selectedPerson = ProductionState.authorizedPersonsList.first;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: Color(0xFFDC2626), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.issuedQty > 0 ? 'Edit / Erase Issued Quantity' : 'Record Issued Quantity',
                          style: const TextStyle(fontSize: 16, fontWeight: AppFontWeights.bold),
                        ),
                        Text(
                          '${currentItem.name} • ${row.dateDisplay}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: AppFontWeights.medium),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(dialogCtx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (row.deductionEntries.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.factory_rounded, size: 15, color: Color(0xFFD97706)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Production Register Entries on this day:',
                                    style: TextStyle(fontSize: 11.5, fontWeight: AppFontWeights.bold, color: Color(0xFFB45309)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ...row.deductionEntries.map((d) => Text(
                                    '• ${d.productName} (Batch #${d.batchNo}): −${Formatters.formatSmart(d.quantityDeducted)} ${d.unit}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  )),
                            ],
                          ),
                        ),

                      // Issued Quantity input
                      Text(
                        'Total Issued Quantity (${currentItem.baseUnit})',
                        style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: qtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'e.g. 3000',
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (qtyController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.cancel_rounded, size: 16, color: AppColors.textMuted),
                                  onPressed: () {
                                    qtyController.clear();
                                    setDialogState(() {});
                                  },
                                  tooltip: 'Clear',
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  padding: EdgeInsets.zero,
                                ),
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(currentItem.baseUnit, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 12),

                      // Authorized Person dropdown
                      const Text(
                        'Issued By / Authorized Person',
                        style: TextStyle(fontSize: 12, fontWeight: AppFontWeights.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder, width: 1.1),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedPerson,
                            isExpanded: true,
                            items: ProductionState.authorizedPersonsList.map((p) {
                              return DropdownMenuItem<String>(
                                value: p,
                                child: Text(p, style: const TextStyle(fontSize: 12.5)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedPerson = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Reason / Note
                      const Text(
                        'Issue Reason / Product Remarks',
                        style: TextStyle(fontSize: 12, fontWeight: AppFontWeights.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Packaging run / Store issue',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (row.issuedQty > 0)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Erase / Clear Issued'),
                    onPressed: () async {
                      final dateStr = DateFormat('yyyy-MM-dd').format(row.date);
                      Navigator.pop(dialogCtx);
                      await ref.read(inventoryStockProvider.notifier).setOrUpdateIssuedStock(
                        itemId: currentItem.id,
                        quantity: 0.0,
                        date: dateStr,
                        time: DateFormat('hh:mm a').format(DateTime.now()),
                        loggedBy: selectedPerson,
                        notes: '',
                      );
                      if (mounted) setState(() {});
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Erased issued stock on ${row.dateDisplay}'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                OutlinedButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Save Issued'),
                  onPressed: () async {
                    final q = double.tryParse(qtyController.text.trim()) ?? 0.0;
                    final dateStr = DateFormat('yyyy-MM-dd').format(row.date);
                    final timeStr = DateFormat('hh:mm a').format(DateTime.now());

                    Navigator.pop(dialogCtx);
                    await ref.read(inventoryStockProvider.notifier).setOrUpdateIssuedStock(
                      itemId: currentItem.id,
                      quantity: q,
                      date: dateStr,
                      time: timeStr,
                      loggedBy: selectedPerson,
                      notes: notesController.text.trim(),
                    );
                    if (mounted) setState(() {});
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(q > 0
                            ? '✓ Updated issued stock for ${currentItem.name}: ${Formatters.formatSmart(q)} ${currentItem.baseUnit} (${row.dateDisplay})'
                            : '✓ Erased/Cleared issued stock for ${currentItem.name} (${row.dateDisplay})'),
                        backgroundColor: const Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PrintTableHeader extends StatelessWidget {
  final String text;
  const _PrintTableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: AppFontWeights.bold,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }
}

class _PrintTableCell extends StatelessWidget {
  final String text;
  final bool isBold;
  final Color? color;

  const _PrintTableCell(this.text, {this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? AppFontWeights.bold : AppFontWeights.regular,
          color: color ?? const Color(0xFF334155),
        ),
      ),
    );
  }
}

class _PrintSignature extends StatelessWidget {
  final String title;
  final String? name;

  const _PrintSignature({required this.title, this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 20,
          child: (name != null && name!.isNotEmpty)
              ? Text(
                  name!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: AppFontWeights.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 4),
        Container(
          width: 170,
          height: 1.2,
          color: Colors.black54,
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: AppFontWeights.bold,
            color: Color(0xFF334155),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LedgerHeaderCell extends StatelessWidget {
  final String text;
  const _LedgerHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: AppFontWeights.bold,
            fontSize: AppTextSizes.caption,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _BoilerReportRow {
  final String date;
  final String time;
  final BoilerRecord? record;
  final bool hasActivity;

  const _BoilerReportRow({
    required this.date,
    required this.time,
    this.record,
    required this.hasActivity,
  });
}

class _DgReportRow {
  final String date;
  final String time;
  final DgHsdRecord? record;
  final bool hasActivity;

  const _DgReportRow({
    required this.date,
    required this.time,
    this.record,
    required this.hasActivity,
  });
}

// ---------------------------------------------------------------------------
// Report Catalogue Chip Widget
// ---------------------------------------------------------------------------
class _ReportCatalogueChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReportCatalogueChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ReportCatalogueChip> createState() => _ReportCatalogueChipState();
}

class _ReportCatalogueChipState extends State<_ReportCatalogueChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (_isHovered ? const Color(0xFFF1F5F9) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (_isHovered
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.cardBorder),
            width: isSelected ? 1.5 : 1.1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : (_isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      const BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ]),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: AppTextSizes.body,
                  fontWeight: isSelected ? AppFontWeights.bold : AppFontWeights.medium,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


