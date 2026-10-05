import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/searchable_dropdown.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/live_time_chip.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/production_provider.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSyncing = false;
  bool _historyExpanded = false;

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
    _searchController.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(productionProvider).successMessage ??
                  '✓ Production entry recorded successfully.',
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
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
                            fontWeight: FontWeight.w700,
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.precision_manufacturing_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'NEW PRODUCTION ENTRY',
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
                                fontWeight: FontWeight.w700,
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
                                          fontWeight: FontWeight.w700,
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
                                      fontWeight: FontWeight.w500,
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
                                        fontWeight: FontWeight.w600,
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
                              style: TextStyle(fontSize: AppTextSizes.body, fontWeight: FontWeight.w700),
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
                                        style: const TextStyle(fontSize: AppTextSizes.body, fontWeight: FontWeight.w600),
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
                    // Active Product Packaging Standard Banner (Directly below Product Name & Authorised Person)
                    if (selectedProduct != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Packaging Standard:  1 Crate = ${selectedProduct.piecesPerCrate} pcs (${Formatters.formatSmart(selectedProduct.piecesPerCrate * selectedProduct.packSizeInBaseUnit)} $unitLabel)  •  Pack Size: ${selectedProduct.packSizeDisplay}',
                                style: const TextStyle(
                                  fontSize: AppTextSizes.caption,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ] else ...[
                      const SizedBox(height: 16),
                    ],

                    // ROW 2: Date and Time
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 600;

                        final dateWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date', style: TextStyle(fontSize: AppTextSizes.body, fontWeight: FontWeight.w700)),
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
                                fontWeight: FontWeight.w700,
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
                                fontWeight: FontWeight.w700,
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
                      'PRODUCTION HISTORY',
                      style: TextStyle(
                        fontSize: AppTextSizes.subheading,
                        fontWeight: FontWeight.w900,
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
                        // Filter Controls: Search, Product Filter, Date Filter
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 780;

                            final searchField = TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search batch, product, person, note...',
                                prefixIcon: Icon(Icons.search_rounded, size: 19),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              onChanged: (val) {
                                ref.read(productionProvider.notifier).setSearchQuery(val);
                              },
                            );

                            final productFilter = _buildProductFilterChip(state);
                            final dateFilter = _buildDateFilterChip(state);

                            if (isWide) {
                              return Row(
                                children: [
                                  Expanded(flex: 5, child: searchField),
                                  const SizedBox(width: 12),
                                  productFilter,
                                  const SizedBox(width: 12),
                                  dateFilter,
                                ],
                              );
                            } else {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  searchField,
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      productFilter,
                                      dateFilter,
                                    ],
                                  ),
                                ],
                              );
                            }
                          },
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
                                              fontWeight: FontWeight.w800,
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
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const Text(
                                                '•',
                                                style: TextStyle(
                                                  fontSize: AppTextSizes.caption,
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                'Logged by: ${item.employeeName}',
                                                style: const TextStyle(
                                                  fontSize: AppTextSizes.caption,
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
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
                                                        fontWeight: FontWeight.w700,
                                                        color: Colors.blue,
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
                                    // Right Metrics: Quantity, Crates & Pieces
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${Formatters.formatSmart(item.quantityProduced)} ${item.unit}',
                                          style: const TextStyle(
                                            fontSize: AppTextSizes.body,
                                            fontWeight: FontWeight.w900,
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
                                                  fontWeight: FontWeight.w800,
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
                                                  fontWeight: FontWeight.w600,
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
                    fontWeight: FontWeight.w700,
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
                      fontWeight: FontWeight.w700,
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
                  fontWeight: FontWeight.w700,
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
                fontWeight: FontWeight.w700,
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
}
