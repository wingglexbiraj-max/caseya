import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/calculation_breakdown.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/live_time_chip.dart';
import '../../core/widgets/metric_card.dart';
import '../../providers/dg_hsd_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/dg_hsd_record.dart';

class DgHsdPage extends ConsumerStatefulWidget {
  const DgHsdPage({super.key});

  @override
  ConsumerState<DgHsdPage> createState() => _DgHsdPageState();
}

class _DgHsdPageState extends ConsumerState<DgHsdPage> {
  final TextEditingController _fuelAddedController = TextEditingController();
  final TextEditingController _startPercentController = TextEditingController();
  final TextEditingController _endPercentController = TextEditingController();
  final TextEditingController _runningHoursController = TextEditingController();
  final TextEditingController _consumptionController = TextEditingController();
  final TextEditingController _kwhController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _archiveExpanded = false;
  DateTime? _filterDate;


  @override
  void dispose() {
    _fuelAddedController.dispose();
    _startPercentController.dispose();
    _endPercentController.dispose();
    _runningHoursController.dispose();
    _consumptionController.dispose();
    _kwhController.dispose();
    _remarksController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final double startPct = Formatters.parseDouble(_startPercentController.text);
    final double endPct = Formatters.parseDouble(_endPercentController.text);
    final double added = Formatters.parseDouble(_fuelAddedController.text);

    ref.read(dgHsdProvider.notifier).setFuelAdded(added);
    ref.read(dgHsdProvider.notifier).setStartPercentage(startPct);
    ref.read(dgHsdProvider.notifier).setEndPercentage(endPct);
    ref.read(dgHsdProvider.notifier).setRunningHours(Formatters.parseDouble(_runningHoursController.text));
    ref.read(dgHsdProvider.notifier).setKwh(Formatters.parseDouble(_kwhController.text));
    ref.read(dgHsdProvider.notifier).setRemarks(_remarksController.text.trim());
    ref.read(dgHsdProvider.notifier).setFuelConsumption(Formatters.parseDouble(_consumptionController.text));
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      final user = ref.read(authProvider);
      final success = await ref.read(dgHsdProvider.notifier).saveOrUpdateRecord(
            employeeId: user.employeeCode,
            employeeName: user.name,
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ DG HSD fuel and generation entry saved.'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
        if (ref.read(dgHsdProvider).editingRecord == null) {
          _remarksController.clear();
          _fuelAddedController.clear();
          _startPercentController.clear();
          _endPercentController.clear();
          _runningHoursController.clear();
          _consumptionController.clear();
          _kwhController.clear();
        }
      }
    }
  }

  void _loadRecordIntoForm(DgHsdRecord record) {
    ref.read(dgHsdProvider.notifier).startEditing(record);
    setState(() {
      _fuelAddedController.text = Formatters.formatSmart(record.fuelAdded);
      _startPercentController.text = Formatters.formatSmart(record.startPercentage);
      _endPercentController.text = Formatters.formatSmart(record.endPercentage);
      _runningHoursController.text = Formatters.formatSmart(record.runningHours);
      _consumptionController.text = Formatters.formatSmart(record.fuelConsumption);
      _kwhController.text = Formatters.formatSmart(record.kwh);
      _remarksController.text = record.remarks;
    });
  }

  void _cancelEditing() {
    ref.read(dgHsdProvider.notifier).cancelEditing();
    setState(() {
      _fuelAddedController.clear();
      _startPercentController.clear();
      _endPercentController.clear();
      _runningHoursController.clear();
      _consumptionController.clear();
      _kwhController.clear();
      _remarksController.clear();
    });
  }

  Future<void> _selectDate() async {
    final current = ref.read(dgHsdProvider).selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      ref.read(dgHsdProvider.notifier).setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dgHsdProvider);
    final user = ref.watch(authProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

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
              if (state.editingRecord != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusBadge.warning('Editing ${state.editingRecord!.recordId}'),
                    OutlinedButton(
                      onPressed: _cancelEditing,
                      child: const Text('Cancel Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

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
                          style: const TextStyle(color: AppColors.danger, fontSize: AppTextSizes.body, fontWeight: AppFontWeights.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Data Entry Heading (Outside the Card)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.electric_bolt_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'DG SHIFT FUEL LOGGING',
                    style: TextStyle(
                      fontSize: AppTextSizes.subheading,
                      fontWeight: AppFontWeights.bold,
                      letterSpacing: 0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  StatusBadge.info(state.selectedShift),
                ],
              ),
              const SizedBox(height: 12),

              // Data Entry Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Row 1: Date, Shift, and Fuel Added (3 chips in one row)
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
                                    const Text('Date', style: TextStyle(fontSize: AppTextSizes.body, fontWeight: AppFontWeights.bold)),
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
                                              style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: AppTextSizes.body),
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

                              // 2. Time
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Time', style: TextStyle(fontSize: AppTextSizes.body, fontWeight: AppFontWeights.bold)),
                                    const SizedBox(height: 6),
                                    LiveTimeChip(
                                      selectedTime: state.selectedTime,
                                      isLiveTime: state.isLiveTime,
                                      isMobile: false,
                                      onTimeChanged: (newTime) {
                                        ref.read(dgHsdProvider.notifier).setTime(newTime);
                                      },
                                      onResetToLive: () {
                                        ref.read(dgHsdProvider.notifier).resetToLiveTime();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 3. Fuel Added (Top-up)
                              Expanded(
                                child: AppTextField(
                                  label: 'Fuel Added / Top-up (L)',
                                  hint: 'e.g., 100',
                                  controller: _fuelAddedController,
                                  suffixText: 'Litres',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => _onFieldChanged(),
                                  validator: (val) {
                                    if (val != null && val.trim().isNotEmpty) {
                                      final n = Formatters.parseDouble(val);
                                      if (n < 0) return 'Top-up litres cannot be negative';
                                    }
                                    final startPct = Formatters.parseDouble(_startPercentController.text);
                                    final topUp = Formatters.parseDouble(val ?? '0');
                                    final openingL = (startPct / 100.0) * AppConstants.DG_TANK_CAPACITY;
                                    if (openingL + topUp > AppConstants.DG_TANK_CAPACITY) {
                                      return 'Fuel after top-up exceeds 380 L';
                                    }
                                    return null;
                                  },
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Date', style: TextStyle(fontSize: AppTextSizes.body, fontWeight: AppFontWeights.bold)),
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
                                                  style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: AppTextSizes.body),
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Time', style: TextStyle(fontSize: AppTextSizes.body, fontWeight: AppFontWeights.bold)),
                                        const SizedBox(height: 6),
                                        LiveTimeChip(
                                          selectedTime: state.selectedTime,
                                          isLiveTime: state.isLiveTime,
                                          isMobile: true,
                                          onTimeChanged: (newTime) {
                                            ref.read(dgHsdProvider.notifier).setTime(newTime);
                                          },
                                          onResetToLive: () {
                                            ref.read(dgHsdProvider.notifier).resetToLiveTime();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                label: 'Fuel Added / Top-up (L)',
                                hint: 'e.g., 100',
                                controller: _fuelAddedController,
                                suffixText: 'Litres',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => _onFieldChanged(),
                                validator: (val) {
                                  if (val != null && val.trim().isNotEmpty) {
                                    final n = Formatters.parseDouble(val);
                                    if (n < 0) return 'Top-up litres cannot be negative';
                                  }
                                  final startPct = Formatters.parseDouble(_startPercentController.text);
                                  final topUp = Formatters.parseDouble(val ?? '0');
                                  final openingL = (startPct / 100.0) * AppConstants.DG_TANK_CAPACITY;
                                  if (openingL + topUp > AppConstants.DG_TANK_CAPACITY) {
                                    return 'Fuel after top-up exceeds 380 L';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Row 2: Opening Level (%), Closing Level (%), Shift Running Hours
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 700;

                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Opening Fuel Level (%)',
                                  hint: 'e.g., 25',
                                  controller: _startPercentController,
                                  suffixText: '%',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => _onFieldChanged(),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Opening % required';
                                    final n = Formatters.parseDouble(val);
                                    if (n < 0 || n > 100) return 'Must be 0-100%';
                                    final topUp = Formatters.parseDouble(_fuelAddedController.text);
                                    final openingL = (n / 100.0) * AppConstants.DG_TANK_CAPACITY;
                                    if (openingL + topUp > AppConstants.DG_TANK_CAPACITY) {
                                      return 'Fuel after top-up exceeds 380 L';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTextField(
                                  label: 'Closing Fuel Level (%)',
                                  hint: 'e.g., 15',
                                  controller: _endPercentController,
                                  suffixText: '%',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => _onFieldChanged(),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Closing % required';
                                    final n = Formatters.parseDouble(val);
                                    if (n < 0 || n > 100) return 'Must be 0-100%';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTextField(
                                  label: 'Shift Running Hours',
                                  hint: 'e.g., 3.5',
                                  controller: _runningHoursController,
                                  suffixText: 'Hours',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => _onFieldChanged(),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Running hours required';
                                    final n = Formatters.parseDouble(val);
                                    if (n <= 0) return 'Must be > 0';
                                    return null;
                                  },
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
                                    child: AppTextField(
                                      label: 'Opening %',
                                      hint: 'e.g., 25',
                                      controller: _startPercentController,
                                      suffixText: '%',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (_) => _onFieldChanged(),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) return 'Opening % required';
                                        final n = Formatters.parseDouble(val);
                                        if (n < 0 || n > 100) return 'Must be 0-100%';
                                        final topUp = Formatters.parseDouble(_fuelAddedController.text);
                                        final openingL = (n / 100.0) * AppConstants.DG_TANK_CAPACITY;
                                        if (openingL + topUp > AppConstants.DG_TANK_CAPACITY) {
                                          return 'Fuel after top-up exceeds 380 L';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Closing %',
                                      hint: 'e.g., 15',
                                      controller: _endPercentController,
                                      suffixText: '%',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (_) => _onFieldChanged(),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) return 'Closing % required';
                                        final n = Formatters.parseDouble(val);
                                        if (n < 0 || n > 100) return 'Must be 0-100%';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                label: 'Shift Running Hours',
                                hint: 'e.g., 3.5',
                                controller: _runningHoursController,
                                suffixText: 'Hours',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => _onFieldChanged(),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Running hours required';
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

                    // Row 3: Total Fuel Consumed (Manual Input) & Energy Generated (Manual Input)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 700;

                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Total Fuel Consumed (Manual Input)',
                                  hint: 'e.g., 138',
                                  controller: _consumptionController,
                                  suffixText: 'Litres',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => _onFieldChanged(),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Total fuel consumed required';
                                    final n = Formatters.parseDouble(val);
                                    if (n < 0) return 'Cannot be negative';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTextField(
                                  label: 'Energy Generated (Manual Input)',
                                  hint: 'e.g., 175',
                                  controller: _kwhController,
                                  suffixText: 'kWh',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => _onFieldChanged(),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'kWh required';
                                    final n = Formatters.parseDouble(val);
                                    if (n < 0) return 'Cannot be negative';
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
                                label: 'Total Fuel Consumed (Manual Input)',
                                hint: 'e.g., 138',
                                controller: _consumptionController,
                                suffixText: 'Litres',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => _onFieldChanged(),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Total fuel consumed required';
                                  final n = Formatters.parseDouble(val);
                                  if (n < 0) return 'Cannot be negative';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                label: 'Energy Generated (Manual Input)',
                                hint: 'e.g., 175',
                                controller: _kwhController,
                                suffixText: 'kWh',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => _onFieldChanged(),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'kWh required';
                                  final n = Formatters.parseDouble(val);
                                  if (n < 0) return 'Cannot be negative';
                                  return null;
                                },
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Calculation Metrics Section Header (Product Calculator style)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.analytics_outlined,
                            size: 16,
                            color: Colors.black.withValues(alpha: 0.60),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'CALCULATION METRICS',
                          style: TextStyle(
                            fontSize: AppTextSizes.caption,
                            fontWeight: AppFontWeights.bold,
                            letterSpacing: 0.6,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '• Tank: 380 L  •  1% = 3.8 L',
                            style: TextStyle(
                              fontSize: AppTextSizes.caption,
                              fontWeight: AppFontWeights.medium,
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTankFuelCalculationDisplay(state),
                    const SizedBox(height: 12),
                    _buildLiveDgChips(state),
                    const SizedBox(height: 14),

                    // Note (optional, shown in red in history if written)
                    AppTextField(
                      label: 'Note',
                      hint: 'e.g. DG operated for cold room and pasteurizer during grid outage',
                      controller: _remarksController,
                      onChanged: (_) => _onFieldChanged(),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons (Record DG Entry & Clear)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            icon: Icon(
                              state.editingRecord != null ? Icons.check_rounded : Icons.save_outlined,
                              size: 20,
                            ),
                            label: Text(
                              state.editingRecord != null ? 'Update DG Record' : 'Record DG Entry',
                              style: const TextStyle(
                                fontSize: AppTextSizes.body,
                                fontWeight: AppFontWeights.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            onPressed: _onSave,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEF2F2),
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(
                                color: Color(0xFFFCA5A5),
                                width: 1.2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            onPressed: _cancelEditing,
                            child: const Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: AppTextSizes.body,
                                fontWeight: AppFontWeights.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Collapsible step-by-step breakdown (Product Calculator style)
              if (state.liveResult != null) ...[
                const SizedBox(height: 20),
                CalculationBreakdownCard(
                  title: 'How was DG efficiency and fuel rate calculated?',
                  steps: state.liveResult!.breakdownSteps,
                ),
              ],

              // Date-Wise History Table & Filters (Default Collapsed)
              const SizedBox(height: 32),
              _buildHistorySection(state, user.isSupervisor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTankFuelCalculationDisplay(DgHsdState state) {
    final result = state.liveResult;
    final double capacity = AppConstants.DG_TANK_CAPACITY;
    final double openingL = result?.openingLitres ?? ((state.startPercentage / 100.0) * capacity);
    final double topUpL = state.fuelAdded;
    final double levelAfterTopUpL = result?.fuelAfterTopUp ?? (openingL + topUpL);
    final double pctAfterTopUp = result?.percentageAfterTopUp ?? (capacity > 0 ? (levelAfterTopUpL / capacity) * 100.0 : 0.0);
    final double closingL = result?.closingLitres ?? ((state.endPercentage / 100.0) * capacity);
    final double consumedL = result?.consumedLitres ?? (openingL + topUpL - closingL);
    final bool hasTopUp = topUpL > 0;
    final bool exceeds = hasTopUp && (result?.exceedsCapacity ?? (levelAfterTopUpL > capacity));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overflow Alert Banner if exceeds 380 L
        if (exceeds) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Calculated level after top-up (${Formatters.formatSmart(levelAfterTopUpL)} L / ${Formatters.formatDecimal(pctAfterTopUp)}%) exceeds DG tank capacity of ${capacity.toInt()} L!',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: AppTextSizes.caption,
                      fontWeight: AppFontWeights.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // 5 Tank Metrics as MetricCard tiles (Product Calculator style)
        LayoutBuilder(
          builder: (context, constraints) {
            final cardOpening = MetricCard(
              title: 'Opening Level',
              value: '${Formatters.formatSmart(state.startPercentage)}% (${Formatters.formatSmart(openingL)} L)',
              unit: '',
              subtitle: 'Initial Shift Level',
              icon: Icons.login_rounded,
              iconColor: Colors.black.withValues(alpha: 0.60),
              iconBgColor: Colors.black.withValues(alpha: 0.06),
              cardBgColor: const Color(0xFFECFDF5),
            );

            final cardFuelAdded = MetricCard(
              title: 'Fuel Added',
              value: hasTopUp ? '${Formatters.formatSmart(topUpL)} L' : '—',
              unit: '',
              subtitle: hasTopUp ? '+${Formatters.formatDecimal(topUpL / capacity * 100)}%' : 'No Top-up',
              icon: Icons.add_circle_outline_rounded,
              iconColor: Colors.black.withValues(alpha: 0.60),
              iconBgColor: Colors.black.withValues(alpha: 0.06),
              cardBgColor: const Color(0xFFFFFBEB),
            );

            final cardAfterTopUp = MetricCard(
              title: 'Level After Top-up',
              value: hasTopUp
                  ? '${Formatters.formatDecimal(pctAfterTopUp)}% (${Formatters.formatSmart(levelAfterTopUpL)} L)'
                  : '—',
              unit: '',
              subtitle: hasTopUp
                  ? (exceeds ? 'Exceeds 380 L!' : 'Tank After Fill')
                  : 'No Top-up Added',
              icon: Icons.local_gas_station_rounded,
              iconColor: hasTopUp && exceeds ? AppColors.danger : Colors.black.withValues(alpha: 0.60),
              iconBgColor: hasTopUp && exceeds ? AppColors.dangerLight : Colors.black.withValues(alpha: 0.06),
              cardBgColor: hasTopUp && exceeds
                  ? const Color(0xFFFEF2F2)
                  : (hasTopUp ? const Color(0xFFEFF6FF) : const Color(0xFFF9FAFB)),
            );

            final cardClosing = MetricCard(
              title: 'Closing Level',
              value: '${Formatters.formatSmart(state.endPercentage)}% (${Formatters.formatSmart(closingL)} L)',
              unit: '',
              subtitle: 'Ending Shift Level',
              icon: Icons.logout_rounded,
              iconColor: Colors.black.withValues(alpha: 0.60),
              iconBgColor: Colors.black.withValues(alpha: 0.06),
              cardBgColor: const Color(0xFFF5F3FF),
            );

            final cardConsumed = MetricCard(
              title: 'Level Difference',
              value: '${Formatters.formatSmart(consumedL >= 0 ? consumedL : 0)} L',
              unit: '',
              subtitle: 'Open + Add - Close',
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.black.withValues(alpha: 0.60),
              iconBgColor: Colors.black.withValues(alpha: 0.06),
              cardBgColor: const Color(0xFFECFDF5),
            );

            if (constraints.maxWidth >= 700) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cardOpening),
                    const SizedBox(width: 12),
                    Expanded(child: cardFuelAdded),
                    const SizedBox(width: 12),
                    Expanded(child: cardAfterTopUp),
                    const SizedBox(width: 12),
                    Expanded(child: cardClosing),
                    const SizedBox(width: 12),
                    Expanded(child: cardConsumed),
                  ],
                ),
              );
            } else {
              final itemWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(width: itemWidth, child: cardOpening),
                  SizedBox(width: itemWidth, child: cardFuelAdded),
                  SizedBox(width: itemWidth, child: cardAfterTopUp),
                  SizedBox(width: itemWidth, child: cardClosing),
                  SizedBox(width: itemWidth, child: cardConsumed),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildLiveDgChips(DgHsdState state) {
    final result = state.liveResult;
    final double fuelConsumption = result?.fuelConsumption ?? 0.0;
    final double unitsPerLitre = result?.unitsPerLitre ?? 0.0;
    final double burnRate = result?.consumptionPerHour ?? 0.0;

    final double percentageDrop = state.startPercentage - state.endPercentage;
    final double remainingFuel = (percentageDrop > 0 && fuelConsumption > 0)
        ? (fuelConsumption / percentageDrop) * state.endPercentage
        : (state.endPercentage > 0 ? (state.endPercentage / 100.0) * AppConstants.DG_TANK_CAPACITY : 0.0);
    final double estimatedRuntime = burnRate > 0 ? (remainingFuel / burnRate) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardFuel = MetricCard(
          title: 'Total Fuel Consumed',
          value: result != null && fuelConsumption > 0 ? Formatters.formatSmart(fuelConsumption) : '—',
          unit: 'Litres',
          subtitle: 'Manual Shift Entry',
          icon: Icons.local_gas_station_rounded,
          iconColor: Colors.black.withValues(alpha: 0.60),
          iconBgColor: Colors.black.withValues(alpha: 0.06),
          cardBgColor: const Color(0xFFECFDF5),
        );

        final cardRate = MetricCard(
          title: 'Consumption Rate',
          value: result != null ? Formatters.formatDecimal(burnRate) : '—',
          unit: 'L/hr',
          subtitle: 'Hourly burn rate',
          icon: Icons.speed_rounded,
          iconColor: Colors.black.withValues(alpha: 0.60),
          iconBgColor: Colors.black.withValues(alpha: 0.06),
          cardBgColor: const Color(0xFFFFFBEB),
        );

        final cardEfficiency = MetricCard(
          title: 'Efficiency Yield',
          value: result != null ? Formatters.formatDecimal(unitsPerLitre) : '—',
          unit: 'kWh/L',
          subtitle: 'Units per litre diesel',
          icon: Icons.electric_bolt_rounded,
          iconColor: Colors.black.withValues(alpha: 0.60),
          iconBgColor: Colors.black.withValues(alpha: 0.06),
          cardBgColor: const Color(0xFFEFF6FF),
        );

        final cardRuntime = MetricCard(
          title: 'Estimated Runtime',
          value: estimatedRuntime > 0 ? '${Formatters.formatDecimal(estimatedRuntime)} hrs' : '—',
          unit: '',
          subtitle: 'Remaining fuel runtime',
          icon: Icons.hourglass_top_rounded,
          iconColor: Colors.black.withValues(alpha: 0.60),
          iconBgColor: Colors.black.withValues(alpha: 0.06),
          cardBgColor: const Color(0xFFF5F3FF),
        );

        if (constraints.maxWidth >= 700) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cardFuel),
                const SizedBox(width: 12),
                Expanded(child: cardRate),
                const SizedBox(width: 12),
                Expanded(child: cardEfficiency),
                const SizedBox(width: 12),
                Expanded(child: cardRuntime),
              ],
            ),
          );
        } else {
          final itemWidth = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: itemWidth, child: cardFuel),
              SizedBox(width: itemWidth, child: cardRate),
              SizedBox(width: itemWidth, child: cardEfficiency),
              SizedBox(width: itemWidth, child: cardRuntime),
            ],
          );
        }
      },
    );
  }

  Widget _buildHistorySection(DgHsdState state, bool canManage) {
    final filteredRecords = state.filteredRecords.where((item) {
      if (_filterDate != null) {
        final itemDate = item.date;
        final iso = Formatters.formatIsoDate(_filterDate!);
        final formatted = Formatters.formatDate(_filterDate!);
        if (itemDate != iso && !itemDate.contains(formatted)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading OUTSIDE of card (matching Milk Standardization History style)
        InkWell(
          onTap: () => setState(() => _archiveExpanded = !_archiveExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 20,
                        color: Colors.black.withValues(alpha: 0.60),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'DG HSD ENTRIES HISTORY',
                      style: TextStyle(
                        fontSize: AppTextSizes.subheading,
                        fontWeight: AppFontWeights.bold,
                        letterSpacing: 0.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusBadge.info(
                      state.allRecords.isEmpty
                          ? '0 Saved Records'
                          : '${filteredRecords.length} Saved Records',
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.cardBorderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _archiveExpanded ? 'Collapse' : 'Expand',
                            style: const TextStyle(
                              fontSize: AppTextSizes.caption,
                              fontWeight: AppFontWeights.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _archiveExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_archiveExpanded) ...[
          const SizedBox(height: 12),
          Container(
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 4, color: AppColors.primary),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filter Controls (Matching Milk Standardization History)
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildShiftFilterChip(state),
                            _buildDateFilterChip(),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Entries List
                        if (filteredRecords.isEmpty) ...[
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
                                Text(
                                  'No DG HSD records matching current filter.',
                                  style: TextStyle(color: AppColors.alert, fontWeight: AppFontWeights.bold),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredRecords.length,
                            separatorBuilder: (_, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = filteredRecords[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Numbered index badge circle (Milk Standardization style)
                                    Container(
                                      width: 32,
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primary.withValues(alpha: 0.20),
                                          width: 1.1,
                                        ),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: AppFontWeights.bold,
                                          fontSize: AppTextSizes.caption,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // 1. Date, Shift & Time
                                          Row(
                                            children: [
                                              Text(
                                                item.date,
                                                style: const TextStyle(
                                                  fontWeight: AppFontWeights.bold,
                                                  fontSize: AppTextSizes.body,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              StatusBadge.neutral(item.shift, fontSize: AppTextSizes.caption),
                                              if (item.time.isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                Text(
                                                  item.time,
                                                  style: const TextStyle(
                                                    fontSize: AppTextSizes.caption,
                                                    fontWeight: AppFontWeights.medium,
                                                    color: AppColors.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),

                                          // 2. Consumption and Generation metrics
                                          Text(
                                            'Consumption: ${Formatters.formatSmart(item.fuelConsumption)} L • Power: ${Formatters.formatSmart(item.kwh)} kWh (${Formatters.formatDecimal(item.unitsPerLitre)} kWh/L) • Rate: ${Formatters.formatDecimal(item.consumptionPerHour)} L/hr • Running: ${Formatters.formatSmart(item.runningHours)} hr',
                                            style: const TextStyle(
                                              fontSize: AppTextSizes.caption,
                                              fontWeight: AppFontWeights.medium,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),

                                          // 3. Tank levels and operator
                                          Text(
                                            'Tank: ${Formatters.formatSmart(item.startPercentage)}% → ${Formatters.formatSmart(item.endPercentage)}% (Drop ${Formatters.formatSmart(item.percentageDrop)}%)${item.fuelAdded > 0 ? ' • Fuel Added: ${Formatters.formatSmart(item.fuelAdded)} L' : ''} • Logged by: ${item.employeeName.isNotEmpty ? item.employeeName : (item.employeeId.isNotEmpty ? item.employeeId : 'DG Operator')}',
                                            style: const TextStyle(
                                              fontSize: AppTextSizes.caption,
                                              fontWeight: AppFontWeights.medium,
                                              color: AppColors.textMuted,
                                            ),
                                          ),

                                          // 4. Shift Note (if any)
                                          if (item.remarks.trim().isNotEmpty) ...[
                                            const SizedBox(height: 5),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.danger.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.sticky_note_2_rounded, size: 14, color: AppColors.danger),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      'Note: ${item.remarks.trim()}',
                                                      style: const TextStyle(
                                                        fontSize: AppTextSizes.caption,
                                                        fontWeight: AppFontWeights.bold,
                                                        color: AppColors.danger,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${Formatters.formatSmart(item.fuelConsumption)} L',
                                          style: const TextStyle(
                                            fontSize: AppTextSizes.body,
                                            fontWeight: AppFontWeights.bold,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                        Text(
                                          '${Formatters.formatSmart(item.kwh)} kWh',
                                          style: const TextStyle(
                                            fontSize: AppTextSizes.caption,
                                            color: AppColors.textSecondary,
                                            fontWeight: AppFontWeights.semiBold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 6),
                                    // Actions Popup Menu (Matching Milk Standardization style)
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
                                      tooltip: 'Actions',
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      onSelected: (val) async {
                                        if (val == 'edit') {
                                          _loadRecordIntoForm(item);
                                        } else if (val == 'delete') {
                                          final confirm = await ConfirmationDialog.show(
                                            context: context,
                                            title: 'Delete DG HSD Record',
                                            message: 'Are you sure you want to permanently delete DG entry ${item.recordId} from ${item.date} (${item.shift})?',
                                            confirmLabel: 'Delete Record',
                                            isDestructive: true,
                                          );
                                          if (confirm) {
                                            ref.read(dgHsdProvider.notifier).deleteRecord(item.recordId);
                                          }
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem<String>(
                                          value: 'edit',
                                          height: 38,
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                                              SizedBox(width: 8),
                                              Text(
                                                'Edit Entry',
                                                style: TextStyle(
                                                  fontSize: AppTextSizes.caption,
                                                  fontWeight: AppFontWeights.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (canManage) ...[
                                          const PopupMenuDivider(height: 1),
                                          const PopupMenuItem<String>(
                                            value: 'delete',
                                            height: 38,
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Delete Record',
                                                  style: TextStyle(
                                                    fontSize: AppTextSizes.caption,
                                                    fontWeight: AppFontWeights.bold,
                                                    color: AppColors.danger,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateFilterChip() {
    final isToday = _filterDate != null &&
        Formatters.formatDate(_filterDate!) == Formatters.formatDate(DateTime.now());

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _filterDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (picked != null) {
              setState(() {
                _filterDate = picked;
              });
            }
          },
          borderRadius: BorderRadius.circular(9),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.cardBorder, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _filterDate != null
                      ? (isToday
                          ? 'Today (${Formatters.formatDate(_filterDate!)})'
                          : Formatters.formatDate(_filterDate!))
                      : 'All Dates',
                  style: TextStyle(
                    fontWeight: AppFontWeights.bold,
                    fontSize: AppTextSizes.body,
                    color: _filterDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_filterDate != null) ...[
          const SizedBox(width: 6),
          InkWell(
            onTap: () => setState(() => _filterDate = null),
            borderRadius: BorderRadius.circular(9),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Clear Date',
                    style: TextStyle(
                      fontSize: AppTextSizes.caption,
                      fontWeight: AppFontWeights.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShiftFilterChip(DgHsdState state) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 17,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: state.filterShift ?? '',
              isDense: true,
              icon: const Icon(
                Icons.arrow_drop_down_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text(
                    'All Shifts',
                    style: TextStyle(
                      fontSize: AppTextSizes.body,
                      fontWeight: AppFontWeights.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ...AppConstants.shifts.map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      s,
                      style: const TextStyle(
                        fontSize: AppTextSizes.body,
                        fontWeight: AppFontWeights.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
              onChanged: (val) {
                ref.read(dgHsdProvider.notifier).setFilterShift(val?.isEmpty ?? true ? null : val);
              },
            ),
          ),
        ],
      ),
    );
  }
}
