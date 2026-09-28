import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/searchable_dropdown.dart';
import '../../core/widgets/result_card.dart';
import '../../core/widgets/calculation_breakdown.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../providers/standardization_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product_model.dart';

class MilkStandardizationPage extends ConsumerStatefulWidget {
  const MilkStandardizationPage({super.key});

  @override
  ConsumerState<MilkStandardizationPage> createState() => _MilkStandardizationPageState();
}

class _MilkStandardizationPageState extends ConsumerState<MilkStandardizationPage> {
  final TextEditingController _milkQtyController = TextEditingController(text: '5000');
  final TextEditingController _fatController = TextEditingController(text: '3.8');
  final TextEditingController _snfController = TextEditingController(text: '8.4');
  final TextEditingController _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _metadataExpanded = false;

  void _selectProduct(ProductModel product) {
    setState(() {
      _metadataExpanded = false;
    });
    ref.read(standardizationProvider.notifier).selectTargetProduct(product);
  }

  @override
  void dispose() {
    _milkQtyController.dispose();
    _fatController.dispose();
    _snfController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onCalculate() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(standardizationProvider.notifier).setMilkQuantity(Formatters.parseDouble(_milkQtyController.text));
      ref.read(standardizationProvider.notifier).setMilkFat(Formatters.parseDouble(_fatController.text));
      ref.read(standardizationProvider.notifier).setMilkSnf(Formatters.parseDouble(_snfController.text));
      ref.read(standardizationProvider.notifier).calculate();
    }
  }

  Future<void> _onFetchLabData() async {
    final hasUserInputs = _milkQtyController.text != '5000' || _fatController.text != '3.8';
    if (hasUserInputs) {
      final confirm = await ConfirmationDialog.show(
        context: context,
        title: 'Overwrite With Lab Data?',
        message: 'This will replace your current manual milk quantity, FAT%, and SNF% with verified morning QC lab test results.',
        confirmLabel: 'Fetch & Overwrite',
      );
      if (!confirm) return;
    }

    await ref.read(standardizationProvider.notifier).fetchTodayLabData();
    final updated = ref.read(standardizationProvider);
    if (updated.hasFetchedLabData && updated.fetchedLabRecord != null) {
      setState(() {
        _milkQtyController.text = Formatters.formatSmart(updated.fetchedLabRecord!.milkQuantity);
        _fatController.text = updated.fetchedLabRecord!.fatPercent.toStringAsFixed(2);
        _snfController.text = updated.fetchedLabRecord!.snfPercent.toStringAsFixed(2);
      });
    }
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
          content: Text('✓ Standardization record saved to plant historical archive.'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
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
              // Header
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
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Milk Standardization',
                            style: TextStyle(
                              fontSize: 23, // Golden ratio headline
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Calculate exact SMP, Water, and Sugar required to standardize raw milk to target specifications.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Lab Data Status Banner
              if (state.labDataFetchStatus != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: state.hasFetchedLabData ? AppColors.successLight : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: state.hasFetchedLabData
                          ? AppColors.primary.withOpacity(0.3)
                          : AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.hasFetchedLabData ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        color: state.hasFetchedLabData ? AppColors.primary : AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.labDataFetchStatus!,
                          style: TextStyle(
                            color: state.hasFetchedLabData ? AppColors.primaryDark : const Color(0xFF92400E),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Unified Raw Milk Intake & Target Standardization Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'RAW MILK INTAKE & TARGET SETUP',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.cardBorderSubtle),
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
                    const SizedBox(height: 16),

                    // Fetch Lab Data Action
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        side: const BorderSide(color: AppColors.primary, width: 1.3),
                      ),
                      icon: const Icon(Icons.biotech_rounded, size: 19, color: AppColors.primary),
                      label: const Text('Fetch Today\'s Lab Data'),
                      onPressed: _onFetchLabData,
                    ),
                    const SizedBox(height: 18),

                    // Milk Quantity
                    AppTextField(
                      label: 'Milk Quantity',
                      hint: 'e.g. 5000',
                      controller: _milkQtyController,
                      suffixText: 'Litres',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Milk quantity cannot be empty';
                        final n = Formatters.parseDouble(val);
                        if (n <= 0) return 'Must be greater than zero';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Milk Fat & SNF Row
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Milk FAT %',
                            hint: 'e.g. 3.8',
                            controller: _fatController,
                            suffixText: '%',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Required';
                              final n = Formatters.parseDouble(val);
                              if (n <= 0 || n > 15.0) return '0.1 - 15.0%';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: AppTextField(
                            label: 'Milk SNF %',
                            hint: 'e.g. 8.4',
                            controller: _snfController,
                            suffixText: '%',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Required';
                              final n = Formatters.parseDouble(val);
                              if (n <= 0 || n > 16.0) return '5.0 - 16.0%';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Target Product Selection Chips (Below Milk FAT & SNF)
                    _buildTargetProductChips(state),

                    // Product Metadata Card (Collapsed by default, opens on click)
                    if (state.selectedTargetProduct != null)
                      _buildMetadataCard(state.selectedTargetProduct!),

                    const SizedBox(height: 20),

                    // Optional Batch Notes
                    AppTextField(
                      label: 'Batch Notes / Tanker Ref (Optional)',
                      hint: 'e.g. Silo 02 batch for evening run',
                      controller: _notesController,
                    ),
                    const SizedBox(height: 22),

                    // Calculate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.calculate_rounded, size: 20),
                        label: const Text(
                          'Calculate Standardization Result',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        onPressed: _onCalculate,
                      ),
                    ),
                  ],
                ),
              ),

              // Standardization Result Section
              if (state.result != null) ...[
                const SizedBox(height: 24),
                ResultCard(
                  title: 'Standardization Result',
                  subtitle: 'Target: ${state.selectedTargetProduct?.productName} • Raw Milk: ${Formatters.formatSmart(state.milkQuantity)} L',
                  trailingAction: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Save Record', style: TextStyle(fontSize: 12.5)),
                    onPressed: _onSaveRecord,
                  ),
                  items: [
                    ResultItem(
                      label: 'Water Required',
                      value: Formatters.formatSmart(state.result!.waterRequired),
                      unit: 'Litres',
                      highlightColor: state.result!.waterRequired > 0 ? AppColors.coolIce : AppColors.textPrimary,
                    ),
                    ResultItem(
                      label: 'SMP Required',
                      value: Formatters.formatSmart(state.result!.smpRequired),
                      unit: 'Kg',
                      highlightColor: state.result!.smpRequired > 0 ? AppColors.goldAccent : AppColors.textPrimary,
                    ),
                    ResultItem(
                      label: 'Sugar Required',
                      value: Formatters.formatSmart(state.result!.sugarRequired),
                      unit: 'Kg',
                      highlightColor: state.result!.sugarRequired > 0 ? AppColors.accentTeal : AppColors.textPrimary,
                    ),
                    ResultItem(
                      label: 'Final Milk Quantity',
                      value: Formatters.formatSmart(state.result!.finalQuantity),
                      unit: 'Litres',
                      highlightColor: AppColors.primary,
                      subtitle: 'FAT: ${Formatters.formatDecimal(state.result!.finalFat)}% • SNF: ${Formatters.formatDecimal(state.result!.finalSnf)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Step-by-Step Mathematical Calculation Breakdown
                CalculationBreakdownCard(
                  title: 'View Step-by-Step Calculation',
                  steps: state.result!.breakdownSteps,
                ),
              ],

              // Historical Standardization Records
              const SizedBox(height: 32),
              _buildHistorySection(state.history),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetProductChips(dynamic state) {
    final targets = state.targetProducts as List<ProductModel>;
    final selected = state.selectedTargetProduct as ProductModel?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Target Product',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (selected != null)
              Text(
                'Specs: FAT ${selected.targetFat ?? 0.0}% • SNF ${selected.targetSnf ?? 0.0}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: targets.map((p) {
            final isSelected = selected?.productId == p.productId;
            return ChoiceChip(
              selected: isSelected,
              label: Text(p.productName),
              avatar: isSelected
                  ? const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white)
                  : const Icon(Icons.radio_button_unchecked_rounded, size: 15, color: AppColors.textSecondary),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.cardBorder,
                width: isSelected ? 1.5 : 1.0,
              ),
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              elevation: isSelected ? 2 : 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              onSelected: (_) => _selectProduct(p),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetadataCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _metadataExpanded = !_metadataExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'PRODUCT SPECIFICATIONS & METADATA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      StatusBadge.neutral(product.category),
                      const SizedBox(width: 8),
                      Icon(
                        _metadataExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_metadataExpanded) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder, width: 1.1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildTabulatedRow('Item Code', product.itemCode, isEven: false),
                  const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                  _buildTabulatedRow('Product Code', product.productCode, isEven: true, valueColor: AppColors.primary),
                  const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                  _buildTabulatedRow('Pieces per Crate', '${product.piecesPerCrate} pcs / crate', isEven: false),
                  const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                  _buildTabulatedRow('Per Crate Quantity', product.calculatedPerCrateDisplay, isEven: true),
                  const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                  _buildTabulatedRow('Price per Piece', product.priceDisplay, isEven: false, valueColor: AppColors.goldAccent),
                  const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                  _buildTabulatedRow('Pack Size', product.packSizeDisplay, isEven: true),
                  const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                  _buildTabulatedRow('Shelf Life', product.shelfLife, isEven: false),
                  const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                  _buildTabulatedRow('Base Unit', product.baseUnitLabel, isEven: true),
                  const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                  _buildTabulatedRow(
                    'Target FAT / SNF',
                    'FAT: ${product.targetFat != null ? Formatters.formatPercent(product.targetFat!) : '—'}   •   SNF: ${product.targetSnf != null ? Formatters.formatPercent(product.targetSnf!) : '—'}',
                    isEven: false,
                    valueColor: AppColors.primaryDark,
                  ),
                  const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                  _buildTabulatedRow('Allowed Modes', product.allowedInputModes.join(' • '), isEven: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabulatedRow(
    String label,
    String value, {
    required bool isEven,
    Color? valueColor,
  }) {
    return Container(
      color: isEven ? const Color(0xFFFBFDFD) : Colors.white,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Cell: Spec / Parameter Label with subtle distinct background
            Container(
              width: 145,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
              color: isEven ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            // Vertical Divider
            Container(
              width: 1,
              color: AppColors.cardBorder,
            ),
            // Right Cell: Technical Value
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(List history) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: const [
            Icon(Icons.history_rounded, size: 36, color: AppColors.textMuted),
            SizedBox(height: 8),
            Text(
              'No previous standardization records found.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'DATE-WISE STANDARDIZATION LOGS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              StatusBadge.info('${history.length} Batches Logged'),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length.clamp(0, 6),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = history[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                title: Text(
                  '${item.targetProductName} (${Formatters.formatSmart(item.finalQuantity)} L)',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: Text(
                  '${item.date} • ${item.time} • ${item.employeeName}\n'
                  'Raw: ${Formatters.formatSmart(item.inputMilkQuantity)} L (F: ${item.inputFat}% S: ${item.inputSnf}%) → Water: ${Formatters.formatSmart(item.waterRequired)} L, SMP: ${Formatters.formatSmart(item.smpRequired)} Kg',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
      ),
    );
  }
}
