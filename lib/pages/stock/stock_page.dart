import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/live_time_chip.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_stock_provider.dart';

class StockPage extends ConsumerStatefulWidget {
  const StockPage({super.key});

  @override
  ConsumerState<StockPage> createState() => _StockPageState();
}

class _StockPageState extends ConsumerState<StockPage> {

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

    // Compute KPI sums
    double totalIngredientsKg = 0.0;
    double totalSmpBags = 0.0;
    double totalSugarBags = 0.0;
    double totalFoilRemainingLids = 0.0;
    double totalFoilRemainingBoxes = 0.0;
    double totalCupsRemainingPcs = 0.0;

    for (final item in stockState.allItems) {
      if (item.category == 'Ingredients') {
        totalIngredientsKg += item.remainingQty;
        if (item.id == 'ingredient_smp') {
          totalSmpBags = item.remainingPackages;
        } else if (item.id == 'ingredient_sugar') {
          totalSugarBags = item.remainingPackages;
        }
      } else if (item.category == 'Aluminium Foil') {
        totalFoilRemainingLids += item.remainingQty;
        totalFoilRemainingBoxes += item.remainingPackages;
      } else if (item.category == 'Cups') {
        totalCupsRemainingPcs += item.remainingQty;
      }
    }

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
            // Top Live Quick KPIs
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Ingredients Buffer',
                    '${Formatters.formatSmart(totalIngredientsKg)} kg',
                    '${Formatters.formatSmart(totalSmpBags)} Bags SMP • ${Formatters.formatSmart(totalSugarBags)} Bags Sugar',
                    Icons.grain_rounded,
                    AppColors.goldAccent,
                    consumedSubtitle: stockState.totalSugarUsedKg > 0 || stockState.totalSmpUsedKg > 0
                        ? '−${Formatters.formatSmart(stockState.totalSugarUsedKg + stockState.totalSmpUsedKg)} kg batch used'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    'Cups Inventory',
                    '${Formatters.formatInt(totalCupsRemainingPcs)} pcs',
                    '7 Types (Lassi, Sweet & Plain Curd)',
                    Icons.takeout_dining_rounded,
                    AppColors.primary,
                    consumedSubtitle: stockState.totalCupsUsed > 0
                        ? '−${Formatters.formatInt(stockState.totalCupsUsed)} cups consumed'
                        : null,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      'Aluminium Foil Buffer',
                      '${Formatters.formatInt(totalFoilRemainingLids)} lids',
                      '${Formatters.formatSmart(totalFoilRemainingBoxes)} Boxes on Floor (Pink & Blue)',
                      Icons.circle_outlined,
                      AppColors.accentCyanDeep,
                      consumedSubtitle: stockState.totalFoilsUsed > 0
                          ? '−${Formatters.formatInt(stockState.totalFoilsUsed)} foils used'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      'Poly Roll Stock',
                      '89 Rolls',
                      'STD, SM+ & Curd Pouches',
                      Icons.album_rounded,
                      AppColors.primaryLight,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

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
                            color: Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.12),
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
                                  color: AppColors.textPrimary,
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

                      return InkWell(
                        onTap: () => ref.read(inventoryStockProvider.notifier).setSelectedCategory(cat),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.black.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.035),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.black.withValues(alpha: 0.22)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(cat),
                                size: 15,
                                color: isSelected ? Colors.black87 : Colors.black.withValues(alpha: 0.60),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                chipText,
                                style: TextStyle(
                                  fontSize: AppTextSizes.caption,
                                  fontWeight: isSelected ? AppFontWeights.bold : AppFontWeights.medium,
                                  color: isSelected ? Colors.black87 : Colors.black.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildMetricTile(
    String title,
    String val,
    String subtitle,
    IconData icon,
    Color color, {
    String? consumedSubtitle,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTextSizes.caption,
                    fontWeight: AppFontWeights.semiBold,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  val,
                  style: const TextStyle(
                    fontSize: AppTextSizes.subheading,
                    fontWeight: AppFontWeights.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
                if (consumedSubtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    consumedSubtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: AppFontWeights.bold,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStockDialog(BuildContext context, List<InventoryItemModel> allItems, [InventoryItemModel? preselected]) {
    String? selectedId = preselected?.id;
    final boxController = TextEditingController();
    final piecesController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay? selectedCustomTime;
    bool isLiveTime = true;
    bool isSyncing = false;

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
            }

            final dateStr = DateFormat('dd MMM yyyy').format(selectedDate);
            final timeStr = isLiveTime
                ? DateFormat('hh:mm a').format(DateTime.now())
                : (selectedCustomTime ?? TimeOfDay.now()).format(context);

            final packagingUnit = selectedItem?.packagingUnit ?? 'Boxes / Bags';
            final baseUnit = selectedItem?.baseUnit ?? 'Units';

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
                  width: 480,
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
                            color: Colors.black.withValues(alpha: selectedId != null ? 0.15 : 0.10),
                          ),
                          color: Colors.black.withValues(alpha: 0.04),
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
                            color: Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.09),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  selectedItem.icon,
                                  size: 18,
                                  color: Colors.black.withValues(alpha: 0.70),
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
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            selectedItem.category,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: AppFontWeights.bold,
                                              color: Colors.black.withValues(alpha: 0.60),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${selectedItem.details} • Current: ${Formatters.formatSmart(selectedItem.remainingQty)} ${selectedItem.baseUnit}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: AppFontWeights.medium,
                                        color: Colors.black.withValues(alpha: 0.60),
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
                      const SizedBox(height: 14),

                      // Date & Time
                      Row(
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                                        const SizedBox(width: 8),
                                        Text(dateStr, style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.medium)),
                                      ],
                                    ),
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
                        ],
                      ),
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
                  onPressed: () {
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

                    ref.read(inventoryStockProvider.notifier).addInwardStock(
                      itemId: selectedItem.id,
                      quantity: finalQty,
                      packages: finalPackages,
                      date: dateStr,
                      time: timeStr,
                      notes: notesController.text.trim(),
                    );

                    Navigator.pop(dialogCtx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✓ Added ${Formatters.formatSmart(finalQty)} ${selectedItem.baseUnit} to ${selectedItem.name}',
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

  const _InventoryChipCard({required this.item, this.onAddStock});

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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onAddStock,
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
                            'Last updated: ${item.lastUpdated}',
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
