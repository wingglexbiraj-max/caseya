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
    SidebarItem(index: 0, title: 'Dashboard', icon: Icons.dashboard_outlined),
    SidebarItem(index: 1, title: 'Product Calculator', icon: Icons.calculate_outlined),
    SidebarItem(index: 2, title: 'Milk Standardization', icon: Icons.water_drop_outlined),
    SidebarItem(index: 3, title: 'Boiler Fuel', icon: Icons.local_fire_department_outlined),
  ];

  static const List<SidebarItem> operationsItems = [
    SidebarItem(index: 4, title: 'Production', icon: Icons.factory_outlined),
    SidebarItem(index: 5, title: 'Dispatch', icon: Icons.local_shipping_outlined),
    SidebarItem(index: 6, title: 'Packaging', icon: Icons.inventory_2_outlined),
    SidebarItem(index: 7, title: 'Stock & Inventory', icon: Icons.warehouse_outlined),
    SidebarItem(index: 8, title: 'Reports & Export', icon: Icons.bar_chart_outlined),
  ];

  static const List<SidebarItem> adminItems = [
    SidebarItem(index: 9, title: 'Products Master', icon: Icons.format_list_bulleted_outlined),
    SidebarItem(index: 10, title: 'Settings & Config', icon: Icons.tune_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
      ),
      child: Column(
        children: [
          // Brand Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'C',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        'Dairy Operations',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                _buildSectionHeader('CORE CALCULATION'),
                ...primaryItems.map((item) => _buildNavItem(item)),
                const SizedBox(height: 12),
                _buildSectionHeader('OPERATIONS'),
                ...operationsItems.map((item) => _buildNavItem(item)),
                const SizedBox(height: 12),
                _buildSectionHeader('MANAGEMENT'),
                ...adminItems.map((item) => _buildNavItem(item)),
              ],
            ),
          ),

          // Plant Location Footer
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Plant Unit #01',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'System v1.0.0',
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
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildNavItem(SidebarItem item) {
    final isSelected = selectedIndex == item.index;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          leading: Icon(
            item.icon,
            size: 19,
            color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
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
                  height: 16,
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
