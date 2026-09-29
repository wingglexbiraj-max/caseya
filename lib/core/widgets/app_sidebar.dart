import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../utils/formatters.dart';

class SidebarItem {
  final int index;
  final String title;
  final IconData icon;
  final String? badge;

  const SidebarItem({
    required this.index,
    required this.title,
    required this.icon,
    this.badge,
  });
}

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onItemSelected;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const List<SidebarItem> primaryItems = [
    SidebarItem(index: 0, title: 'Dashboard', icon: Icons.grid_view_rounded),
    SidebarItem(index: 1, title: 'Product Calculator', icon: Icons.calculate_rounded),
    SidebarItem(index: 2, title: 'Milk Standardization', icon: Icons.water_drop_rounded),
    SidebarItem(index: 3, title: 'Boiler Fuel', icon: Icons.local_fire_department_rounded),
    SidebarItem(index: 4, title: 'DG HSD Fuel', icon: Icons.electric_bolt_rounded),
  ];

  static const List<SidebarItem> operationsItems = [
    SidebarItem(index: 5, title: 'Production Register', icon: Icons.precision_manufacturing_rounded),
    SidebarItem(index: 6, title: 'Daily Batch Making', icon: Icons.blender_rounded),
    SidebarItem(index: 7, title: 'Dispatch Logistics', icon: Icons.local_shipping_rounded),
    SidebarItem(index: 8, title: 'Packaging Tracker', icon: Icons.all_inbox_rounded),
    SidebarItem(index: 9, title: 'Stock & Inventory', icon: Icons.warehouse_rounded),
    SidebarItem(index: 10, title: 'Reports & Export', icon: Icons.insights_rounded),
  ];

  static const List<SidebarItem> adminItems = [
    SidebarItem(index: 11, title: 'Products Master', icon: Icons.tune_rounded),
    SidebarItem(index: 12, title: 'Settings & Config', icon: Icons.settings_suggest_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 258,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
      ),
      child: Column(
        children: [
          // Brand Header with Deep Welcome Card Navy Blue Background
          Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: AppColors.brandHeaderBackground,
              gradient: AppColors.brandHeaderGradient,
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFF1E3A8A),
                  width: 1.2,
                ),
                right: BorderSide(
                  color: Color(0xFF1E3A8A),
                  width: 1.2,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.cyanGradient,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'C',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Menu Navigation List (Clean without section headings)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
              children: [
                ...primaryItems.map((item) => _buildNavItem(item)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Divider(height: 1, color: AppColors.divider),
                ),
                ...operationsItems.map((item) => _buildNavItem(item)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Divider(height: 1, color: AppColors.divider),
                ),
                ...adminItems.map((item) => _buildNavItem(item)),
              ],
            ),
          ),

          // Plant Facility Active Chip with Real-time Clock & Date
          const _LivePlantSidebarChip(),
        ],
      ),
    );
  }

  Widget _buildNavItem(SidebarItem item) {
    final isSelected = selectedIndex == item.index;

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
          leading: Icon(
            item.icon,
            size: 20,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
          trailing: isSelected
              ? Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              : null,
          onTap: () => onItemSelected(item.index),
        ),
      ),
    );
  }
}

class _LivePlantSidebarChip extends StatefulWidget {
  const _LivePlantSidebarChip();

  @override
  State<_LivePlantSidebarChip> createState() => _LivePlantSidebarChipState();
}

class _LivePlantSidebarChipState extends State<_LivePlantSidebarChip> {
  late DateTime _currentTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = Formatters.formatTimeWithSeconds(_currentTime);
    final dateStr = Formatters.formatDate(_currentTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      margin: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: AppColors.goldAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldAccent.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Plant Facility Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$timeStr • $dateStr',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
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
