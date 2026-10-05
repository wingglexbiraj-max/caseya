import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selectedModule = 'Boiler Consumption Report';
  String _selectedShift = 'All Shifts';
  final DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  final DateTime _endDate = DateTime.now();

  static const List<String> _modules = [
    'Boiler Consumption Report',
    'Milk Standardization Report',
    'Product Calculation Report',
    'Daily Production Report',
    'Dispatch & Fleet Report',
    'Stock & Inventory Report',
  ];

  void _exportCsv() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Exported "$_selectedModule" CSV data stream.'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _printReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Generating printable summary for "$_selectedModule"...'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
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
            if (!isMobile) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Print Preview'),
                    onPressed: _printReport,
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Export CSV / Excel'),
                    onPressed: _exportCsv,
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],

            // Filters Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'REPORT PARAMETERS',
                    style: TextStyle(fontSize: AppTextSizes.caption, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Select Module
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Select Module', style: TextStyle(fontSize: AppTextSizes.body, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.cardBorder, width: 1.2),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedModule,
                                  isExpanded: true,
                                  items: _modules.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _selectedModule = v);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Select Shift
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Shift Filter', style: TextStyle(fontSize: AppTextSizes.body, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.cardBorder, width: 1.2),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedShift,
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem(value: 'All Shifts', child: Text('All Shifts')),
                                    ...AppConstants.shifts.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) setState(() => _selectedShift = v);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Date Range Display
                  Row(
                    children: [
                      const Icon(Icons.date_range, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Date Range: ${Formatters.formatDate(_startDate)}  —  ${Formatters.formatDate(_endDate)}',
                        style: const TextStyle(fontSize: AppTextSizes.body, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Report Preview Table
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedModule.toUpperCase(),
                        style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: AppColors.textSecondary),
                      ),
                      StatusBadge.info('Verified Log Data'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildReportPreview(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportPreview() {
    return Table(
      border: TableBorder.all(color: AppColors.cardBorder, width: 1),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.primaryContainer),
          children: const [
            Padding(padding: EdgeInsets.all(10), child: Text('Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: AppTextSizes.body))),
            Padding(padding: EdgeInsets.all(10), child: Text('Shift / Batch', style: TextStyle(fontWeight: FontWeight.w700, fontSize: AppTextSizes.body))),
            Padding(padding: EdgeInsets.all(10), child: Text('Consumption / Net Output', style: TextStyle(fontWeight: FontWeight.w700, fontSize: AppTextSizes.body))),
            Padding(padding: EdgeInsets.all(10), child: Text('Officer / Chemist', style: TextStyle(fontWeight: FontWeight.w700, fontSize: AppTextSizes.body))),
          ],
        ),
        TableRow(
          children: const [
            Padding(padding: EdgeInsets.all(10), child: Text('2026-09-27')),
            Padding(padding: EdgeInsets.all(10), child: Text('Shift A (06:00 - 14:00)')),
            Padding(padding: EdgeInsets.all(10), child: Text('900.00 L (Diff: 70 CM)')),
            Padding(padding: EdgeInsets.all(10), child: Text('Biraj Goswami')),
          ],
        ),
        TableRow(
          children: const [
            Padding(padding: EdgeInsets.all(10), child: Text('2026-09-26')),
            Padding(padding: EdgeInsets.all(10), child: Text('Shift B (14:00 - 22:00)')),
            Padding(padding: EdgeInsets.all(10), child: Text('797.14 L (Diff: 62 CM)')),
            Padding(padding: EdgeInsets.all(10), child: Text('M. Hazarika')),
          ],
        ),
        TableRow(
          children: const [
            Padding(padding: EdgeInsets.all(10), child: Text('2026-09-25')),
            Padding(padding: EdgeInsets.all(10), child: Text('Shift A (06:00 - 14:00)')),
            Padding(padding: EdgeInsets.all(10), child: Text('1064.29 L (Top-up: 100 L)')),
            Padding(padding: EdgeInsets.all(10), child: Text('Biraj Goswami')),
          ],
        ),
      ],
    );
  }
}
