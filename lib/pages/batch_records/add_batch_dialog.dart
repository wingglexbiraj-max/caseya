import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../models/batch_record_model.dart';
import '../../providers/batch_records_provider.dart';
import '../../providers/lab_provider.dart';
import '../../services/batch_recipe_service.dart';

class AddBatchDialog extends ConsumerStatefulWidget {
  final BatchRecordModel? existingBatch;

  const AddBatchDialog({super.key, this.existingBatch});

  @override
  ConsumerState<AddBatchDialog> createState() => _AddBatchDialogState();
}

class _IngredientRowController {
  final String id;
  final TextEditingController nameController;
  final TextEditingController qtyController;
  String unit;

  _IngredientRowController({
    required this.id,
    required String name,
    required String qty,
    required this.unit,
  })  : nameController = TextEditingController(text: name),
        qtyController = TextEditingController(text: qty);

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
  }
}

class _AddBatchDialogState extends ConsumerState<AddBatchDialog> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  late TextEditingController _batchNumberController;
  late TextEditingController _quantityController;
  late TextEditingController _notesController;
  late TextEditingController _operatorController;

  String _selectedProduct = 'Lassi';
  String _selectedUnit = 'L';
  String _selectedSilo = 'RMST';
  late String _selectedShift;

  final List<_IngredientRowController> _ingredientRows = [];

  bool get isEditMode => widget.existingBatch != null;

  @override
  void initState() {
    super.initState();

    if (widget.existingBatch != null) {
      final b = widget.existingBatch!;
      _selectedDate = DateTime.tryParse(b.productionDate) ?? DateTime.now();
      _selectedProduct = b.productName;
      _selectedUnit = b.batchUnit;
      _selectedShift = b.shift ?? AppConstants.determineShift(DateTime.now());
      _selectedSilo = b.siloId ?? (b.notes?.toUpperCase().contains('PMST') == true ? 'PMST' : 'RMST');
      _batchNumberController = TextEditingController(text: b.batchNumber);
      _quantityController =
          TextEditingController(text: Formatters.formatSmart(b.batchQuantity));
      _notesController = TextEditingController(text: b.notes ?? '');
      _operatorController = TextEditingController(text: b.operatorName ?? '');

      for (final ing in b.ingredients) {
        _ingredientRows.add(
          _IngredientRowController(
            id: ing.id.isNotEmpty ? ing.id : const Uuid().v4(),
            name: ing.ingredientName,
            qty: Formatters.formatSmart(ing.quantity),
            unit: ing.unit,
          ),
        );
      }
    } else {
      _selectedDate = DateTime.now();
      _selectedProduct = 'Lassi';
      _selectedUnit = 'L';
      _selectedShift = AppConstants.determineShift(DateTime.now());
      _batchNumberController = TextEditingController();
      _quantityController = TextEditingController(text: '500');
      _notesController = TextEditingController();
      _operatorController = TextEditingController(text: 'Operator');

      // Preload default Lassi recipe rows
      _applyStandardTemplate('Lassi');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isEditMode && _batchNumberController.text.isEmpty) {
      final dateStr = Formatters.formatIsoDate(_selectedDate);
      final generated = ref
          .read(batchRecordsProvider.notifier)
          .generateNextBatchNumber(dateStr, _selectedProduct);
      _batchNumberController.text = generated;
    }
  }

  @override
  void dispose() {
    _batchNumberController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _operatorController.dispose();
    for (final row in _ingredientRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _applyStandardTemplate(String product) {
    for (final row in _ingredientRows) {
      row.dispose();
    }
    _ingredientRows.clear();

    final recipe = BatchRecipeService.getRecipeForProduct(product);
    if (recipe != null) {
      _selectedUnit = recipe.defaultUnit;
      final batchQty = Formatters.parseDouble(_quantityController.text);
      final multiplier = batchQty > 0 ? batchQty / 100.0 : 1.0;

      for (final ing in recipe.ingredients) {
        final calculatedQty = ing.defaultRatio * multiplier;
        _ingredientRows.add(
          _IngredientRowController(
            id: const Uuid().v4(),
            name: ing.ingredientName,
            qty: calculatedQty > 0
                ? Formatters.formatSmart(calculatedQty)
                : (ing.defaultRatio > 0
                    ? Formatters.formatSmart(ing.defaultRatio)
                    : ''),
            unit: ing.unit,
          ),
        );
      }
    } else {
      // Default blank row
      _addBlankIngredientRow();
    }
    setState(() {});
  }

  void _addBlankIngredientRow() {
    setState(() {
      _ingredientRows.add(
        _IngredientRowController(
          id: const Uuid().v4(),
          name: '',
          qty: '',
          unit: _selectedUnit == 'L' ? 'L' : 'kg',
        ),
      );
    });
  }

  void _removeIngredientRow(int index) {
    if (index >= 0 && index < _ingredientRows.length) {
      setState(() {
        _ingredientRows[index].dispose();
        _ingredientRows.removeAt(index);
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        if (!isEditMode) {
          final dateStr = Formatters.formatIsoDate(_selectedDate);
          _batchNumberController.text = ref
              .read(batchRecordsProvider.notifier)
              .generateNextBatchNumber(dateStr, _selectedProduct);
        }
      });
    }
  }

  Future<void> _saveBatch() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ingredientRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one ingredient row.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final dateStr = Formatters.formatIsoDate(_selectedDate);
    final batchQty = Formatters.parseDouble(_quantityController.text);
    final batchId = isEditMode ? widget.existingBatch!.id : const Uuid().v4();

    final List<BatchIngredientModel> ingredients = [];
    for (final row in _ingredientRows) {
      final name = row.nameController.text.trim();
      final qty = Formatters.parseDouble(row.qtyController.text);
      if (name.isEmpty) continue;

      ingredients.add(
        BatchIngredientModel(
          id: row.id,
          batchId: batchId,
          ingredientName: name,
          quantity: qty,
          unit: row.unit,
        ),
      );
    }

    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide ingredient names and quantities.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // DUPLICATE BATCH CHECK:
    // If a batch for the same product and date already exists, ask the user to confirm
    if (!isEditMode) {
      final existingBatches = ref.read(batchRecordsProvider).batches.where(
        (b) => b.productionDate == dateStr &&
               b.productName.trim().toLowerCase() == _selectedProduct.trim().toLowerCase(),
      ).toList();

      if (existingBatches.isNotEmpty) {
        final existing = existingBatches.first;
        final isStd = existing.notes != null &&
            (existing.notes!.contains('Standardized') || existing.batchNumber.startsWith('STD-'));
        final sourceDesc = isStd ? ' (from Milk Standardization)' : '';

        final confirmDuplicate = await ConfirmationDialog.show(
          context: context,
          title: 'Batch Already Recorded for Today',
          message:
              'A batch for "$_selectedProduct" has already been recorded on $dateStr:\n'
              '• Batch #${existing.batchNumber} (${Formatters.formatSmart(existing.batchQuantity)} ${existing.batchUnit}$sourceDesc)\n\n'
              'Are you sure you want to add this batch again?',
          confirmLabel: 'Yes, Add Again',
          cancelLabel: 'Cancel',
        );

        if (!confirmDuplicate) {
          return;
        }
      }
    }

    final now = DateTime.now();
    final effectiveCreatedAt = isEditMode
        ? widget.existingBatch!.createdAt
        : AppConstants.alignDateTimeToShift(
            DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, now.hour, now.minute),
            _selectedShift,
          );

    final record = BatchRecordModel(
      id: batchId,
      productionDate: dateStr,
      productId: _selectedProduct.toUpperCase().replaceAll(' ', '_'),
      productName: _selectedProduct,
      batchNumber: _batchNumberController.text.trim(),
      batchQuantity: batchQty,
      batchUnit: _selectedUnit,
      shift: _selectedShift,
      operatorName: _operatorController.text.trim(),
      notes: _notesController.text.trim().isNotEmpty
          ? '${_notesController.text.trim()} [Silo: $_selectedSilo]'
          : '[Silo: $_selectedSilo]',
      siloId: _selectedSilo,
      ingredients: ingredients,
      createdAt: effectiveCreatedAt,
      updatedAt: DateTime.now(),
    );

    bool success;
    if (isEditMode) {
      success = await ref
          .read(batchRecordsProvider.notifier)
          .updateBatch(record);
    } else {
      success = await ref
          .read(batchRecordsProvider.notifier)
          .createBatch(record);
    }

    if (success && mounted) {
      // Refresh real-time Silo Milk Stock in Lab page & Dashboard
      ref.read(labProvider.notifier).refreshSiloStock();
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = BatchRecipeService.getSupportedProducts();
    final labState = ref.watch(labProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 780),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Title Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.blender_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditMode ? 'Edit Batch Record' : 'Add Batch Record',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppTextSizes.subheading,
                            fontWeight: AppFontWeights.bold,
                          ),
                        ),
                        Text(
                          isEditMode
                              ? 'Modify batch formulation and quantities'
                              : 'Record new production batch & ingredient consumption',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: AppTextSizes.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Modal Body Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section: Batch Specifications
                      Row(
                        children: [
                          Container(
                            width: 3.5,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'BATCH SPECIFICATIONS',
                            style: TextStyle(
                              fontSize: AppTextSizes.caption,
                              fontWeight: AppFontWeights.bold,
                              letterSpacing: 1.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 1: Date & Product
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Production Date
                          Expanded(
                            flex: 5,
                            child: InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(9),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Production Date *',
                                  suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                                ),
                                child: Text(
                                  Formatters.formatIsoDate(_selectedDate),
                                  style: const TextStyle(fontWeight: AppFontWeights.bold, fontSize: AppTextSizes.body),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Product Name Dropdown
                          Expanded(
                            flex: 5,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedProduct,
                              decoration: const InputDecoration(
                                labelText: 'Product Name *',
                                suffixIcon: Icon(Icons.category_rounded, size: 18),
                              ),
                              items: products
                                  .map((p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(p, style: const TextStyle(fontWeight: AppFontWeights.bold)),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedProduct = val;
                                    if (!isEditMode) {
                                      final dateStr = Formatters.formatIsoDate(_selectedDate);
                                      _batchNumberController.text = ref
                                          .read(batchRecordsProvider.notifier)
                                          .generateNextBatchNumber(dateStr, val);
                                      _applyStandardTemplate(val);
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 2: Batch Number & Quantity & Unit
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Batch Number
                          Expanded(
                            flex: 4,
                            child: AppTextField(
                              label: 'Batch Number *',
                              hint: 'e.g. BT-20260928-01',
                              controller: _batchNumberController,
                              validator: (val) => val == null || val.trim().isEmpty
                                  ? 'Enter batch number'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Batch Quantity
                          Expanded(
                            flex: 3,
                            child: AppTextField(
                              label: 'Batch Quantity *',
                              hint: 'e.g. 500',
                              controller: _quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter quantity';
                                final n = Formatters.parseDouble(val);
                                if (n <= 0) return 'Must be > 0';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Batch Unit
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'Batch Unit *',
                              ),
                              items: BatchRecipeService.batchUnits
                                  .map((u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(u, style: const TextStyle(fontWeight: AppFontWeights.bold)),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedUnit = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Shift & Operator
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedShift,
                              decoration: const InputDecoration(
                                labelText: 'Shift',
                                suffixIcon: Icon(Icons.schedule_rounded, size: 18),
                              ),
                              items: AppConstants.shifts
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s, style: const TextStyle(fontSize: AppTextSizes.caption)),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedShift = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AppTextField(
                              label: 'Operator / Technologist',
                              hint: 'e.g. Biraj Goswami',
                              controller: _operatorController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row: Source Milk Silo (RMST / PMST - Deducted from Stock)
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedSilo,
                              decoration: InputDecoration(
                                labelText: 'Source Silo / Tank (Deducts Milk From Stock) *',
                                suffixIcon: const Icon(Icons.storage_rounded, size: 18),
                                helperText: _selectedSilo == 'RMST'
                                    ? 'Current RMST Stock: ${Formatters.formatSmart(labState.rmstStockLitres)} L'
                                    : 'Current PMST Stock: ${Formatters.formatSmart(labState.pmstStockLitres)} L',
                                helperStyle: const TextStyle(fontWeight: AppFontWeights.bold, color: AppColors.primary),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'RMST',
                                  child: Text('RMST (Raw Milk Storage Tank - ${Formatters.formatSmart(labState.rmstStockLitres)} L)'),
                                ),
                                DropdownMenuItem(
                                  value: 'PMST',
                                  child: Text('PMST (Pasteurized Milk Tank - ${Formatters.formatSmart(labState.pmstStockLitres)} L)'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedSilo = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Section: Dynamic Ingredients Rows
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 3.5,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: AppColors.accentCyanDeep,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'INGREDIENTS / RAW MATERIALS USED *',
                                style: TextStyle(
                                  fontSize: AppTextSizes.caption,
                                  fontWeight: AppFontWeights.bold,
                                  letterSpacing: 1.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Reset Template'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _applyStandardTemplate(_selectedProduct),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                'Ingredient Name',
                                style: TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.bold, color: AppColors.textSecondary),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Quantity',
                                style: TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.bold, color: AppColors.textSecondary),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Unit',
                                style: TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.bold, color: AppColors.textSecondary),
                              ),
                            ),
                            SizedBox(width: 40),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Dynamic Row List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ingredientRows.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final row = _ingredientRows[index];
                          return Row(
                            children: [
                              // Ingredient name with autocomplete suggestions
                              Expanded(
                                flex: 5,
                                child: Autocomplete<String>(
                                  initialValue: TextEditingValue(text: row.nameController.text),
                                  optionsBuilder: (textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return BatchRecipeService.commonIngredients;
                                    }
                                    return BatchRecipeService.commonIngredients.where(
                                      (option) => option.toLowerCase().contains(
                                            textEditingValue.text.toLowerCase(),
                                          ),
                                    );
                                  },
                                  onSelected: (selection) {
                                    row.nameController.text = selection;
                                  },
                                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                    // Sync controller with row controller
                                    controller.addListener(() {
                                      row.nameController.text = controller.text;
                                    });
                                    return TextFormField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      style: const TextStyle(fontSize: AppTextSizes.body, fontWeight: AppFontWeights.semiBold),
                                      decoration: InputDecoration(
                                        hintText: 'e.g. Milk, Water, SMP, Sugar',
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        isDense: true,
                                      ),
                                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Quantity
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: row.qtyController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: AppTextSizes.body, fontWeight: AppFontWeights.bold),
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. 300',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    isDense: true,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Required';
                                    final n = Formatters.parseDouble(val);
                                    if (n <= 0) return '> 0';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Unit Dropdown
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  initialValue: row.unit,
                                  isDense: true,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  items: BatchRecipeService.ingredientUnits
                                      .map((u) => DropdownMenuItem(
                                            value: u,
                                            child: Text(u, style: const TextStyle(fontSize: AppTextSizes.caption, fontWeight: AppFontWeights.bold)),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        row.unit = val;
                                      });
                                    }
                                  },
                                ),
                              ),

                              // Remove button
                              SizedBox(
                                width: 40,
                                child: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.danger, size: 20),
                                  tooltip: 'Remove Row',
                                  onPressed: () => _removeIngredientRow(index),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // + Add Ingredient Button
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Ingredient Row'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.2),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _addBlankIngredientRow,
                      ),
                      const SizedBox(height: 20),

                      // Notes
                      AppTextField(
                        label: 'Batch Notes / Remarks (Optional)',
                        hint: 'e.g. Inoculation at 42°C, acidity 0.72%, batch passed QC taste panel',
                        controller: _notesController,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Modal Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: Text(isEditMode ? 'Update Batch Record' : 'Save Batch Record'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: _saveBatch,
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
