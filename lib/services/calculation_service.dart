import '../models/product_model.dart';
import '../core/widgets/calculation_breakdown.dart';
import '../core/utils/formatters.dart';

class ProductCalculationResult {
  final int pieces;
  final double crates;
  final double volumeLitres;
  final double weightKg;
  final List<BreakdownStep> breakdownSteps;
  final String summaryText;

  const ProductCalculationResult({
    required this.pieces,
    required this.crates,
    required this.volumeLitres,
    required this.weightKg,
    required this.breakdownSteps,
    required this.summaryText,
  });
}

class CalculationService {
  /// Calculate product conversions based on product metadata and selected input mode
  /// Supported Modes: Pieces, Crates, Litres, Kg
  static ProductCalculationResult calculateProduct({
    required ProductModel product,
    required String inputMode,
    required double inputQuantity,
  }) {
    int pieces = 0;
    double crates = 0.0;
    double volumeLitres = 0.0;
    double weightKg = 0.0;
    final List<BreakdownStep> steps = [];

    final packSizeBase = product.packSizeInBaseUnit; // in Litres or Kg
    final piecesPerCrate = product.piecesPerCrate > 0 ? product.piecesPerCrate : 1;
    final isLiquid = product.baseUnitLabel == 'Litres';

    switch (inputMode) {
      case 'Pieces':
        pieces = inputQuantity.round();
        crates = pieces / piecesPerCrate;
        final baseTotal = pieces * packSizeBase;
        if (isLiquid) {
          volumeLitres = baseTotal;
          // Approximate dairy density ~1.03 kg/L for milk
          weightKg = baseTotal * 1.03;
        } else {
          weightKg = baseTotal;
          volumeLitres = baseTotal;
        }

        steps.add(BreakdownStep(
          stepTitle: 'Step 1: Pieces',
          formula: 'Pieces = Entered Quantity',
          calculation: '${Formatters.formatInt(pieces)} pieces',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 2: Volume / Weight',
          formula: 'Volume = Pieces × Pack Size (${product.packSizeDisplay})',
          calculation:
              '${Formatters.formatInt(pieces)} pieces × ${Formatters.formatSmart(packSizeBase)} ${product.baseUnitLabel} = ${Formatters.formatSmart(isLiquid ? volumeLitres : weightKg)} ${product.baseUnitLabel}',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 3: Crates',
          formula: 'Crates = Pieces ÷ Pieces per Crate ($piecesPerCrate)',
          calculation:
              '${Formatters.formatInt(pieces)} pieces ÷ $piecesPerCrate pieces/crate = ${Formatters.formatSmart(crates)} crates',
          note: crates == crates.roundToDouble()
              ? 'Complete whole crates'
              : 'Contains partial crate: ${crates.floor()} full crates + ${(pieces % piecesPerCrate)} loose pouches',
        ));
        break;

      case 'Crates':
        crates = inputQuantity;
        pieces = (crates * piecesPerCrate).round();
        final baseTotal = pieces * packSizeBase;
        if (isLiquid) {
          volumeLitres = baseTotal;
          weightKg = baseTotal * 1.03;
        } else {
          weightKg = baseTotal;
          volumeLitres = baseTotal;
        }

        steps.add(BreakdownStep(
          stepTitle: 'Step 1: Crates',
          formula: 'Crates = Entered Quantity',
          calculation: '${Formatters.formatSmart(crates)} crates',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 2: Pieces from Crates',
          formula: 'Pieces = Crates × Pieces per Crate ($piecesPerCrate)',
          calculation:
              '${Formatters.formatSmart(crates)} crates × $piecesPerCrate = ${Formatters.formatInt(pieces)} pieces',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 3: Volume / Weight',
          formula: 'Volume = Pieces × Pack Size (${product.packSizeDisplay})',
          calculation:
              '${Formatters.formatInt(pieces)} pieces × ${Formatters.formatSmart(packSizeBase)} ${product.baseUnitLabel} = ${Formatters.formatSmart(isLiquid ? volumeLitres : weightKg)} ${product.baseUnitLabel}',
        ));
        break;

      case 'Litres':
      case 'Kg':
        final enteredBase = inputQuantity;
        if (isLiquid) {
          volumeLitres = enteredBase;
          weightKg = enteredBase * 1.03;
        } else {
          weightKg = enteredBase;
          volumeLitres = enteredBase;
        }

        if (packSizeBase > 0) {
          final rawPieces = enteredBase / packSizeBase;
          pieces = rawPieces.round();
          crates = pieces / piecesPerCrate;
        }

        steps.add(BreakdownStep(
          stepTitle: 'Step 1: Volume / Weight Entered',
          formula: 'Input = Entered Quantity',
          calculation: '${Formatters.formatSmart(enteredBase)} ${product.baseUnitLabel}',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 2: Pouches / Pieces',
          formula: 'Pieces = Total Volume ÷ Pack Size (${product.packSizeDisplay})',
          calculation:
              '${Formatters.formatSmart(enteredBase)} ${product.baseUnitLabel} ÷ ${Formatters.formatSmart(packSizeBase)} = ${Formatters.formatInt(pieces)} pieces',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 3: Crates Required',
          formula: 'Crates = Pieces ÷ Pieces per Crate ($piecesPerCrate)',
          calculation:
              '${Formatters.formatInt(pieces)} pieces ÷ $piecesPerCrate = ${Formatters.formatSmart(crates)} crates',
        ));
        break;

      default:
        pieces = inputQuantity.round();
        crates = pieces / piecesPerCrate;
        volumeLitres = pieces * packSizeBase;
        weightKg = volumeLitres;
    }

    final summary = '${Formatters.formatInt(pieces)} Pieces | '
        '${Formatters.formatSmart(crates)} Crates | '
        '${Formatters.formatSmart(isLiquid ? volumeLitres : weightKg)} ${product.baseUnitLabel}';

    return ProductCalculationResult(
      pieces: pieces,
      crates: crates,
      volumeLitres: volumeLitres,
      weightKg: weightKg,
      breakdownSteps: steps,
      summaryText: summary,
    );
  }
}
