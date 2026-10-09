import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  List<UserModel> _employeeList = [];
  bool _isLoadingEmployees = false;
  String? _employeeLoadError;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final currentUser = ref.read(authProvider);
    if (!currentUser.isAdmin) return;

    setState(() {
      _isLoadingEmployees = true;
      _employeeLoadError = null;
    });

    try {
      if (SupabaseService.isInitialized) {
        final list = await SupabaseService.fetchAllEmployeeProfiles();
        if (mounted) {
          setState(() {
            _employeeList = list;
            _isLoadingEmployees = false;
          });
        }
      } else {
        // Active employee directory (fallback mode)
        if (mounted) {
          setState(() {
            _employeeList = [currentUser];
            _isLoadingEmployees = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _employeeLoadError = e.toString().replaceFirst('Exception: ', '');
          _isLoadingEmployees = false;
        });
      }
    }
  }

  void _openInviteDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final codeCtrl = TextEditingController(text: 'EMP-${DateTime.now().millisecondsSinceEpoch % 1000}');
    String selectedRole = 'Employee';
    String selectedDept = 'Processing & Operations';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.person_add_rounded, color: AppColors.primary),
                SizedBox(width: 10),
                Text('Invite / Provision Employee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Provision a new dairy plant employee account. An invitation link will be dispatched or linked to their profile in Supabase.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Employee Full Name *',
                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Plant Email Address *',
                        hintText: 'operator@caseya-plant.com',
                        prefixIcon: Icon(Icons.mail_outline, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Employee Code *',
                        prefixIcon: Icon(Icons.tag_rounded, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Plant Role *',
                        prefixIcon: Icon(Icons.security_rounded, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Admin', child: Text('Admin (Full Access & User Management)')),
                        DropdownMenuItem(value: 'Plant Manager', child: Text('Plant Manager (Operations & Reports)')),
                        DropdownMenuItem(value: 'Employee', child: Text('Employee (Operations Recording Only)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDept,
                      decoration: const InputDecoration(
                        labelText: 'Plant Department *',
                        prefixIcon: Icon(Icons.corporate_fare_rounded, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Processing & Operations', child: Text('Processing & Operations')),
                        DropdownMenuItem(value: 'Quality Assurance & Lab', child: Text('Quality Assurance & Lab')),
                        DropdownMenuItem(value: 'Boiler & Utilities', child: Text('Boiler & Utilities')),
                        DropdownMenuItem(value: 'Logistics & Dispatch', child: Text('Logistics & Dispatch')),
                        DropdownMenuItem(value: 'Inventory & Stores', child: Text('Inventory & Stores')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedDept = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all required fields')),
                          );
                          return;
                        }

                        setModalState(() => isSaving = true);
                        try {
                          await SupabaseService.provisionEmployee(
                            email: emailCtrl.text.trim(),
                            fullName: nameCtrl.text.trim(),
                            role: selectedRole,
                            employeeCode: codeCtrl.text.trim(),
                            department: selectedDept,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          await _loadEmployees();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✓ Employee invitation sent and profile provisioned.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (err) {
                          setModalState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Provisioning error: $err'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Invite & Provision'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openEditRoleDialog(UserModel emp) {
    String role = emp.role;
    String status = emp.accountStatus;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Edit Access: ${emp.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${emp.email}  •  Code: ${emp.employeeCode}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Assigned Role', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'Plant Manager', child: Text('Plant Manager')),
                      DropdownMenuItem(value: 'Employee', child: Text('Employee')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => role = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Account Status', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active (Authorized)')),
                      DropdownMenuItem(value: 'disabled', child: Text('Disabled / Suspended')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => status = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: isSaving
                    ? null
                    : () async {
                        setModalState(() => isSaving = true);
                        try {
                          if (role != emp.role) {
                            await SupabaseService.updateEmployeeRole(employeeId: emp.id, newRole: role);
                          }
                          if (status != emp.accountStatus) {
                            await SupabaseService.updateEmployeeStatus(employeeId: emp.id, newStatus: status);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          await _loadEmployees();
                        } catch (e) {
                          setModalState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
                            );
                          }
                        }
                      },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
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
            // Active User Profile & Session Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ACTIVE USER & ROLE-BASED ACCESS',
                        style: TextStyle(
                          fontSize: AppTextSizes.caption,
                          fontWeight: AppFontWeights.bold,
                          letterSpacing: 1.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          StatusBadge.success(user.role),
                          const SizedBox(width: 8),
                          StatusBadge(
                            text: user.accountStatus.toUpperCase(),
                            backgroundColor: user.isActive ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                            textColor: user.isActive ? const Color(0xFF047857) : const Color(0xFFDC2626),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0] : 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: AppFontWeights.bold, fontSize: AppTextSizes.subheading),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: AppTextSizes.body)),
                            Text(
                              'Email: ${user.email.isNotEmpty ? user.email : "Not linked"}  •  Code: ${user.employeeCode}  •  Department: ${user.department}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: AppTextSizes.caption),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        label: const Text('Log Out'),
                        onPressed: () async {
                          await ref.read(authNotifierProvider.notifier).logout();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Plant Employee Directory & Access Control (Admin Only)
            if (user.isAdmin) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PLANT EMPLOYEE DIRECTORY & PERMISSIONS',
                              style: TextStyle(
                                fontSize: AppTextSizes.caption,
                                fontWeight: AppFontWeights.bold,
                                letterSpacing: 1.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Manage employee account access, assigned roles, and invitations',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              tooltip: 'Refresh Employee List',
                              onPressed: _loadEmployees,
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.person_add_rounded, size: 16),
                              label: const Text('Invite Employee'),
                              onPressed: _openInviteDialog,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingEmployees)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_employeeLoadError != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF87171)),
                        ),
                        child: Text(
                          'Notice: $_employeeLoadError',
                          style: const TextStyle(color: AppColors.danger, fontSize: 13),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _employeeList.length,
                        separatorBuilder: (_, _) => const Divider(height: 16),
                        itemBuilder: (context, index) {
                          final emp = _employeeList[index];
                          final isSelf = emp.id == user.id || emp.email == user.email;

                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: emp.isAdmin ? AppColors.primary : AppColors.primaryLight,
                                child: Text(
                                  emp.name.isNotEmpty ? emp.name[0] : 'E',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          emp.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                        ),
                                        if (isSelf) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryContainer,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('YOU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      emp.email.isNotEmpty ? emp.email : 'No email associated',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  emp.department,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ),
                              StatusBadge.neutral(emp.role),
                              const SizedBox(width: 10),
                              StatusBadge(
                                text: emp.accountStatus.toUpperCase(),
                                backgroundColor: emp.isActive ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                                textColor: emp.isActive ? const Color(0xFF047857) : const Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 10),
                              if (!isSelf)
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: 'Modify Role / Access',
                                  onPressed: () => _openEditRoleDialog(emp),
                                )
                              else
                                const SizedBox(width: 40),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

          ],
        ),
      ),
    );
  }
}
