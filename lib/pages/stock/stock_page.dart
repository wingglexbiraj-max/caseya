import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_stock_provider.dart';

class StockPage extends ConsumerStatefulWidget {
  const StockPage({super.key});

  @override
  ConsumerState<StockPage> createState() => _StockPageState();
}

class _StockPageState extends ConsumerState<StockPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLedgerExpanded = true;

  @override
  void dispose() {
    _searchController.dispose();
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
            const SizedBox(height: 18),

            // Live Connection Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sync_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textPrimary),
                        children: [
                          const TextSpan(
                            text: 'Live Linked to Production & Standardization Registers: ',
                            style: TextStyle(fontWeight: AppFontWeights.bold, color: AppColors.primaryDark),
                          ),
                          TextSpan(
                            text: stockState.deductionLedger.isEmpty
                                ? 'Whenever you record production entries (e.g. 20 cups of Lassi or curd cups) or milk batches, cups, foils, wooden spoons, sugar, and SMP are automatically deducted in real time.'
                                : 'Active deductions: ${stockState.totalCupsUsed} cups, ${stockState.totalFoilsUsed} foils, ${stockState.totalSpoonsUsed} wooden spoons, ${Formatters.formatSmart(stockState.totalSugarUsedKg)} kg sugar, ${Formatters.formatSmart(stockState.totalSmpUsedKg)} kg SMP deducted.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (stockState.deductionLedger.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isLedgerExpanded = !_isLedgerExpanded;
                        });
                      },
                      icon: Icon(
                        _isLedgerExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        _isLedgerExpanded ? 'Hide Ledger' : 'View Ledger (${stockState.deductionLedger.length})',
                        style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.bold, color: AppColors.primary),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Expandable Production & Batch Deduction Ledger Card
            if (stockState.deductionLedger.isNotEmpty && _isLedgerExpanded) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                            const Text(
                              'Live Production & Batch Consumption Ledger',
                              style: TextStyle(
                                fontSize: AppTextSizes.body,
                                fontWeight: AppFontWeights.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${stockState.deductionLedger.length} Records',
                                style: const TextStyle(
                                  fontSize: AppTextSizes.caption,
                                  fontWeight: AppFontWeights.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Cross-verified against Production & Batch Registers',
                          style: TextStyle(
                            fontSize: AppTextSizes.caption,
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stockState.deductionLedger.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 40),
                      itemBuilder: (context, index) {
                        final entry = stockState.deductionLedger[index];
                        final isFoil = entry.unit == 'lids';
                        final isIngredient = entry.unit == 'kg';
                        final isSpoon = entry.inventoryItemId == 'serving_wooden_spoon';

                        final badgeColor = entry.source == 'Production Register'
                            ? AppColors.primary
                            : (entry.source == 'Milk Standardization' ? AppColors.accentCyanDeep : AppColors.goldAccent);

                        final itemColor = isIngredient
                            ? AppColors.goldAccent
                            : (isSpoon
                                ? AppColors.warning
                                : (isFoil ? AppColors.accentCyanDeep : AppColors.primary));

                        final itemIcon = isIngredient
                            ? Icons.grain_rounded
                            : (isSpoon
                                ? Icons.flatware_rounded
                                : (isFoil ? Icons.circle_outlined : Icons.takeout_dining_rounded));

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: itemColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  itemIcon,
                                  color: itemColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          entry.inventoryItemName,
                                          style: const TextStyle(
                                            fontWeight: AppFontWeights.bold,
                                            fontSize: AppTextSizes.body,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: badgeColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            entry.source,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: AppFontWeights.bold,
                                              color: badgeColor,
                                            ),
                                          ),
                                        ),
                                        if (entry.isCrossVerified)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.success.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              '✓ Cross-Verified',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: AppFontWeights.bold,
                                                color: AppColors.success,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${entry.date} ${entry.time} • Batch: ${entry.batchNo} • Product: ${entry.productName} • ${entry.notes}',
                                      style: const TextStyle(
                                        fontSize: AppTextSizes.caption,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '−${Formatters.formatSmart(entry.quantityDeducted)} ${entry.unit}',
                                  style: const TextStyle(
                                    fontWeight: AppFontWeights.bold,
                                    fontSize: AppTextSizes.caption,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Main Inventory Table Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search input
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => ref.read(inventoryStockProvider.notifier).setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Search items (e.g. STD 500ml, Sugar, S80, Foil)...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(inventoryStockProvider.notifier).clearSearch();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
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

                      return ChoiceChip(
                        avatar: Icon(
                          _getCategoryIcon(cat),
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        label: Text(chipText),
                        selected: isSelected,
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.background,
                        elevation: isSelected ? 1 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.cardBorder,
                            width: isSelected ? 1.6 : 1.0,
                          ),
                        ),
                        labelStyle: TextStyle(
                          fontSize: AppTextSizes.caption,
                          fontWeight: isSelected ? AppFontWeights.bold : AppFontWeights.medium,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(inventoryStockProvider.notifier).setSelectedCategory(cat);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Text(
                        '${filtered.length} ITEMS LOGGED',
                        style: const TextStyle(
                          fontSize: AppTextSizes.caption,
                          fontWeight: AppFontWeights.bold,
                          letterSpacing: 1.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (stockState.totalCupsUsed > 0 || stockState.totalSugarUsedKg > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.warningLight,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'Live Deductions Active',
                                style: TextStyle(
                                  fontSize: AppTextSizes.caption,
                                  fontWeight: AppFontWeights.bold,
                                  color: AppColors.goldDark,
                                ),
                              ),
                            ),
                          StatusBadge.success('Physical Floor Count Verified'),
                        ],
                      ),
                    ],
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
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _buildItemChipCard(filtered[index]),
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

  Color _getItemCardBgColor(String category) {
    return Colors.black.withValues(alpha: 0.035); // Low opacity black background
  }

  Color _getItemBorderColor(String category) {
    switch (category) {
      case 'Cups':
        return const Color(0xFF1D4ED8).withValues(alpha: 0.22);
      case 'Aluminium Foil':
        return const Color(0xFF6D28D9).withValues(alpha: 0.22);
      case 'Poly Roll':
        return const Color(0xFF047857).withValues(alpha: 0.22);
      case 'Ingredients':
        return const Color(0xFFB45309).withValues(alpha: 0.22);
      case 'Serving Material':
        return const Color(0xFFBE123C).withValues(alpha: 0.22);
      default:
        return Colors.black.withValues(alpha: 0.08);
    }
  }

  Color _getItemCategoryTextColor(String category) {
    switch (category) {
      case 'Cups':
        return const Color(0xFF1D4ED8); // Blue 700
      case 'Aluminium Foil':
        return const Color(0xFF6D28D9); // Violet 700
      case 'Poly Roll':
        return const Color(0xFF047857); // Emerald 700
      case 'Ingredients':
        return const Color(0xFFB45309); // Amber 700
      case 'Serving Material':
        return const Color(0xFFBE123C); // Rose 700
      default:
        return AppColors.primary;
    }
  }

  Widget _buildItemChipCard(InventoryItemModel item) {
    final isLow = item.status == 'Low Stock Alert';
    final isOutOfStock = item.status == 'Out of Stock Alert';

    final cardBgColor = _getItemCardBgColor(item.category);
    final borderColor = _getItemBorderColor(item.category);
    final categoryColor = _getItemCategoryTextColor(item.category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
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
                  style: const TextStyle(
                    fontWeight: AppFontWeights.bold,
                    fontSize: AppTextSizes.body,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Category: ${item.category}',
                  style: TextStyle(
                    fontSize: AppTextSizes.caption,
                    fontWeight: AppFontWeights.bold,
                    color: categoryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.details,
                  style: const TextStyle(
                    fontSize: AppTextSizes.caption,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${Formatters.formatSmart(item.remainingPackages)} ${item.packagingUnit}',
                style: const TextStyle(
                  fontWeight: AppFontWeights.bold,
                  fontSize: AppTextSizes.body,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${Formatters.formatSmart(item.remainingQty)} ${item.baseUnit}',
                style: const TextStyle(
                  fontSize: AppTextSizes.caption,
                  fontWeight: AppFontWeights.semiBold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              if (isOutOfStock)
                const Text(
                  'Out of Stock Alert',
                  style: TextStyle(
                    fontSize: AppTextSizes.caption,
                    color: AppColors.danger,
                    fontWeight: AppFontWeights.bold,
                  ),
                )
              else if (isLow)
                const Text(
                  'Low Buffer Alert',
                  style: TextStyle(
                    fontSize: AppTextSizes.caption,
                    color: AppColors.warning,
                    fontWeight: AppFontWeights.bold,
                  ),
                )
              else
                const Text(
                  'Adequate',
                  style: TextStyle(
                    fontSize: AppTextSizes.caption,
                    color: AppColors.success,
                    fontWeight: AppFontWeights.semiBold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
