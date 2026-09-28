class StandardizationRecord {
  final String recordId;
  final String date; // YYYY-MM-DD
  final String time; // HH:mm AM/PM
  final String employeeId;
  final String employeeName;
  final double totalBatchRequired; // Total batch size in Litres
  final double inputMilkQuantity; // Milk Taken in Litres
  final String inputUnit; // Litres
  final double inputFat;
  final double inputSnf;
  final String targetProductId;
  final String targetProductName;
  final double targetFat;
  final double targetSnf;
  final double availableFatKg;
  final double availableSnfKg;
  final double requiredSnfKg;
  final double snfDeficitKg;
  final double waterRequired;
  final double smpRequired;
  final double sugarRequired;
  final double finalQuantity;
  final double finalFat;
  final double finalSnf;
  final double smpFactor;
  final String calculationFormulaVersion;
  final String notes;
  final DateTime createdAt;

  const StandardizationRecord({
    required this.recordId,
    required this.date,
    required this.time,
    required this.employeeId,
    required this.employeeName,
    this.totalBatchRequired = 0.0,
    required this.inputMilkQuantity,
    this.inputUnit = 'Litres',
    required this.inputFat,
    required this.inputSnf,
    required this.targetProductId,
    required this.targetProductName,
    required this.targetFat,
    required this.targetSnf,
    this.availableFatKg = 0.0,
    this.availableSnfKg = 0.0,
    this.requiredSnfKg = 0.0,
    this.snfDeficitKg = 0.0,
    required this.waterRequired,
    required this.smpRequired,
    required this.sugarRequired,
    required this.finalQuantity,
    required this.finalFat,
    required this.finalSnf,
    this.smpFactor = 95.0,
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
      'total_batch_required': totalBatchRequired,
      'input_milk_quantity': inputMilkQuantity,
      'input_unit': inputUnit,
      'input_fat': inputFat,
      'input_snf': inputSnf,
      'target_product_id': targetProductId,
      'target_product_name': targetProductName,
      'target_fat': targetFat,
      'target_snf': targetSnf,
      'available_fat_kg': availableFatKg,
      'available_snf_kg': availableSnfKg,
      'required_snf_kg': requiredSnfKg,
      'snf_deficit_kg': snfDeficitKg,
      'water_required': waterRequired,
      'smp_required': smpRequired,
      'sugar_required': sugarRequired,
      'final_quantity': finalQuantity,
      'final_fat': finalFat,
      'final_snf': finalSnf,
      'smp_factor': smpFactor,
      'calculation_formula_version': calculationFormulaVersion,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StandardizationRecord.fromJson(Map<String, dynamic> json) {
    final inputMilk = (json['input_milk_quantity'] as num?)?.toDouble() ?? 0.0;
    final finalQty = (json['final_quantity'] as num?)?.toDouble() ?? inputMilk;
    final totalBatch = (json['total_batch_required'] as num?)?.toDouble() ?? finalQty;

    return StandardizationRecord(
      recordId: json['record_id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? 'Dairy Technologist',
      totalBatchRequired: totalBatch,
      inputMilkQuantity: inputMilk,
      inputUnit: json['input_unit']?.toString() ?? 'Litres',
      inputFat: (json['input_fat'] as num?)?.toDouble() ?? 0.0,
      inputSnf: (json['input_snf'] as num?)?.toDouble() ?? 0.0,
      targetProductId: json['target_product_id']?.toString() ?? '',
      targetProductName: json['target_product_name']?.toString() ?? '',
      targetFat: (json['target_fat'] as num?)?.toDouble() ?? 0.0,
      targetSnf: (json['target_snf'] as num?)?.toDouble() ?? 0.0,
      availableFatKg: (json['available_fat_kg'] as num?)?.toDouble() ?? 0.0,
      availableSnfKg: (json['available_snf_kg'] as num?)?.toDouble() ?? 0.0,
      requiredSnfKg: (json['required_snf_kg'] as num?)?.toDouble() ?? 0.0,
      snfDeficitKg: (json['snf_deficit_kg'] as num?)?.toDouble() ?? 0.0,
      waterRequired: (json['water_required'] as num?)?.toDouble() ?? 0.0,
      smpRequired: (json['smp_required'] as num?)?.toDouble() ?? 0.0,
      sugarRequired: (json['sugar_required'] as num?)?.toDouble() ?? 0.0,
      finalQuantity: finalQty,
      finalFat: (json['final_fat'] as num?)?.toDouble() ?? 0.0,
      finalSnf: (json['final_snf'] as num?)?.toDouble() ?? 0.0,
      smpFactor: (json['smp_factor'] as num?)?.toDouble() ?? 95.0,
      calculationFormulaVersion:
          json['calculation_formula_version']?.toString() ?? 'v1.2-Standard-2026',
      notes: json['notes']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
