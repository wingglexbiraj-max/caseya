import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/result_card.dart';
import '../../core/widgets/calculation_breakdown.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../providers/boiler_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/boiler_record.dart';

class BoilerPage extends ConsumerStatefulWidget {
  const BoilerPage({super.key});

  @override
  ConsumerState<BoilerPage> createState() => _BoilerPageState();
}

class _BoilerPageState extends ConsumerState<BoilerPage> {
  final TextEditingController _openingController = TextEditingController(text: '500');
  final TextEditingController _closingController = TextEditingController(text: '430');
  final TextEditingController _hoursController = TextEditingController(text: '8.5');
  final TextEditingController _topUpController = TextEditingController(text: '0');
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();


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
          _topUpController.text = '0';
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
      _openingController.text = '500';
      _closingController.text = '430';
      _hoursController.text = '8.5';
      _topUpController.text = '0';
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
                          style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w700),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'SHIFT FUEL LOGGING',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Data Entry Card
              AppCard(
                topBorderColor: AppColors.primary,
                topBorderHeight: 4,
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

                              // 2. Shift
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Shift', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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
                                          value: state.selectedShift,
                                          isExpanded: true,
                                          items: AppConstants.shifts.map((s) {
                                            return DropdownMenuItem(
                                              value: s,
                                              child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                            );
                                          }).toList(),
                                          onChanged: (newShift) {
                                            if (newShift != null) {
                                              ref.read(boilerProvider.notifier).setShift(newShift);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 3. Fuel Top-up
                              Expanded(
                                child: AppTextField(
                                  label: 'Fuel Top-up',
                                  hint: '0',
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Shift', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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
                                              value: state.selectedShift,
                                              isExpanded: true,
                                              items: AppConstants.shifts.map((s) {
                                                return DropdownMenuItem(
                                                  value: s,
                                                  child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                                );
                                              }).toList(),
                                              onChanged: (newShift) {
                                                if (newShift != null) {
                                                  ref.read(boilerProvider.notifier).setShift(newShift);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                label: 'Fuel Top-up',
                                hint: '0',
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
                                  hint: '500',
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
                                  hint: '430',
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
                                  hint: '8.5',
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
                                      hint: '500',
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
                                      hint: '430',
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
                                hint: '8.5',
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

                    // Live Fuel Consumption & Top-up Chips (directly below Opening & Closing CM)
                    _buildLiveFuelChips(state),
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
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
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
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Live Automatic Result Card
              if (state.liveResult != null) ...[
                const SizedBox(height: 20),
                ResultCard(
                  title: 'BOILER CONSUMPTION RESULT',
                  items: [
                    ResultItem(
                      label: 'Opening Level',
                      value: Formatters.formatSmart(state.liveResult!.openingCm),
                      unit: 'CM',
                    ),
                    ResultItem(
                      label: 'Closing Level',
                      value: Formatters.formatSmart(state.liveResult!.closingCm),
                      unit: 'CM',
                    ),
                    ResultItem(
                      label: 'Level Difference',
                      value: Formatters.formatSmart(state.liveResult!.levelDifferenceCm),
                      unit: 'CM',
                      highlightColor: state.liveResult!.levelDifferenceCm >= 0 ? AppColors.primaryDark : AppColors.danger,
                    ),
                    ResultItem(
                      label: 'Calculated Consumption',
                      value: Formatters.formatSmart(state.liveResult!.calculatedLevelConsumption),
                      unit: 'Litres',
                      highlightColor: AppColors.primary,
                    ),
                    if (state.liveResult!.fuelTopUp > 0)
                      ResultItem(
                        label: 'Fuel Top-up',
                        value: Formatters.formatSmart(state.liveResult!.fuelTopUp),
                        unit: 'Litres',
                        highlightColor: AppColors.goldAccent,
                      ),
                    ResultItem(
                      label: 'Consumption / Hour',
                      value: Formatters.formatDecimal(state.liveResult!.consumptionPerHour),
                      unit: 'L/hr',
                      highlightColor: AppColors.primaryDark,
                      subtitle: 'Running: ${Formatters.formatSmart(state.liveResult!.runningHours)} hrs',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Collapsible step-by-step breakdown
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

  Widget _buildLiveFuelChips(BoilerState state) {
    final result = state.liveResult;
    final double levelConsumption = result?.calculatedLevelConsumption ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2448), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_fire_department_rounded, color: AppColors.goldAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FUEL CONSUMPTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: AppColors.goldAccent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.formatSmart(levelConsumption)} L',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BoilerState state, bool canManage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'RECENT BOILER ENTRIES (DATE-WISE)',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            StatusBadge.info(
              state.allRecords.isEmpty
                  ? '0 Entries'
                  : '${state.allRecords.length} Entries Recorded',
            ),
          ],
        ),
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
                      // Filters Row
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 700;

                          return Row(
                            children: [
                              Expanded(
                                flex: isWide ? 6 : 12,
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    hintText: 'Search date, shift, employee, note...',
                                    prefixIcon: Icon(Icons.search_rounded, size: 19),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                  onChanged: (val) {
                                    ref.read(boilerProvider.notifier).setSearchQuery(val);
                                  },
                                ),
                              ),
                              if (isWide) ...[
                                const SizedBox(width: 12),
                                DropdownButton<String>(
                                  value: state.filterShift,
                                  hint: const Text('Filter Shift', style: TextStyle(fontSize: 13)),
                                  items: [
                                    const DropdownMenuItem(value: '', child: Text('All Shifts')),
                                    ...AppConstants.shifts.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                                  ],
                                  onChanged: (val) {
                                    ref.read(boilerProvider.notifier).setFilterShift(val?.isEmpty ?? true ? null : val);
                                  },
                                ),
                              ],
                            ],
                          );
                        },
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
                              Text('No boiler records matching current filter.', style: TextStyle(color: AppColors.alert, fontWeight: FontWeight.w700)),
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
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.metricBgBoiler,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.local_fire_department_rounded, color: AppColors.goldAccent, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              item.date,
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                            ),
                                            const SizedBox(width: 8),
                                            StatusBadge.neutral(item.shift, fontSize: 11),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Opening: ${Formatters.formatSmart(item.openingCm)} CM  •  Closing: ${Formatters.formatSmart(item.closingCm)} CM  •  Running: ${Formatters.formatSmart(item.runningHours)} hr',
                                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                        ),
                                        if (item.fuelTopUp > 0)
                                          Text(
                                            'Fuel Top-up: ${Formatters.formatSmart(item.fuelTopUp)} L',
                                            style: const TextStyle(fontSize: 11.5, color: AppColors.goldAccent, fontWeight: FontWeight.w700),
                                          ),
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
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${Formatters.formatSmart(item.netReportedConsumption)} L',
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                      Text(
                                        '${Formatters.formatDecimal(item.consumptionPerHour)} L/hr',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  // Actions (Edit, Delete)
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
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
                                      const PopupMenuItem(value: 'edit', child: Text('Edit Record')),
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
          ),
        ),
      ],
    );
  }
}
