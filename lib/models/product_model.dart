class ProductModel {
  final String productId;
  final String productName;
  final String itemCode; // e.g. 9900010, 9900026, NA
  final String shortCode; // e.g. S400, P80, P400, PL200, CP400, CP1000
  final String category; // Curd, Fermented, Milk, Ghee, Paneer, Sweet, Honey, Flavoured Milk
  final String unit; // Litre, Kg, Gram, ml, g
  final double packSize; // e.g. 400 (g), 80 (g), 200 (ml), 1000 (g), 500 (ml)
  final String packSizeDisplay; // e.g. "400 g", "80 g", "200 ml", "1 kg"
  final int piecesPerCrate; // e.g. 15, 60, 30, 12, 20, 0 if not specified
  final double? perCrateQty; // e.g. 6.0 kg, 4.8 kg, 12.0 kg
  final double? perCrateQtyGrams; // e.g. 6000.0 g
  final String? perCrateDisplay; // e.g. "6.0 kg (6000.0 g)", "6.0 L (6000.0 ml)"
  final double pricePerPiece; // e.g. 55.0, 15.0, 20.0, 35.0, 75.0, 0.0 if not specified
  final String? priceCustomLabel; // e.g. "Defence Supply", "Price Pending"
  final String individualSaleUnit; // 'packet', 'cup', 'bottle'
  final String? bulkPackingUnit; // 'Crates', 'Boxes', null
  final String shelfLife; // e.g. "12 Days", "7 Days", "90 Days"
  final List<String> allowedInputModes; // ['Packets', 'Cups', 'Bottles', 'Crates', 'Boxes', 'Pieces']
  final double? targetFat; // e.g. 4.5 for toned, 6.0 for full cream
  final double? targetSnf; // e.g. 8.5, 9.0
  final double? targetSugar; // e.g. 12.0%, 15.0% or null (NA)
  final bool active;

  const ProductModel({
    required this.productId,
    required this.productName,
    this.itemCode = 'NA',
    this.shortCode = '',
    required this.category,
    required this.unit,
    required this.packSize,
    required this.packSizeDisplay,
    required this.piecesPerCrate,
    this.perCrateQty,
    this.perCrateQtyGrams,
    this.perCrateDisplay,
    this.pricePerPiece = 0.0,
    this.priceCustomLabel,
    this.individualSaleUnit = 'packet',
    this.bulkPackingUnit,
    this.shelfLife = '12 Days',
    required this.allowedInputModes,
    this.targetFat,
    this.targetSnf,
    this.targetSugar,
    this.active = true,
  });

  /// Check whether bulk packaging (crates / boxes) is configured
  bool get hasCrateConfiguration => piecesPerCrate > 0;

  /// Check whether commercial sale unit price is configured
  bool get hasPriceConfiguration => pricePerPiece > 0;

  /// Plural sale unit display (e.g. "packets", "cups", "bottles")
  String get individualSaleUnitPlural {
    final lower = individualSaleUnit.toLowerCase().trim();
    if (lower == 'cup') return 'cups';
    if (lower == 'bottle') return 'bottles';
    if (lower == 'packet') return 'packets';
    if (lower.endsWith('s')) return lower;
    return '${lower}s';
  }

  /// Capitalized sale unit (e.g. "Packets", "Cups", "Bottles")
  String get capitalizedSaleUnit {
    final plural = individualSaleUnitPlural;
    return '${plural[0].toUpperCase()}${plural.substring(1)}';
  }

  /// Formatted target sugar string (e.g. "12%", "15%", "NA")
  String get targetSugarDisplay {
    if (targetSugar == null) return 'NA';
    final formatted = targetSugar == targetSugar!.roundToDouble()
        ? targetSugar!.toInt().toString()
        : targetSugar!.toStringAsFixed(1);
    return '$formatted%';
  }

  /// Pack size in base unit: Litres (for liquid) or Kg (for solids)
  double get packSizeInBaseUnit {
    final lowerUnit = unit.toLowerCase();
    if (lowerUnit == 'ml') {
      return packSize / 1000.0;
    } else if (lowerUnit == 'gram' || lowerUnit == 'g') {
      return packSize / 1000.0;
    }
    return packSize; // already Litres or Kg
  }

  String get baseUnitLabel {
    final lowerUnit = unit.toLowerCase();
    if (lowerUnit == 'ml' || lowerUnit == 'litre' || lowerUnit == 'l') {
      return 'Litres';
    }
    return 'Kg';
  }

  /// Product code alias (e.g. S200, S80, S400, P80, P400, PL200, PP250, PP500, smart+500)
  String get productCode => shortCode.isNotEmpty ? shortCode : productId;

  /// Price display string (handles custom labels like "Defence Supply", "Price Pending")
  String get priceDisplay {
    if (priceCustomLabel != null && priceCustomLabel!.isNotEmpty) {
      return priceCustomLabel!;
    }
    if (pricePerPiece <= 0) {
      return 'Price Unavailable';
    }
    final formatted = pricePerPiece == pricePerPiece.roundToDouble()
        ? pricePerPiece.toInt().toString()
        : pricePerPiece.toStringAsFixed(2);
    return '₹$formatted';
  }

  /// Formatted per crate display, e.g., "6.0 kg (6000.0 g)"
  String get calculatedPerCrateDisplay {
    if (perCrateDisplay != null && perCrateDisplay!.isNotEmpty) {
      return perCrateDisplay!;
    }
    if (!hasCrateConfiguration) {
      return 'Packaging Unconfigured';
    }
    final totalBase = piecesPerCrate * packSizeInBaseUnit;
    final totalSmall = totalBase * 1000.0;
    final smallUnit = baseUnitLabel == 'Litres' ? 'ml' : 'g';
    final largeUnit = baseUnitLabel == 'Litres' ? 'L' : 'kg';
    return '${totalBase.toStringAsFixed(1)} $largeUnit (${totalSmall.toStringAsFixed(1)} $smallUnit)';
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'item_code': itemCode,
      'short_code': shortCode,
      'category': category,
      'unit': unit,
      'pack_size': packSize,
      'pack_size_display': packSizeDisplay,
      'pieces_per_crate': piecesPerCrate,
      'per_crate_qty': perCrateQty,
      'per_crate_qty_grams': perCrateQtyGrams,
      'per_crate_display': perCrateDisplay,
      'price_per_piece': pricePerPiece,
      'price_custom_label': priceCustomLabel,
      'individual_sale_unit': individualSaleUnit,
      'bulk_packing_unit': bulkPackingUnit,
      'shelf_life': shelfLife,
      'allowed_input_modes': allowedInputModes,
      'target_fat': targetFat,
      'target_snf': targetSnf,
      'target_sugar': targetSugar,
      'active': active,
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final unitVal = json['unit']?.toString() ?? 'g';
    final packSizeVal = (json['pack_size'] as num?)?.toDouble() ?? 400.0;
    final pcsCrate = (json['pieces_per_crate'] as num?)?.toInt() ?? 0;

    return ProductModel(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      itemCode: json['item_code']?.toString() ?? 'NA',
      shortCode: json['short_code']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Curd',
      unit: unitVal,
      packSize: packSizeVal,
      packSizeDisplay: json['pack_size_display']?.toString() ?? '$packSizeVal $unitVal',
      piecesPerCrate: pcsCrate,
      perCrateQty: (json['per_crate_qty'] as num?)?.toDouble(),
      perCrateQtyGrams: (json['per_crate_qty_grams'] as num?)?.toDouble(),
      perCrateDisplay: json['per_crate_display']?.toString(),
      pricePerPiece: (json['price_per_piece'] as num?)?.toDouble() ?? 0.0,
      priceCustomLabel: json['price_custom_label']?.toString(),
      individualSaleUnit: json['individual_sale_unit']?.toString() ?? 'packet',
      bulkPackingUnit: json['bulk_packing_unit']?.toString(),
      shelfLife: json['shelf_life']?.toString() ?? '12 Days',
      allowedInputModes: (json['allowed_input_modes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Packets', 'Crates'],
      targetFat: (json['target_fat'] as num?)?.toDouble(),
      targetSnf: (json['target_snf'] as num?)?.toDouble(),
      targetSugar: (json['target_sugar'] as num?)?.toDouble(),
      active: json['active'] as bool? ?? true,
    );
  }

  ProductModel copyWith({
    String? productId,
    String? productName,
    String? itemCode,
    String? shortCode,
    String? category,
    String? unit,
    double? packSize,
    String? packSizeDisplay,
    int? piecesPerCrate,
    double? perCrateQty,
    double? perCrateQtyGrams,
    String? perCrateDisplay,
    double? pricePerPiece,
    String? priceCustomLabel,
    String? individualSaleUnit,
    String? bulkPackingUnit,
    String? shelfLife,
    List<String>? allowedInputModes,
    double? targetFat,
    double? targetSnf,
    double? targetSugar,
    bool? active,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      itemCode: itemCode ?? this.itemCode,
      shortCode: shortCode ?? this.shortCode,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      packSize: packSize ?? this.packSize,
      packSizeDisplay: packSizeDisplay ?? this.packSizeDisplay,
      piecesPerCrate: piecesPerCrate ?? this.piecesPerCrate,
      perCrateQty: perCrateQty ?? this.perCrateQty,
      perCrateQtyGrams: perCrateQtyGrams ?? this.perCrateQtyGrams,
      perCrateDisplay: perCrateDisplay ?? this.perCrateDisplay,
      pricePerPiece: pricePerPiece ?? this.pricePerPiece,
      priceCustomLabel: priceCustomLabel ?? this.priceCustomLabel,
      individualSaleUnit: individualSaleUnit ?? this.individualSaleUnit,
      bulkPackingUnit: bulkPackingUnit ?? this.bulkPackingUnit,
      shelfLife: shelfLife ?? this.shelfLife,
      allowedInputModes: allowedInputModes ?? this.allowedInputModes,
      targetFat: targetFat ?? this.targetFat,
      targetSnf: targetSnf ?? this.targetSnf,
      targetSugar: targetSugar ?? this.targetSugar,
      active: active ?? this.active,
    );
  }
}
