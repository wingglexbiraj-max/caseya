import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/live_time_chip.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../models/batch_record_model.dart';
import '../../providers/batch_records_provider.dart';
import '../../providers/production_provider.dart';
import '../../providers/lab_provider.dart';
import '../../services/milk_standardization_calculator.dart';
import '../../core/widgets/metric_card.dart';
import '../../models/product_model.dart';
import '../../models/standardization_record.dart';
import '../../providers/standardization_provider.dart';
import 'add_batch_dialog.dart';

class BatchRecordsPage extends ConsumerStatefulWidget {
  const BatchRecordsPage({super.key});

  @override
  ConsumerState<BatchRecordsPage> createState() => _BatchRecordsPageState();
}

class _BatchRecordsPageState extends ConsumerState<BatchRecordsPage> {
  // Add Batch Entry Form Controllers
  final TextEditingController _milkController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();
  final TextEditingController _sugarController = TextEditingController();
  final TextEditingController _smpController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customPersonController = TextEditingController();

  // Accordion expanded state for batch cards
  final Set<String> _expandedBatchIds = {};

  // History section collapse state (collapsed by default)
  bool _historyExpanded = false;

  // Form State
  String? _selectedProduct;
  StandardizationRecord? _selectedStandardizationRecord;
  String _selectedLoggedBy = ProductionState.authorizedPersonsList.first;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _isLiveTime = true;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  static const List<String> authorizedPersonsList = ProductionState.authorizedPersonsList;

  String _determineCurrentShift() {
    return AppConstants.determineShift(DateTime.now());
  }

  @override
  void dispose() {
    _milkController.dispose();
    _fatController.dispose();
    _waterController.dispose();
    _sugarController.dispose();
    _smpController.dispose();
    _notesController.dispose();
    _customPersonController.dispose();
    super.dispose();
  }

  double get _currentTotalVolume {
    final m = Formatters.parseDouble(_milkController.text);
    final w = Formatters.parseDouble(_waterController.text);
    final s = Formatters.parseDouble(_sugarController.text);
    final smp = Formatters.parseDouble(_smpController.text);
    return m + w + s + smp;
  }

  void _onClearEntryForm() {
    _milkController.clear();
    _fatController.clear();
    _waterController.clear();
    _sugarController.clear();
    _smpController.clear();
    _notesController.clear();
    _customPersonController.clear();
    setState(() {
      _selectedProduct = null;
      _selectedStandardizationRecord = null;
      _selectedDate = DateTime.now();
      _selectedTime = null;
      _isLiveTime = true;
    });
  }

  String _generateBatchNumber(DateTime date, String productName, int existingCount) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final code = productName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final shortCode = code.length > 5 ? code.substring(0, 5) : code;
    final seq = (existingCount + 1).toString().padLeft(2, '0');
    return 'BT-$y$m$d-$shortCode-$seq';
  }

  void _onRecordBatchEntry() async {
    if (_selectedProduct == null || _selectedProduct!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a batch first.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final milk = Formatters.parseDouble(_milkController.text);
    final fat = Formatters.parseDouble(_fatController.text);
    final water = Formatters.parseDouble(_waterController.text);
    final sugar = Formatters.parseDouble(_sugarController.text);
    final smp = Formatters.parseDouble(_smpController.text);

    if (milk <= 0 && water <= 0 && sugar <= 0 && smp <= 0 && fat <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least milk, fat, water, sugar, or SMP quantity.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final effectivePerson = (_selectedLoggedBy == 'Other (Type manually)' &&
            _customPersonController.text.trim().isNotEmpty)
        ? _customPersonController.text.trim()
        : _selectedLoggedBy;

    final totalVolume = milk + water + sugar + smp;
    final now = DateTime.now();
    final dateIso = Formatters.formatIsoDate(_selectedDate);

    // DUPLICATE BATCH CHECK:
    // If a batch for the same product and date already exists, ask the user to confirm
    final existingBatches = ref.read(batchRecordsProvider).batches.where(
      (b) => b.productionDate == dateIso &&
             b.productName.trim().toLowerCase() == _selectedProduct!.trim().toLowerCase(),
    ).toList();

    if (existingBatches.isNotEmpty) {
      final existing = existingBatches.first;
      final isStd = existing.notes != null &&
          (existing.notes!.contains('Standardized') || existing.batchNumber.startsWith('STD-'));
      final sourceDesc = isStd ? ' (from Milk Standardization)' : '';

      final confirmDuplicate = await ConfirmationDialog.show(
        context: context,
        title: 'Batch Already Recorded for Today',
        message:
            'A batch for "$_selectedProduct" has already been recorded on $dateIso:\n'
            '• Batch #${existing.batchNumber} (${Formatters.formatSmart(existing.batchQuantity)} ${existing.batchUnit}$sourceDesc)\n\n'
            'Are you sure you want to add it again?',
        confirmLabel: 'Yes, Add Again',
        cancelLabel: 'Cancel',
      );

      if (!confirmDuplicate) {
        return;
      }
    }

    final effectiveShift = _isLiveTime
        ? AppConstants.determineShift(DateTime.now())
        : (_selectedTime != null
            ? AppConstants.determineShift(DateTime(now.year, now.month, now.day, _selectedTime!.hour, _selectedTime!.minute))
            : _determineCurrentShift());
    final batchNum = _generateBatchNumber(
      _selectedDate,
      _selectedProduct!,
      ref.read(batchRecordsProvider).batches.length,
    );

    final ingredients = <BatchIngredientModel>[
      if (milk > 0)
        BatchIngredientModel(
          id: 'ING-${now.millisecondsSinceEpoch}-1',
          batchId: batchNum,
          ingredientName: 'Milk Taken',
          quantity: milk,
          unit: 'L',
        ),
      if (fat > 0)
        BatchIngredientModel(
          id: 'ING-${now.millisecondsSinceEpoch}-fat',
          batchId: batchNum,
          ingredientName: 'Fat ($fat%)',
          quantity: fat,
          unit: '%',
        ),
      if (water > 0)
        BatchIngredientModel(
          id: 'ING-${now.millisecondsSinceEpoch}-2',
          batchId: batchNum,
          ingredientName: 'Water',
          quantity: water,
          unit: 'L',
        ),
      if (sugar > 0)
        BatchIngredientModel(
          id: 'ING-${now.millisecondsSinceEpoch}-3',
          batchId: batchNum,
          ingredientName: 'Sugar',
          quantity: sugar,
          unit: 'kg',
        ),
      if (smp > 0)
        BatchIngredientModel(
          id: 'ING-${now.millisecondsSinceEpoch}-4',
          batchId: batchNum,
          ingredientName: 'SMP',
          quantity: smp,
          unit: 'kg',
        ),
    ];

    final batch = BatchRecordModel(
      id: 'BR-${now.millisecondsSinceEpoch}',
      productionDate: dateIso,
      productId: _selectedProduct!,
      productName: _selectedProduct!,
      batchNumber: batchNum,
      batchQuantity: totalVolume,
      batchUnit: 'L',
      shift: effectiveShift,
      operatorName: effectivePerson,
      fatPercent: fat > 0 ? fat : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      ingredients: ingredients,
      createdAt: now,
      updatedAt: now,
    );

    final success = await ref.read(batchRecordsProvider.notifier).createBatch(batch);
    if (success && mounted) {
      ref.read(labProvider.notifier).refreshSiloStock();
      final List<String> deductedParts = [];
      if (smp > 0) deductedParts.add('${Formatters.formatSmart(smp)} kg SMP');
      if (sugar > 0) deductedParts.add('${Formatters.formatSmart(sugar)} kg Sugar');
      final stockDeductMsg = deductedParts.isNotEmpty
          ? ' • Deducted ${deductedParts.join(' & ')} from Inventory'
          : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Batch $batchNum for $_selectedProduct (${Formatters.formatSmart(totalVolume)} L) recorded successfully$stockDeductMsg.',
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 4),
        ),
      );
      _onClearEntryForm();
    }
  }

  void _openAddBatchDialog({BatchRecordModel? existingBatch}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddBatchDialog(existingBatch: existingBatch),
    );

    if (result == true && mounted) {
      ref.read(labProvider.notifier).refreshSiloStock();
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
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Delete Batch Record?'),
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

    final dStr =
        '${parsed.day.toString().padLeft(2, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.year}';
    return '$prefix$dStr';
  }



  @override
  Widget build(BuildContext context) {
    final state = ref.watch(batchRecordsProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

    final stdState = ref.watch(standardizationProvider);
    final targetProducts = stdState.targetProducts.isNotEmpty
        ? stdState.targetProducts
        : MilkStandardizationCalculator.standardizationProducts;

    final grouped = state.groupedByDate;
    final dailySummaries = state.dailySummaries;

    // Unified product options list for history search & filter dropdown
    final allProductNames = <String>{
      ...targetProducts.map((p) => p.productName),
      ...state.batches.map((b) => b.productName),
    }.toList();

    // Global totals
    final totalBatches = state.batches.length;
    final totalProduction = state.batches.fold(0.0, (acc, b) => acc + b.batchQuantity);

    final effectiveShift = _isLiveTime
        ? AppConstants.determineShift(DateTime.now())
        : (_selectedTime != null
            ? AppConstants.determineShift(DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedTime!.hour,
                _selectedTime!.minute,
              ))
            : _determineCurrentShift());

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
            // =================================================================
            // 1. TOTAL METRIC SUMMARY (All Dates Till Now - Lifetime Cumulative)
            // Exactly matches Dashboard Total Metric Summary design
            // =================================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'TOTAL METRIC SUMMARY',
                      style: TextStyle(
                        fontSize: AppTextSizes.subheading,
                        fontWeight: AppFontWeights.bold,
                        letterSpacing: 0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'All Dates Till Now',
                  style: TextStyle(
                    fontSize: AppTextSizes.caption,
                    fontWeight: AppFontWeights.medium,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 600
                    ? 1
                    : (constraints.maxWidth < 1000 ? 2 : 3);
                final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 16)) / crossAxisCount;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Total Batches Logged',
                        value: Formatters.formatSmart(totalBatches.toDouble()),
                        unit: totalBatches == 1 ? 'Batch' : 'Batches',
                        subtitle: 'Across all production dates',
                        icon: Icons.blender_rounded,
                        iconColor: Colors.black.withValues(alpha: 0.60),
                        iconBgColor: Colors.black.withValues(alpha: 0.06),
                        cardBgColor: const Color(0xFFEFF6FF),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Total Production Volume',
                        value: Formatters.formatSmart(totalProduction),
                        unit: 'Litres',
                        subtitle: 'Cumulative dairy yield',
                        icon: Icons.water_drop_rounded,
                        iconColor: Colors.black.withValues(alpha: 0.60),
                        iconBgColor: Colors.black.withValues(alpha: 0.06),
                        cardBgColor: const Color(0xFFECFDF5),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Production Dates',
                        value: '${grouped.length}',
                        unit: grouped.length == 1 ? 'Day' : 'Days',
                        subtitle: 'Active manufacturing records',
                        icon: Icons.calendar_month_rounded,
                        iconColor: Colors.black.withValues(alpha: 0.60),
                        iconBgColor: Colors.black.withValues(alpha: 0.06),
                        cardBgColor: const Color(0xFFFFFBEB),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // -------------------------------------------------------------
            // 2. ADD BATCH ENTRY SECTION
            // -------------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.blender_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ADD BATCH ENTRY',
                      style: TextStyle(
                        fontSize: AppTextSizes.subheading,
                        fontWeight: AppFontWeights.bold,
                        letterSpacing: 0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                StatusBadge.info(effectiveShift),
              ],
            ),
            const SizedBox(height: 12),
            _buildAddBatchEntryCard(targetProducts),
            const SizedBox(height: 32),

            // -------------------------------------------------------------
            // 3. DAILY BATCH RECORDS HISTORY (Collapsible, Collapsed by Default)
            // -------------------------------------------------------------
            InkWell(
              onTap: () {
                setState(() {
                  _historyExpanded = !_historyExpanded;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            size: 20,
                            color: Colors.black.withValues(alpha: 0.60),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'DAILY BATCH RECORDS HISTORY',
                          style: TextStyle(
                            fontSize: AppTextSizes.subheading,
                            fontWeight: AppFontWeights.bold,
                            letterSpacing: 0.6,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        StatusBadge.info(
                          '${state.filteredBatches.length} ${state.filteredBatches.length == 1 ? 'Batch' : 'Batches'}',
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.cardBorderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _historyExpanded ? 'Collapse' : 'Expand',
                                style: const TextStyle(
                                  fontSize: AppTextSizes.caption,
                                  fontWeight: AppFontWeights.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _historyExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (_historyExpanded) ...[
              const SizedBox(height: 12),
              _buildFilterToolbar(state, allProductNames),
              const SizedBox(height: 10),
              _buildTodaysConsumption(state.batches),
              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // 4. DATE-WISE GROUPED BATCHES LIST
              // -------------------------------------------------------------
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
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGET: ADD BATCH ENTRY SECTION
  // ---------------------------------------------------------------------------
  Widget _buildAddBatchEntryCard(List<ProductModel> targetProducts) {
    final isCustomPerson = _selectedLoggedBy == 'Other (Type manually)';
    final currentVolume = _currentTotalVolume;

    final stdState = ref.watch(standardizationProvider);
    final stdBatches = stdState.history;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 0: Date, Time & Logged By (3 Chips in One Line)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;

              final dateWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date', style: TextStyle(fontSize: AppTextSizes.body, fontWeight: AppFontWeights.bold)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: AppColors.cardBorder, width: 1.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Formatters.formatDate(_selectedDate),
                            style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: AppTextSizes.body),
                          ),
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              );

              final timeWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Time', style: TextStyle(fontSize: AppTextSizes.body, fontWeight: AppFontWeights.bold)),
                  const SizedBox(height: 6),
                  LiveTimeChip(
                    selectedTime: _selectedTime,
                    isLiveTime: _isLiveTime,
                    isMobile: !isWide,
                    onTimeChanged: (newTime) {
                      setState(() {
                        _selectedTime = newTime;
                        _isLiveTime = false;
                      });
                    },
                    onResetToLive: () {
                      setState(() {
                        _isLiveTime = true;
                        _selectedTime = null;
                      });
                    },
                  ),
                ],
              );

              final personWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Logged By',
                    style: TextStyle(fontSize: AppTextSizes.body, fontWeight: AppFontWeights.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.cardBorder, width: 1.2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: authorizedPersonsList.contains(_selectedLoggedBy)
                            ? _selectedLoggedBy
                            : authorizedPersonsList.first,
                        isExpanded: true,
                        items: authorizedPersonsList.map((person) {
                          return DropdownMenuItem(
                            value: person,
                            child: Text(
                              person,
                              style: const TextStyle(fontSize: AppTextSizes.body, fontWeight: AppFontWeights.semiBold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedLoggedBy = val);
                        },
                      ),
                    ),
                  ),
                ],
              );

              if (isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: dateWidget),
                        const SizedBox(width: 12),
                        Expanded(child: timeWidget),
                        const SizedBox(width: 12),
                        Expanded(child: personWidget),
                      ],
                    ),
                    if (isCustomPerson) ...[
                      const SizedBox(height: 10),
                      AppTextField(
                        label: 'Enter Name',
                        hint: 'Type employee name...',
                        controller: _customPersonController,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dateWidget,
                    const SizedBox(height: 12),
                    timeWidget,
                    const SizedBox(height: 12),
                    personWidget,
                    if (isCustomPerson) ...[
                      const SizedBox(height: 10),
                      AppTextField(
                        label: 'Enter Name',
                        hint: 'Type employee name...',
                        controller: _customPersonController,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // Row 1: Select Batch & Fetch from Milk Standardization (Side-by-Side)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;

              final batchDropdownWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.blender_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Select Batch',
                        style: TextStyle(
                          fontSize: AppTextSizes.body,
                          fontWeight: AppFontWeights.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_selectedProduct != null) ...[
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedProduct = null;
                              _selectedStandardizationRecord = null;
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.close_rounded, size: 14, color: AppColors.danger),
                                SizedBox(width: 4),
                                Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: AppFontWeights.bold,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: _selectedProduct != null
                            ? AppColors.primary
                            : AppColors.cardBorder,
                        width: 1.2,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: (targetProducts.any((p) => p.productName.trim().toLowerCase() == _selectedProduct?.trim().toLowerCase()))
                            ? targetProducts.firstWhere((p) => p.productName.trim().toLowerCase() == _selectedProduct?.trim().toLowerCase()).productName
                            : '',
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text(
                              'Select Batch',
                              style: TextStyle(
                                fontSize: AppTextSizes.body,
                                fontWeight: AppFontWeights.medium,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...targetProducts.map((p) {
                            final specs = 'Fat: ${Formatters.formatPercent(p.targetFat ?? 0)}% • SNF: ${Formatters.formatPercent(p.targetSnf ?? 0)}%${p.targetSugar != null && p.targetSugar! > 0 ? ' • Sugar: ${Formatters.formatPercent(p.targetSugar!)}%' : ''}';
                            return DropdownMenuItem<String>(
                              value: p.productName,
                              child: Text(
                                '${p.productName}  ($specs)',
                                style: const TextStyle(
                                  fontSize: AppTextSizes.body,
                                  fontWeight: AppFontWeights.semiBold,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedProduct = (val == null || val.isEmpty) ? null : val;
                            _selectedStandardizationRecord = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              );

              final fetchFromStdWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sync_alt_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Fetch from Milk Standardization',
                        style: TextStyle(
                          fontSize: AppTextSizes.body,
                          fontWeight: AppFontWeights.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_selectedStandardizationRecord != null) ...[
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedStandardizationRecord = null;
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.close_rounded, size: 14, color: AppColors.danger),
                                SizedBox(width: 4),
                                Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: AppFontWeights.bold,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: _selectedStandardizationRecord != null
                            ? AppColors.primary
                            : AppColors.cardBorder,
                        width: 1.2,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: (_selectedStandardizationRecord != null &&
                                stdBatches.any((b) => b.recordId == _selectedStandardizationRecord!.recordId))
                            ? _selectedStandardizationRecord!.recordId
                            : '',
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text(
                              '-- Select Standardization Batch (Optional) --',
                              style: TextStyle(
                                fontSize: AppTextSizes.body,
                                fontWeight: AppFontWeights.medium,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...stdBatches.map((b) {
                            final batchQty = b.finalQuantity > 0 ? b.finalQuantity : b.totalBatchRequired;
                            final timeAndDate = b.time.isNotEmpty ? '${b.time}, ${b.date}' : b.date;
                            final label = '${b.targetProductName} • ${Formatters.formatSmart(batchQty)} L • $timeAndDate';
                            return DropdownMenuItem<String>(
                              value: b.recordId,
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: AppTextSizes.body,
                                  fontWeight: AppFontWeights.semiBold,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          if (val == null || val.isEmpty) {
                            setState(() {
                              _selectedStandardizationRecord = null;
                            });
                          } else {
                            final b = stdBatches.firstWhere((item) => item.recordId == val);
                            setState(() {
                              _selectedStandardizationRecord = b;
                              _selectedProduct = b.targetProductName;
                              _milkController.text = Formatters.formatSmart(b.inputMilkQuantity);
                              _fatController.text = Formatters.formatSmart(b.targetFat > 0 ? b.targetFat : b.inputFat);
                              _waterController.text = Formatters.formatSmart(b.waterRequired);
                              _sugarController.text = Formatters.formatSmart(b.sugarRequired);
                              _smpController.text = Formatters.formatSmart(b.smpRequired);
                              if (b.notes.isNotEmpty) {
                                _notesController.text = 'From Std Record: ${b.notes}';
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: batchDropdownWidget),
                    const SizedBox(width: 14),
                    Expanded(child: fetchFromStdWidget),
                  ],
                );
              } else {
                return Column(
                  children: [
                    batchDropdownWidget,
                    const SizedBox(height: 14),
                    fetchFromStdWidget,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 18),

          // Row 2: Five Formulation Inputs: Milk Taken, Fat %, Water, Sugar, SMP
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 920;
              final isMedium = constraints.maxWidth >= 600 && !isWide;

              final milkField = AppTextField(
                label: 'Milk Taken (L)',
                hint: 'e.g. 1500',
                suffixText: 'Litres',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                controller: _milkController,
                onChanged: (_) => setState(() {}),
              );

              final fatField = AppTextField(
                label: 'Fat (%)',
                hint: 'e.g. 3.0',
                suffixText: '%',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                controller: _fatController,
                onChanged: (_) => setState(() {}),
              );

              final waterField = AppTextField(
                label: 'Water (L)',
                hint: 'e.g. 120',
                suffixText: 'Litres',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                controller: _waterController,
                onChanged: (_) => setState(() {}),
              );

              final sugarField = AppTextField(
                label: 'Sugar (kg)',
                hint: 'e.g. 180',
                suffixText: 'kg',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                controller: _sugarController,
                onChanged: (_) => setState(() {}),
              );

              final smpField = AppTextField(
                label: 'SMP (kg)',
                hint: 'e.g. 60',
                suffixText: 'kg',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                controller: _smpController,
                onChanged: (_) => setState(() {}),
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: milkField),
                    const SizedBox(width: 10),
                    Expanded(child: fatField),
                    const SizedBox(width: 10),
                    Expanded(child: waterField),
                    const SizedBox(width: 10),
                    Expanded(child: sugarField),
                    const SizedBox(width: 10),
                    Expanded(child: smpField),
                  ],
                );
              } else if (isMedium) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: milkField),
                        const SizedBox(width: 10),
                        Expanded(child: fatField),
                        const SizedBox(width: 10),
                        Expanded(child: waterField),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: sugarField),
                        const SizedBox(width: 10),
                        Expanded(child: smpField),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: milkField),
                        const SizedBox(width: 10),
                        Expanded(child: fatField),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: waterField),
                        const SizedBox(width: 10),
                        Expanded(child: sugarField),
                      ],
                    ),
                    const SizedBox(height: 10),
                    smpField,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // Calculation Metrics Section (Product Calculator / Boiler / DG style)
          _buildLiveBatchMetrics(currentVolume),
          const SizedBox(height: 16),

          // Batch Note
          AppTextField(
            label: 'Note',
            hint: 'e.g. Silo 02 milk used, culture added at 42°C',
            controller: _notesController,
          ),
          const SizedBox(height: 20),

          // Action Buttons (Record Batch Entry & Clear) - styled exactly like Boiler Page
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  icon: const Icon(Icons.save_outlined, size: 20),
                  label: const Text(
                    'Record Batch Entry',
                    style: TextStyle(
                      fontSize: AppTextSizes.body,
                      fontWeight: AppFontWeights.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  onPressed: _onRecordBatchEntry,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(
                      color: Color(0xFFFCA5A5),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  onPressed: _onClearEntryForm,
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: AppTextSizes.body,
                      fontWeight: AppFontWeights.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBatchMetrics(double totalVolume) {
    final m = Formatters.parseDouble(_milkController.text);
    final fat = Formatters.parseDouble(_fatController.text);
    final w = Formatters.parseDouble(_waterController.text);
    final s = Formatters.parseDouble(_sugarController.text);
    final smp = Formatters.parseDouble(_smpController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calculation Metrics Header inside card
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 16,
                color: Colors.black.withValues(alpha: 0.60),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'BATCH CALCULATION METRICS',
              style: TextStyle(
                fontSize: AppTextSizes.caption,
                fontWeight: AppFontWeights.bold,
                letterSpacing: 0.6,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardTotal = MetricCard(
              title: 'Total Batch Volume',
              value: totalVolume > 0 ? Formatters.formatSmart(totalVolume) : '0',
              unit: 'Litres',
              subtitle: totalVolume > 0 ? 'Cumulative dairy yield' : 'Enter ingredients above',
              icon: Icons.blender_rounded,
              iconColor: Colors.black.withValues(alpha: 0.60),
              iconBgColor: Colors.black.withValues(alpha: 0.06),
              cardBgColor: const Color(0xFFEFF6FF), // Soft Blue
            );

            final cardMilk = MetricCard(
              title: 'Milk Taken',
              value: m > 0 ? Formatters.formatSmart(m) : '0',
              unit: 'Litres',
              subtitle: 'Raw milk quantity',
              icon: Icons.water_drop_rounded,
              iconColor: Colors.black.withValues(alpha: 0.60),
              iconBgColor: Colors.black.withValues(alpha: 0.06),
              cardBgColor: const Color(0xFFECFDF5), // Soft Mint
            );

            final cardFat = MetricCard(
              title: 'Fat (%)',
              value: fat > 0 ? '${Formatters.formatSmart(fat)}%' : '0%',
              unit: '%',
              subtitle: fat > 0 ? 'Batch Fat content' : 'Enter Fat above',
              icon: Icons.opacity_rounded,
              iconColor: Colors.black.withValues(alpha: 0.60),
              iconBgColor: Colors.black.withValues(alpha: 0.06),
              cardBgColor: const Color(0xFFFDF4FF), // Soft Pink
            );

            final cardWater = MetricCard(
              title: 'Water Added',
              value: w > 0 ? Formatters.formatSmart(w) : '0',
              unit: 'Litres',
              subtitle: w > 0 ? 'Dilution liquid' : 'No water added',
              icon: Icons.water_rounded,
              iconColor: Colors.black.withValues(alpha: 0.60),
              iconBgColor: Colors.black.withValues(alpha: 0.06),
              cardBgColor: const Color(0xFFF5F3FF), // Soft Purple
            );

            final cardSugar = MetricCard(
              title: 'Sugar Added',
              value: s > 0 ? Formatters.formatSmart(s) : '0',
              unit: 'Kg',
              subtitle: s > 0 ? 'Sweetener' : 'No sugar added',
              icon: Icons.cookie_outlined,
              iconColor: Colors.black.withValues(alpha: 0.60),
              iconBgColor: Colors.black.withValues(alpha: 0.06),
              cardBgColor: const Color(0xFFFFFBEB), // Soft Amber
            );

            final cardSmp = MetricCard(
              title: 'SMP Added',
              value: smp > 0 ? Formatters.formatSmart(smp) : '0',
              unit: 'Kg',
              subtitle: smp > 0 ? 'Skimmed Milk Powder' : 'No SMP added',
              icon: Icons.grain_rounded,
              iconColor: Colors.black.withValues(alpha: 0.60),
              iconBgColor: Colors.black.withValues(alpha: 0.06),
              cardBgColor: const Color(0xFFFFF7ED), // Soft Peach/Orange
            );

            if (constraints.maxWidth >= 1050) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cardTotal),
                    const SizedBox(width: 10),
                    Expanded(child: cardMilk),
                    const SizedBox(width: 10),
                    Expanded(child: cardFat),
                    const SizedBox(width: 10),
                    Expanded(child: cardWater),
                    const SizedBox(width: 10),
                    Expanded(child: cardSugar),
                    const SizedBox(width: 10),
                    Expanded(child: cardSmp),
                  ],
                ),
              );
            } else {
              final crossAxisCount = constraints.maxWidth < 560
                  ? 1
                  : (constraints.maxWidth < 820 ? 2 : 3);
              final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 12)) / crossAxisCount;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(width: itemWidth, child: cardTotal),
                  SizedBox(width: itemWidth, child: cardMilk),
                  SizedBox(width: itemWidth, child: cardFat),
                  SizedBox(width: itemWidth, child: cardWater),
                  SizedBox(width: itemWidth, child: cardSugar),
                  SizedBox(width: itemWidth, child: cardSmp),
                ],
              );
            }
          },
        ),
      ],
    );
  }
  // ---------------------------------------------------------------------------
  // WIDGET: FILTER TOOLBAR (Unified All Batches & Date Selector)
  // ---------------------------------------------------------------------------
  Widget _buildFilterToolbar(BatchRecordsState state, List<String> productNames) {
    final now = DateTime.now();
    final isTodaySelected = state.selectedDate != null &&
        state.selectedDate!.year == now.year &&
        state.selectedDate!.month == now.month &&
        state.selectedDate!.day == now.day;
    final isCustomDateSelected = state.selectedDate != null && !isTodaySelected;

    final allProductFilterOptions = ['All', ...productNames];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;

          // Product / Batch Name Filter Dropdown
          final productDropdown = Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: state.selectedProduct != 'All' ? AppColors.primary : AppColors.cardBorder,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 16,
                  color: state.selectedProduct != 'All' ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: allProductFilterOptions.contains(state.selectedProduct)
                        ? state.selectedProduct
                        : 'All',
                    isDense: true,
                    style: const TextStyle(
                      fontSize: AppTextSizes.body,
                      fontWeight: AppFontWeights.bold,
                      color: AppColors.textPrimary,
                    ),
                    items: allProductFilterOptions.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(p == 'All' ? 'All Batches' : p),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(batchRecordsProvider.notifier).setProductFilter(val);
                      }
                    },
                  ),
                ),
              ],
            ),
          );

          // Unified Date Segmented Control: [ Today | Select Date ]
          final dateSegmentControl = Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Today Button
                InkWell(
                  onTap: () {
                    ref.read(batchRecordsProvider.notifier).setDateFilter(DateTime.now());
                  },
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isTodaySelected ? AppColors.primary : Colors.transparent,
                      borderRadius: isTodaySelected
                          ? const BorderRadius.horizontal(left: Radius.circular(7))
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.today_rounded,
                          size: 15,
                          color: isTodaySelected ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Today',
                          style: TextStyle(
                            fontSize: AppTextSizes.body,
                            fontWeight: AppFontWeights.bold,
                            color: isTodaySelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 22,
                  color: AppColors.cardBorder,
                ),
                // Custom Date Picker Button
                InkWell(
                  onTap: _pickSingleDate,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCustomDateSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: isCustomDateSelected
                          ? const BorderRadius.horizontal(right: Radius.circular(7))
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 15,
                          color: isCustomDateSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCustomDateSelected
                              ? Formatters.formatIsoDate(state.selectedDate!)
                              : 'Select Date',
                          style: TextStyle(
                            fontSize: AppTextSizes.body,
                            fontWeight: AppFontWeights.bold,
                            color: isCustomDateSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );

          // Clear Filter button if non-default filter is applied
          final hasActiveFilters = isCustomDateSelected || state.selectedProduct != 'All';
          final clearFilterButton = hasActiveFilters
              ? TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text(
                    'Reset to Today',
                    style: TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.bold),
                  ),
                  onPressed: () {
                    ref.read(batchRecordsProvider.notifier).clearFilters();
                  },
                )
              : null;

          if (isWide) {
            return Row(
              children: [
                productDropdown,
                const SizedBox(width: 12),
                dateSegmentControl,
                if (clearFilterButton != null) ...[
                  const SizedBox(width: 10),
                  clearFilterButton,
                ],
              ],
            );
          } else {
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                productDropdown,
                dateSegmentControl,
                ?clearFilterButton,
              ],
            );
          }
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGET: TODAY'S CONSUMPTION (Clean simple inline design without chip cards)
  // ---------------------------------------------------------------------------
  Widget _buildTodaysConsumption(List<BatchRecordModel> allBatches) {
    final now = DateTime.now();
    final todayIso = Formatters.formatIsoDate(now);
    final todayBatches = allBatches.where((b) => b.productionDate == todayIso);

    double milk = 0;
    double water = 0;
    double sugar = 0;
    double smp = 0;

    for (final b in todayBatches) {
      for (final ing in b.ingredients) {
        final name = ing.ingredientName.toLowerCase();
        if (name.contains('milk') && !name.contains('smp') && !name.contains('powder')) {
          milk += ing.quantity;
        } else if (name.contains('water')) {
          water += ing.quantity;
        } else if (name.contains('sugar')) {
          sugar += ing.quantity;
        } else if (name.contains('smp') || name.contains('powder')) {
          smp += ing.quantity;
        }
      }
    }

    Widget buildMetric(String label, double val, String unit, Color color) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: AppTextSizes.body,
              fontWeight: AppFontWeights.semiBold,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${Formatters.formatSmart(val)} $unit',
            style: TextStyle(
              fontSize: AppTextSizes.body,
              fontWeight: AppFontWeights.bold,
              color: color,
            ),
          ),
        ],
      );
    }

    const dot = Text(
      '•',
      style: TextStyle(
        fontSize: AppTextSizes.body,
        fontWeight: AppFontWeights.bold,
        color: AppColors.textMuted,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 6,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                "Today's Consumption:",
                style: TextStyle(
                  fontSize: AppTextSizes.body,
                  fontWeight: AppFontWeights.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          buildMetric('Milk Taken', milk, 'L', AppColors.primaryDark),
          dot,
          buildMetric('Water', water, 'L', AppColors.accentCyanDeep),
          dot,
          buildMetric('Sugar', sugar, 'kg', const Color(0xFFB45309)),
          dot,
          buildMetric('SMP', smp, 'kg', const Color(0xFF4338CA)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGET: DATE GROUP SECTION & BATCH CARDS
  // ---------------------------------------------------------------------------
  Widget _buildDateGroupSection(
    String dateStr,
    DailyBatchSummary summary,
    List<BatchRecordModel> batches,
  ) {
    final isToday = dateStr == Formatters.formatIsoDate(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only show date heading for non-today dates (as today's date & consumption are already displayed above)
        if (!isToday) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: Row(
              children: [
                const Icon(Icons.event_note_rounded, size: 17, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  _formatDateHeading(dateStr),
                  style: const TextStyle(
                    fontSize: AppTextSizes.subheading,
                    fontWeight: AppFontWeights.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                StatusBadge.info('${summary.totalBatches} ${summary.totalBatches == 1 ? 'Batch' : 'Batches'}'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Total: ${Formatters.formatSmart(summary.totalQuantity)} L',
                    style: const TextStyle(color: Colors.white, fontWeight: AppFontWeights.bold, fontSize: AppTextSizes.caption),
                  ),
                ),
              ],
            ),
          ),
        ],

        // List of Individual Batches for this Date
        ...batches.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildBatchCard(entry.value, entry.key + 1),
            )),
      ],
    );
  }

  /// Builds a single Batch record card with heading batch name, time & shift below name, logged by, and accordion formulation breakdown
  Widget _buildBatchCard(BatchRecordModel batch, int batchIndex) {
    final isExpanded = _expandedBatchIds.contains(batch.id);

    // Derived summary string for compact view
    final summaryPreview = batch.ingredients.map((ing) {
      return '${ing.ingredientName}: ${Formatters.formatSmart(ing.quantity)}${ing.unit}';
    }).join(' • ');

    // Ensure shift and time are 100% accurate: if shift is Shift A, entry time cannot be 5pm (5pm is Shift B)
    final displayShift = (batch.shift != null &&
            AppConstants.isDateTimeValidForShift(batch.createdAt, batch.shift!))
        ? batch.shift!
        : AppConstants.determineShift(batch.createdAt);

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Batch Number Chip (e.g., 1, 2, 3...)
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
                  ),
                  child: Text(
                    '$batchIndex',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: AppTextSizes.body,
                      fontWeight: AppFontWeights.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 1. Heading: Batch Name + Batch Number
                // 2. Below name: Time and Shift
                // 3. Below that: Logged by
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Heading: Batch Name
                      Text(
                        batch.productName,
                        style: const TextStyle(
                          fontWeight: AppFontWeights.bold,
                          fontSize: AppTextSizes.body,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Below name: Time and Shift
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.formatTime(batch.createdAt),
                            style: const TextStyle(
                              fontSize: AppTextSizes.caption,
                              fontWeight: AppFontWeights.semiBold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (displayShift.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textMuted)),
                            const SizedBox(width: 6),
                            Text(
                              displayShift,
                              style: const TextStyle(
                                fontSize: AppTextSizes.caption,
                                fontWeight: AppFontWeights.semiBold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Below that: Logged by
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Logged by: ${batch.operatorName ?? 'Not specified'}',
                            style: const TextStyle(
                              fontSize: AppTextSizes.caption,
                              fontWeight: AppFontWeights.semiBold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Batch Quantity Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${Formatters.formatSmart(batch.batchQuantity)} ${batch.batchUnit}',
                    style: const TextStyle(
                      fontWeight: AppFontWeights.bold,
                      fontSize: AppTextSizes.body,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

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

          // Accordion Type Dropdown for Ingredient Formulation Breakdown
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedBatchIds.remove(batch.id);
                } else {
                  _expandedBatchIds.add(batch.id);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isExpanded ? AppColors.background : Colors.transparent,
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 15,
                    color: isExpanded ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ingredients Formulation Breakdown',
                    style: TextStyle(
                      fontSize: AppTextSizes.caption,
                      fontWeight: AppFontWeights.bold,
                      color: isExpanded ? AppColors.primaryDark : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isExpanded ? AppColors.primaryContainer : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${batch.ingredients.length} items',
                      style: TextStyle(
                        fontSize: AppTextSizes.caption,
                        fontWeight: AppFontWeights.bold,
                        color: isExpanded ? AppColors.primaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (!isExpanded && summaryPreview.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        summaryPreview,
                        style: const TextStyle(
                          fontSize: AppTextSizes.caption,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else ...[
                    const Spacer(),
                  ],
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: isExpanded ? AppColors.primary : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Formulation Breakdown content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            child: Text('Ingredient', style: TextStyle(fontWeight: AppFontWeights.bold, fontSize: AppTextSizes.caption, color: AppColors.textSecondary)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Text('Quantity Used', style: TextStyle(fontWeight: AppFontWeights.bold, fontSize: AppTextSizes.caption, color: AppColors.textSecondary)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Text('Unit', style: TextStyle(fontWeight: AppFontWeights.bold, fontSize: AppTextSizes.caption, color: AppColors.textSecondary)),
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
                                      style: const TextStyle(fontWeight: AppFontWeights.semiBold, fontSize: AppTextSizes.caption),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Text(
                                Formatters.formatSmart(ing.quantity),
                                style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: AppTextSizes.caption, color: AppColors.textPrimary),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Text(
                                ing.unit,
                                style: const TextStyle(fontWeight: AppFontWeights.semiBold, fontSize: AppTextSizes.caption, color: AppColors.textSecondary),
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
                        style: const TextStyle(fontSize: AppTextSizes.caption, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.alertLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_outlined, size: 48, color: AppColors.alert),
            ),
            const SizedBox(height: 14),
            const Text(
              'No Batch Records Found',
              style: TextStyle(fontSize: AppTextSizes.subheading, fontWeight: AppFontWeights.bold, color: AppColors.alert),
            ),
            const SizedBox(height: 6),
            const Text(
              'No manufacturing batches match the current filter or date selection.',
              style: TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

}
