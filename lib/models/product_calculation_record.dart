class ProductCalculationRecord {
  final String recordId;
  final String date; // YYYY-MM-DD
  final String time; // HH:mm AM/PM
  final String employeeId;
  final String employeeName;
  final String productId;
  final String productName;
  final String productNameWithQuantity; // e.g. "Sweet Curd Cup 400g (S400) — 150 Crates"
  final String inputMode; // Pieces, Crates, Litres, Kg
  final double inputQuantity;
  final int pieces; // Total pieces required
  final double crates; // Crates
  final String packingNeeded; // e.g. "150 Crates"
  final double volumeLitres;
  final double weightKg;
  final String totalQuantityDisplay; // e.g. "900.0 kg"
  final double pricePerPiece; // e.g. 55.0
  final double totalPrice; // e.g. 123750.0
  final String totalPriceDisplay; // e.g. "₹1,23,750.00"
  final String breakdownText;
  final DateTime createdAt;

  const ProductCalculationRecord({
    required this.recordId,
    required this.date,
    required this.time,
    required this.employeeId,
    required this.employeeName,
    required this.productId,
    required this.productName,
    this.productNameWithQuantity = '',
    required this.inputMode,
    required this.inputQuantity,
    required this.pieces,
    required this.crates,
    this.packingNeeded = '',
    required this.volumeLitres,
    required this.weightKg,
    this.totalQuantityDisplay = '',
    this.pricePerPiece = 0.0,
    this.totalPrice = 0.0,
    this.totalPriceDisplay = '',
    required this.breakdownText,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'record_id': recordId,
      'date': date,
      'time': time,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'product_id': productId,
      'product_name': productName,
      'product_name_with_quantity': productNameWithQuantity,
      'input_mode': inputMode,
      'input_quantity': inputQuantity,
      'pieces': pieces,
      'crates': crates,
      'packing_needed': packingNeeded,
      'volume_litres': volumeLitres,
      'weight_kg': weightKg,
      'total_quantity_display': totalQuantityDisplay,
      'price_per_piece': pricePerPiece,
      'total_price': totalPrice,
      'total_price_display': totalPriceDisplay,
      'breakdown_text': breakdownText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ProductCalculationRecord.fromJson(Map<String, dynamic> json) {
    return ProductCalculationRecord(
      recordId: json['record_id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? 'Plant Employee',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      productNameWithQuantity: json['product_name_with_quantity']?.toString() ?? '',
      inputMode: json['input_mode']?.toString() ?? 'Pieces',
      inputQuantity: (json['input_quantity'] as num?)?.toDouble() ?? 0.0,
      pieces: (json['pieces'] as num?)?.toInt() ?? 0,
      crates: (json['crates'] as num?)?.toDouble() ?? 0.0,
      packingNeeded: json['packing_needed']?.toString() ?? '',
      volumeLitres: (json['volume_litres'] as num?)?.toDouble() ?? 0.0,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      totalQuantityDisplay: json['total_quantity_display']?.toString() ?? '',
      pricePerPiece: (json['price_per_piece'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      totalPriceDisplay: json['total_price_display']?.toString() ?? '',
      breakdownText: json['breakdown_text']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
