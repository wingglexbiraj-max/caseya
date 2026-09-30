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
import '../../providers/dg_hsd_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/dg_hsd_record.dart';

class DgHsdPage extends ConsumerStatefulWidget {
  const DgHsdPage({super.key});

  @override
  ConsumerState<DgHsdPage> createState() => _DgHsdPageState();
}

class _DgHsdPageState extends ConsumerState<DgHsdPage> {
  final TextEditingController _fuelAddedController = TextEditingController(text: '0');
  final TextEditingController _startPercentController = TextEditingController(text: '80');
  final TextEditingController _endPercentController = TextEditingController(text: '65');
  final TextEditingController _runningHoursController = TextEditingController(text: '3.5');
  final TextEditingController _consumptionController = TextEditingController(text: '50');
  final TextEditingController _kwhController = TextEditingController(text: '175');
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();


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
    ref.read(dgHsdProvider.notifier).setFuelAdded(Formatters.parseDouble(_fuelAddedController.text));
    ref.read(dgHsdProvider.notifier).setStartPercentage(Formatters.parseDouble(_startPercentController.text));
    ref.read(dgHsdProvider.notifier).setEndPercentage(Formatters.parseDouble(_endPercentController.text));
    ref.read(dgHsdProvider.notifier).setRunningHours(Formatters.parseDouble(_runningHoursController.text));
    ref.read(dgHsdProvider.notifier).setFuelConsumption(Formatters.parseDouble(_consumptionController.text));
    ref.read(dgHsdProvider.notifier).setKwh(Formatters.parseDouble(_kwhController.text));
    ref.read(dgHsdProvider.notifier).setRemarks(_remarksController.text.trim());
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
          _fuelAddedController.text = '0';
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
      _fuelAddedController.text = '0';
      _startPercentController.text = '80';
      _endPercentController.text = '65';
      _runningHoursController.text = '3.5';
      _consumptionController.text = '50';
      _kwhController.text = '175';
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
                      Icons.electric_bolt_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'DG SHIFT FUEL LOGGING',
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
                                              ref.read(dgHsdProvider.notifier).setShift(newShift);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 3. Fuel Added
                              Expanded(
                                child: AppTextField(
                                  label: 'Fuel Added',
                                  hint: '0',
                                  controller: _fuelAddedController,
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
                                                  ref.read(dgHsdProvider.notifier).setShift(newShift);
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
                                label: 'Fuel Added',
                                hint: '0',
                                controller: _fuelAddedController,
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

                    // Row 2: Start Percentage, End Percentage, Shift Running Hours
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 700;

                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Start Percentage',
                                  hint: '80',
                                  controller: _startPercentController,
                                  suffixText: '%',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => _onFieldChanged(),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Start % required';
                                    final n = Formatters.parseDouble(val);
                                    if (n < 0 || n > 100) return 'Must be 0-100%';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTextField(
                                  label: 'End Percentage',
                                  hint: '65',
                                  controller: _endPercentController,
                                  suffixText: '%',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => _onFieldChanged(),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'End % required';
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
                                  hint: '3.5',
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
                                      label: 'Start %',
                                      hint: '80',
                                      controller: _startPercentController,
                                      suffixText: '%',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (_) => _onFieldChanged(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'End %',
                                      hint: '65',
                                      controller: _endPercentController,
                                      suffixText: '%',
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (_) => _onFieldChanged(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                label: 'Shift Running Hours',
                                hint: '3.5',
                                controller: _runningHoursController,
                                suffixText: 'Hours',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => _onFieldChanged(),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Row 3: Fuel Consumption (Manual User Input) & kWh (Manual User Input)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 700;

                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Fuel Consumption (Manual Input)',
                                  hint: '50',
                                  controller: _consumptionController,
                                  suffixText: 'Litres',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => _onFieldChanged(),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Fuel consumption required';
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
                                  hint: '175',
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
                                label: 'Fuel Consumption (Manual Input)',
                                hint: '50',
                                controller: _consumptionController,
                                suffixText: 'Litres',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => _onFieldChanged(),
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                label: 'Energy Generated (Manual Input)',
                                hint: '175',
                                controller: _kwhController,
                                suffixText: 'kWh',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => _onFieldChanged(),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Live Fuel & Efficiency Chips (Below Fuel Consumption inputs)
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
                  title: 'DG OPERATIONAL EFFICIENCY RESULT',
                  items: [
                    ResultItem(
                      label: 'Fuel Consumed',
                      value: Formatters.formatSmart(state.liveResult!.fuelConsumption),
                      unit: 'Litres',
                      highlightColor: AppColors.primary,
                    ),
                    ResultItem(
                      label: 'Energy Generated',
                      value: Formatters.formatSmart(state.liveResult!.kwh),
                      unit: 'kWh',
                      highlightColor: AppColors.goldAccent,
                    ),
                    ResultItem(
                      label: 'DG Efficiency',
                      value: Formatters.formatDecimal(state.liveResult!.unitsPerLitre),
                      unit: 'kWh/L',
                      highlightColor: AppColors.primaryDark,
                      subtitle: 'Units per litre diesel',
                    ),
                    ResultItem(
                      label: 'Fuel Burn Rate',
                      value: Formatters.formatDecimal(state.liveResult!.consumptionPerHour),
                      unit: 'L/hr',
                      highlightColor: AppColors.primary,
                    ),
                    ResultItem(
                      label: 'Average DG Load',
                      value: Formatters.formatDecimal(state.liveResult!.averageLoadKw),
                      unit: 'kW',
                    ),
                    ResultItem(
                      label: 'Tank Level Drop',
                      value: Formatters.formatSmart(state.liveResult!.percentageDrop),
                      unit: '%',
                      subtitle: '${Formatters.formatSmart(state.liveResult!.startPercentage)}% → ${Formatters.formatSmart(state.liveResult!.endPercentage)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Collapsible step-by-step breakdown
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

  Widget _buildLiveDgChips(DgHsdState state) {
    final result = state.liveResult;
    final double fuelConsumption = result?.fuelConsumption ?? 0.0;
    final double kwh = result?.kwh ?? 0.0;
    final double unitsPerLitre = result?.unitsPerLitre ?? 0.0;
    final double burnRate = result?.consumptionPerHour ?? 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        final fuelChip = Container(
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
                child: const Icon(Icons.local_gas_station_rounded, color: AppColors.goldAccent, size: 22),
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
                      '${Formatters.formatSmart(fuelConsumption)} L',
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

        final energyChip = Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.goldAccent, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.electric_bolt_rounded, color: Color(0xFFB45309), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ENERGY GENERATED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.formatSmart(kwh)} kWh',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF78350F),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        final efficiencyChip = Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.speed_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EFFICIENCY YIELD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${Formatters.formatDecimal(unitsPerLitre)} kWh/L',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${Formatters.formatDecimal(burnRate)} L/hr',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(flex: 3, child: fuelChip),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: energyChip),
              const SizedBox(width: 12),
              Expanded(flex: 4, child: efficiencyChip),
            ],
          );
        } else {
          return Column(
            children: [
              fuelChip,
              const SizedBox(height: 10),
              energyChip,
              const SizedBox(height: 10),
              efficiencyChip,
            ],
          );
        }
      },
    );
  }

  Widget _buildHistorySection(DgHsdState state, bool canManage) {
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
                  'RECENT DG HSD ENTRIES (DATE-WISE)',
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
                                hintText: 'Search date, shift, operator, note...',
                                prefixIcon: Icon(Icons.search_rounded, size: 19),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              onChanged: (val) {
                                ref.read(dgHsdProvider.notifier).setSearchQuery(val);
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
                                ref.read(dgHsdProvider.notifier).setFilterShift(val?.isEmpty ?? true ? null : val);
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
                      padding: const EdgeInsets.all(20),
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
                          Text('No DG HSD records matching current filter.', style: TextStyle(color: AppColors.alert, fontWeight: FontWeight.w700)),
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
                                child: const Icon(Icons.electric_bolt_rounded, color: AppColors.goldAccent, size: 22),
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
                                      'Start: ${Formatters.formatSmart(item.startPercentage)}%  •  End: ${Formatters.formatSmart(item.endPercentage)}% (Drop: ${Formatters.formatSmart(item.percentageDrop)}%)  •  Running: ${Formatters.formatSmart(item.runningHours)} hr',
                                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                    ),
                                    if (item.fuelAdded > 0)
                                      Text(
                                        'Fuel Added: ${Formatters.formatSmart(item.fuelAdded)} L',
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
                                    '${Formatters.formatSmart(item.fuelConsumption)} L',
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  Text(
                                    '${Formatters.formatSmart(item.kwh)} kWh (${Formatters.formatDecimal(item.unitsPerLitre)} u/L)',
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
