import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/dairy_products.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/stock_ledger_exporter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/dispatch_record.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dispatch_provider.dart';
import '../../providers/navigation_provider.dart';

class DispatchPage extends ConsumerStatefulWidget {
  const DispatchPage({super.key});

  @override
  ConsumerState<DispatchPage> createState() => _DispatchPageState();
}

class _DispatchPageState extends ConsumerState<DispatchPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Inline Form State for Tab 1 (Enter Dispatch)
  final _inlineFormKey = GlobalKey<FormState>();
  final TextEditingController _inlineVehicleController = TextEditingController();
  final TextEditingController _inlineDistributorController = TextEditingController();
  final TextEditingController _inlineDriverController = TextEditingController();
  final TextEditingController _inlineRemarksController = TextEditingController();
  final List<_ProductRowDraft> _inlineProductRows = [];
  bool _isInlineSaving = false;

  @override
  void initState() {
    super.initState();
    // 5 Required Tabs: Enter Dispatch, Dispatch Records, Product Wise, Distributor Wise, Reports
    _tabController = TabController(length: 5, vsync: this);

    // Initialize with 1 default product row for quick entry
    _initDefaultProductRow();
  }

  void _initDefaultProductRow() {
    _inlineProductRows.add(
      _ProductRowDraft(
        productId: null,
        inputMode: 'Pieces',
        initialQty: '',
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _inlineVehicleController.dispose();
    _inlineDistributorController.dispose();
    _inlineDriverController.dispose();
    _inlineRemarksController.dispose();
    for (final r in _inlineProductRows) {
      r.dispose();
    }
    super.dispose();
  }

  String _formatDisplayDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final dt = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${days[dt.weekday - 1]}, ${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
      }
    } catch (_) {}
    return dateStr;
  }

  Future<void> _pickDate(String currentDateStr) async {
    DateTime initial = DateTime.now();
    try {
      final parts = currentDateStr.split('-');
      if (parts.length == 3) {
        initial = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final dateStr =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      ref.read(dispatchProvider.notifier).setSelectedDate(dateStr);
    }
  }

  void _shiftDate(int days) {
    final state = ref.read(dispatchProvider);
    try {
      final parts = state.selectedDate.split('-');
      if (parts.length == 3) {
        final current = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final next = current.add(Duration(days: days));
        final nextStr =
            '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
        ref.read(dispatchProvider.notifier).setSelectedDate(nextStr);
      }
    } catch (_) {}
  }

  void _jumpToToday() {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    ref.read(dispatchProvider.notifier).setSelectedDate(todayStr);
  }

  // Add Product row dynamically in Tab 1
  void _addInlineProductRow(List<ProductModel> catalog) {
    final selectedProductIds = _inlineProductRows
        .map((r) => r.productId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    if (selectedProductIds.length >= catalog.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All products from the catalogue have already been added.'),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }

    setState(() {
      _inlineProductRows.add(
        _ProductRowDraft(
          productId: null,
          inputMode: 'Pieces',
          initialQty: '',
        ),
      );
    });
  }

  void _removeInlineProductRow(int index) {
    if (_inlineProductRows.length > 1) {
      setState(() {
        _inlineProductRows[index].dispose();
        _inlineProductRows.removeAt(index);
      });
    } else {
      // Clear the single row
      setState(() {
        _inlineProductRows[0].clear();
      });
    }
  }

  // Clear Form for next vehicle while retaining the selected dispatch date
  void _resetInlineForm() {
    _inlineVehicleController.clear();
    _inlineDistributorController.clear();
    _inlineDriverController.clear();
    _inlineRemarksController.clear();
    for (final r in _inlineProductRows) {
      r.dispose();
    }
    _inlineProductRows.clear();
    _initDefaultProductRow();
    setState(() {});
  }

  String _getPieceUnitSuffix(ProductModel? p) {
    if (p == null) return 'pcs';
    final unit = p.individualSaleUnit.toLowerCase().trim();
    if (unit == 'cup') return 'cups';
    if (unit == 'packet') return 'pkts';
    if (unit == 'bottle') return 'btls';
    return 'pcs';
  }

  String _getBaseUnitSuffix(ProductModel? p) {
    if (p == null) return '';
    return p.baseUnitLabel == 'Litres' ? 'L' : 'kg';
  }

  String _getBulkUnitSuffix(ProductModel? p) {
    if (p == null) return 'crt';
    if (!p.hasCrateConfiguration) return 'N/A';
    if (p.bulkPackingUnit == 'Boxes') return 'box';
    return 'crt';
  }

  double _getRowCostValue(_ProductRowDraft row, ProductModel? p) {
    if (p == null || !p.hasPriceConfiguration) return 0.0;
    final pieces = double.tryParse(row.piecesController.text.trim()) ?? 0.0;
    return pieces * p.pricePerPiece;
  }

  String _formatRowCost(_ProductRowDraft row, ProductModel? p) {
    if (p == null) return '₹0.00';
    if (p.priceCustomLabel != null && p.priceCustomLabel!.isNotEmpty) {
      return p.priceCustomLabel!;
    }
    final cost = _getRowCostValue(row, p);
    if (cost <= 0) return '₹0.00';
    return '₹${Formatters.formatDecimal(cost)}';
  }

  void _syncRowCalculations(_ProductRowDraft row, ProductModel? product, String sourceField) {
    row.lastEditedField = sourceField;
    if (product == null) {
      setState(() {});
      return;
    }

    final piecesPerCrate = product.piecesPerCrate > 0 ? product.piecesPerCrate : 0;
    final packBase = product.packSizeInBaseUnit > 0 ? product.packSizeInBaseUnit : 1.0;

    if (sourceField == 'crates') {
      final cText = row.cratesController.text.trim();
      if (cText.isEmpty) {
        row.piecesController.clear();
        row.baseQtyController.clear();
        row.quantityController.clear();
      } else {
        final c = double.tryParse(cText) ?? 0.0;
        final pieces = (c * piecesPerCrate).round();
        final baseQty = pieces * packBase;
        row.piecesController.text = pieces > 0 ? pieces.toString() : '';
        row.baseQtyController.text = baseQty > 0 ? Formatters.formatSmart(baseQty) : '';
        row.quantityController.text = pieces > 0 ? pieces.toString() : '';
      }
    } else if (sourceField == 'pieces') {
      final pText = row.piecesController.text.trim();
      if (pText.isEmpty) {
        row.cratesController.clear();
        row.baseQtyController.clear();
        row.quantityController.clear();
      } else {
        final p = double.tryParse(pText) ?? 0.0;
        final c = piecesPerCrate > 0 ? (p / piecesPerCrate) : 0.0;
        final baseQty = p * packBase;
        row.cratesController.text = (c > 0 && piecesPerCrate > 0) ? Formatters.formatSmart(c) : '';
        row.baseQtyController.text = baseQty > 0 ? Formatters.formatSmart(baseQty) : '';
        row.quantityController.text = p > 0 ? Formatters.formatSmart(p) : '';
      }
    } else if (sourceField == 'baseQty') {
      final qText = row.baseQtyController.text.trim();
      if (qText.isEmpty) {
        row.piecesController.clear();
        row.cratesController.clear();
        row.quantityController.clear();
      } else {
        final q = double.tryParse(qText) ?? 0.0;
        final pieces = (q / packBase).round();
        final c = piecesPerCrate > 0 ? (pieces / piecesPerCrate) : 0.0;
        row.piecesController.text = pieces > 0 ? pieces.toString() : '';
        row.cratesController.text = (c > 0 && piecesPerCrate > 0) ? Formatters.formatSmart(c) : '';
        row.quantityController.text = pieces > 0 ? pieces.toString() : '';
      }
    }
    setState(() {});
  }

  // Submit Vehicle Entry in Tab 1
  Future<void> _submitInlineVehicle() async {
    if (!_inlineFormKey.currentState!.validate()) return;

    final distributor = _inlineDistributorController.text.trim();
    if (distributor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Distributor Name is required.'),
          backgroundColor: Color(0xFF991B1B),
        ),
      );
      return;
    }

    final vehicleNo = _inlineVehicleController.text.trim();
    if (vehicleNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle Number is required.'),
          backgroundColor: Color(0xFF991B1B),
        ),
      );
      return;
    }

    // Filter valid product rows
    final state = ref.read(dispatchProvider);
    final catalog = state.catalogProducts;
    final List<DispatchItem> validItems = [];

    final dispatchId = 'DISP-${DateTime.now().millisecondsSinceEpoch}';

    for (int i = 0; i < _inlineProductRows.length; i++) {
      final draft = _inlineProductRows[i];
      if (draft.productId == null || draft.productId!.isEmpty) continue;

      double pieces = double.tryParse(draft.piecesController.text.trim()) ?? 0.0;
      if (pieces <= 0) {
        final crates = double.tryParse(draft.cratesController.text.trim()) ?? 0.0;
        final product = catalog.firstWhere(
          (p) => p.productId == draft.productId,
          orElse: () => DairyProducts.officialProducts.first,
        );
        if (crates > 0 && product.piecesPerCrate > 0) {
          pieces = crates * product.piecesPerCrate;
        } else {
          pieces = double.tryParse(draft.quantityController.text.trim()) ?? 0.0;
        }
      }

      if (pieces <= 0) {
        // Skip zero/empty rows
        continue;
      }

      final product = catalog.firstWhere(
        (p) => p.productId == draft.productId,
        orElse: () => DairyProducts.officialProducts.first,
      );

      // Perform verified calculation via CalculationService
      validItems.add(
        DispatchItem.fromInput(
          id: '$dispatchId-ITEM-${i + 1}',
          dispatchId: dispatchId,
          product: product,
          inputMode: 'Pieces',
          inputQuantity: pieces,
        ),
      );
    }

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one product with a valid quantity (> 0).'),
          backgroundColor: Color(0xFF991B1B),
        ),
      );
      return;
    }

    setState(() => _isInlineSaving = true);

    final currentUser = ref.read(authProvider);
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    final newDispatch = VehicleDispatch(
      id: dispatchId,
      dispatchDate: state.selectedDate,
      vehicleNumber: vehicleNo.toUpperCase(),
      distributorName: distributor,
      driverName: _inlineDriverController.text.trim(),
      route: '',
      dispatchTime: timeStr,
      remarks: _inlineRemarksController.text.trim(),
      status: 'Dispatched',
      createdBy: currentUser.fullName.isNotEmpty ? currentUser.fullName : 'Plant Operator',
      items: validItems,
      createdAt: now,
      updatedAt: now,
    );

    final success = await ref.read(dispatchProvider.notifier).saveDispatch(newDispatch);

    if (mounted) {
      setState(() => _isInlineSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Vehicle ${newDispatch.vehicleNumber} added to dispatch with ${validItems.length} products! Daily totals updated.'),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 4),
          ),
        );
        // Reset form for next vehicle, retaining the current date!
        _resetInlineForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'Failed to save vehicle dispatch. Please retry.'),
            backgroundColor: const Color(0xFF991B1B),
          ),
        );
      }
    }
  }

  void _openDispatchDialog({VehicleDispatch? existing}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _VehicleDispatchDialog(existing: existing),
    );
  }

  void _openVehicleDetails(VehicleDispatch dispatch) {
    showDialog(
      context: context,
      builder: (ctx) => _VehicleDetailDialog(dispatch: dispatch),
    );
  }

  Future<void> _confirmDelete(VehicleDispatch dispatch) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Vehicle Dispatch?',
      message:
          'Are you sure you want to delete dispatch record for vehicle "${dispatch.vehicleNumber}" (${dispatch.distributorName})? All associated product lines will be removed and daily summary will be recalculated immediately.',
      confirmLabel: 'Delete Dispatch',
      isDestructive: true,
    );

    if (confirmed) {
      final success = await ref
          .read(dispatchProvider.notifier)
          .deleteDispatch(dispatch.id);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✓ Vehicle dispatch ${dispatch.vehicleNumber} deleted successfully.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dispatchProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final isViewingToday = state.selectedDate == todayStr;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24,
          vertical: 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Date Navigation Bar
            _buildHeader(isMobile, isViewingToday, todayStr),
            const SizedBox(height: 16),

            // 5 Tabs as explicitly specified
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder, width: 1.1),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: isMobile,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: AppFontWeights.bold,
                  fontSize: AppTextSizes.body,
                ),
                tabs: [
                  const Tab(
                    icon: Icon(Icons.add_shopping_cart_rounded, size: 18),
                    text: 'New Entry',
                  ),
                  Tab(
                    icon: const Icon(Icons.local_shipping_rounded, size: 18),
                    text: 'Vehicle Records (${state.dispatchesForSelectedDate.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.inventory_2_rounded, size: 18),
                    text: 'Product Wise (${state.dailyProductSummaries.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    text: 'Distributor Wise (${state.distributorSummaries.length})',
                  ),
                  const Tab(
                    icon: Icon(Icons.analytics_rounded, size: 18),
                    text: 'Reports & Export',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab View Contents
            SizedBox(
              height: 850,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Enter Dispatch
                  _buildEnterDispatchTab(state, isMobile),
                  // Tab 2: Dispatch Records
                  _buildDispatchRecordsTab(state, isMobile),
                  // Tab 3: Product Wise
                  _buildProductWiseTab(state, isMobile),
                  // Tab 4: Distributor Wise
                  _buildDistributorWiseTab(state, isMobile),
                  // Tab 5: Reports
                  _buildReportsTab(state, isMobile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP DATE NAVIGATION BAR
  // ===========================================================================

  Widget _buildHeader(bool isMobile, bool isViewingToday, String todayStr) {
    final state = ref.watch(dispatchProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          final dateControls = Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.textPrimary),
                  tooltip: 'Previous Day',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: () => _shiftDate(-1),
                ),
                InkWell(
                  onTap: () => _pickDate(state.selectedDate),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          _formatDisplayDate(state.selectedDate),
                          style: const TextStyle(
                            fontWeight: AppFontWeights.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textPrimary),
                  tooltip: 'Next Day',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: () => _shiftDate(1),
                ),
              ],
            ),
          );

          final rightActions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isViewingToday) ...[
                TextButton(
                  onPressed: _jumpToToday,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  child: const Text('Today', style: TextStyle(fontWeight: AppFontWeights.bold)),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(targetReportSectionProvider.notifier).state = 'dispatch';
                  ref.read(shellNavigationIndexProvider.notifier).state = 10;
                },
                icon: const Icon(Icons.analytics_outlined, size: 15),
                label: const Text('Reports Catalogue'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: dateControls),
                const SizedBox(height: 8),
                Center(child: rightActions),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              dateControls,
              rightActions,
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // TAB 1: ENTER DISPATCH (SIMPLIFIED & INTUITIVE VEHICLE ENTRY FORM)
  // ===========================================================================

  Widget _buildEnterDispatchTab(DispatchState state, bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: _buildVehicleEntryFormCard(state, isMobile),
    );
  }

  Widget _buildVehicleEntryFormCard(DispatchState state, bool isMobile) {
    final catalog = state.catalogProducts;
    final distributors = state.availableDistributors;

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Form(
        key: _inlineFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Header: Icon + Title & Subtitle + Date Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        color: Color(0xFF1B5E20),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'New Vehicle Dispatch',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Record outgoing vehicle details and supplied products',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => _pickDate(state.selectedDate),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF334155)),
                        const SizedBox(width: 8),
                        Text(
                          _formatDisplayDate(state.selectedDate),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // 2. Four Top Form Fields (Distributor, Vehicle Number, Driver, Remarks)
            LayoutBuilder(
              builder: (context, constraints) {
                final distributorField = _buildFieldWithTopLabel(
                  label: 'Distributor Name',
                  isRequired: true,
                  child: TextFormField(
                    controller: _inlineDistributorController,
                    onChanged: (_) => setState(() {}),
                    decoration: _boxedInputDecoration(
                      hint: 'Select distributor',
                      icon: Icons.storefront_outlined,
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                        tooltip: 'Select Distributor',
                        onSelected: (val) {
                          setState(() {
                            _inlineDistributorController.text = val;
                          });
                        },
                        itemBuilder: (context) {
                          return distributors.map((d) {
                            return PopupMenuItem<String>(
                              value: d,
                              child: Text(d, style: const TextStyle(fontSize: 13)),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Required' : null,
                  ),
                );

                final vehicleField = _buildFieldWithTopLabel(
                  label: 'Vehicle Number',
                  isRequired: true,
                  child: TextFormField(
                    controller: _inlineVehicleController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _boxedInputDecoration(
                      hint: 'e.g. BR01AB1234',
                      icon: Icons.local_shipping_outlined,
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Required' : null,
                  ),
                );

                final driverField = _buildFieldWithTopLabel(
                  label: 'Driver Name',
                  child: TextFormField(
                    controller: _inlineDriverController,
                    decoration: _boxedInputDecoration(
                      hint: 'e.g. Ramesh Kumar',
                      icon: Icons.person_outline,
                    ),
                  ),
                );

                final remarksField = _buildFieldWithTopLabel(
                  label: 'Remarks (Optional)',
                  child: TextFormField(
                    controller: _inlineRemarksController,
                    decoration: _boxedInputDecoration(
                      hint: 'e.g. Morning supply',
                      icon: Icons.description_outlined,
                    ),
                  ),
                );

                if (constraints.maxWidth >= 850) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: distributorField),
                      const SizedBox(width: 14),
                      Expanded(child: vehicleField),
                      const SizedBox(width: 14),
                      Expanded(child: driverField),
                      const SizedBox(width: 14),
                      Expanded(child: remarksField),
                    ],
                  );
                } else if (constraints.maxWidth >= 550) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: distributorField),
                          const SizedBox(width: 12),
                          Expanded(child: vehicleField),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: driverField),
                          const SizedBox(width: 12),
                          Expanded(child: remarksField),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      distributorField,
                      const SizedBox(height: 12),
                      vehicleField,
                      const SizedBox(height: 12),
                      driverField,
                      const SizedBox(height: 12),
                      remarksField,
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 24),

            // 3. Products Supplied Header
            Row(
              children: [
                const Text(
                  'Products Supplied',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_inlineProductRows.length} item${_inlineProductRows.length == 1 ? '' : 's'})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 4. Products Table
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;

                return Column(
                  children: [
                    // Desktop Table Header
                    if (isWide)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 36,
                              child: Center(
                                child: Text('#', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              ),
                            ),
                            Container(width: 1, height: 16, color: const Color(0xFFCBD5E1)),
                            const Expanded(
                              flex: 4,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              ),
                            ),
                            Container(width: 1, height: 16, color: const Color(0xFFCBD5E1)),
                            const Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('Crates', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              ),
                            ),
                            Container(width: 1, height: 16, color: const Color(0xFFCBD5E1)),
                            const Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('Pieces', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              ),
                            ),
                            Container(width: 1, height: 16, color: const Color(0xFFCBD5E1)),
                            const Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('Quantity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              ),
                            ),
                            Container(width: 1, height: 16, color: const Color(0xFFCBD5E1)),
                            const Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('Cost', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              ),
                            ),
                            Container(width: 1, height: 16, color: const Color(0xFFCBD5E1)),
                            const SizedBox(
                              width: 50,
                              child: Center(
                                child: Text('Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Product Item Rows (each entry is a single clean card with 14px separation)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _inlineProductRows.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final row = _inlineProductRows[index];
                        final ProductModel? selectedProduct = row.productId != null
                            ? catalog.cast<ProductModel?>().firstWhere(
                                (p) => p?.productId == row.productId,
                                orElse: () => null,
                              )
                            : null;

                        // Exclude products already selected in other rows to prevent duplicate entries
                        final otherSelectedIds = _inlineProductRows
                            .asMap()
                            .entries
                            .where((entry) => entry.key != index && entry.value.productId != null)
                            .map((entry) => entry.value.productId!)
                            .toSet();

                        final availableCatalog = catalog.where((p) {
                          return p.productId == row.productId || !otherSelectedIds.contains(p.productId);
                        }).toList();

                        if (!isWide) {
                          return _buildMobileProductRowCard(
                            index: index,
                            row: row,
                            selectedProduct: selectedProduct,
                            catalog: catalog,
                            availableCatalog: availableCatalog,
                          );
                        }

                        return _buildDesktopProductRow(
                          index: index,
                          row: row,
                          selectedProduct: selectedProduct,
                          catalog: catalog,
                          availableCatalog: availableCatalog,
                        );
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 14),

            // Long bar "+ Add Product" button (above reset & save dispatch buttons)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addInlineProductRow(catalog),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: const Text(
                  '+ Add Product',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF166534),
                  backgroundColor: const Color(0xFFF0FDF4),
                  side: const BorderSide(color: Color(0xFF86EFAC), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 5. Action Buttons (Reset Form + Save Vehicle Dispatch)
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _resetInlineForm,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Reset Form',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF166534),
                    side: const BorderSide(color: Color(0xFF166534)),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isInlineSaving ? null : _submitInlineVehicle,
                    icon: _isInlineSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 20),
                    label: Text(
                      _isInlineSaving ? 'Saving Vehicle Dispatch...' : 'Save Vehicle Dispatch',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF166534),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // HELPER METHODS FOR NEW VEHICLE ENTRY FORM
  // ===========================================================================

  Widget _buildFieldWithTopLabel({
    required String label,
    required Widget child,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildDesktopProductRow({
    required int index,
    required _ProductRowDraft row,
    required ProductModel? selectedProduct,
    required List<ProductModel> catalog,
    required List<ProductModel> availableCatalog,
  }) {
    final bulkSuffix = _getBulkUnitSuffix(selectedProduct);
    final pieceSuffix = _getPieceUnitSuffix(selectedProduct);
    final baseSuffix = _getBaseUnitSuffix(selectedProduct);
    final hasCrates = selectedProduct == null || selectedProduct.hasCrateConfiguration;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Index Cell
          SizedBox(
            width: 36,
            child: Center(
              child: Text(
                '#${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),

          // 2. Product Selector Cell
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButtonFormField<String>(
                initialValue: row.productId,
                isExpanded: true,
                decoration: _desktopTableCellInputDecoration(hint: 'Select product'),
                hint: const Text(
                  'Select product',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  overflow: TextOverflow.ellipsis,
                ),
                selectedItemBuilder: (context) {
                  return availableCatalog.map((p) {
                    return Text.rich(
                      TextSpan(
                        text: p.productName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                        children: [
                          if (p.packSizeDisplay.isNotEmpty)
                            TextSpan(
                              text: ' (${p.packSizeDisplay})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );
                  }).toList();
                },
                items: availableCatalog.map((p) {
                  return DropdownMenuItem<String>(
                    value: p.productId,
                    child: Text.rich(
                      TextSpan(
                        text: p.productName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                        children: [
                          if (p.packSizeDisplay.isNotEmpty)
                            TextSpan(
                              text: ' (${p.packSizeDisplay})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      row.productId = val;
                      final np = catalog.firstWhere((p) => p.productId == val);
                      if (row.lastEditedField == 'crates' && row.cratesController.text.isNotEmpty) {
                        _syncRowCalculations(row, np, 'crates');
                      } else if (row.piecesController.text.isNotEmpty) {
                        _syncRowCalculations(row, np, 'pieces');
                      } else if (row.baseQtyController.text.isNotEmpty) {
                        _syncRowCalculations(row, np, 'baseQty');
                      } else {
                        _syncRowCalculations(row, np, 'crates');
                      }
                    });
                  }
                },
              ),
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),

          // 3. Crates Input Cell
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextFormField(
                controller: row.cratesController,
                focusNode: row.cratesFocusNode,
                enabled: hasCrates,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _syncRowCalculations(row, selectedProduct, 'crates'),
                decoration: _desktopTableCellInputDecoration(
                  hint: hasCrates ? '0' : 'N/A',
                  suffixText: bulkSuffix,
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: hasCrates ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),

          // 4. Pieces Input Cell
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextFormField(
                controller: row.piecesController,
                focusNode: row.piecesFocusNode,
                keyboardType: TextInputType.number,
                onChanged: (_) => _syncRowCalculations(row, selectedProduct, 'pieces'),
                decoration: _desktopTableCellInputDecoration(
                  hint: '0',
                  suffixText: pieceSuffix,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),

          // 5. Quantity (L / kg) Input Cell
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextFormField(
                controller: row.baseQtyController,
                focusNode: row.baseQtyFocusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _syncRowCalculations(row, selectedProduct, 'baseQty'),
                decoration: _desktopTableCellInputDecoration(
                  hint: '0',
                  suffixText: baseSuffix,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),

          // 6. Cost (₹) Live Cell
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatRowCost(row, selectedProduct),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (selectedProduct != null && selectedProduct.hasPriceConfiguration)
                    Text(
                      '₹${Formatters.formatSmart(selectedProduct.pricePerPiece)} / $pieceSuffix',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),

          // 7. Action Cell
          SizedBox(
            width: 50,
            child: Center(
              child: IconButton(
                tooltip: 'Delete product',
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                onPressed: () => _removeInlineProductRow(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                splashRadius: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileProductRowCard({
    required int index,
    required _ProductRowDraft row,
    required ProductModel? selectedProduct,
    required List<ProductModel> catalog,
    required List<ProductModel> availableCatalog,
  }) {
    final bulkSuffix = _getBulkUnitSuffix(selectedProduct);
    final pieceSuffix = _getPieceUnitSuffix(selectedProduct);
    final baseSuffix = _getBaseUnitSuffix(selectedProduct);
    final hasCrates = selectedProduct == null || selectedProduct.hasCrateConfiguration;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item #${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              IconButton(
                tooltip: 'Delete product',
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                onPressed: () => _removeInlineProductRow(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: row.productId,
            isExpanded: true,
            decoration: _tableCellInputDecoration(hint: 'Select product'),
            hint: const Text(
              'Select product',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              overflow: TextOverflow.ellipsis,
            ),
            selectedItemBuilder: (context) {
              return availableCatalog.map((p) {
                return Text.rich(
                  TextSpan(
                    text: p.productName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                    children: [
                      if (p.packSizeDisplay.isNotEmpty)
                        TextSpan(
                          text: ' (${p.packSizeDisplay})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                );
              }).toList();
            },
            items: availableCatalog.map((p) {
              return DropdownMenuItem<String>(
                value: p.productId,
                child: Text.rich(
                  TextSpan(
                    text: p.productName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                    children: [
                      if (p.packSizeDisplay.isNotEmpty)
                        TextSpan(
                          text: ' (${p.packSizeDisplay})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  row.productId = val;
                  final np = catalog.firstWhere((p) => p.productId == val);
                  if (row.lastEditedField == 'crates' && row.cratesController.text.isNotEmpty) {
                    _syncRowCalculations(row, np, 'crates');
                  } else if (row.piecesController.text.isNotEmpty) {
                    _syncRowCalculations(row, np, 'pieces');
                  } else if (row.baseQtyController.text.isNotEmpty) {
                    _syncRowCalculations(row, np, 'baseQty');
                  } else {
                    _syncRowCalculations(row, np, 'crates');
                  }
                });
              }
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Crates', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: row.cratesController,
                      focusNode: row.cratesFocusNode,
                      enabled: hasCrates,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _syncRowCalculations(row, selectedProduct, 'crates'),
                      decoration: _tableCellInputDecoration(
                        hint: hasCrates ? '0' : 'N/A',
                        suffixText: bulkSuffix,
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: hasCrates ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pieces ($pieceSuffix)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: row.piecesController,
                      focusNode: row.piecesFocusNode,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _syncRowCalculations(row, selectedProduct, 'pieces'),
                      decoration: _tableCellInputDecoration(
                        hint: '0',
                        suffixText: pieceSuffix,
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Qty ($baseSuffix)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: row.baseQtyController,
                      focusNode: row.baseQtyFocusNode,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _syncRowCalculations(row, selectedProduct, 'baseQty'),
                      decoration: _tableCellInputDecoration(
                        hint: '0',
                        suffixText: baseSuffix,
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (selectedProduct != null && selectedProduct.hasCrateConfiguration)
                  Text(
                    '${selectedProduct.piecesPerCrate} $pieceSuffix / $bulkSuffix',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  'Cost: ${_formatRowCost(row, selectedProduct)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _desktopTableCellInputDecoration({required String hint, String? suffixText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      suffixText: suffixText,
      suffixStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF166534), width: 1.5),
      ),
    );
  }

  InputDecoration _boxedInputDecoration({
    required String hint,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFF64748B)) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF166534), width: 1.5),
      ),
    );
  }

  InputDecoration _tableCellInputDecoration({required String hint, String? suffixText}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      suffixText: suffixText,
      suffixStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF166534), width: 1.5),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: DISPATCH RECORDS (VEHICLE-WISE RECORDS WITH CHIPS & ACTIONS)
  // ===========================================================================

  Widget _buildDispatchRecordsTab(DispatchState state, bool isMobile) {
    final dispatches = state.filteredDispatches;

    return Column(
      children: [
        // Filter & Search Controls
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(dispatchProvider.notifier).setSearchQuery(val);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search by vehicle (e.g. AS-01-A), distributor, driver, products...',
                    hintStyle: TextStyle(fontSize: AppTextSizes.body, color: AppColors.textSecondary),
                    prefixIcon: Icon(Icons.search, size: 18),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(dispatchProvider.notifier).setSearchQuery('');
                  },
                ),
              const SizedBox(width: 12),
              // Distributor dropdown filter
              DropdownButton<String?>(
                value: state.distributorFilter,
                hint: const Text('All Distributors', style: TextStyle(fontSize: AppTextSizes.caption)),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Distributors', style: TextStyle(fontSize: AppTextSizes.caption)),
                  ),
                  ...state.availableDistributors.map((d) {
                    return DropdownMenuItem<String?>(
                      value: d,
                      child: Text(d, style: const TextStyle(fontSize: AppTextSizes.caption)),
                    );
                  }),
                ],
                onChanged: (val) {
                  ref.read(dispatchProvider.notifier).setDistributorFilter(val);
                },
              ),
              const SizedBox(width: 8),
              // CSV Export Button
              ElevatedButton.icon(
                onPressed: dispatches.isEmpty
                    ? null
                    : () {
                        final csv = ref
                            .read(dispatchProvider.notifier)
                            .generateVehicleRecordsCsv(dispatches);
                        downloadLedgerCsv('dispatch_records_${state.selectedDate}.csv', csv);
                      },
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Export Records (CSV)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Records Table
        Expanded(
          child: AppCard(
            child: dispatches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        const Text(
                          'No Vehicle Dispatches Found for this Date',
                          style: TextStyle(
                            fontSize: AppTextSizes.subheading,
                            fontWeight: AppFontWeights.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Switch to "Enter Dispatch" tab to add morning vehicle dispatches.',
                          style: TextStyle(fontSize: AppTextSizes.body, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Table(
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: AppColors.divider.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(0.6), // S.No
                        1: FlexColumnWidth(1.1), // Time
                        2: FlexColumnWidth(1.6), // Vehicle
                        3: FlexColumnWidth(1.8), // Distributor
                        4: FlexColumnWidth(1.3), // Driver
                        5: FlexColumnWidth(3.4), // Products Supplied Chips
                        6: FlexColumnWidth(1.3), // Recorded By
                        7: FlexColumnWidth(1.1), // Status
                        8: FlexColumnWidth(1.2), // Actions
                      },
                      children: [
                        // Header
                        TableRow(
                          decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                          children: [
                            _buildTableHeaderCell('#'),
                            _buildTableHeaderCell('Time'),
                            _buildTableHeaderCell('Vehicle No'),
                            _buildTableHeaderCell('Distributor'),
                            _buildTableHeaderCell('Driver'),
                            _buildTableHeaderCell('Products Supplied in Vehicle'),
                            _buildTableHeaderCell('Recorded By'),
                            _buildTableHeaderCell('Status'),
                            _buildTableHeaderCell('Actions', alignRight: true),
                          ],
                        ),
                        // Data rows
                        ...dispatches.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final d = entry.value;

                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Text(
                                  '$idx',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: AppFontWeights.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Text(
                                  d.dispatchTime.isNotEmpty
                                      ? d.dispatchTime
                                      : '${d.dispatchedAt.hour.toString().padLeft(2, '0')}:${d.dispatchedAt.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.semiBold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    d.vehicleNumber,
                                    style: const TextStyle(
                                      fontWeight: AppFontWeights.bold,
                                      fontSize: 12,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Text(
                                  d.distributorName,
                                  style: const TextStyle(
                                    fontWeight: AppFontWeights.bold,
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Text(
                                  d.driverName.isNotEmpty ? d.driverName : '—',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ),
                              // Products Supplied Chips
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: d.items.map((item) {
                                    return Container(
                                      constraints: const BoxConstraints(maxWidth: 160),
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: Text(
                                        '${item.shortCode}: ${item.formattedQuantity}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: AppFontWeights.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Text(
                                  d.recordedBy,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: StatusBadge.success(d.status),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
                                      tooltip: 'View Details',
                                      onPressed: () => _openVehicleDetails(d),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0F766E)),
                                      tooltip: 'Edit Dispatch',
                                      onPressed: () => _openDispatchDialog(existing: d),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                                      tooltip: 'Delete Dispatch',
                                      onPressed: () => _confirmDelete(d),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: PRODUCT WISE (PERIOD REPORT WITH CONVERSIONS & EXPORT)
  // ===========================================================================

  Widget _buildProductWiseTab(DispatchState state, bool isMobile) {
    final summaries = state.productSummariesForDateRange;

    return Column(
      children: [
        // Preset Date Range Filter Bar
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Wrap(
                spacing: 6,
                children: ['Today', 'Yesterday', 'Last 7 Days', 'Last 30 Days', 'All Time'].map((preset) {
                  final isSelected = state.datePreset == preset;
                  return ChoiceChip(
                    label: Text(preset),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(dispatchProvider.notifier).setDatePreset(preset);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? AppFontWeights.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Range: ${state.rangeStartDate} to ${state.rangeEndDate}',
                  style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.bold, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: summaries.isEmpty
                    ? null
                    : () {
                        final csv = ref.read(dispatchProvider.notifier).generateProductWiseCsv(
                              summaries,
                              '${state.rangeStartDate} to ${state.rangeEndDate}',
                            );
                        downloadLedgerCsv('product_wise_dispatch_${state.datePreset}.csv', csv);
                      },
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Export Product Wise (CSV)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: AppCard(
            child: summaries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        const Text(
                          'No Product Dispatches Recorded in this Date Range',
                          style: TextStyle(
                            fontSize: AppTextSizes.subheading,
                            fontWeight: AppFontWeights.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Select a different date preset above or record new dispatches.',
                          style: TextStyle(fontSize: AppTextSizes.body, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Table(
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: AppColors.divider.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(1.2), // Code
                        1: FlexColumnWidth(3.0), // Name
                        2: FlexColumnWidth(1.2), // Pack
                        3: FlexColumnWidth(1.2), // Crates
                        4: FlexColumnWidth(1.2), // Pieces
                        5: FlexColumnWidth(1.6), // Equivalent Base
                        6: FlexColumnWidth(1.2), // Vehicles
                        7: FlexColumnWidth(1.5), // Value (₹)
                      },
                      children: [
                        // Header
                        TableRow(
                          decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                          children: [
                            _buildTableHeaderCell('Item Code'),
                            _buildTableHeaderCell('Product Name'),
                            _buildTableHeaderCell('Pack Size'),
                            _buildTableHeaderCell('Total Crates', alignRight: true),
                            _buildTableHeaderCell('Total Pieces', alignRight: true),
                            _buildTableHeaderCell('Base Unit Equivalent', alignRight: true),
                            _buildTableHeaderCell('Vehicles', alignRight: true),
                            _buildTableHeaderCell('Total Value (₹)', alignRight: true),
                          ],
                        ),
                        ...summaries.map((s) {
                          final isLiquid = s.normalizedUnit.toLowerCase().startsWith('l');
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: Text(
                                  s.itemCode,
                                  style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: Text(
                                  s.productName,
                                  style: const TextStyle(
                                    fontWeight: AppFontWeights.bold,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: Text(s.packSizeDisplay, style: const TextStyle(fontSize: 12)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    s.formattedCrates,
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    s.formattedPieces,
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isLiquid ? const Color(0xFFF0F9FF) : const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isLiquid ? const Color(0xFFBAE6FD) : const Color(0xFFFDE68A),
                                      ),
                                    ),
                                    child: Text(
                                      s.formattedQuantity,
                                      style: TextStyle(
                                        fontWeight: AppFontWeights.bold,
                                        fontSize: 12,
                                        color: isLiquid ? const Color(0xFF0369A1) : const Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${s.vehicleCount}',
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    s.formattedRevenue,
                                    style: const TextStyle(
                                      fontWeight: AppFontWeights.bold,
                                      fontSize: 13,
                                      color: Color(0xFF047857),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 4: DISTRIBUTOR WISE (DISTRIBUTOR ROUTES, VEHICLE TRIPS & BREAKDOWN)
  // ===========================================================================

  Widget _buildDistributorWiseTab(DispatchState state, bool isMobile) {
    final summaries = state.distributorSummariesForDateRange;

    return Column(
      children: [
        // Filter bar
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Wrap(
                spacing: 6,
                children: ['Today', 'Yesterday', 'Last 7 Days', 'Last 30 Days', 'All Time'].map((preset) {
                  final isSelected = state.datePreset == preset;
                  return ChoiceChip(
                    label: Text(preset),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(dispatchProvider.notifier).setDatePreset(preset);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? AppFontWeights.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: summaries.isEmpty
                    ? null
                    : () {
                        final csv = ref.read(dispatchProvider.notifier).generateDistributorWiseCsv(
                              summaries,
                              '${state.rangeStartDate} to ${state.rangeEndDate}',
                            );
                        downloadLedgerCsv('distributor_wise_dispatch_${state.datePreset}.csv', csv);
                      },
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Export Distributor Wise (CSV)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: AppCard(
            child: summaries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storefront_outlined, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        const Text(
                          'No Distributor Dispatches Found',
                          style: TextStyle(
                            fontSize: AppTextSizes.subheading,
                            fontWeight: AppFontWeights.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Select a different date preset above to view distributor breakdown.',
                          style: TextStyle(fontSize: AppTextSizes.body, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: summaries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = summaries[index];

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
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
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      item.distributorName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: AppFontWeights.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    StatusBadge.info('${item.dispatches.length} Trips / Dispatches'),
                                    StatusBadge.success('${item.vehicles.length} Vehicles'),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),

                            // Total Stats Row
                            Row(
                              children: [
                                Text(
                                  'Vehicles Deployed: ${item.vehicles.join(", ")}',
                                  style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.semiBold, color: AppColors.textSecondary),
                                ),
                                const Spacer(),
                                Text(
                                  'Total Crates: ${Formatters.formatSmart(item.totalCrates)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: AppFontWeights.bold),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  'Liquid Volume: ${Formatters.formatSmart(item.totalLitres)} L',
                                  style: const TextStyle(fontSize: 13, fontWeight: AppFontWeights.bold, color: Color(0xFF0284C7)),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  'Curd/Solids: ${Formatters.formatSmart(item.totalKg)} kg',
                                  style: const TextStyle(fontSize: 13, fontWeight: AppFontWeights.bold, color: Color(0xFFD97706)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Product breakdown chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: item.productItems.map((pi) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Text(
                                    '${pi.shortCode}: ${pi.formattedQuantity}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: AppFontWeights.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 5: REPORTS (EXECUTIVE EXPORT CENTER & ANALYTICS)
  // ===========================================================================

  Widget _buildReportsTab(DispatchState state, bool isMobile) {
    final dispatches = state.dispatchesForDateRange;
    final productSummaries = state.productSummariesForDateRange;
    final distributorSummaries = state.distributorSummariesForDateRange;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner directing to Reports Catalogue
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Looking for Consolidated Dispatch Reports & Catalogue?',
                        style: TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13, color: Color(0xFF065F46)),
                      ),
                      Text(
                        'Today\'s full summary rollup, product catalogue totals & sales analytics are now located in the Reports Catalogue section.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(targetReportSectionProvider.notifier).state = 'dispatch';
                    ref.read(shellNavigationIndexProvider.notifier).state = 10;
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                  label: const Text('Open in Reports'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Filter presets
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Text(
                  'Reporting Period:',
                  style: TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 6,
                  children: ['Today', 'Yesterday', 'Last 7 Days', 'Last 30 Days', 'All Time'].map((preset) {
                    final isSelected = state.datePreset == preset;
                    return ChoiceChip(
                      label: Text(preset),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(dispatchProvider.notifier).setDatePreset(preset);
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? AppFontWeights.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const Spacer(),
                Text(
                  'Showing data from ${state.rangeStartDate} to ${state.rangeEndDate}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Instant Export Action Cards
          const Text(
            'Instant CSV Export Center',
            style: TextStyle(
              fontSize: AppTextSizes.subheading,
              fontWeight: AppFontWeights.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildExportActionCard(
                  title: 'Vehicle-Wise Records (CSV)',
                  subtitle: 'Full list of vehicles dispatched with driver, distributor, and line items',
                  icon: Icons.local_shipping_rounded,
                  color: AppColors.primary,
                  onDownload: () {
                    final csv = ref.read(dispatchProvider.notifier).generateVehicleRecordsCsv(dispatches);
                    downloadLedgerCsv('dispatch_vehicles_${state.datePreset}.csv', csv);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildExportActionCard(
                  title: 'Product-Wise Totals (CSV)',
                  subtitle: 'Consolidated product totals, crate conversions, base units & revenue',
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFF0F766E),
                  onDownload: () {
                    final csv = ref.read(dispatchProvider.notifier).generateProductWiseCsv(
                          productSummaries,
                          '${state.rangeStartDate} to ${state.rangeEndDate}',
                        );
                    downloadLedgerCsv('dispatch_products_${state.datePreset}.csv', csv);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildExportActionCard(
                  title: 'Distributor-Wise Summary (CSV)',
                  subtitle: 'Breakdown of dispatches, vehicle deployments and volumes per distributor',
                  icon: Icons.storefront_rounded,
                  color: const Color(0xFF2563EB),
                  onDownload: () {
                    final csv = ref.read(dispatchProvider.notifier).generateDistributorWiseCsv(
                          distributorSummaries,
                          '${state.rangeStartDate} to ${state.rangeEndDate}',
                        );
                    downloadLedgerCsv('dispatch_distributors_${state.datePreset}.csv', csv);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Daily History Breakdown Table
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DAILY DISPATCH HISTORICAL LOG',
                      style: TextStyle(
                        fontSize: AppTextSizes.caption,
                        fontWeight: AppFontWeights.bold,
                        letterSpacing: 1.1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    StatusBadge.info('${state.dateWiseHistory.length} Recorded Dates'),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: AppColors.divider.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1.8), // Date
                    1: FlexColumnWidth(1.2), // Vehicles
                    2: FlexColumnWidth(1.2), // Distributors
                    3: FlexColumnWidth(1.2), // Product Lines
                    4: FlexColumnWidth(1.4), // Crates
                    5: FlexColumnWidth(1.4), // Litres
                    6: FlexColumnWidth(1.4), // Kg
                    7: FlexColumnWidth(1.2), // Action
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                      children: [
                        _buildTableHeaderCell('Dispatch Date'),
                        _buildTableHeaderCell('Vehicles', alignRight: true),
                        _buildTableHeaderCell('Distributors', alignRight: true),
                        _buildTableHeaderCell('Product Lines', alignRight: true),
                        _buildTableHeaderCell('Total Crates', alignRight: true),
                        _buildTableHeaderCell('Liquid (L)', alignRight: true),
                        _buildTableHeaderCell('Curd/Solids (kg)', alignRight: true),
                        _buildTableHeaderCell('Action', alignRight: true),
                      ],
                    ),
                    ...state.dateWiseHistory.map((h) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            child: Text(
                              _formatDisplayDate(h.date),
                              style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text('${h.vehiclesCount}', style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text('${h.distributorsCount}', style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text('${h.productLinesCount}', style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                Formatters.formatSmart(h.totalCrates),
                                style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${Formatters.formatSmart(h.totalLitres)} L',
                                style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13, color: Color(0xFF0284C7)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${Formatters.formatSmart(h.totalKg)} kg',
                                style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13, color: Color(0xFFD97706)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  ref.read(dispatchProvider.notifier).setSelectedDate(h.date);
                                  _tabController.animateTo(1); // Go to Dispatch Records
                                },
                                child: const Text('View Date'),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onDownload,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: AppFontWeights.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Download CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: AppTextSizes.caption,
            fontWeight: AppFontWeights.bold,
            letterSpacing: 0.5,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}



// =============================================================================
// PRODUCT ROW DRAFT FOR VEHICLE FORM
// =============================================================================

class _ProductRowDraft {
  String? productId;
  String inputMode;
  String lastEditedField = 'crates'; // 'crates', 'pieces', 'baseQty'
  final TextEditingController quantityController;
  final FocusNode quantityFocusNode;
  final TextEditingController cratesController;
  final FocusNode cratesFocusNode;
  final TextEditingController piecesController;
  final FocusNode piecesFocusNode;
  final TextEditingController baseQtyController;
  final FocusNode baseQtyFocusNode;

  _ProductRowDraft({
    this.productId,
    this.inputMode = 'Pieces',
    String initialQty = '',
    String initialCrates = '',
    String initialPieces = '',
    String initialBaseQty = '',
  })  : quantityController = TextEditingController(text: initialQty.isNotEmpty ? initialQty : initialPieces),
        quantityFocusNode = FocusNode(),
        cratesController = TextEditingController(text: initialCrates),
        cratesFocusNode = FocusNode(),
        piecesController = TextEditingController(text: initialPieces.isNotEmpty ? initialPieces : initialQty),
        piecesFocusNode = FocusNode(),
        baseQtyController = TextEditingController(text: initialBaseQty),
        baseQtyFocusNode = FocusNode();

  void dispose() {
    quantityController.dispose();
    quantityFocusNode.dispose();
    cratesController.dispose();
    cratesFocusNode.dispose();
    piecesController.dispose();
    piecesFocusNode.dispose();
    baseQtyController.dispose();
    baseQtyFocusNode.dispose();
  }

  void clear() {
    quantityController.clear();
    cratesController.clear();
    piecesController.clear();
    baseQtyController.clear();
  }
}

// =============================================================================
// VEHICLE DISPATCH DIALOG (FOR EDITING & NEW VEHICLE POPUP)
// =============================================================================

class _VehicleDispatchDialog extends ConsumerStatefulWidget {
  final VehicleDispatch? existing;

  const _VehicleDispatchDialog({this.existing});

  @override
  ConsumerState<_VehicleDispatchDialog> createState() => _VehicleDispatchDialogState();
}

class _VehicleDispatchDialogState extends ConsumerState<_VehicleDispatchDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _distributorController;
  late TextEditingController _vehicleController;
  late TextEditingController _driverController;
  late TextEditingController _routeController;
  late TextEditingController _timeController;
  late TextEditingController _remarksController;
  late String _dispatchDate;

  final List<_ProductRowDraft> _productDrafts = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    final now = DateTime.now();

    final defaultDate = ref.read(dispatchProvider).selectedDate;
    _dispatchDate = d?.dispatchDate ?? defaultDate;

    _distributorController = TextEditingController(text: d?.distributorName ?? '');
    _vehicleController = TextEditingController(text: d?.vehicleNumber ?? '');
    _driverController = TextEditingController(text: d?.driverName ?? '');
    _routeController = TextEditingController(text: d?.route ?? '');
    _timeController = TextEditingController(
      text: d?.dispatchTime ??
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}',
    );
    _remarksController = TextEditingController(text: d?.remarks ?? '');

    if (d != null && d.items.isNotEmpty) {
      for (final item in d.items) {
        _productDrafts.add(
          _ProductRowDraft(
            productId: item.productId,
            inputMode: item.inputMode,
            initialQty: item.inputQuantity == item.inputQuantity.roundToDouble()
                ? item.inputQuantity.toInt().toString()
                : item.inputQuantity.toString(),
          ),
        );
      }
    } else {
      final defaultProduct = DairyProducts.officialProducts.first;
      _productDrafts.add(
        _ProductRowDraft(
          productId: defaultProduct.productId,
          inputMode: defaultProduct.allowedInputModes.contains('Pieces')
              ? 'Pieces'
              : defaultProduct.allowedInputModes.first,
        ),
      );
    }
  }

  @override
  void dispose() {
    _distributorController.dispose();
    _vehicleController.dispose();
    _driverController.dispose();
    _routeController.dispose();
    _timeController.dispose();
    _remarksController.dispose();
    for (final row in _productDrafts) {
      row.quantityController.dispose();
      row.quantityFocusNode.dispose();
    }
    super.dispose();
  }

  void _addProductRow(List<ProductModel> catalog) {
    setState(() {
      final first = catalog.isNotEmpty ? catalog.first : DairyProducts.officialProducts.first;
      _productDrafts.add(
        _ProductRowDraft(
          productId: first.productId,
          inputMode: first.allowedInputModes.contains('Pieces')
              ? 'Pieces'
              : first.allowedInputModes.first,
        ),
      );
    });
  }

  void _removeProductRow(int index) {
    if (_productDrafts.length > 1) {
      setState(() {
        _productDrafts[index].quantityController.dispose();
        _productDrafts[index].quantityFocusNode.dispose();
        _productDrafts.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_productDrafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product to the vehicle dispatch.'),
          backgroundColor: Color(0xFF991B1B),
        ),
      );
      return;
    }

    final catalog = ref.read(dispatchProvider).catalogProducts;
    final List<DispatchItem> items = [];
    final dispatchId = widget.existing?.id ?? 'DISP-${DateTime.now().millisecondsSinceEpoch}';

    for (int i = 0; i < _productDrafts.length; i++) {
      final draft = _productDrafts[i];
      if (draft.productId == null || draft.productId!.isEmpty) continue;

      final qty = double.tryParse(draft.quantityController.text.trim()) ?? 0.0;
      if (qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quantity must be greater than 0 for product row #${i + 1}.'),
            backgroundColor: const Color(0xFF991B1B),
          ),
        );
        return;
      }

      final product = catalog.firstWhere(
        (p) => p.productId == draft.productId,
        orElse: () => catalog.first,
      );

      items.add(
        DispatchItem.fromInput(
          id: '$dispatchId-ITEM-${i + 1}',
          dispatchId: dispatchId,
          product: product,
          inputMode: draft.inputMode,
          inputQuantity: qty,
        ),
      );
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify at least one product with quantity > 0.'),
          backgroundColor: Color(0xFF991B1B),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final currentUser = ref.read(authProvider);
    final now = DateTime.now();

    final record = VehicleDispatch(
      id: dispatchId,
      dispatchDate: _dispatchDate,
      vehicleNumber: _vehicleController.text.trim().toUpperCase(),
      distributorName: _distributorController.text.trim(),
      driverName: _driverController.text.trim(),
      route: _routeController.text.trim(),
      dispatchTime: _timeController.text.trim(),
      remarks: _remarksController.text.trim(),
      status: widget.existing?.status ?? 'Dispatched',
      createdBy: widget.existing?.createdBy ?? (currentUser.fullName.isNotEmpty ? currentUser.fullName : 'Plant Operator'),
      items: items,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    final notifier = ref.read(dispatchProvider.notifier);
    final bool success;
    if (widget.existing != null) {
      success = await notifier.updateDispatch(record);
    } else {
      success = await notifier.saveDispatch(record);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existing != null
                  ? '✓ Vehicle dispatch ${record.vehicleNumber} updated successfully!'
                  : '✓ Vehicle dispatch ${record.vehicleNumber} saved successfully!',
            ),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(dispatchProvider).error ?? 'Failed to save vehicle dispatch.'),
            backgroundColor: const Color(0xFF991B1B),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.read(dispatchProvider).catalogProducts;
    final distributors = ref.read(dispatchProvider).availableDistributors;
    final isEditing = widget.existing != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 760),
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_note_rounded : Icons.add_task_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Vehicle Dispatch' : 'New Vehicle Dispatch',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: AppFontWeights.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Dispatch Date: $_dispatchDate',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Inputs
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _vehicleController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Number *',
                        hintText: 'e.g. AS-01-EC-4421',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Autocomplete<String>(
                      initialValue: TextEditingValue(text: _distributorController.text),
                      optionsBuilder: (textVal) {
                        if (textVal.text.isEmpty) return distributors;
                        return distributors.where((d) => d.toLowerCase().contains(textVal.text.toLowerCase()));
                      },
                      onSelected: (val) => _distributorController.text = val,
                      fieldViewBuilder: (ctx, ctrl, fn, onDone) {
                        ctrl.addListener(() => _distributorController.text = ctrl.text);
                        return TextFormField(
                          controller: ctrl,
                          focusNode: fn,
                          decoration: InputDecoration(
                            labelText: 'Distributor *',
                            hintText: 'Select distributor',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _driverController,
                      decoration: InputDecoration(
                        labelText: 'Driver Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _remarksController,
                      decoration: InputDecoration(
                        labelText: 'Remarks',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Products Supplied in Vehicle',
                    style: TextStyle(fontWeight: AppFontWeights.bold, fontSize: 14),
                  ),
                  TextButton.icon(
                    onPressed: () => _addProductRow(catalog),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Product'),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Expanded(
                child: ListView.separated(
                  itemCount: _productDrafts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final row = _productDrafts[index];
                    final product = catalog.firstWhere(
                      (p) => p.productId == row.productId,
                      orElse: () => catalog.first,
                    );

                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: DropdownButtonFormField<String>(
                              initialValue: row.productId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Product',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              items: catalog.map((p) {
                                return DropdownMenuItem<String>(
                                  value: p.productId,
                                  child: Text('${p.productName} (${p.packSizeDisplay})', overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    row.productId = val;
                                    final np = catalog.firstWhere((p) => p.productId == val);
                                    if (!np.allowedInputModes.contains(row.inputMode)) {
                                      row.inputMode = np.allowedInputModes.first;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              key: ValueKey('${row.productId}_${row.inputMode}'),
                              initialValue: product.allowedInputModes.contains(row.inputMode)
                                  ? row.inputMode
                                  : product.allowedInputModes.first,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              items: product.allowedInputModes.map((u) {
                                return DropdownMenuItem<String>(
                                  value: u,
                                  child: Text(u),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => row.inputMode = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: row.quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Qty',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
                            onPressed: () => _removeProductRow(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(_isSaving ? 'Saving...' : (isEditing ? 'Save Changes' : 'Save Dispatch')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// VEHICLE DETAIL DIALOG (VIEW PRODUCTS & EQUIVALENTS)
// =============================================================================

class _VehicleDetailDialog extends StatelessWidget {
  final VehicleDispatch dispatch;

  const _VehicleDetailDialog({required this.dispatch});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dispatch.vehicleNumber,
                          style: const TextStyle(fontSize: 18, fontWeight: AppFontWeights.bold),
                        ),
                        Text(
                          'Distributor: ${dispatch.distributorName}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Metadata info
            Row(
              children: [
                _buildInfoColumn('Date', dispatch.dispatchDate),
                _buildInfoColumn('Driver', dispatch.driverName.isNotEmpty ? dispatch.driverName : '—'),
                _buildInfoColumn('Recorded By', dispatch.recordedBy),
                _buildInfoColumn('Status', dispatch.status),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Products Supplied:',
              style: TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),

            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: dispatch.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = dispatch.items[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.productName} (${item.packSizeDisplay})',
                          style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13),
                        ),
                        Text(
                          '${item.inputQuantity} ${item.inputMode} • ${item.formattedQuantity}',
                          style: const TextStyle(fontWeight: AppFontWeights.bold, color: AppColors.primary, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.bold)),
        ],
      ),
    );
  }
}
