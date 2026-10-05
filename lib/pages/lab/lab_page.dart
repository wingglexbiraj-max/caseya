import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
import '../../models/silo_model.dart';

class LabPage extends ConsumerStatefulWidget {
  const LabPage({super.key});

  @override
  ConsumerState<LabPage> createState() => _LabPageState();
}

class _LabPageState extends ConsumerState<LabPage> {
  static const List<String> _defaultAnalysts = [
    'Biraj Goswami',
    'Ritesh Debnath',
    'Bhriguraj Borah',
    'Pranjit Das',
    'Parag Jyoti Patowary',
    'Ritul Kaushik',
    'Joydeep Chanda',
    'Navjyoti Barman',
    'Dipankar Barman',
    'Prasenjit Das',
    'Rupam Boruah',
    'Other (Type manually)',
  ];

  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _snfController = TextEditingController();
  final TextEditingController _analystController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _siloStockController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _historyExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentUserName = ref.read(authProvider).name;
        final match = _defaultAnalysts.firstWhere(
          (n) => n.toLowerCase() == currentUserName.toLowerCase(),
          orElse: () => '',
        );
        setState(() {
          if (match.isNotEmpty && match != 'Other (Type manually)') {
            _analystController.text = match;
          } else {
            _analystController.text = currentUserName;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _fatController.dispose();
    _snfController.dispose();
    _analystController.dispose();
    _remarksController.dispose();
    _siloStockController.dispose();
    super.dispose();
  }

  void _showQuickEditStockDialog(dynamic silo, double currentStock) {
    final controller = TextEditingController(
      text: Formatters.formatSmart(currentStock).replaceAll(',', ''),
    );
    final formKey = GlobalKey<FormState>();
    final isPMST = (silo.id as String).toUpperCase().contains('PMST');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPMST
                      ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                      : const Color(0xFFD97706).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.water_drop_rounded,
                  color: isPMST ? const Color(0xFF0284C7) : const Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit ${silo.name} Stock',
                      style: const TextStyle(
                        fontSize: AppTextSizes.subheading,
                        fontWeight: AppFontWeights.bold,
                      ),
                    ),
                    Text(
                      _getSiloFullName(silo),
                      style: const TextStyle(
                        fontSize: AppTextSizes.caption,
                        color: AppColors.textSecondary,
                        fontWeight: AppFontWeights.medium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter current milk stock in Litres:',
                  style: TextStyle(
                    fontSize: AppTextSizes.body,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '${silo.name} Stock (Litres)',
                    hintText: 'e.g. 8500',
                    suffixText: 'Litres',
                    prefixIcon: const Icon(Icons.storage_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter quantity in Litres';
                    final n = Formatters.parseDouble(val);
                    if (n < 0) return 'Must be 0 or more';
                    return null;
                  },
                  onFieldSubmitted: (_) async {
                    if (formKey.currentState?.validate() ?? false) {
                      final newVal = Formatters.parseDouble(controller.text);
                      Navigator.of(ctx).pop();
                      final user = ref.read(authProvider);
                      final labState = ref.read(labProvider);
                      await ref.read(labProvider.notifier).updateMilkStock(
                        pmstLitres: isPMST ? newVal : labState.pmstStockLitres,
                        rmstLitres: !isPMST ? newVal : labState.rmstStockLitres,
                        notes: 'Quick edit ${silo.name} by ${user.name}',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✓ ${silo.name} stock updated to ${Formatters.formatSmart(newVal)} Litres'),
                            backgroundColor: const Color(0xFF16A34A),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isPMST ? const Color(0xFF0284C7) : const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final newVal = Formatters.parseDouble(controller.text);
                  Navigator.of(ctx).pop();
                  final user = ref.read(authProvider);
                  final labState = ref.read(labProvider);
                  await ref.read(labProvider.notifier).updateMilkStock(
                    pmstLitres: isPMST ? newVal : labState.pmstStockLitres,
                    rmstLitres: !isPMST ? newVal : labState.rmstStockLitres,
                    notes: 'Quick edit ${silo.name} by ${user.name}',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✓ ${silo.name} stock updated to ${Formatters.formatSmart(newVal)} Litres'),
                        backgroundColor: const Color(0xFF16A34A),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Stock', style: TextStyle(fontWeight: AppFontWeights.bold)),
            ),
          ],
        );
      },
    );
  }

  void _promptSelectSiloFirst() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Select tank silo first',
                style: TextStyle(
                  fontWeight: AppFontWeights.bold,
                  fontSize: AppTextSizes.body,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD97706),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onSave() async {
    final fatText = _fatController.text.trim();
    final snfText = _snfController.text.trim();
    final stockText = _siloStockController.text.trim();
    final user = ref.read(authProvider);
    final labState = ref.read(labProvider);
    final siloId = labState.selectedSiloId;

    if (siloId == null || siloId.isEmpty) {
      _promptSelectSiloFirst();
      return;
    }

    final isPMST = siloId.toUpperCase().contains('PMST');

    // Case 1: User enters only milk stock in this section
    if (stockText.isNotEmpty && fatText.isEmpty && snfText.isEmpty) {
      final stockVal = Formatters.parseDouble(stockText);
      if (stockVal < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Milk stock must be 0 or more Litres')),
        );
        return;
      }

      await ref.read(labProvider.notifier).updateMilkStock(
        pmstLitres: isPMST ? stockVal : labState.pmstStockLitres,
        rmstLitres: !isPMST ? stockVal : labState.rmstStockLitres,
        notes: 'Stock updated for $siloId by ${user.name}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('✓ $siloId Milk Stock updated to ${Formatters.formatSmart(stockVal)} Litres'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _siloStockController.clear();
        });
      }
      return;
    }

    // Case 2: Full quality test entry (Fat & SNF required)
    if (_formKey.currentState?.validate() ?? false) {
      final analystName = _analystController.text.trim().isNotEmpty
          ? _analystController.text.trim()
          : user.name;

      ref
          .read(labProvider.notifier)
          .setFat(Formatters.parseDouble(_fatController.text));
      ref
          .read(labProvider.notifier)
          .setSnf(Formatters.parseDouble(_snfController.text));
      ref.read(labProvider.notifier).setRemarks(_remarksController.text.trim());

      final success = await ref
          .read(labProvider.notifier)
          .saveReading(userId: user.employeeCode, userName: analystName);

      // If user also entered milk stock alongside the test
      if (stockText.isNotEmpty) {
        final stockVal = Formatters.parseDouble(stockText);
        await ref.read(labProvider.notifier).updateMilkStock(
          pmstLitres: isPMST ? stockVal : labState.pmstStockLitres,
          rmstLitres: !isPMST ? stockVal : labState.rmstStockLitres,
          notes: 'Updated alongside lab reading for $siloId',
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              stockText.isNotEmpty
                  ? '✓ Lab test and $siloId stock (${Formatters.formatSmart(Formatters.parseDouble(stockText))} L) recorded successfully.'
                  : (ref.read(labProvider).successMessage ??
                      '✓ Lab reading recorded successfully.'),
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _siloStockController.clear();
        });
        _onClear();
      }
    }
  }

  void _onClear() {
    ref.read(labProvider.notifier).cancelEditing();
    ref.read(labProvider.notifier).resetToLiveTime();
    final currentUserName = ref.read(authProvider).name;
    final match = _defaultAnalysts.firstWhere(
      (n) => n.toLowerCase() == currentUserName.toLowerCase(),
      orElse: () => '',
    );
    setState(() {
      _fatController.clear();
      _snfController.clear();
      _remarksController.clear();
      if (match.isNotEmpty && match != 'Other (Type manually)') {
        _analystController.text = match;
      } else {
        _analystController.text = currentUserName;
      }
    });
  }

  void _loadIntoForm(LabMilkTest test) {
    ref.read(labProvider.notifier).startEditing(test);
    final match = _defaultAnalysts.firstWhere(
      (n) => n.toLowerCase() == test.labUserName.toLowerCase(),
      orElse: () => '',
    );
    setState(() {
      _fatController.text = test.fatPercentage.toStringAsFixed(2);
      _snfController.text = test.snfPercentage.toStringAsFixed(2);
      _remarksController.text = test.remarks;
      if (match.isNotEmpty && match != 'Other (Type manually)') {
        _analystController.text = match;
      } else {
        _analystController.text = test.labUserName;
      }
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
      helpText: 'SELECT SAMPLE COLLECTION TIME',
    );
    if (picked != null) {
      ref.read(labProvider.notifier).setTime(picked, isManual: true);
    }
  }

  Widget _buildAnalystSelector() {
    return AppTextField(
      label: 'Lab Analyst (Person) *',
      hint: 'Type name or select from list',
      controller: _analystController,
      prefixIcon: Icon(
        Icons.person_rounded,
        size: 18,
        color: Colors.black.withValues(alpha: 0.60),
      ),
      suffixIcon: PopupMenuButton<String>(
        tooltip: 'Select analyst from list',
        icon: const Icon(
          Icons.arrow_drop_down_rounded,
          color: AppColors.textSecondary,
          size: 26,
        ),
        onSelected: (val) {
          setState(() {
            if (val == 'Other (Type manually)') {
              _analystController.clear();
            } else {
              _analystController.text = val;
            }
          });
        },
        itemBuilder: (context) => _defaultAnalysts.map((name) {
          final isOther = name == 'Other (Type manually)';
          return PopupMenuItem<String>(
            value: name,
            child: Row(
              children: [
                Icon(
                  isOther
                      ? Icons.edit_note_rounded
                      : Icons.person_outline_rounded,
                  size: 16,
                  color: isOther ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: AppTextSizes.body,
                    fontWeight: isOther ? AppFontWeights.bold : AppFontWeights.semiBold,
                    color: isOther ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Analyst name is required';
        }
        return null;
      },
    );
  }

  Widget _buildSiloSelectorDropdown(LabState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tank / Silo *',
          style: TextStyle(
            fontSize: AppTextSizes.body,
            fontWeight: AppFontWeights.semiBold,
            color: AppColors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.08),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.storage_rounded,
                size: 18,
                color: Colors.black.withValues(alpha: 0.60),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.selectedSiloId,
                    hint: const Text(
                      'Select Silo',
                      style: TextStyle(
                        fontSize: AppTextSizes.body,
                        color: AppColors.textMuted,
                        fontWeight: AppFontWeights.semiBold,
                      ),
                    ),
                    isExpanded: true,
                    items: state.silos.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          '${s.name} (${s.description})',
                          style: const TextStyle(
                            fontSize: AppTextSizes.body,
                            fontWeight: AppFontWeights.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (newSiloId) {
                      if (newSiloId != null) {
                        ref
                            .read(labProvider.notifier)
                            .setSiloId(newSiloId);
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
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(labProvider);
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
              if (state.editingTest != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusBadge.warning(
                      'Editing ${state.editingTest!.siloName} Reading',
                    ),
                    OutlinedButton(
                      onPressed: _onClear,
                      child: const Text('Cancel Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Error messages
              if (state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: AppTextSizes.body,
                            fontWeight: AppFontWeights.bold,
                          ),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.biotech_rounded,
                      size: 20,
                      color: Colors.black.withValues(alpha: 0.60),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'RECORD MILK QUALITY TEST',
                    style: TextStyle(
                      fontSize: AppTextSizes.subheading,
                      fontWeight: AppFontWeights.bold,
                      letterSpacing: 0.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppCard(
                backgroundColor: const Color(0xFFF5F3FF),
                borderColor: Colors.black.withValues(alpha: 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Date, Time, and Lab Analyst (3 chips in one row)
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
                                    const Text(
                                      'Date',
                                      style: TextStyle(
                                        fontSize: AppTextSizes.body,
                                        fontWeight: AppFontWeights.semiBold,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: _selectDate,
                                      borderRadius: BorderRadius.circular(9),
                                      child: Container(
                                        height: 48,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                          border: Border.all(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: 17,
                                              color: Colors.black.withValues(alpha: 0.60),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                Formatters.formatDate(
                                                  state.selectedDate,
                                                ),
                                                style: const TextStyle(
                                                  fontWeight: AppFontWeights.bold,
                                                  fontSize: AppTextSizes.body,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 2. Time (Auto recorded in Real-Time / Selectable)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Time',
                                      style: TextStyle(
                                        fontSize: AppTextSizes.body,
                                        fontWeight: AppFontWeights.semiBold,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _LiveTimeSelectorChip(
                                      isMobile: false,
                                      onTap: _selectTime,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 3. Lab Analyst (Person)
                              Expanded(
                                child: _buildAnalystSelector(),
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
                                          color: Colors.white,
                                          border: Border.all(
                                            color: Colors.black.withValues(alpha: 0.08),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: 16,
                                              color: Colors.black.withValues(alpha: 0.60),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                Formatters.formatDate(
                                                  state.selectedDate,
                                                ),
                                                style: const TextStyle(
                                                  fontWeight: AppFontWeights.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _LiveTimeSelectorChip(
                                      isMobile: true,
                                      onTap: _selectTime,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildAnalystSelector(),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Row 2: Milk Fat (%), Milk SNF (%), and Tank / Silo - 3 in a row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 700;

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Milk Fat (%)',
                                  hint: 'e.g., 4.30',
                                  controller: _fatController,
                                  onChanged: (_) => setState(() {}),
                                  prefixIcon: Icon(
                                    Icons.opacity_rounded,
                                    size: 18,
                                    color: Colors.black.withValues(alpha: 0.60),
                                  ),
                                  suffixText: '%',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  validator: (val) {
                                    if (_siloStockController.text.trim().isNotEmpty &&
                                        (val == null || val.trim().isEmpty)) {
                                      return null;
                                    }
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Milk Fat is required';
                                    }
                                    final n = Formatters.parseDouble(val);
                                    if (n <= 0) return 'Must be greater than 0';
                                    if (n < 1.0 || n > 15.0) {
                                      return 'Warning: Unusually high/low Fat';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTextField(
                                  label: 'Milk SNF (%)',
                                  hint: 'e.g., 8.33',
                                  controller: _snfController,
                                  onChanged: (_) => setState(() {}),
                                  prefixIcon: Icon(
                                    Icons.biotech_rounded,
                                    size: 18,
                                    color: Colors.black.withValues(alpha: 0.60),
                                  ),
                                  suffixText: '%',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  validator: (val) {
                                    if (_siloStockController.text.trim().isNotEmpty &&
                                        (val == null || val.trim().isEmpty)) {
                                      return null;
                                    }
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Milk SNF is required';
                                    }
                                    final n = Formatters.parseDouble(val);
                                    if (n <= 0) return 'Must be greater than 0';
                                    if (n < 5.0 || n > 18.0) {
                                      return 'Warning: Unusually high/low SNF';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: _buildSiloSelectorDropdown(state)),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTextField(
                                label: 'Milk Fat (%)',
                                hint: 'e.g., 4.30',
                                controller: _fatController,
                                onChanged: (_) => setState(() {}),
                                prefixIcon: Icon(
                                  Icons.opacity_rounded,
                                  size: 18,
                                  color: Colors.black.withValues(alpha: 0.60),
                                ),
                                suffixText: '%',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (val) {
                                  if (_siloStockController.text.trim().isNotEmpty &&
                                      (val == null || val.trim().isEmpty)) {
                                    return null;
                                  }
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Fat required';
                                  }
                                  final n = Formatters.parseDouble(val);
                                  if (n <= 0) return 'Must be > 0';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                label: 'Milk SNF (%)',
                                hint: 'e.g., 8.33',
                                controller: _snfController,
                                onChanged: (_) => setState(() {}),
                                prefixIcon: Icon(
                                  Icons.biotech_rounded,
                                  size: 18,
                                  color: Colors.black.withValues(alpha: 0.60),
                                ),
                                suffixText: '%',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (val) {
                                  if (_siloStockController.text.trim().isNotEmpty &&
                                      (val == null || val.trim().isEmpty)) {
                                    return null;
                                  }
                                  if (val == null || val.trim().isEmpty) {
                                    return 'SNF required';
                                  }
                                  final n = Formatters.parseDouble(val);
                                  if (n <= 0) return 'Must be > 0';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildSiloSelectorDropdown(state),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Row 3: Optional Remarks & Stock of Milk (in one line, two chips/fields)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 650;
                        final hasSilo = state.selectedSiloId != null &&
                            state.selectedSiloId!.isNotEmpty;
                        final selectedSilo = hasSilo
                            ? state.silos.firstWhere(
                                (s) => s.id == state.selectedSiloId,
                                orElse: () => SiloModel(
                                  id: state.selectedSiloId!,
                                  name: state.selectedSiloId!,
                                  description: '',
                                ),
                              )
                            : null;
                        final siloDisplayName = selectedSilo != null
                            ? (selectedSilo.name.toUpperCase().contains('PMST')
                                ? 'PMST'
                                : (selectedSilo.name.toUpperCase().contains('RMST')
                                    ? 'RMST'
                                    : selectedSilo.name))
                            : 'Select Silo';
                        final isPMST = selectedSilo != null &&
                            (selectedSilo.id.toUpperCase().contains('PMST') ||
                                selectedSilo.name.toUpperCase().contains('PMST'));
                        final currentStock = selectedSilo != null
                            ? (isPMST ? state.pmstStockLitres : state.rmstStockLitres)
                            : null;

                        final remarksField = AppTextField(
                          label: 'Optional Remarks (Note)',
                          hint: 'e.g., Tanker composite sample approved',
                          controller: _remarksController,
                          prefixIcon: Icon(
                            Icons.edit_note_rounded,
                            size: 18,
                            color: Colors.black.withValues(alpha: 0.60),
                          ),
                        );

                        final stockField = GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: !hasSilo ? _promptSelectSiloFirst : null,
                          child: AppTextField(
                            label: hasSilo
                                ? 'Stock of Milk ($siloDisplayName)'
                                : 'Stock of Milk (Select Silo)',
                            hint: hasSilo
                                ? 'Current: ${Formatters.formatSmart(currentStock ?? 0)} L'
                                : 'Select tank silo first',
                            controller: _siloStockController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            readOnly: !hasSilo,
                            onTap: !hasSilo ? _promptSelectSiloFirst : null,
                            prefixIcon: Icon(
                              Icons.water_drop_rounded,
                              size: 18,
                              color: Colors.black.withValues(alpha: 0.60),
                            ),
                            suffixText: hasSilo ? 'Litres' : null,
                            onChanged: (_) => setState(() {}),
                          ),
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: remarksField),
                              const SizedBox(width: 12),
                              Expanded(flex: 5, child: stockField),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              remarksField,
                              const SizedBox(height: 12),
                              stockField,
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons (Record Reading & Clear)
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
                              state.editingTest != null
                                  ? Icons.check_rounded
                                  : Icons.save_outlined,
                              size: 20,
                            ),
                            label: Text(
                              state.editingTest != null
                                  ? 'Update Lab Reading'
                                  : (_siloStockController.text.trim().isNotEmpty &&
                                          _fatController.text.trim().isEmpty &&
                                          _snfController.text.trim().isEmpty
                                      ? 'Update Milk Stock Only'
                                      : (_siloStockController.text.trim().isNotEmpty
                                          ? 'Record Reading & Stock'
                                          : 'Record Reading')),
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
                            onPressed: _onClear,
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
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    size: 20,
                    color: Colors.black.withValues(alpha: 0.60),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'LATEST READINGS DASHBOARD (TODAY)',
                  style: TextStyle(
                    fontSize: AppTextSizes.subheading,
                    fontWeight: AppFontWeights.bold,
                    letterSpacing: 0.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Text(
              'Automatic Source for Milk Standardization',
              style: TextStyle(
                fontSize: AppTextSizes.caption,
                color: AppColors.textSecondary,
                fontWeight: AppFontWeights.semiBold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final visibleSilos = state.silos.where((s) {
              final id = s.id.toUpperCase();
              final name = s.name.toUpperCase();
              return id == 'RMST' ||
                  id == 'PMST' ||
                  (id != 'SILO_1' &&
                      id != 'SILO_2' &&
                      !name.contains('SILO 1') &&
                      !name.contains('SILO 2'));
            }).toList();

            final crossAxisCount = constraints.maxWidth >= 600 ? 2 : 1;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleSilos.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 188,
              ),
              itemBuilder: (context, index) {
                final silo = visibleSilos[index];
                final reading = state.todayLatestBySilo[silo.id];

                return _buildSiloReadingCard(silo, reading, state);
              },
            );
          },
        ),
      ],
    );
  }

  String _getSiloFullName(dynamic silo) {
    final id = (silo.id as String).toUpperCase();
    final name = (silo.name as String).toUpperCase();
    if (id.contains('PMST') || name.contains('PMST')) {
      return 'Pasteurized Milk Storage Tank';
    } else if (id.contains('RMST') || name.contains('RMST')) {
      return 'Raw Milk Storage Tank';
    }
    final desc = silo.description as String?;
    return (desc != null && desc.isNotEmpty) ? desc : 'Milk Storage Tank';
  }

  Widget _buildSiloReadingCard(dynamic silo, LabMilkTest? reading, LabState state) {
    return _SiloReadingCard(
      silo: silo,
      reading: reading,
      state: state,
      onEditStock: _showQuickEditStockDialog,
    );
  }

  // ---------------------------------------------------------------------------
  // READING HISTORY TABLE
  // ---------------------------------------------------------------------------
  Widget _buildHistoryTable(LabState state, bool canManage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _historyExpanded = !_historyExpanded),
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
                      'LABORATORY READING HISTORY',
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
                      '${state.filteredHistory.length} Test Records',
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
                            _historyExpanded ? 'Collapse' : 'Expand',
                            style: const TextStyle(
                              fontSize: AppTextSizes.caption,
                              fontWeight: AppFontWeights.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _historyExpanded
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
        if (_historyExpanded) ...[
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
                        // Filter Controls (Silo, Date)
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildSiloFilterChip(state),
                            _buildDateFilterChip(state),
                          ],
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
                            border: Border.all(
                              color: AppColors.alert.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 20,
                                color: AppColors.alert,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'No lab readings matching current filter.',
                                style: TextStyle(
                                  color: AppColors.alert,
                                  fontWeight: AppFontWeights.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.filteredHistory.length,
                          separatorBuilder: (_, index) =>
                              const Divider(height: 1),
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
                                    child: const Icon(
                                      Icons.science_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              item.testDate,
                                              style: const TextStyle(
                                                fontWeight: AppFontWeights.bold,
                                                fontSize: AppTextSizes.body,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              item.testTime,
                                              style: const TextStyle(
                                                fontWeight: AppFontWeights.semiBold,
                                                fontSize: AppTextSizes.caption,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            StatusBadge.neutral(
                                              item.siloName,
                                              fontSize: AppTextSizes.caption,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tested by: ${item.labUserName}',
                                          style: const TextStyle(
                                            fontSize: AppTextSizes.caption,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        if (item.remarks.trim().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.danger
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: AppColors.danger
                                                    .withValues(alpha: 0.25),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.sticky_note_2_rounded,
                                                  size: 13,
                                                  color: AppColors.danger,
                                                ),
                                                const SizedBox(width: 5),
                                                Flexible(
                                                  child: Text(
                                                    'Note: ${item.remarks.trim()}',
                                                    style: const TextStyle(
                                                      fontSize: AppTextSizes.caption,
                                                      fontWeight:
                                                          AppFontWeights.bold,
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
                                  // Fat % & SNF %
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Fat: ${item.fatPercentage.toStringAsFixed(2)}%',
                                        style: const TextStyle(
                                          fontSize: AppTextSizes.body,
                                          fontWeight: AppFontWeights.bold,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                      Text(
                                        'SNF: ${item.snfPercentage.toStringAsFixed(2)}%',
                                        style: const TextStyle(
                                          fontSize: AppTextSizes.body,
                                          fontWeight: AppFontWeights.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  // Action Menu (Edit, Delete)
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                    onSelected: (val) async {
                                      if (val == 'edit') {
                                        _loadIntoForm(item);
                                      } else if (val == 'delete') {
                                        final confirm =
                                            await ConfirmationDialog.show(
                                              context: context,
                                              title: 'Delete Lab Test',
                                              message:
                                                  'Are you sure you want to permanently delete this lab test for ${item.siloName} on ${item.testDate} (${item.testTime})?',
                                              confirmLabel: 'Delete Test',
                                              isDestructive: true,
                                            );
                                        if (confirm) {
                                          ref
                                              .read(labProvider.notifier)
                                              .deleteReading(item.id);
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit Reading'),
                                      ),
                                      if (canManage)
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: AppColors.danger,
                                            ),
                                          ),
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
      ],
    );
  }

  Widget _buildDateFilterChip(LabState state) {
    final isToday = state.filterDate == null ||
        Formatters.formatDate(state.filterDate!) ==
            Formatters.formatDate(DateTime.now());

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: state.filterDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (picked != null) {
              ref.read(labProvider.notifier).setFilterDate(picked);
            }
          },
          borderRadius: BorderRadius.circular(9),
          child: Container(
            height: 44,
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
                  state.filterDate != null
                      ? (isToday
                          ? 'Today (${Formatters.formatDate(state.filterDate!)})'
                          : Formatters.formatDate(state.filterDate!))
                      : 'Select Date',
                  style: const TextStyle(
                    fontWeight: AppFontWeights.bold,
                    fontSize: AppTextSizes.body,
                    color: AppColors.textPrimary,
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
        if (!isToday) ...[
          const SizedBox(width: 6),
          InkWell(
            onTap: () =>
                ref.read(labProvider.notifier).setFilterDate(DateTime.now()),
            borderRadius: BorderRadius.circular(9),
            child: Container(
              height: 44,
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
                    Icons.replay_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Today',
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

  Widget _buildSiloFilterChip(LabState state) {
    return Container(
      height: 44,
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
            Icons.storage_rounded,
            size: 17,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: state.filterSiloId ?? '',
              isDense: true,
              icon: const Icon(
                Icons.arrow_drop_down_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              style: const TextStyle(
                fontWeight: AppFontWeights.bold,
                fontSize: AppTextSizes.body,
                color: AppColors.textPrimary,
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('All Silos / Tanks'),
                ),
                ...state.silos.map(
                  (s) => DropdownMenuItem(
                    value: s.id,
                    child: Text('${s.name} (${s.description})'),
                  ),
                ),
              ],
              onChanged: (val) {
                ref.read(labProvider.notifier).setFilterSiloId(
                      val == null || val.isEmpty ? null : val,
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveTimeSelectorChip extends ConsumerStatefulWidget {
  final bool isMobile;
  final VoidCallback onTap;

  const _LiveTimeSelectorChip({
    required this.isMobile,
    required this.onTap,
  });

  @override
  ConsumerState<_LiveTimeSelectorChip> createState() => _LiveTimeSelectorChipState();
}

class _LiveTimeSelectorChipState extends ConsumerState<_LiveTimeSelectorChip> {
  Timer? _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final now = DateTime.now();
        setState(() {
          _currentTime = now;
        });
        ref.read(labProvider.notifier).updateLiveTime(now);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labState = ref.watch(labProvider);
    final isLive = labState.isLiveTime;

    // Real-time second-by-second live clock when in LIVE mode;
    // User picked time when in MANUAL mode
    final String displayTime = isLive
        ? DateFormat('hh:mm:ss a').format(_currentTime)
        : labState.selectedTime.format(context);

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 9),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.isMobile ? 10 : 14,
          vertical: widget.isMobile ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: isLive ? const Color(0xFFF9FDFB) : Colors.white,
          borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 9),
          border: Border.all(
            color: isLive ? const Color(0xFF86EFAC) : AppColors.cardBorder,
            width: isLive ? 1.4 : 1.2,
          ),
          boxShadow: isLive
              ? [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isLive ? Icons.access_time_filled_rounded : Icons.access_time_rounded,
              size: widget.isMobile ? 16 : 17,
              color: isLive ? const Color(0xFF16A34A) : AppColors.primary,
            ),
            SizedBox(width: widget.isMobile ? 8 : 10),
            Expanded(
              child: Text(
                displayTime,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: AppFontWeights.bold,
                  fontSize: widget.isMobile ? AppTextSizes.caption : AppTextSizes.body,
                  color: isLive ? const Color(0xFF0F2448) : AppColors.primaryDark,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (isLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: AppFontWeights.bold,
                        color: Color(0xFF16A34A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              InkWell(
                onTap: () {
                  ref.read(labProvider.notifier).resetToLiveTime();
                },
                borderRadius: BorderRadius.circular(4),
                child: Tooltip(
                  message: 'Reset to Live Real-Time Clock',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.refresh_rounded, size: 11, color: AppColors.primary),
                        SizedBox(width: 2),
                        Text(
                          'RESET',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: AppFontWeights.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SiloReadingCard extends StatefulWidget {
  final dynamic silo;
  final LabMilkTest? reading;
  final LabState state;
  final void Function(dynamic silo, double currentStock) onEditStock;

  const _SiloReadingCard({
    required this.silo,
    required this.reading,
    required this.state,
    required this.onEditStock,
  });

  @override
  State<_SiloReadingCard> createState() => _SiloReadingCardState();
}

class _SiloReadingCardState extends State<_SiloReadingCard> {
  bool _isHovered = false;

  String _getSiloFullName(dynamic silo) {
    final id = (silo.id as String).toUpperCase();
    final name = (silo.name as String).toUpperCase();
    if (id.contains('PMST') || name.contains('PMST')) {
      return 'Pasteurized Milk Storage Tank';
    } else if (id.contains('RMST') || name.contains('RMST')) {
      return 'Raw Milk Storage Tank';
    }
    final desc = silo.description as String?;
    return (desc != null && desc.isNotEmpty) ? desc : 'Milk Storage Tank';
  }

  @override
  Widget build(BuildContext context) {
    final silo = widget.silo;
    final reading = widget.reading;
    final hasReading = reading != null;
    final isPMST = (silo.id as String).toUpperCase().contains('PMST');
    final siloStock = isPMST ? widget.state.pmstStockLitres : widget.state.rmstStockLitres;

    // Matching Total Metric Summary chip card colors:
    // PMST: Soft Blue (0xFFEFF6FF)
    // RMST: Soft Amber (0xFFFFFBEB)
    final Color cardBg = isPMST ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB);
    final Color themeColor = isPMST ? const Color(0xFF0284C7) : const Color(0xFFD97706);
    final Color valueColor = isPMST ? const Color(0xFF0284C7) : const Color(0xFFD97706);

    final effectiveBg = _isHovered
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.60), cardBg)
        : cardBg;

    final testDateFormatted = () {
      if (reading != null && reading.testDate.isNotEmpty) {
        final parsed = DateTime.tryParse(reading.testDate);
        if (parsed != null) return Formatters.formatDate(parsed);
      }
      return Formatters.formatDate(DateTime.now());
    }();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? themeColor.withValues(alpha: 0.55)
                : Colors.black.withValues(alpha: 0.08),
            width: _isHovered ? 1.4 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? themeColor.withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: _isHovered ? 10 : 4,
              offset: _isHovered ? const Offset(0, 3) : const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Silo Header: Low-opacity black circular icon + Silo Name + Status Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.storage_rounded,
                            color: Colors.black.withValues(alpha: 0.60),
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                silo.name,
                                style: const TextStyle(
                                  fontWeight: AppFontWeights.bold,
                                  fontSize: AppTextSizes.body,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 1.5),
                              Text(
                                _getSiloFullName(silo),
                                style: const TextStyle(
                                  fontSize: AppTextSizes.caption,
                                  fontWeight: AppFontWeights.semiBold,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasReading)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.20),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF16A34A),
                            size: 11,
                          ),
                          SizedBox(width: 3.5),
                          Text(
                            'Fresh Reading',
                            style: TextStyle(
                              fontSize: AppTextSizes.caption,
                              fontWeight: AppFontWeights.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.20),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.danger,
                            size: 11,
                          ),
                          SizedBox(width: 3.5),
                          Text(
                            'No reading today',
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
              ),

              // Fat, SNF & Current Stock Values (All in same line)
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FAT',
                          style: TextStyle(
                            fontSize: AppTextSizes.caption,
                            fontWeight: AppFontWeights.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          hasReading ? '${reading.fatPercentage.toStringAsFixed(2)}%' : '--',
                          style: TextStyle(
                            fontSize: AppTextSizes.subheading,
                            fontWeight: AppFontWeights.bold,
                            color: hasReading ? valueColor : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 26, color: Colors.black.withValues(alpha: 0.07)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SNF',
                          style: TextStyle(
                            fontSize: AppTextSizes.caption,
                            fontWeight: AppFontWeights.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          hasReading ? '${reading.snfPercentage.toStringAsFixed(2)}%' : '--',
                          style: TextStyle(
                            fontSize: AppTextSizes.subheading,
                            fontWeight: AppFontWeights.bold,
                            color: hasReading ? valueColor : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 26, color: Colors.black.withValues(alpha: 0.07)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: InkWell(
                      onTap: () => widget.onEditStock(silo, siloStock),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CURRENT STOCK',
                              style: TextStyle(
                                fontSize: AppTextSizes.caption,
                                fontWeight: AppFontWeights.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${Formatters.formatSmart(siloStock)} L',
                                  style: TextStyle(
                                    fontSize: AppTextSizes.subheading,
                                    fontWeight: AppFontWeights.bold,
                                    color: valueColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.edit_rounded,
                                  size: 13,
                                  color: valueColor.withValues(alpha: 0.85),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Footer (Last tested date, time & analyst)
              Container(
                padding: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.black.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hasReading
                          ? 'Tested: $testDateFormatted, ${reading.testTime}'
                          : 'No sample',
                      style: const TextStyle(
                        fontSize: AppTextSizes.caption,
                        fontWeight: AppFontWeights.semiBold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      hasReading ? reading.labUserName : 'Pending',
                      style: const TextStyle(
                        fontSize: AppTextSizes.caption,
                        fontWeight: AppFontWeights.semiBold,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

