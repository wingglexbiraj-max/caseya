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
import '../../models/batch_record_model.dart';
import '../../providers/batch_records_provider.dart';
import '../../providers/production_provider.dart';
import '../../services/milk_standardization_calculator.dart';
import 'add_batch_dialog.dart';

class BatchRecordsPage extends ConsumerStatefulWidget {
  const BatchRecordsPage({super.key});

  @override
  ConsumerState<BatchRecordsPage> createState() => _BatchRecordsPageState();
}

class _BatchRecordsPageState extends ConsumerState<BatchRecordsPage> {
  // Add Batch Entry Form Controllers
  final TextEditingController _milkController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();
  final TextEditingController _sugarController = TextEditingController();
  final TextEditingController _smpController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customPersonController = TextEditingController();

  // Accordion expanded state for batch cards
  final Set<String> _expandedBatchIds = {};

  // Standardization Batch Products List
  static final List<String> standardizationProductNames =
      MilkStandardizationCalculator.standardizationProducts
          .map((p) => p.productName)
          .toList();

  // Form State
  String? _selectedProduct;
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
    _waterController.clear();
    _sugarController.clear();
    _smpController.clear();
    _notesController.clear();
    _customPersonController.clear();
    setState(() {
      _selectedProduct = null;
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
    final water = Formatters.parseDouble(_waterController.text);
    final sugar = Formatters.parseDouble(_sugarController.text);
    final smp = Formatters.parseDouble(_smpController.text);

    if (milk <= 0 && water <= 0 && sugar <= 0 && smp <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least milk, water, sugar, or SMP quantity.'),
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
      notes: _notesController.text.trim(),
      ingredients: ingredients,
      createdAt: now,
      updatedAt: now,
    );

    final success = await ref.read(batchRecordsProvider.notifier).createBatch(batch);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Batch $batchNum for $_selectedProduct (${Formatters.formatSmart(totalVolume)} L) recorded successfully.',
          ),
          backgroundColor: const Color(0xFF10B981),
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

  IconData _getProductIcon(String product) {
    switch (product.toLowerCase()) {
      case 'lassi':
      case 'purabi lassi 200 ml':
        return Icons.local_drink_rounded;
      case 'curd':
      case 'sweet curd':
      case 'sweet curd cup 400g':
      case 'plain curd cup':
      case 'plain curd cup 80g':
      case 'plain curd cup 400g':
        return Icons.takeout_dining_rounded;
      case 'plain curd pouch':
      case 'curd pouch 400 g':
      case 'curd pouch 1 kg':
        return Icons.shopping_bag_outlined;
      case 'std milk':
      case 'milk pouch':
      case 'milk':
      case 'std 500 ml':
      case 'std 250 ml':
        return Icons.water_drop_rounded;
      case 'sm+ (army milk)':
      case 'purabi smart + 500 ml':
        return Icons.shield_rounded;
      case 'paneer':
      case 'purabi paneer 200g':
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

    // Standardization products list for batch entry dropdown (aligned with milk standardization)
    final batchProductNames = standardizationProductNames;

    // Unified product options list for history search & filter dropdown
    final allProductNames = <String>{
      ...batchProductNames,
      ...state.batches.map((b) => b.productName),
    }.toList();

    // Global totals
    final totalBatches = state.batches.length;
    final totalProduction = state.batches.fold(0.0, (acc, b) => acc + b.batchQuantity);

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
            // -------------------------------------------------------------
            // 1. TOP KPI SUMMARY CARDS (Total Batches Logged & Volume)
            // -------------------------------------------------------------
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
            const SizedBox(height: 24),

            // -------------------------------------------------------------
            // 2. ADD BATCH ENTRY SECTION (Heading outside card like Boiler)
            // -------------------------------------------------------------
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.blender_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'ADD BATCH ENTRY',
                  style: TextStyle(
                    fontSize: AppTextSizes.subheading,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAddBatchEntryCard(batchProductNames),
            const SizedBox(height: 32),

            // -------------------------------------------------------------
            // 3. DAILY BATCH RECORDS (Heading outside card like Boiler)
            // -------------------------------------------------------------
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'DAILY BATCH RECORDS (DATE-WISE)',
                  style: TextStyle(
                    fontSize: AppTextSizes.subheading,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
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
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGET: ADD BATCH ENTRY SECTION
  // ---------------------------------------------------------------------------
  Widget _buildAddBatchEntryCard(List<String> productNames) {
    final isCustomPerson = _selectedLoggedBy == 'Other (Type manually)';
    final currentVolume = _currentTotalVolume;

    return AppCard(
      topBorderColor: AppColors.primary,
      topBorderHeight: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 0: Date & Live Time Chips
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 650;

              final dateWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date', style: TextStyle(fontSize: AppTextSizes.body, fontWeight: FontWeight.w700)),
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
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: AppTextSizes.body),
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
                  const Text('Time', style: TextStyle(fontSize: AppTextSizes.body, fontWeight: FontWeight.w700)),
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

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: dateWidget),
                    const SizedBox(width: 14),
                    Expanded(child: timeWidget),
                  ],
                );
              } else {
                return Column(
                  children: [
                    dateWidget,
                    const SizedBox(height: 12),
                    timeWidget,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // Row 1: Batch Name & Logged By Dropdowns
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 650;

              final productDropdownWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Batch Name',
                    style: TextStyle(fontSize: AppTextSizes.body, fontWeight: FontWeight.w700),
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
                        value: (_selectedProduct != null && productNames.contains(_selectedProduct))
                            ? _selectedProduct
                            : null,
                        hint: const Text(
                          'Select Batch',
                          style: TextStyle(fontSize: AppTextSizes.body, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                        ),
                        isExpanded: true,
                        items: productNames.map((name) {
                          return DropdownMenuItem(
                            value: name,
                            child: Row(
                              children: [
                                Icon(_getProductIcon(name), size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontSize: AppTextSizes.body, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedProduct = val);
                        },
                      ),
                    ),
                  ),
                ],
              );

              final personDropdownWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Logged By',
                    style: TextStyle(fontSize: AppTextSizes.body, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 44,
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
                              style: const TextStyle(fontSize: AppTextSizes.body, fontWeight: FontWeight.w600),
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
                  if (isCustomPerson) ...[
                    const SizedBox(height: 8),
                    AppTextField(
                      label: 'Enter Name',
                      hint: 'Type employee name...',
                      controller: _customPersonController,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: productDropdownWidget),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: personDropdownWidget),
                  ],
                );
              } else {
                return Column(
                  children: [
                    productDropdownWidget,
                    const SizedBox(height: 14),
                    personDropdownWidget,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 18),

          // Row 3: Four Formulation Inputs: Milk Taken, Water, Sugar, SMP
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 680;

              final milkField = AppTextField(
                label: 'Milk Taken (L)',
                hint: 'e.g. 1500',
                suffixText: 'Litres',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                controller: _milkController,
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
                    const SizedBox(width: 12),
                    Expanded(child: waterField),
                    const SizedBox(width: 12),
                    Expanded(child: sugarField),
                    const SizedBox(width: 12),
                    Expanded(child: smpField),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: milkField),
                        const SizedBox(width: 12),
                        Expanded(child: waterField),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: sugarField),
                        const SizedBox(width: 12),
                        Expanded(child: smpField),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // Total Batch Quantity Banner (Placed directly above Batch Note, styled like Boiler page)
          _buildLiveTotalBatchBanner(currentVolume),
          const SizedBox(height: 14),

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
                      fontWeight: FontWeight.w700,
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
                      fontWeight: FontWeight.w700,
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

  Widget _buildLiveTotalBatchBanner(double totalVolume) {
    final m = Formatters.parseDouble(_milkController.text);
    final w = Formatters.parseDouble(_waterController.text);
    final s = Formatters.parseDouble(_sugarController.text);
    final smp = Formatters.parseDouble(_smpController.text);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2448), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.blender_rounded, color: AppColors.accentCyan, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL BATCH QUANTITY',
                  style: TextStyle(
                    fontSize: AppTextSizes.caption,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: AppColors.goldAccent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.formatSmart(totalVolume)} L',
                  style: const TextStyle(
                    fontSize: AppTextSizes.subheading,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          if (totalVolume > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Text(
                'Milk: ${Formatters.formatSmart(m)}L • Water: ${Formatters.formatSmart(w)}L\nSugar: ${Formatters.formatSmart(s)}kg • SMP: ${Formatters.formatSmart(smp)}kg',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: AppTextSizes.caption,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ],
      ),
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
                      fontWeight: FontWeight.w700,
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
                            fontWeight: FontWeight.w700,
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
                            fontWeight: FontWeight.w700,
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
                    style: TextStyle(fontSize: AppTextSizes.caption, fontWeight: FontWeight.w700),
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
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${Formatters.formatSmart(val)} $unit',
            style: TextStyle(
              fontSize: AppTextSizes.body,
              fontWeight: FontWeight.w800,
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
        fontWeight: FontWeight.w800,
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
                  fontWeight: FontWeight.w800,
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
                    fontWeight: FontWeight.w800,
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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: AppTextSizes.caption),
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
                      fontWeight: FontWeight.w900,
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
                          fontWeight: FontWeight.w800,
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
                              fontWeight: FontWeight.w600,
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
                                fontWeight: FontWeight.w600,
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
                              fontWeight: FontWeight.w600,
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
                      fontWeight: FontWeight.w800,
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
                      fontWeight: FontWeight.w700,
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
                        fontWeight: FontWeight.w700,
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
                            child: Text('Ingredient', style: TextStyle(fontWeight: FontWeight.w700, fontSize: AppTextSizes.caption, color: AppColors.textSecondary)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Text('Quantity Used', style: TextStyle(fontWeight: FontWeight.w700, fontSize: AppTextSizes.caption, color: AppColors.textSecondary)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Text('Unit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: AppTextSizes.caption, color: AppColors.textSecondary)),
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
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: AppTextSizes.caption),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Text(
                                Formatters.formatSmart(ing.quantity),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: AppTextSizes.caption, color: AppColors.textPrimary),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Text(
                                ing.unit,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: AppTextSizes.caption, color: AppColors.textSecondary),
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
              style: TextStyle(fontSize: AppTextSizes.subheading, fontWeight: FontWeight.w800, color: AppColors.alert),
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
                  style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                Text(
                  val,
                  style: const TextStyle(fontSize: AppTextSizes.subheading, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textMuted),
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
