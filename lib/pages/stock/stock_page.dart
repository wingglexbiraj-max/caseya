import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../models/inventory_item_model.dart';
import '../../models/stock_ledger_entry_model.dart';
import '../../providers/inventory_stock_provider.dart';
import '../../providers/production_provider.dart';

class StockPage extends ConsumerStatefulWidget {
  const StockPage({super.key});

  @override
  ConsumerState<StockPage> createState() => _StockPageState();
}

class _StockPageState extends ConsumerState<StockPage> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedItemId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    final isMobile = ResponsiveLayout.isMobile(context);
    final stockState = ref.watch(inventoryStockProvider);
    final filtered = stockState.filteredItems;
    final counts = stockState.categoryCounts;

    final categories = ['All', 'Cups', 'Poly Roll', 'Aluminium Foil', 'Serving Material', 'Ingredients'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 28,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Inventory Table Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with "+ Add New Stock" Chip
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
                        children: const [
                          Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 10),
                          Text(
                            'No inventory items match your search.',
                            style: TextStyle(fontWeight: AppFontWeights.bold, color: AppColors.textSecondary),
                          ),
                          SizedBox(height: 4),
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
                            final isSelected = _selectedItemId == item.id;
                            return SizedBox(
                              width: itemWidth,
                              child: _InventoryChipCard(
                                item: item,
                                isSelected: isSelected,
                                onSelect: () {
                                  setState(() => _selectedItemId = item.id);
                                  _showAddStockDialog(context, stockState.allItems, item);
                                },
                                onAddStock: () {
                                  setState(() => _selectedItemId = item.id);
                                  _showAddStockDialog(context, stockState.allItems, item);
                                },
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
                      // 1. Inventory Item Selector Dropdown
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

                      // Selected Item preview
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedItem.name,
                                      style: const TextStyle(
                                        fontWeight: AppFontWeights.bold,
                                        fontSize: AppTextSizes.body,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Current Stock: ${Formatters.formatSmart(selectedItem.remainingQty)} ${selectedItem.baseUnit} • 1 $packagingUnit = ${Formatters.formatSmart(selectedItem.itemsPerPackage)} $baseUnit',
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
                        ),
                      ],
                      const SizedBox(height: 14),

                      // 2. Quantity Input (Boxes vs Units)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  packagingUnit,
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

                      // Date, Time & Logged By
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(dateStr, style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.medium)),
                                        const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.textSecondary),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                InkWell(
                                  onTap: () async {
                                    final pickedTime = await showTimePicker(
                                      context: context,
                                      initialTime: selectedCustomTime ?? TimeOfDay.now(),
                                    );
                                    if (pickedTime != null) {
                                      setDialogState(() {
                                        selectedCustomTime = pickedTime;
                                        isLiveTime = false;
                                      });
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(timeStr, style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.medium)),
                                        const Icon(Icons.access_time_rounded, size: 15, color: AppColors.textSecondary),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Received By',
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

                    final isoDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
                    await ref.read(inventoryStockProvider.notifier).addInwardStock(
                      itemId: selectedItem.id,
                      quantity: finalQty,
                      packages: finalPackages,
                      date: isoDateStr,
                      time: timeStr,
                      loggedBy: effectiveLoggedBy,
                      notes: notesController.text.trim(),
                    );

                    if (mounted) setState(() {});
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✓ Successfully added ${Formatters.formatSmart(finalQty)} ${selectedItem.baseUnit} to ${selectedItem.name} on $dateStr'),
                        backgroundColor: const Color(0xFF16A34A),
                        behavior: SnackBarBehavior.floating,
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
  final bool isSelected;
  final VoidCallback? onAddStock;
  final VoidCallback? onSelect;

  const _InventoryChipCard({
    required this.item,
    this.isSelected = false,
    this.onAddStock,
    this.onSelect,
  });

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

    final Color statusColor = isCritical
        ? const Color(0xFFDC2626)
        : (isLow ? const Color(0xFFD97706) : const Color(0xFF16A34A));
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
            color: widget.isSelected
                ? AppColors.primary.withValues(alpha: 0.04)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primary
                  : (_isHovered
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.08)),
              width: widget.isSelected ? 1.6 : (_isHovered ? 1.2 : 1.0),
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
                          style: const TextStyle(
                            fontSize: AppTextSizes.caption,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: AppFontWeights.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Remaining Balance',
                        style: TextStyle(
                          fontSize: AppTextSizes.caption,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${Formatters.formatSmart(item.remainingQty)} ${item.baseUnit}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: AppFontWeights.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (item.itemsPerPackage > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.packagingUnit,
                          style: const TextStyle(
                            fontSize: AppTextSizes.caption,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatSmart(item.remainingQty / item.itemsPerPackage),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: AppFontWeights.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const Divider(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Last added: $displayLastUpdated',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
