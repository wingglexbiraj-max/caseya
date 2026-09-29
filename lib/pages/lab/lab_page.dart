import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../providers/lab_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/lab_milk_test.dart';

class LabPage extends ConsumerStatefulWidget {
  const LabPage({super.key});

  @override
  ConsumerState<LabPage> createState() => _LabPageState();
}

class _LabPageState extends ConsumerState<LabPage> {
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _snfController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fatController.dispose();
    _snfController.dispose();
    _remarksController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      final user = ref.read(authProvider);
      ref.read(labProvider.notifier).setFat(Formatters.parseDouble(_fatController.text));
      ref.read(labProvider.notifier).setSnf(Formatters.parseDouble(_snfController.text));
      ref.read(labProvider.notifier).setRemarks(_remarksController.text.trim());

      final success = await ref.read(labProvider.notifier).saveReading(
            userId: user.employeeCode,
            userName: user.name,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(labProvider).successMessage ?? '✓ Lab reading saved successfully.'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
        _onClear();
      }
    }
  }

  void _onClear() {
    ref.read(labProvider.notifier).cancelEditing();
    setState(() {
      _fatController.clear();
      _snfController.clear();
      _remarksController.clear();
    });
  }

  void _loadIntoForm(LabMilkTest test) {
    ref.read(labProvider.notifier).startEditing(test);
    setState(() {
      _fatController.text = test.fatPercentage.toStringAsFixed(2);
      _snfController.text = test.snfPercentage.toStringAsFixed(2);
      _remarksController.text = test.remarks;
    });
  }

  Future<void> _selectDate() async {
    final current = ref.read(labProvider).selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      ref.read(labProvider.notifier).setDate(picked);
    }
  }

  Future<void> _selectTime() async {
    final current = ref.read(labProvider).selectedTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked != null) {
      ref.read(labProvider.notifier).setTime(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(labProvider);
    final user = ref.watch(authProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

    final todayFormatted = Formatters.formatDate(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 28,
          vertical: 22,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header with Today's Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.goldAccent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Lab Fat & SNF',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.today_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 5),
                                Text(
                                  'Today: $todayFormatted',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (state.editingTest != null) ...[
                            const SizedBox(width: 10),
                            StatusBadge.warning('Editing ${state.editingTest!.siloName} Reading'),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Daily laboratory testing of milk Fat % and SNF % across storage silos & tanks',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (state.editingTest != null)
                    OutlinedButton(
                      onPressed: _onClear,
                      child: const Text('Cancel Edit'),
                    ),
                ],
              ),
              const SizedBox(height: 22),

              // Error messages
              if (state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ===============================================================
              // 1. LATEST READINGS DASHBOARD (TOP SECTION)
              // ===============================================================
              _buildLatestReadingsDashboard(state),
              const SizedBox(height: 24),

              // ===============================================================
              // 2. LAB ENTRY FORM
              // ===============================================================
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'RECORD MILK QUALITY TEST',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Row 1: Date, Time, and Tank/Silo (3 chips in one row)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 700;

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Date
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: _selectDate,
                                      borderRadius: BorderRadius.circular(9),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(9),
                                          border: Border.all(color: AppColors.cardBorder, width: 1.2),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              Formatters.formatDate(state.selectedDate),
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                            ),
                                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 2. Time (Auto recorded / Selectable)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: _selectTime,
                                      borderRadius: BorderRadius.circular(9),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(9),
                                          border: Border.all(color: AppColors.cardBorder, width: 1.2),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              state.selectedTime.format(context),
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                            ),
                                            const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 3. Tank / Silo Dropdown
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Tank / Silo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(color: AppColors.cardBorder, width: 1.2),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: state.selectedSiloId,
                                          isExpanded: true,
                                          items: state.silos.map((s) {
                                            return DropdownMenuItem(
                                              value: s.id,
                                              child: Text('${s.name} (${s.description})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                                            );
                                          }).toList(),
                                          onChanged: (newSiloId) {
                                            if (newSiloId != null) {
                                              ref.read(labProvider.notifier).setSiloId(newSiloId);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: _selectDate,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppColors.cardBorder),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(Formatters.formatDate(state.selectedDate), style: const TextStyle(fontWeight: FontWeight.w700)),
                                            const Icon(Icons.calendar_today_rounded, size: 16),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: InkWell(
                                      onTap: _selectTime,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppColors.cardBorder),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(state.selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                                            const Icon(Icons.access_time_rounded, size: 16),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(color: AppColors.cardBorder, width: 1.2),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: state.selectedSiloId,
                                    isExpanded: true,
                                    items: state.silos.map((s) {
                                      return DropdownMenuItem(
                                        value: s.id,
                                        child: Text('${s.name} (${s.description})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (newSiloId) {
                                      if (newSiloId != null) {
                                        ref.read(labProvider.notifier).setSiloId(newSiloId);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Row 2: Milk Fat (%) and Milk SNF (%)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 700;

                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Milk Fat (%)',
                                  hint: '4.30',
                                  controller: _fatController,
                                  suffixText: '%',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Milk Fat is required';
                                    final n = Formatters.parseDouble(val);
                                    if (n <= 0) return 'Must be greater than 0';
                                    if (n < 1.0 || n > 15.0) return 'Warning: Unusually high/low Fat';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTextField(
                                  label: 'Milk SNF (%)',
                                  hint: '8.33',
                                  controller: _snfController,
                                  suffixText: '%',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Milk SNF is required';
                                    final n = Formatters.parseDouble(val);
                                    if (n <= 0) return 'Must be greater than 0';
                                    if (n < 5.0 || n > 18.0) return 'Warning: Unusually high/low SNF';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              AppTextField(
                                label: 'Milk Fat (%)',
                                hint: '4.30',
                                controller: _fatController,
                                suffixText: '%',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Fat required';
                                  final n = Formatters.parseDouble(val);
                                  if (n <= 0) return 'Must be > 0';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                label: 'Milk SNF (%)',
                                hint: '8.33',
                                controller: _snfController,
                                suffixText: '%',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'SNF required';
                                  final n = Formatters.parseDouble(val);
                                  if (n <= 0) return 'Must be > 0';
                                  return null;
                                },
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Row 3: Lab Person display & Optional Remarks
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 700;

                        if (isWide) {
                          return Row(
                            children: [
                              // Lab Person (Read-only / Current User)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Lab Analyst', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(color: AppColors.cardBorder, width: 1.2),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${user.name} (${user.role})',
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTextField(
                                  label: 'Optional Remarks (Note)',
                                  hint: 'e.g. Tanker composite sample approved for processing',
                                  controller: _remarksController,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text('Analyst: ${user.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                label: 'Optional Remarks (Note)',
                                hint: 'e.g. Approved sample',
                                controller: _remarksController,
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons (Save Reading & Clear)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: Icon(state.editingTest != null ? Icons.check_rounded : Icons.save_outlined, size: 20),
                            label: Text(state.editingTest != null ? 'Update Lab Reading' : 'Save Reading'),
                            onPressed: _onSave,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _onClear,
                            child: const Text('Clear'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ===============================================================
              // 3. READING HISTORY TABLE & FILTERS
              // ===============================================================
              const SizedBox(height: 32),
              _buildHistoryTable(state, user.isSupervisor),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LATEST READINGS DASHBOARD
  // ---------------------------------------------------------------------------
  Widget _buildLatestReadingsDashboard(LabState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'LATEST READINGS DASHBOARD (TODAY)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Text(
              'Automatic Source for Milk Standardization',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final isMedium = constraints.maxWidth >= 550;

            final crossAxisCount = isWide ? 4 : (isMedium ? 2 : 1);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.silos.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 154,
              ),
              itemBuilder: (context, index) {
                final silo = state.silos[index];
                final reading = state.todayLatestBySilo[silo.id];

                return _buildSiloReadingCard(silo, reading);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSiloReadingCard(dynamic silo, LabMilkTest? reading) {
    final hasReading = reading != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasReading ? AppColors.primary.withValues(alpha: 0.3) : AppColors.cardBorder,
          width: hasReading ? 1.5 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasReading ? AppColors.primary.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Silo Name + Status Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: hasReading ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.storage_rounded,
                      color: hasReading ? AppColors.primary : AppColors.textSecondary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    silo.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (hasReading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 11),
                      SizedBox(width: 3),
                      Text(
                        'Fresh Reading',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 11),
                      SizedBox(width: 3),
                      Text(
                        'No reading today',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Fat & SNF Values
          if (hasReading)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FAT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
                      Text(
                        '${reading.fatPercentage.toStringAsFixed(2)}%',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: AppColors.divider),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SNF', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
                      Text(
                        '${reading.snfPercentage.toStringAsFixed(2)}%',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Awaiting today\'s laboratory test. Enter Fat & SNF below.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontStyle: FontStyle.italic),
              ),
            ),

          // Footer (Last tested time & analyst)
          Container(
            padding: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasReading ? 'Tested: ${reading.testTime}' : 'No sample',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                Text(
                  hasReading ? reading.labUserName : 'Pending',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // READING HISTORY TABLE
  // ---------------------------------------------------------------------------
  Widget _buildHistoryTable(LabState state, bool canManage) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'LABORATORY READING HISTORY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                StatusBadge.info('${state.filteredHistory.length} Test Records'),
              ],
            ),
          ),
          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Controls (Date, Silo, Search)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 750;

                    return Row(
                      children: [
                        Expanded(
                          flex: isWide ? 6 : 12,
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search date, silo, analyst, remarks...',
                              prefixIcon: Icon(Icons.search_rounded, size: 19),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onChanged: (val) {
                              ref.read(labProvider.notifier).setSearchQuery(val);
                            },
                          ),
                        ),
                        if (isWide) ...[
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: state.filterSiloId,
                            hint: const Text('All Silos / Tanks', style: TextStyle(fontSize: 13)),
                            items: [
                              const DropdownMenuItem(value: '', child: Text('All Silos / Tanks')),
                              ...state.silos.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                            ],
                            onChanged: (val) {
                              ref.read(labProvider.notifier).setFilterSiloId(val?.isEmpty ?? true ? null : val);
                            },
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            icon: const Icon(Icons.date_range_rounded, size: 16),
                            label: Text(
                              state.filterDate != null ? Formatters.formatDate(state.filterDate!) : 'Filter Date',
                              style: const TextStyle(fontSize: 12.5),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: state.filterDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              ref.read(labProvider.notifier).setFilterDate(picked);
                            },
                          ),
                          if (state.filterDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => ref.read(labProvider.notifier).setFilterDate(null),
                            ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Table / List of Historical Test Records
                if (state.filteredHistory.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.alertLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.alert.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 20, color: AppColors.alert),
                        SizedBox(width: 8),
                        Text('No lab readings matching current filter.', style: TextStyle(color: AppColors.alert, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.filteredHistory.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = state.filteredHistory[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.science_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.testDate,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        item.testTime,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(width: 10),
                                      StatusBadge.neutral(item.siloName, fontSize: 11),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tested by: ${item.labUserName}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  if (item.remarks.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.danger.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.sticky_note_2_rounded, size: 13, color: AppColors.danger),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              'Note: ${item.remarks.trim()}',
                                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.danger),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Fat % & SNF %
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Fat: ${item.fatPercentage.toStringAsFixed(2)}%',
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                Text(
                                  'SNF: ${item.snfPercentage.toStringAsFixed(2)}%',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            // Action Menu (Edit, Delete)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
                              onSelected: (val) async {
                                if (val == 'edit') {
                                  _loadIntoForm(item);
                                } else if (val == 'delete') {
                                  final confirm = await ConfirmationDialog.show(
                                    context: context,
                                    title: 'Delete Lab Test',
                                    message: 'Are you sure you want to permanently delete this lab test for ${item.siloName} on ${item.testDate} (${item.testTime})?',
                                    confirmLabel: 'Delete Test',
                                    isDestructive: true,
                                  );
                                  if (confirm) {
                                    ref.read(labProvider.notifier).deleteReading(item.id);
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit Reading')),
                                if (canManage)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete', style: TextStyle(color: AppColors.danger)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
