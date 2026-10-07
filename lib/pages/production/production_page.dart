import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/searchable_dropdown.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/live_time_chip.dart';
import '../../core/widgets/metric_card.dart';
import '../../models/product_model.dart';
import '../../models/stock_ledger_entry_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/production_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/inventory_stock_service.dart';

class ProductionPage extends ConsumerStatefulWidget {
  const ProductionPage({super.key});

  @override
  ConsumerState<ProductionPage> createState() => _ProductionPageState();
}

class _ProductionPageState extends ConsumerState<ProductionPage> {
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _cratesController = TextEditingController();
  final TextEditingController _piecesController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _customPersonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSyncing = false;
  bool _historyExpanded = false;
  bool _metadataExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Auto-match logged in user to authorized person if present
        final userName = ref.read(authProvider).name;
        final match = ProductionState.authorizedPersonsList.firstWhere(
          (n) => n.toLowerCase() == userName.toLowerCase(),
          orElse: () => '',
        );
        if (match.isNotEmpty && match != 'Other (Type manually)') {
          ref.read(productionProvider.notifier).setAuthorizedPerson(match);
        }
      }
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _cratesController.dispose();
    _piecesController.dispose();
    _remarksController.dispose();
    _customPersonController.dispose();
    super.dispose();
  }

  // --- Synchronized Calculations based on Product Calculator specifications ---

  void _onCratesChanged(String val, ProductModel? product) {
    if (_isSyncing || product == null) return;
    final crates = Formatters.parseDouble(val);
    _isSyncing = true;
    ref.read(productionProvider.notifier).updateFromCrates(crates);

    if (val.trim().isEmpty || crates == 0) {
      _piecesController.text = '';
      _qtyController.text = '';
    } else {
      final pcs = (crates * product.piecesPerCrate).round();
      final qty = pcs * product.packSizeInBaseUnit;
      _piecesController.text = pcs.toString();
      _qtyController.text = Formatters.formatSmart(qty);
    }
    _isSyncing = false;
  }

  void _onPiecesChanged(String val, ProductModel? product) {
    if (_isSyncing || product == null) return;
    final pcs = int.tryParse(val.trim()) ?? 0;
    _isSyncing = true;
    ref.read(productionProvider.notifier).updateFromPieces(pcs);

    if (val.trim().isEmpty || pcs == 0) {
      _cratesController.text = '';
      _qtyController.text = '';
    } else {
      final crates = product.piecesPerCrate > 0 ? (pcs / product.piecesPerCrate) : 0.0;
      final qty = pcs * product.packSizeInBaseUnit;
      _cratesController.text = Formatters.formatSmart(crates);
      _qtyController.text = Formatters.formatSmart(qty);
    }
    _isSyncing = false;
  }

  void _onQuantityChanged(String val, ProductModel? product) {
    if (_isSyncing || product == null) return;
    final qty = Formatters.parseDouble(val);
    _isSyncing = true;
    ref.read(productionProvider.notifier).updateFromQuantity(qty);

    if (val.trim().isEmpty || qty == 0) {
      _cratesController.text = '';
      _piecesController.text = '';
    } else {
      final pcs = product.packSizeInBaseUnit > 0 ? (qty / product.packSizeInBaseUnit).round() : 0;
      final crates = product.piecesPerCrate > 0 ? (pcs / product.piecesPerCrate) : 0.0;
      _piecesController.text = pcs.toString();
      _cratesController.text = Formatters.formatSmart(crates);
    }
    _isSyncing = false;
  }

  void _onProductSelected(ProductModel p) {
    ref.read(productionProvider.notifier).selectProduct(p);

    // Re-sync with newly selected product packing metrics
    if (_cratesController.text.isNotEmpty && Formatters.parseDouble(_cratesController.text) > 0) {
      _onCratesChanged(_cratesController.text, p);
    } else if (_piecesController.text.isNotEmpty && (int.tryParse(_piecesController.text) ?? 0) > 0) {
      _onPiecesChanged(_piecesController.text, p);
    } else if (_qtyController.text.isNotEmpty && Formatters.parseDouble(_qtyController.text) > 0) {
      _onQuantityChanged(_qtyController.text, p);
    }
  }

  void _onClear() {
    _isSyncing = true;
    _qtyController.clear();
    _cratesController.clear();
    _piecesController.clear();
    _remarksController.clear();
    _customPersonController.clear();
    ref.read(productionProvider.notifier).clearForm();
    _isSyncing = false;
  }

  Future<void> _onSave() async {
    if (ref.read(productionProvider).selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product first.'),
          backgroundColor: AppColors.danger,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      final user = ref.read(authProvider);
      final success = await ref.read(productionProvider.notifier).recordProductionEntry(
        employeeId: user.employeeCode,
      );

      if (success && mounted) {
        setState(() {
          _historyExpanded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(productionProvider).successMessage ??
                  '✓ Production entry recorded successfully.',
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
          ),
        );
        _onClear();
      }
    }
  }

  Future<void> _selectDate() async {
    final current = ref.read(productionProvider).selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      ref.read(productionProvider.notifier).setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productionProvider);
    final isMobile = ResponsiveLayout.isMobile(context);
    final latestConsumption = ref.watch(latestProductionConsumptionProvider);

    final selectedProduct = state.selectedProduct;
    final unitLabel = selectedProduct?.baseUnitLabel ?? 'Litres';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 28,
          vertical: 22,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error Alert Banner
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
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: AppTextSizes.body,
                            fontWeight: AppFontWeights.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // -------------------------------------------------------------
              // 1. DATA ENTRY HEADING (Outside the Card, styled like Boiler page)
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
                          Icons.precision_manufacturing_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'NEW PRODUCTION ENTRY',
                        style: TextStyle(
                          fontSize: AppTextSizes.subheading,
                          fontWeight: AppFontWeights.bold,
                          letterSpacing: 0.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (selectedProduct != null)
                    StatusBadge.info(selectedProduct.productName),
                ],
              ),
              const SizedBox(height: 12),

              // -------------------------------------------------------------
              // DATA ENTRY CARD
              // -------------------------------------------------------------
              AppCard(
                topBorderColor: AppColors.primary,
                topBorderHeight: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // OPTION: FETCH FROM MILK STANDARDIZATION (Dropdown above Product Name)
                    Column(
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
                            if (state.selectedStandardizationBatch != null) ...[
                              const Spacer(),
                              InkWell(
                                onTap: () {
                                  ref.read(productionProvider.notifier).clearStandardizationBatch();
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Row(
                                    children: [
                                      Icon(Icons.close_rounded, size: 14, color: AppColors.danger),
                                      SizedBox(width: 4),
                                      Text(
                                        'Clear Selection',
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
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: state.selectedStandardizationBatch != null
                                  ? AppColors.primary
                                  : AppColors.cardBorder,
                              width: 1.2,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: (state.selectedStandardizationBatch != null &&
                                      state.standardizationBatches.any((b) => b.recordId == state.selectedStandardizationBatch!.recordId))
                                  ? state.selectedStandardizationBatch!.recordId.toString()
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
                                  ),
                                ),
                                ...state.standardizationBatches.map((b) {
                                  final batchQty = b.finalQuantity > 0 ? b.finalQuantity : b.totalBatchRequired;
                                  final timeAndDate = b.time.isNotEmpty ? '${b.time}, ${b.date}' : b.date;
                                  final label = '${b.targetProductName} • ${Formatters.formatSmart(batchQty)} L • $timeAndDate • Logged by: ${b.employeeName}';
                                  return DropdownMenuItem<String>(
                                    value: b.recordId.toString(),
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
                                  ref.read(productionProvider.notifier).clearStandardizationBatch();
                                } else {
                                  final b = state.standardizationBatches.firstWhere(
                                    (item) => item.recordId.toString() == val,
                                  );
                                  ref.read(productionProvider.notifier).selectStandardizationBatch(b);
                                  final matchedProduct = ref.read(productionProvider).selectedProduct;
                                  final batchQty = b.finalQuantity > 0 ? b.finalQuantity : b.totalBatchRequired;
                                  _isSyncing = true;
                                  _qtyController.text = Formatters.formatSmart(batchQty);
                                  if (matchedProduct != null && matchedProduct.packSizeInBaseUnit > 0) {
                                    final pcs = (batchQty / matchedProduct.packSizeInBaseUnit).round();
                                    final crates = matchedProduct.piecesPerCrate > 0 ? (pcs / matchedProduct.piecesPerCrate) : 0.0;
                                    _piecesController.text = pcs.toString();
                                    _cratesController.text = Formatters.formatSmart(crates);
                                  } else {
                                    _piecesController.text = '';
                                    _cratesController.text = '';
                                  }
                                  _isSyncing = false;
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ROW 1: Product Selection Dropdown & Authorised Person Dropdown
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 720;
                        final isOtherPerson = state.selectedAuthorizedPerson == 'Other (Type manually)';

                        final productDropdownWidget = SearchableDropdown<ProductModel>(
                          label: 'Product Name',
                          hint: 'Select Product',
                          items: state.products,
                          selectedItem: selectedProduct,
                          itemLabel: (p) => p.productName,
                          itemSubtitle: (p) =>
                              'Pack: ${p.packSizeDisplay} • 1 Crate = ${p.piecesPerCrate} pcs (${Formatters.formatSmart(p.piecesPerCrate * p.packSizeInBaseUnit)} ${p.baseUnitLabel})',
                          isRequired: true,
                          onChanged: (p) {
                            if (p != null) _onProductSelected(p);
                          },
                        );

                        final currentPerson = ProductionState.authorizedPersonsList.contains(state.selectedAuthorizedPerson)
                            ? state.selectedAuthorizedPerson
                            : ProductionState.authorizedPersonsList.first;

                        final personDropdownWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Logged By',
                              style: TextStyle(fontSize: AppTextSizes.body, fontWeight: AppFontWeights.bold),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: AppColors.cardBorder, width: 1.2),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: currentPerson,
                                  isExpanded: true,
                                  items: ProductionState.authorizedPersonsList.map((person) {
                                    return DropdownMenuItem(
                                      value: person,
                                      child: Text(
                                        person,
                                        style: const TextStyle(fontSize: AppTextSizes.body, fontWeight: AppFontWeights.semiBold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newPerson) {
                                    if (newPerson != null) {
                                      ref.read(productionProvider.notifier).setAuthorizedPerson(newPerson);
                                    }
                                  },
                                ),
                              ),
                            ),
                            if (isOtherPerson) ...[
                              const SizedBox(height: 10),
                              AppTextField(
                                label: 'Enter Name',
                                hint: 'Type full name...',
                                controller: _customPersonController,
                                onChanged: (val) {
                                  ref.read(productionProvider.notifier).setCustomAuthorizedPerson(val);
                                },
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              productDropdownWidget,
                              const SizedBox(height: 14),
                              personDropdownWidget,
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Collapsible PRODUCT SPECIFICATIONS directly below Product Selection (Product Calculator style)
                    _buildCollapsibleSpecifications(selectedProduct),
                    const SizedBox(height: 18),

                    // ROW 2: Date and Time
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 600;

                        final dateWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date', style: TextStyle(fontSize: AppTextSizes.body, fontWeight: AppFontWeights.bold)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: _selectDate,
                              borderRadius: BorderRadius.circular(9),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(color: AppColors.cardBorder, width: 1.2),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      Formatters.formatDate(state.selectedDate),
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
                              selectedTime: state.selectedTime,
                              isLiveTime: state.isLiveTime,
                              isMobile: !isWide,
                              onTimeChanged: (newTime) {
                                ref.read(productionProvider.notifier).setTime(newTime);
                              },
                              onResetToLive: () {
                                ref.read(productionProvider.notifier).resetToLiveTime();
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
                    const SizedBox(height: 18),

                    // ROW 3: Quantity, Crates, and Pieces Inputs (Linked Auto-Calculation)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 720;

                        final cratesField = AppTextField(
                          label: 'Crates Produced',
                          hint: 'e.g., 20',
                          controller: _cratesController,
                          suffixText: 'Crates',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (val) => _onCratesChanged(val, selectedProduct),
                        );

                        final piecesField = AppTextField(
                          label: 'Pieces Produced',
                          hint: 'e.g., 240',
                          controller: _piecesController,
                          suffixText: 'Pieces',
                          keyboardType: TextInputType.number,
                          onChanged: (val) => _onPiecesChanged(val, selectedProduct),
                        );

                        final qtyField = AppTextField(
                          label: 'Quantity Produced',
                          hint: 'e.g., 120.0',
                          controller: _qtyController,
                          suffixText: unitLabel,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (val) => _onQuantityChanged(val, selectedProduct),
                        );

                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(child: cratesField),
                              const SizedBox(width: 14),
                              Expanded(child: piecesField),
                              const SizedBox(width: 14),
                              Expanded(child: qtyField),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: cratesField),
                                  const SizedBox(width: 12),
                                  Expanded(child: piecesField),
                                ],
                              ),
                              const SizedBox(height: 12),
                              qtyField,
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Remarks / Note
                    AppTextField(
                      label: 'Note',
                      hint: 'e.g. Standard pouch packaging, batch cleared for cold storage dispatch',
                      controller: _remarksController,
                      onChanged: (val) => ref.read(productionProvider.notifier).setRemarks(val),
                    ),
                    const SizedBox(height: 20),

                    // CALCULATION METRICS Section Header (Product Calculator style)
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
                        if (selectedProduct != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '• ${selectedProduct.productName}',
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

                    // 4 MetricCard tiles: Total Pieces, Packing (Crates), Total Quantity, Estimated Valuation
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final pcs = state.pieces;
                        final crates = state.crates;
                        final qty = state.quantity;
                        final totalPrice = (selectedProduct != null && pcs > 0)
                            ? (pcs * selectedProduct.pricePerPiece)
                            : 0.0;

                        final cardPieces = MetricCard(
                          title: 'Total Pieces',
                          value: pcs > 0 ? Formatters.formatInt(pcs) : '—',
                          unit: 'Pieces',
                          subtitle: selectedProduct != null ? 'Pack size: ${selectedProduct.packSizeDisplay}' : 'Packaging count',
                          icon: Icons.widgets_outlined,
                          iconColor: Colors.black.withValues(alpha: 0.60),
                          iconBgColor: Colors.black.withValues(alpha: 0.06),
                          cardBgColor: const Color(0xFFEFF6FF),
                        );

                        final cardPacking = MetricCard(
                          title: 'Packing (Crates)',
                          value: crates > 0 ? Formatters.formatSmart(crates) : '—',
                          unit: 'Crates',
                          subtitle: selectedProduct != null ? '${selectedProduct.piecesPerCrate} pcs / crate' : 'Crates produced',
                          icon: Icons.all_inbox_rounded,
                          iconColor: Colors.black.withValues(alpha: 0.60),
                          iconBgColor: Colors.black.withValues(alpha: 0.06),
                          cardBgColor: const Color(0xFFFFFBEB),
                        );

                        final cardQuantity = MetricCard(
                          title: 'Total Quantity',
                          value: qty > 0 ? Formatters.formatSmart(qty) : '—',
                          unit: selectedProduct?.baseUnitLabel ?? 'kg',
                          subtitle: selectedProduct != null ? 'Unit: ${selectedProduct.baseUnitLabel}' : 'Total volume / weight',
                          icon: Icons.water_drop_rounded,
                          iconColor: Colors.black.withValues(alpha: 0.60),
                          iconBgColor: Colors.black.withValues(alpha: 0.06),
                          cardBgColor: const Color(0xFFECFDF5),
                        );

                        final cardPrice = MetricCard(
                          title: 'Estimated Valuation',
                          value: totalPrice > 0 ? '₹${Formatters.formatSmart(totalPrice)}' : '—',
                          unit: 'INR',
                          subtitle: selectedProduct != null ? '@ ₹${Formatters.formatSmart(selectedProduct.pricePerPiece)} / piece' : 'Gross valuation',
                          icon: Icons.currency_rupee_rounded,
                          iconColor: Colors.black.withValues(alpha: 0.60),
                          iconBgColor: Colors.black.withValues(alpha: 0.06),
                          cardBgColor: const Color(0xFFF5F3FF),
                        );

                        if (constraints.maxWidth >= 700) {
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
                    const SizedBox(height: 22),

                    // ACTION BUTTONS (Boiler-Style: Green Record Button & Red Clear Button)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981), // Green
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 20,
                            ),
                            label: const Text(
                              'Record Production Entry',
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
                            onPressed: _onClear,
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
              ),

              const SizedBox(height: 32),

              // -------------------------------------------------------------
              // LATEST CONSUMPTION BANNER (Instant Store Ledger Deduction Summary)
              // -------------------------------------------------------------
              if (latestConsumption != null) ...[
                _buildLatestConsumptionCard(latestConsumption, isMobile),
                const SizedBox(height: 16),
              ],

              // -------------------------------------------------------------
              // 2. PRODUCTION HISTORY (Styled exactly like Lab Page's Lab History)
              // -------------------------------------------------------------
              _buildHistorySection(state, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LATEST CONSUMPTION SUMMARY CARD (Instant Visual Feedback on Packaging Deducted)
  // ---------------------------------------------------------------------------
  Widget _buildLatestConsumptionCard(ProductionConsumptionEvent event, bool isMobile) {
    final consumedItems = event.consumedPackaging.whereType<ConsumedPackagingSummary>().toList();
    final parsedDate = StockLedgerCalculator.parseAnyDate(event.date) ?? DateTime.now();
    final monthDisplay = DateFormat('MMMM yyyy').format(parsedDate);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'STORE LEDGER UPDATED — PACKAGING DEDUCTION RECORDED',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (event.isBackDate) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFF59E0B)),
                              ),
                              child: Text(
                                'Back-dated: ${event.date}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Batch ${event.batchNo} • ${event.productName} (${Formatters.formatSmart(event.quantityProduced)} ${event.unit} / ${event.pieces} pcs) recorded on ${event.date}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF166534)),
                  onPressed: () {
                    ref.read(latestProductionConsumptionProvider.notifier).state = null;
                  },
                ),
              ],
            ),
          ),

          // Body: List of Deducted Materials
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The following materials were automatically deducted from inventory stock in the Store Ledger:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF166534),
                  ),
                ),
                const SizedBox(height: 10),
                if (consumedItems.isEmpty)
                  const Text(
                    'No packaging materials configured for this product.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  )
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: consumedItems.map((c) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF15803D)),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  c.itemName,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '−${Formatters.formatSmart(c.quantity)} ${c.unit}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                    if (c.note.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '(${c.note})',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF15803D),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              icon: const Icon(Icons.menu_book_rounded, size: 13),
                              label: Text(
                                'View in Ledger ($monthDisplay)',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                ref.read(stockLedgerTargetMonthProvider.notifier).state =
                                    DateTime(parsedDate.year, parsedDate.month, 1);
                                ref.read(stockLedgerTargetItemProvider.notifier).state = c.itemId;
                                ref.read(stockLedgerHighlightDateProvider.notifier).state = parsedDate;
                                ref.read(shellNavigationIndexProvider.notifier).state = 9;
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PRODUCTION HISTORY WIDGET (Product-wise & Date-wise Filterable, Today by Default)
  // ---------------------------------------------------------------------------
  Widget _buildHistorySection(ProductionState state, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header (Outside the card, like Lab Page)
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
                      'PRODUCTION HISTORY',
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
                    StatusBadge.info('${state.filteredHistory.length} Batches'),
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
                        // Filter Controls: Product Filter, Date Filter (No search bar)
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildProductFilterChip(state),
                            _buildDateFilterChip(state),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Table / List of Production Batches
                        if (state.filteredHistory.isEmpty) ...[
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
                                  'No production entries matching current filter.',
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
                            itemCount: state.filteredHistory.length,
                            separatorBuilder: (_, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = state.filteredHistory[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontWeight: AppFontWeights.bold,
                                              fontSize: AppTextSizes.body,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              StatusBadge.info(item.shift, fontSize: AppTextSizes.caption),
                                              if (item.standardizationRecordId != null && item.standardizationRecordId!.isNotEmpty) ...[
                                                StatusBadge.success('Standardized', fontSize: AppTextSizes.caption),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 6,
                                            children: [
                                              Text(
                                                '${item.date} • ${item.time}',
                                                style: const TextStyle(
                                                  fontSize: AppTextSizes.caption,
                                                  color: AppColors.textSecondary,
                                                  fontWeight: AppFontWeights.semiBold,
                                                ),
                                              ),
                                              const Text(
                                                '•',
                                                style: TextStyle(
                                                  fontSize: AppTextSizes.caption,
                                                  color: AppColors.textSecondary,
                                                  fontWeight: AppFontWeights.bold,
                                                ),
                                              ),
                                              Text(
                                                'Logged by: ${item.employeeName}',
                                                style: const TextStyle(
                                                  fontSize: AppTextSizes.caption,
                                                  color: AppColors.textSecondary,
                                                  fontWeight: AppFontWeights.semiBold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (item.remarks.trim().isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.blue.withValues(alpha: 0.25),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.notes_rounded,
                                                    size: 13,
                                                    color: Colors.blue,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Flexible(
                                                    child: Text(
                                                      'Note: ${item.remarks.trim()}',
                                                      style: const TextStyle(
                                                        fontSize: AppTextSizes.caption,
                                                        fontWeight: AppFontWeights.bold,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          Builder(
                                            builder: (context) {
                                              final consumedList = InventoryStockService.getConsumedPackagingForRecord(item);
                                              if (consumedList.isEmpty) return const SizedBox.shrink();
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 6),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF0FDF4),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: const Color(0xFF86EFAC),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Wrap(
                                                    spacing: 8,
                                                    runSpacing: 4,
                                                    crossAxisAlignment: WrapCrossAlignment.center,
                                                    children: [
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons.all_inbox_rounded,
                                                            size: 13,
                                                            color: Color(0xFF16A34A),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'Packaging: ${consumedList.map((c) => '${Formatters.formatSmart(c.quantity)} ${c.unit} ${c.itemName}').join(' • ')}',
                                                            style: const TextStyle(
                                                              fontSize: AppTextSizes.caption,
                                                              fontWeight: AppFontWeights.bold,
                                                              color: Color(0xFF15803D),
                                                            ),
                                                          ),
                                                        ],
                                                                                  ),
                                                      ...consumedList.map((c) {
                                                        return InkWell(
                                                          onTap: () {
                                                            final parsedDate = StockLedgerCalculator.parseAnyDate(item.date) ?? DateTime.now();
                                                            ref.read(stockLedgerTargetMonthProvider.notifier).state = DateTime(parsedDate.year, parsedDate.month, 1);
                                                            ref.read(stockLedgerTargetItemProvider.notifier).state = c.itemId;
                                                            ref.read(stockLedgerHighlightDateProvider.notifier).state = parsedDate;
                                                            ref.read(shellNavigationIndexProvider.notifier).state = 9;
                                                          },
                                                          borderRadius: BorderRadius.circular(4),
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFF15803D),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Text(
                                                                  'Ledger: ${c.itemName}',
                                                                  style: const TextStyle(
                                                                    fontSize: 10.5,
                                                                    fontWeight: AppFontWeights.bold,
                                                                    color: Colors.white,
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 3),
                                                                const Icon(
                                                                  Icons.arrow_forward_rounded,
                                                                  size: 11,
                                                                  color: Colors.white,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      }),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Right Metrics: Quantity, Crates & Pieces
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${Formatters.formatSmart(item.quantityProduced)} ${item.unit}',
                                          style: const TextStyle(
                                            fontSize: AppTextSizes.body,
                                            fontWeight: AppFontWeights.bold,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${Formatters.formatSmart(item.cratesProduced)} Crates',
                                                style: const TextStyle(
                                                  fontSize: AppTextSizes.caption,
                                                  fontWeight: AppFontWeights.bold,
                                                  color: Color(0xFF059669),
                                                ),
                                              ),
                                            ),
                                            if (item.piecesProduced > 0) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                '(${Formatters.formatInt(item.piecesProduced)} pcs)',
                                                style: const TextStyle(
                                                  fontSize: AppTextSizes.caption,
                                                  fontWeight: AppFontWeights.semiBold,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                      tooltip: 'Delete batch record',
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => const ConfirmationDialog(
                                            title: 'Delete Production Entry',
                                            message: 'Are you sure you want to remove this production batch record?',
                                            confirmLabel: 'Delete',
                                            isDestructive: true,
                                          ),
                                        );
                                        if (confirm == true) {
                                          await ref.read(productionProvider.notifier).deleteRecord(item.recordId);
                                        }
                                      },
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

  // Date Filter Chip (Today by default, exactly like Lab Page)
  Widget _buildDateFilterChip(ProductionState state) {
    final isToday = state.filterDate == null ||
        Formatters.formatDate(state.filterDate!) ==
            Formatters.formatDate(DateTime.now());

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: state.filterDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (picked != null) {
              ref.read(productionProvider.notifier).setFilterDate(picked);
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
                  state.filterDate != null
                      ? (isToday
                          ? 'Today (${Formatters.formatDate(state.filterDate!)})'
                          : Formatters.formatDate(state.filterDate!))
                      : 'All Dates',
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
            onTap: () => ref.read(productionProvider.notifier).setFilterDate(DateTime.now()),
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
        const SizedBox(width: 6),
        InkWell(
          onTap: () {
            if (state.filterDate != null) {
              ref.read(productionProvider.notifier).clearFilterDate();
            } else {
              ref.read(productionProvider.notifier).setFilterDate(DateTime.now());
            }
          },
          borderRadius: BorderRadius.circular(9),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: state.filterDate == null
                  ? AppColors.primaryContainer
                  : Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: state.filterDate == null
                    ? AppColors.primary
                    : AppColors.cardBorder,
                width: 1.2,
              ),
            ),
            child: Center(
              child: Text(
                state.filterDate == null ? '✓ All Dates' : 'All',
                style: TextStyle(
                  fontSize: AppTextSizes.caption,
                  fontWeight: AppFontWeights.bold,
                  color: state.filterDate == null ? AppColors.primaryDark : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Product Filter Chip / Dropdown
  Widget _buildProductFilterChip(ProductionState state) {
    final Map<String, String> productOptions = {};
    for (final p in state.products) {
      if (p.productId.isNotEmpty && !productOptions.containsKey(p.productId)) {
        productOptions[p.productId] = p.productName;
      }
    }
    final filterVal = (state.filterProductId != null && productOptions.containsKey(state.filterProductId))
        ? state.filterProductId!
        : '';

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
            Icons.filter_alt_outlined,
            size: 17,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: filterVal,
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
                ...productOptions.entries.map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                ),
              ],
              onChanged: (val) {
                ref.read(productionProvider.notifier).setFilterProduct(
                      val == null || val.isEmpty ? null : val,
                    );
              },
            ),
          ),
        ],
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
      chipBg = const Color(0xFFFFFBEB);
      chipBorder = const Color(0xFFFDE68A);
      accentColor = const Color(0xFFD97706);
    } else if (isMilk) {
      chipBg = const Color(0xFFEFF6FF);
      chipBorder = const Color(0xFFBFDBFE);
      accentColor = const Color(0xFF0284C7);
    } else if (isLassi) {
      chipBg = const Color(0xFFF5F3FF);
      chipBorder = const Color(0xFFDDD6FE);
      accentColor = const Color(0xFF7C3AED);
    } else if (product.shortCode.startsWith('S')) {
      chipBg = const Color(0xFFFFFBEB);
      chipBorder = const Color(0xFFFDE68A);
      accentColor = const Color(0xFFD97706);
    } else {
      chipBg = const Color(0xFFECFDF5);
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
}


