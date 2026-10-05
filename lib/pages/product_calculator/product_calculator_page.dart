import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/dairy_products.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/searchable_dropdown.dart';
import '../../core/widgets/metric_card.dart';
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
  DateTime? _filterDate = DateTime.now();
  String? _filterProductId;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_onQuantityChanged);
  }

  void _onQuantityChanged() {
    final text = _quantityController.text.trim();
    final qty = Formatters.parseDouble(text);
    ref.read(productCalculatorProvider.notifier).setQuantity(qty);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onQuantityChanged);
    _quantityController.dispose();
    super.dispose();
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
                          style: const TextStyle(color: AppColors.danger, fontSize: AppTextSizes.body, fontWeight: AppFontWeights.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Input Specifications Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              Icons.calculate_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'INPUT SPECIFICATIONS',
                            style: TextStyle(
                              fontSize: AppTextSizes.subheading,
                              fontWeight: AppFontWeights.bold,
                              letterSpacing: 0.2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (state.selectedProduct != null)
                        StatusBadge.info(state.selectedProduct!.productName),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Selection Dropdown (Product Chip)
                        SearchableDropdown<ProductModel>(
                          label: 'Product',
                          hint: 'Select Product',
                          items: state.products
                              .where((p) =>
                                  p.productName.trim() != '2' &&
                                  p.productId.trim() != '2' &&
                                  p.productName.trim().isNotEmpty)
                              .toList(),
                          selectedItem: state.selectedProduct,
                          itemLabel: (p) => p.productName,
                          onChanged: (product) {
                            ref.read(productCalculatorProvider.notifier).selectProduct(product);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Collapsible PRODUCT SPECIFICATIONS directly below Product Chip
                        _buildCollapsibleSpecifications(state.selectedProduct),
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
                                      fontSize: AppTextSizes.body,
                                      fontWeight: AppFontWeights.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(Allowed: ${state.selectedProduct!.allowedInputModes.join(', ')})',
                                    style: const TextStyle(
                                      fontSize: AppTextSizes.caption,
                                      color: AppColors.textMuted,
                                      fontWeight: AppFontWeights.medium,
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
                                      fontSize: AppTextSizes.body,
                                      fontWeight: isSelected ? AppFontWeights.bold : AppFontWeights.medium,
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

                        // Quantity Input (Auto-calculates immediately upon typing)
                        AppTextField(
                          label: 'Enter Quantity',
                          hint: 'e.g. 150',
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffixText: state.selectedProduct != null ? state.selectedInputMode : 'Qty',
                          onChanged: (val) {
                            final qty = Formatters.parseDouble(val);
                            ref.read(productCalculatorProvider.notifier).setQuantity(qty);
                          },
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter a quantity';
                            }
                            final n = Formatters.parseDouble(val);
                            if (n <= 0) return 'Quantity must be greater than zero';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Result Chip Cards (styled like Today's Metric Summary)
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
                              'CALCULATION METRICS',
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
                                  '• ${state.result!.productNameWithQuantity}',
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
                            final cardPieces = MetricCard(
                              title: 'Total Pieces Required',
                              value: state.result != null ? Formatters.formatInt(state.result!.pieces) : '—',
                              unit: 'Pieces',
                              subtitle: state.selectedProduct != null ? 'Pack size: ${state.selectedProduct!.packSizeDisplay}' : 'Packaging count',
                              icon: Icons.widgets_outlined,
                              iconColor: Colors.black.withValues(alpha: 0.60),
                              iconBgColor: Colors.black.withValues(alpha: 0.06),
                              cardBgColor: const Color(0xFFEFF6FF),
                            );

                            final cardPacking = MetricCard(
                              title: 'Packing Needed',
                              value: state.result != null ? Formatters.formatSmart(state.result!.crates) : '—',
                              unit: 'Crates',
                              subtitle: state.result?.packingBreakdown ?? (state.selectedProduct != null ? '${state.selectedProduct!.piecesPerCrate} pcs / crate' : 'Crates required'),
                              icon: Icons.all_inbox_rounded,
                              iconColor: Colors.black.withValues(alpha: 0.60),
                              iconBgColor: Colors.black.withValues(alpha: 0.06),
                              cardBgColor: const Color(0xFFFFFBEB),
                            );

                            final cardQuantity = MetricCard(
                              title: 'Total Quantity',
                              value: state.result != null ? Formatters.formatSmart(state.result!.totalQuantity) : '—',
                              unit: state.selectedProduct?.baseUnitLabel ?? 'kg',
                              subtitle: state.result?.totalQuantityDisplay ?? (state.selectedProduct != null ? 'Unit: ${state.selectedProduct!.baseUnitLabel}' : 'Total volume / weight'),
                              icon: Icons.water_drop_rounded,
                              iconColor: Colors.black.withValues(alpha: 0.60),
                              iconBgColor: Colors.black.withValues(alpha: 0.06),
                              cardBgColor: const Color(0xFFECFDF5),
                            );

                            final cardPrice = MetricCard(
                              title: 'Total Price',
                              value: state.result != null ? state.result!.totalPriceDisplay : '—',
                              unit: 'INR',
                              subtitle: state.result != null ? '@ ₹${Formatters.formatSmart(state.result!.pricePerPiece)} / piece' : (state.selectedProduct != null ? 'MRP ${state.selectedProduct!.priceDisplay}' : 'Gross valuation'),
                              icon: Icons.currency_rupee_rounded,
                              iconColor: Colors.black.withValues(alpha: 0.60),
                              iconBgColor: Colors.black.withValues(alpha: 0.06),
                              cardBgColor: const Color(0xFFF5F3FF),
                            );

                            if (constraints.maxWidth >= 550) {
                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: cardPieces),
                                    const SizedBox(width: 12),
                                    Expanded(child: cardPacking),
                                    const SizedBox(width: 12),
                                    Expanded(child: cardQuantity),
                                    const SizedBox(width: 12),
                                    Expanded(child: cardPrice),
                                  ],
                                ),
                              );
                            } else {
                              final itemWidth = (constraints.maxWidth - 12) / 2;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(width: itemWidth, child: cardPieces),
                                  SizedBox(width: itemWidth, child: cardPacking),
                                  SizedBox(width: itemWidth, child: cardQuantity),
                                  SizedBox(width: itemWidth, child: cardPrice),
                                ],
                              );
                            }
                          },
                        ),
                        if (state.result != null) ...[
                          const SizedBox(height: 16),
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
                                  icon: const Icon(Icons.check_rounded, size: 20),
                                  label: const Text(
                                    'Record Calculation',
                                    style: TextStyle(
                                      fontSize: AppTextSizes.body,
                                      fontWeight: AppFontWeights.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  onPressed: _onSave,
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
                                  onPressed: () {
                                    _quantityController.clear();
                                    ref.read(productCalculatorProvider.notifier).resetForm();
                                    setState(() => _metadataExpanded = false);
                                  },
                                  child: const Text(
                                    'Reset',
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
                      ],
                    ),
                  ),
                ],
              ),

              // Calculation Breakdown & Formula Details (OUTSIDE the main card)
              if (state.result != null) ...[
                const SizedBox(height: 20),
                CalculationBreakdownCard(
                  title: 'Calculation Breakdown & Formula Details',
                  steps: state.result!.breakdownSteps,
                  initiallyExpanded: false,
                ),
              ],

              // Recent Calculations History
              const SizedBox(height: 32),
              _buildHistorySection(state.history, state.products),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsibleSpecifications(ProductModel? product) {
    final isLassi = product != null &&
        (product.category == 'Fermented' ||
            product.shortCode.toLowerCase().contains('lassi') ||
            product.productName.toLowerCase().contains('lassi'));
    final isMilk = product != null &&
        !isLassi &&
        (product.category == 'Milk' ||
            product.shortCode.contains('STD') ||
            product.shortCode.contains('SM+') ||
            product.shortCode.contains('TM') ||
            product.shortCode.contains('DTM') ||
            product.shortCode.contains('FC') ||
            product.shortCode.contains('FCM'));

    final Color chipBg;
    final Color chipBorder;
    final Color accentColor;

    if (product == null) {
      chipBg = const Color(0xFFFFFBEB); // Soft Amber (matching dashboard metric summary)
      chipBorder = const Color(0xFFFDE68A);
      accentColor = const Color(0xFFD97706);
    } else if (isMilk) {
      chipBg = const Color(0xFFEFF6FF); // Soft Blue
      chipBorder = const Color(0xFFBFDBFE);
      accentColor = const Color(0xFF0284C7);
    } else if (isLassi) {
      chipBg = const Color(0xFFF5F3FF); // Soft Purple
      chipBorder = const Color(0xFFDDD6FE);
      accentColor = const Color(0xFF7C3AED);
    } else if (product.shortCode.startsWith('S')) {
      chipBg = const Color(0xFFFFFBEB); // Soft Amber
      chipBorder = const Color(0xFFFDE68A);
      accentColor = const Color(0xFFD97706);
    } else {
      chipBg = const Color(0xFFECFDF5); // Soft Emerald
      chipBorder = const Color(0xFFA7F3D0);
      accentColor = const Color(0xFF059669);
    }

    return Container(
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _metadataExpanded
              ? accentColor.withValues(alpha: 0.6)
              : chipBorder,
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _metadataExpanded = !_metadataExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: 16,
                      color: Colors.black.withValues(alpha: 0.60),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'PRODUCT SPECIFICATIONS',
                    style: TextStyle(
                      fontSize: AppTextSizes.caption,
                      fontWeight: AppFontWeights.bold,
                      letterSpacing: 0.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
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
                          _metadataExpanded ? 'Collapse' : 'Expand',
                          style: const TextStyle(
                            fontSize: AppTextSizes.caption,
                            fontWeight: AppFontWeights.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _metadataExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
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
          if (_metadataExpanded) ...[
            const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
            if (product != null)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 650;
                  return Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: chipBorder, width: 1.1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Row 1: Pieces / Crate & Item Code (Right)
                        _buildTwoColumnRow(
                          label1: 'Pieces / Crate',
                          value1: '${product.piecesPerCrate} pcs',
                          label2: 'Item Code',
                          value2: product.itemCode,
                          isEven: false,
                          isCompact: isCompact,
                        ),
                        const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                        // Row 2: Crate Quantity & Product Code (Right)
                        _buildTwoColumnRow(
                          label1: 'Crate Quantity',
                          value1: product.calculatedPerCrateDisplay,
                          label2: 'Product Code',
                          value2: product.productCode,
                          valueColor2: AppColors.primary,
                          isEven: true,
                          isCompact: isCompact,
                        ),
                        const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                        // Row 3: Price per Piece & Pack Size (Right)
                        _buildTwoColumnRow(
                          label1: 'Price / Piece',
                          value1: product.priceDisplay,
                          valueColor1: AppColors.goldAccent,
                          label2: 'Pack Size',
                          value2: product.packSizeDisplay,
                          isEven: false,
                          isCompact: isCompact,
                        ),
                        const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                        // Row 4: Target FAT/SNF & Base Unit (Right)
                        _buildTwoColumnRow(
                          label1: 'Target FAT/SNF',
                          value1:
                              'F: ${product.targetFat != null ? Formatters.formatPercent(product.targetFat!) : '—'} • S: ${product.targetSnf != null ? Formatters.formatPercent(product.targetSnf!) : '—'}',
                          label2: 'Base Unit',
                          value2: product.baseUnitLabel,
                          isEven: true,
                          isCompact: isCompact,
                        ),
                        const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                        // Row 5: Allowed Modes & Shelf Life (Right)
                        _buildTwoColumnRow(
                          label1: 'Allowed Modes',
                          value1: product.allowedInputModes.join(' • '),
                          label2: 'Shelf Life',
                          value2: product.shelfLife,
                          isEven: false,
                          isCompact: isCompact,
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textMuted),
                    SizedBox(width: 8),
                    Text(
                      'Select a product above to inspect specifications & packaging standards.',
                      style: TextStyle(
                        fontSize: AppTextSizes.caption,
                        color: AppColors.textSecondary,
                        fontWeight: AppFontWeights.medium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTwoColumnRow({
    required String label1,
    required String value1,
    Color? valueColor1,
    required String label2,
    required String value2,
    Color? valueColor2,
    required bool isEven,
    required bool isCompact,
  }) {
    final labelWidth = isCompact ? 100.0 : 135.0;

    return Container(
      color: isEven ? const Color(0xFFFBFDFD) : Colors.white,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Column
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: labelWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                    color: isEven ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label1,
                      style: const TextStyle(
                        fontSize: AppTextSizes.caption,
                        fontWeight: AppFontWeights.semiBold,
                        color: Color(0xFF475569),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Container(width: 1, color: AppColors.cardBorder),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value1,
                          style: TextStyle(
                            fontSize: AppTextSizes.caption,
                            fontWeight: AppFontWeights.bold,
                            color: valueColor1 ?? AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Vertical Divider between columns
            Container(width: 1, color: AppColors.cardBorder),
            // Right Column
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: labelWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                    color: isEven ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label2,
                      style: const TextStyle(
                        fontSize: AppTextSizes.caption,
                        fontWeight: AppFontWeights.semiBold,
                        color: Color(0xFF475569),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Container(width: 1, color: AppColors.cardBorder),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value2,
                          style: TextStyle(
                            fontSize: AppTextSizes.caption,
                            fontWeight: AppFontWeights.bold,
                            color: valueColor2 ?? AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(
    List<ProductCalculationRecord> allHistory,
    List<ProductModel> products,
  ) {
    final filteredHistory = allHistory.where((item) {
      if (_filterDate != null) {
        if (!_matchesDate(item, _filterDate!)) return false;
      }
      if (_filterProductId != null && _filterProductId!.isNotEmpty) {
        final sel = products.where((p) => p.productId == _filterProductId).firstOrNull;
        final matchId = item.productId == _filterProductId;
        final matchName = item.productName == _filterProductId;
        final matchSel = sel != null &&
            (item.productName.toLowerCase() == sel.productName.toLowerCase() ||
             item.productName.toLowerCase().contains(sel.shortCode.toLowerCase()) ||
             item.productId == sel.productId);
        if (!matchId && !matchName && !matchSel) {
          return false;
        }
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading OUTSIDE of card
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
                      'PRODUCT CALCULATION HISTORY',
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
                            _buildProductFilterChip(products),
                            _buildDateFilterChip(),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Records list or empty state
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
                                  'No product calculations matching current filter.',
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
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryContainer,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                item.date,
                                                style: const TextStyle(
                                                  fontWeight: AppFontWeights.bold,
                                                  fontSize: AppTextSizes.body,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                item.time,
                                                style: const TextStyle(
                                                  fontWeight: AppFontWeights.semiBold,
                                                  fontSize: AppTextSizes.caption,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              StatusBadge.neutral(
                                                item.productName,
                                                fontSize: AppTextSizes.caption,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Calculated by: ${item.employeeName.isNotEmpty ? item.employeeName : 'Staff'}',
                                            style: const TextStyle(
                                              fontSize: AppTextSizes.caption,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Packing: ${item.packingNeeded.isNotEmpty ? item.packingNeeded : '${Formatters.formatSmart(item.crates)} Crates'} • '
                                            'Volume: ${item.totalQuantityDisplay.isNotEmpty ? item.totalQuantityDisplay : '${Formatters.formatSmart(item.volumeLitres)} L'}',
                                            style: const TextStyle(
                                              fontSize: AppTextSizes.caption,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${Formatters.formatInt(item.pieces)} pcs',
                                          style: const TextStyle(
                                            fontSize: AppTextSizes.body,
                                            fontWeight: AppFontWeights.bold,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                        if (item.totalPriceDisplay.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.totalPriceDisplay,
                                            style: const TextStyle(
                                              fontSize: AppTextSizes.body,
                                              fontWeight: AppFontWeights.bold,
                                              color: AppColors.goldAccent,
                                            ),
                                          ),
                                        ],
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

  bool _matchesDate(ProductCalculationRecord r, DateTime filterDate) {
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
    final validProducts = (products.isNotEmpty ? products : DairyProducts.officialProducts)
        .where((p) =>
            p.productName.trim() != '2' &&
            p.productId.trim() != '2' &&
            p.productName.trim().isNotEmpty)
        .toList();
    final isSelectedValid = _filterProductId != null &&
        validProducts.any((p) => p.productId == _filterProductId);

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
}
