import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/calculation_breakdown.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../providers/standardization_provider.dart';
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
  final TextEditingController _totalBatchController = TextEditingController(text: '1700');
  final TextEditingController _milkTakenController = TextEditingController(text: '1400');
  final TextEditingController _fatController = TextEditingController(text: '4.3');
  final TextEditingController _snfController = TextEditingController(text: '8.33');
  final TextEditingController _desiredFatController = TextEditingController(text: '3.5');
  final TextEditingController _desiredSnfController = TextEditingController(text: '8.5');
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
      _totalBatchController.text = '1700';
      _milkTakenController.text = '1400';
      _fatController.text = '4.3';
      _snfController.text = '8.33';
      final defaultProduct = ref.read(standardizationProvider).selectedTargetProduct;
      _desiredFatController.text = (defaultProduct?.targetFat ?? 3.5).toStringAsFixed(2);
      _desiredSnfController.text = (defaultProduct?.targetSnf ?? 8.5).toStringAsFixed(2);
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Select a milk silo / storage tank to populate lab tested values',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
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
                                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
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
                                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.danger),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (hasReading)
                                  Text(
                                    'Fat ${reading.fatPercentage.toStringAsFixed(2)}%  •  SNF ${reading.snfPercentage.toStringAsFixed(2)}%  •  Tested ${reading.testTime}',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                                  )
                                else
                                  Text(
                                    silo.description,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
    final user = ref.read(authProvider);
    final success = await ref.read(standardizationProvider.notifier).saveRecord(
          employeeId: user.employeeCode,
          employeeName: user.name,
          notes: _notesController.text.trim(),
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Standardization record saved and linked to Batch Records section.'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final current = ref.read(standardizationProvider).selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      ref.read(standardizationProvider.notifier).setDate(picked);
    }
  }

  void _openFormulaSettingsDialog() {
    final state = ref.read(standardizationProvider);
    final smpController = TextEditingController(text: state.smpFactor.toStringAsFixed(1));
    String waterMethod = state.waterCalculationMethod;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Standardization Formula Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure plant standard SMP factor, water calculation model, and default product solid targets.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),

                  // Configurable SMP Factor
                  const Text(
                    'SMP SNF Contribution Factor (%)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: smpController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'e.g. 95.0',
                      suffixText: '%',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      helperText: 'Standard plant default: 95.0% SNF contribution',
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Water calculation method
                  const Text(
                    'Water Requirement Formula Model',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setDialogState(() => waterMethod = 'standard'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  waterMethod == 'standard' ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: waterMethod == 'standard' ? AppColors.primary : AppColors.textMuted,
                                  size: 19,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Standard Plant Model (Recommended)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                      Text('Water = Total Batch - (Milk Taken + SNF Deficit)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        InkWell(
                          onTap: () => setDialogState(() => waterMethod = 'withSugarDisplacement'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  waterMethod == 'withSugarDisplacement' ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: waterMethod == 'withSugarDisplacement' ? AppColors.primary : AppColors.textMuted,
                                  size: 19,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('With Sugar Displacement Volume', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                      Text('Water = Total Batch - (Milk Taken + SNF Deficit + (Sugar × 0.63))', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Product Solid Standards Table
                  const Text(
                    'Active Product Target Formulation Standards',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: state.targetProducts.map((p) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(p.productName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('FAT: ${p.targetFat ?? 0}%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('SNF: ${p.targetSnf ?? 8.5}%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Sugar: ${p.targetSugarDisplay}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              ),
              onPressed: () {
                final smpVal = Formatters.parseDouble(smpController.text);
                if (smpVal > 50 && smpVal <= 100) {
                  ref.read(standardizationProvider.notifier).setSmpFactor(smpVal);
                }
                ref.read(standardizationProvider.notifier).setWaterMethod(waterMethod);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Formulation parameters updated and applied.'),
                    backgroundColor: AppColors.primary,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Save & Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(standardizationProvider);
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
              // Header Section with Title & Settings Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Milk Standardization Calculator',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Batch formulation engine: Calculate required SMP, Sugar, and Water from available milk FAT and SNF.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: const BorderSide(color: AppColors.cardBorder),
                        ),
                        icon: const Icon(Icons.settings_outlined, size: 16, color: AppColors.primary),
                        label: const Text('Formula Master', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        onPressed: _openFormulaSettingsDialog,
                      ),
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                Formatters.formatDate(state.selectedDate),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

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
                            fontSize: 12.5,
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
                          style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Main Formulation Input Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                'INPUTS & FORMULATION PARAMETERS',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            side: const BorderSide(color: AppColors.primary, width: 1.2),
                          ),
                          icon: const Icon(Icons.biotech_rounded, size: 17, color: AppColors.primary),
                          label: const Text('Fetch Lab Fat & SNF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          onPressed: _openFetchLabSiloDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 1. Product Selection
                    _buildTargetProductChips(state),

                    // Product Formulation Standard Card (Collapsible & Customizable)
                    if (state.selectedTargetProduct != null)
                      _buildProductStandardCard(state.selectedTargetProduct!, state),

                    const SizedBox(height: 20),

                    // 2. Batch Volumes: Total Batch Required & Milk Taken
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
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
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
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
                                  if (val == null || val.trim().isEmpty) return 'Enter quantity or enable auto-calculate';
                                  final n = Formatters.parseDouble(val);
                                  if (n <= 0) return 'Must be greater than 0';
                                  final total = Formatters.parseDouble(_totalBatchController.text);
                                  if (total > 0 && n > total) return 'Cannot exceed Total Batch';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _autoCalculateMilk,
                                      activeColor: AppColors.primary,
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
                                  Expanded(
                                    child: GestureDetector(
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
                                      child: const Text(
                                        'Auto-calculate milk required from target fat',
                                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Present Milk Fat & SNF Header with Source indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PRESENT MILK FAT & SNF',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.biotech_rounded, size: 16, color: AppColors.primary),
                          label: const Text(
                            'Fetch Lab Fat & SNF',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                          onPressed: _openFetchLabSiloDialog,
                        ),
                      ],
                    ),
                    if (_fetchedSiloSource != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF16A34A)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _fetchedSiloSource!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _fetchedSiloSource = null;
                                });
                                ref.read(standardizationProvider.notifier).clearLabDataStatus();
                              },
                              child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF166534)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ] else
                      const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Present Milk FAT %',
                            hint: 'e.g. 4.30',
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
                            hint: 'e.g. 8.33',
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

                    // Action Buttons Row: Calculate, Clear, Save
                    Row(
                      children: [
                        // Calculate Button
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.calculate_rounded, size: 21),
                            label: const Text(
                              'Calculate',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            onPressed: _onCalculate,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Clear Button
                        Expanded(
                          flex: 1,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 19, color: AppColors.textSecondary),
                            label: const Text(
                              'Clear',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                            ),
                            onPressed: _onClear,
                          ),
                        ),

                        // Save Calculation Button
                        if (state.result != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.save_rounded, size: 19),
                              label: const Text(
                                'Save Calculation',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                              onPressed: _onSaveRecord,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Standardization Result Card Section
              if (state.result != null) ...[
                const SizedBox(height: 24),
                _buildStandardizationResultCard(state),
                const SizedBox(height: 16),

                // Step-by-Step Calculation Breakdown
                CalculationBreakdownCard(
                  title: 'Step-by-Step Mathematical Calculation Breakdown',
                  steps: state.result!.breakdownSteps,
                ),
              ],

              // Historical Standardization Records Section
              const SizedBox(height: 32),
              _buildHistorySection(state.history),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetProductChips(StandardizationState state) {
    final allProducts = state.targetProducts;
    final selected = state.selectedTargetProduct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Product / Batch Type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: allProducts.map((p) => _buildProductChip(p, selected)).toList(),
        ),
      ],
    );
  }

  Widget _buildProductChip(ProductModel p, ProductModel? selected) {
    final isSelected = selected?.productId == p.productId;
    return InkWell(
      onTap: () => _selectProduct(p),
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F7FF) : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  p.productName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Fat: ${p.targetFat ?? 0}% • SNF: ${p.targetSnf ?? 0}%${p.targetSugar != null && p.targetSugar! > 0 ? ' • Sugar: ${p.targetSugar}%' : ''}',
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primaryDark.withValues(alpha: 0.8) : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductStandardCard(ProductModel p, StandardizationState state) {
    final currentTargetFat = Formatters.parseDouble(_desiredFatController.text);
    final currentTargetSnf = Formatters.parseDouble(_desiredSnfController.text);
    final isCustomized = (currentTargetFat > 0 && currentTargetFat != (p.targetFat ?? 3.5)) ||
        (currentTargetSnf > 0 && currentTargetSnf != (p.targetSnf ?? 8.5));

    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCustomized ? AppColors.goldAccent.withValues(alpha: 0.6) : AppColors.cardBorder,
          width: isCustomized ? 1.5 : 1.0,
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
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                            ),
                            if (isCustomized) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.goldAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.4)),
                                ),
                                child: const Text(
                                  'CUSTOMIZED',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.goldAccent),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Target Fat: ${_desiredFatController.text.isNotEmpty ? _desiredFatController.text : (p.targetFat ?? 3.5)}%  •  Target SNF: ${_desiredSnfController.text.isNotEmpty ? _desiredSnfController.text : (p.targetSnf ?? 8.5)}%${p.targetSugar != null && p.targetSugar! > 0 ? '  •  Sugar: ${p.targetSugar}%' : ''}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
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
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      if (isCustomized)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.restore_rounded, size: 14, color: AppColors.primary),
                          label: const Text('Reset to Standard', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
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
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title & Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                              'STANDARDIZATION RESULT',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      StatusBadge.info(
                        state.selectedTargetProduct?.productName ?? 'Standardized Batch',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Target Batch: ${Formatters.formatSmart(res.totalBatch)} L • Milk Taken: ${Formatters.formatDecimal(res.milkTaken)} L',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.save_rounded, size: 16, color: Colors.white),
                label: const Text('Save Record', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                onPressed: _onSaveRecord,
              ),
            ],
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
          const SizedBox(height: 20),

          // Detailed Specifications Grid
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultDataRow('Target Batch', '${Formatters.formatSmart(res.totalBatch)} L', 'Milk Taken', '${Formatters.formatDecimal(res.milkTaken)} L', isHeader: true),
                if (res.reserveVolume > 0) ...[
                  const Divider(height: 1),
                  _buildResultDataRow(
                    'Formulated Base (Milk+SMP+Water)',
                    '${Formatters.formatDecimal(res.totalFormulatedQuantity)} L',
                    'Process Inoculum / Buffer Reserve',
                    '-${Formatters.formatDecimal(res.reserveVolume)} L (${((res.reserveVolume / res.totalBatch) * 100).toStringAsFixed(2)}%)',
                    highlightFirst: true,
                  ),
                ],
                const Divider(height: 1),
                _buildResultDataRow('Present Fat', '${Formatters.formatDecimal(res.presentFat)}%', 'Present SNF', '${Formatters.formatDecimal(res.presentSnf)}%'),
                const Divider(height: 1),
                _buildResultDataRow('Available Fat', '${Formatters.formatDecimal(res.availableFatKg)} kg', 'Final Fat %', '${Formatters.formatDecimal(res.finalFat)}%'),
                const Divider(height: 1),
                _buildResultDataRow('Available SNF', '${Formatters.formatDecimal(res.availableSnfKg)} kg', 'Required SNF', '${Formatters.formatDecimal(res.requiredSnfKg)} kg'),
                const Divider(height: 1),
                _buildResultDataRow('SNF Deficit', '${Formatters.formatDecimal(res.snfDeficitKg)} kg', 'SMP Required', '${Formatters.formatDecimal(res.smpRequired)} kg', highlightSecond: true),
                const Divider(height: 1),
                _buildResultDataRow('Water Required', '${Formatters.formatDecimal(res.waterRequired)} L', 'Base Batch (Milk+SMP+Water)', '${Formatters.formatDecimal(res.totalFormulatedQuantity)} L (Verified)', highlightSecond: true),
                if (res.sugarRequired > 0) ...[
                  const Divider(height: 1),
                  _buildResultDataRow('Sugar Addition (Extra)', '${Formatters.formatDecimal(res.sugarRequired)} kg', 'Final Recipe Batch (with Sugar)', '${Formatters.formatDecimal(res.quantityWithSugar)} L/kg'),
                ],
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
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
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
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultDataRow(
    String label1,
    String val1,
    String label2,
    String val2, {
    bool isHeader = false,
    bool highlightFirst = false,
    bool highlightSecond = false,
  }) {
    return Container(
      color: isHeader ? AppColors.background : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label1, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                Text(
                  val1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: highlightFirst ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label2, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                Text(
                  val2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: highlightSecond ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(List history) {
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
                                fontSize: 11.5,
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
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
                            fontSize: 11.5,
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
                      style: TextStyle(color: AppColors.alert, fontSize: 13.5, fontWeight: FontWeight.w700),
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
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Row(
                      children: [
                        Text(
                          '${item.targetProductName} (${Formatters.formatSmart(item.finalQuantity)} L)',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Batch Record Synced', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${item.date} • ${item.time} • Operator: ${item.employeeName}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Raw: ${Formatters.formatSmart(item.inputMilkQuantity)} L (${item.inputFat}% F, ${item.inputSnf}% SNF) → SMP: ${Formatters.formatDecimal(item.smpRequired)} kg, Water: ${Formatters.formatDecimal(item.waterRequired)} L, Sugar: ${Formatters.formatDecimal(item.sugarRequired)} kg',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                        ),
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
                                      fontSize: 12,
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
