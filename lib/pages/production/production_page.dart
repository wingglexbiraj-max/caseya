import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_badge.dart';
import '../../providers/auth_provider.dart';

class ProductionPage extends ConsumerStatefulWidget {
  const ProductionPage({super.key});

  @override
  ConsumerState<ProductionPage> createState() => _ProductionPageState();
}

class _ProductionPageState extends ConsumerState<ProductionPage> {
  final TextEditingController _batchController = TextEditingController(text: 'BT-2026-0927-A');
  final TextEditingController _productController = TextEditingController(text: 'Purabi Plus Milk 500 ml');
  final TextEditingController _qtyController = TextEditingController(text: '4200');
  final TextEditingController _cratesController = TextEditingController(text: '210');
  final TextEditingController _fatController = TextEditingController(text: '4.52');
  final TextEditingController _snfController = TextEditingController(text: '8.54');

  final List<Map<String, dynamic>> _productionEntries = [
    {
      'date': '2026-09-27',
      'shift': 'Shift A',
      'batch': 'BT-2026-0927-A',
      'product': 'Purabi Plus Milk 500 ml',
      'qty': 4200.0,
      'crates': 210,
      'fat': 4.52,
      'snf': 8.54,
      'employee': 'R. K. Baruah',
    },
    {
      'date': '2026-09-27',
      'shift': 'Shift A',
      'batch': 'BT-2026-0927-B',
      'product': 'Toned Milk 500 ml',
      'qty': 3000.0,
      'crates': 150,
      'fat': 3.02,
      'snf': 8.51,
      'employee': 'R. K. Baruah',
    },
    {
      'date': '2026-09-26',
      'shift': 'Shift B',
      'batch': 'BT-2026-0926-C',
      'product': 'Curd Pouch 400 g',
      'qty': 1200.0,
      'crates': 100,
      'fat': 3.25,
      'snf': 9.60,
      'employee': 'M. Hazarika',
    },
  ];

  void _addEntry() {
    final user = ref.read(authProvider);
    final qty = Formatters.parseDouble(_qtyController.text);
    final crates = int.tryParse(_cratesController.text) ?? (qty / 20).round();

    setState(() {
      _productionEntries.insert(0, {
        'date': Formatters.formatIsoDate(DateTime.now()),
        'shift': 'Shift A',
        'batch': _batchController.text,
        'product': _productController.text,
        'qty': qty,
        'crates': crates,
        'fat': double.tryParse(_fatController.text) ?? 4.5,
        'snf': double.tryParse(_snfController.text) ?? 8.5,
        'employee': user.name,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Production batch logged into daily manufacturing register.'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
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
              'Production Register',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Daily pasteurization and packaging floor output batches.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Entry Form
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NEW PRODUCTION BATCH ENTRY',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Batch Number',
                          controller: _batchController,
                          hint: 'BT-XXXX-XXXX',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AppTextField(
                          label: 'Product',
                          controller: _productController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Quantity Produced',
                          controller: _qtyController,
                          suffixText: 'Litres',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AppTextField(
                          label: 'Crates Produced',
                          controller: _cratesController,
                          suffixText: 'Crates',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AppTextField(
                          label: 'Tested FAT %',
                          controller: _fatController,
                          suffixText: '%',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AppTextField(
                          label: 'Tested SNF %',
                          controller: _snfController,
                          suffixText: '%',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_task, size: 18),
                      label: const Text('Save Batch Entry'),
                      onPressed: _addEntry,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Production History Table
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TODAY\'S PRODUCTION BATCHES',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: AppColors.textSecondary),
                      ),
                      StatusBadge.info('${_productionEntries.length} Batches'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _productionEntries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _productionEntries[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        title: Text(
                          '${item['product']} (${Formatters.formatSmart(item['qty'])} L)',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${item['date']} • ${item['shift']} • Batch: ${item['batch']}\nFAT: ${item['fat']}%  •  SNF: ${item['snf']}%  •  Operator: ${item['employee']}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        trailing: Text(
                          '${item['crates']} Crates',
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
