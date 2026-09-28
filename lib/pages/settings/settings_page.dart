import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_badge.dart';
import '../../providers/auth_provider.dart';
import '../../providers/boiler_provider.dart';
import '../../services/api_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final TextEditingController _apiUrlController = TextEditingController(text: ApiService.baseUrl);

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final boilerState = ref.watch(boilerProvider);
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
              'Settings & System Configuration',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Configure plant operational formulas, user permissions, and API backend connections.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // User & Role Management
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ACTIVE OPERATOR & ROLE-BASED ACCESS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: AppColors.textSecondary),
                      ),
                      StatusBadge.success(user.role),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user.name[0],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            Text(
                              'Code: ${user.employeeCode}  •  Department: ${user.department}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Switch Role for Testing Access Permissions:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: [
                      _buildRoleButton('Admin', user.role == 'Admin'),
                      _buildRoleButton('Supervisor', user.role == 'Supervisor'),
                      _buildRoleButton('Operator', user.role == 'Operator'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Plant Calculation Configurations
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CALCULATION ENGINE SETTINGS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Boiler: Include Fuel Top-Up in Net Shift Consumption',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'When enabled: Net Consumption = Level Drop Fuel + Fuel Top-up. When disabled, top-up is recorded as a separate inflow log.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    value: boilerState.includeTopUpInNet,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      ref.read(boilerProvider.notifier).toggleTopUpInclusion(val);
                    },
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Boiler Formula Multiplier', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      Text('900.0 (L / 70 CM)', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Standardization Formula Version', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      Text(AppConstants.formulaVersion, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // FastAPI Backend Settings
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'BACKEND & DATA STORE ARCHITECTURE',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: AppColors.textSecondary),
                      ),
                      StatusBadge(
                        text: 'Google Sheets & FastAPI Ready',
                        backgroundColor: AppColors.metricBgStock,
                        textColor: Color(0xFF1E40AF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'FastAPI Backend REST URL',
                    controller: _apiUrlController,
                    hint: 'http://localhost:8000/api/v1',
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Connect to Remote FastAPI Backend',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'When disabled, CASEYA runs in zero-latency offline mode using browser local storage.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    value: ApiService.useBackend,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        ApiService.useBackend = val;
                        ApiService.baseUrl = _apiUrlController.text.trim();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? 'Backend syncing enabled.' : 'Local storage mode active.'),
                          backgroundColor: AppColors.primary,
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

  Widget _buildRoleButton(String role, bool isCurrent) {
    return ChoiceChip(
      label: Text(role),
      selected: isCurrent,
      selectedColor: AppColors.primaryContainer,
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
        color: isCurrent ? AppColors.primaryDark : AppColors.textPrimary,
      ),
      onSelected: (selected) {
        if (selected) {
          ref.read(authProvider.notifier).switchRole(role);
        }
      },
    );
  }
}
