import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/dairy_products.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/stock_ledger_exporter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/metric_card.dart';
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

  static const List<String> authorizedLoggers = [
    'Biraj Goswami',
    'Bhriguraj Borah',
    'Pranjit Das',
    'Parag Jyoti Patowary',
    'Ritul Kaushik',
    'Joydeep Chanda',
    'Navjyoti Barman',
    'Dipankar Barman',
    'Prasenjit Das',
    'Rupam Boruah',
  ];

  // Inline Form State for Tab 1 (Enter Dispatch)
  final _inlineFormKey = GlobalKey<FormState>();
  final TextEditingController _inlineVehicleController = TextEditingController();
  final TextEditingController _inlineDistributorController = TextEditingController();
  final TextEditingController _inlineDriverController = TextEditingController();
  final TextEditingController _inlineRemarksController = TextEditingController();
  final List<_ProductRowDraft> _inlineProductRows = [];
  bool _isInlineSaving = false;
  String? _selectedDistributorName;

  // Crates Allocation State (opens after clicking Save Vehicle Dispatch)
  bool _showCratesEntrySection = false;
  final TextEditingController _productCratesController = TextEditingController();
  final TextEditingController _milkCratesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 3 Tabs: Enter Dispatch, Product Wise, Distributor Wise
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

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
    _productCratesController.dispose();
    _milkCratesController.dispose();
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



  Future<void> _pickProductWiseDate(String currentDateStr) async {
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
      ref.read(dispatchProvider.notifier).setDateRange(dateStr, dateStr);
      ref.read(dispatchProvider.notifier).setSelectedDate(dateStr);
    }
  }

  void _shiftProductWiseDate(int days) {
    final state = ref.read(dispatchProvider);
    final currentStr = state.datePreset == 'Custom' ? state.rangeStartDate : state.selectedDate;
    try {
      final parts = currentStr.split('-');
      if (parts.length == 3) {
        final current = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final next = current.add(Duration(days: days));
        final nextStr =
            '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
        ref.read(dispatchProvider.notifier).setDateRange(nextStr, nextStr);
        ref.read(dispatchProvider.notifier).setSelectedDate(nextStr);
      }
    } catch (_) {}
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
    _showCratesEntrySection = false;
    _productCratesController.clear();
    _milkCratesController.clear();
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

  List<DispatchItem> _getValidInlineItems(String dispatchId) {
    final state = ref.read(dispatchProvider);
    final catalog = state.catalogProducts;
    final List<DispatchItem> validItems = [];

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
    return validItems;
  }

  // Opens the long chip section for Product Crate & Milk Crate when user clicks "Save Vehicle Dispatch"
  void _openCratesEntrySection() {
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

    final validItems = _getValidInlineItems('TEMP');
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one product with a valid quantity (> 0).'),
          backgroundColor: Color(0xFF991B1B),
        ),
      );
      return;
    }

    // Keep empty space so user can freely type
    _productCratesController.clear();
    _milkCratesController.clear();

    setState(() {
      _showCratesEntrySection = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter Product Crates & Milk Crates above, then click Record Dispatch Vehicle.'),
        backgroundColor: Color(0xFF1D4ED8),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Records the vehicle dispatch with product crates and milk crates, then resets form for the next distributor
  Future<void> _recordDispatchVehicle() async {
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

    final dispatchId = 'DISP-${DateTime.now().millisecondsSinceEpoch}';
    final validItems = _getValidInlineItems(dispatchId);

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one product with a valid quantity (> 0).'),
          backgroundColor: Color(0xFF991B1B),
        ),
      );
      return;
    }

    final productCrates = int.tryParse(_productCratesController.text.trim()) ?? 0;
    final milkCrates = int.tryParse(_milkCratesController.text.trim()) ?? 0;

    setState(() => _isInlineSaving = true);

    final state = ref.read(dispatchProvider);
    final currentUser = ref.read(authProvider);
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    final loggedBy = _inlineDriverController.text.trim();
    final effectiveUser = loggedBy.isNotEmpty
        ? loggedBy
        : (currentUser.fullName.isNotEmpty ? currentUser.fullName : 'Plant Operator');

    final newDispatch = VehicleDispatch(
      id: dispatchId,
      dispatchDate: state.selectedDate,
      vehicleNumber: vehicleNo.toUpperCase(),
      distributorName: distributor,
      driverName: loggedBy,
      route: '',
      dispatchTime: timeStr,
      remarks: _inlineRemarksController.text.trim(),
      status: 'Dispatched',
      createdBy: effectiveUser,
      items: validItems,
      productCrates: productCrates,
      milkCrates: milkCrates,
      createdAt: now,
      updatedAt: now,
    );

    final success = await ref.read(dispatchProvider.notifier).saveDispatch(newDispatch);

    if (mounted) {
      setState(() => _isInlineSaving = false);
      if (success) {
        final totalCratesRecorded = productCrates + milkCrates;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Vehicle ${newDispatch.vehicleNumber} recorded for $distributor! ($totalCratesRecorded Crates: $productCrates Prod • $milkCrates Milk). Ready for next distributor.'),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 4),
          ),
        );
        // Reset form for next vehicle/distributor, retaining the current date!
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

  // Dispatches to appropriate action depending on whether crates section is open
  Future<void> _submitInlineVehicle() async {
    if (_showCratesEntrySection) {
      await _recordDispatchVehicle();
    } else {
      _openCratesEntrySection();
    }
  }

  // ignore: unused_element
  void _openDispatchDialog({VehicleDispatch? existing}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _VehicleDispatchDialog(existing: existing),
    );
  }

  // ignore: unused_element
  void _openVehicleDetails(VehicleDispatch dispatch) {
    showDialog(
      context: context,
      builder: (ctx) => _VehicleDetailDialog(dispatch: dispatch),
    );
  }

  // ignore: unused_element
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
    final activeIndex = _tabController.index;

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
            // Tabs
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder, width: 1.1),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: isMobile,
                onTap: (index) => setState(() {}),
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
                    icon: const Icon(Icons.inventory_2_rounded, size: 18),
                    text: 'Product Wise (${state.dailyProductSummaries.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    text: 'Distributor Wise (${state.distributorSummaries.length})',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab View Contents rendered directly on the page
            if (activeIndex == 0)
              _buildEnterDispatchTab(state, isMobile)
            else if (activeIndex == 1)
              _buildProductWiseTab(state, isMobile)
            else
              _buildDistributorWiseTab(state, isMobile),
          ],
        ),
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

                final loggedByField = _buildFieldWithTopLabel(
                  label: 'Logged By',
                  child: TextFormField(
                    controller: _inlineDriverController,
                    onChanged: (_) => setState(() {}),
                    decoration: _boxedInputDecoration(
                      hint: 'Select or type name',
                      icon: Icons.person_outline,
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                        tooltip: 'Select Staff / Logged By',
                        onSelected: (val) {
                          setState(() {
                            _inlineDriverController.text = val;
                          });
                        },
                        itemBuilder: (context) {
                          return authorizedLoggers.map((person) {
                            return PopupMenuItem<String>(
                              value: person,
                              child: Text(person, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            );
                          }).toList();
                        },
                      ),
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
                      Expanded(child: loggedByField),
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
                          Expanded(child: loggedByField),
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
                      loggedByField,
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

            // Long bar "+ Add Product" button (Navy Blue with increased height)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _addInlineProductRow(catalog),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: const Text(
                  '+ Add Product',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Crates Allocation Section (Long chip with two sections: Product Crate and Milk Crate)
            if (_showCratesEntrySection) ...[
              _buildCratesEntryChip(),
              const SizedBox(height: 16),
            ],

            // 5. Action Buttons (Reset Form + Save / Record Vehicle Dispatch)
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _resetInlineForm,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Reset Form',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
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
                        : Icon(
                            _showCratesEntrySection ? Icons.check_circle_outline_rounded : Icons.save_outlined,
                            size: 20,
                          ),
                    label: Text(
                      _isInlineSaving
                          ? 'Recording Vehicle Dispatch...'
                          : (_showCratesEntrySection ? 'Record Dispatch Vehicle' : 'Save Vehicle Dispatch'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showCratesEntrySection
                          ? const Color(0xFF059669) // Emerald green when recording
                          : const Color(0xFF10B981), // Green
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
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

  // Long chip with two sections: Product Crate and Milk Crate
  Widget _buildCratesEntryChip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Fresh light mint background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.all_inbox_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Enter Crates to Dispatch with Vehicle',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF065F46),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Text(
                  'Only numbers (0 to any count)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Long Chip with Two Sections
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30), // Long pill/chip shape
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // SECTION 1: Product Crate
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            size: 17,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Product Crate',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Dispatched count',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 115,
                          height: 46,
                          child: TextFormField(
                            controller: _productCratesController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              hintText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // VERTICAL DIVIDER between two sections of the long chip
                Container(
                  width: 1.5,
                  height: 42,
                  color: const Color(0xFFE2E8F0),
                ),

                // SECTION 2: Milk Crate
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            size: 17,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Milk Crate',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Dispatched count',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 115,
                          height: 46,
                          child: TextFormField(
                            controller: _milkCratesController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              hintText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF059669), width: 2.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
  // TAB 2: PRODUCT WISE (PERIOD REPORT WITH CONVERSIONS & EXPORT)
  // ===========================================================================

  Widget _buildProductWiseTab(DispatchState state, bool isMobile) {
    final summaries = state.productSummariesForDateRange;
    final currentDateDisplay = state.datePreset == 'Custom'
        ? '${_formatDisplayDate(state.rangeStartDate)} to ${_formatDisplayDate(state.rangeEndDate)}'
        : _formatDisplayDate(state.selectedDate);

    final totalCratesSum = summaries.fold<double>(0.0, (sum, s) => sum + s.totalCrates);
    final totalBoxesSum = summaries.fold<double>(0.0, (sum, s) => sum + (s.totalBoxes ?? 0.0));
    final totalPiecesSum = summaries.fold<int>(0, (sum, s) => sum + s.totalPieces);
    final totalLiquidSum = summaries.where((s) => s.normalizedUnit.toLowerCase().startsWith('l')).fold<double>(0.0, (sum, s) => sum + s.totalQuantity);
    final totalSolidSum = summaries.where((s) => !s.normalizedUnit.toLowerCase().startsWith('l')).fold<double>(0.0, (sum, s) => sum + s.totalQuantity);
    final totalRevenueSum = summaries.fold<double>(0.0, (sum, s) => sum + s.revenue);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Title & Action Buttons (Print / Preview & Export CSV)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              final titleWidget = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Product Wise Dispatch Report',
                          style: TextStyle(
                            fontSize: AppTextSizes.subheading,
                            fontWeight: AppFontWeights.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Dispatched summary for $currentDateDisplay',
                          style: const TextStyle(
                            fontSize: AppTextSizes.caption,
                            color: AppColors.textSecondary,
                            fontWeight: AppFontWeights.medium,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actionsWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text('Print / Preview', style: TextStyle(fontSize: 12, fontWeight: AppFontWeights.semiBold)),
                    onPressed: summaries.isEmpty
                        ? null
                        : () => _showProductWisePrintPreviewDialog(context, state, summaries),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Export CSV', style: TextStyle(fontSize: 12, fontWeight: AppFontWeights.semiBold)),
                    onPressed: summaries.isEmpty
                        ? null
                        : () {
                            final csv = ref.read(dispatchProvider.notifier).generateProductWiseCsv(
                                  summaries,
                                  '${state.rangeStartDate} to ${state.rangeEndDate}',
                                );
                            downloadLedgerCsv('product_wise_dispatch_${state.datePreset}.csv', csv);
                          },
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 10),
                    actionsWidget,
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleWidget),
                  actionsWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // 2. Control Toolbar: Date Presets & Manual Date Picker (Today, Yesterday, All Time, Date Selector)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...['Today', 'Yesterday', 'All Time'].map((preset) {
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
                }),
                const SizedBox(width: 4),
                // Manual Date Selector (like Sat, 10 Oct 2026 with < > arrows)
                Container(
                  decoration: BoxDecoration(
                    color: state.datePreset == 'Custom' ? const Color(0xFFE8F5E9) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: state.datePreset == 'Custom' ? AppColors.primary : AppColors.cardBorder,
                      width: state.datePreset == 'Custom' ? 1.4 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.textPrimary),
                        tooltip: 'Previous Day',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        onPressed: () => _shiftProductWiseDate(-1),
                      ),
                      InkWell(
                        onTap: () => _pickProductWiseDate(
                          state.datePreset == 'Custom' ? state.rangeStartDate : state.selectedDate,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                _formatDisplayDate(
                                  state.datePreset == 'Custom' ? state.rangeStartDate : state.selectedDate,
                                ),
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
                        onPressed: () => _shiftProductWiseDate(1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Product Wise Table (or Empty State)
          if (summaries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
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
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth < 1100 ? 1100.0 : constraints.maxWidth;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.cardBorder, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Table(
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        border: const TableBorder(
                          horizontalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(2.6), // Product Name
                          1: FlexColumnWidth(1.2), // Pack Size
                          2: FlexColumnWidth(1.2), // Total Crates
                          3: FlexColumnWidth(1.2), // Total Boxes
                          4: FlexColumnWidth(1.2), // Total Pieces
                          5: FlexColumnWidth(1.6), // Base Unit Equivalent
                          6: FlexColumnWidth(1.0), // Vehicles
                          7: FlexColumnWidth(1.5), // Total Value (₹)
                        },
                        children: [
                          // Header Row
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                            children: [
                              _buildTableHeaderCell('Product Name', alignCenter: true),
                              _buildTableHeaderCell('Pack Size', alignCenter: true),
                              _buildTableHeaderCell('Total Crates', alignCenter: true),
                              _buildTableHeaderCell('Total Boxes', alignCenter: true),
                              _buildTableHeaderCell('Total Pieces', alignCenter: true),
                              _buildTableHeaderCell('Base Unit Equivalent', alignCenter: true),
                              _buildTableHeaderCell('Vehicles', alignCenter: true),
                              _buildTableHeaderCell('Total Value (₹)', alignCenter: true),
                            ],
                          ),
                          // Data Rows
                          ...summaries.map((s) {
                            final isLiquid = s.normalizedUnit.toLowerCase().startsWith('l');
                            return TableRow(
                              children: [
                                // Product Name
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  child: Center(
                                    child: Text(
                                      s.productName,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: AppFontWeights.bold,
                                        fontSize: 13,
                                        color: s.totalQuantity > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                // Pack Size
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  child: Center(
                                    child: Text(
                                      s.packSizeDisplay,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                // Total Crates
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  child: Center(
                                    child: Text(
                                      s.formattedCrates,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: AppFontWeights.bold,
                                        fontSize: 13,
                                        color: s.totalCrates > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                // Total Boxes (Plain text, centered, no chips)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  child: Center(
                                    child: Text(
                                      s.formattedBoxes,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: AppFontWeights.bold,
                                        fontSize: 13,
                                        color: s.piecesPerBox == null
                                            ? AppColors.textMuted
                                            : (s.totalBoxes != null && s.totalBoxes! > 0
                                                ? const Color(0xFF1D4ED8)
                                                : AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
                                ),
                                // Total Pieces
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  child: Center(
                                    child: Text(
                                      s.formattedPieces,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: AppFontWeights.bold,
                                        fontSize: 13,
                                        color: s.totalPieces > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                // Base Unit Equivalent (Plain text, centered, no chips)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  child: Center(
                                    child: Text(
                                      s.formattedQuantity,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: AppFontWeights.bold,
                                        fontSize: 12.5,
                                        color: s.totalQuantity == 0
                                            ? AppColors.textSecondary
                                            : (isLiquid ? const Color(0xFF0369A1) : const Color(0xFFB45309)),
                                      ),
                                    ),
                                  ),
                                ),
                                // Vehicles
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  child: Center(
                                    child: Text(
                                      s.vehicleCount > 0 ? '${s.vehicleCount}' : '—',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: AppFontWeights.bold,
                                        fontSize: 13,
                                        color: s.vehicleCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                // Total Value (₹)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  child: Center(
                                    child: Text(
                                      s.formattedRevenue,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: AppFontWeights.bold,
                                        fontSize: 13,
                                        color: s.revenue > 0 ? const Color(0xFF047857) : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                          // Total Summary Row
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.summarize_rounded, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'TOTAL (${summaries.length})',
                                        style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12.5, color: AppColors.textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: Center(
                                  child: Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: Center(
                                  child: Text(
                                    totalCratesSum == totalCratesSum.roundToDouble()
                                        ? '${totalCratesSum.toInt()} crates'
                                        : '${Formatters.formatSmart(totalCratesSum)} crates',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: Center(
                                  child: Text(
                                    totalBoxesSum > 0
                                        ? (totalBoxesSum == totalBoxesSum.roundToDouble()
                                            ? '${totalBoxesSum.toInt()} boxes'
                                            : '${Formatters.formatSmart(totalBoxesSum)} boxes')
                                        : '0 boxes',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13, color: Color(0xFF1D4ED8)),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: Center(
                                  child: Text(
                                    '$totalPiecesSum pcs',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: Center(
                                  child: Text(
                                    '${Formatters.formatSmart(totalLiquidSum)} L / ${Formatters.formatSmart(totalSolidSum)} kg',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12, color: Color(0xFF0369A1)),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: Center(
                                  child: Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                child: Center(
                                  child: Text(
                                    totalRevenueSum > 0 ? '₹${Formatters.formatSmart(totalRevenueSum)}' : '₹0',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13, color: Color(0xFF047857)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PRINT / PREVIEW MODAL DIALOG (LIKE INVENTORY REPORT)
  // ===========================================================================

  void _showProductWisePrintPreviewDialog(
    BuildContext context,
    DispatchState state,
    List<DailyDispatchProductSummary> summaries,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final currentDateDisplay = state.datePreset == 'Custom'
            ? '${_formatDisplayDate(state.rangeStartDate)} to ${_formatDisplayDate(state.rangeEndDate)}'
            : _formatDisplayDate(state.selectedDate);

        final totalCratesSum = summaries.fold<double>(0.0, (sum, s) => sum + s.totalCrates);
        final totalBoxesSum = summaries.fold<double>(0.0, (sum, s) => sum + (s.totalBoxes ?? 0.0));
        final totalPiecesSum = summaries.fold<int>(0, (sum, s) => sum + s.totalPieces);
        final totalLiquidSum = summaries.where((s) => s.normalizedUnit.toLowerCase().startsWith('l')).fold<double>(0.0, (sum, s) => sum + s.totalQuantity);
        final totalSolidSum = summaries.where((s) => !s.normalizedUnit.toLowerCase().startsWith('l')).fold<double>(0.0, (sum, s) => sum + s.totalQuantity);
        final totalRevenueSum = summaries.fold<double>(0.0, (sum, s) => sum + s.revenue);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050, maxHeight: 820),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.print_rounded, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Product Wise Dispatch Register — Print Preview',
                                    style: TextStyle(
                                      fontSize: AppTextSizes.subheading,
                                      fontWeight: AppFontWeights.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'CASEYA • Purabi Dairy, Silchar Plant • $currentDateDisplay',
                                    style: const TextStyle(
                                      fontSize: AppTextSizes.caption,
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Export CSV'),
                            onPressed: () {
                              final csv = ref.read(dispatchProvider.notifier).generateProductWiseCsv(
                                    summaries,
                                    '${state.rangeStartDate} to ${state.rangeEndDate}',
                                  );
                              downloadLedgerCsv('product_wise_dispatch_${state.datePreset}.csv', csv);
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.print_rounded, size: 16),
                            label: const Text('Print Sheet'),
                            onPressed: () {
                              printLedger();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Triggered print sheet in browser.'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Printable Register Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text('CASEYA', style: TextStyle(fontWeight: AppFontWeights.bold, fontSize: 18, letterSpacing: 1.5, color: Color(0xFF0F172A)), textAlign: TextAlign.center),
                                  const SizedBox(height: 2),
                                  const Text('a digital solution by biraj goswami', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, fontWeight: AppFontWeights.medium, color: Color(0xFF64748B), letterSpacing: 0.3), textAlign: TextAlign.center),
                                  const SizedBox(height: 3),
                                  const Text('Purabi Dairy (NEDFL), Silchar Plant', style: TextStyle(fontWeight: AppFontWeights.bold, fontSize: 14, color: Color(0xFF334155)), textAlign: TextAlign.center),
                                  const SizedBox(height: 3),
                                  const Text('Product Wise Dispatch Register', style: TextStyle(fontWeight: AppFontWeights.semiBold, fontSize: 12.5, color: AppColors.textSecondary, letterSpacing: 0.5), textAlign: TextAlign.center),
                                  const SizedBox(height: 4),
                                  Text('$currentDateDisplay • ${summaries.length} Products', style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.medium, color: AppColors.textPrimary), textAlign: TextAlign.center),
                                  const SizedBox(height: 2),
                                  Text('Generated on: ${DateFormat('dd/MM/yy • hh:mm a').format(DateTime.now())}', style: const TextStyle(fontSize: 11, color: Colors.black54), textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Summary strip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildPrintableSummaryItem('Total Products', '${summaries.length} Items'),
                                  _buildPrintableSummaryItem('Total Crates', totalCratesSum == totalCratesSum.roundToDouble() ? '${totalCratesSum.toInt()} crt' : '${Formatters.formatSmart(totalCratesSum)} crt'),
                                  _buildPrintableSummaryItem('Total Boxes', totalBoxesSum > 0 ? (totalBoxesSum == totalBoxesSum.roundToDouble() ? '${totalBoxesSum.toInt()} box' : '${Formatters.formatSmart(totalBoxesSum)} box') : '0 box'),
                                  _buildPrintableSummaryItem('Total Pieces', '$totalPiecesSum pcs'),
                                  _buildPrintableSummaryItem('Liquid Volume', '${Formatters.formatSmart(totalLiquidSum)} L'),
                                  _buildPrintableSummaryItem('Total Revenue', '₹${Formatters.formatSmart(totalRevenueSum)}'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Printable Table
                            Table(
                              border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 1),
                              columnWidths: const {
                                0: FlexColumnWidth(2.6),
                                1: FlexColumnWidth(1.2),
                                2: FlexColumnWidth(1.2),
                                3: FlexColumnWidth(1.2),
                                4: FlexColumnWidth(1.2),
                                5: FlexColumnWidth(1.6),
                                6: FlexColumnWidth(1.0),
                                7: FlexColumnWidth(1.5),
                              },
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                                  children: [
                                    _PrintTableHeader('Product Name'),
                                    _PrintTableHeader('Pack Size'),
                                    _PrintTableHeader('Total Crates'),
                                    _PrintTableHeader('Total Boxes'),
                                    _PrintTableHeader('Total Pieces'),
                                    _PrintTableHeader('Base Equivalent'),
                                    _PrintTableHeader('Vehicles'),
                                    _PrintTableHeader('Total Value (₹)'),
                                  ],
                                ),
                                ...summaries.map((s) {
                                  return TableRow(
                                    children: [
                                      _PrintTableCell(s.productName, isBold: true),
                                      _PrintTableCell(s.packSizeDisplay),
                                      _PrintTableCell(s.formattedCrates),
                                      _PrintTableCell(s.formattedBoxes, color: (s.totalBoxes != null && s.totalBoxes! > 0) ? const Color(0xFF1D4ED8) : null),
                                      _PrintTableCell(s.formattedPieces),
                                      _PrintTableCell(s.formattedQuantity),
                                      _PrintTableCell(s.vehicleCount > 0 ? '${s.vehicleCount}' : '0'),
                                      _PrintTableCell(s.formattedRevenue, color: s.revenue > 0 ? const Color(0xFF047857) : null),
                                    ],
                                  );
                                }),
                                TableRow(
                                  decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                                  children: [
                                    _PrintTableCell('TOTAL (${summaries.length})', isBold: true),
                                    const _PrintTableCell('—', isBold: true),
                                    _PrintTableCell(
                                      totalCratesSum == totalCratesSum.roundToDouble()
                                          ? '${totalCratesSum.toInt()} crates'
                                          : '${Formatters.formatSmart(totalCratesSum)} crates',
                                      isBold: true,
                                    ),
                                    _PrintTableCell(
                                      totalBoxesSum > 0
                                          ? (totalBoxesSum == totalBoxesSum.roundToDouble()
                                              ? '${totalBoxesSum.toInt()} boxes'
                                              : '${Formatters.formatSmart(totalBoxesSum)} boxes')
                                          : '0 boxes',
                                      isBold: true,
                                      color: const Color(0xFF1D4ED8),
                                    ),
                                    _PrintTableCell('$totalPiecesSum pcs', isBold: true),
                                    _PrintTableCell('${Formatters.formatSmart(totalLiquidSum)} L / ${Formatters.formatSmart(totalSolidSum)} kg', isBold: true, color: const Color(0xFF0369A1)),
                                    const _PrintTableCell('—', isBold: true),
                                    _PrintTableCell(totalRevenueSum > 0 ? '₹${Formatters.formatSmart(totalRevenueSum)}' : '₹0', isBold: true, color: const Color(0xFF047857)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: const [
                                _PrintSignature(name: 'Biraj Goswami', title: 'Caseya Developer'),
                                _PrintSignature(title: 'Verified by'),
                                _PrintSignature(title: 'Plant Head'),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrintableSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: AppFontWeights.medium)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: AppFontWeights.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  // ===========================================================================
  // TAB 4: DISTRIBUTOR WISE (DISTRIBUTOR ROUTES, VEHICLE TRIPS & BREAKDOWN)
  // ===========================================================================

  Widget _buildDistributorWiseTab(DispatchState state, bool isMobile) {
    final summaries = state.distributorSummariesForDateRange;
    final availableDistributors = summaries.map((s) => s.distributorName).toList();
    
    // By default, show "Select Distributor" (do not auto-select unless explicitly chosen)
    final activeDistributor = (_selectedDistributorName != null && availableDistributors.contains(_selectedDistributorName))
        ? _selectedDistributorName
        : null;

    final currentDateDisplay = state.datePreset == 'Custom'
        ? '${_formatDisplayDate(state.rangeStartDate)} to ${_formatDisplayDate(state.rangeEndDate)}'
        : _formatDisplayDate(state.selectedDate);

    // Products dispatched to this specific distributor
    final distributorProducts = activeDistributor != null
        ? state.productSummariesForDistributor(activeDistributor)
        : <DailyDispatchProductSummary>[];
    final dispatchedProducts = distributorProducts
        .where((p) => p.totalQuantity > 0 || p.totalCrates > 0 || p.totalPieces > 0)
        .toList();

    final totalCratesSum = dispatchedProducts.fold<double>(0.0, (sum, s) => sum + s.totalCrates);
    final totalBoxesSum = dispatchedProducts.fold<double>(0.0, (sum, s) => sum + (s.totalBoxes ?? 0.0));
    final totalPiecesSum = dispatchedProducts.fold<int>(0, (sum, s) => sum + s.totalPieces);
    final totalLiquidSum = dispatchedProducts.where((s) => s.normalizedUnit.toLowerCase().startsWith('l')).fold<double>(0.0, (sum, s) => sum + s.totalQuantity);
    final totalSolidSum = dispatchedProducts.where((s) => !s.normalizedUnit.toLowerCase().startsWith('l')).fold<double>(0.0, (sum, s) => sum + s.totalQuantity);
    final totalRevenueSum = dispatchedProducts.fold<double>(0.0, (sum, s) => sum + s.revenue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. TOP CARDS: Total Distributors, Total Products Dispatch, Total Crates Dispatched, Total Dispatch Value
        _buildDistributorKpiCards(state, summaries, isMobile),
        const SizedBox(height: 18),

        // 2. HEADING OUTSIDE CARD: Distributor Summary + Date Presets & Export Actions
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 950;
            final titleWidget = Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_rounded, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Distributor Summary',
                  style: TextStyle(
                    fontSize: AppTextSizes.subheading,
                    fontWeight: AppFontWeights.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            );

            final actionsWidget = Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Date presets: Today, Yesterday, All Time
                ...['Today', 'Yesterday', 'All Time'].map((preset) {
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
                }),
                const SizedBox(width: 2),
                // Manual Date Selector: [ < ] [ Sat, 10 Oct 2026 ] [ > ]
                Container(
                  decoration: BoxDecoration(
                    color: state.datePreset == 'Custom' ? const Color(0xFFE8F5E9) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: state.datePreset == 'Custom' ? AppColors.primary : AppColors.cardBorder,
                      width: state.datePreset == 'Custom' ? 1.4 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.textPrimary),
                        tooltip: 'Previous Day',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        onPressed: () => _shiftProductWiseDate(-1),
                      ),
                      InkWell(
                        onTap: () => _pickProductWiseDate(
                          state.datePreset == 'Custom' ? state.rangeStartDate : state.selectedDate,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                _formatDisplayDate(
                                  state.datePreset == 'Custom' ? state.rangeStartDate : state.selectedDate,
                                ),
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
                        onPressed: () => _shiftProductWiseDate(1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Export Preview Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('Print / Preview', style: TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13)),
                  onPressed: () {
                    _showDistributorWisePrintPreviewDialog(
                      context,
                      state,
                      summaries,
                      activeDistributor,
                      dispatchedProducts,
                    );
                  },
                ),
                // Export CSV
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Export CSV', style: TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13)),
                  onPressed: summaries.isEmpty
                      ? null
                      : () {
                          final csv = ref.read(dispatchProvider.notifier).generateDistributorWiseCsv(
                                summaries,
                                '${state.rangeStartDate} to ${state.rangeEndDate}',
                              );
                          downloadLedgerCsv('distributor_wise_dispatch_${state.datePreset}.csv', csv);
                        },
                ),
              ],
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  const SizedBox(height: 12),
                  actionsWidget,
                ],
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: titleWidget),
                actionsWidget,
              ],
            );
          },
        ),
        const SizedBox(height: 14),

        // 3. MAIN SECTION CARD: Select Distributor Long Chip + Product Wise Table
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SELECT DISTRIBUTOR LONG CHIP (pill shape, no separate heading above it)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: activeDistributor != null ? AppColors.primary : AppColors.cardBorder,
                    width: activeDistributor != null ? 1.4 : 1.1,
                  ),
                ),
                child: availableDistributors.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No distributors with dispatches on this date. Change date above.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: availableDistributors.contains(activeDistributor) ? activeDistributor : null,
                          hint: Row(
                            children: const [
                              Icon(Icons.storefront_rounded, size: 18, color: AppColors.primary),
                              SizedBox(width: 10),
                              Text(
                                'Select Distributor',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: AppFontWeights.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 24),
                          items: availableDistributors.map((dist) {
                            final s = summaries.firstWhere((item) => item.distributorName == dist);
                            return DropdownMenuItem<String>(
                              value: dist,
                              child: Row(
                                children: [
                                  const Icon(Icons.business_outlined, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    dist,
                                    style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      '${s.dispatches.length} trips • ${Formatters.formatSmart(s.totalCrates)} crt',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: AppFontWeights.medium),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (newDist) {
                            setState(() {
                              _selectedDistributorName = newDist;
                            });
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // 4. BELOW TABLE: SHOWING WHAT PRODUCTS WE DISPATCHED TO THAT PARTICULAR DISTRIBUTOR
              if (activeDistributor == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storefront_outlined, size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Select Distributor',
                          style: TextStyle(
                            fontSize: AppTextSizes.subheading,
                            fontWeight: AppFontWeights.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Choose a distributor from the dropdown chip above to view their product dispatch details.',
                          style: TextStyle(fontSize: AppTextSizes.body, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else if (availableDistributors.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
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
                  ),
                )
              else if (dispatchedProducts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textSecondary),
                      const SizedBox(height: 8),
                      Text(
                        'No products dispatched to "$activeDistributor" on $currentDateDisplay',
                        style: const TextStyle(fontSize: 14, fontWeight: AppFontWeights.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select another date above or select another distributor from the dropdown.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else ...[
                // Section Title for Table
                Text(
                  'Dispatched Products for $activeDistributor (${dispatchedProducts.length} items)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: AppFontWeights.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                // Product Wise Table for Selected Distributor
                LayoutBuilder(
                  builder: (context, constraints) {
                    final tableWidth = constraints.maxWidth < 1100 ? 1100.0 : constraints.maxWidth;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.cardBorder, width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableWidth,
                          child: Table(
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            border: const TableBorder(
                              horizontalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                            ),
                            columnWidths: const {
                              0: FlexColumnWidth(2.8), // Product Name
                              1: FlexColumnWidth(1.2), // Pack Size
                              2: FlexColumnWidth(1.2), // Total Crates
                              3: FlexColumnWidth(1.2), // Total Boxes
                              4: FlexColumnWidth(1.2), // Total Pieces
                              5: FlexColumnWidth(1.6), // Base Unit Equivalent
                              6: FlexColumnWidth(1.5), // Total Value (₹)
                            },
                            children: [
                              // Header Row
                              TableRow(
                                decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                                children: [
                                  _buildTableHeaderCell('Product Name', alignCenter: true),
                                  _buildTableHeaderCell('Pack Size', alignCenter: true),
                                  _buildTableHeaderCell('Total Crates', alignCenter: true),
                                  _buildTableHeaderCell('Total Boxes', alignCenter: true),
                                  _buildTableHeaderCell('Total Pieces', alignCenter: true),
                                  _buildTableHeaderCell('Base Unit Equivalent', alignCenter: true),
                                  _buildTableHeaderCell('Total Value (₹)', alignCenter: true),
                                ],
                              ),
                              // Data Rows
                              ...dispatchedProducts.map((s) {
                                return TableRow(
                                  children: [
                                    // Product Name
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      child: Center(
                                        child: Text(
                                          s.productName,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: AppFontWeights.bold,
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Pack Size
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      child: Center(
                                        child: Text(
                                          s.packSizeDisplay,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    // Total Crates
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      child: Center(
                                        child: Text(
                                          s.formattedCrates,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: AppFontWeights.bold,
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Total Boxes (plain text, NO chips)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      child: Center(
                                        child: Text(
                                          s.formattedBoxes,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: AppFontWeights.bold,
                                            fontSize: 13,
                                            color: (s.totalBoxes != null && s.totalBoxes! > 0)
                                                ? const Color(0xFF1D4ED8)
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Total Pieces
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      child: Center(
                                        child: Text(
                                          s.formattedPieces,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: AppFontWeights.bold,
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Base Unit Equivalent
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      child: Center(
                                        child: Text(
                                          s.formattedQuantity,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: AppFontWeights.bold,
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Total Value (₹)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      child: Center(
                                        child: Text(
                                          s.formattedRevenue,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: AppFontWeights.bold,
                                            fontSize: 13,
                                            color: s.revenue > 0 ? const Color(0xFF047857) : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                              // Total Summary Row
                              TableRow(
                                decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.summarize_rounded, size: 16, color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Text(
                                            'TOTAL (${dispatchedProducts.length})',
                                            style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 12.5, color: AppColors.textPrimary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                    child: Center(
                                      child: Text('—', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                    child: Center(
                                      child: Text(
                                        totalCratesSum == totalCratesSum.roundToDouble()
                                            ? '${totalCratesSum.toInt()} crates'
                                            : '${Formatters.formatSmart(totalCratesSum)} crates',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13, color: AppColors.textPrimary),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                    child: Center(
                                      child: Text(
                                        totalBoxesSum > 0
                                            ? (totalBoxesSum == totalBoxesSum.roundToDouble()
                                                ? '${totalBoxesSum.toInt()} boxes'
                                                : '${Formatters.formatSmart(totalBoxesSum)} boxes')
                                            : '0 boxes',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13, color: Color(0xFF1D4ED8)),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                    child: Center(
                                      child: Text(
                                        '$totalPiecesSum pcs',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13, color: AppColors.textPrimary),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                    child: Center(
                                      child: Text(
                                        '${Formatters.formatSmart(totalLiquidSum)} L / ${Formatters.formatSmart(totalSolidSum)} kg',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13, color: Color(0xFF0369A1)),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                    child: Center(
                                      child: Text(
                                        totalRevenueSum > 0 ? '₹${Formatters.formatSmart(totalRevenueSum)}' : '₹0',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13, color: Color(0xFF047857)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // DISTRIBUTOR KPI CARDS
  // ===========================================================================

  Widget _buildDistributorKpiCards(
    DispatchState state,
    List<DistributorDailySummary> summaries,
    bool isMobile,
  ) {
    final totalDistributors = summaries.length;
    final allProductsCount = state.catalogProducts.length;
    final dispatchedProductsCount = state.productSummariesForDateRange
        .where((p) => p.totalQuantity > 0 || p.totalCrates > 0 || p.totalPieces > 0)
        .length;
    final totalCratesSum = summaries.fold<double>(0.0, (acc, s) => acc + s.totalCrates);
    final totalPiecesSum = state.productSummariesForDateRange.fold<int>(0, (acc, p) => acc + p.totalPieces);
    final totalRevenueSum = state.productSummariesForDateRange.fold<double>(0.0, (acc, p) => acc + p.revenue);

    // Sum product crates and milk crates across all dispatches in the date range
    int totalProductCratesSum = 0;
    int totalMilkCratesSum = 0;
    for (final d in state.dispatchesForDateRange) {
      totalProductCratesSum += d.productCrates;
      totalMilkCratesSum += d.milkCrates;
    }
    final totalExplicitCrates = totalProductCratesSum + totalMilkCratesSum;
    final displayTotalCrates = totalExplicitCrates > 0 ? totalExplicitCrates.toDouble() : totalCratesSum;

    final cards = [
      MetricCard(
        title: 'Total Distributors',
        value: '$totalDistributors',
        unit: totalDistributors == 1 ? 'Distributor' : 'Distributors',
        subtitle: totalDistributors > 0 ? 'With dispatches in range' : 'No dispatches recorded',
        icon: Icons.storefront_rounded,
        iconColor: Colors.black.withValues(alpha: 0.60),
        iconBgColor: Colors.black.withValues(alpha: 0.06),
        cardBgColor: const Color(0xFFEFF6FF), // Soft Blue matching Dashboard Total Metric Summary #1
      ),
      MetricCard(
        title: 'Total Products Dispatch',
        value: '$dispatchedProductsCount / $allProductsCount',
        unit: 'Items',
        subtitle: '$dispatchedProductsCount of $allProductsCount kinds dispatched',
        icon: Icons.category_rounded,
        iconColor: Colors.black.withValues(alpha: 0.60),
        iconBgColor: Colors.black.withValues(alpha: 0.06),
        cardBgColor: const Color(0xFFFFFBEB), // Soft Amber matching Dashboard Total Metric Summary #2
      ),
      MetricCard(
        title: 'Total Crates Dispatched',
        value: displayTotalCrates == displayTotalCrates.roundToDouble()
            ? '${displayTotalCrates.toInt()}'
            : Formatters.formatSmart(displayTotalCrates),
        unit: 'Crates',
        subtitleWidget: (totalProductCratesSum > 0 || totalMilkCratesSum > 0)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      'Prod: $totalProductCratesSum crt',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Text(
                      'Milk: $totalMilkCratesSum crt',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              )
            : Text(
                '$totalPiecesSum Pieces dispatched',
                style: const TextStyle(
                  fontSize: AppTextSizes.caption,
                  fontWeight: AppFontWeights.medium,
                  color: AppColors.textMuted,
                ),
              ),
        icon: Icons.inventory_2_rounded,
        iconColor: Colors.black.withValues(alpha: 0.60),
        iconBgColor: Colors.black.withValues(alpha: 0.06),
        cardBgColor: const Color(0xFFECFDF5), // Soft Mint matching Dashboard Total Metric Summary #3
      ),
      MetricCard(
        title: 'Total Dispatch Value',
        value: totalRevenueSum > 0 ? '₹${Formatters.formatSmart(totalRevenueSum)}' : '₹0',
        subtitle: totalRevenueSum > 0 ? 'Gross revenue recorded' : 'No revenue recorded',
        icon: Icons.payments_rounded,
        iconColor: Colors.black.withValues(alpha: 0.60),
        iconBgColor: Colors.black.withValues(alpha: 0.06),
        cardBgColor: const Color(0xFFF5F3FF), // Soft Purple matching Dashboard Total Metric Summary #4
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 650
            ? 1
            : (constraints.maxWidth < 1100 ? 2 : 4);
        final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 16)) / crossAxisCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards.map((c) => SizedBox(width: itemWidth, child: c)).toList(),
        );
      },
    );
  }

  // ===========================================================================
  // DISTRIBUTOR WISE PRINT PREVIEW DIALOG
  // ===========================================================================

  void _showDistributorWisePrintPreviewDialog(
    BuildContext context,
    DispatchState state,
    List<DistributorDailySummary> summaries,
    String? selectedDistributor,
    List<DailyDispatchProductSummary> dispatchedProducts,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final currentDateDisplay = state.datePreset == 'Custom'
            ? '${_formatDisplayDate(state.rangeStartDate)} to ${_formatDisplayDate(state.rangeEndDate)}'
            : _formatDisplayDate(state.selectedDate);

        final totalCratesSum = dispatchedProducts.fold<double>(0.0, (sum, s) => sum + s.totalCrates);
        final totalBoxesSum = dispatchedProducts.fold<double>(0.0, (sum, s) => sum + (s.totalBoxes ?? 0.0));
        final totalPiecesSum = dispatchedProducts.fold<int>(0, (sum, s) => sum + s.totalPieces);
        final totalLiquidSum = dispatchedProducts.where((s) => s.normalizedUnit.toLowerCase().startsWith('l')).fold<double>(0.0, (sum, s) => sum + s.totalQuantity);
        final totalSolidSum = dispatchedProducts.where((s) => !s.normalizedUnit.toLowerCase().startsWith('l')).fold<double>(0.0, (sum, s) => sum + s.totalQuantity);
        final totalRevenueSum = dispatchedProducts.fold<double>(0.0, (sum, s) => sum + s.revenue);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050, maxHeight: 820),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.print_rounded, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedDistributor != null
                                        ? '$selectedDistributor — Dispatch Register'
                                        : 'Distributor Wise Dispatch Register — Print Preview',
                                    style: const TextStyle(
                                      fontSize: AppTextSizes.subheading,
                                      fontWeight: AppFontWeights.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'CASEYA • Purabi Dairy, Silchar Plant • $currentDateDisplay',
                                    style: const TextStyle(
                                      fontSize: AppTextSizes.caption,
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Export CSV'),
                            onPressed: () {
                              final csv = ref.read(dispatchProvider.notifier).generateDistributorWiseCsv(
                                    summaries,
                                    '${state.rangeStartDate} to ${state.rangeEndDate}',
                                  );
                              downloadLedgerCsv('distributor_wise_dispatch_${state.datePreset}.csv', csv);
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.print_rounded, size: 16),
                            label: const Text('Print Sheet'),
                            onPressed: () {
                              printLedger();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Triggered print sheet in browser.'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Printable Register Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text('CASEYA', style: TextStyle(fontWeight: AppFontWeights.bold, fontSize: 18, letterSpacing: 1.5, color: Color(0xFF0F172A)), textAlign: TextAlign.center),
                                  const SizedBox(height: 2),
                                  const Text('a digital solution by biraj goswami', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, fontWeight: AppFontWeights.medium, color: Color(0xFF64748B), letterSpacing: 0.3), textAlign: TextAlign.center),
                                  const SizedBox(height: 3),
                                  const Text('Purabi Dairy (NEDFL), Silchar Plant', style: TextStyle(fontWeight: AppFontWeights.bold, fontSize: 14, color: Color(0xFF334155)), textAlign: TextAlign.center),
                                  const SizedBox(height: 3),
                                  Text(
                                    selectedDistributor != null
                                        ? 'Distributor Dispatch Register: $selectedDistributor'
                                        : 'Distributor Wise Dispatch Register',
                                    style: const TextStyle(fontWeight: AppFontWeights.semiBold, fontSize: 12.5, color: AppColors.textSecondary, letterSpacing: 0.5),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('$currentDateDisplay • ${dispatchedProducts.length} Dispatched Products', style: const TextStyle(fontSize: 12, fontWeight: AppFontWeights.medium, color: AppColors.textPrimary), textAlign: TextAlign.center),
                                  const SizedBox(height: 2),
                                  Text('Generated on: ${DateFormat('dd/MM/yy • hh:mm a').format(DateTime.now())}', style: const TextStyle(fontSize: 11, color: Colors.black54), textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Summary strip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildPrintableSummaryItem('Distributor', selectedDistributor ?? 'All'),
                                  _buildPrintableSummaryItem('Total Products', '${dispatchedProducts.length} Items'),
                                  _buildPrintableSummaryItem('Total Crates', totalCratesSum == totalCratesSum.roundToDouble() ? '${totalCratesSum.toInt()} crt' : '${Formatters.formatSmart(totalCratesSum)} crt'),
                                  _buildPrintableSummaryItem('Total Boxes', totalBoxesSum > 0 ? (totalBoxesSum == totalBoxesSum.roundToDouble() ? '${totalBoxesSum.toInt()} box' : '${Formatters.formatSmart(totalBoxesSum)} box') : '0 box'),
                                  _buildPrintableSummaryItem('Total Pieces', '$totalPiecesSum pcs'),
                                  _buildPrintableSummaryItem('Liquid Volume', '${Formatters.formatSmart(totalLiquidSum)} L'),
                                  _buildPrintableSummaryItem('Total Revenue', '₹${Formatters.formatSmart(totalRevenueSum)}'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Printable Table
                            Table(
                              border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 1),
                              columnWidths: const {
                                0: FlexColumnWidth(2.6),
                                1: FlexColumnWidth(1.2),
                                2: FlexColumnWidth(1.2),
                                3: FlexColumnWidth(1.2),
                                4: FlexColumnWidth(1.2),
                                5: FlexColumnWidth(1.6),
                                6: FlexColumnWidth(1.0),
                                7: FlexColumnWidth(1.5),
                              },
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                                  children: [
                                    _PrintTableHeader('Product Name'),
                                    _PrintTableHeader('Pack Size'),
                                    _PrintTableHeader('Total Crates'),
                                    _PrintTableHeader('Total Boxes'),
                                    _PrintTableHeader('Total Pieces'),
                                    _PrintTableHeader('Base Equivalent'),
                                    _PrintTableHeader('Vehicles'),
                                    _PrintTableHeader('Total Value (₹)'),
                                  ],
                                ),
                                ...dispatchedProducts.map((s) {
                                  return TableRow(
                                    children: [
                                      _PrintTableCell(s.productName, isBold: true),
                                      _PrintTableCell(s.packSizeDisplay),
                                      _PrintTableCell(s.formattedCrates),
                                      _PrintTableCell(s.formattedBoxes, color: (s.totalBoxes != null && s.totalBoxes! > 0) ? const Color(0xFF1D4ED8) : null),
                                      _PrintTableCell(s.formattedPieces),
                                      _PrintTableCell(s.formattedQuantity),
                                      _PrintTableCell(s.vehicleCount > 0 ? '${s.vehicleCount}' : '0'),
                                      _PrintTableCell(s.formattedRevenue, color: s.revenue > 0 ? const Color(0xFF047857) : null),
                                    ],
                                  );
                                }),
                                TableRow(
                                  decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                                  children: [
                                    _PrintTableCell('TOTAL (${dispatchedProducts.length})', isBold: true),
                                    const _PrintTableCell('—', isBold: true),
                                    _PrintTableCell(
                                      totalCratesSum == totalCratesSum.roundToDouble()
                                          ? '${totalCratesSum.toInt()} crates'
                                          : '${Formatters.formatSmart(totalCratesSum)} crates',
                                      isBold: true,
                                    ),
                                    _PrintTableCell(
                                      totalBoxesSum > 0
                                          ? (totalBoxesSum == totalBoxesSum.roundToDouble()
                                              ? '${totalBoxesSum.toInt()} boxes'
                                              : '${Formatters.formatSmart(totalBoxesSum)} boxes')
                                          : '0 boxes',
                                      isBold: true,
                                      color: const Color(0xFF1D4ED8),
                                    ),
                                    _PrintTableCell('$totalPiecesSum pcs', isBold: true),
                                    _PrintTableCell('${Formatters.formatSmart(totalLiquidSum)} L / ${Formatters.formatSmart(totalSolidSum)} kg', isBold: true, color: const Color(0xFF0369A1)),
                                    const _PrintTableCell('—', isBold: true),
                                    _PrintTableCell(totalRevenueSum > 0 ? '₹${Formatters.formatSmart(totalRevenueSum)}' : '₹0', isBold: true, color: const Color(0xFF047857)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: const [
                                _PrintSignature(name: 'Biraj Goswami', title: 'Caseya Developer'),
                                _PrintSignature(title: 'Verified by'),
                                _PrintSignature(title: 'Plant Head'),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 5: REPORTS (EXECUTIVE EXPORT CENTER & ANALYTICS)
  // ===========================================================================

  // ignore: unused_element
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
                  subtitle: 'Full list of vehicles dispatched with logged by, distributor, and line items',
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
                                  _tabController.animateTo(2); // Go to Distributor Wise
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

  Widget _buildTableHeaderCell(String text, {bool alignRight = false, bool alignCenter = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Align(
        alignment: alignCenter
            ? Alignment.center
            : (alignRight ? Alignment.centerRight : Alignment.centerLeft),
        child: Text(
          text,
          textAlign: alignCenter ? TextAlign.center : (alignRight ? TextAlign.right : TextAlign.left),
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
                        labelText: 'Logged By',
                        hintText: 'Select or type name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                        suffixIcon: PopupMenuButton<String>(
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                          tooltip: 'Select Logged By',
                          onSelected: (val) {
                            setState(() {
                              _driverController.text = val;
                            });
                          },
                          itemBuilder: (context) {
                            return _DispatchPageState.authorizedLoggers.map((person) {
                              return PopupMenuItem<String>(
                                value: person,
                                child: Text(person, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              );
                            }).toList();
                          },
                        ),
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
                _buildInfoColumn('Logged By', dispatch.driverName.isNotEmpty ? dispatch.driverName : (dispatch.recordedBy.isNotEmpty ? dispatch.recordedBy : '—')),
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

class _PrintTableHeader extends StatelessWidget {
  final String text;
  const _PrintTableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: AppFontWeights.bold,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }
}

class _PrintTableCell extends StatelessWidget {
  final String text;
  final bool isBold;
  final Color? color;

  const _PrintTableCell(this.text, {this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? AppFontWeights.bold : AppFontWeights.regular,
          color: color ?? const Color(0xFF334155),
        ),
      ),
    );
  }
}

class _PrintSignature extends StatelessWidget {
  final String title;
  final String? name;

  const _PrintSignature({required this.title, this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 20,
          child: (name != null && name!.isNotEmpty)
              ? Text(
                  name!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: AppFontWeights.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 4),
        Container(
          width: 170,
          height: 1.2,
          color: Colors.black54,
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF475569),
            fontWeight: AppFontWeights.medium,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}


