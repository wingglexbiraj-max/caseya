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
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/live_time_chip.dart';
import '../../providers/boiler_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/boiler_record.dart';

class BoilerPage extends ConsumerStatefulWidget {
  const BoilerPage({super.key});

  @override
  ConsumerState<BoilerPage> createState() => _BoilerPageState();
}

class _BoilerPageState extends ConsumerState<BoilerPage> {
  final TextEditingController _openingController = TextEditingController();
  final TextEditingController _closingController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _topUpController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _archiveExpanded = false;


  @override
  void dispose() {
    _openingController.dispose();
    _closingController.dispose();
    _hoursController.dispose();
    _topUpController.dispose();
    _remarksController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    ref.read(boilerProvider.notifier).setOpeningCm(Formatters.parseDouble(_openingController.text));
    ref.read(boilerProvider.notifier).setClosingCm(Formatters.parseDouble(_closingController.text));
    ref.read(boilerProvider.notifier).setRunningHours(Formatters.parseDouble(_hoursController.text));
    ref.read(boilerProvider.notifier).setFuelTopUp(Formatters.parseDouble(_topUpController.text));
    ref.read(boilerProvider.notifier).setRemarks(_remarksController.text.trim());
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      final user = ref.read(authProvider);
      final success = await ref.read(boilerProvider.notifier).saveOrUpdateRecord(
            employeeId: user.employeeCode,
            employeeName: user.name,
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Boiler fuel entry saved to date-wise log.'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
        if (ref.read(boilerProvider).editingRecord == null) {
          _remarksController.clear();
          _topUpController.clear();
          _openingController.clear();
          _closingController.clear();
          _hoursController.clear();
        }
      }
    }
  }

  void _loadRecordIntoForm(BoilerRecord record) {
    ref.read(boilerProvider.notifier).startEditing(record);
    setState(() {
      _openingController.text = Formatters.formatSmart(record.openingCm);
      _closingController.text = Formatters.formatSmart(record.closingCm);
      _hoursController.text = Formatters.formatSmart(record.runningHours);
      _topUpController.text = Formatters.formatSmart(record.fuelTopUp);
      _remarksController.text = record.remarks;
    });
  }

  void _cancelEditing() {
    ref.read(boilerProvider.notifier).cancelEditing();
    setState(() {
      _openingController.clear();
      _closingController.clear();
      _hoursController.clear();
      _topUpController.clear();
      _remarksController.clear();
    });
  }

  Future<void> _selectDate() async {
    final current = ref.read(boilerProvider).selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      ref.read(boilerProvider.notifier).setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(boilerProvider);
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

              // Shift Fuel Logging Section Header (Product Calculator style)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'SHIFT FUEL LOGGING',
                        style: TextStyle(
                          fontSize: AppTextSizes.subheading,
                          fontWeight: AppFontWeights.bold,
                          letterSpacing: 0.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge.info(state.selectedShift),
                ],
              ),
              const SizedBox(height: 12),

              // Data Entry Card (Product Calculator style clean AppCard)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Row 1: Date, Shift, and Fuel Top-up (3 chips in one row)
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
                                        ref.read(boilerProvider.notifier).setTime(newTime);
                                      },
                                      onResetToLive: () {
                                        ref.read(boilerProvider.notifier).resetToLiveTime();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 3. Fuel Top-up
                              Expanded(
                                child: AppTextField(
                                  label: 'Fuel Top-up',
                                  hint: 'e.g., 0',
                                  controller: _topUpController,
                                  suffixText: 'Litres',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => _onFieldChanged(),
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
                                            ref.read(boilerProvider.notifier).setTime(newTime);
                                          },
                                          onResetToLive: () {
                                            ref.read(boilerProvider.notifier).resetToLiveTime();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                label: 'Fuel Top-up',
                                hint: 'e.g., 0',
                                controller: _topUpController,
                                suffixText: 'Litres',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => _onFieldChanged(),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Row 2: Opening CM, Closing CM, Running Hours
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 700;

                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Opening Fuel Level',
                                  hint: 'e.g., 500',
                                  controller: _openingController,
                                  suffixText: 'CM',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => _onFieldChanged(),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Opening CM cannot be empty';
                                    final n = Formatters.parseDouble(val);
                                    if (n < 0) return 'Cannot be negative';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTextField(
                                  label: 'Closing Fuel Level',
                                  hint: 'e.g., 430',
                                  controller: _closingController,
                                  suffixText: 'CM',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => _onFieldChanged(),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Closing CM cannot be empty';
                                    final n = Formatters.parseDouble(val);
                                    if (n < 0) return 'Cannot be negative';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTextField(
                                  label: 'Running Hours',
                                  hint: 'e.g., 8.5',
                                  controller: _hoursController,
                                  suffixText: 'Hours',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => _onFieldChanged(),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Running hours required';
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
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Opening Level',
                                      hint: 'e.g., 500',
                                      controller: _openingController,
                                      suffixText: 'CM',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (_) => _onFieldChanged(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Closing Level',
                                      hint: 'e.g., 430',
                                      controller: _closingController,
                                      suffixText: 'CM',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (_) => _onFieldChanged(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                label: 'Running Hours',
                                hint: 'e.g., 8.5',
                                controller: _hoursController,
                                suffixText: 'Hours',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => _onFieldChanged(),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Boiler Consumption Result Section Header (in place of old fuel consumption chip)
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
                          'BOILER CONSUMPTION RESULT',
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
                            '• Formula: ((Opening CM - Closing CM) × 900) ÷ 70',
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
                    _buildLiveFuelMetrics(state),
                    const SizedBox(height: 14),

                    // Note (Renamed from Remarks / Observations)
                    AppTextField(
                      label: 'Note',
                      hint: 'e.g. Normal steam pressure maintained across shift',
                      controller: _remarksController,
                      onChanged: (_) => _onFieldChanged(),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons (Record Boiler Entry & Clear)
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
                              state.editingRecord != null ? 'Update Boiler Record' : 'Record Boiler Entry',
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
                  title: 'How was boiler consumption calculated?',
                  steps: state.liveResult!.breakdownSteps,
                ),
              ],

              // Date-Wise History Table & Filters
              const SizedBox(height: 32),
              _buildHistorySection(state, user.isSupervisor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveFuelMetrics(BoilerState state) {
    final result = state.liveResult;
    final double levelConsumption = result?.calculatedLevelConsumption ?? 0.0;
    final double levelDrop = (result != null)
        ? (result.openingCm - result.closingCm)
        : (state.openingCm - state.closingCm);
    final double burnRate = result?.consumptionPerHour ?? 0.0;
    final double topUp = result?.fuelTopUp ?? state.fuelTopUp;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardConsumption = MetricCard(
          title: 'Fuel Consumed',
          value: result != null ? Formatters.formatSmart(levelConsumption) : '—',
          unit: 'Litres',
          subtitle: 'Calculated boiler burn',
          icon: Icons.local_fire_department_rounded,
          iconColor: Colors.black.withValues(alpha: 0.60),
          iconBgColor: Colors.black.withValues(alpha: 0.06),
          cardBgColor: const Color(0xFFECFDF5), // Soft Emerald
        );

        final cardDrop = MetricCard(
          title: 'Level Difference',
          value: result != null ? Formatters.formatSmart(levelDrop) : '—',
          unit: 'CM',
          subtitle: '${Formatters.formatSmart(state.openingCm)} → ${Formatters.formatSmart(state.closingCm)} CM',
          icon: Icons.height_rounded,
          iconColor: Colors.black.withValues(alpha: 0.60),
          iconBgColor: Colors.black.withValues(alpha: 0.06),
          cardBgColor: const Color(0xFFEFF6FF), // Soft Blue
        );

        final cardBurnRate = MetricCard(
          title: 'Fuel Burn Rate',
          value: result != null ? Formatters.formatDecimal(burnRate) : '—',
          unit: 'L/hr',
          subtitle: state.runningHours > 0 ? 'Hourly consumption rate' : 'Awaiting running hours',
          icon: Icons.speed_rounded,
          iconColor: Colors.black.withValues(alpha: 0.60),
          iconBgColor: Colors.black.withValues(alpha: 0.06),
          cardBgColor: const Color(0xFFFFFBEB), // Soft Amber
        );

        final cardTopUp = MetricCard(
          title: 'Fuel Top-up',
          value: Formatters.formatSmart(topUp),
          unit: 'Litres',
          subtitle: topUp > 0 ? 'Added during shift' : 'No top-up logged',
          icon: Icons.add_circle_outline_rounded,
          iconColor: Colors.black.withValues(alpha: 0.60),
          iconBgColor: Colors.black.withValues(alpha: 0.06),
          cardBgColor: const Color(0xFFF5F3FF), // Soft Purple
        );

        if (constraints.maxWidth >= 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cardConsumption),
              const SizedBox(width: 12),
              Expanded(child: cardDrop),
              const SizedBox(width: 12),
              Expanded(child: cardBurnRate),
              const SizedBox(width: 12),
              Expanded(child: cardTopUp),
            ],
          );
        } else {
          final itemWidth = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: itemWidth, child: cardConsumption),
              SizedBox(width: itemWidth, child: cardDrop),
              SizedBox(width: itemWidth, child: cardBurnRate),
              SizedBox(width: itemWidth, child: cardTopUp),
            ],
          );
        }
      },
    );
  }

  Widget _buildHistorySection(BoilerState state, bool canManage) {
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
                      'BOILER ENTRIES HISTORY',
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
                          : '${state.filteredRecords.length} Saved Records',
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
                            _buildDateFilterChip(state),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Entries List
                        if (state.filteredRecords.isEmpty) ...[
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
                                  'No boiler records matching current filter.',
                                  style: TextStyle(color: AppColors.alert, fontWeight: AppFontWeights.bold),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.filteredRecords.length,
                            separatorBuilder: (_, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = state.filteredRecords[index];
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

                                          // 2. Consumption and Level metrics
                                          Text(
                                            'Consumption: ${Formatters.formatSmart(item.netReportedConsumption)} L • Rate: ${Formatters.formatDecimal(item.consumptionPerHour)} L/hr • Level: ${Formatters.formatSmart(item.openingCm)} → ${Formatters.formatSmart(item.closingCm)} CM (Δ ${Formatters.formatSmart(item.levelDifferenceCm)} CM) • Running: ${Formatters.formatSmart(item.runningHours)} hr',
                                            style: const TextStyle(
                                              fontSize: AppTextSizes.caption,
                                              fontWeight: AppFontWeights.medium,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),

                                          // 3. Fuel Top-up & Logged by
                                          Text(
                                            'Fuel Top-up: ${item.fuelTopUp > 0 ? '${Formatters.formatSmart(item.fuelTopUp)} L' : '0 L'} • Logged by: ${item.employeeName.isNotEmpty ? item.employeeName : (item.employeeId.isNotEmpty ? item.employeeId : 'Boiler Operator')}',
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
                                          '${Formatters.formatSmart(item.netReportedConsumption)} L',
                                          style: const TextStyle(
                                            fontSize: AppTextSizes.body,
                                            fontWeight: AppFontWeights.bold,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                        Text(
                                          '${Formatters.formatDecimal(item.consumptionPerHour)} L/hr',
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
                                            title: 'Delete Boiler Record',
                                            message: 'Are you sure you want to permanently delete boiler entry ${item.recordId} from ${item.date} (${item.shift})?',
                                            confirmLabel: 'Delete Record',
                                            isDestructive: true,
                                          );
                                          if (confirm) {
                                            ref.read(boilerProvider.notifier).deleteRecord(item.recordId);
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

  Widget _buildDateFilterChip(BoilerState state) {
    final filterDate = state.filterDate;
    final isToday = filterDate != null &&
        Formatters.formatDate(filterDate) == Formatters.formatDate(DateTime.now());

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: filterDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (picked != null) {
              ref.read(boilerProvider.notifier).setFilterDate(picked);
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
                  filterDate != null
                      ? (isToday
                          ? 'Today (${Formatters.formatDate(filterDate)})'
                          : Formatters.formatDate(filterDate))
                      : 'All Dates',
                  style: TextStyle(
                    fontWeight: AppFontWeights.bold,
                    fontSize: AppTextSizes.body,
                    color: filterDate != null ? AppColors.textPrimary : AppColors.textSecondary,
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
        if (filterDate != null) ...[
          const SizedBox(width: 6),
          InkWell(
            onTap: () => ref.read(boilerProvider.notifier).setFilterDate(null),
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

  Widget _buildShiftFilterChip(BoilerState state) {
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
                ref.read(boilerProvider.notifier).setFilterShift(val?.isEmpty ?? true ? null : val);
              },
            ),
          ),
        ],
      ),
    );
  }
}
