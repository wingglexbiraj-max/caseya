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
          // Brand Header with Gradient Logo
          Container(
            padding: const EdgeInsets.fromLTRB(21, 24, 21, 18),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'C',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.9,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        'Dairy Plant OS',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: AppColors.textMuted,
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
