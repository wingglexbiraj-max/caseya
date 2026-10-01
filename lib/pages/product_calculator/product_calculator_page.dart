import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/dairy_products.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _historyExpanded = false;
  bool _metadataExpanded = false;
  DateTime? _filterDate = DateTime.now();
  String? _filterProductId;
  String _searchQuery = '';

  @override
  void dispose() {
    _quantityController.dispose();
    _searchController.dispose();
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.calculate_rounded,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'INPUT SPECIFICATIONS',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AppCard(
                              topBorderColor: AppColors.primary,
                              topBorderHeight: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                              // Product Selection Dropdown
                              SearchableDropdown<ProductModel>(
                                label: 'Product',
                                hint: 'Select product from plant catalog...',
                                items: state.products
                                    .where((p) =>
                                        p.productName.trim() != '2' &&
                                        p.productId.trim() != '2' &&
                                        p.productName.trim().isNotEmpty)
                                    .toList(),
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
                          ],
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
              _buildHistorySection(state.history, state.products),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataCard(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    size: 20,
                    color: AppColors.goldAccent,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'PRODUCT SPECIFICATIONS',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            StatusBadge.neutral(product.category),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          topBorderColor: AppColors.goldAccent,
          topBorderHeight: 4,
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
                      Text(
                        _metadataExpanded
                            ? 'Hide Specifications'
                            : 'Show Specifications & Metadata',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
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
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _metadataExpanded
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
    ),
  ],
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
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = item.productName.toLowerCase().contains(q) ||
            item.productNameWithQuantity.toLowerCase().contains(q) ||
            item.employeeName.toLowerCase().contains(q) ||
            item.packingNeeded.toLowerCase().contains(q) ||
            item.inputMode.toLowerCase().contains(q) ||
            item.totalPriceDisplay.toLowerCase().contains(q);
        if (!matches) return false;
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
                      'RECENT PRODUCT CALCULATIONS',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
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
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
                        // Filter Controls (Search, Product Chip Card, Date Chip Card)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 750;

                            if (isWide) {
                              return Row(
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Search product, employee, crates, packaging...',
                                        prefixIcon: Icon(
                                          Icons.search_rounded,
                                          size: 19,
                                        ),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _searchQuery = val;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildProductFilterChip(products),
                                  const SizedBox(width: 12),
                                  _buildDateFilterChip(),
                                ],
                              );
                            } else {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _searchController,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Search product, employee, crates, packaging...',
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        size: 19,
                                      ),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _searchQuery = val;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      _buildProductFilterChip(products),
                                      _buildDateFilterChip(),
                                    ],
                                  ),
                                ],
                              );
                            }
                          },
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.inbox_outlined,
                                  size: 20,
                                  color: AppColors.alert,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'No product calculations found for ${_filterDate != null ? Formatters.formatDate(_filterDate!) : 'selected filter'}.',
                                  style: const TextStyle(
                                    color: AppColors.alert,
                                    fontWeight: FontWeight.w700,
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
                              final titleText = item.productNameWithQuantity
                                      .isNotEmpty
                                  ? item.productNameWithQuantity
                                  : '${item.productName} — ${Formatters.formatSmart(item.inputQuantity)} ${item.inputMode}';

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_outlined,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            titleText,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${item.date} • ${item.time} • ${item.employeeName}\n'
                                            'Packing: ${item.packingNeeded.isNotEmpty ? item.packingNeeded : '${Formatters.formatSmart(item.crates)} Crates'} | '
                                            'Quantity: ${item.totalQuantityDisplay.isNotEmpty ? item.totalQuantityDisplay : '${Formatters.formatSmart(item.volumeLitres)} L'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${Formatters.formatInt(item.pieces)} pcs',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                        if (item.totalPriceDisplay
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.totalPriceDisplay,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
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
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
                fontWeight: FontWeight.w700,
                fontSize: 13,
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
