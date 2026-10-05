import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
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

    // Filter products for the Finished Goods Production breakdown
    final filteredProducts = state.productTotals.where((p) {
      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Milk & Lassi') {
        return p.category == 'Milk' || p.category == 'Fermented' || p.shortCode.contains('STD') || p.shortCode.contains('SM+') || p.shortCode.contains('Lassi');
      }
      if (_selectedCategory == 'Curd Cups') {
        return (p.shortCode.startsWith('S') || p.shortCode.startsWith('P')) && !p.shortCode.contains('CP');
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
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Welcome, ${user.name}',
                    style: const TextStyle(
                      fontSize: AppTextSizes.heading,
                      fontWeight: FontWeight.w900,
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
                          fontWeight: FontWeight.w500,
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
            // =================================================================
            AppCard(
              topBorderColor: AppColors.primary,
              topBorderHeight: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Row(
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
                              Icons.analytics_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL METRIC SUMMARY',
                                style: TextStyle(
                                  fontSize: AppTextSizes.subheading,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'All dates till now • Cumulative Plant Metrics',
                                style: TextStyle(
                                  fontSize: AppTextSizes.caption,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.all_inclusive_rounded, size: 14, color: AppColors.primary),
                            SizedBox(width: 5),
                            Text(
                              'All-Time Total',
                              style: TextStyle(
                                fontSize: AppTextSizes.caption,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Core Resource & Operations Grid (6 Metrics)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final int crossAxisCount = width < 600
                          ? 1
                          : (width < 900 ? 2 : (width < 1250 ? 3 : 6));
                      final itemWidth = (width - ((crossAxisCount - 1) * 12)) / crossAxisCount;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildTotalMetricCard(
                            width: itemWidth,
                            title: 'Total Production',
                            value: Formatters.formatSmart(state.totalProductionLitres),
                            unit: 'Litres',
                            subtitle: 'Milk in L (All Dates)',
                            icon: Icons.water_drop_rounded,
                            iconColor: AppColors.primary,
                            bgColor: const Color(0xFFEFF6FF),
                            borderColor: const Color(0xFFBFDBFE),
                            onTap: () => widget.onNavigate(6),
                          ),
                          _buildTotalMetricCard(
                            width: itemWidth,
                            title: 'Total SMP Used',
                            value: Formatters.formatSmart(state.totalSmpUsedKg),
                            unit: 'Kg',
                            subtitle: 'Skimmed Milk Powder',
                            icon: Icons.grain_rounded,
                            iconColor: const Color(0xFFD97706),
                            bgColor: const Color(0xFFFFFBEB),
                            borderColor: const Color(0xFFFDE68A),
                            onTap: () => widget.onNavigate(3),
                          ),
                          _buildTotalMetricCard(
                            width: itemWidth,
                            title: 'Total Sugar Used',
                            value: Formatters.formatSmart(state.totalSugarUsedKg),
                            unit: 'Kg',
                            subtitle: 'Sweetened Batches',
                            icon: Icons.cookie_outlined,
                            iconColor: const Color(0xFFE11D48),
                            bgColor: const Color(0xFFFFF1F2),
                            borderColor: const Color(0xFFFECDD3),
                            onTap: () => widget.onNavigate(3),
                          ),
                          _buildTotalMetricCard(
                            width: itemWidth,
                            title: 'Total Water Used',
                            value: Formatters.formatSmart(state.totalWaterUsedLitres),
                            unit: 'Litres',
                            subtitle: 'Standardization Blend',
                            icon: Icons.opacity_rounded,
                            iconColor: const Color(0xFF0284C7),
                            bgColor: const Color(0xFFF0F9FF),
                            borderColor: const Color(0xFFBAE6FD),
                            onTap: () => widget.onNavigate(3),
                          ),
                          _buildTotalMetricCard(
                            width: itemWidth,
                            title: 'Boiler Fuel Burned',
                            value: Formatters.formatSmart(state.totalBoilerFuelBurnedLitres),
                            unit: 'Litres',
                            subtitle: 'Boiler HSD Log',
                            icon: Icons.local_fire_department_rounded,
                            iconColor: const Color(0xFFEA580C),
                            bgColor: const Color(0xFFFFF7ED),
                            borderColor: const Color(0xFFFED7AA),
                            onTap: () => widget.onNavigate(4),
                          ),
                          _buildTotalMetricCard(
                            width: itemWidth,
                            title: 'DG Fuel Consumed',
                            value: Formatters.formatSmart(state.totalDgFuelConsumptionLitres),
                            unit: 'Litres',
                            subtitle: 'Generator HSD Log',
                            icon: Icons.electric_bolt_rounded,
                            iconColor: const Color(0xFF059669),
                            bgColor: const Color(0xFFECFDF5),
                            borderColor: const Color(0xFFA7F3D0),
                            onTap: () => widget.onNavigate(5),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // -----------------------------------------------------------
                  // Product-Wise Finished Goods Production (14 Products)
                  // -----------------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'FINISHED GOODS PRODUCTION BY PRODUCT (ALL DATES)',
                            style: TextStyle(
                              fontSize: AppTextSizes.caption,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.9,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${state.productTotals.length} Products Tracked',
                        style: const TextStyle(
                          fontSize: AppTextSizes.caption,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryFilterChip('All', 'All (${state.productTotals.length})'),
                        const SizedBox(width: 8),
                        _buildCategoryFilterChip('Milk & Lassi', 'Milk & Lassi (4)'),
                        const SizedBox(width: 8),
                        _buildCategoryFilterChip('Curd Cups', 'Curd Cups (6)'),
                        const SizedBox(width: 8),
                        _buildCategoryFilterChip('Curd Pouches', 'Curd Pouches (4)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

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
              ),
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.today_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'TODAY\'S METRIC SUMMARY',
                      style: TextStyle(
                        fontSize: AppTextSizes.caption,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  Formatters.formatDate(DateTime.now()),
                  style: const TextStyle(
                    fontSize: AppTextSizes.caption,
                    fontWeight: FontWeight.w600,
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
                        iconColor: AppColors.primary,
                        iconBgColor: AppColors.metricBgMilk,
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
                        iconColor: AppColors.goldAccent,
                        iconBgColor: AppColors.metricBgDispatch,
                        onTap: () => widget.onNavigate(8),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Cold Room Stock',
                        value: Formatters.formatSmart(state.currentStockLitres),
                        unit: 'Litres',
                        subtitle: 'Finished Goods Inventory',
                        icon: Icons.ac_unit_rounded,
                        iconColor: AppColors.coolIce,
                        iconBgColor: AppColors.metricBgStock,
                        onTap: () => widget.onNavigate(9),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Boiler Fuel Burned',
                        value: Formatters.formatSmart(state.todayBoilerConsumptionLitres),
                        unit: 'Litres',
                        subtitle: 'Today\'s Boiler Log',
                        icon: Icons.local_fire_department_rounded,
                        iconColor: AppColors.goldAccent,
                        iconBgColor: AppColors.metricBgBoiler,
                        onTap: () => widget.onNavigate(4),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // =================================================================
            // 3. RECENT ACTIVITIES & QUICK ENGINES
            // =================================================================
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 950;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Recent Activities Timeline (Flex 62 ~ Golden Ratio)
                    Expanded(
                      flex: isWide ? 62 : 100,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
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
                                      const Expanded(
                                        child: Text(
                                          'RECENT PLANT TRANSACTIONS',
                                          style: TextStyle(
                                            fontSize: AppTextSizes.caption,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.1,
                                            color: AppColors.textSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge.success('Live Shift Log', icon: Icons.sensors_rounded),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.recentActivities.length,
                              separatorBuilder: (_, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final act = state.recentActivities[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySurface,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.primaryContainer),
                                        ),
                                        child: Text(
                                          act.time,
                                          style: const TextStyle(
                                            fontSize: AppTextSizes.caption,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              act.title,
                                              style: const TextStyle(
                                                fontSize: AppTextSizes.body,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              act.subtitle,
                                              style: const TextStyle(
                                                fontSize: AppTextSizes.caption,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (isWide) const SizedBox(width: 20),

                    // Right: Quick Actions & Plant Status (Flex 38 ~ Golden Ratio)
                    if (isWide)
                      Expanded(
                        flex: 38,
                        child: Column(
                          children: [
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        'QUICK ENGINES',
                                        style: TextStyle(
                                          fontSize: AppTextSizes.caption,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.1,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _buildEngineShortcut(
                                    icon: Icons.science_rounded,
                                    title: 'Lab Fat & SNF',
                                    subtitle: 'Milk Silo Tank Testing',
                                    badge: 'Quality Core',
                                    onTap: () => widget.onNavigate(1),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildEngineShortcut(
                                    icon: Icons.calculate_rounded,
                                    title: 'Product Calculator',
                                    subtitle: 'Convert Pieces, Crates & Litres',
                                    badge: 'Phase 1 Core',
                                    onTap: () => widget.onNavigate(2),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildEngineShortcut(
                                    icon: Icons.water_drop_rounded,
                                    title: 'Milk Standardization',
                                    subtitle: 'Mass Balance & Lab Testing',
                                    badge: 'Phase 1 Core',
                                    onTap: () => widget.onNavigate(3),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildEngineShortcut(
                                    icon: Icons.local_fire_department_rounded,
                                    title: 'Boiler Fuel Burn',
                                    subtitle: 'Level Calibration Engine',
                                    badge: 'Plant Energy',
                                    onTap: () => widget.onNavigate(4),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildEngineShortcut(
                                    icon: Icons.electric_bolt_rounded,
                                    title: 'DG HSD Fuel & Energy',
                                    subtitle: 'Fuel Consumption & Yield (kWh/L)',
                                    badge: 'Generator',
                                    onTap: () => widget.onNavigate(5),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildEngineShortcut(
                                    icon: Icons.precision_manufacturing_rounded,
                                    title: 'Production Register',
                                    subtitle: 'Finished Packaging Entries',
                                    badge: 'Production',
                                    onTap: () => widget.onNavigate(6),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildEngineShortcut(
                                    icon: Icons.blender_rounded,
                                    title: 'Daily Batch Making',
                                    subtitle: 'Recipe Formulation & Ingredients',
                                    badge: 'Daily Module',
                                    onTap: () => widget.onNavigate(7),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildEngineShortcut(
                                    icon: Icons.insights_rounded,
                                    title: 'Daily Shift Reports',
                                    subtitle: 'Export CSV & Printable Log',
                                    badge: 'Analytics',
                                    onTap: () => widget.onNavigate(10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),

            if (isMobile) ...[
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QUICK ENGINES',
                      style: TextStyle(fontSize: AppTextSizes.caption, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    _buildEngineShortcut(
                      icon: Icons.science_rounded,
                      title: 'Lab Fat & SNF',
                      subtitle: 'Milk Silo Tank Testing',
                      badge: 'Quality Core',
                      onTap: () => widget.onNavigate(1),
                    ),
                    const SizedBox(height: 10),
                    _buildEngineShortcut(
                      icon: Icons.calculate_rounded,
                      title: 'Product Calculator',
                      subtitle: 'Convert Pieces, Crates & Litres',
                      badge: 'Phase 1',
                      onTap: () => widget.onNavigate(2),
                    ),
                    const SizedBox(height: 10),
                    _buildEngineShortcut(
                      icon: Icons.water_drop_rounded,
                      title: 'Milk Standardization',
                      subtitle: 'Mass Balance & Lab Testing',
                      badge: 'Phase 1',
                      onTap: () => widget.onNavigate(3),
                    ),
                    const SizedBox(height: 10),
                    _buildEngineShortcut(
                      icon: Icons.local_fire_department_rounded,
                      title: 'Boiler Fuel Burn',
                      subtitle: 'Level Calibration Engine',
                      badge: 'Phase 1',
                      onTap: () => widget.onNavigate(4),
                    ),
                    const SizedBox(height: 10),
                    _buildEngineShortcut(
                      icon: Icons.electric_bolt_rounded,
                      title: 'DG HSD Fuel & Energy',
                      subtitle: 'Fuel Consumption & Yield',
                      badge: 'Generator',
                      onTap: () => widget.onNavigate(5),
                    ),
                    const SizedBox(height: 10),
                    _buildEngineShortcut(
                      icon: Icons.precision_manufacturing_rounded,
                      title: 'Production Register',
                      subtitle: 'Finished Packaging Entries',
                      badge: 'Production',
                      onTap: () => widget.onNavigate(6),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilterChip(String categoryKey, String label) {
    final isSelected = _selectedCategory == categoryKey;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = categoryKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTextSizes.caption,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalMetricCard({
    required double width,
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const Icon(
                  Icons.arrow_outward_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppTextSizes.caption,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppTextSizes.subheading,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: AppTextSizes.caption,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: AppTextSizes.caption,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductTotalMetric p, double width, VoidCallback onTap) {
    Color accentColor;
    Color bgLight;
    if (p.category == 'Milk') {
      accentColor = AppColors.primary;
      bgLight = const Color(0xFFEFF6FF);
    } else if (p.category == 'Fermented') {
      accentColor = const Color(0xFF7C3AED);
      bgLight = const Color(0xFFF5F3FF);
    } else if (p.shortCode.startsWith('S')) {
      accentColor = const Color(0xFFD97706);
      bgLight = const Color(0xFFFFFBEB);
    } else {
      accentColor = const Color(0xFF059669);
      bgLight = const Color(0xFFECFDF5);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: bgLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    p.shortCode,
                    style: TextStyle(
                      fontSize: AppTextSizes.caption,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                    ),
                  ),
                ),
                Text(
                  p.packSizeDisplay,
                  style: const TextStyle(
                    fontSize: AppTextSizes.caption,
                    fontWeight: FontWeight.w700,
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
                fontWeight: FontWeight.w700,
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
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  p.unit,
                  style: const TextStyle(
                    fontSize: AppTextSizes.caption,
                    fontWeight: FontWeight.w700,
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
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
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
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
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
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: AppTextSizes.body, color: AppColors.textPrimary),
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
