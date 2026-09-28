import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/batch_record_model.dart';
import '../../providers/batch_records_provider.dart';
import '../../services/batch_recipe_service.dart';
import 'add_batch_dialog.dart';

class BatchRecordsPage extends ConsumerStatefulWidget {
  const BatchRecordsPage({super.key});

  @override
  ConsumerState<BatchRecordsPage> createState() => _BatchRecordsPageState();
}

class _BatchRecordsPageState extends ConsumerState<BatchRecordsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddBatchDialog({BatchRecordModel? existingBatch}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddBatchDialog(existingBatch: existingBatch),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingBatch != null
                ? '✓ Batch ${existingBatch.batchNumber} updated successfully'
                : '✓ New production batch recorded successfully',
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmDeleteBatch(BatchRecordModel batch) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            const SizedBox(width: 8),
            const Text('Delete Batch Record?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete batch "${batch.batchNumber}" for ${batch.productName} (${Formatters.formatSmart(batch.batchQuantity)} ${batch.batchUnit}) on ${batch.productionDate}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(batchRecordsProvider.notifier).deleteBatch(batch.id);
            },
            child: const Text('Delete Batch'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSingleDate() async {
    final state = ref.read(batchRecordsProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      ref.read(batchRecordsProvider.notifier).setDateFilter(picked);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      ref.read(batchRecordsProvider.notifier).setDateRangeFilter(picked);
    }
  }

  String _formatDateHeading(String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final comp = DateTime(parsed.year, parsed.month, parsed.day);

    String prefix = '';
    if (comp == today) {
      prefix = 'Today — ';
    } else if (comp == today.subtract(const Duration(days: 1))) {
      prefix = 'Yesterday — ';
    }

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthName = months[parsed.month - 1];
    return '$prefix${parsed.day} $monthName ${parsed.year}';
  }

  IconData _getProductIcon(String product) {
    switch (product.toLowerCase()) {
      case 'lassi':
        return Icons.local_drink_rounded;
      case 'curd':
      case 'sweet curd':
        return Icons.takeout_dining_rounded;
      case 'milk pouch':
      case 'milk':
        return Icons.water_drop_rounded;
      case 'paneer':
        return Icons.layers_rounded;
      default:
        return Icons.blender_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(batchRecordsProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

    final grouped = state.groupedByDate;
    final dailySummaries = state.dailySummaries;
    final products = ['All', ...BatchRecipeService.getSupportedProducts()];

    // Global totals
    int totalBatches = state.batches.length;
    double totalProduction = state.batches.fold(0.0, (acc, b) => acc + b.batchQuantity);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 28,
          vertical: 22,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Title & Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Daily Batch Making Records',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Record, track, and aggregate recipe formulations and raw material consumption date-wise.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add Batch Record'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 14 : 20,
                      vertical: isMobile ? 12 : 14,
                    ),
                  ),
                  onPressed: () => _openAddBatchDialog(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Top KPI Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildKpiTile(
                    'Total Batches Logged',
                    '$totalBatches Batches',
                    'Across all production dates',
                    Icons.blender_rounded,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiTile(
                    'Total Production Volume',
                    '${Formatters.formatSmart(totalProduction)} L',
                    'Cumulative dairy yield',
                    Icons.water_drop_rounded,
                    AppColors.accentCyanDeep,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiTile(
                      'Production Dates',
                      '${grouped.length} Days',
                      'Active manufacturing records',
                      Icons.calendar_month_rounded,
                      AppColors.goldAccent,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Control Bar: Search & Filter Toolbar
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Search and Date Filter buttons
                  Row(
                    children: [
                      // Search field
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            ref.read(batchRecordsProvider.notifier).setSearchQuery(val);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search batch #, product, or ingredient (e.g. Lassi, SMP, Sugar)...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref.read(batchRecordsProvider.notifier).setSearchQuery('');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Pick Specific Date
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(
                          state.selectedDate != null
                              ? Formatters.formatIsoDate(state.selectedDate!)
                              : 'Select Date',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: state.selectedDate != null ? AppColors.primary : AppColors.textPrimary,
                          side: BorderSide(
                            color: state.selectedDate != null ? AppColors.primary : AppColors.cardBorder,
                            width: state.selectedDate != null ? 1.6 : 1.0,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        onPressed: _pickSingleDate,
                      ),
                      const SizedBox(width: 8),

                      // Pick Date Range
                      OutlinedButton.icon(
                        icon: const Icon(Icons.date_range_rounded, size: 16),
                        label: Text(
                          state.dateRange != null
                              ? '${Formatters.formatIsoDate(state.dateRange!.start)} - ${Formatters.formatIsoDate(state.dateRange!.end)}'
                              : 'Date Range',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: state.dateRange != null ? AppColors.primary : AppColors.textPrimary,
                          side: BorderSide(
                            color: state.dateRange != null ? AppColors.primary : AppColors.cardBorder,
                            width: state.dateRange != null ? 1.6 : 1.0,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        onPressed: _pickDateRange,
                      ),

                      // Clear filters button (if active)
                      if (state.selectedDate != null ||
                          state.dateRange != null ||
                          state.selectedProduct != 'All' ||
                          state.searchQuery.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Clear Filters',
                          icon: const Icon(Icons.filter_alt_off_rounded, color: AppColors.danger),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(batchRecordsProvider.notifier).clearFilters();
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Product Filter Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: products.map((prod) {
                      final isSelected = state.selectedProduct == prod;
                      return ChoiceChip(
                        avatar: Icon(
                          prod == 'All' ? Icons.apps_rounded : _getProductIcon(prod),
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        label: Text(prod),
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
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(batchRecordsProvider.notifier).setProductFilter(prod);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date-wise Grouped Records List
            if (grouped.isEmpty)
              _buildEmptyState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: grouped.length,
                itemBuilder: (context, index) {
                  final dateKey = grouped.keys.elementAt(index);
                  final batchesOnDate = grouped[dateKey]!;
                  final summary = dailySummaries[dateKey]!;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _buildDateGroupSection(dateKey, summary, batchesOnDate),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a complete Date Group with its Daily Summary card and child batch cards
  Widget _buildDateGroupSection(
    String dateStr,
    DailyBatchSummary summary,
    List<BatchRecordModel> batches,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Daily Summary Card
        AppCard(
          backgroundColor: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Header: Date title + Batches count badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.event_note_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDateHeading(dateStr),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Products Made: ${summary.productsProduced.join(', ')}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      StatusBadge.info('${summary.totalBatches} ${summary.totalBatches == 1 ? 'Batch' : 'Batches'}'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Total: ${Formatters.formatSmart(summary.totalQuantity)} L',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Aggregated Ingredient Consumption Summary
              Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 13,
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'DAILY INGREDIENT CONSUMPTION SUMMARY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Ingredient Summary Badges
              if (summary.ingredientTotals.isEmpty)
                const Text('No ingredients recorded.', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: summary.ingredientTotals.entries.expand((entry) {
                    final ingName = entry.key;
                    final unitMap = entry.value;

                    return unitMap.entries.map((unitEntry) {
                      final unit = unitEntry.key;
                      final qty = unitEntry.value;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getIngredientIcon(ingName), size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              '$ingName: ',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            Text(
                              '${Formatters.formatSmart(qty)} $unit',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                      );
                    });
                  }).toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // List of Individual Batches for this Date
        ...batches.map((batch) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildBatchCard(batch),
            )),
      ],
    );
  }

  /// Builds a single Batch record card with full ingredient breakdown table and actions
  Widget _buildBatchCard(BatchRecordModel batch) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Batch Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Product Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getProductIcon(batch.productName),
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Batch Number & Product
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            batch.batchNumber,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge.neutral(batch.productName, fontSize: 11),
                          if (batch.shift != null && batch.shift!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '•  ${batch.shift}',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                      if (batch.operatorName != null && batch.operatorName!.isNotEmpty)
                        Text(
                          'Operator: ${batch.operatorName}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),

                // Batch Quantity Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${Formatters.formatSmart(batch.batchQuantity)} ${batch.batchUnit}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(width: 10),

                // Actions: Edit and Delete
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                  tooltip: 'Edit Batch',
                  onPressed: () => _openAddBatchDialog(existingBatch: batch),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                  tooltip: 'Delete Batch',
                  onPressed: () => _confirmDeleteBatch(batch),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Ingredient Table
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ingredients Formulation Breakdown:',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(4),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(2),
                  },
                  children: [
                    // Header row
                    TableRow(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Text('Ingredient', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: AppColors.textSecondary)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Text('Quantity Used', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: AppColors.textSecondary)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Text('Unit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                    // Ingredient items
                    ...batch.ingredients.map(
                      (ing) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Row(
                              children: [
                                Icon(_getIngredientIcon(ing.ingredientName), size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    ing.ingredientName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Text(
                              Formatters.formatSmart(ing.quantity),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.textPrimary),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Text(
                              ing.unit,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (batch.notes != null && batch.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Notes: ${batch.notes}',
                      style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
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

  IconData _getIngredientIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('milk')) return Icons.water_drop_rounded;
    if (lower.contains('water')) return Icons.water_rounded;
    if (lower.contains('smp') || lower.contains('powder')) return Icons.grain_rounded;
    if (lower.contains('sugar')) return Icons.inventory_2_rounded;
    if (lower.contains('culture')) return Icons.science_rounded;
    return Icons.circle_outlined;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.blender_outlined, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 14),
            const Text(
              'No Batch Records Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'No manufacturing batches match the current filter or date selection.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Batch Record'),
              onPressed: () => _openAddBatchDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiTile(String title, String val, String subtitle, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
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
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                Text(
                  val,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
