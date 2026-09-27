class ProductModel {
  final String productId;
  final String productName;
  final String category; // Milk, Curd, Fermented, Ghee, Paneer, Sweet
  final String unit; // Litre, Kg, Gram, ml
  final double packSize; // e.g. 500 (ml), 250 (ml), 400 (g), 80 (g), 200 (ml), 1.0 (L)
  final String packSizeDisplay; // e.g. "500 ml", "400 g", "1 L"
  final int piecesPerCrate; // e.g. 20 for 500ml milk pouches
  final List<String> allowedInputModes; // ['Pieces', 'Crates', 'Litres', 'Kg']
  final double? targetFat; // e.g. 4.5 for toned, 6.0 for full cream
  final double? targetSnf; // e.g. 8.5, 9.0
  final bool active;

  const ProductModel({
    required this.productId,
    required this.productName,
    required this.category,
    required this.unit,
    required this.packSize,
    required this.packSizeDisplay,
    required this.piecesPerCrate,
    required this.allowedInputModes,
    this.targetFat,
    this.targetSnf,
    this.active = true,
  });

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

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'category': category,
      'unit': unit,
      'pack_size': packSize,
      'pack_size_display': packSizeDisplay,
      'pieces_per_crate': piecesPerCrate,
      'allowed_input_modes': allowedInputModes,
      'target_fat': targetFat,
      'target_snf': targetSnf,
      'active': active,
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Milk',
      unit: json['unit']?.toString() ?? 'ml',
      packSize: (json['pack_size'] as num?)?.toDouble() ?? 500.0,
      packSizeDisplay: json['pack_size_display']?.toString() ?? '500 ml',
      piecesPerCrate: (json['pieces_per_crate'] as num?)?.toInt() ?? 20,
      allowedInputModes: (json['allowed_input_modes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Pieces', 'Crates', 'Litres'],
      targetFat: (json['target_fat'] as num?)?.toDouble(),
      targetSnf: (json['target_snf'] as num?)?.toDouble(),
      active: json['active'] as bool? ?? true,
    );
  }

  ProductModel copyWith({
    String? productId,
    String? productName,
    String? category,
    String? unit,
    double? packSize,
    String? packSizeDisplay,
    int? piecesPerCrate,
    List<String>? allowedInputModes,
    double? targetFat,
    double? targetSnf,
    bool? active,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      packSize: packSize ?? this.packSize,
      packSizeDisplay: packSizeDisplay ?? this.packSizeDisplay,
      piecesPerCrate: piecesPerCrate ?? this.piecesPerCrate,
      allowedInputModes: allowedInputModes ?? this.allowedInputModes,
      targetFat: targetFat ?? this.targetFat,
      targetSnf: targetSnf ?? this.targetSnf,
      active: active ?? this.active,
    );
  }
}
