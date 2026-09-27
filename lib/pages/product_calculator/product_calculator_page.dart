import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/searchable_dropdown.dart';
import '../../core/widgets/result_card.dart';
import '../../core/widgets/calculation_breakdown.dart';
import '../../core/widgets/status_badge.dart';
import '../../providers/product_calculator_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product_model.dart';

class ProductCalculatorPage extends ConsumerStatefulWidget {
  const ProductCalculatorPage({super.key});

  @override
  ConsumerState<ProductCalculatorPage> createState() => _ProductCalculatorPageState();
}

class _ProductCalculatorPageState extends ConsumerState<ProductCalculatorPage> {
  final TextEditingController _quantityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _onCalculate() {
    if (_formKey.currentState?.validate() ?? false) {
      final qty = Formatters.parseDouble(_quantityController.text);
      ref.read(productCalculatorProvider.notifier).setQuantity(qty);
      ref.read(productCalculatorProvider.notifier).calculate();
    }
  }

  Future<void> _onSave() async {
    final user = ref.read(authProvider);
    final success = await ref.read(productCalculatorProvider.notifier).saveCalculation(
          employeeId: user.employeeCode,
          employeeName: user.name,
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Calculation recorded to plant operational history'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productCalculatorProvider);
    final user = ref.watch(authProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 28,
          vertical: 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title & Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Product Calculator',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Convert quantities across Pieces, Crates, and Volume using verified product master specifications.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Feedback alerts
              if (state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Main Input Area & Metadata Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 850;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Calculation Controls Form
                      Expanded(
                        flex: isWide ? 6 : 12,
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'INPUT SPECIFICATIONS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Product Selection Dropdown
                              SearchableDropdown<ProductModel>(
                                label: 'Select Product',
                                hint: 'Search product master...',
                                items: state.products,
                                selectedItem: state.selectedProduct,
                                itemLabel: (p) => p.productName,
                                itemSubtitle: (p) =>
                                    '${p.category} • ${p.packSizeDisplay} • ${p.piecesPerCrate} pcs/crate',
                                onChanged: (product) {
                                  if (product != null) {
                                    ref.read(productCalculatorProvider.notifier).selectProduct(product);
                                  }
                                },
                              ),
                              const SizedBox(height: 16),

                              // Dynamic Input Mode Selection
                              if (state.selectedProduct != null) ...[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Input Mode',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(Allowed: ${state.selectedProduct!.allowedInputModes.join(', ')})',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: state.selectedProduct!.allowedInputModes.map((mode) {
                                        final isSelected = state.selectedInputMode == mode;
                                        return ChoiceChip(
                                          label: Text(mode),
                                          selected: isSelected,
                                          selectedColor: AppColors.primaryContainer,
                                          backgroundColor: AppColors.background,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                            side: BorderSide(
                                              color: isSelected ? AppColors.primary : AppColors.cardBorder,
                                              width: isSelected ? 1.5 : 1.0,
                                            ),
                                          ),
                                          labelStyle: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                                          ),
                                          onSelected: (selected) {
                                            if (selected) {
                                              ref.read(productCalculatorProvider.notifier).setInputMode(mode);
                                            }
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Quantity Input
                              AppTextField(
                                label: 'Enter Quantity',
                                hint: 'e.g. 3000',
                                controller: _quantityController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                suffixText: state.selectedInputMode,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter a quantity';
                                  }
                                  final n = Formatters.parseDouble(val);
                                  if (n <= 0) return 'Quantity must be greater than zero';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 22),

                              // Calculate Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.calculate, size: 20),
                                  label: const Text('Calculate'),
                                  onPressed: _onCalculate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (isWide) const SizedBox(width: 20),

                      // Product Metadata Card
                      if (isWide && state.selectedProduct != null)
                        Expanded(
                          flex: 6,
                          child: _buildMetadataCard(state.selectedProduct!),
                        ),
                    ],
                  );
                },
              ),

              // If mobile, show metadata card underneath
              if (isMobile && state.selectedProduct != null) ...[
                const SizedBox(height: 16),
                _buildMetadataCard(state.selectedProduct!),
              ],

              // Results Section
              if (state.result != null) ...[
                const SizedBox(height: 24),
                ResultCard(
                  title: 'Calculation Result',
                  subtitle: '${state.selectedProduct?.productName} (${state.selectedInputMode}: ${Formatters.formatSmart(state.enteredQuantity)})',
                  trailingAction: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Save Record', style: TextStyle(fontSize: 12.5)),
                    onPressed: _onSave,
                  ),
                  items: [
                    ResultItem(
                      label: 'Pieces / Pouches',
                      value: Formatters.formatInt(state.result!.pieces),
                      unit: 'Pcs',
                      highlightColor: AppColors.primaryDark,
                    ),
                    ResultItem(
                      label: 'Total Crates',
                      value: Formatters.formatSmart(state.result!.crates),
                      unit: 'Crates',
                      highlightColor: AppColors.primaryDark,
                    ),
                    ResultItem(
                      label: state.selectedProduct?.baseUnitLabel == 'Litres' ? 'Net Volume' : 'Net Weight',
                      value: Formatters.formatSmart(
                        state.selectedProduct?.baseUnitLabel == 'Litres'
                            ? state.result!.volumeLitres
                            : state.result!.weightKg,
                      ),
                      unit: state.selectedProduct?.baseUnitLabel ?? 'Litres',
                      highlightColor: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Collapsible Calculation Breakdown Card
                CalculationBreakdownCard(
                  title: 'How was this calculated?',
                  steps: state.result!.breakdownSteps,
                ),
              ],

              // Recent Calculations History
              const SizedBox(height: 32),
              _buildHistorySection(state.history),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataCard(ProductModel product) {
    return AppCard(
      backgroundColor: const Color(0xFFF9FBFA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PRODUCT METADATA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.primaryDark,
                ),
              ),
              StatusBadge.neutral(product.category),
            ],
          ),
          const SizedBox(height: 14),
          _buildMetaRow('Product Code', product.productId),
          _buildMetaRow('Pack Size', product.packSizeDisplay),
          _buildMetaRow('Base Unit', product.baseUnitLabel),
          _buildMetaRow('Pieces per Crate', '${product.piecesPerCrate} pcs/crate'),
          if (product.targetFat != null)
            _buildMetaRow('Target FAT %', Formatters.formatPercent(product.targetFat!)),
          if (product.targetSnf != null)
            _buildMetaRow('Target SNF %', Formatters.formatPercent(product.targetSnf!)),
          _buildMetaRow('Input Modes', product.allowedInputModes.join(' • ')),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(List history) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: const [
            Icon(Icons.history, size: 36, color: AppColors.textMuted),
            SizedBox(height: 8),
            Text(
              'No previous product calculation records yet.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECENT PRODUCT CALCULATIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),
              StatusBadge.info('${history.length} Saved Records'),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length.clamp(0, 5),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = history[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                title: Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: Text(
                  '${item.date} • ${item.time} • ${item.employeeName}\nInput: ${Formatters.formatSmart(item.inputQuantity)} ${item.inputMode}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${Formatters.formatInt(item.pieces)} pcs (${Formatters.formatSmart(item.crates)} crt)',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryDark),
                    ),
                    Text(
                      '${Formatters.formatSmart(item.volumeLitres)} L',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
