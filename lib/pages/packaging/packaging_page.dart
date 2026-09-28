import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_badge.dart';

class PackagingPage extends StatefulWidget {
  const PackagingPage({super.key});

  @override
  State<PackagingPage> createState() => _PackagingPageState();
}

class _PackagingPageState extends State<PackagingPage> {
  final TextEditingController _machineController = TextEditingController(text: 'FPM-01 (Form-Fill-Seal)');
  final TextEditingController _rollController = TextEditingController(text: 'ROLL-2026-901');
  final TextEditingController _filmConsumedController = TextEditingController(text: '45.0');
  final TextEditingController _wastageController = TextEditingController(text: '1.2');
  final TextEditingController _pouchesController = TextEditingController(text: '8400');

  final List<Map<String, dynamic>> _packagingEntries = [
    {
      'date': '2026-09-27',
      'shift': 'Shift A',
      'machine': 'FPM-01',
      'roll': 'ROLL-2026-901',
      'product': 'Purabi Plus Milk 500 ml',
      'consumed': 45.0,
      'wastage': 1.2,
      'pouches': 8400,
      'wastagePercent': 2.67,
    },
    {
      'date': '2026-09-26',
      'shift': 'Shift B',
      'machine': 'FPM-02',
      'roll': 'ROLL-2026-880',
      'product': 'Curd Pouch 400 g',
      'consumed': 38.5,
      'wastage': 0.9,
      'pouches': 3600,
      'wastagePercent': 2.34,
    },
  ];

  void _addEntry() {
    final consumed = Formatters.parseDouble(_filmConsumedController.text);
    final wastage = Formatters.parseDouble(_wastageController.text);
    final pct = consumed > 0 ? (wastage / consumed) * 100 : 0.0;

    setState(() {
      _packagingEntries.insert(0, {
        'date': Formatters.formatIsoDate(DateTime.now()),
        'shift': 'Shift A',
        'machine': _machineController.text,
        'roll': _rollController.text,
        'product': 'Purabi Plus Milk 500 ml',
        'consumed': consumed,
        'wastage': wastage,
        'pouches': int.tryParse(_pouchesController.text) ?? 5000,
        'wastagePercent': pct,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Packaging film consumption recorded.'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildRollChip(String label, String stock, String product) {
    final isSelected = _rollController.text.contains(label);
    return ActionChip(
      avatar: Icon(
        Icons.album_rounded,
        size: 15,
        color: isSelected ? Colors.white : AppColors.primary,
      ),
      label: Text('$label ($stock)'),
      backgroundColor: isSelected ? AppColors.primary : AppColors.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.primaryDark,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.cardBorder,
        ),
      ),
      onPressed: () {
        setState(() {
          _rollController.text = '$label - Batch ${DateTime.now().year}';
        });
      },
    );
  }

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
              'Packaging & Film Wastage Tracker',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Track film roll consumption, pouch packing counts, and calculate film wastage percentage.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RECORD PACKAGING ROLL USAGE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Quick Select Plant Film Roll (Active Stock):',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildRollChip('Poly film 250ml (STD)', '42 roll', 'Purabi Plus Milk 250 ml'),
                      _buildRollChip('Poly film 500ml (STD)', '8 roll', 'Purabi Plus Milk 500 ml'),
                      _buildRollChip('Poly film 500ml (SM+)', '5 roll', 'Purabi Smart Plus 500 ml'),
                      _buildRollChip('Poly film 400gm (p/c)', '3 roll', 'Curd Pouch 400 g (CP400)'),
                      _buildRollChip('Poly film 400gm (s/c)', '3 roll', 'Sweet Curd Pouch 400 g'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Packing Machine No.',
                          controller: _machineController,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AppTextField(
                          label: 'Film Roll Batch ID',
                          controller: _rollController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Film Consumed (Kg)',
                          controller: _filmConsumedController,
                          suffixText: 'Kg',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AppTextField(
                          label: 'Film Wastage (Kg)',
                          controller: _wastageController,
                          suffixText: 'Kg',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AppTextField(
                          label: 'Pouches Packed',
                          controller: _pouchesController,
                          suffixText: 'Pouches',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.inventory_2, size: 18),
                      label: const Text('Save Packaging Log'),
                      onPressed: _addEntry,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PACKAGING RECENT LOGS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: AppColors.textSecondary),
                      ),
                      StatusBadge.info('${_packagingEntries.length} Records'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _packagingEntries.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _packagingEntries[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        title: Text(
                          '${item['product']} — ${item['machine']}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${item['date']} • ${item['shift']} • Roll: ${item['roll']}\n'
                          'Film: ${item['consumed']} Kg  •  Wastage: ${item['wastage']} Kg (${Formatters.formatPercent(item['wastagePercent'])})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        trailing: Text(
                          '${Formatters.formatInt(item['pouches'])} Pouches',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primaryDark),
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
