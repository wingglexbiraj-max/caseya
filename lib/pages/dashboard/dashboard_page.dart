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
          horizontal: isMobile ? 14 : 28,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant Welcome Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder, width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${user.name}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Role: ${user.role}  •  Department: ${user.department}  •  Operational Log Date: ${Formatters.formatDate(DateTime.now())}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile)
                    StatusBadge.success('Facility Online', icon: Icons.sensors),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Action Buttons
            Text(
              'OPERATIONAL SHORTCUTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _buildQuickAction(
                  icon: Icons.calculate_outlined,
                  label: 'Product Calculator',
                  onTap: () => onNavigate(1),
                ),
                _buildQuickAction(
                  icon: Icons.water_drop_outlined,
                  label: 'Milk Standardization',
                  onTap: () => onNavigate(2),
                ),
                _buildQuickAction(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Record Boiler Fuel',
                  onTap: () => onNavigate(3),
                ),
                _buildQuickAction(
                  icon: Icons.bar_chart_outlined,
                  label: 'View Daily Reports',
                  onTap: () => onNavigate(8),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Key Plant Metrics Grid
            Text(
              'TODAY\'S PLANT METRICS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 600
                    ? 1
                    : (constraints.maxWidth < 950 ? 2 : 4);
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
                        subtitle: 'Pasteurized & Packed',
                        icon: Icons.factory_outlined,
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
                        subtitle: '8 Routes Dispatched',
                        icon: Icons.local_shipping_outlined,
                        iconColor: const Color(0xFF7C3AED),
                        iconBgColor: AppColors.metricBgDispatch,
                        onTap: () => onNavigate(5),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Current Cold Stock',
                        value: Formatters.formatSmart(state.currentStockLitres),
                        unit: 'Litres',
                        subtitle: 'Finished Goods Inventory',
                        icon: Icons.warehouse_outlined,
                        iconColor: const Color(0xFF2563EB),
                        iconBgColor: AppColors.metricBgStock,
                        onTap: () => onNavigate(7),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        title: 'Boiler Fuel Burn',
                        value: Formatters.formatSmart(state.todayBoilerConsumptionLitres),
                        unit: 'Litres',
                        subtitle: 'Calibrated shift burn',
                        icon: Icons.local_fire_department_outlined,
                        iconColor: const Color(0xFFD97706),
                        iconBgColor: AppColors.metricBgBoiler,
                        onTap: () => onNavigate(3),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Recent Activities Timeline Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(
                        child: Text(
                          'RECENT ACTIVITIES & TRANSACTIONS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      StatusBadge(
                        text: 'Live Shift Feed',
                        backgroundColor: Color(0xFFF1F5F3),
                        textColor: AppColors.primaryDark,
                      ),
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
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Text(
                                act.time,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
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
                                  const SizedBox(height: 2),
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
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryDark,
        side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      onPressed: onTap,
    );
  }
}
