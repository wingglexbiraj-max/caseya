import '../models/product_model.dart';
import '../core/widgets/calculation_breakdown.dart';
import '../core/utils/formatters.dart';

class ProductCalculationResult {
  final String productName;
  final String productNameWithQuantity; // e.g. "Sweet Curd Cup 400g (S400) — 150 Crates"
  final int pieces; // Total pieces / individual units
  final double crates; // Total crates or boxes
  final String packingNeeded; // e.g. "150 Crates" or "20 Boxes"
  final String packingBreakdown; // e.g. "150 full crates (0 loose pieces)"
  final double totalQuantity; // in base unit (kg or L)
  final String totalQuantityDisplay; // e.g. "900.0 kg (900000.0 g)"
  final double volumeLitres;
  final double weightKg;
  final double pricePerPiece; // e.g. ₹55.0
  final double totalPrice; // e.g. 123750.0
  final String totalPriceDisplay; // e.g. "₹1,23,750.00" or "Defence Supply" or "Price Pending"
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
  /// Supported Modes: Pieces, Packets, Cups, Bottles, Crates, Boxes, Litres, Kg
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
    final piecesPerCrate = product.piecesPerCrate > 0 ? product.piecesPerCrate : 0;
    final isLiquid = product.baseUnitLabel == 'Litres';
    final smallUnit = isLiquid ? 'ml' : 'g';
    final largeUnit = isLiquid ? 'L' : 'kg';
    final bulkUnitLabel = product.bulkPackingUnit ?? 'Crates';
    final saleUnit = product.individualSaleUnitPlural;

    final modeUpper = inputMode.trim().toUpperCase();

    switch (modeUpper) {
      case 'PIECES':
      case 'PACKETS':
      case 'CUPS':
      case 'BOTTLES':
        pieces = inputQuantity.round();
        if (piecesPerCrate > 0) {
          crates = pieces / piecesPerCrate;
        } else {
          crates = 0.0; // Packaging size not configured
        }
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
          formula: 'Entered ${Formatters.formatInt(pieces)} $saleUnit of ${product.productName}',
          calculation: 'Rate: ${product.priceDisplay}/unit | Pack: ${product.packSizeDisplay}'
              '${piecesPerCrate > 0 ? " | $bulkUnitLabel: $piecesPerCrate pcs" : ""}',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 2: Total Units Required',
          formula: 'Units = Entered Quantity',
          calculation: '${Formatters.formatInt(pieces)} $saleUnit',
        ));
        if (piecesPerCrate > 0) {
          steps.add(BreakdownStep(
            stepTitle: 'Step 3: Packing Needed ($bulkUnitLabel)',
            formula: '$bulkUnitLabel = Total Units ÷ Units per $bulkUnitLabel ($piecesPerCrate)',
            calculation:
                '${Formatters.formatInt(pieces)} $saleUnit ÷ $piecesPerCrate units/$bulkUnitLabel = ${Formatters.formatSmart(crates)} $bulkUnitLabel',
            note: crates == crates.roundToDouble()
                ? '${crates.toInt()} complete whole $bulkUnitLabel'
                : 'Contains partial $bulkUnitLabel: ${crates.floor()} full + ${(pieces % piecesPerCrate)} loose $saleUnit',
          ));
        } else {
          steps.add(BreakdownStep(
            stepTitle: 'Step 3: Bulk Packaging',
            formula: 'Packaging size not specified in product master',
            calculation: 'Dispatched as individual $saleUnit',
          ));
        }
        steps.add(BreakdownStep(
          stepTitle: 'Step 4: Total Quantity ($largeUnit)',
          formula: 'Total Quantity = Units × Pack Size (${product.packSizeDisplay})',
          calculation:
              '${Formatters.formatInt(pieces)} $saleUnit × ${Formatters.formatSmart(packSizeBase)} $largeUnit = ${Formatters.formatSmart(totalQuantity)} $largeUnit (${Formatters.formatSmart(totalQuantity * 1000)} $smallUnit)',
        ));
        break;

      case 'CRATES':
      case 'BOXES':
        crates = inputQuantity;
        final factor = piecesPerCrate > 0 ? piecesPerCrate : 1;
        pieces = (crates * factor).round();
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
          formula: 'Entered ${Formatters.formatSmart(crates)} $bulkUnitLabel of ${product.productName}',
          calculation: 'Rate: ${product.priceDisplay}/unit | Pack: ${product.packSizeDisplay} | $bulkUnitLabel: $piecesPerCrate pcs',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 2: Converted Individual Units',
          formula: 'Units = $bulkUnitLabel × Units per $bulkUnitLabel ($factor)',
          calculation:
              '${Formatters.formatSmart(crates)} $bulkUnitLabel × $factor units = ${Formatters.formatInt(pieces)} $saleUnit',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 3: Total Quantity ($largeUnit)',
          formula: 'Total Quantity = Units × Pack Size (${product.packSizeDisplay})',
          calculation:
              '${Formatters.formatInt(pieces)} $saleUnit × ${Formatters.formatSmart(packSizeBase)} $largeUnit = ${Formatters.formatSmart(totalQuantity)} $largeUnit (${Formatters.formatSmart(totalQuantity * 1000)} $smallUnit)',
        ));
        break;

      case 'LITRES':
      case 'KG':
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
          if (piecesPerCrate > 0) {
            crates = pieces / piecesPerCrate;
          }
        }

        steps.add(BreakdownStep(
          stepTitle: 'Step 1: Product & Quantity Entered',
          formula: 'Entered ${Formatters.formatSmart(totalQuantity)} $largeUnit of ${product.productName}',
          calculation: 'Rate: ${product.priceDisplay}/unit | Pack: ${product.packSizeDisplay}',
        ));
        steps.add(BreakdownStep(
          stepTitle: 'Step 2: Converted Units Required',
          formula: 'Units = Total Quantity ÷ Pack Size (${product.packSizeDisplay})',
          calculation:
              '${Formatters.formatSmart(totalQuantity)} $largeUnit ÷ ${Formatters.formatSmart(packSizeBase)} $largeUnit = ${Formatters.formatInt(pieces)} $saleUnit',
        ));
        break;

      default:
        pieces = inputQuantity.round();
        if (piecesPerCrate > 0) {
          crates = pieces / piecesPerCrate;
        }
        totalQuantity = pieces * packSizeBase;
        volumeLitres = totalQuantity;
        weightKg = totalQuantity;
    }

    // Commercial calculation: Total Price = Pieces * pricePerPiece
    final isCustomPrice = product.priceCustomLabel != null && product.priceCustomLabel!.isNotEmpty;
    final pricePerPiece = product.pricePerPiece;
    final totalPrice = pricePerPiece > 0 ? (pieces * pricePerPiece) : 0.0;
    final totalPriceDisplay = isCustomPrice
        ? product.priceCustomLabel!
        : (pricePerPiece > 0 ? '₹${Formatters.formatSmart(totalPrice)}' : 'Price Unavailable');

    steps.add(BreakdownStep(
      stepTitle: 'Step 5: Total Commercial Value',
      formula: isCustomPrice
          ? 'Allocation: ${product.priceCustomLabel}'
          : (pricePerPiece > 0
              ? 'Total Price = Units × Unit Price (₹${Formatters.formatSmart(pricePerPiece)})'
              : 'Price not configured in master'),
      calculation: isCustomPrice
          ? '${Formatters.formatInt(pieces)} $saleUnit allocated under ${product.priceCustomLabel}'
          : (pricePerPiece > 0
              ? '${Formatters.formatInt(pieces)} $saleUnit × ₹${Formatters.formatSmart(pricePerPiece)} = $totalPriceDisplay'
              : 'Commercial value unavailable'),
    ));

    final isWholeCrates = crates == crates.roundToDouble();
    final packingNeeded = piecesPerCrate > 0
        ? '${Formatters.formatSmart(crates)} $bulkUnitLabel'
        : 'Individual Units Only';
    final packingBreakdown = piecesPerCrate > 0
        ? (isWholeCrates
            ? '${crates.toInt()} full $bulkUnitLabel ($piecesPerCrate pcs/$bulkUnitLabel)'
            : '${crates.floor()} full $bulkUnitLabel + ${(pieces % piecesPerCrate)} loose $saleUnit')
        : 'Packaging size not specified';

    final totalQuantityDisplay =
        '${Formatters.formatSmart(totalQuantity)} $largeUnit (${Formatters.formatSmart(totalQuantity * 1000)} $smallUnit)';

    final productNameWithQuantity =
        '${product.productName} — ${Formatters.formatSmart(inputQuantity)} $inputMode';

    final summary = '${product.productName} | '
        '${Formatters.formatInt(pieces)} $saleUnit | '
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
