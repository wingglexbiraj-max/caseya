import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

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
  ];

  static const List<SidebarItem> operationsItems = [
    SidebarItem(index: 4, title: 'Production Register', icon: Icons.precision_manufacturing_rounded),
    SidebarItem(index: 5, title: 'Daily Batch Making', icon: Icons.blender_rounded),
    SidebarItem(index: 6, title: 'Dispatch Logistics', icon: Icons.local_shipping_rounded),
    SidebarItem(index: 7, title: 'Packaging Tracker', icon: Icons.all_inbox_rounded),
    SidebarItem(index: 8, title: 'Stock & Inventory', icon: Icons.warehouse_rounded),
    SidebarItem(index: 9, title: 'Reports & Export', icon: Icons.insights_rounded),
  ];

  static const List<SidebarItem> adminItems = [
    SidebarItem(index: 10, title: 'Products Master', icon: Icons.tune_rounded),
    SidebarItem(index: 11, title: 'Settings & Config', icon: Icons.settings_suggest_rounded),
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
          // Brand Header with Gradient Logo (Precision Midnight Navy, Height 66 matching AppHeader)
          Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: AppColors.headerBackground,
              gradient: AppColors.headerGradient,
              border: Border(
                bottom: BorderSide(color: AppColors.headerBorder, width: 1.2),
                right: BorderSide(color: AppColors.headerBorder, width: 1.2),
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
                      color: AppColors.primary.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
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
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),

          // Menu Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
              children: [
                _buildSectionHeader('CORE ENGINES'),
                ...primaryItems.map((item) => _buildNavItem(item)),
                const SizedBox(height: 13),
                _buildSectionHeader('MANUFACTURING & FLEET'),
                ...operationsItems.map((item) => _buildNavItem(item)),
                const SizedBox(height: 13),
                _buildSectionHeader('CONTROL & STANDARDS'),
                ...adminItems.map((item) => _buildNavItem(item)),
              ],
            ),
          ),

          // Plant Location Footer with Golden Ratio Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accentMint,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Processing Plant #01',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Engine Calibrated • v1.0',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: AppColors.primaryDark,
        ),
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
                  width: 5,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                )
              : null,
          onTap: () => onItemSelected(item.index),
        ),
      ),
    );
  }
}
