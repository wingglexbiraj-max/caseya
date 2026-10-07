import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/live_time_chip.dart';
import '../../models/inventory_item_model.dart';
import '../../models/stock_ledger_entry_model.dart';
import '../../providers/inventory_stock_provider.dart';
import '../../providers/production_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../core/utils/stock_ledger_exporter.dart';
import '../../core/widgets/metric_card.dart';

class StockPage extends ConsumerStatefulWidget {
  const StockPage({super.key});

  @override
  ConsumerState<StockPage> createState() => _StockPageState();
}

class _StockPageState extends ConsumerState<StockPage> {
  DateTime _selectedLedgerMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String? _selectedLedgerItemId;
  bool _showAllMonthDays = true;
  bool _showAllHistory = false;

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
      {'id': 'cup_s80', 'name': 'S80 Cup (Sweet Curd 80g)', 'reason': '1:1 Cup for S80'},
    ],
    'cup_s200': [
      {'id': 'foil_pink_200_400', 'name': 'Alum Foil (Pink) 200/400gm', 'reason': '1:1 Foil lid for S200'},
      {'id': 'serving_wooden_spoon', 'name': 'Wooden Spoon', 'reason': '1:1 Spoon for S200'},
    ],
    'cup_s400': [
      {'id': 'foil_pink_200_400', 'name': 'Alum Foil (Pink) 200/400gm', 'reason': '1:1 Foil lid for S400'},
      {'id': 'serving_wooden_spoon', 'name': 'Wooden Spoon', 'reason': '1:1 Spoon for S400'},
    ],
    'foil_pink_200_400': [
      {'id': 'cup_s200', 'name': 'S200 Cup (Sweet Curd 200g)', 'reason': 'Shared Foil for S200'},
      {'id': 'cup_s400', 'name': 'S400 Cup (Sweet Curd 400g)', 'reason': 'Shared Foil for S400'},
    ],
    'cup_p80': [
      {'id': 'foil_blue_80', 'name': 'Alum Foil (Blue) 80gm', 'reason': '1:1 Foil lid for P80 Cup'},
      {'id': 'serving_wooden_spoon', 'name': 'Wooden Spoon', 'reason': '1:1 Spoon for P80'},
    ],
    'cup_p200': [
      {'id': 'foil_blue_200_400', 'name': 'Alum Foil (Blue) 200/400gm', 'reason': '1:1 Foil lid for P200'},
      {'id': 'serving_wooden_spoon', 'name': 'Wooden Spoon', 'reason': '1:1 Spoon for P200'},
    ],
    'cup_p400': [
      {'id': 'foil_blue_200_400', 'name': 'Alum Foil (Blue) 200/400gm', 'reason': '1:1 Foil lid for P400'},
      {'id': 'serving_wooden_spoon', 'name': 'Wooden Spoon', 'reason': '1:1 Spoon for P400'},
    ],
    'foil_blue_200_400': [
      {'id': 'cup_p200', 'name': 'P200 Cup (Plain Curd 200g)', 'reason': 'Shared Foil for P200'},
      {'id': 'cup_p400', 'name': 'P400 Cup (Plain Curd 400g)', 'reason': 'Shared Foil for P400'},
    ],
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedLedgerMonth = DateTime(now.year, now.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetMonth = ref.read(stockLedgerTargetMonthProvider);
      final targetItem = ref.read(stockLedgerTargetItemProvider);
      if (targetMonth != null || targetItem != null) {
        setState(() {
          if (targetMonth != null) {
            _selectedLedgerMonth = DateTime(targetMonth.year, targetMonth.month, 1);
          }
          if (targetItem != null) {
            _selectedLedgerItemId = targetItem;
          }
        });
        ref.read(stockLedgerTargetMonthProvider.notifier).state = null;
        ref.read(stockLedgerTargetItemProvider.notifier).state = null;
      }
    });
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Cups':
        return Icons.takeout_dining_rounded;
      case 'Poly Roll':
        return Icons.album_rounded;
      case 'Aluminium Foil':
        return Icons.circle_outlined;
      case 'Serving Material':
        return Icons.flatware_rounded;
      case 'Ingredients':
        return Icons.grain_rounded;
      default:
        return Icons.all_inbox_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(stockLedgerTargetItemProvider, (prev, next) {
      if (next != null && next.isNotEmpty) {
        setState(() {
          _selectedLedgerItemId = next;
        });
        ref.read(stockLedgerTargetItemProvider.notifier).state = null;
      }
    });

    ref.listen<DateTime?>(stockLedgerTargetMonthProvider, (prev, next) {
      if (next != null) {
        setState(() {
          _selectedLedgerMonth = DateTime(next.year, next.month, 1);
        });
        ref.read(stockLedgerTargetMonthProvider.notifier).state = null;
      }
    });

    final isMobile = ResponsiveLayout.isMobile(context);
    final stockState = ref.watch(inventoryStockProvider);
    final filtered = stockState.filteredItems;
    final counts = stockState.categoryCounts;

    final categories = ['All', 'Cups', 'Poly Roll', 'Aluminium Foil', 'Serving Material', 'Ingredients'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 28,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date-wise Stock Report & Material Store Ledger Section
            _buildDateWiseStockReportSection(
              context: context,
              isMobile: isMobile,
              stockState: stockState,
            ),
            const SizedBox(height: 18),

            // Main Inventory Table Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with "+ Add New Stock" Chip (replaces search bar)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Inventory Items',
                        style: TextStyle(
                          fontSize: AppTextSizes.subheading,
                          fontWeight: AppFontWeights.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      InkWell(
                        onTap: () => _showAddStockDialog(context, stockState.allItems),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              width: 1.0,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_circle_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '+ Add New Stock',
                                style: TextStyle(
                                  fontSize: AppTextSizes.caption,
                                  fontWeight: AppFontWeights.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Category Filter Chips with Dynamic Item Counts
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = stockState.selectedCategory == cat;
                      final count = counts[cat] ?? 0;
                      final chipText = '$cat ($count)';

                      return _StockCategoryFilterChip(
                        label: chipText,
                        icon: _getCategoryIcon(cat),
                        isSelected: isSelected,
                        onTap: () => ref.read(inventoryStockProvider.notifier).setSelectedCategory(cat),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    '${filtered.length} ITEMS LOGGED',
                    style: const TextStyle(
                      fontSize: AppTextSizes.caption,
                      fontWeight: AppFontWeights.bold,
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 10),
                          const Text(
                            'No inventory items match your search.',
                            style: TextStyle(fontWeight: AppFontWeights.bold, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try changing category filter or search keywords.',
                            style: TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth < 680
                            ? 1
                            : (constraints.maxWidth < 1200 ? 2 : 3);
                        final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 14)) / crossAxisCount;

                        return Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: filtered.map((item) {
                            return SizedBox(
                              width: itemWidth,
                              child: _InventoryChipCard(
                                item: item,
                                onSelect: () => setState(() => _selectedLedgerItemId = item.id),
                                onAddStock: () => _showAddStockDialog(context, stockState.allItems, item),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
    _showMonthYearPickerDialog(context);
  }

  void _showMonthYearPickerDialog(BuildContext context) {
    int activeYear = _selectedLedgerMonth.year;
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
                          final isSelected = _selectedLedgerMonth.year == activeYear && _selectedLedgerMonth.month == monthNum;
                          final isCurrent = now.year == activeYear && now.month == monthNum;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedLedgerMonth = DateTime(activeYear, monthNum, 1);
                              });
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
                              setState(() {
                                _selectedLedgerMonth = DateTime(now.year, now.month, 1);
                              });
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

  bool _isExporting = false;

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

  Widget _buildDateWiseStockReportSection({
    required BuildContext context,
    required bool isMobile,
    required InventoryStockState stockState,
  }) {
    final allItems = stockState.allItems;
    if (allItems.isEmpty) return const SizedBox.shrink();

    final currentItem = (allItems.any((i) => i.id == _selectedLedgerItemId))
        ? allItems.firstWhere((i) => i.id == _selectedLedgerItemId)
        : allItems.first;

    final MonthlyStockLedgerResult ledgerResult;
    if (_showAllHistory) {
      ledgerResult = StockLedgerCalculator.calculateAllActivityLedger(
        item: currentItem,
        inwardLedger: stockState.inwardLedger,
        deductionLedger: stockState.deductionLedger,
      );
    } else {
      ledgerResult = StockLedgerCalculator.calculateMonthlyLedger(
        item: currentItem,
        month: _selectedLedgerMonth,
        inwardLedger: stockState.inwardLedger,
        deductionLedger: stockState.deductionLedger,
      );
    }

    // Detect activity in other months for currentItem
    DateTime? otherMonthWithActivity;
    String? otherMonthActivitySummary;

    for (final d in stockState.deductionLedger) {
      if (d.inventoryItemId == currentItem.id) {
        final dDate = StockLedgerCalculator.parseAnyDate(d.date);
        if (dDate != null && (dDate.year != _selectedLedgerMonth.year || dDate.month != _selectedLedgerMonth.month)) {
          otherMonthWithActivity = DateTime(dDate.year, dDate.month, 1);
          otherMonthActivitySummary = '${Formatters.formatSmart(d.quantityDeducted)} ${d.unit} issued on ${DateFormat('dd-MMM-yyyy').format(dDate)} for ${d.productName}';
          break;
        }
      }
    }
    if (otherMonthWithActivity == null) {
      for (final inEntry in stockState.inwardLedger) {
        if (inEntry.itemId == currentItem.id) {
          final inDate = StockLedgerCalculator.parseAnyDate(inEntry.date);
          if (inDate != null && (inDate.year != _selectedLedgerMonth.year || inDate.month != _selectedLedgerMonth.month)) {
            otherMonthWithActivity = DateTime(inDate.year, inDate.month, 1);
            otherMonthActivitySummary = '${Formatters.formatSmart(inEntry.quantity)} ${inEntry.unit} received on ${DateFormat('dd-MMM-yyyy').format(inDate)}';
            break;
          }
        }
      }
    }

    final displayedRows = _showAllMonthDays
        ? ledgerResult.rows
        : ledgerResult.rows.where((r) => r.hasActivity || r.date.day == 1).toList();

    final prevMonth = DateTime(_selectedLedgerMonth.year, _selectedLedgerMonth.month - 1, 1);
    final nextMonth = DateTime(_selectedLedgerMonth.year, _selectedLedgerMonth.month + 1, 1);
    final prevMonthName = DateFormat('MMM yyyy').format(prevMonth);
    final nextMonthName = DateFormat('MMM yyyy').format(nextMonth);
    final currentMonthName = DateFormat('MMMM yyyy').format(_selectedLedgerMonth);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Title & Action Buttons (Print Preview & Export CSV)
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
                          'Date-wise Stock Report',
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

          // 2. Control Toolbar: Material Selection, Month Navigation, Days Filter (stretches to full width up to balance stock card)
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
                      selected: !_showAllHistory && _showAllMonthDays,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: (!_showAllHistory && _showAllMonthDays) ? Colors.white : AppColors.textPrimary,
                        fontWeight: AppFontWeights.bold,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _showAllHistory = false;
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
                      selected: !_showAllHistory && !_showAllMonthDays,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: (!_showAllHistory && !_showAllMonthDays) ? Colors.white : AppColors.textPrimary,
                        fontWeight: AppFontWeights.bold,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _showAllHistory = false;
                            _showAllMonthDays = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('All Historical Dates', style: TextStyle(fontSize: 11)),
                      selected: _showAllHistory,
                      selectedColor: const Color(0xFF10B981),
                      labelStyle: TextStyle(
                        color: _showAllHistory ? Colors.white : AppColors.textPrimary,
                        fontWeight: AppFontWeights.bold,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _showAllHistory = true;
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
                          return ActionChip(
                            backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.5),
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
                            avatar: const Icon(Icons.swap_horiz_rounded, size: 14, color: AppColors.primary),
                            label: Text(
                              '${rel['name']} (${rel['reason']})',
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
          if (otherMonthWithActivity != null && !_showAllHistory) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '📌 Activity recorded in ${DateFormat('MMMM yyyy').format(otherMonthWithActivity)}: $otherMonthActivitySummary. Currently viewing ${DateFormat('MMMM yyyy').format(_selectedLedgerMonth)}.',
                        style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.semiBold, color: Color(0xFF1E40AF)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 13),
                      label: Text('Switch to ${DateFormat('MMM yyyy').format(otherMonthWithActivity)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        setState(() {
                          _selectedLedgerMonth = otherMonthWithActivity!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
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
                cardBgColor: const Color(0xFFEFF6FF), // Dashboard Soft Blue
              );

              final cardReceipt = MetricCard(
                title: 'Received Quantity',
                value: '+${Formatters.formatSmart(ledgerResult.totalReceipts)}',
                unit: currentItem.baseUnit,
                subtitle: 'Added inward receipts',
                icon: Icons.input_rounded,
                iconColor: Colors.black.withValues(alpha: 0.60),
                iconBgColor: Colors.black.withValues(alpha: 0.06),
                cardBgColor: const Color(0xFFECFDF5), // Dashboard Soft Green
              );

              final cardIssued = MetricCard(
                title: 'Issued Quantity',
                value: '−${Formatters.formatSmart(ledgerResult.totalIssues)}',
                unit: currentItem.baseUnit,
                subtitle: 'From Production & Batches',
                icon: Icons.output_rounded,
                iconColor: Colors.black.withValues(alpha: 0.60),
                iconBgColor: Colors.black.withValues(alpha: 0.06),
                cardBgColor: const Color(0xFFFFFBEB), // Dashboard Soft Amber
              );

              final cardBalance = MetricCard(
                title: 'Balance in Stock',
                value: Formatters.formatSmart(ledgerResult.closingStock),
                unit: currentItem.baseUnit,
                subtitle: 'C/F to $nextMonthName',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: Colors.black.withValues(alpha: 0.60),
                iconBgColor: Colors.black.withValues(alpha: 0.06),
                cardBgColor: const Color(0xFFF5F3FF), // Dashboard Soft Purple
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

          // 4. Ledger Table with exact 7 columns (stretching to full width matching the metric cards above)
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
                        0: FlexColumnWidth(1.35), // Date
                        1: FlexColumnWidth(2.65), // Particulars
                        2: FlexColumnWidth(1.4),  // Previous Stock
                        3: FlexColumnWidth(1.45), // Received Quantity
                        4: FlexColumnWidth(1.45), // Issued Quantity
                        5: FlexColumnWidth(1.5),  // Balance in Stock
                      },
                      children: [
                        // Header Row (All Centered, 6 columns)
                        TableRow(
                          decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                          children: const [
                            _LedgerHeaderCell('Date'),
                            _LedgerHeaderCell('Particulars'),
                            _LedgerHeaderCell('Previous Stock'),
                            _LedgerHeaderCell('Received Quantity'),
                            _LedgerHeaderCell('Issued Quantity'),
                            _LedgerHeaderCell('Balance in Stock'),
                          ],
                        ),

                        // Data Rows (All Centered)
                        ...displayedRows.map((r) {
                          final hasReceipt = r.receiptQty > 0;
                          final hasIssue = r.issuedQty > 0;
                          final rowColor = r.hasActivity ? const Color(0xFFF0FDF4) : Colors.white;

                          return TableRow(
                            decoration: BoxDecoration(color: rowColor),
                            children: [
                              // Date Cell (Centered)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          r.hasActivity ? Icons.event_available_rounded : Icons.calendar_today_rounded,
                                          size: 13,
                                          color: r.hasActivity ? const Color(0xFF16A34A) : AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          r.dateDisplay,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: r.hasActivity ? AppFontWeights.bold : AppFontWeights.medium,
                                            fontSize: 12,
                                            color: r.hasActivity ? AppColors.textPrimary : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Particulars Cell (Centered & Clickable)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                child: Center(
                                  child: InkWell(
                                    onTap: () {
                                      if (r.inwardEntries.isNotEmpty || r.deductionEntries.isNotEmpty) {
                                        _showDayParticularsDetailDialog(context, r, currentItem, allItems);
                                      } else {
                                        _showAddStockDialog(context, allItems, currentItem, r.date);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(4),
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

                              // Previous Stock Cell (Centered)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${Formatters.formatSmart(r.previousStock)} ${currentItem.baseUnit}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.medium),
                                    ),
                                  ),
                                ),
                              ),

                              // Received Quantity Cell (Centered - Green text with clean edit pencil icon, no bg)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                                      const SizedBox(width: 8),
                                      Tooltip(
                                        message: 'Add Stock on ${r.dateDisplay}',
                                        child: InkWell(
                                          onTap: () => _showAddStockDialog(context, allItems, currentItem, r.date),
                                          borderRadius: BorderRadius.circular(4),
                                          child: const Padding(
                                            padding: EdgeInsets.all(2),
                                            child: Icon(
                                              Icons.edit_outlined,
                                              size: 13.5,
                                              color: Color(0xFF16A34A),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Issued Quantity Cell (Centered - Red text, no pencil icon)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                child: Center(
                                  child: hasIssue
                                      ? FittedBox(
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
                                        )
                                      : const Text('—', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                ),
                              ),

                              // Balance in Stock Cell (Centered)
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

                        // Total Summary Footer Row (All Centered, 6 columns)
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
                  // Dialog Header Row
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

                  // Printable Ledger Sheet View
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
                            // Official Dairy Plant Header
                            Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'CASEYA',
                                    style: TextStyle(
                                      fontWeight: AppFontWeights.bold,
                                      fontSize: 18,
                                      letterSpacing: 1.5,
                                      color: Color(0xFF0F172A),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Purabi Dairy, Silchar Plant',
                                    style: TextStyle(
                                      fontWeight: AppFontWeights.bold,
                                      fontSize: 14,
                                      color: Color(0xFF334155),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Monthly Material Stock Register',
                                    style: TextStyle(
                                      fontWeight: AppFontWeights.semiBold,
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$currentMonthName • ${result.item.name}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: AppFontWeights.medium,
                                      color: AppColors.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Summary Ribbon
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(6),
                              ),
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

                            // Full Printable Table
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
                                // Table Header
                                TableRow(
                                  decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                                  children: const [
                                    _PrintTableHeader('Date'),
                                    _PrintTableHeader('Particulars'),
                                    _PrintTableHeader('Previous Stock'),
                                    _PrintTableHeader('Received Qty'),
                                    _PrintTableHeader('Issued Qty'),
                                    _PrintTableHeader('Balance in Stock'),
                                  ],
                                ),
                                // Table Rows
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
                                // Summary Footer Row
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

                            // Signatures section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: const [
                                _PrintSignature(
                                  name: 'Biraj Goswami',
                                  title: 'Caseya Developer',
                                ),
                                _PrintSignature(
                                  title: 'Verified by',
                                ),
                                _PrintSignature(
                                  title: 'Plant Head',
                                ),
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
                  // Daily balances summary card
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

                  // Inward Materials Added / Received
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
                                      Text(
                                        e.time,
                                        style: const TextStyle(fontSize: 11, fontWeight: AppFontWeights.medium, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(width: 5),
                                      const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF16A34A)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Logged by: ${e.loggedBy}${e.notes.isNotEmpty ? ' • Note: ${e.notes}' : ''}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 16),

                  // Material Issues (Deductions from Production Register)
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
                                  Text(
                                    d.productName,
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12),
                                  ),
                                  Text(
                                    'Batch #${d.batchNo} • ${d.source}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '−${Formatters.formatSmart(d.quantityDeducted)} ${d.unit}',
                              style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12.5, color: Color(0xFFD97706)),
                            ),
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
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: const Text('+ Add Stock'),
              onPressed: () {
                Navigator.pop(ctx);
                _showAddStockDialog(context, allItems, item, row.date);
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
                        const Text(
                          'Edit Received Stock',
                          style: TextStyle(fontSize: 16, fontWeight: AppFontWeights.bold),
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
                          suffixText: currentItem.packagingUnit,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          if (isUpdatingFromQty) return;
                          isUpdatingFromPackages = true;
                          final pkg = double.tryParse(val.trim()) ?? 0.0;
                          final qty = pkg * currentItem.itemsPerPackage;
                          qtyController.text = qty > 0 ? Formatters.formatSmart(qty) : '';
                          isUpdatingFromPackages = false;
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
                          suffixText: currentItem.baseUnit,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          if (isUpdatingFromPackages) return;
                          isUpdatingFromQty = true;
                          final q = double.tryParse(val.trim()) ?? 0.0;
                          if (currentItem.itemsPerPackage > 0) {
                            final pkg = q / currentItem.itemsPerPackage;
                            packagesController.text = pkg > 0 ? Formatters.formatSmart(pkg) : '';
                          }
                          isUpdatingFromQty = false;
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
                    label: const Text('Clear Received'),
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
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Cleared received stock on ${row.dateDisplay}'),
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
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✓ Updated received stock for ${currentItem.name} (${row.dateDisplay})'),
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
                        const Text(
                          'Edit Issued Quantity',
                          style: TextStyle(fontSize: 16, fontWeight: AppFontWeights.bold),
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
                          suffixText: currentItem.baseUnit,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
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
                    label: const Text('Clear Issued'),
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
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Cleared issued stock on ${row.dateDisplay}'),
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
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✓ Updated issued stock for ${currentItem.name} (${row.dateDisplay})'),
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

  void _showAddStockDialog(BuildContext context, List<InventoryItemModel> allItems, [InventoryItemModel? preselected, DateTime? initialDate]) {
    String? selectedId = preselected?.id;
    final boxController = TextEditingController();
    final piecesController = TextEditingController();
    final notesController = TextEditingController();
    final customPersonController = TextEditingController();
    DateTime selectedDate = initialDate ?? DateTime.now();
    TimeOfDay? selectedCustomTime;
    bool isLiveTime = true;
    bool isSyncing = false;
    String selectedLoggedBy = ProductionState.authorizedPersonsList.first;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedItem = selectedId != null
                ? allItems.firstWhere(
                    (i) => i.id == selectedId,
                    orElse: () => allItems.first,
                  )
                : null;

            void onBoxChanged(String val) {
              if (isSyncing || selectedItem == null) return;
              isSyncing = true;
              final boxes = double.tryParse(val) ?? 0.0;
              if (boxes > 0 && selectedItem.itemsPerPackage > 0) {
                final pcs = boxes * selectedItem.itemsPerPackage;
                piecesController.text = Formatters.formatSmart(pcs);
              } else if (val.isEmpty) {
                piecesController.clear();
              }
              isSyncing = false;
              setDialogState(() {});
            }

            void onPiecesChanged(String val) {
              if (isSyncing || selectedItem == null) return;
              isSyncing = true;
              final pcs = double.tryParse(val) ?? 0.0;
              if (pcs > 0 && selectedItem.itemsPerPackage > 0) {
                final boxes = pcs / selectedItem.itemsPerPackage;
                boxController.text = Formatters.formatSmart(boxes);
              } else if (val.isEmpty) {
                boxController.clear();
              }
              isSyncing = false;
              setDialogState(() {});
            }

            final dateStr = DateFormat('dd MMM yyyy').format(selectedDate);
            final timeStr = isLiveTime
                ? DateFormat('hh:mm a').format(DateTime.now())
                : (selectedCustomTime ?? TimeOfDay.now()).format(context);

            final packagingUnit = selectedItem?.packagingUnit ?? 'Boxes / Bags';
            final baseUnit = selectedItem?.baseUnit ?? 'Units';

            final existingEntriesOnDate = selectedItem != null
                ? ref.read(inventoryStockProvider).inwardLedger.where((e) {
                    if (e.itemId != selectedItem.id) return false;
                    return StockLedgerCalculator.isSameDay(selectedDate, e.date);
                  }).toList()
                : <InwardStockEntry>[];
            final double existingDateQty = existingEntriesOnDate.fold<double>(0.0, (sum, e) => sum + e.quantity);
            final double existingDatePkgs = existingEntriesOnDate.fold<double>(0.0, (sum, e) => sum + e.packages);

            final pcsVal = double.tryParse(piecesController.text.replaceAll(',', '')) ?? 0.0;
            final boxVal = double.tryParse(boxController.text.replaceAll(',', '')) ?? 0.0;
            final currentEnteredQty = pcsVal > 0
                ? pcsVal
                : (selectedItem != null && selectedItem.itemsPerPackage > 0 ? boxVal * selectedItem.itemsPerPackage : boxVal);
            final currentEnteredPkgs = boxVal > 0
                ? boxVal
                : (selectedItem != null && selectedItem.itemsPerPackage > 0 ? currentEnteredQty / selectedItem.itemsPerPackage : 0.0);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Add New Stock',
                    style: TextStyle(
                      fontSize: AppTextSizes.subheading,
                      fontWeight: AppFontWeights.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 580,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Inventory Item Selector Dropdown Chip
                      const Text(
                        'Select Inventory Item *',
                        style: TextStyle(
                          fontSize: AppTextSizes.caption,
                          fontWeight: AppFontWeights.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedId != null
                                ? AppColors.primary.withValues(alpha: 0.35)
                                : AppColors.cardBorder,
                            width: 1.2,
                          ),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedId,
                            hint: Row(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 18, color: Colors.black.withValues(alpha: 0.50)),
                                const SizedBox(width: 10),
                                Text(
                                  'Select Inventory Item',
                                  style: TextStyle(
                                    fontWeight: AppFontWeights.medium,
                                    fontSize: AppTextSizes.body,
                                    color: Colors.black.withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            items: allItems.map((item) {
                              return DropdownMenuItem<String>(
                                value: item.id,
                                child: Row(
                                  children: [
                                    Icon(item.icon, size: 18, color: Colors.black.withValues(alpha: 0.65)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${item.name} (${item.category})',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: AppFontWeights.medium,
                                          fontSize: AppTextSizes.body,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (newVal) {
                              if (newVal != null) {
                                setDialogState(() {
                                  selectedId = newVal;
                                  boxController.clear();
                                  piecesController.clear();
                                });
                              }
                            },
                          ),
                        ),
                      ),

                      // Selected Item Chip Card preview (only when item selected)
                      if (selectedItem != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.22),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  selectedItem.icon,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          selectedItem.name,
                                          style: const TextStyle(
                                            fontWeight: AppFontWeights.bold,
                                            fontSize: AppTextSizes.body,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            selectedItem.category,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: AppFontWeights.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${selectedItem.details} • Current: ${Formatters.formatSmart(selectedItem.remainingQty)} ${selectedItem.baseUnit}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: AppFontWeights.medium,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // 2. Quantity Inputs
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quantity ($packagingUnit)',
                                  style: const TextStyle(
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: AppFontWeights.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: boxController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: onBoxChanged,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 5',
                                    suffixText: packagingUnit,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total ($baseUnit)',
                                  style: const TextStyle(
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: AppFontWeights.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: piecesController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: onPiecesChanged,
                                  decoration: InputDecoration(
                                    hintText: selectedItem != null
                                        ? 'e.g. ${Formatters.formatSmart(selectedItem.itemsPerPackage * 5)}'
                                        : 'e.g. 500',
                                    suffixText: baseUnit,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Live info chips for existing receipts and current addition
                      if (existingDateQty > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF2563EB)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Existing stock received on $dateStr: ${Formatters.formatSmart(existingDateQty)} $baseUnit (${Formatters.formatSmart(existingDatePkgs)} $packagingUnit). New additions will sum with this.',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: AppFontWeights.medium,
                                    color: Color(0xFF1E40AF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (currentEnteredQty > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline_rounded, size: 15, color: Color(0xFF16A34A)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  existingDateQty > 0
                                      ? 'Adding: +${Formatters.formatSmart(currentEnteredQty)} $baseUnit • New total on $dateStr: ${Formatters.formatSmart(existingDateQty + currentEnteredQty)} $baseUnit'
                                      : 'Adding: +${Formatters.formatSmart(currentEnteredQty)} $baseUnit (${Formatters.formatSmart(currentEnteredPkgs)} $packagingUnit)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: AppFontWeights.bold,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Date, Time & Logged By (3 chips in one row)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Date Chip
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: AppFontWeights.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) {
                                      setDialogState(() => selectedDate = picked);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.textSecondary),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            dateStr,
                                            style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.medium),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 2. Time Chip
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Time',
                                  style: TextStyle(
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: AppFontWeights.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                LiveTimeChip(
                                  selectedTime: selectedCustomTime,
                                  isLiveTime: isLiveTime,
                                  isMobile: true,
                                  onTimeChanged: (newTime) {
                                    setDialogState(() {
                                      selectedCustomTime = newTime;
                                      isLiveTime = false;
                                    });
                                  },
                                  onResetToLive: () {
                                    setDialogState(() {
                                      selectedCustomTime = null;
                                      isLiveTime = true;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 3. Logged By Chip
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Logged By',
                                  style: TextStyle(
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: AppFontWeights.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: ProductionState.authorizedPersonsList.contains(selectedLoggedBy)
                                          ? selectedLoggedBy
                                          : ProductionState.authorizedPersonsList.first,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary, size: 20),
                                      items: ProductionState.authorizedPersonsList.map((person) {
                                        return DropdownMenuItem(
                                          value: person,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.person_outline_rounded, size: 15, color: AppColors.textSecondary),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  person,
                                                  style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.medium),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      selectedItemBuilder: (context) {
                                        return ProductionState.authorizedPersonsList.map((person) {
                                          return Row(
                                            children: [
                                              const Icon(Icons.person_outline_rounded, size: 15, color: AppColors.textSecondary),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  person,
                                                  style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.medium),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList();
                                      },
                                      onChanged: (val) {
                                        if (val != null) {
                                          setDialogState(() => selectedLoggedBy = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Manual Name Input when 'Other' selected
                      if (selectedLoggedBy == 'Other (Type manually)') ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: customPersonController,
                          decoration: InputDecoration(
                            labelText: 'Enter Name',
                            hintText: 'Type employee name...',
                            prefixIcon: const Icon(Icons.badge_outlined, size: 16),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Optional Notes
                      const Text(
                        'Notes (Optional)',
                        style: TextStyle(
                          fontSize: AppTextSizes.caption,
                          fontWeight: AppFontWeights.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          hintText: 'e.g. GRN-1042 / Supplier name',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (selectedItem == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select an inventory item first.'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                      return;
                    }

                    final pcs = double.tryParse(piecesController.text.replaceAll(',', '')) ?? 0.0;
                    final boxes = double.tryParse(boxController.text.replaceAll(',', '')) ?? 0.0;

                    if (pcs <= 0 && boxes <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid stock quantity in boxes or loose units.'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                      return;
                    }

                    final finalQty = pcs > 0 ? pcs : (boxes * selectedItem.itemsPerPackage);
                    final finalPackages = boxes > 0
                        ? boxes
                        : (selectedItem.itemsPerPackage > 0 ? finalQty / selectedItem.itemsPerPackage : 0.0);

                    final effectiveLoggedBy = selectedLoggedBy == 'Other (Type manually)'
                        ? (customPersonController.text.trim().isNotEmpty
                            ? customPersonController.text.trim()
                            : 'Authorized Person')
                        : selectedLoggedBy;

                    Navigator.pop(dialogCtx);

                    await ref.read(inventoryStockProvider.notifier).addInwardStock(
                      itemId: selectedItem.id,
                      quantity: finalQty,
                      packages: finalPackages,
                      date: dateStr,
                      time: timeStr,
                      loggedBy: effectiveLoggedBy,
                      notes: notesController.text.trim(),
                    );

                    if (!context.mounted) return;

                    final newTotal = existingDateQty + finalQty;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          existingDateQty > 0
                              ? '✓ Added +${Formatters.formatSmart(finalQty)} ${selectedItem.baseUnit} to ${selectedItem.name} (Day Total: ${Formatters.formatSmart(newTotal)} ${selectedItem.baseUnit})'
                              : '✓ Added ${Formatters.formatSmart(finalQty)} ${selectedItem.baseUnit} to ${selectedItem.name}',
                          style: const TextStyle(fontWeight: AppFontWeights.bold),
                        ),
                        backgroundColor: const Color(0xFF16A34A),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  },
                  child: const Text('Add Stock'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _InventoryChipCard extends StatefulWidget {
  final InventoryItemModel item;
  final VoidCallback? onAddStock;
  final VoidCallback? onSelect;

  const _InventoryChipCard({required this.item, this.onAddStock, this.onSelect});

  @override
  State<_InventoryChipCard> createState() => _InventoryChipCardState();
}

class _InventoryChipCardState extends State<_InventoryChipCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isCritical = item.status == 'Critical' || item.status == 'Out of Stock Alert';
    final isLow = item.status == 'Low' || item.status == 'Low Stock Alert';

    // Respective colors: Green for Adequate, Yellow for Low, Red for Critical
    final Color statusColor = isCritical
        ? const Color(0xFFDC2626) // Red
        : (isLow ? const Color(0xFFD97706) : const Color(0xFF16A34A)); // Yellow / Green
    final String statusLabel = isCritical
        ? 'Critical'
        : (isLow ? 'Low' : 'Adequate');

    final person = (item.lastUpdatedBy != null && item.lastUpdatedBy!.trim().isNotEmpty)
        ? item.lastUpdatedBy!.trim()
        : 'Biraj Goswami';
    final displayLastUpdated = item.lastUpdated.contains('• by')
        ? item.lastUpdated
        : '${item.lastUpdated} • by $person';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onSelect ?? widget.onAddStock,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.08),
              width: _isHovered ? 1.2 : 1.0,
            ),
            boxShadow: _isHovered
                ? const [
                    BoxShadow(
                      color: Color(0x0A0F172A),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    color: Colors.black.withValues(alpha: 0.65),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: AppFontWeights.bold,
                          fontSize: AppTextSizes.body,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Category: ${item.category}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppTextSizes.caption,
                          fontWeight: AppFontWeights.medium,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: AppTextSizes.caption,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Above: pieces count in respective color
                    Text(
                      '${Formatters.formatSmart(item.remainingQty)} ${item.baseUnit}',
                      style: TextStyle(
                        fontWeight: AppFontWeights.bold,
                        fontSize: AppTextSizes.body,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Below: box counts in respective color
                    Text(
                      '${Formatters.formatSmart(item.remainingPackages)} ${item.packagingUnit}',
                      style: TextStyle(
                        fontSize: AppTextSizes.caption,
                        fontWeight: AppFontWeights.semiBold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Below: 3 threshold limits (Adequate: green, Low: yellow, Critical: red)
                    Tooltip(
                      message: item.limitDescription != null
                          ? 'Threshold Limits:\n${item.limitDescription}'
                          : 'Stock Status: $statusLabel',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: AppTextSizes.caption,
                              color: statusColor,
                              fontWeight: AppFontWeights.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.adequateLimit != null && item.criticalLimit != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        isCritical
                            ? '< ${Formatters.formatSmart(item.criticalLimit!)}'
                            : (isLow
                                ? '${Formatters.formatSmart(item.criticalLimit!)}–${Formatters.formatSmart(item.adequateLimit!)}'
                                : '> ${Formatters.formatSmart(item.adequateLimit!)}'),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: AppFontWeights.medium,
                          color: statusColor.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Bottom Footer: Last updated date with time & added stock badge
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.black.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: Colors.black.withValues(alpha: 0.40),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Last updated: $displayLastUpdated',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: AppFontWeights.medium,
                              color: Colors.black.withValues(alpha: 0.50),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (item.hasAddedStock) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+${Formatters.formatSmart(item.addedQty)} ${item.baseUnit}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: AppFontWeights.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (widget.onAddStock != null)
                    InkWell(
                      onTap: widget.onAddStock,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_circle_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 5),
                            Text(
                              '+ Add Stock',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: AppFontWeights.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

class _StockCategoryFilterChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _StockCategoryFilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StockCategoryFilterChip> createState() => _StockCategoryFilterChipState();
}

class _StockCategoryFilterChipState extends State<_StockCategoryFilterChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppColors.primary
              : (_isHovered ? const Color(0xFFF1F5F9) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isSelected
                ? AppColors.primary
                : (_isHovered
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.cardBorder),
            width: 1.2,
          ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : (_isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 15,
                    color: widget.isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: AppTextSizes.caption,
                      fontWeight: widget.isSelected ? AppFontWeights.bold : AppFontWeights.medium,
                      color: widget.isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
