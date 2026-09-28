import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_badge.dart';

class DispatchPage extends StatefulWidget {
  const DispatchPage({super.key});

  @override
  State<DispatchPage> createState() => _DispatchPageState();
}

class _DispatchPageState extends State<DispatchPage> {
  final TextEditingController _vehicleController = TextEditingController(text: 'AS-01-EC-4021');
  final TextEditingController _routeController = TextEditingController(text: 'Route 04 - City North');
  final TextEditingController _driverController = TextEditingController(text: 'D. Kalita');
  final TextEditingController _cratesController = TextEditingController(text: '150');
  final TextEditingController _volumeController = TextEditingController(text: '3000');

  final List<Map<String, dynamic>> _dispatches = [
    {
      'vehicle': 'AS-01-EC-4021',
      'route': 'Route 04 - City North',
      'driver': 'D. Kalita',
      'crates': 150,
      'volume': 3000.0,
      'time': '08:50 AM',
      'date': '2026-09-27',
      'status': 'In Transit',
    },
    {
      'vehicle': 'AS-01-FC-8910',
      'route': 'Route 01 - Downtown Hub',
      'driver': 'B. Das',
      'crates': 220,
      'volume': 4400.0,
      'time': '07:15 AM',
      'date': '2026-09-27',
      'status': 'Delivered',
    },
    {
      'vehicle': 'AS-25-CC-1102',
      'route': 'Route 07 - Suburbs & Retail',
      'driver': 'J. Roy',
      'crates': 180,
      'volume': 3600.0,
      'time': '06:30 AM',
      'date': '2026-09-27',
      'status': 'Delivered',
    },
  ];

  void _addDispatch() {
    setState(() {
      _dispatches.insert(0, {
        'vehicle': _vehicleController.text,
        'route': _routeController.text,
        'driver': _driverController.text,
        'crates': int.tryParse(_cratesController.text) ?? 100,
        'volume': Formatters.parseDouble(_volumeController.text),
        'time': Formatters.formatTime(DateTime.now()),
        'date': Formatters.formatIsoDate(DateTime.now()),
        'status': 'Gate Out / In Transit',
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Vehicle dispatch departure recorded.'),
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
              'Dispatch & Fleet Logistics',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gate passes, delivery routes, and cold-chain crate distributions.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NEW VEHICLE DISPATCH ENTRY',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Vehicle Number',
                          controller: _vehicleController,
                          hint: 'AS-XX-XX-XXXX',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AppTextField(
                          label: 'Route / Hub',
                          controller: _routeController,
                          hint: 'Route 01...',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AppTextField(
                          label: 'Driver Name',
                          controller: _driverController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Total Crates Loaded',
                          controller: _cratesController,
                          suffixText: 'Crates',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AppTextField(
                          label: 'Total Net Volume',
                          controller: _volumeController,
                          suffixText: 'Litres',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.local_shipping, size: 18),
                      label: const Text('Record Dispatch Departure'),
                      onPressed: _addDispatch,
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
                        'TODAY\'S DISPATCHED VEHICLES',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: AppColors.textSecondary),
                      ),
                      StatusBadge.info('${_dispatches.length} Vehicles'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _dispatches.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _dispatches[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        title: Text(
                          '${item['vehicle']} — ${item['route']}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${item['date']} • ${item['time']} • Driver: ${item['driver']}\nStatus: ${item['status']}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item['crates']} Crates',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primaryDark),
                            ),
                            Text(
                              '${Formatters.formatSmart(item['volume'])} L',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
