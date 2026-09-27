import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';

class StockPage extends StatelessWidget {
  const StockPage({super.key});

  static final List<Map<String, dynamic>> _stockData = [
    {
      'product': 'Purabi Plus Milk 500 ml',
      'category': 'Milk',
      'pieces': 4200,
      'crates': 210,
      'volume': 2100.0,
      'threshold': 500.0,
      'status': 'Adequate',
    },
    {
      'product': 'Purabi Plus Milk 250 ml',
      'category': 'Milk',
      'pieces': 3600,
      'crates': 90,
      'volume': 900.0,
      'threshold': 400.0,
      'status': 'Adequate',
    },
    {
      'product': 'Curd Pouch 400 g',
      'category': 'Curd',
      'pieces': 1800,
      'crates': 72,
      'volume': 720.0,
      'threshold': 200.0,
      'status': 'Adequate',
    },
    {
      'product': 'Sweet Curd Cup 80 g',
      'category': 'Curd',
      'pieces': 1200,
      'crates': 24,
      'volume': 96.0,
      'threshold': 150.0,
      'status': 'Low Stock Alert',
    },
    {
      'product': 'Lassi 200 ml',
      'category': 'Fermented',
      'pieces': 2400,
      'crates': 80,
      'volume': 480.0,
      'threshold': 200.0,
      'status': 'Adequate',
    },
    {
      'product': 'Toned Milk 500 ml',
      'category': 'Milk',
      'pieces': 3000,
      'crates': 150,
      'volume': 1500.0,
      'threshold': 500.0,
      'status': 'Adequate',
    },
  ];

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Cold Room & Finished Goods Inventory',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Real-time physical stock counts, crates on floor, and minimum threshold alerts.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CURRENT INVENTORY BALANCE',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: AppColors.textSecondary),
                      ),
                      StatusBadge.success('Cold Chain Verified'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _stockData.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _stockData[index];
                      final isLow = item['status'] == 'Low Stock Alert';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isLow ? AppColors.warningLight : AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isLow ? Icons.warning_amber : Icons.warehouse,
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
                                      Text(
                                        item['product'],
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusBadge.neutral(item['category'], fontSize: 11),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${Formatters.formatInt(item['pieces'])} Pieces  •  ${item['crates']} Crates',
                                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${Formatters.formatSmart(item['volume'])} ${item['category'] == 'Curd' ? 'Kg' : 'L'}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primaryDark),
                                ),
                                if (isLow)
                                  const Text(
                                    'Low Stock Alert',
                                    style: TextStyle(fontSize: 11.5, color: AppColors.danger, fontWeight: FontWeight.w700),
                                  )
                                else
                                  const Text(
                                    'Normal Buffer',
                                    style: TextStyle(fontSize: 11.5, color: AppColors.success, fontWeight: FontWeight.w600),
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
}
