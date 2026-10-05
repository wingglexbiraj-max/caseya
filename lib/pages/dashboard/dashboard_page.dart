import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/app_card.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  final void Function(int) onNavigate;

  const DashboardPage({
    super.key,
    required this.onNavigate,
  });

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String _selectedCategory = 'All';
  bool _isFinishedGoodsExpanded = false;

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning and';
    } else if (hour < 17) {
      return 'Good afternoon and';
    } else {
      return 'Good evening and';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final user = ref.watch(authProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

    final milkCount = state.productTotals.where((p) =>
        (p.category == 'Milk' ||
            p.shortCode.contains('STD') ||
            p.shortCode.contains('SM+')) &&
        !p.shortCode.toLowerCase().contains('lassi') &&
        p.category != 'Fermented').length;
    final lassiCount = state.productTotals.where((p) =>
        p.category == 'Fermented' ||
        p.shortCode.toLowerCase().contains('lassi') ||
        p.productName.toLowerCase().contains('lassi')).length;
    final curdCupsCount = state.productTotals.where((p) =>
        (p.shortCode.startsWith('S') || p.shortCode.startsWith('P')) &&
        !p.shortCode.contains('CP')).length;
    final curdPouchesCount = state.productTotals.where((p) =>
        p.shortCode.contains('CP')).length;

    // Filter products for the Finished Goods Production breakdown
    final filteredProducts = state.productTotals.where((p) {
      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Milk') {
        return (p.category == 'Milk' ||
                p.shortCode.contains('STD') ||
                p.shortCode.contains('SM+')) &&
            !p.shortCode.toLowerCase().contains('lassi') &&
            p.category != 'Fermented';
      }
      if (_selectedCategory == 'Lassi') {
        return p.category == 'Fermented' ||
            p.shortCode.toLowerCase().contains('lassi') ||
            p.productName.toLowerCase().contains('lassi');
      }
      if (_selectedCategory == 'Curd Cups') {
        return (p.shortCode.startsWith('S') || p.shortCode.startsWith('P')) &&
            !p.shortCode.contains('CP');
      }
      if (_selectedCategory == 'Curd Pouches') {
        return p.shortCode.contains('CP');
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 28,
          vertical: 22,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant Welcome Banner with Golden Ratio Padding
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
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
                  Text(
                    _getTimeGreeting(),
                    style: const TextStyle(
                      fontSize: AppTextSizes.body,
                      fontWeight: AppFontWeights.semiBold,
                      letterSpacing: 0.5,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Welcome, ${user.name}',
                    style: const TextStyle(
                      fontSize: AppTextSizes.heading,
                      fontWeight: AppFontWeights.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 15,
                        color: Color(0xFF38BDF8),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'at Purabi Dairy (NEDFL), Silchar Branch',
                        style: TextStyle(
                          fontSize: AppTextSizes.body,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: AppFontWeights.medium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // =================================================================
            // 1. TOTAL METRIC SUMMARY (All Dates Till Now - Lifetime Cumulative)
            // Exactly matches Today's Metric Summary design
            // =================================================================
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
                        Icons.analytics_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'TOTAL METRIC SUMMARY',
                      style: TextStyle(
                        fontSize: AppTextSizes.subheading,
                        fontWeight: AppFontWeights.bold,
                        letterSpacing: 0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'All Dates Till Now',
                  style: TextStyle(
                    fontSize: AppTextSizes.caption,
                    fontWeight: AppFontWeights.medium,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 600
                    ? 1
                    : (constraints.maxWidth < 1000
                        ? 2
                        : (constraints.maxWidth < 1400 ? 3 : 6));
                final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 16)) / crossAxisCount;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Total Production',
                        value: Formatters.formatSmart(state.totalProductionLitres),
                        unit: 'Litres',
                        subtitle: 'Milk in L (All Dates)',
                        icon: Icons.precision_manufacturing_rounded,
                        iconColor: Colors.black.withValues(alpha: 0.60),
                        iconBgColor: Colors.black.withValues(alpha: 0.06),
                        cardBgColor: const Color(0xFFEFF6FF),
                        onTap: () => widget.onNavigate(6),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Total SMP Used',
                        value: Formatters.formatSmart(state.totalSmpUsedKg),
                        unit: 'Kg',
                        subtitle: 'Skimmed Milk Powder',
                        icon: Icons.grain_rounded,
                        iconColor: Colors.black.withValues(alpha: 0.60),
                        iconBgColor: Colors.black.withValues(alpha: 0.06),
                        cardBgColor: const Color(0xFFFFFBEB),
                        onTap: () => widget.onNavigate(3),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Total Sugar Used',
                        value: Formatters.formatSmart(state.totalSugarUsedKg),
                        unit: 'Kg',
                        subtitle: 'All Formulations',
                        icon: Icons.cookie_outlined,
                        iconColor: Colors.black.withValues(alpha: 0.60),
                        iconBgColor: Colors.black.withValues(alpha: 0.06),
                        cardBgColor: const Color(0xFFECFDF5),
                        onTap: () => widget.onNavigate(3),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Total Water Used',
                        value: Formatters.formatSmart(state.totalWaterUsedLitres),
                        unit: 'Litres',
                        subtitle: 'Standardization Water',
                        icon: Icons.water_drop_rounded,
                        iconColor: Colors.black.withValues(alpha: 0.60),
                        iconBgColor: Colors.black.withValues(alpha: 0.06),
                        cardBgColor: const Color(0xFFF5F3FF),
                        onTap: () => widget.onNavigate(3),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Total Boiler Fuel',
                        value: Formatters.formatSmart(state.totalBoilerFuelBurnedLitres),
                        unit: 'Litres',
                        subtitle: 'Furnace Fuel Burned',
                        icon: Icons.local_fire_department_rounded,
                        iconColor: Colors.black.withValues(alpha: 0.60),
                        iconBgColor: Colors.black.withValues(alpha: 0.06),
                        cardBgColor: const Color(0xFFEFF6FF),
                        onTap: () => widget.onNavigate(4),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Total DG Fuel Consumed',
                        value: Formatters.formatSmart(state.totalDgFuelConsumptionLitres),
                        unit: 'Litres',
                        subtitle: 'Generator HSD Fuel',
                        icon: Icons.bolt_rounded,
                        iconColor: Colors.black.withValues(alpha: 0.60),
                        iconBgColor: Colors.black.withValues(alpha: 0.06),
                        cardBgColor: const Color(0xFFFFFBEB),
                        onTap: () => widget.onNavigate(5),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // =================================================================
            // 2. TODAY'S METRIC SUMMARY
            // =================================================================
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
                        Icons.today_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'TODAY\'S METRIC SUMMARY',
                      style: TextStyle(
                        fontSize: AppTextSizes.subheading,
                        fontWeight: AppFontWeights.bold,
                        letterSpacing: 0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  Formatters.formatDate(DateTime.now()),
                  style: const TextStyle(
                    fontSize: AppTextSizes.caption,
                    fontWeight: AppFontWeights.medium,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 600
                    ? 1
                    : (constraints.maxWidth < 1000 ? 2 : 4);
                final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 16)) / crossAxisCount;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Today\'s Production',
                        value: Formatters.formatSmart(state.todayProductionLitres),
                        unit: 'Litres',
                        subtitle: 'Pasteurized & Finished',
                        icon: Icons.precision_manufacturing_rounded,
                        iconColor: Colors.black.withValues(alpha: 0.60),
                        iconBgColor: Colors.black.withValues(alpha: 0.06),
                        cardBgColor: const Color(0xFFEFF6FF),
                        onTap: () => widget.onNavigate(6),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Today\'s Dispatch',
                        value: Formatters.formatSmart(state.todayDispatchLitres),
                        unit: 'Litres',
                        subtitle: '8 Routes On Route',
                        icon: Icons.local_shipping_rounded,
                        iconColor: Colors.black.withValues(alpha: 0.60),
                        iconBgColor: Colors.black.withValues(alpha: 0.06),
                        cardBgColor: const Color(0xFFFFFBEB),
                        onTap: () => widget.onNavigate(8),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Inventory Stocks',
                        value: Formatters.formatSmart(state.currentStockLitres),
                        unit: 'Litres',
                        subtitle: 'Finished Goods Inventory',
                        icon: Icons.warehouse_rounded,
                        iconColor: Colors.black.withValues(alpha: 0.60),
                        iconBgColor: Colors.black.withValues(alpha: 0.06),
                        cardBgColor: const Color(0xFFECFDF5),
                        onTap: () => widget.onNavigate(9),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Milk Stock',
                        value: Formatters.formatSmart(state.todayMilkStockLitres),
                        unit: 'Litres',
                        subtitle: state.milkStockTanksDescription,
                        icon: Icons.water_drop_rounded,
                        iconColor: Colors.black.withValues(alpha: 0.60),
                        iconBgColor: Colors.black.withValues(alpha: 0.06),
                        cardBgColor: const Color(0xFFF5F3FF),
                        onTap: () => widget.onNavigate(1),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // =================================================================
            // 3. FINISHED GOODS PRODUCTION (Separate in Collapsible Format)
            // =================================================================
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Collapsible Header (tappable)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        _isFinishedGoodsExpanded = !_isFinishedGoodsExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inventory_2_rounded,
                              size: 20,
                              color: Colors.black.withValues(alpha: 0.60),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FINISHED GOODS PRODUCTION',
                                  style: TextStyle(
                                    fontSize: AppTextSizes.subheading,
                                    fontWeight: AppFontWeights.bold,
                                    letterSpacing: 0.2,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'All-Time Cumulative',
                                  style: TextStyle(
                                    fontSize: AppTextSizes.caption,
                                    color: AppColors.textMuted,
                                    fontWeight: AppFontWeights.medium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.08),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '14 Products',
                              style: TextStyle(
                                fontSize: AppTextSizes.caption,
                                fontWeight: AppFontWeights.bold,
                                color: Colors.black.withValues(alpha: 0.70),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _isFinishedGoodsExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Collapsible Content
                  if (_isFinishedGoodsExpanded) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryFilterChip('All', 'All (${state.productTotals.length})'),
                          const SizedBox(width: 8),
                          _buildCategoryFilterChip('Milk', 'Milk ($milkCount)'),
                          const SizedBox(width: 8),
                          _buildCategoryFilterChip('Lassi', 'Lassi ($lassiCount)'),
                          const SizedBox(width: 8),
                          _buildCategoryFilterChip('Curd Cups', 'Curd Cups ($curdCupsCount)'),
                          const SizedBox(width: 8),
                          _buildCategoryFilterChip('Curd Pouches', 'Curd Pouches ($curdPouchesCount)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 14 Products Responsive Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final int crossAxisCount = width < 550
                            ? 1
                            : (width < 850 ? 2 : (width < 1200 ? 3 : 4));
                        final itemWidth = (width - ((crossAxisCount - 1) * 12)) / crossAxisCount;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: filteredProducts.map((p) {
                            return _buildProductCard(p, itemWidth, () => widget.onNavigate(6));
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // =================================================================
            // 4. QUICK ENGINES
            // =================================================================
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.apps_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'QUICK ENGINES',
                  style: TextStyle(
                    fontSize: AppTextSizes.subheading,
                    fontWeight: AppFontWeights.bold,
                    letterSpacing: 0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 600
                    ? 1
                    : (constraints.maxWidth < 1000 ? 2 : 4);
                final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 14)) / crossAxisCount;

                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _buildEngineShortcut(
                        icon: Icons.science_rounded,
                        title: 'Lab Fat & SNF',
                        subtitle: 'Milk Silo Tank Testing',
                        badge: 'Quality Core',
                        onTap: () => widget.onNavigate(1),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildEngineShortcut(
                        icon: Icons.calculate_rounded,
                        title: 'Product Calculator',
                        subtitle: 'Convert Pieces, Crates & Litres',
                        badge: 'Phase 1 Core',
                        onTap: () => widget.onNavigate(2),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildEngineShortcut(
                        icon: Icons.water_drop_rounded,
                        title: 'Milk Standardization',
                        subtitle: 'Mass Balance & Lab Testing',
                        badge: 'Phase 1 Core',
                        onTap: () => widget.onNavigate(3),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildEngineShortcut(
                        icon: Icons.local_fire_department_rounded,
                        title: 'Boiler Fuel Burn',
                        subtitle: 'Level Calibration Engine',
                        badge: 'Plant Energy',
                        onTap: () => widget.onNavigate(4),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildEngineShortcut(
                        icon: Icons.electric_bolt_rounded,
                        title: 'DG HSD Fuel & Energy',
                        subtitle: 'Fuel Consumption & Yield (kWh/L)',
                        badge: 'Generator',
                        onTap: () => widget.onNavigate(5),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildEngineShortcut(
                        icon: Icons.precision_manufacturing_rounded,
                        title: 'Production Register',
                        subtitle: 'Finished Packaging Entries',
                        badge: 'Production',
                        onTap: () => widget.onNavigate(6),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildEngineShortcut(
                        icon: Icons.blender_rounded,
                        title: 'Daily Batch Making',
                        subtitle: 'Recipe Formulation & Ingredients',
                        badge: 'Daily Module',
                        onTap: () => widget.onNavigate(7),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildEngineShortcut(
                        icon: Icons.insights_rounded,
                        title: 'Daily Shift Reports',
                        subtitle: 'Export CSV & Printable Log',
                        badge: 'Analytics',
                        onTap: () => widget.onNavigate(10),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilterChip(String categoryKey, String label) {
    return _CategoryFilterChip(
      categoryKey: categoryKey,
      label: label,
      isSelected: _selectedCategory == categoryKey,
      onTap: () => setState(() => _selectedCategory = categoryKey),
    );
  }

  Widget _buildProductCard(ProductTotalMetric p, double width, VoidCallback onTap) {
    return _DashboardProductCard(
      product: p,
      width: width,
      onTap: onTap,
    );
  }

  Widget _buildEngineShortcut({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorderSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 19, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: AppTextSizes.body, color: AppColors.textPrimary),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatefulWidget {
  final String categoryKey;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryFilterChip({
    required this.categoryKey,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryFilterChip> createState() => _CategoryFilterChipState();
}

class _CategoryFilterChipState extends State<_CategoryFilterChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppColors.primary
              : (_isHovered ? const Color(0xFFF1F5F9) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isSelected
                ? AppColors.primary
                : (_isHovered
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.cardBorder),
            width: 1.2,
          ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : (_isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: AppTextSizes.caption,
                  fontWeight: AppFontWeights.bold,
                  color: widget.isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardProductCard extends StatefulWidget {
  final ProductTotalMetric product;
  final double width;
  final VoidCallback onTap;

  const _DashboardProductCard({
    required this.product,
    required this.width,
    required this.onTap,
  });

  @override
  State<_DashboardProductCard> createState() => _DashboardProductCardState();
}

class _DashboardProductCardState extends State<_DashboardProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final isLassi = p.category == 'Fermented' ||
        p.shortCode.toLowerCase().contains('lassi') ||
        p.productName.toLowerCase().contains('lassi');
    final isMilk = !isLassi &&
        (p.category == 'Milk' ||
            p.shortCode.contains('STD') ||
            p.shortCode.contains('SM+'));

    // Distinct 4 card chip backgrounds matching Total Metric Summary
    final Color cardBg;
    final Color accentColor;

    if (isMilk) {
      cardBg = const Color(0xFFEFF6FF); // Soft Blue
      accentColor = const Color(0xFF0284C7);
    } else if (isLassi) {
      cardBg = const Color(0xFFF5F3FF); // Soft Purple
      accentColor = const Color(0xFF7C3AED);
    } else if (p.shortCode.startsWith('S')) {
      cardBg = const Color(0xFFFFFBEB); // Soft Amber
      accentColor = const Color(0xFFD97706);
    } else {
      cardBg = const Color(0xFFECFDF5); // Soft Emerald
      accentColor = const Color(0xFF059669);
    }

    // On cursor hover, smoothly blink/brighten the full chip background
    final effectiveBg = _isHovered
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.60), cardBg)
        : cardBg;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: widget.width,
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isHovered
                ? accentColor.withValues(alpha: 0.55)
                : Colors.black.withValues(alpha: 0.08),
            width: _isHovered ? 1.4 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? accentColor.withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: _isHovered ? 10 : 4,
              offset: _isHovered ? const Offset(0, 3) : const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            hoverColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          p.shortCode,
                          style: TextStyle(
                            fontSize: AppTextSizes.caption,
                            fontWeight: AppFontWeights.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                      Text(
                        p.packSizeDisplay,
                        style: const TextStyle(
                          fontSize: AppTextSizes.caption,
                          fontWeight: AppFontWeights.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.productName,
                    style: const TextStyle(
                      fontSize: AppTextSizes.body,
                      fontWeight: AppFontWeights.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        Formatters.formatSmart(p.totalQuantity),
                        style: TextStyle(
                          fontSize: AppTextSizes.subheading,
                          fontWeight: AppFontWeights.bold,
                          color: accentColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.unit,
                        style: const TextStyle(
                          fontSize: AppTextSizes.caption,
                          fontWeight: AppFontWeights.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.formatInt(p.totalPieces)} pcs  •  ${Formatters.formatSmart(p.totalCrates)} crates',
                    style: const TextStyle(
                      fontSize: AppTextSizes.caption,
                      fontWeight: AppFontWeights.semiBold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
