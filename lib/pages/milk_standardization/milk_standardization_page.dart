import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/searchable_dropdown.dart';
import '../../core/widgets/calculation_breakdown.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../providers/standardization_provider.dart';
import '../../providers/production_provider.dart';
import '../../providers/batch_records_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lab_provider.dart';
import '../../models/product_model.dart';
import '../../models/standardization_record.dart';
import '../../models/lab_milk_test.dart';
import '../../services/local_storage_service.dart';

class MilkStandardizationPage extends ConsumerStatefulWidget {
  const MilkStandardizationPage({super.key});

  @override
  ConsumerState<MilkStandardizationPage> createState() => _MilkStandardizationPageState();
}

class _MilkStandardizationPageState extends ConsumerState<MilkStandardizationPage> {
  final TextEditingController _totalBatchController = TextEditingController();
  final TextEditingController _milkTakenController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _snfController = TextEditingController();
  final TextEditingController _desiredFatController = TextEditingController();
  final TextEditingController _desiredSnfController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _standardsExpanded = false;
  bool _archiveExpanded = false;
  bool _autoCalculateMilk = false;
  String? _fetchedSiloSource;
  String? _fetchedLabTester;
  DateTime? _filterDate = DateTime.now();
  String? _filterProductId;

  bool _matchesDate(StandardizationRecord r, DateTime filterDate) {
    final targetIso = Formatters.formatIsoDate(filterDate);
    if (r.date == targetIso) return true;
    if (r.date == Formatters.formatDate(filterDate)) return true;
    if (r.createdAt.year == filterDate.year &&
        r.createdAt.month == filterDate.month &&
        r.createdAt.day == filterDate.day) {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(standardizationProvider);
      if (_totalBatchController.text.isEmpty && state.totalBatchRequired > 0) {
        _totalBatchController.text = state.totalBatchRequired.toStringAsFixed(0);
      }
      if (_milkTakenController.text.isEmpty && state.milkTaken != null && state.milkTaken! > 0) {
        _milkTakenController.text = state.milkTaken!.toStringAsFixed(0);
      }
      if (_fatController.text.isEmpty && state.milkFat > 0) {
        _fatController.text = state.milkFat.toStringAsFixed(2);
      }
      if (_snfController.text.isEmpty && state.milkSnf > 0) {
        _snfController.text = state.milkSnf.toStringAsFixed(2);
      }
      if (state.selectedTargetProduct != null) {
        if (_desiredFatController.text.isEmpty) {
          _desiredFatController.text = (state.selectedTargetProduct!.targetFat ?? 3.5).toStringAsFixed(2);
        }
        if (_desiredSnfController.text.isEmpty) {
          _desiredSnfController.text = (state.selectedTargetProduct!.targetSnf ?? 8.5).toStringAsFixed(2);
        }
      }
      _onCalculate();
    });
  }

  @override
  void dispose() {
    _totalBatchController.dispose();
    _milkTakenController.dispose();
    _fatController.dispose();
    _snfController.dispose();
    _desiredFatController.dispose();
    _desiredSnfController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectProduct(ProductModel product) {
    setState(() {
      _standardsExpanded = false;
      _desiredFatController.text = (product.targetFat ?? 3.5).toStringAsFixed(2);
      _desiredSnfController.text = (product.targetSnf ?? 8.5).toStringAsFixed(2);
    });
    ref.read(standardizationProvider.notifier).selectTargetProduct(product);
    _onCalculate();
  }

  void _onCalculate({bool showErrorIfInvalid = false}) {
    final totalBatch = Formatters.parseDouble(_totalBatchController.text);
    final fat = Formatters.parseDouble(_fatController.text);
    final snf = Formatters.parseDouble(_snfController.text);
    final state = ref.read(standardizationProvider);

    if (state.selectedTargetProduct == null || totalBatch <= 0 || fat <= 0 || snf <= 0) {
      if (showErrorIfInvalid) {
        _formKey.currentState?.validate();
      }
      return;
    }

    final notifier = ref.read(standardizationProvider.notifier);
    notifier.setTotalBatch(totalBatch);
    final bool shouldAutoMilk = _autoCalculateMilk || _milkTakenController.text.trim().isEmpty;
    notifier.setAutoCalculateMilk(shouldAutoMilk);
    if (!shouldAutoMilk && _milkTakenController.text.trim().isNotEmpty) {
      notifier.setMilkTaken(Formatters.parseDouble(_milkTakenController.text));
    } else {
      notifier.setMilkTaken(null);
    }
    notifier.setMilkFat(fat);
    notifier.setMilkSnf(snf);

    final targetFat = Formatters.parseDouble(_desiredFatController.text);
    final targetSnf = Formatters.parseDouble(_desiredSnfController.text);
    if (targetFat > 0) {
      notifier.setTargetFat(targetFat);
      notifier.setDesiredFinalFat(targetFat);
    }
    if (targetSnf > 0) {
      notifier.setTargetSnf(targetSnf);
      notifier.setDesiredTargetSnf(targetSnf);
    }

    notifier.calculate();
  }

  void _onClear() {
    setState(() {
      _totalBatchController.clear();
      _milkTakenController.clear();
      _fatController.clear();
      _snfController.clear();
      _desiredFatController.clear();
      _desiredSnfController.clear();
      _notesController.clear();
      _autoCalculateMilk = false;
      _standardsExpanded = false;
      _fetchedSiloSource = null;
      _fetchedLabTester = null;
    });
    ref.read(standardizationProvider.notifier).clear();
  }

  Future<void> _openFetchLabSiloDialog() async {
    final silos = await LocalStorageService.getSilos();
    final todayStr = Formatters.formatDate(DateTime.now());

    // Fetch latest reading for each silo for today
    final Map<String, LabMilkTest?> readings = {};
    for (final silo in silos) {
      readings[silo.id] = await LocalStorageService.getLatestReadingForSilo(silo.id, todayDateStr: todayStr);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.biotech_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fetch Lab Fat & SNF',
                    style: TextStyle(fontSize: AppTextSizes.subheading, fontWeight: AppFontWeights.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Select a milk silo / storage tank to populate lab tested values',
                    style: TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textSecondary, fontWeight: AppFontWeights.medium),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: silos.map((silo) {
                final reading = readings[silo.id];
                final hasReading = reading != null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      if (!hasReading) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No laboratory reading recorded today for ${silo.name}. Please enter reading in Lab module.'),
                            backgroundColor: AppColors.danger,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _fatController.text = reading.fatPercentage.toStringAsFixed(2);
                        _snfController.text = reading.snfPercentage.toStringAsFixed(2);
                        _fetchedSiloSource = 'Source: ${reading.siloName} • Lab tested ${reading.testTime}';
                        _fetchedLabTester = reading.labUserName;
                      });

                      ref.read(standardizationProvider.notifier).applyLabReading(
                            siloName: reading.siloName,
                            testTime: reading.testTime,
                            fat: reading.fatPercentage,
                            snf: reading.snfPercentage,
                            siloId: silo.id,
                          );

                      _onCalculate();

                      Navigator.pop(ctx);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Loaded ${reading.siloName} (Fat: ${reading.fatPercentage.toStringAsFixed(2)}%, SNF: ${reading.snfPercentage.toStringAsFixed(2)}%)'),
                          backgroundColor: AppColors.primary,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: hasReading ? Colors.white : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasReading ? AppColors.primary.withValues(alpha: 0.3) : AppColors.cardBorder,
                          width: hasReading ? 1.5 : 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: hasReading ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.storage_rounded,
                              color: hasReading ? AppColors.primary : AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      silo.name,
                                      style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: AppTextSizes.body),
                                    ),
                                    const SizedBox(width: 8),
                                    if (hasReading)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Today',
                                          style: TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.bold, color: Color(0xFF16A34A)),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.danger.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                                        ),
                                        child: const Text(
                                          'No reading today',
                                          style: TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.bold, color: AppColors.danger),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (hasReading)
                                  Text(
                                    'Fat ${reading.fatPercentage.toStringAsFixed(2)}%  •  SNF ${reading.snfPercentage.toStringAsFixed(2)}%  •  Tested ${reading.testTime}',
                                    style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.bold, color: AppColors.primaryDark),
                                  )
                                else
                                  Text(
                                    silo.description,
                                    style: const TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textSecondary),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (hasReading)
                            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary)
                          else
                            const Icon(Icons.block_rounded, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _onSaveRecord() async {
    // 1. Sync form inputs from controllers to state
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check form fields and correct invalid values before recording.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final notifier = ref.read(standardizationProvider.notifier);
    notifier.setTotalBatch(Formatters.parseDouble(_totalBatchController.text));
    final bool shouldAutoMilk = _autoCalculateMilk || _milkTakenController.text.trim().isEmpty;
    notifier.setAutoCalculateMilk(shouldAutoMilk);
    if (!shouldAutoMilk && _milkTakenController.text.trim().isNotEmpty) {
      notifier.setMilkTaken(Formatters.parseDouble(_milkTakenController.text));
    } else {
      notifier.setMilkTaken(null);
    }
    notifier.setMilkFat(Formatters.parseDouble(_fatController.text));
    notifier.setMilkSnf(Formatters.parseDouble(_snfController.text));

    final targetFat = Formatters.parseDouble(_desiredFatController.text);
    final targetSnf = Formatters.parseDouble(_desiredSnfController.text);
    if (targetFat > 0) {
      notifier.setTargetFat(targetFat);
      notifier.setDesiredFinalFat(targetFat);
    }
    if (targetSnf > 0) {
      notifier.setTargetSnf(targetSnf);
      notifier.setDesiredTargetSnf(targetSnf);
    }

    // 2. Ensure calculation is performed
    notifier.calculate();

    // 3. Save official batch record
    final user = ref.read(authProvider);
    final success = await notifier.saveRecord(
      employeeId: user.employeeCode,
      employeeName: user.name,
      notes: _notesController.text.trim(),
      testedBy: _fetchedLabTester ?? 'QC Lab',
    );

    if (success && mounted) {
      // Refresh Production Register, Batch Records, and Silo Milk Stock immediately
      ref.read(productionProvider.notifier).reloadStandardizationBatches();
      ref.read(batchRecordsProvider.notifier).loadBatches();
      ref.read(labProvider.notifier).refreshSiloStock();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(standardizationProvider).successMessage ??
                '✓ Standardization batch officially recorded and synced to Production Register & Batch Records.',
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 4),
        ),
      );
    } else if (mounted) {
      final error = ref.read(standardizationProvider).errorMessage ??
          'Could not record batch. Please ensure all inputs are valid.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(standardizationProvider);
    final productionState = ref.watch(productionProvider);
    final labState = ref.watch(labProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 28,
          vertical: 22,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Lab Data Status Banner
              if (state.labDataFetchStatus != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: state.hasFetchedLabData ? AppColors.successLight : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: state.hasFetchedLabData
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.hasFetchedLabData ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        color: state.hasFetchedLabData ? AppColors.primary : AppColors.warning,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.labDataFetchStatus!,
                          style: TextStyle(
                            color: state.hasFetchedLabData ? AppColors.primaryDark : const Color(0xFF92400E),
                            fontSize: AppTextSizes.caption,
                            fontWeight: AppFontWeights.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Error Banner
              if (state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: AppTextSizes.body, fontWeight: AppFontWeights.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Section Heading OUTSIDE Card (matching Lab Fat SNF page)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.science_rounded,
                      size: 20,
                      color: Colors.black.withValues(alpha: 0.60),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'BATCH MAKING INPUT',
                    style: TextStyle(
                      fontSize: AppTextSizes.subheading,
                      fontWeight: AppFontWeights.bold,
                      letterSpacing: 0.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Main Formulation Input Card (matching Lab Fat SNF page record card)
              AppCard(
                backgroundColor: Colors.white,
                borderColor: Colors.black.withValues(alpha: 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Product Selection Dropdown
                    _buildProductDropdown(state),

                    // Product Formulation Standard Card (Collapsible & Customizable)
                    if (state.selectedTargetProduct != null)
                      _buildProductStandardCard(state.selectedTargetProduct!, state),

                    const SizedBox(height: 18),

                    // Source Silo Selector (RMST / PMST - Deducted from Silo Stock)
                    _buildSourceSiloSelector(state, labState),

                    const SizedBox(height: 18),

                    // 2. Batch Volumes: Total Batch Required & Milk Taken
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 600;

                        final totalBatchField = AppTextField(
                          label: 'Total Batch Required',
                          hint: 'e.g. 1700',
                          controller: _totalBatchController,
                          suffixText: 'Litres',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => _onCalculate(),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Batch quantity required';
                            final n = Formatters.parseDouble(val);
                            if (n <= 0) return 'Must be greater than 0';
                            return null;
                          },
                        );

                        final milkTakenWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              label: 'Milk Taken',
                              hint: _autoCalculateMilk ? 'Auto-derived from Target Fat' : 'e.g. 1400',
                              controller: _milkTakenController,
                              suffixText: 'Litres',
                              readOnly: _autoCalculateMilk,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => _onCalculate(),
                              validator: (val) {
                                if (_autoCalculateMilk) return null;
                                if (val == null || val.trim().isEmpty) return 'Required';
                                final n = Formatters.parseDouble(val);
                                if (n <= 0) return 'Must be greater than 0';
                                final total = Formatters.parseDouble(_totalBatchController.text);
                                if (total > 0 && n > total) return 'Cannot exceed Total Batch';
                                return null;
                              },
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _autoCalculateMilk = !_autoCalculateMilk;
                                  if (_autoCalculateMilk) {
                                    _milkTakenController.clear();
                                  } else if (_milkTakenController.text.isEmpty) {
                                    _milkTakenController.text = '1400';
                                  }
                                });
                                _onCalculate();
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: Checkbox(
                                        value: _autoCalculateMilk,
                                        activeColor: AppColors.primary,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                        onChanged: (val) {
                                          setState(() {
                                            _autoCalculateMilk = val ?? false;
                                            if (_autoCalculateMilk) {
                                              _milkTakenController.clear();
                                            } else if (_milkTakenController.text.isEmpty) {
                                              _milkTakenController.text = '1400';
                                            }
                                          });
                                          _onCalculate();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Auto-calculate milk required from target fat',
                                      style: TextStyle(
                                        fontSize: AppTextSizes.caption,
                                        color: AppColors.textSecondary,
                                        fontWeight: AppFontWeights.semiBold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: totalBatchField),
                              const SizedBox(width: 14),
                              Expanded(child: milkTakenWidget),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              totalBatchField,
                              const SizedBox(height: 12),
                              milkTakenWidget,
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. Fetch Latest Lab Data Chip (Positioned directly above Present Fat & SNF)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: _openFetchLabSiloDialog,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _fetchedSiloSource != null
                                  ? const Color(0xFFDCFCE7)
                                  : AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _fetchedSiloSource != null
                                    ? const Color(0xFF16A34A).withValues(alpha: 0.5)
                                    : AppColors.primary.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _fetchedSiloSource != null
                                      ? Icons.verified_rounded
                                      : Icons.biotech_rounded,
                                  size: 16,
                                  color: _fetchedSiloSource != null
                                      ? const Color(0xFF16A34A)
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _fetchedSiloSource != null
                                      ? _fetchedSiloSource!
                                      : 'Fetch Latest Lab Data',
                                  style: TextStyle(
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: AppFontWeights.bold,
                                    color: _fetchedSiloSource != null
                                        ? const Color(0xFF166534)
                                        : AppColors.primary,
                                  ),
                                ),
                                if (_fetchedSiloSource != null) ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      setState(() { _fetchedSiloSource = null; });
                                      ref.read(standardizationProvider.notifier).clearLabDataStatus();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded, size: 13, color: Color(0xFF166534)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Present Milk FAT % and SNF %
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Present Milk FAT %',
                            hint: 'e.g., 4.5',
                            controller: _fatController,
                            suffixText: '%',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => _onCalculate(),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Required';
                              final n = Formatters.parseDouble(val);
                              if (n < 0 || n > 15.0) return '0.0 - 15.0%';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: AppTextField(
                            label: 'Present Milk SNF %',
                            hint: 'e.g., 8.5',
                            controller: _snfController,
                            suffixText: '%',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => _onCalculate(),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Required';
                              final n = Formatters.parseDouble(val);
                              if (n < 0 || n > 16.0) return '0.0 - 16.0%';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4. Optional Remarks (Notes)
                    AppTextField(
                      label: 'Optional Remarks (Notes)',
                      hint: 'e.g. Silo 03, Evening incubation batch, Tanker 04...',
                      controller: _notesController,
                    ),
                    const SizedBox(height: 20),

                    // Result Chip Cards (styled like Today's Metric Summary / Product Calculator Page)
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
                          'STANDARDIZATION METRICS',
                          style: TextStyle(
                            fontSize: AppTextSizes.caption,
                            fontWeight: AppFontWeights.bold,
                            letterSpacing: 0.6,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (state.result != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '• ${state.selectedTargetProduct?.productName ?? 'Standardized Batch'}',
                              style: const TextStyle(
                                fontSize: AppTextSizes.caption,
                                fontWeight: AppFontWeights.medium,
                                color: AppColors.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardMilk = MetricCard(
                          title: 'Milk Taken',
                          value: state.result != null ? Formatters.formatDecimal(state.result!.milkTaken) : '—',
                          unit: 'Litres',
                          subtitle: state.result != null
                              ? (state.result!.isAutoCalculatedMilk ? 'Auto-Derived' : 'Allocated Milk')
                              : 'Raw milk allocation',
                          icon: Icons.local_drink_rounded,
                          iconColor: Colors.black.withValues(alpha: 0.60),
                          iconBgColor: Colors.black.withValues(alpha: 0.06),
                          cardBgColor: const Color(0xFFEFF6FF),
                        );

                        final cardSmp = MetricCard(
                          title: 'SMP Required',
                          value: state.result != null ? Formatters.formatDecimal(state.result!.smpRequired) : '—',
                          unit: 'kg',
                          subtitle: state.result != null
                              ? '${state.result!.smpFactor.toStringAsFixed(0)}% SNF Factor'
                              : 'Deficit correction',
                          icon: Icons.grain_rounded,
                          iconColor: Colors.black.withValues(alpha: 0.60),
                          iconBgColor: Colors.black.withValues(alpha: 0.06),
                          cardBgColor: const Color(0xFFFFFBEB),
                        );

                        final cardWater = MetricCard(
                          title: 'Water Required',
                          value: state.result != null ? Formatters.formatDecimal(state.result!.waterRequired) : '—',
                          unit: 'Litres',
                          subtitle: state.result != null
                              ? (state.result!.reserveVolume > 0
                                  ? 'Blending (-${Formatters.formatDecimal(state.result!.reserveVolume)}L Reserve)'
                                  : 'Process blending water')
                              : 'Dilution water',
                          icon: Icons.water_drop_rounded,
                          iconColor: Colors.black.withValues(alpha: 0.60),
                          iconBgColor: Colors.black.withValues(alpha: 0.06),
                          cardBgColor: const Color(0xFFECFDF5),
                        );

                        final cardSugar = MetricCard(
                          title: 'Sugar (Extra)',
                          value: state.result != null ? Formatters.formatDecimal(state.result!.sugarRequired) : '—',
                          unit: 'kg',
                          subtitle: state.result != null
                              ? (state.result!.sugarRequired > 0
                                  ? '${state.result!.sugarPercent.toStringAsFixed(1)}% Added Extra'
                                  : 'Unsweetened')
                              : 'Added sugar',
                          icon: Icons.cookie_rounded,
                          iconColor: Colors.black.withValues(alpha: 0.60),
                          iconBgColor: Colors.black.withValues(alpha: 0.06),
                          cardBgColor: const Color(0xFFF5F3FF),
                        );

                        if (constraints.maxWidth >= 550) {
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: cardMilk),
                                const SizedBox(width: 12),
                                Expanded(child: cardSmp),
                                const SizedBox(width: 12),
                                Expanded(child: cardWater),
                                const SizedBox(width: 12),
                                Expanded(child: cardSugar),
                              ],
                            ),
                          );
                        } else {
                          final itemWidth = (constraints.maxWidth - 12) / 2;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(width: itemWidth, child: cardMilk),
                              SizedBox(width: itemWidth, child: cardSmp),
                              SizedBox(width: itemWidth, child: cardWater),
                              SizedBox(width: itemWidth, child: cardSugar),
                            ],
                          );
                        }
                      },
                    ),

                    if (state.result != null && state.result!.warnings.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: state.result!.warnings.map((w) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      w,
                                      style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.semiBold, color: Color(0xFF92400E)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),

                    // Action Buttons: Record Batch Standardization (Green) and Clear (Red)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 640;

                        final recordBtn = ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          ),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                          label: const Text(
                            'Record Batch Standardization',
                            style: TextStyle(fontSize: AppTextSizes.body, fontWeight: AppFontWeights.bold, letterSpacing: 0.3),
                          ),
                          onPressed: _onSaveRecord,
                        );

                        final clearBtn = OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEF2F2),
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          ),
                          onPressed: _onClear,
                          child: const Text(
                            'Clear',
                            style: TextStyle(fontSize: AppTextSizes.body, fontWeight: AppFontWeights.bold),
                          ),
                        );

                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(flex: 3, child: recordBtn),
                              const SizedBox(width: 10),
                              Expanded(flex: 1, child: clearBtn),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              recordBtn,
                              const SizedBox(height: 10),
                              clearBtn,
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Step-by-Step Calculation Breakdown (OUTSIDE the main card)
              if (state.result != null) ...[
                const SizedBox(height: 20),
                CalculationBreakdownCard(
                  title: 'Calculation Breakdown & Formula Details',
                  steps: state.result!.breakdownSteps,
                  initiallyExpanded: false,
                ),
              ],

              // Historical Standardization Records Section
              const SizedBox(height: 32),
              _buildHistorySection(state.history, productionState, state.targetProducts, labState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductDropdown(StandardizationState state) {
    return SearchableDropdown<ProductModel>(
      label: 'Select Product',
      hint: 'Select Product',
      items: state.targetProducts,
      selectedItem: state.selectedTargetProduct,
      itemLabel: (p) => p.productName,
      onChanged: (product) {
        if (product != null) {
          _selectProduct(product);
        }
      },
    );
  }

  Widget _buildProductStandardCard(ProductModel p, StandardizationState state) {
    final bool isCustomized = (double.tryParse(_desiredFatController.text) != null &&
            (double.tryParse(_desiredFatController.text)! - (p.targetFat ?? 3.5)).abs() > 0.001) ||
        (double.tryParse(_desiredSnfController.text) != null &&
            (double.tryParse(_desiredSnfController.text)! - (p.targetSnf ?? 8.5)).abs() > 0.001);

    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _standardsExpanded = !_standardsExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.tune_rounded, size: 15, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${p.productName.toUpperCase()} FORMULATION STANDARD',
                              style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.bold, color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              'Target Fat: ${_desiredFatController.text.isNotEmpty ? _desiredFatController.text : (p.targetFat ?? 3.5)}%  •  Target SNF: ${_desiredSnfController.text.isNotEmpty ? _desiredSnfController.text : (p.targetSnf ?? 8.5)}%${p.targetSugar != null && p.targetSugar! > 0 ? '  •  Sugar: ${p.targetSugar}%' : ''}',
                              style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.semiBold, color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.edit_outlined, size: 13, color: AppColors.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cardBorderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _standardsExpanded ? 'Collapse' : 'Customize Target',
                          style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.bold, color: AppColors.primary),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _standardsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_standardsExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Customize Target Fat & SNF Standards for This Batch',
                        style: TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.bold, color: AppColors.textPrimary),
                      ),
                      if (isCustomized)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.restore_rounded, size: 14, color: AppColors.primary),
                          label: const Text('Reset to Standard', style: TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.bold)),
                          onPressed: () {
                            setState(() {
                              _desiredFatController.text = (p.targetFat ?? 3.5).toStringAsFixed(2);
                              _desiredSnfController.text = (p.targetSnf ?? 8.5).toStringAsFixed(2);
                            });
                            _onCalculate();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Target FAT %',
                          hint: 'e.g. ${p.targetFat ?? 3.5}',
                          controller: _desiredFatController,
                          suffixText: '%',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) {
                            setState(() {});
                            _onCalculate();
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AppTextField(
                          label: 'Target SNF %',
                          hint: 'e.g. ${p.targetSnf ?? 8.5}',
                          controller: _desiredSnfController,
                          suffixText: '%',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) {
                            setState(() {});
                            _onCalculate();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _editRecord(StandardizationRecord item, List<ProductModel> targetProducts) {
    final p = targetProducts.where((prod) => prod.productId == item.targetProductId || prod.productName.toLowerCase() == item.targetProductName.toLowerCase()).firstOrNull;
    if (p != null) {
      _selectProduct(p);
    }
    setState(() {
      _totalBatchController.text = item.totalBatchRequired > 0
          ? Formatters.formatSmart(item.totalBatchRequired)
          : Formatters.formatSmart(item.finalQuantity);
      _milkTakenController.text = Formatters.formatSmart(item.inputMilkQuantity);
      _fatController.text = item.inputFat.toStringAsFixed(2);
      _snfController.text = item.inputSnf.toStringAsFixed(2);
      _desiredFatController.text = item.targetFat.toStringAsFixed(2);
      _desiredSnfController.text = item.targetSnf.toStringAsFixed(2);
      _notesController.text = item.notes;
      _autoCalculateMilk = false;
      _fetchedSiloSource = item.siloId != null ? 'Source: ${item.siloId}' : null;
      _fetchedLabTester = item.testedBy.isNotEmpty ? item.testedBy : null;
    });
    ref.read(standardizationProvider.notifier).setTotalBatch(item.totalBatchRequired > 0 ? item.totalBatchRequired : item.finalQuantity);
    ref.read(standardizationProvider.notifier).setMilkTaken(item.inputMilkQuantity);
    ref.read(standardizationProvider.notifier).setMilkFat(item.inputFat);
    ref.read(standardizationProvider.notifier).setMilkSnf(item.inputSnf);
    ref.read(standardizationProvider.notifier).setTargetFat(item.targetFat);
    ref.read(standardizationProvider.notifier).setTargetSnf(item.targetSnf);
    if (item.siloId != null) {
      ref.read(standardizationProvider.notifier).setSiloId(item.siloId!);
    }
    _onCalculate();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Loaded "${item.targetProductName}" into batch input form for editing.'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getTesterName(StandardizationRecord item, LabState labState) {
    if (item.testedBy.trim().isNotEmpty && item.testedBy.toLowerCase() != 'qc lab') {
      return item.testedBy.trim();
    }
    // Match by silo and date or fat/snf in lab tests
    final match = labState.allTests.where((t) {
      final matchSilo = item.siloId != null && (t.siloId == item.siloId || t.siloName == item.siloId);
      final matchDate = t.testDate == item.date;
      return matchSilo && (matchDate || (t.fatPercentage - item.inputFat).abs() < 0.05);
    }).firstOrNull;

    if (match != null && match.labUserName.trim().isNotEmpty) {
      return match.labUserName.trim();
    }

    final matchAnyFatSnf = labState.allTests.where((t) {
      return (t.fatPercentage - item.inputFat).abs() < 0.05 && (t.snfPercentage - item.inputSnf).abs() < 0.05;
    }).firstOrNull;

    if (matchAnyFatSnf != null && matchAnyFatSnf.labUserName.trim().isNotEmpty) {
      return matchAnyFatSnf.labUserName.trim();
    }

    return item.employeeName.trim().isNotEmpty ? item.employeeName.trim() : 'Lab Analyst';
  }

  Widget _buildHistorySection(
    List<StandardizationRecord> allHistory,
    ProductionState productionState,
    List<ProductModel> targetProducts,
    LabState labState,
  ) {
    final filteredHistory = allHistory.where((item) {
      if (_filterDate != null) {
        if (!_matchesDate(item, _filterDate!)) return false;
      }
      if (_filterProductId != null && _filterProductId!.isNotEmpty) {
        final sel = targetProducts.where((p) => p.productId == _filterProductId).firstOrNull;
        final matchId = item.targetProductId == _filterProductId;
        final matchName = item.targetProductName.toLowerCase() == _filterProductId!.toLowerCase();
        final matchSel = sel != null && (
          item.targetProductName.toLowerCase().contains(sel.productName.toLowerCase()) ||
          item.targetProductName.toLowerCase().contains(sel.shortCode.toLowerCase()) ||
          item.targetProductId == sel.productId
        );
        if (!matchId && !matchName && !matchSel) {
          return false;
        }
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading OUTSIDE of card (matching Product Calculation History style)
        InkWell(
          onTap: () => setState(() => _archiveExpanded = !_archiveExpanded),
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
                      'MILK STANDARDIZATION HISTORY',
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusBadge.info(
                      '${filteredHistory.length} Saved Records',
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.cardBorderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _archiveExpanded ? 'Collapse' : 'Expand',
                            style: const TextStyle(
                              fontSize: AppTextSizes.caption,
                              fontWeight: AppFontWeights.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _archiveExpanded
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
        if (_archiveExpanded) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 4, color: AppColors.primary),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filter Controls (Product, Date)
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildProductFilterChip(targetProducts),
                            _buildDateFilterChip(),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (filteredHistory.isEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.alertLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.alert.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 20,
                                  color: AppColors.alert,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'No standardization records matching current filter.',
                                  style: TextStyle(
                                    color: AppColors.alert,
                                    fontWeight: AppFontWeights.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredHistory.length,
                            separatorBuilder: (_, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = filteredHistory[index];
                              final linkedProd = productionState.findProductionRecordForStandardizationBatch(item);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primary.withValues(alpha: 0.20),
                                          width: 1.1,
                                        ),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: AppFontWeights.bold,
                                          fontSize: AppTextSizes.caption,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // 1. Above: Batch Product Name
                                          Text(
                                            item.targetProductName,
                                            style: const TextStyle(
                                              fontWeight: AppFontWeights.bold,
                                              fontSize: AppTextSizes.body,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),

                                          // 2. Below it: Milk SMP Sugar Water used and then dot total quantity
                                          Text(
                                            'Milk: ${Formatters.formatSmart(item.inputMilkQuantity)} L • SMP: ${Formatters.formatDecimal(item.smpRequired)} kg • Water: ${Formatters.formatDecimal(item.waterRequired)} L • Sugar: ${Formatters.formatDecimal(item.sugarRequired)} kg • Total: ${Formatters.formatSmart(item.finalQuantity > 0 ? item.finalQuantity : item.totalBatchRequired)} L',
                                            style: const TextStyle(
                                              fontSize: AppTextSizes.caption,
                                              fontWeight: AppFontWeights.medium,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),

                                          // 3. Below it: FAT SNF for that batch and dot tested by whom
                                          Text(
                                            'FAT: ${Formatters.formatDecimal(item.targetFat)}% • SNF: ${Formatters.formatDecimal(item.targetSnf)}% • Tested by: ${_getTesterName(item, labState)}',
                                            style: const TextStyle(
                                              fontSize: AppTextSizes.caption,
                                              fontWeight: AppFontWeights.medium,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),

                                          // 4. Below it: Time and Date and dot standardized by whom
                                          Text(
                                            '${item.time} • ${item.date} • Standardized by: ${item.employeeName.isNotEmpty ? item.employeeName : 'Dairy Technologist'}',
                                            style: const TextStyle(
                                              fontSize: AppTextSizes.caption,
                                              fontWeight: AppFontWeights.medium,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          if (linkedProd != null) ...[
                                            const SizedBox(height: 5),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFECFDF5),
                                                borderRadius: BorderRadius.circular(5),
                                                border: Border.all(color: const Color(0xFF86EFAC), width: 1.1),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.inventory_2_outlined, size: 12, color: Color(0xFF059669)),
                                                  const SizedBox(width: 5),
                                                  Flexible(
                                                    child: Text(
                                                      'Linked in Production: ${linkedProd.productName} • ${Formatters.formatSmart(linkedProd.cratesProduced)} Crates (${Formatters.formatInt(linkedProd.piecesProduced)} pcs) • Batch: ${linkedProd.batchNo} • Logged by: ${linkedProd.employeeName}',
                                                      style: const TextStyle(
                                                        fontSize: AppTextSizes.caption,
                                                        fontWeight: AppFontWeights.bold,
                                                        color: Color(0xFF065F46),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ] else ...[
                                            const SizedBox(height: 5),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.06),
                                                borderRadius: BorderRadius.circular(5),
                                                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFF2563EB)),
                                                  SizedBox(width: 5),
                                                  Flexible(
                                                    child: Text(
                                                      'Ready for packaging • Available in Production Register fetch list',
                                                      style: TextStyle(
                                                        fontSize: AppTextSizes.caption,
                                                        fontWeight: AppFontWeights.medium,
                                                        color: Color(0xFF1D4ED8),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          if (item.notes.trim().isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.danger.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.sticky_note_2_rounded, size: 14, color: AppColors.danger),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      'Batch Note: ${item.notes.trim()}',
                                                      style: const TextStyle(
                                                        fontSize: AppTextSizes.caption,
                                                        fontWeight: AppFontWeights.bold,
                                                        color: AppColors.danger,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
                                      tooltip: 'Actions',
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      onSelected: (val) async {
                                        if (val == 'edit') {
                                          _editRecord(item, targetProducts);
                                        } else if (val == 'delete') {
                                          final confirm = await ConfirmationDialog.show(
                                            context: context,
                                            title: 'Delete Standardization Record',
                                            message: 'Are you sure you want to delete ${item.targetProductName} record? This action cannot be undone.',
                                            isDestructive: true,
                                          );
                                          if (confirm) {
                                            ref.read(standardizationProvider.notifier).deleteRecord(item.recordId);
                                          }
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem<String>(
                                          value: 'edit',
                                          height: 38,
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                                              SizedBox(width: 8),
                                              Text(
                                                'Edit Entry',
                                                style: TextStyle(
                                                  fontSize: AppTextSizes.caption,
                                                  fontWeight: AppFontWeights.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuDivider(height: 1),
                                        const PopupMenuItem<String>(
                                          value: 'delete',
                                          height: 38,
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                                              SizedBox(width: 8),
                                              Text(
                                                'Delete Entry',
                                                style: TextStyle(
                                                  fontSize: AppTextSizes.caption,
                                                  fontWeight: AppFontWeights.bold,
                                                  color: AppColors.danger,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateFilterChip() {
    final isToday = _filterDate == null ||
        Formatters.formatDate(_filterDate!) ==
            Formatters.formatDate(DateTime.now());

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _filterDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (picked != null) {
              setState(() {
                _filterDate = picked;
              });
            }
          },
          borderRadius: BorderRadius.circular(9),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.cardBorder, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _filterDate != null
                      ? (isToday
                          ? 'Today (${Formatters.formatDate(_filterDate!)})'
                          : Formatters.formatDate(_filterDate!))
                      : 'Select Date',
                  style: const TextStyle(
                    fontWeight: AppFontWeights.bold,
                    fontSize: AppTextSizes.body,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (!isToday) ...[
          const SizedBox(width: 6),
          InkWell(
            onTap: () => setState(() => _filterDate = DateTime.now()),
            borderRadius: BorderRadius.circular(9),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.replay_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Today',
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
      ],
    );
  }

  Widget _buildProductFilterChip(List<ProductModel> products) {
    final validProducts = products
        .where((p) =>
            p.productName.trim() != '2' &&
            p.productId.trim() != '2' &&
            p.productName.trim().isNotEmpty)
        .toList();
    final isSelectedValid = _filterProductId != null &&
        validProducts.any((p) => p.productId == _filterProductId || p.productName == _filterProductId);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_2_rounded,
            size: 17,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: isSelectedValid ? _filterProductId : '',
              isDense: true,
              icon: const Icon(
                Icons.arrow_drop_down_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              style: const TextStyle(
                fontWeight: AppFontWeights.bold,
                fontSize: AppTextSizes.body,
                color: AppColors.textPrimary,
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('All Products'),
                ),
                ...validProducts.map(
                  (p) => DropdownMenuItem(
                    value: p.productId,
                    child: Text(p.productName),
                  ),
                ),
              ],
              onChanged: (val) {
                setState(() {
                  _filterProductId = (val == null || val.isEmpty) ? null : val;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceSiloSelector(StandardizationState state, LabState labState) {
    final silos = labState.silos.where((s) {
      final id = s.id.toUpperCase();
      return id == 'RMST' || id == 'PMST' || (!id.contains('SILO_1') && !id.contains('SILO_2'));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SOURCE SILO / TANK',
          style: TextStyle(
            fontSize: AppTextSizes.caption,
            fontWeight: AppFontWeights.bold,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 500;
            final children = silos.map((silo) {
              final isSelected = state.selectedSiloId == silo.id;
              final isPmst = silo.id.toUpperCase().contains('PMST');
              final currentStock = isPmst ? labState.pmstStockLitres : labState.rmstStockLitres;
              final hasMilk = currentStock > 0.001;

              final borderColor = Colors.black.withValues(alpha: isSelected ? 0.24 : 0.08);
              final Color bgColor;
              final Color iconColor;
              final Color textColor;
              final Color stockColor;

              if (hasMilk) {
                // Low opacity navy blue
                bgColor = isSelected
                    ? const Color(0xFFE2EDFB) // Richer low opacity navy
                    : const Color(0xFFF0F7FF); // Soft low opacity navy
                iconColor = isSelected
                    ? AppColors.primary
                    : AppColors.primaryLight;
                textColor = isSelected
                    ? AppColors.primaryDark
                    : AppColors.textPrimary;
                stockColor = isSelected
                    ? AppColors.primary
                    : AppColors.primaryLight;
              } else {
                // Low opacity black
                bgColor = Colors.black.withValues(alpha: isSelected ? 0.08 : 0.04);
                iconColor = Colors.black.withValues(alpha: isSelected ? 0.60 : 0.35);
                textColor = Colors.black.withValues(alpha: isSelected ? 0.75 : 0.50);
                stockColor = Colors.black.withValues(alpha: 0.45);
              }

              return InkWell(
                onTap: () {
                  ref.read(standardizationProvider.notifier).setSiloId(silo.id);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: borderColor,
                      width: isSelected ? 1.4 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: hasMilk
                              ? AppColors.primary.withValues(alpha: isSelected ? 0.12 : 0.06)
                              : Colors.black.withValues(alpha: isSelected ? 0.08 : 0.04),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.storage_rounded,
                          color: iconColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${silo.name} (${isPmst ? "Pasteurized Tank" : "Raw Tank"})',
                              style: TextStyle(
                                fontWeight: AppFontWeights.bold,
                                fontSize: AppTextSizes.body,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Current Stock: ${Formatters.formatSmart(currentStock)} L${hasMilk ? "" : " (Empty)"}',
                              style: TextStyle(
                                fontSize: AppTextSizes.caption,
                                fontWeight: isSelected ? AppFontWeights.bold : AppFontWeights.medium,
                                color: stockColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList();

            if (isWide) {
              return Row(
                children: children
                    .map((w) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: w,
                          ),
                        ))
                    .toList(),
              );
            } else {
              return Column(
                children: children
                    .map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: w,
                        ))
                    .toList(),
              );
            }
          },
        ),
      ],
    );
  }
}