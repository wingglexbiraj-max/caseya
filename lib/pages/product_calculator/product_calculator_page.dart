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
import '../../providers/product_calculator_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product_model.dart';
import '../../models/product_calculation_record.dart';

class ProductCalculatorPage extends ConsumerStatefulWidget {
  const ProductCalculatorPage({super.key});

  @override
  ConsumerState<ProductCalculatorPage> createState() => _ProductCalculatorPageState();
}

class _ProductCalculatorPageState extends ConsumerState<ProductCalculatorPage> {
  final TextEditingController _quantityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _historyExpanded = false;
  bool _metadataExpanded = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _onCalculate() {
    if (_formKey.currentState?.validate() ?? false) {
      final qty = Formatters.parseDouble(_quantityController.text);
      ref.read(productCalculatorProvider.notifier).setQuantity(qty);
      ref.read(productCalculatorProvider.notifier).calculate();
    }
  }

  Future<void> _onSave() async {
    final user = ref.read(authProvider);
    final success = await ref.read(productCalculatorProvider.notifier).saveCalculation(
          employeeId: user.employeeCode,
          employeeName: user.name,
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Calculation recorded to plant operational history'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  IconData _getInputModeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'pieces':
      case 'piece':
        return Icons.widgets_outlined;
      case 'crates':
      case 'crate':
        return Icons.all_inbox_rounded;
      case 'litres':
      case 'litre':
      case 'liters':
      case 'liter':
        return Icons.water_drop_rounded;
      case 'kg':
      case 'kgs':
        return Icons.scale_rounded;
      default:
        return Icons.tune_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productCalculatorProvider);
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
              // Page Title & Header
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
                            'Product Calculator',
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
                        'Instant plant conversions: Total Pieces, Packing Needed, Total Quantity, and Commercial Price.',
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

              // Feedback alerts
              if (state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

              // Golden Ratio Layout: 61.8% Input Controls vs 38.2% Metadata
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 880;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Calculation Controls Form (Flex 62)
                      Expanded(
                        flex: isWide ? 62 : 100,
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                    'INPUT SPECIFICATIONS',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Product Selection Dropdown
                              SearchableDropdown<ProductModel>(
                                label: 'Product',
                                hint: 'Select product from plant catalog...',
                                items: state.products,
                                selectedItem: state.selectedProduct,
                                itemLabel: (p) => p.productName,
                                onChanged: (product) {
                                  if (product != null) {
                                    ref.read(productCalculatorProvider.notifier).selectProduct(product);
                                  }
                                },
                              ),
                              const SizedBox(height: 16),

                              // Dynamic Input Mode Selection
                              if (state.selectedProduct != null) ...[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Input Mode',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(Allowed: ${state.selectedProduct!.allowedInputModes.join(', ')})',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: state.selectedProduct!.allowedInputModes.map((mode) {
                                        final isSelected = state.selectedInputMode == mode;
                                        return ChoiceChip(
                                          avatar: Icon(
                                            _getInputModeIcon(mode),
                                            size: 16,
                                            color: isSelected ? Colors.white : AppColors.textSecondary,
                                          ),
                                          label: Text(mode),
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
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                            color: isSelected ? Colors.white : AppColors.textSecondary,
                                          ),
                                          onSelected: (selected) {
                                            if (selected) {
                                              ref.read(productCalculatorProvider.notifier).setInputMode(mode);
                                            }
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Quantity Input
                              AppTextField(
                                label: 'Enter Quantity',
                                hint: 'e.g. 150',
                                controller: _quantityController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                suffixText: state.selectedInputMode,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter a quantity';
                                  }
                                  final n = Formatters.parseDouble(val);
                                  if (n <= 0) return 'Quantity must be greater than zero';
                                  return null;
                                },
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
                                  label: const Text('Calculate'),
                                  onPressed: _onCalculate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (isWide) const SizedBox(width: 20),

                      // Product Metadata Card (Flex 38)
                      if (isWide && state.selectedProduct != null)
                        Expanded(
                          flex: 38,
                          child: _buildMetadataCard(state.selectedProduct!),
                        ),
                    ],
                  );
                },
              ),

              // Mobile Metadata Card underneath
              if (isMobile && state.selectedProduct != null) ...[
                const SizedBox(height: 16),
                _buildMetadataCard(state.selectedProduct!),
              ],

              // Results Section
              if (state.result != null) ...[
                const SizedBox(height: 24),

                // Primary Results Card
                ResultCard(
                  title: 'CALCULATION RESULT',
                  subtitle: state.result!.productNameWithQuantity,
                  trailingAction: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Save Record', style: TextStyle(fontSize: 12.5)),
                    onPressed: _onSave,
                  ),
                  items: [
                    ResultItem(
                      label: 'Total Pieces Required',
                      value: Formatters.formatInt(state.result!.pieces),
                      unit: 'Pieces',
                      subtitle: 'Pack size: ${state.selectedProduct?.packSizeDisplay}',
                      highlightColor: AppColors.primary,
                    ),
                    ResultItem(
                      label: 'Packing Needed',
                      value: Formatters.formatSmart(state.result!.crates),
                      unit: 'Crates',
                      subtitle: state.result!.packingBreakdown,
                      highlightColor: AppColors.primaryDark,
                    ),
                    ResultItem(
                      label: 'Total Quantity',
                      value: Formatters.formatSmart(state.result!.totalQuantity),
                      unit: state.selectedProduct?.baseUnitLabel ?? 'kg',
                      subtitle: state.result!.totalQuantityDisplay,
                      highlightColor: AppColors.accentCyanDeep,
                    ),
                    ResultItem(
                      label: 'Total Price',
                      value: state.result!.totalPriceDisplay,
                      unit: 'INR',
                      subtitle: '@ ₹${Formatters.formatSmart(state.result!.pricePerPiece)} / piece',
                      highlightColor: AppColors.goldAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Collapsible Calculation Breakdown Card (Collapsed by default)
                CalculationBreakdownCard(
                  title: 'Calculation Breakdown & Formula Details',
                  steps: state.result!.breakdownSteps,
                  initiallyExpanded: false,
                ),
              ],

              // Recent Calculations History
              const SizedBox(height: 32),
              _buildHistorySection(state.history),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataCard(ProductModel product) {
    return AppCard(
      backgroundColor: const Color(0xFFF9FBFA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _metadataExpanded = !_metadataExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
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
            const SizedBox(height: 14),
            Container(
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

  Widget _buildHistorySection(List<ProductCalculationRecord> history) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.alert.withValues(alpha: 0.25)),
        ),
        child: const Column(
          children: [
            Icon(Icons.inbox_outlined, size: 36, color: AppColors.alert),
            SizedBox(height: 8),
            Text(
              'No previous product calculation records yet.',
              style: TextStyle(color: AppColors.alert, fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _historyExpanded = !_historyExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
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
                        'RECENT PRODUCT CALCULATIONS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      StatusBadge.info('${history.length} Saved Records'),
                      const SizedBox(width: 8),
                      Icon(
                        _historyExpanded
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
          if (_historyExpanded) ...[
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length.clamp(0, 5),
              separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = history[index];
              final titleText = item.productNameWithQuantity.isNotEmpty
                  ? item.productNameWithQuantity
                  : '${item.productName} — ${Formatters.formatSmart(item.inputQuantity)} ${item.inputMode}';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                title: Text(
                  titleText,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                subtitle: Text(
                  '${item.date} • ${item.time} • ${item.employeeName}\n'
                  'Packing: ${item.packingNeeded.isNotEmpty ? item.packingNeeded : '${Formatters.formatSmart(item.crates)} Crates'} | '
                  'Quantity: ${item.totalQuantityDisplay.isNotEmpty ? item.totalQuantityDisplay : '${Formatters.formatSmart(item.volumeLitres)} L'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${Formatters.formatInt(item.pieces)} pcs',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.primaryDark),
                    ),
                    if (item.totalPriceDisplay.isNotEmpty)
                      Text(
                        item.totalPriceDisplay,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.goldAccent),
                      ),
                  ],
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
