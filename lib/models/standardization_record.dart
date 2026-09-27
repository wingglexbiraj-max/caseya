class StandardizationRecord {
  final String recordId;
  final String date; // YYYY-MM-DD
  final String time; // HH:mm AM/PM
  final String employeeId;
  final String employeeName;
  final double inputMilkQuantity;
  final String inputUnit; // Litres
  final double inputFat;
  final double inputSnf;
  final String targetProductId;
  final String targetProductName;
  final double targetFat;
  final double targetSnf;
  final double waterRequired;
  final double smpRequired;
  final double sugarRequired;
  final double finalQuantity;
  final double finalFat;
  final double finalSnf;
  final String calculationFormulaVersion;
  final String notes;
  final DateTime createdAt;

  const StandardizationRecord({
    required this.recordId,
    required this.date,
    required this.time,
    required this.employeeId,
    required this.employeeName,
    required this.inputMilkQuantity,
    this.inputUnit = 'Litres',
    required this.inputFat,
    required this.inputSnf,
    required this.targetProductId,
    required this.targetProductName,
    required this.targetFat,
    required this.targetSnf,
    required this.waterRequired,
    required this.smpRequired,
    required this.sugarRequired,
    required this.finalQuantity,
    required this.finalFat,
    required this.finalSnf,
    required this.calculationFormulaVersion,
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'record_id': recordId,
      'date': date,
      'time': time,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'input_milk_quantity': inputMilkQuantity,
      'input_unit': inputUnit,
      'input_fat': inputFat,
      'input_snf': inputSnf,
      'target_product_id': targetProductId,
      'target_product_name': targetProductName,
      'target_fat': targetFat,
      'target_snf': targetSnf,
      'water_required': waterRequired,
      'smp_required': smpRequired,
      'sugar_required': sugarRequired,
      'final_quantity': finalQuantity,
      'final_fat': finalFat,
      'final_snf': finalSnf,
      'calculation_formula_version': calculationFormulaVersion,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StandardizationRecord.fromJson(Map<String, dynamic> json) {
    return StandardizationRecord(
      recordId: json['record_id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? 'Dairy Technologist',
      inputMilkQuantity: (json['input_milk_quantity'] as num?)?.toDouble() ?? 0.0,
      inputUnit: json['input_unit']?.toString() ?? 'Litres',
      inputFat: (json['input_fat'] as num?)?.toDouble() ?? 0.0,
      inputSnf: (json['input_snf'] as num?)?.toDouble() ?? 0.0,
      targetProductId: json['target_product_id']?.toString() ?? '',
      targetProductName: json['target_product_name']?.toString() ?? '',
      targetFat: (json['target_fat'] as num?)?.toDouble() ?? 0.0,
      targetSnf: (json['target_snf'] as num?)?.toDouble() ?? 0.0,
      waterRequired: (json['water_required'] as num?)?.toDouble() ?? 0.0,
      smpRequired: (json['smp_required'] as num?)?.toDouble() ?? 0.0,
      sugarRequired: (json['sugar_required'] as num?)?.toDouble() ?? 0.0,
      finalQuantity: (json['final_quantity'] as num?)?.toDouble() ?? 0.0,
      finalFat: (json['final_fat'] as num?)?.toDouble() ?? 0.0,
      finalSnf: (json['final_snf'] as num?)?.toDouble() ?? 0.0,
      calculationFormulaVersion:
          json['calculation_formula_version']?.toString() ?? 'v1.2-Standard-2026',
      notes: json['notes']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
