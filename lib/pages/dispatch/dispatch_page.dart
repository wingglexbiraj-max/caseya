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
import '../../services/calculation_service.dart';

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
    final defaultProduct = DairyProducts.officialProducts.first;
    _inlineProductRows.add(
      _ProductRowDraft(
        productId: defaultProduct.productId,
        inputMode: defaultProduct.allowedInputModes.contains('Pieces')
            ? 'Pieces'
            : defaultProduct.allowedInputModes.first,
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
      r.quantityController.dispose();
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
    setState(() {
      final first = catalog.isNotEmpty ? catalog.first : DairyProducts.officialProducts.first;
      _inlineProductRows.add(
        _ProductRowDraft(
          productId: first.productId,
          inputMode: first.allowedInputModes.contains('Pieces')
              ? 'Pieces'
              : first.allowedInputModes.first,
          initialQty: '',
        ),
      );
    });
  }

  void _removeInlineProductRow(int index) {
    if (_inlineProductRows.length > 1) {
      setState(() {
        _inlineProductRows[index].quantityController.dispose();
        _inlineProductRows.removeAt(index);
      });
    } else {
      // Clear the single row
      setState(() {
        _inlineProductRows[0].quantityController.clear();
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
      r.quantityController.dispose();
    }
    _inlineProductRows.clear();
    _initDefaultProductRow();
    setState(() {});
  }

  // Submit Vehicle Entry in Tab 1
  Future<void> _submitInlineVehicle() async {
    if (!_inlineFormKey.currentState!.validate()) return;

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

    final distributor = _inlineDistributorController.text.trim();
    if (distributor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Distributor is required. Please select or enter a distributor.'),
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

      final qty = double.tryParse(draft.quantityController.text.trim()) ?? 0.0;
      if (qty <= 0) {
        // Skip or warn if zero/negative
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
          inputMode: draft.inputMode,
          inputQuantity: qty,
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
            // Top Header & Date Navigation
            _buildHeader(isMobile, isViewingToday, todayStr),
            const SizedBox(height: 16),

            // Top Summary Metrics Grid
            _buildMetricsGrid(state, isMobile),
            const SizedBox(height: 20),

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
                    text: 'Enter Dispatch',
                  ),
                  Tab(
                    icon: const Icon(Icons.local_shipping_rounded, size: 18),
                    text: 'Dispatch Records (${state.dispatchesForSelectedDate.length})',
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
                    text: 'Reports',
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
  // TOP EXECUTIVE HEADER & DATE BAR
  // ===========================================================================

  Widget _buildHeader(bool isMobile, bool isViewingToday, String todayStr) {
    final state = ref.watch(dispatchProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.headerBackground,
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2448), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.headerBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2448).withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: AppColors.goldAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CASEYA DISPATCH MANAGEMENT',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: AppTextSizes.caption,
                          letterSpacing: 1.2,
                          fontWeight: AppFontWeights.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vehicle-Wise Plant Distribution',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: AppFontWeights.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openDispatchDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(isMobile ? 'New' : 'New Vehicle Entry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),

          // Date Navigator Controls
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
                tooltip: 'Previous Day',
                onPressed: () => _shiftDate(-1),
              ),
              InkWell(
                onTap: () => _pickDate(state.selectedDate),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Color(0xFFFDE68A), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _formatDisplayDate(state.selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: AppFontWeights.bold,
                          fontSize: AppTextSizes.body,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                tooltip: 'Next Day',
                onPressed: () => _shiftDate(1),
              ),
              const SizedBox(width: 8),
              if (!isViewingToday)
                TextButton(
                  onPressed: _jumpToToday,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text(
                    'Jump to Today',
                    style: TextStyle(
                      color: Color(0xFFFDE68A),
                      fontWeight: AppFontWeights.bold,
                      fontSize: AppTextSizes.caption,
                    ),
                  ),
                ),
              const Spacer(),
              if (!isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isViewingToday
                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isViewingToday ? const Color(0xFF34D399) : Colors.white24,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isViewingToday ? Icons.check_circle_rounded : Icons.history_rounded,
                        color: isViewingToday ? const Color(0xFF34D399) : Colors.white70,
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isViewingToday ? 'LIVE TODAY DISPATCH' : 'HISTORICAL ARCHIVE',
                        style: TextStyle(
                          color: isViewingToday ? const Color(0xFF34D399) : Colors.white70,
                          fontSize: AppTextSizes.caption,
                          fontWeight: AppFontWeights.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(DispatchState state, bool isMobile) {
    final double revenue = state.totalRevenueForSelectedDate;

    final metrics = [
      _MetricTile(
        title: 'Vehicles Dispatched',
        value: '${state.totalVehiclesForSelectedDate}',
        subtitle: 'Plant Gate Out',
        icon: Icons.local_shipping_rounded,
        color: AppColors.primary,
      ),
      _MetricTile(
        title: 'Total Crates',
        value: Formatters.formatSmart(state.totalCratesForSelectedDate),
        subtitle: 'Standard Crates',
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFF0F766E),
      ),
      _MetricTile(
        title: 'Total Pieces',
        value: Formatters.formatInt(state.totalPiecesForSelectedDate),
        subtitle: 'Individual Packets',
        icon: Icons.format_list_bulleted_rounded,
        color: const Color(0xFF2563EB),
      ),
      _MetricTile(
        title: 'Total Sales Revenue',
        value: '₹${Formatters.formatSmart(revenue)}',
        subtitle: 'Commercial Value',
        icon: Icons.currency_rupee_rounded,
        color: const Color(0xFF059669),
      ),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.45,
        children: metrics,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (3 * 14)) / 4;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: metrics
              .map((m) => SizedBox(width: itemWidth, child: m))
              .toList(),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 1: ENTER DISPATCH (VEHICLE ENTRY FORM + TODAY'S DISPATCH SUMMARY)
  // ===========================================================================

  Widget _buildEnterDispatchTab(DispatchState state, bool isMobile) {
    if (isMobile) {
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildVehicleEntryFormCard(state),
            const SizedBox(height: 16),
            _buildTodaysSummaryCard(state),
          ],
        ),
      );
    }

    // Desktop: Split 2-Column Responsive Layout
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Vehicle Entry Form (50% width)
        Expanded(
          flex: 6,
          child: _buildVehicleEntryFormCard(state),
        ),
        const SizedBox(width: 16),
        // Right Column: Live Daily Dispatch Summary (50% width)
        Expanded(
          flex: 5,
          child: _buildTodaysSummaryCard(state),
        ),
      ],
    );
  }

  Widget _buildVehicleEntryFormCard(DispatchState state) {
    final catalog = state.catalogProducts;
    final distributors = state.availableDistributors;

    return AppCard(
      child: Form(
        key: _inlineFormKey,
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VEHICLE DISPATCH ENTRY',
                          style: TextStyle(
                            fontSize: AppTextSizes.caption,
                            fontWeight: AppFontWeights.bold,
                            letterSpacing: 1.1,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Date: ${_formatDisplayDate(state.selectedDate)}',
                          style: const TextStyle(
                            fontSize: AppTextSizes.subheading,
                            fontWeight: AppFontWeights.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                StatusBadge.info('Fast Morning Entry'),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Vehicle Number & Distributor Inputs
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _inlineVehicleController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Vehicle Number *',
                      hintText: 'e.g. AS-01-EC-4421 / Vehicle A',
                      prefixIcon: const Icon(Icons.directions_car_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return distributors;
                      }
                      return distributors.where((d) =>
                          d.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      _inlineDistributorController.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      // Keep in sync
                      if (_inlineDistributorController.text.isNotEmpty && controller.text.isEmpty) {
                        controller.text = _inlineDistributorController.text;
                      }
                      controller.addListener(() {
                        _inlineDistributorController.text = controller.text;
                      });
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        decoration: InputDecoration(
                          labelText: 'Distributor *',
                          hintText: 'Select or enter distributor',
                          prefixIcon: const Icon(Icons.storefront_rounded, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Driver Name & Remarks
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _inlineDriverController,
                    decoration: InputDecoration(
                      labelText: 'Driver Name (Optional)',
                      hintText: 'e.g. Ramesh Bora',
                      prefixIcon: const Icon(Icons.person_outline, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _inlineRemarksController,
                    decoration: InputDecoration(
                      labelText: 'Remarks (Optional)',
                      hintText: 'e.g. Morning Route 1',
                      prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section: Products Supplied in This Vehicle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Products Supplied in This Vehicle',
                  style: TextStyle(
                    fontWeight: AppFontWeights.bold,
                    fontSize: AppTextSizes.body,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addInlineProductRow(catalog),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Add Product', style: TextStyle(fontWeight: AppFontWeights.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Dynamic Product Line Items
            Expanded(
              child: ListView.separated(
                itemCount: _inlineProductRows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = _inlineProductRows[index];
                  final selectedProduct = catalog.firstWhere(
                    (p) => p.productId == row.productId,
                    orElse: () => catalog.isNotEmpty ? catalog.first : DairyProducts.officialProducts.first,
                  );

                  // Compute real-time conversion preview
                  final double enteredQty = double.tryParse(row.quantityController.text.trim()) ?? 0.0;
                  String equivalentPreview = '';
                  if (enteredQty > 0) {
                    final calc = CalculationService.calculateProduct(
                      product: selectedProduct,
                      inputMode: row.inputMode,
                      inputQuantity: enteredQty,
                    );
                    final saleUnit = selectedProduct.individualSaleUnitPlural;
                    final bulkUnit = selectedProduct.bulkPackingUnit ?? 'crates';
                    final isBulkInput = row.inputMode == 'Crates' || row.inputMode == 'Boxes';

                    if (isBulkInput) {
                      equivalentPreview = '= ${calc.pieces} $saleUnit (${Formatters.formatSmart(calc.totalQuantity)} ${selectedProduct.baseUnitLabel}) • ${calc.totalPriceDisplay}';
                    } else if (selectedProduct.hasCrateConfiguration) {
                      equivalentPreview = '= ${Formatters.formatSmart(calc.crates)} $bulkUnit (${Formatters.formatSmart(calc.totalQuantity)} ${selectedProduct.baseUnitLabel}) • ${calc.totalPriceDisplay}';
                    } else {
                      equivalentPreview = '= ${Formatters.formatSmart(calc.totalQuantity)} ${selectedProduct.baseUnitLabel} • ${calc.totalPriceDisplay}';
                    }
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Product Selector
                        Expanded(
                          flex: 4,
                          child: DropdownButtonFormField<String>(
                            initialValue: row.productId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Product',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            items: catalog.map((p) {
                              return DropdownMenuItem<String>(
                                value: p.productId,
                                child: Text(
                                  '${p.productName} (${p.packSizeDisplay})',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
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

                        // Unit Selector (Restricted to units supported by selected product)
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('${row.productId}_${row.inputMode}'),
                            initialValue: selectedProduct.allowedInputModes.contains(row.inputMode)
                                ? row.inputMode
                                : selectedProduct.allowedInputModes.first,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            items: selectedProduct.allowedInputModes.map((u) {
                              return DropdownMenuItem<String>(
                                value: u,
                                child: Text(u, style: const TextStyle(fontSize: 13)),
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

                        // Quantity Input
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: row.quantityController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              hintText: 'Qty',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Real-time Equivalent Preview Pill
                        if (equivalentPreview.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Text(
                              equivalentPreview,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: AppFontWeights.bold,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ),

                        const SizedBox(width: 6),
                        // Remove Row Button
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)),
                          tooltip: 'Remove Row',
                          onPressed: () => _removeInlineProductRow(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Action Row: Prominent "Add to Today's Dispatch" Button
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _resetInlineForm,
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: const Text('Reset Form'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isInlineSaving ? null : _submitInlineVehicle,
                    icon: _isInlineSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.add_task_rounded, size: 20),
                    label: Text(
                      _isInlineSaving ? 'Saving Vehicle to Dispatch...' : 'Add to Today\'s Dispatch',
                      style: const TextStyle(
                        fontSize: AppTextSizes.body,
                        fontWeight: AppFontWeights.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
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

  Widget _buildTodaysSummaryCard(DispatchState state) {
    final summaries = state.dailyProductSummaries;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TODAY\'S DISPATCH SUMMARY',
                    style: TextStyle(
                      fontSize: AppTextSizes.caption,
                      fontWeight: AppFontWeights.bold,
                      letterSpacing: 1.1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Daily Totals for ${_formatDisplayDate(state.selectedDate)}',
                    style: const TextStyle(
                      fontSize: AppTextSizes.subheading,
                      fontWeight: AppFontWeights.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              StatusBadge.success('Live Dynamic Rollup'),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Mini Daily Metric Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMiniSummaryChip(
                label: 'Vehicles',
                value: '${state.totalVehiclesForSelectedDate}',
                icon: Icons.local_shipping_outlined,
                color: AppColors.primary,
              ),
              _buildMiniSummaryChip(
                label: 'Crates',
                value: Formatters.formatSmart(state.totalCratesForSelectedDate),
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF0F766E),
              ),
              _buildMiniSummaryChip(
                label: 'Pieces',
                value: Formatters.formatInt(state.totalPiecesForSelectedDate),
                icon: Icons.format_list_bulleted,
                color: const Color(0xFF2563EB),
              ),
              _buildMiniSummaryChip(
                label: 'Liquid Milk/Lassi',
                value: '${Formatters.formatSmart(state.totalLitresForSelectedDate)} L',
                icon: Icons.water_drop_outlined,
                color: const Color(0xFF0284C7),
              ),
              _buildMiniSummaryChip(
                label: 'Curd/Solids',
                value: '${Formatters.formatSmart(state.totalKgForSelectedDate)} kg',
                icon: Icons.takeout_dining_outlined,
                color: const Color(0xFFD97706),
              ),
              _buildMiniSummaryChip(
                label: 'Revenue',
                value: '₹${Formatters.formatSmart(state.totalRevenueForSelectedDate)}',
                icon: Icons.currency_rupee_rounded,
                color: const Color(0xFF059669),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Table of Product Summaries
          if (summaries.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inbox_outlined, size: 44, color: AppColors.textSecondary),
                    const SizedBox(height: 8),
                    const Text(
                      'No Dispatches Yet Today',
                      style: TextStyle(
                        fontSize: AppTextSizes.body,
                        fontWeight: AppFontWeights.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter vehicle number and products on the left, then click "Add to Today\'s Dispatch".',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: AppColors.divider.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(3.0),
                    1: FlexColumnWidth(1.2),
                    2: FlexColumnWidth(1.2),
                    3: FlexColumnWidth(1.5),
                    4: FlexColumnWidth(1.4),
                  },
                  children: [
                    // Header Row
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                      children: [
                        _buildTableHeaderCell('Product Description'),
                        _buildTableHeaderCell('Crates', alignRight: true),
                        _buildTableHeaderCell('Pieces', alignRight: true),
                        _buildTableHeaderCell('Equivalent (L/kg)', alignRight: true),
                        _buildTableHeaderCell('Value (₹)', alignRight: true),
                      ],
                    ),
                    // Product Rows
                    ...summaries.map((s) {
                      final isLiquid = s.normalizedUnit.toLowerCase().startsWith('l');
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.productName,
                                  style: const TextStyle(
                                    fontWeight: AppFontWeights.bold,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${s.itemCode} • ${s.packSizeDisplay} • ${s.vehicleCount} veh',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                s.formattedCrates,
                                style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                s.formattedPieces,
                                style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: 13),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                s.formattedQuantity,
                                style: TextStyle(
                                  fontWeight: AppFontWeights.bold,
                                  fontSize: 13,
                                  color: isLiquid ? const Color(0xFF0369A1) : const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
          ],
        ],
      ),
    );
  }

  Widget _buildMiniSummaryChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: AppFontWeights.bold, color: color),
          ),
        ],
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
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: Text(
                                        '${item.shortCode}: ${item.formattedQuantity}',
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
// METRIC TILE WIDGET
// =============================================================================

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTextSizes.caption,
                    fontWeight: AppFontWeights.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: AppFontWeights.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
  final TextEditingController quantityController;

  _ProductRowDraft({
    this.productId,
    this.inputMode = 'Pieces',
    String initialQty = '',
  }) : quantityController = TextEditingController(text: initialQty);
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
