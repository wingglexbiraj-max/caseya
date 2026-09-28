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

class DashboardPage extends ConsumerWidget {
  final void Function(int) onNavigate;

  const DashboardPage({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final user = ref.watch(authProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'PLANT CONTROL CENTER',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AppColors.goldAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFDE68A),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Welcome back, ${user.name}',
                          style: const TextStyle(
                            fontSize: 22, // Golden ratio subheadline
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Operations Active • ${user.department} • Shift Schedule: Standard 24h Plant Cycle',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFBAE6FD),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF38BDF8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Sensors Synchronized',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Key Plant Metrics Grid (Golden Ratio Proportions)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TODAY\'S METRIC SUMMARY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  Formatters.formatDate(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 12,
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
                        onTap: () => onNavigate(4),
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
                        iconColor: const Color(0xFF7C3AED),
                        iconBgColor: AppColors.metricBgDispatch,
                        onTap: () => onNavigate(6),
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
                        onTap: () => onNavigate(8),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Boiler Fuel Burned',
                        value: Formatters.formatSmart(state.todayBoilerConsumptionLitres),
                        unit: 'Litres',
                        subtitle: 'Formula: ((Diff × 900) ÷ 70)',
                        icon: Icons.local_fire_department_rounded,
                        iconColor: AppColors.goldAccent,
                        iconBgColor: AppColors.metricBgBoiler,
                        onTap: () => onNavigate(3),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Golden Ratio Split: 61.8% Recent Activities vs 38.2% Quick Actions & Plant Status
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
                                            fontSize: 12,
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
                              separatorBuilder: (_, __) => const Divider(height: 1),
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
                                            fontSize: 11.5,
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
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              act.subtitle,
                                              style: const TextStyle(
                                                fontSize: 12,
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
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.1,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _buildEngineShortcut(
                                    icon: Icons.calculate_rounded,
                                    title: 'Product Calculator',
                                    subtitle: 'Convert Pieces, Crates & Litres',
                                    badge: 'Phase 1 Core',
                                    onTap: () => onNavigate(1),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildEngineShortcut(
                                    icon: Icons.water_drop_rounded,
                                    title: 'Milk Standardization',
                                    subtitle: 'Mass Balance & Lab Testing',
                                    badge: 'Phase 1 Core',
                                    onTap: () => onNavigate(2),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildEngineShortcut(
                                    icon: Icons.local_fire_department_rounded,
                                    title: 'Boiler Fuel Burn',
                                    subtitle: 'Level Calibration Engine',
                                    badge: 'Phase 1 Core',
                                    onTap: () => onNavigate(3),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildEngineShortcut(
                                    icon: Icons.blender_rounded,
                                    title: 'Daily Batch Making',
                                    subtitle: 'Recipe Formulation & Ingredients',
                                    badge: 'Daily Module',
                                    onTap: () => onNavigate(5),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildEngineShortcut(
                                    icon: Icons.insights_rounded,
                                    title: 'Daily Shift Reports',
                                    subtitle: 'Export CSV & Printable Log',
                                    badge: 'Analytics',
                                    onTap: () => onNavigate(9),
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
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    _buildEngineShortcut(
                      icon: Icons.calculate_rounded,
                      title: 'Product Calculator',
                      subtitle: 'Convert Pieces, Crates & Litres',
                      badge: 'Phase 1',
                      onTap: () => onNavigate(1),
                    ),
                    const SizedBox(height: 10),
                    _buildEngineShortcut(
                      icon: Icons.water_drop_rounded,
                      title: 'Milk Standardization',
                      subtitle: 'Mass Balance & Lab Testing',
                      badge: 'Phase 1',
                      onTap: () => onNavigate(2),
                    ),
                    const SizedBox(height: 10),
                    _buildEngineShortcut(
                      icon: Icons.local_fire_department_rounded,
                      title: 'Boiler Fuel Burn',
                      subtitle: 'Level Calibration Engine',
                      badge: 'Phase 1',
                      onTap: () => onNavigate(3),
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
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
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
