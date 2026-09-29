import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../providers/products_master_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product_model.dart';

class ProductsMasterPage extends ConsumerStatefulWidget {
  const ProductsMasterPage({super.key});

  @override
  ConsumerState<ProductsMasterPage> createState() => _ProductsMasterPageState();
}

class _ProductsMasterPageState extends ConsumerState<ProductsMasterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController(text: 'Milk');
  final TextEditingController _packSizeController = TextEditingController(text: '500');
  final TextEditingController _unitController = TextEditingController(text: 'ml');
  final TextEditingController _packDisplayController = TextEditingController(text: '500 ml');
  final TextEditingController _cratePiecesController = TextEditingController(text: '20');
  final TextEditingController _fatController = TextEditingController(text: '4.5');
  final TextEditingController _snfController = TextEditingController(text: '8.5');

  final List<String> _selectedModes = ['Pieces', 'Crates', 'Litres'];
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _packSizeController.dispose();
    _unitController.dispose();
    _packDisplayController.dispose();
    _cratePiecesController.dispose();
    _fatController.dispose();
    _snfController.dispose();
    super.dispose();
  }

  void _openProductDialog([ProductModel? product]) {
    if (product != null) {
      _nameController.text = product.productName;
      _categoryController.text = product.category;
      _packSizeController.text = Formatters.formatSmart(product.packSize);
      _unitController.text = product.unit;
      _packDisplayController.text = product.packSizeDisplay;
      _cratePiecesController.text = product.piecesPerCrate.toString();
      _fatController.text = product.targetFat?.toString() ?? '';
      _snfController.text = product.targetSnf?.toString() ?? '';
      _selectedModes.clear();
      _selectedModes.addAll(product.allowedInputModes);
    } else {
      _nameController.clear();
      _categoryController.text = 'Milk';
      _packSizeController.text = '500';
      _unitController.text = 'ml';
      _packDisplayController.text = '500 ml';
      _cratePiecesController.text = '20';
      _fatController.text = '4.5';
      _snfController.text = '8.5';
      _selectedModes.clear();
      _selectedModes.addAll(['Pieces', 'Crates', 'Litres']);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: Text(
              product == null ? 'Add Product Master' : 'Edit ${product.productName}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTextField(
                        label: 'Product Name',
                        hint: 'e.g. Purabi Plus Milk 500 ml',
                        controller: _nameController,
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Category',
                              hint: 'Milk, Curd, Ghee',
                              controller: _categoryController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              label: 'Pack Size',
                              hint: '500',
                              controller: _packSizeController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Unit',
                              hint: 'ml, g, L, Kg',
                              controller: _unitController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              label: 'Display Label',
                              hint: '500 ml',
                              controller: _packDisplayController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Pieces / Crate',
                              hint: '20',
                              controller: _cratePiecesController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              label: 'Target FAT %',
                              hint: '4.5',
                              controller: _fatController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              label: 'Target SNF %',
                              hint: '8.5',
                              controller: _snfController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text('Allowed Input Modes:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: ['Pieces', 'Crates', 'Litres', 'Kg'].map((mode) {
                          final selected = _selectedModes.contains(mode);
                          return FilterChip(
                            label: Text(mode),
                            selected: selected,
                            onSelected: (val) {
                              setModalState(() {
                                if (val) {
                                  _selectedModes.add(mode);
                                } else {
                                  if (_selectedModes.length > 1) {
                                    _selectedModes.remove(mode);
                                  }
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    final item = ProductModel(
                      productId: product?.productId ?? 'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      productName: _nameController.text.trim(),
                      category: _categoryController.text.trim(),
                      unit: _unitController.text.trim(),
                      packSize: Formatters.parseDouble(_packSizeController.text),
                      packSizeDisplay: _packDisplayController.text.trim(),
                      piecesPerCrate: int.tryParse(_cratePiecesController.text) ?? 20,
                      allowedInputModes: List.from(_selectedModes),
                      targetFat: double.tryParse(_fatController.text),
                      targetSnf: double.tryParse(_snfController.text),
                      active: true,
                    );
                    await ref.read(productsMasterProvider.notifier).saveProduct(item);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Save Product'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsMasterProvider);
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
            if (user.isAdmin || user.isSupervisor) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Product'),
                    onPressed: () => _openProductDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],

            AppCard(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.products.length,
                separatorBuilder: (_, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = state.products[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    p.productName,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusBadge.neutral(p.category, fontSize: 11),
                                  if (p.productCode.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySurface,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.primaryLight),
                                      ),
                                      child: Text(
                                        'Code: ${p.productCode}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Item Code: ${p.itemCode}  •  Pack: ${p.packSizeDisplay}  •  ${p.piecesPerCrate} pcs/crate (${p.calculatedPerCrateDisplay})  •  ₹${Formatters.formatSmart(p.pricePerPiece)}/pc  •  Shelf Life: ${p.shelfLife}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Base Unit: ${p.baseUnitLabel}${p.targetFat != null ? '  •  Target FAT: ${Formatters.formatPercent(p.targetFat!)}' : ''}${p.targetSnf != null ? '  •  Target SNF: ${Formatters.formatPercent(p.targetSnf!)}' : ''}  •  Allowed: ${p.allowedInputModes.join(', ')}',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        if (user.isAdmin || user.isSupervisor) ...[
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                            onPressed: () => _openProductDialog(p),
                            tooltip: 'Edit Product',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                            onPressed: () async {
                              final confirm = await ConfirmationDialog.show(
                                context: context,
                                title: 'Delete Product',
                                message: 'Are you sure you want to remove "${p.productName}" from the product master?',
                                isDestructive: true,
                              );
                              if (confirm) {
                                ref.read(productsMasterProvider.notifier).deleteProduct(p.productId);
                              }
                            },
                            tooltip: 'Delete Product',
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
