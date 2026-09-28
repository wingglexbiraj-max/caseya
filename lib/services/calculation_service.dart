import '../models/product_model.dart';
import '../core/widgets/calculation_breakdown.dart';
import '../core/utils/formatters.dart';

class ProductCalculationResult {
  final String productName;
  final String productNameWithQuantity; // e.g. "Sweet Curd Cup 400g (S400) — 150 Crates"
  final int pieces; // Total pieces required
  final double crates; // Total crates
  final String packingNeeded; // e.g. "150 Crates"
  final String packingBreakdown; // e.g. "150 full crates (0 loose pieces)"
  final double totalQuantity; // in base unit (kg or L)
  final String totalQuantityDisplay; // e.g. "900.0 kg (900000.0 g)"
  final double volumeLitres;
  final double weightKg;
  final double pricePerPiece; // e.g. ₹55.0
  final double totalPrice; // e.g. 123750.0
  final String totalPriceDisplay; // e.g. "₹1,23,750.00"
  final List<BreakdownStep> breakdownSteps;
  final String summaryText;

  const ProductCalculationResult({
    required this.productName,
    required this.productNameWithQuantity,
    required this.pieces,
    required this.crates,
    required this.packingNeeded,
    required this.packingBreakdown,
    required this.totalQuantity,
    required this.totalQuantityDisplay,
    required this.volumeLitres,
    required this.weightKg,
    required this.pricePerPiece,
    required this.totalPrice,
    required this.totalPriceDisplay,
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
    double totalQuantity = 0.0;
    double volumeLitres = 0.0;
    double weightKg = 0.0;
    final List<BreakdownStep> steps = [];

    final packSizeBase = product.packSizeInBaseUnit; // in Litres or Kg
    final piecesPerCrate = product.piecesPerCrate > 0 ? product.piecesPerCrate : 1;
    final isLiquid = product.baseUnitLabel == 'Litres';
    final smallUnit = isLiquid ? 'ml' : 'g';
    final largeUnit = isLiquid ? 'L' : 'kg';

    switch (inputMode) {
      case 'Pieces':
        pieces = inputQuantity.round();
        crates = pieces / piecesPerCrate;
        totalQuantity = pieces * packSizeBase;
        if (isLiquid) {
          volumeLitres = totalQuantity;
          weightKg = totalQuantity * 1.03; // Approximate dairy density ~1.03 kg/L
        } else {
          weightKg = totalQuantity;
          volumeLitres = totalQuantity;
        }

        steps.add(BreakdownStep(
          stepTitle: 'Step 1: Product & Input Specification',
          formula: 'Entered ${Formatters.formatInt(pieces)} pieces of ${product.productName}',
          calculation: 'Rate: ${product.priceDisplay}/pc | Pack: ${product.packSizeDisplay} | Crate: $piecesPerCrate pcs',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 2: Total Pieces Required',
          formula: 'Pieces = Entered Quantity',
          calculation: '${Formatters.formatInt(pieces)} pieces',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 3: Packing Needed (Crates)',
          formula: 'Crates = Total Pieces ÷ Pieces per Crate ($piecesPerCrate)',
          calculation:
              '${Formatters.formatInt(pieces)} pieces ÷ $piecesPerCrate pieces/crate = ${Formatters.formatSmart(crates)} crates',
          note: crates == crates.roundToDouble()
              ? '${crates.toInt()} complete whole crates'
              : 'Contains partial crate: ${crates.floor()} full crates + ${(pieces % piecesPerCrate)} loose pieces',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 4: Total Quantity ($largeUnit)',
          formula: 'Total Quantity = Pieces × Pack Size (${product.packSizeDisplay})',
          calculation:
              '${Formatters.formatInt(pieces)} pieces × ${Formatters.formatSmart(packSizeBase)} $largeUnit = ${Formatters.formatSmart(totalQuantity)} $largeUnit (${Formatters.formatSmart(totalQuantity * 1000)} $smallUnit)',
        ));
        break;

      case 'Crates':
        crates = inputQuantity;
        pieces = (crates * piecesPerCrate).round();
        totalQuantity = pieces * packSizeBase;
        if (isLiquid) {
          volumeLitres = totalQuantity;
          weightKg = totalQuantity * 1.03;
        } else {
          weightKg = totalQuantity;
          volumeLitres = totalQuantity;
        }

        steps.add(BreakdownStep(
          stepTitle: 'Step 1: Product & Input Specification',
          formula: 'Entered ${Formatters.formatSmart(crates)} crates of ${product.productName}',
          calculation: 'Rate: ${product.priceDisplay}/pc | Pack: ${product.packSizeDisplay} | Crate: $piecesPerCrate pcs',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 2: Total Pieces Required',
          formula: 'Pieces = Crates × Pieces per Crate ($piecesPerCrate)',
          calculation:
              '${Formatters.formatSmart(crates)} crates × $piecesPerCrate pcs/crate = ${Formatters.formatInt(pieces)} pieces',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 3: Packing Needed (Crates)',
          formula: 'Crates = Entered Quantity',
          calculation: '${Formatters.formatSmart(crates)} crates (${piecesPerCrate} pcs/crate)',
          note: crates == crates.roundToDouble()
              ? '${crates.toInt()} complete whole crates'
              : '${crates.floor()} full crates + ${(pieces % piecesPerCrate)} loose pieces',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 4: Total Quantity ($largeUnit)',
          formula: 'Total Quantity = Pieces × Pack Size (${product.packSizeDisplay})',
          calculation:
              '${Formatters.formatInt(pieces)} pieces × ${Formatters.formatSmart(packSizeBase)} $largeUnit = ${Formatters.formatSmart(totalQuantity)} $largeUnit (${Formatters.formatSmart(totalQuantity * 1000)} $smallUnit)',
        ));
        break;

      case 'Litres':
      case 'Kg':
        totalQuantity = inputQuantity;
        if (isLiquid) {
          volumeLitres = totalQuantity;
          weightKg = totalQuantity * 1.03;
        } else {
          weightKg = totalQuantity;
          volumeLitres = totalQuantity;
        }

        if (packSizeBase > 0) {
          final rawPieces = totalQuantity / packSizeBase;
          pieces = rawPieces.round();
          crates = pieces / piecesPerCrate;
        }

        steps.add(BreakdownStep(
          stepTitle: 'Step 1: Product & Quantity Entered',
          formula: 'Entered ${Formatters.formatSmart(totalQuantity)} $largeUnit of ${product.productName}',
          calculation: 'Rate: ${product.priceDisplay}/pc | Pack: ${product.packSizeDisplay} | Crate: $piecesPerCrate pcs',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 2: Total Pieces Required',
          formula: 'Pieces = Total Quantity ÷ Pack Size (${product.packSizeDisplay})',
          calculation:
              '${Formatters.formatSmart(totalQuantity)} $largeUnit ÷ ${Formatters.formatSmart(packSizeBase)} $largeUnit = ${Formatters.formatInt(pieces)} pieces',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 3: Packing Needed (Crates)',
          formula: 'Crates = Total Pieces ÷ Pieces per Crate ($piecesPerCrate)',
          calculation:
              '${Formatters.formatInt(pieces)} pieces ÷ $piecesPerCrate = ${Formatters.formatSmart(crates)} crates',
          note: crates == crates.roundToDouble()
              ? '${crates.toInt()} complete whole crates'
              : '${crates.floor()} full crates + ${(pieces % piecesPerCrate)} loose pieces',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 4: Total Quantity Verified',
          formula: 'Verified = ${Formatters.formatInt(pieces)} pieces × ${product.packSizeDisplay}',
          calculation:
              '${Formatters.formatSmart(totalQuantity)} $largeUnit (${Formatters.formatSmart(totalQuantity * 1000)} $smallUnit)',
        ));
        break;

      default:
        pieces = inputQuantity.round();
        crates = pieces / piecesPerCrate;
        totalQuantity = pieces * packSizeBase;
        volumeLitres = totalQuantity;
        weightKg = totalQuantity;
    }

    // Commercial calculation: Total Price = Pieces * pricePerPiece
    final isCustomPrice = product.priceCustomLabel != null && product.priceCustomLabel!.isNotEmpty;
    final pricePerPiece = product.pricePerPiece;
    final totalPrice = pieces * pricePerPiece;
    final totalPriceDisplay = isCustomPrice
        ? product.priceCustomLabel!
        : '₹${Formatters.formatSmart(totalPrice)}';

    steps.add(BreakdownStep(
      stepTitle: 'Step 5: Total Price (Commercial Value)',
      formula: isCustomPrice
          ? 'Allocation Category: ${product.priceCustomLabel}'
          : 'Total Price = Total Pieces × Price per Piece (₹${Formatters.formatSmart(pricePerPiece)})',
      calculation: isCustomPrice
          ? '${Formatters.formatInt(pieces)} pieces allocated under ${product.priceCustomLabel}'
          : '${Formatters.formatInt(pieces)} pieces × ₹${Formatters.formatSmart(pricePerPiece)} = $totalPriceDisplay',
    ));

    final isWholeCrates = crates == crates.roundToDouble();
    final packingNeeded = '${Formatters.formatSmart(crates)} Crates';
    final packingBreakdown = isWholeCrates
        ? '${crates.toInt()} full crates (${piecesPerCrate} pcs/crate)'
        : '${crates.floor()} full crates + ${(pieces % piecesPerCrate)} loose pieces';

    final totalQuantityDisplay =
        '${Formatters.formatSmart(totalQuantity)} $largeUnit (${Formatters.formatSmart(totalQuantity * 1000)} $smallUnit)';

    final productNameWithQuantity =
        '${product.productName} — ${Formatters.formatSmart(inputQuantity)} $inputMode';

    final summary = '${product.productName} | '
        '${Formatters.formatInt(pieces)} Pieces | '
        '$packingNeeded | '
        '${Formatters.formatSmart(totalQuantity)} $largeUnit | '
        '$totalPriceDisplay';

    return ProductCalculationResult(
      productName: product.productName,
      productNameWithQuantity: productNameWithQuantity,
      pieces: pieces,
      crates: crates,
      packingNeeded: packingNeeded,
      packingBreakdown: packingBreakdown,
      totalQuantity: totalQuantity,
      totalQuantityDisplay: totalQuantityDisplay,
      volumeLitres: volumeLitres,
      weightKg: weightKg,
      pricePerPiece: pricePerPiece,
      totalPrice: totalPrice,
      totalPriceDisplay: totalPriceDisplay,
      breakdownSteps: steps,
      summaryText: summary,
    );
  }
}
