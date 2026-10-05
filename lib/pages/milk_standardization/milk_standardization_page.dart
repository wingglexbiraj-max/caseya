import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/searchable_dropdown.dart';
import '../../core/widgets/calculation_breakdown.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../providers/standardization_provider.dart';
import '../../providers/production_provider.dart';
import '../../providers/batch_records_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product_model.dart';
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
  }

  void _onCalculate() {
    if (_formKey.currentState?.validate() ?? false) {
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

      notifier.calculate();
    }
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
                borderRadius: BorderRadius.circular(8),
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
                    style: TextStyle(fontSize: AppTextSizes.subheading, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Select a milk silo / storage tank to populate lab tested values',
                    style: TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
                      });

                      ref.read(standardizationProvider.notifier).applyLabReading(
                            siloName: reading.siloName,
                            testTime: reading.testTime,
                            fat: reading.fatPercentage,
                            snf: reading.snfPercentage,
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
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: AppTextSizes.body),
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
                                          style: TextStyle(fontSize: AppTextSizes.caption, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
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
                                          style: TextStyle(fontSize: AppTextSizes.caption, fontWeight: FontWeight.w800, color: AppColors.danger),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (hasReading)
                                  Text(
                                    'Fat ${reading.fatPercentage.toStringAsFixed(2)}%  •  SNF ${reading.snfPercentage.toStringAsFixed(2)}%  •  Tested ${reading.testTime}',
                                    style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
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
    );

    if (success && mounted) {
      // Refresh Production Register and Batch Records immediately
      ref.read(productionProvider.notifier).reloadStandardizationBatches();
      ref.read(batchRecordsProvider.notifier).loadBatches();

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
                            fontWeight: FontWeight.w700,
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
                          style: const TextStyle(color: AppColors.danger, fontSize: AppTextSizes.body, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Section Heading OUTSIDE Card
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.science_rounded, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'BATCH MAKING INPUT',
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

              // Main Formulation Input Card with blue header
              AppCard(
                topBorderColor: AppColors.primary,
                topBorderHeight: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Product Selection Dropdown
                    _buildProductDropdown(state),

                    // Product Formulation Standard Card (Collapsible & Customizable)
                    if (state.selectedTargetProduct != null)
                      _buildProductStandardCard(state.selectedTargetProduct!, state),

                    const SizedBox(height: 20),

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
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Auto-calculate milk required from target fat',
                                      style: TextStyle(
                                        fontSize: AppTextSizes.caption,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
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
                                    fontWeight: FontWeight.w700,
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

                    // 4. Batch Notes (Optional)
                    AppTextField(
                      label: 'Batch Notes / Tanker Reference (Optional)',
                      hint: 'e.g. Silo 03, Evening incubation batch, Tanker 04...',
                      controller: _notesController,
                    ),
                    const SizedBox(height: 22),

                    // Action Buttons: Record Batch Standardization, Calculate, and Clear
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
                            style: TextStyle(fontSize: AppTextSizes.body, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                          ),
                          onPressed: _onSaveRecord,
                        );

                        final calculateBtn = ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          ),
                          icon: const Icon(Icons.calculate_rounded, size: 20),
                          label: const Text(
                            'Calculate',
                            style: TextStyle(fontSize: AppTextSizes.body, fontWeight: FontWeight.w700),
                          ),
                          onPressed: _onCalculate,
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
                            style: TextStyle(fontSize: AppTextSizes.body, fontWeight: FontWeight.w700),
                          ),
                        );

                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(flex: 3, child: recordBtn),
                              const SizedBox(width: 10),
                              Expanded(flex: 2, child: calculateBtn),
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
                              Row(
                                children: [
                                  Expanded(flex: 2, child: calculateBtn),
                                  const SizedBox(width: 10),
                                  Expanded(flex: 1, child: clearBtn),
                                ],
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Standardization Result Card Section
              if (state.result != null) ...[
                const SizedBox(height: 24),

                // Result Heading OUTSIDE Card
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.analytics_rounded, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'STANDARDIZATION RESULT',
                      style: TextStyle(
                        fontSize: AppTextSizes.subheading,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    StatusBadge.info(
                      state.selectedTargetProduct?.productName ?? 'Standardized Batch',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStandardizationResultCard(state),

                // Save Record Button below result
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                    icon: const Icon(Icons.save_rounded, size: 19),
                    label: const Text(
                      'Record Batch Standardization',
                      style: TextStyle(fontSize: AppTextSizes.body, fontWeight: FontWeight.w800),
                    ),
                    onPressed: _onSaveRecord,
                  ),
                ),
                const SizedBox(height: 16),

                // Step-by-Step Calculation Breakdown
                CalculationBreakdownCard(
                  title: 'Step-by-Step Mathematical Calculation Breakdown',
                  steps: state.result!.breakdownSteps,
                ),
              ],

              // Historical Standardization Records Section
              const SizedBox(height: 32),
              _buildHistorySection(state.history, productionState),
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
                              style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Target Fat: ${_desiredFatController.text.isNotEmpty ? _desiredFatController.text : (p.targetFat ?? 3.5)}%  •  Target SNF: ${_desiredSnfController.text.isNotEmpty ? _desiredSnfController.text : (p.targetSnf ?? 8.5)}%${p.targetSugar != null && p.targetSugar! > 0 ? '  •  Sugar: ${p.targetSugar}%' : ''}',
                          style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
                          style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: FontWeight.w700, color: AppColors.primary),
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
                        style: TextStyle(fontSize: AppTextSizes.caption, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      if (isCustomized)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.restore_rounded, size: 14, color: AppColors.primary),
                          label: const Text('Reset to Standard', style: TextStyle(fontSize: AppTextSizes.caption, fontWeight: FontWeight.w700)),
                          onPressed: () {
                            setState(() {
                              _desiredFatController.text = (p.targetFat ?? 3.5).toStringAsFixed(2);
                              _desiredSnfController.text = (p.targetSnf ?? 8.5).toStringAsFixed(2);
                            });
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
                          onChanged: (_) => setState(() {}),
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
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Target Fat and SNF will be used directly to calculate exact SMP, Water, and Milk allocation for this batch.',
                    style: const TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStandardizationResultCard(StandardizationState state) {
    final res = state.result!;

    return AppCard(
      topBorderColor: AppColors.primary,
      topBorderHeight: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle
          Text(
            'Target Batch: ${Formatters.formatSmart(res.totalBatch)} L • Milk Taken: ${Formatters.formatDecimal(res.milkTaken)} L',
            style: const TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),

          // Primary Formulation Highlights Banner (SMP, Water, Sugar, Total Formulated)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.05),
                  AppColors.coolIceLight.withValues(alpha: 0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.headerBorder),
            ),
            child: Row(
              children: [
                _buildHighlightMetric(
                  label: 'Milk Taken',
                  value: '${Formatters.formatDecimal(res.milkTaken)} L',
                  sub: res.isAutoCalculatedMilk ? 'Auto-Derived' : 'Allocated Milk',
                  color: AppColors.primaryDark,
                  icon: Icons.local_drink_rounded,
                ),
                Container(width: 1.2, height: 48, color: AppColors.headerBorder),
                _buildHighlightMetric(
                  label: 'SMP Required',
                  value: '${Formatters.formatDecimal(res.smpRequired)} kg',
                  sub: '${res.smpFactor.toStringAsFixed(0)}% SNF Factor',
                  color: AppColors.goldAccent,
                  icon: Icons.grain_rounded,
                ),
                Container(width: 1.2, height: 48, color: AppColors.headerBorder),
                _buildHighlightMetric(
                  label: 'Water Required',
                  value: '${Formatters.formatDecimal(res.waterRequired)} L',
                  sub: res.reserveVolume > 0 ? 'Blending (-${Formatters.formatDecimal(res.reserveVolume)}L Reserve)' : 'Process blending water',
                  color: AppColors.primary,
                  icon: Icons.water_drop_rounded,
                ),
                Container(width: 1.2, height: 48, color: AppColors.headerBorder),
                _buildHighlightMetric(
                  label: 'Sugar (Extra)',
                  value: '${Formatters.formatDecimal(res.sugarRequired)} kg',
                  sub: res.sugarRequired > 0 ? '${res.sugarPercent.toStringAsFixed(1)}% Added Extra' : 'Unsweetened',
                  color: AppColors.coolIce,
                  icon: Icons.cookie_rounded,
                ),
              ],
            ),
          ),


          // Any calculation warnings
          if (res.warnings.isNotEmpty) ...[
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
                children: res.warnings.map((w) {
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
                            style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightMetric({
    required String label,
    required String value,
    required String sub,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: AppTextSizes.subheading,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildHistorySection(List history, ProductionState productionState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _archiveExpanded = !_archiveExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 3.5,
                              height: 13,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Text(
                              'STANDARDIZATION & BATCH ARCHIVE',
                              style: TextStyle(
                                fontSize: AppTextSizes.caption,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        history.isEmpty ? '0 Batches' : '${history.length} Batches Recorded',
                        style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: history.isNotEmpty ? AppColors.primaryContainer : AppColors.cardBorderSubtle,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _archiveExpanded ? 'Hide Archive' : 'View Archive',
                          style: TextStyle(
                            fontSize: AppTextSizes.caption,
                            fontWeight: FontWeight.w700,
                            color: history.isNotEmpty ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _archiveExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_archiveExpanded) ...[
            const Divider(height: 1),
            if (history.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 36, color: AppColors.alert),
                    SizedBox(height: 8),
                    Text(
                      'No previous standardization records found.',
                      style: TextStyle(color: AppColors.alert, fontSize: AppTextSizes.body, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length.clamp(0, 10),
                separatorBuilder: (_, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = history[index];
                  final isPrepared = productionState.isStandardizationBatchPrepared(item);
                  final linkedProd = productionState.findProductionRecordForStandardizationBatch(item);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    title: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${item.targetProductName} (${Formatters.formatSmart(item.finalQuantity)} L)',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: AppTextSizes.body),
                        ),
                        if (isPrepared)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0xFF10B981), width: 1.1),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
                                SizedBox(width: 4),
                                Text(
                                  'Already Prepared',
                                  style: TextStyle(
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0xFFD1D5DB), width: 1.1),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.hourglass_empty_rounded, size: 12, color: Color(0xFF6B7280)),
                                SizedBox(width: 4),
                                Text(
                                  'Not Prepared Yet',
                                  style: TextStyle(
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${item.recordId}',
                            style: const TextStyle(
                              fontSize: AppTextSizes.caption,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${item.date} • ${item.time} • Operator: ${item.employeeName}',
                          style: const TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Raw: ${Formatters.formatSmart(item.inputMilkQuantity)} L (${item.inputFat}% F, ${item.inputSnf}% SNF) → SMP: ${Formatters.formatDecimal(item.smpRequired)} kg, Water: ${Formatters.formatDecimal(item.waterRequired)} L, Sugar: ${Formatters.formatDecimal(item.sugarRequired)} kg',
                          style: const TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textSecondary, height: 1.3),
                        ),
                        if (linkedProd != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF86EFAC), width: 1.1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF059669)),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    'Linked in Production: ${linkedProd.productName} • ${Formatters.formatSmart(linkedProd.cratesProduced)} Crates (${Formatters.formatInt(linkedProd.piecesProduced)} pcs) • Batch: ${linkedProd.batchNo} • Logged by: ${linkedProd.employeeName}',
                                    style: const TextStyle(
                                      fontSize: AppTextSizes.caption,
                                      fontWeight: FontWeight.w700,
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
                                Text(
                                  'Ready for packaging • Available in Production Register fetch list',
                                  style: TextStyle(
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1D4ED8),
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
                                      fontWeight: FontWeight.w700,
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
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.textMuted),
                      onPressed: () async {
                        final confirm = await ConfirmationDialog.show(
                          context: context,
                          title: 'Delete Standardization Record',
                          message: 'Are you sure you want to delete batch ${item.recordId}? This action cannot be undone.',
                          isDestructive: true,
                        );
                        if (confirm) {
                          ref.read(standardizationProvider.notifier).deleteRecord(item.recordId);
                        }
                      },
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
