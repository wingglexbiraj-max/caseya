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
    // --- RAW MATERIALS ---
    {
      'name': 'SMP (Skimmed Milk Powder)',
      'category': 'Raw Materials',
      'packaging': '57 Bags',
      'totalQty': '1,425 kg',
      'details': '25 kg / bag • Plant standardization stock',
      'status': 'Adequate',
      'icon': Icons.grain_rounded,
    },
    {
      'name': 'Sugar',
      'category': 'Raw Materials',
      'packaging': '19 Bags',
      'totalQty': '950 kg',
      'details': '50 kg / bag • Sweet curd production buffer',
      'status': 'Adequate',
      'icon': Icons.inventory_2_rounded,
    },

    // --- CUPS & SPOONS ---
    {
      'name': 'S80 Cup (Sweet Curd 80g)',
      'category': 'Cups & Spoons',
      'packaging': '22 Boxes',
      'totalQty': '52,800 pcs',
      'details': '2,400 pcs / box',
      'status': 'Adequate',
      'icon': Icons.takeout_dining_rounded,
    },
    {
      'name': 'S200 Cup (Sweet Curd 200g)',
      'category': 'Cups & Spoons',
      'packaging': '11 Boxes',
      'totalQty': '22,000 pcs',
      'details': '2,000 pcs / box',
      'status': 'Adequate',
      'icon': Icons.takeout_dining_rounded,
    },
    {
      'name': 'S400 Cup (Sweet Curd 400g)',
      'category': 'Cups & Spoons',
      'packaging': '40 Boxes',
      'totalQty': '4,000 pcs',
      'details': '100 pcs / box',
      'status': 'Adequate',
      'icon': Icons.takeout_dining_rounded,
    },
    {
      'name': 'P80 Cup (Plain Curd 80g)',
      'category': 'Cups & Spoons',
      'packaging': '16 Boxes',
      'totalQty': '38,400 pcs',
      'details': '2,400 pcs / box',
      'status': 'Adequate',
      'icon': Icons.takeout_dining_rounded,
    },
    {
      'name': 'P200 Cup (Plain Curd 200g)',
      'category': 'Cups & Spoons',
      'packaging': '5 Boxes',
      'totalQty': '10,000 pcs',
      'details': '2,000 pcs / box',
      'status': 'Low Stock Alert',
      'icon': Icons.takeout_dining_rounded,
    },
    {
      'name': 'P400 Cup (Plain Curd 400g)',
      'category': 'Cups & Spoons',
      'packaging': '47 Boxes',
      'totalQty': '47,000 pcs',
      'details': '1,000 pcs / box',
      'status': 'Adequate',
      'icon': Icons.takeout_dining_rounded,
    },
    {
      'name': 'Lassi Cup (200ml)',
      'category': 'Cups & Spoons',
      'packaging': '33 Boxes',
      'totalQty': '82,500 pcs',
      'details': '2,500 pcs / box',
      'status': 'Adequate',
      'icon': Icons.local_drink_rounded,
    },
    {
      'name': 'Wooden Spoon',
      'category': 'Cups & Spoons',
      'packaging': '7 Boxes',
      'totalQty': '126,000 pcs',
      'details': '18,000 pcs / box',
      'status': 'Adequate',
      'icon': Icons.flatware_rounded,
    },

    // --- FOIL LIDS ---
    {
      'name': 'Foil 80gm (Pink)',
      'category': 'Foil Lids',
      'packaging': '22 Boxes',
      'totalQty': '831,600 lids',
      'details': '37,800 lids / box • Sweet curd 80g',
      'status': 'Adequate',
      'icon': Icons.circle_outlined,
    },
    {
      'name': 'Foil 80gm / 200ml (Blue)',
      'category': 'Foil Lids',
      'packaging': '69 Boxes',
      'totalQty': '96,600 lids',
      'details': '1,400 lids / box • Plain curd 80g & Lassi 200ml',
      'status': 'Adequate',
      'icon': Icons.circle_outlined,
    },
    {
      'name': 'Foil 400gm / 200gm (Pink)',
      'category': 'Foil Lids',
      'packaging': '12 Boxes',
      'totalQty': '16,800 lids',
      'details': '1,400 lids / box • Sweet curd cups',
      'status': 'Adequate',
      'icon': Icons.circle_outlined,
    },
    {
      'name': 'Foil 400gm / 200gm (Blue)',
      'category': 'Foil Lids',
      'packaging': '35 Boxes',
      'totalQty': '49,000 lids',
      'details': '1,400 lids / box • Plain curd cups',
      'status': 'Adequate',
      'icon': Icons.circle_outlined,
    },

    // --- POLY FILM ROLLS ---
    {
      'name': 'Poly Film 250ml (STD)',
      'category': 'Poly Film Rolls',
      'packaging': '42 Rolls',
      'totalQty': '42 Rolls',
      'details': 'Standardized milk 250 ml packaging film',
      'status': 'Adequate',
      'icon': Icons.album_rounded,
    },
    {
      'name': 'Poly Film 500ml (STD)',
      'category': 'Poly Film Rolls',
      'packaging': '8 Rolls',
      'totalQty': '8 Rolls',
      'details': 'Standardized milk 500 ml packaging film',
      'status': 'Adequate',
      'icon': Icons.album_rounded,
    },
    {
      'name': 'Poly Film 500ml (SM+)',
      'category': 'Poly Film Rolls',
      'packaging': '5 Rolls',
      'totalQty': '5 Rolls',
      'details': 'Smart Plus toned milk 500 ml film',
      'status': 'Low Stock Alert',
      'icon': Icons.album_rounded,
    },
    {
      'name': 'Poly Film 400gm (Plain Curd p/c)',
      'category': 'Poly Film Rolls',
      'packaging': '3 Rolls',
      'totalQty': '3 Rolls',
      'details': 'Plain curd 400g pouch film',
      'status': 'Low Stock Alert',
      'icon': Icons.album_rounded,
    },
    {
      'name': 'Poly Film 400gm (Sweet Curd s/c)',
      'category': 'Poly Film Rolls',
      'packaging': '3 Rolls',
      'totalQty': '3 Rolls',
      'details': 'Sweet curd 400g pouch film',
      'status': 'Low Stock Alert',
      'icon': Icons.album_rounded,
    },

    // --- COLD ROOM FINISHED GOODS ---
    {
      'name': 'Curd Pouch 400 g (CP400)',
      'category': 'Finished Goods',
      'packaging': '60 Crates',
      'totalQty': '1,800 pcs (720.0 kg)',
      'details': '30 pcs / crate • 12.0 kg per crate • Rate ₹35/pc',
      'status': 'Adequate',
      'icon': Icons.inventory_rounded,
    },
    {
      'name': 'Curd Pouch 1 kg (CP1000)',
      'category': 'Finished Goods',
      'packaging': '100 Crates',
      'totalQty': '1,200 pcs (1,200.0 kg)',
      'details': '12 pcs / crate • 12.0 kg per crate • Rate ₹75/pc',
      'status': 'Adequate',
      'icon': Icons.inventory_rounded,
    },
    {
      'name': 'Purabi Plus Milk 500 ml',
      'category': 'Finished Goods',
      'packaging': '210 Crates',
      'totalQty': '4,200 pcs (2,100.0 L)',
      'details': '20 pcs / crate • 10.0 L per crate',
      'status': 'Adequate',
      'icon': Icons.water_drop_rounded,
    },
    {
      'name': 'Purabi Plus Milk 250 ml',
      'category': 'Finished Goods',
      'packaging': '90 Crates',
      'totalQty': '3,600 pcs (900.0 L)',
      'details': '40 pcs / crate • 10.0 L per crate',
      'status': 'Adequate',
      'icon': Icons.water_drop_rounded,
    },
    {
      'name': 'Sweet Curd Cup 80 g (S80)',
      'category': 'Finished Goods',
      'packaging': '20 Crates',
      'totalQty': '1,200 pcs (96.0 kg)',
      'details': '60 pcs / crate • 4.8 kg per crate',
      'status': 'Low Stock Alert',
      'icon': Icons.takeout_dining_rounded,
    },
    {
      'name': 'Purabi Lassi 200 ml (PL200)',
      'category': 'Finished Goods',
      'packaging': '80 Crates',
      'totalQty': '2,400 pcs (480.0 L)',
      'details': '30 pcs / crate • 6.0 L per crate',
      'status': 'Adequate',
      'icon': Icons.local_drink_rounded,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Finished Goods':
        return Icons.warehouse_rounded;
      case 'Raw Materials':
        return Icons.grain_rounded;
      case 'Cups & Spoons':
        return Icons.takeout_dining_rounded;
      case 'Foil Lids':
        return Icons.circle_outlined;
      case 'Poly Film Rolls':
        return Icons.album_rounded;
      default:
        return Icons.all_inbox_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final query = _searchController.text.trim().toLowerCase();

    final categories = ['All', 'Finished Goods', 'Raw Materials', 'Cups & Spoons', 'Foil Lids', 'Poly Film Rolls'];

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
            Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Plant Inventory & Material Balance',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Real-time physical stock counts: Raw Materials (SMP & Sugar), Packaging (Cups, Foils, Rolls), and Cold Room Finished Goods.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Top Quick KPIs
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Raw Materials',
                    '2,375 kg',
                    '57 Bags SMP • 19 Bags Sugar',
                    Icons.grain_rounded,
                    AppColors.goldAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    'Poly Film Rolls',
                    '61 Rolls',
                    'STD, SM+ & Curd Pouches',
                    Icons.album_rounded,
                    AppColors.primary,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      'Foil Lids Buffer',
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
                      hintText: 'Search items (e.g. CP400, SMP, S80, Poly Film)...',
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
                      return ChoiceChip(
                        avatar: Icon(
                          _getCategoryIcon(cat),
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        label: Text(cat),
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
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
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
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
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
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusBadge.neutral(item['category'], fontSize: 10.5),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item['details'],
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['totalQty'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (isLow)
                                  const Text(
                                    'Low Buffer Alert',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                else
                                  const Text(
                                    'Adequate',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
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
              color: color.withOpacity(0.12),
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
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                Text(
                  val,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
