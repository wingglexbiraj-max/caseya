import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  static const List<Map<String, dynamic>> _inventoryData = [
    // --- CUPS ---
    {
      'name': 'Lassi Cup (200ml)',
      'category': 'Cups',
      'packaging': '33 Boxes',
      'totalQty': '82,500 pcs',
      'details': '2,500 pcs / box',
      'status': 'Adequate',
      'icon': Icons.local_drink_rounded,
    },
    {
      'name': 'S80 Cup (Sweet Curd 80g)',
      'category': 'Cups',
      'packaging': '22 Boxes',
      'totalQty': '52,800 pcs',
      'details': '2,400 pcs / box',
      'status': 'Adequate',
      'icon': Icons.takeout_dining_rounded,
    },
    {
      'name': 'S200 Cup (Sweet Curd 200g)',
      'category': 'Cups',
      'packaging': '11 Boxes',
      'totalQty': '22,000 pcs',
      'details': '2,000 pcs / box',
      'status': 'Adequate',
      'icon': Icons.takeout_dining_rounded,
    },
    {
      'name': 'S400 Cup (Sweet Curd 400g)',
      'category': 'Cups',
      'packaging': '40 Boxes',
      'totalQty': '4,000 pcs',
      'details': '100 pcs / box',
      'status': 'Adequate',
      'icon': Icons.takeout_dining_rounded,
    },
    {
      'name': 'P80 Cup (Plain Curd 80g)',
      'category': 'Cups',
      'packaging': '16 Boxes',
      'totalQty': '38,400 pcs',
      'details': '2,400 pcs / box',
      'status': 'Adequate',
      'icon': Icons.takeout_dining_rounded,
    },
    {
      'name': 'P200 Cup (Plain Curd 200g)',
      'category': 'Cups',
      'packaging': '5 Boxes',
      'totalQty': '10,000 pcs',
      'details': '2,000 pcs / box',
      'status': 'Low Stock Alert',
      'icon': Icons.takeout_dining_rounded,
    },
    {
      'name': 'P400 Cup (Plain Curd 400g)',
      'category': 'Cups',
      'packaging': '47 Boxes',
      'totalQty': '47,000 pcs',
      'details': '1,000 pcs / box',
      'status': 'Adequate',
      'icon': Icons.takeout_dining_rounded,
    },

    // --- POLY ROLL ---
    {
      'name': 'Poly Film STD 500ml',
      'category': 'Poly Roll',
      'packaging': '8 Rolls',
      'totalQty': '8 Rolls',
      'details': 'Standardized milk 500 ml packaging film',
      'status': 'Adequate',
      'icon': Icons.album_rounded,
    },
    {
      'name': 'Poly Film STD 250ml',
      'category': 'Poly Roll',
      'packaging': '42 Rolls',
      'totalQty': '42 Rolls',
      'details': 'Standardized milk 250 ml packaging film',
      'status': 'Adequate',
      'icon': Icons.album_rounded,
    },
    {
      'name': 'Poly Film STD 200ml',
      'category': 'Poly Roll',
      'packaging': '15 Rolls',
      'totalQty': '15 Rolls',
      'details': 'Standardized milk 200 ml packaging film',
      'status': 'Adequate',
      'icon': Icons.album_rounded,
    },
    {
      'name': 'Poly Film SM+ 500ml',
      'category': 'Poly Roll',
      'packaging': '5 Rolls',
      'totalQty': '5 Rolls',
      'details': 'Smart Plus toned milk 500 ml film',
      'status': 'Low Stock Alert',
      'icon': Icons.album_rounded,
    },
    {
      'name': 'Poly Film Sweet Curd 400gm',
      'category': 'Poly Roll',
      'packaging': '3 Rolls',
      'totalQty': '3 Rolls',
      'details': 'Sweet curd 400g pouch film',
      'status': 'Low Stock Alert',
      'icon': Icons.album_rounded,
    },
    {
      'name': 'Poly Film Sweet Curd 1kg',
      'category': 'Poly Roll',
      'packaging': '6 Rolls',
      'totalQty': '6 Rolls',
      'details': 'Sweet curd 1 kg pouch packaging film',
      'status': 'Adequate',
      'icon': Icons.album_rounded,
    },
    {
      'name': 'Poly Film Plain Curd 400gm',
      'category': 'Poly Roll',
      'packaging': '3 Rolls',
      'totalQty': '3 Rolls',
      'details': 'Plain curd 400g pouch film',
      'status': 'Low Stock Alert',
      'icon': Icons.album_rounded,
    },
    {
      'name': 'Poly Film Plain Curd 1kg',
      'category': 'Poly Roll',
      'packaging': '7 Rolls',
      'totalQty': '7 Rolls',
      'details': 'Plain curd 1 kg pouch packaging film',
      'status': 'Adequate',
      'icon': Icons.album_rounded,
    },

    // --- ALUMINIUM FOIL ---
    {
      'name': 'Foil 80gm (Pink)',
      'category': 'Aluminium Foil',
      'packaging': '22 Boxes',
      'totalQty': '831,600 lids',
      'details': '37,800 lids / box • Sweet curd 80g',
      'status': 'Adequate',
      'icon': Icons.circle_outlined,
    },
    {
      'name': 'Foil 200/400gm (Pink)',
      'category': 'Aluminium Foil',
      'packaging': '12 Boxes',
      'totalQty': '16,800 lids',
      'details': '1,400 lids / box • Sweet curd cups',
      'status': 'Adequate',
      'icon': Icons.circle_outlined,
    },
    {
      'name': 'Foil 80gm (Blue)',
      'category': 'Aluminium Foil',
      'packaging': '69 Boxes',
      'totalQty': '96,600 lids',
      'details': '1,400 lids / box • Plain curd 80g & Lassi 200ml',
      'status': 'Adequate',
      'icon': Icons.circle_outlined,
    },
    {
      'name': 'Foil 200/400gm (Blue)',
      'category': 'Aluminium Foil',
      'packaging': '35 Boxes',
      'totalQty': '49,000 lids',
      'details': '1,400 lids / box • Plain curd cups',
      'status': 'Adequate',
      'icon': Icons.circle_outlined,
    },

    // --- SERVING MATERIAL ---
    {
      'name': 'Wooden Spoon',
      'category': 'Serving Material',
      'packaging': '7 Boxes',
      'totalQty': '126,000 pcs',
      'details': '18,000 pcs / box • Curd & dessert spoon',
      'status': 'Adequate',
      'icon': Icons.flatware_rounded,
    },

    // --- INGREDIENTS ---
    {
      'name': 'Sugar',
      'category': 'Ingredients',
      'packaging': '19 Bags',
      'totalQty': '950 kg',
      'details': '50 kg / bag • Sweet curd production buffer',
      'status': 'Adequate',
      'icon': Icons.inventory_2_rounded,
    },
    {
      'name': 'SMP (Skimmed Milk Powder)',
      'category': 'Ingredients',
      'packaging': '57 Bags',
      'totalQty': '1,425 kg',
      'details': '25 kg / bag • Plant standardization stock',
      'status': 'Adequate',
      'icon': Icons.grain_rounded,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Cups':
        return Icons.takeout_dining_rounded;
      case 'Poly Roll':
        return Icons.album_rounded;
      case 'Aluminium Foil':
        return Icons.circle_outlined;
      case 'Serving Material':
        return Icons.flatware_rounded;
      case 'Ingredients':
        return Icons.grain_rounded;
      default:
        return Icons.all_inbox_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final query = _searchController.text.trim().toLowerCase();

    final categories = ['All', 'Cups', 'Poly Roll', 'Aluminium Foil', 'Serving Material', 'Ingredients'];

    final filtered = _inventoryData.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item['category'] == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          item['name'].toString().toLowerCase().contains(query) ||
          item['packaging'].toString().toLowerCase().contains(query) ||
          item['details'].toString().toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

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
            // Top Quick KPIs
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Ingredients Buffer',
                    '2,375 kg',
                    '57 Bags SMP • 19 Bags Sugar',
                    Icons.grain_rounded,
                    AppColors.goldAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    'Poly Roll Stock',
                    '89 Rolls',
                    'STD, SM+ & Curd Pouches',
                    Icons.album_rounded,
                    AppColors.primary,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      'Aluminium Foil Buffer',
                      '994k Lids',
                      '138 Total Boxes on Floor',
                      Icons.circle_outlined,
                      AppColors.accentCyanDeep,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search input
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search items (e.g. STD 500ml, Sugar, S80, Foil)...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category Filter Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      final count = cat == 'All'
                          ? _inventoryData.length
                          : _inventoryData.where((item) => item['category'] == cat).length;
                      final chipText = '$cat ($count)';

                      return ChoiceChip(
                        avatar: Icon(
                          _getCategoryIcon(cat),
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        label: Text(chipText),
                        selected: isSelected,
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.background,
                        elevation: isSelected ? 1 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.cardBorder,
                            width: isSelected ? 1.6 : 1.0,
                          ),
                        ),
                        labelStyle: TextStyle(
                          fontSize: AppTextSizes.caption,
                          fontWeight: isSelected ? AppFontWeights.bold : AppFontWeights.medium,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filtered.length} ITEMS LOGGED',
                        style: const TextStyle(
                          fontSize: AppTextSizes.caption,
                          fontWeight: AppFontWeights.bold,
                          letterSpacing: 1.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      StatusBadge.success('Physical Floor Count Verified'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isLow = item['status'] == 'Low Stock Alert';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isLow ? AppColors.warningLight : AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                color: isLow ? AppColors.warning : AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item['name'],
                                          style: const TextStyle(
                                            fontWeight: AppFontWeights.bold,
                                            fontSize: AppTextSizes.body,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusBadge.neutral(item['category'], fontSize: AppTextSizes.caption),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item['details'],
                                    style: const TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  item['packaging'],
                                  style: const TextStyle(
                                    fontWeight: AppFontWeights.bold,
                                    fontSize: AppTextSizes.body,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['totalQty'],
                                  style: const TextStyle(
                                    fontSize: AppTextSizes.caption,
                                    fontWeight: AppFontWeights.semiBold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (isLow)
                                  const Text(
                                    'Low Buffer Alert',
                                    style: TextStyle(
                                      fontSize: AppTextSizes.caption,
                                      color: AppColors.danger,
                                      fontWeight: AppFontWeights.bold,
                                    ),
                                  )
                                else
                                  const Text(
                                    'Adequate',
                                    style: TextStyle(
                                      fontSize: AppTextSizes.caption,
                                      color: AppColors.success,
                                      fontWeight: AppFontWeights.semiBold,
                                    ),
                                  ),
                              ],
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

  Widget _buildMetricTile(String title, String val, String subtitle, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.semiBold, color: AppColors.textSecondary),
                ),
                Text(
                  val,
                  style: const TextStyle(fontSize: AppTextSizes.subheading, fontWeight: AppFontWeights.bold, color: AppColors.textPrimary),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: AppTextSizes.caption, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
