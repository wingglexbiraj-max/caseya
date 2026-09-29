import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
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
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
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
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final next = current.add(Duration(days: days));
        final nextStr =
            '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
        ref.read(dispatchProvider.notifier).setSelectedDate(nextStr);
      }
    } catch (_) {}
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
          'Are you sure you want to delete dispatch record for vehicle "${dispatch.vehicleNumber}" (${dispatch.distributorName})? All associated product lines will be removed and daily summary will be recalculated.',
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

    final todayStr =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    final isViewingToday = state.selectedDate == todayStr;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 26,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Executive Header
            _buildHeader(isMobile, isViewingToday, todayStr),
            const SizedBox(height: 18),

            // Metrics Summary Grid
            _buildMetricsGrid(state, isMobile),
            const SizedBox(height: 22),

            // Tab Bar Navigation
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
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.table_chart_rounded, size: 18),
                    text: 'Daily Summary (${state.dailyProductSummaries.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.local_shipping_rounded, size: 18),
                    text: 'Vehicles (${state.dispatchesForSelectedDate.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    text: 'Distributor-wise (${state.distributorSummaries.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.history_rounded, size: 18),
                    text: 'History (${state.dateWiseHistory.length} Days)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab View Contents
            SizedBox(
              height: 720,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDailySummaryTab(state),
                  _buildVehiclesTab(state, isMobile),
                  _buildDistributorSummaryTab(state),
                  _buildHistoryTab(state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                      border: Border.all(
                        color: AppColors.goldAccent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: Color(0xFFFDE68A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PLANT LOGISTICS & GATE OUT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                      Text(
                        'Dispatch Records',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openDispatchDialog(),
                icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                label: const Text(
                  'New Vehicle Dispatch',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFF1E3A8A)),
          const SizedBox(height: 12),

          // Date Navigator Strip
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                      onPressed: () => _shiftDate(-1),
                      tooltip: 'Previous Day',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                    InkWell(
                      onTap: () => _pickDate(state.selectedDate),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: Color(0xFFBAE6FD), size: 14),
                            const SizedBox(width: 8),
                            Text(
                              _formatDisplayDate(state.selectedDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                      onPressed: () => _shiftDate(1),
                      tooltip: 'Next Day',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (!isViewingToday)
                TextButton(
                  onPressed: () {
                    ref.read(dispatchProvider.notifier).setSelectedDate(todayStr);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text(
                    'Jump to Today',
                    style: TextStyle(color: Color(0xFFFDE68A), fontWeight: FontWeight.w700, fontSize: 12),
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
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
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
    final double crates = state.totalCratesForSelectedDate;
    final int pieces = state.totalPiecesForSelectedDate;
    final double litres = state.totalLitresForSelectedDate;
    final double kg = state.totalKgForSelectedDate;

    final metrics = [
      _MetricTile(
        title: 'Total Vehicles',
        value: '${state.totalVehiclesForSelectedDate}',
        subtitle: 'Dispatched Gate Out',
        icon: Icons.local_shipping_rounded,
        color: AppColors.primary,
      ),
      _MetricTile(
        title: 'Distributors',
        value: '${state.totalDistributorsForSelectedDate}',
        subtitle: 'Distribution Routes',
        icon: Icons.storefront_rounded,
        color: AppColors.goldAccent,
      ),
      _MetricTile(
        title: 'Product Lines',
        value: '${state.totalProductLinesForSelectedDate}',
        subtitle: 'SKU Line Dispatches',
        icon: Icons.format_list_bulleted_rounded,
        color: const Color(0xFF0F766E),
      ),
      _MetricTile(
        title: 'Liquid Volume',
        value: '${Formatters.formatSmart(litres)} L',
        subtitle: 'Lassi & Fluid Milk',
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF0284C7),
      ),
      _MetricTile(
        title: 'Curd / Solids',
        value: '${Formatters.formatSmart(kg)} kg',
        subtitle: 'Curd Cups & Pouches',
        icon: Icons.scale_rounded,
        color: const Color(0xFFD97706),
      ),
      _MetricTile(
        title: 'Total Crates',
        value: crates == crates.roundToDouble()
            ? '${crates.toInt()}'
            : Formatters.formatSmart(crates),
        subtitle: '$pieces Pieces Total',
        icon: Icons.all_inbox_rounded,
        color: const Color(0xFF4F46E5),
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
        final itemWidth = (constraints.maxWidth - (5 * 12)) / 6;
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
  // TAB 1: DAILY CONSOLIDATED SUMMARY (PRODUCT-WISE TOTALS)
  // ===========================================================================

  Widget _buildDailySummaryTab(DispatchState state) {
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
                    'DAILY DISPATCH CONSOLIDATED SUMMARY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Consolidated Product Totals for ${_formatDisplayDate(state.selectedDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  StatusBadge.success('Dynamic Real-time Rollup'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),

          if (summaries.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF991B1B)),
                    const SizedBox(height: 12),
                    const Text(
                      'No Dispatches Recorded for this Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Click "+ New Vehicle Dispatch" to record a vehicle and generate product totals.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _openDispatchDialog(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Vehicle Dispatch'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            const SizedBox(height: 12),
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
                    3: FlexColumnWidth(1.6),
                    4: FlexColumnWidth(1.2),
                  },
                  children: [
                    // Header Row
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                      ),
                      children: [
                        _buildTableHeaderCell('Product Description'),
                        _buildTableHeaderCell('Total Crates', alignRight: true),
                        _buildTableHeaderCell('Total Pieces', alignRight: true),
                        _buildTableHeaderCell('Quantity (L / kg)', alignRight: true),
                        _buildTableHeaderCell('Spread', alignRight: true),
                      ],
                    ),

                    // Product Summary Rows
                    ...summaries.map((s) {
                      final isLiquid = s.normalizedUnit.toLowerCase().startsWith('l');
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isLiquid
                                        ? const Color(0xFFE0F2FE)
                                        : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    isLiquid
                                        ? Icons.water_drop_outlined
                                        : Icons.takeout_dining_outlined,
                                    size: 16,
                                    color: isLiquid
                                        ? const Color(0xFF0284C7)
                                        : const Color(0xFFD97706),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Code: ${s.itemCode} • Pack: ${s.packSizeDisplay}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                s.formattedCrates,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                s.formattedPieces,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
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
                                  color: isLiquid
                                      ? const Color(0xFFF0F9FF)
                                      : const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isLiquid
                                        ? const Color(0xFFBAE6FD)
                                        : const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: Text(
                                  s.formattedQuantity,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: isLiquid
                                        ? const Color(0xFF0369A1)
                                        : const Color(0xFFB45309),
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
                                '${s.vehicleCount} ${s.vehicleCount == 1 ? 'veh' : 'vehs'} • ${s.distributorCount} dist',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
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

            // Separate Totals Strip at Bottom (Never sum L and kg together)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DAILY TOTALS:',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      letterSpacing: 0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Wrap(
                    spacing: 16,
                    children: [
                      Text(
                        'Total Crates: ${Formatters.formatSmart(state.totalCratesForSelectedDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      Text(
                        'Total Pieces: ${state.totalPiecesForSelectedDate}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Liquid Milk/Lassi: ${Formatters.formatSmart(state.totalLitresForSelectedDate)} L',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Curd/Solids: ${Formatters.formatSmart(state.totalKgForSelectedDate)} kg',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: VEHICLE DISPATCHES (GROUPED BY VEHICLE)
  // ===========================================================================

  Widget _buildVehiclesTab(DispatchState state, bool isMobile) {
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
                    hintText: 'Search by vehicle (e.g. AS01AB1234), distributor, product, driver...',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                hint: const Text('All Distributors', style: TextStyle(fontSize: 12.5)),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Distributors', style: TextStyle(fontSize: 12.5)),
                  ),
                  ...state.availableDistributors.map(
                    (d) => DropdownMenuItem<String?>(
                      value: d,
                      child: Text(d, style: const TextStyle(fontSize: 12.5)),
                    ),
                  ),
                ],
                onChanged: (val) {
                  ref.read(dispatchProvider.notifier).setDistributorFilter(val);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Vehicles List
        Expanded(
          child: dispatches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 48, color: Color(0xFF991B1B)),
                      const SizedBox(height: 12),
                      const Text(
                        'No Vehicle Dispatches Match Filter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Try clearing search filters or add a new vehicle dispatch.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: dispatches.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final d = dispatches[index];
                    return _buildVehicleCard(d, isMobile);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVehicleCard(VehicleDispatch dispatch, bool isMobile) {
    final hasRemarks = dispatch.remarks.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1.1),
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
          // Vehicle Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: const Border(
                bottom: BorderSide(color: AppColors.cardBorder, width: 1.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dispatch.vehicleNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      dispatch.distributorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.goldAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        dispatch.summaryLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Time: ${dispatch.dispatchTime}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: 'View Details',
                      onPressed: () => _openVehicleDetails(dispatch),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Dispatch',
                      onPressed: () => _openDispatchDialog(existing: dispatch),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF991B1B)),
                      tooltip: 'Delete Dispatch',
                      onPressed: () => _confirmDelete(dispatch),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Metadata row (Driver, Route)
          if (dispatch.driverName.isNotEmpty || dispatch.route.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  if (dispatch.driverName.isNotEmpty) ...[
                    const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Driver: ${dispatch.driverName}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (dispatch.route.isNotEmpty) ...[
                    const Icon(Icons.alt_route, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Route: ${dispatch.route}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),

          // Products Table / List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: dispatch.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right, size: 18, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.formattedCrates} • ${item.formattedPieces} • ${item.formattedQuantityWithUnit}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Note / Remarks strip (Red if present as per CASEYA rule)
          if (hasRemarks)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note_alt_outlined, size: 14, color: Color(0xFF991B1B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Note: ${dispatch.remarks}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF991B1B),
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
  // TAB 3: DISTRIBUTOR-WISE SUMMARY
  // ===========================================================================

  Widget _buildDistributorSummaryTab(DispatchState state) {
    final list = state.distributorSummaries;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined, size: 48, color: Color(0xFF991B1B)),
            const SizedBox(height: 12),
            const Text(
              'No Distributor Data for this Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF991B1B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final dist = list[index];
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.storefront, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dist.distributorName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Vehicles: ${dist.vehicles.join(", ")}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${Formatters.formatSmart(dist.totalCrates)} Crates Total',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Product breakdown
              Column(
                children: dist.productItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '• ${item.productName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${item.formattedCrates} (${item.formattedPieces} • ${item.formattedQuantityWithUnit})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 4: DISPATCH HISTORY (DATE-WISE ARCHIVE)
  // ===========================================================================

  Widget _buildHistoryTab(DispatchState state) {
    final list = state.dateWiseHistory;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 48, color: Color(0xFF991B1B)),
            const SizedBox(height: 12),
            const Text(
              'No Historical Dispatches Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF991B1B),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DISPATCH ARCHIVE HISTORY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select any date to view all vehicle dispatches and consolidated product metrics.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final hist = list[index];
                final isSelected = hist.date == state.selectedDate;

                return InkWell(
                  onTap: () {
                    ref.read(dispatchProvider.notifier).setSelectedDate(hist.date);
                    _tabController.animateTo(0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : null,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDisplayDate(hist.date),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${hist.vehiclesCount} vehicles • ${hist.distributorsCount} distributors • ${hist.productLinesCount} lines',
                                style: const TextStyle(
                                  fontSize: 12,
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
                              '${Formatters.formatSmart(hist.totalCrates)} Crates',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              '${Formatters.formatSmart(hist.totalLitres)} L • ${Formatters.formatSmart(hist.totalKg)} kg',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.5,
          color: AppColors.textSecondary,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// VEHICLE DISPATCH CREATION & EDIT DIALOG
// =============================================================================

class _VehicleDispatchDialog extends ConsumerStatefulWidget {
  final VehicleDispatch? existing;

  const _VehicleDispatchDialog({this.existing});

  @override
  ConsumerState<_VehicleDispatchDialog> createState() =>
      _VehicleDispatchDialogState();
}

class _ProductRowDraft {
  String? productId;
  String inputMode;
  final TextEditingController quantityController;

  _ProductRowDraft({
    this.productId,
    this.inputMode = 'Crates',
    String initialQty = '',
  }) : quantityController = TextEditingController(text: initialQty);
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

    _distributorController =
        TextEditingController(text: d?.distributorName ?? '');
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
      // Default initial row
      _productDrafts.add(_ProductRowDraft(inputMode: 'Crates'));
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

  void _addProductRow() {
    setState(() {
      _productDrafts.add(_ProductRowDraft(inputMode: 'Crates'));
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

    final products = ref.read(dispatchProvider).products;
    final List<DispatchItem> items = [];
    final dispatchId = widget.existing?.id ??
        'DISP-${DateTime.now().millisecondsSinceEpoch}';

    for (int i = 0; i < _productDrafts.length; i++) {
      final draft = _productDrafts[i];
      if (draft.productId == null || draft.productId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a product for row #${i + 1}.'),
            backgroundColor: const Color(0xFF991B1B),
          ),
        );
        return;
      }

      final qty = double.tryParse(draft.quantityController.text.trim()) ?? 0.0;
      if (qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quantity must be greater than 0 for row #${i + 1}.'),
            backgroundColor: const Color(0xFF991B1B),
          ),
        );
        return;
      }

      final product = products.firstWhere(
        (p) => p.productId == draft.productId,
        orElse: () => products.first,
      );

      final item = DispatchItem.fromInput(
        id: 'ITEM-${DateTime.now().millisecondsSinceEpoch}-$i',
        dispatchId: dispatchId,
        product: product,
        inputMode: draft.inputMode,
        inputQuantity: qty,
      );
      items.add(item);
    }

    setState(() => _isSaving = true);

    final currentUser = ref.read(authProvider).name;
    final record = VehicleDispatch(
      id: dispatchId,
      dispatchDate: _dispatchDate,
      distributorName: _distributorController.text.trim(),
      vehicleNumber: _vehicleController.text.trim().toUpperCase(),
      driverName: _driverController.text.trim(),
      route: _routeController.text.trim(),
      dispatchTime: _timeController.text.trim(),
      remarks: _remarksController.text.trim(),
      createdBy: widget.existing?.createdBy ?? currentUser,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      items: items,
    );

    final success = widget.existing != null
        ? await ref.read(dispatchProvider.notifier).updateDispatch(record)
        : await ref.read(dispatchProvider.notifier).saveDispatch(record);

    setState(() => _isSaving = false);

    if (mounted && success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Vehicle ${record.vehicleNumber} dispatch recorded with ${items.length} products.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(dispatchProvider).products;
    final availableDistributors = ref.watch(dispatchProvider).availableDistributors;

    // Calculate live totals for the dialog preview
    double liveCrates = 0.0;
    int livePieces = 0;
    double liveLitres = 0.0;
    double liveKg = 0.0;

    for (final draft in _productDrafts) {
      if (draft.productId != null && draft.productId!.isNotEmpty) {
        final qty = double.tryParse(draft.quantityController.text) ?? 0.0;
        if (qty > 0) {
          final prod = products.firstWhere(
            (p) => p.productId == draft.productId,
            orElse: () => products.first,
          );
          final calc = CalculationService.calculateProduct(
            product: prod,
            inputMode: draft.inputMode,
            inputQuantity: qty,
          );
          liveCrates += calc.crates;
          livePieces += calc.pieces;
          if (prod.baseUnitLabel == 'Litres') {
            liveLitres += calc.totalQuantity;
          } else {
            liveKg += calc.totalQuantity;
          }
        }
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 860),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: AppColors.headerBackground,
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F2448), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          widget.existing != null
                              ? 'Edit Vehicle Dispatch — ${widget.existing!.vehicleNumber}'
                              : 'New Vehicle Dispatch',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Vehicle & Route Information
                      const Text(
                        '1. VEHICLE & ROUTE DETAILS',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          // Distributor Dropdown / Autocomplete
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Distributor Name *',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 5),
                                Autocomplete<String>(
                                  initialValue: TextEditingValue(text: _distributorController.text),
                                  optionsBuilder: (textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return availableDistributors;
                                    }
                                    return availableDistributors.where((d) => d
                                        .toLowerCase()
                                        .contains(textEditingValue.text.toLowerCase()));
                                  },
                                  onSelected: (val) {
                                    _distributorController.text = val;
                                  },
                                  fieldViewBuilder: (ctx, ctrl, focusNode, onFieldSubmitted) {
                                    _distributorController = ctrl;
                                    return TextFormField(
                                      controller: ctrl,
                                      focusNode: focusNode,
                                      validator: (val) => val == null || val.trim().isEmpty
                                          ? 'Distributor is required'
                                          : null,
                                      decoration: InputDecoration(
                                        hintText: 'e.g. Distributor A',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Vehicle Number
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vehicle Number *',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: _vehicleController,
                                  textCapitalization: TextCapitalization.characters,
                                  validator: (val) => val == null || val.trim().isEmpty
                                      ? 'Vehicle is required'
                                      : null,
                                  decoration: InputDecoration(
                                    hintText: 'AS01AB1234',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Dispatch Time
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dispatch Time',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: _timeController,
                                  decoration: InputDecoration(
                                    hintText: '08:35 AM',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          // Driver Name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Driver Name (Optional)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: _driverController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Ramesh Sharma',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Route/Area
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Route / Area (Optional)',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: _routeController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Route 01 - City North',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Remarks / Special Notes (Rendered in red alert format in UI if present)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Remarks / Notes (Optional - Highlights in red alert if populated)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _remarksController,
                            decoration: InputDecoration(
                              hintText: 'e.g. Temperature checked 4°C, pre-chilled van, seal #9921',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Section 2: Products Lines
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '2. DISPATCH PRODUCTS (ONE VEHICLE = MULTIPLE PRODUCTS)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addProductRow,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Dynamic product entry rows
                      ..._productDrafts.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final draft = entry.value;

                        // Find selected product
                        ProductModel? selectedProduct;
                        if (draft.productId != null) {
                          try {
                            selectedProduct = products.firstWhere((p) => p.productId == draft.productId);
                          } catch (_) {}
                        }

                        // Determine available input modes based on product metadata
                        final allowedModes = selectedProduct?.allowedInputModes ?? ['Crates', 'Pieces', 'Litres', 'Kg'];
                        if (!allowedModes.contains(draft.inputMode) && allowedModes.isNotEmpty) {
                          draft.inputMode = allowedModes.first;
                        }

                        // Calculate conversion preview for this row
                        final qty = double.tryParse(draft.quantityController.text) ?? 0.0;
                        ProductCalculationResult? calcResult;
                        if (selectedProduct != null && qty > 0) {
                          calcResult = CalculationService.calculateProduct(
                            product: selectedProduct,
                            inputMode: draft.inputMode,
                            inputQuantity: qty,
                          );
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Product Dropdown
                                  Expanded(
                                    flex: 4,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: draft.productId,
                                      hint: const Text('Select Product *', style: TextStyle(fontSize: 13)),
                                      isDense: true,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                        fillColor: Colors.white,
                                        filled: true,
                                      ),
                                      items: products.map((p) {
                                        return DropdownMenuItem<String>(
                                          value: p.productId,
                                          child: Text(
                                            '${p.productName} (${p.packSizeDisplay}, ${p.piecesPerCrate} pcs/cr)',
                                            style: const TextStyle(fontSize: 12.5),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (newProductId) {
                                        setState(() {
                                          draft.productId = newProductId;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Input Mode selector
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: draft.inputMode,
                                      isDense: true,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                        fillColor: Colors.white,
                                        filled: true,
                                      ),
                                      items: allowedModes.map((mode) {
                                        return DropdownMenuItem<String>(
                                          value: mode,
                                          child: Text(mode, style: const TextStyle(fontSize: 12.5)),
                                        );
                                      }).toList(),
                                      onChanged: (newMode) {
                                        if (newMode != null) {
                                          setState(() {
                                            draft.inputMode = newMode;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Quantity input
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: draft.quantityController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        hintText: 'Qty',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                        fillColor: Colors.white,
                                        filled: true,
                                      ),
                                      onChanged: (val) {
                                        setState(() {}); // Trigger preview recalculation
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),

                                  // Delete button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFF991B1B)),
                                    onPressed: _productDrafts.length > 1
                                        ? () => _removeProductRow(idx)
                                        : null,
                                  ),
                                ],
                              ),

                              // Real-time automatic conversion preview line
                              if (calcResult != null && selectedProduct != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.sync_alt, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Conversion: ${calcResult.crates == calcResult.crates.roundToDouble() ? calcResult.crates.toInt() : Formatters.formatSmart(calcResult.crates)} Crates • ${calcResult.pieces} Pieces • ${Formatters.formatSmart(calcResult.totalQuantity)} ${selectedProduct.baseUnitLabel == "Litres" ? "L" : "kg"}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Live Vehicle Summary Strip & Action Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                  border: Border(top: BorderSide(color: AppColors.cardBorder)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Live calculation summary
                    Wrap(
                      spacing: 16,
                      children: [
                        Text(
                          'Crates: ${Formatters.formatSmart(liveCrates)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        Text(
                          'Pieces: $livePieces',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        if (liveLitres > 0)
                          Text(
                            'Liquid: ${Formatters.formatSmart(liveLitres)} L',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        if (liveKg > 0)
                          Text(
                            'Curd: ${Formatters.formatSmart(liveKg)} kg',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFFD97706),
                            ),
                          ),
                      ],
                    ),

                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _submit,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            widget.existing != null ? 'Update Dispatch' : 'Save Vehicle Dispatch',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// VEHICLE DETAIL MODAL
// =============================================================================

class _VehicleDetailDialog extends StatelessWidget {
  final VehicleDispatch dispatch;

  const _VehicleDetailDialog({required this.dispatch});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Padding(
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          dispatch.vehicleNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        dispatch.distributorName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
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
              const SizedBox(height: 12),

              Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  _infoPair('Date', dispatch.dispatchDate),
                  _infoPair('Time', dispatch.dispatchTime),
                  if (dispatch.driverName.isNotEmpty)
                    _infoPair('Driver', dispatch.driverName),
                  if (dispatch.route.isNotEmpty)
                    _infoPair('Route', dispatch.route),
                  _infoPair('Officer', dispatch.createdBy),
                ],
              ),
              if (dispatch.remarks.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.note_alt_outlined, size: 16, color: Color(0xFF991B1B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: ${dispatch.remarks}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              const Text(
                'DISPATCHED PRODUCTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              Table(
                border: TableBorder(
                  horizontalInside: BorderSide(color: Colors.grey.shade200),
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade100),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Product', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Input', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Crates', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Pieces', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Quantity', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ],
                  ),
                  ...dispatch.items.map((i) {
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Text(i.productName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Text('${Formatters.formatSmart(i.inputQuantity)} ${i.inputMode}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Text(i.formattedCrates, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Text('${i.pieces}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Text(i.formattedQuantityWithUnit, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Vehicle Totals:', style: TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                      '${Formatters.formatSmart(dispatch.totalCrates)} Crates • ${dispatch.totalPieces} Pieces • ${Formatters.formatSmart(dispatch.totalLitres)} L • ${Formatters.formatSmart(dispatch.totalKg)} kg',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoPair(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
