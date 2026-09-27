class ProductCalculationRecord {
  final String recordId;
  final String date; // YYYY-MM-DD
  final String time; // HH:mm AM/PM
  final String employeeId;
  final String employeeName;
  final String productId;
  final String productName;
  final String inputMode; // Pieces, Crates, Litres, Kg
  final double inputQuantity;
  final int pieces;
  final double crates;
  final double volumeLitres;
  final double weightKg;
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
    required this.inputMode,
    required this.inputQuantity,
    required this.pieces,
    required this.crates,
    required this.volumeLitres,
    required this.weightKg,
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
      'input_mode': inputMode,
      'input_quantity': inputQuantity,
      'pieces': pieces,
      'crates': crates,
      'volume_litres': volumeLitres,
      'weight_kg': weightKg,
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
      inputMode: json['input_mode']?.toString() ?? 'Pieces',
      inputQuantity: (json['input_quantity'] as num?)?.toDouble() ?? 0.0,
      pieces: (json['pieces'] as num?)?.toInt() ?? 0,
      crates: (json['crates'] as num?)?.toDouble() ?? 0.0,
      volumeLitres: (json['volume_litres'] as num?)?.toDouble() ?? 0.0,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      breakdownText: json['breakdown_text']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
