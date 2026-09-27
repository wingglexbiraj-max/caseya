class BoilerRecord {
  final String recordId;
  final String date; // YYYY-MM-DD
  final String time; // HH:mm AM/PM
  final String shift;
  final String employeeId;
  final String employeeName;
  final double openingCm;
  final double closingCm;
  final double levelDifferenceCm;
  final double calculatedLevelConsumption;
  final double fuelTopUp;
  final double netReportedConsumption;
  final double runningHours;
  final double consumptionPerHour;
  final String remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BoilerRecord({
    required this.recordId,
    required this.date,
    required this.time,
    required this.shift,
    required this.employeeId,
    required this.employeeName,
    required this.openingCm,
    required this.closingCm,
    required this.levelDifferenceCm,
    required this.calculatedLevelConsumption,
    required this.fuelTopUp,
    required this.netReportedConsumption,
    required this.runningHours,
    required this.consumptionPerHour,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'record_id': recordId,
      'date': date,
      'time': time,
      'shift': shift,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'opening_cm': openingCm,
      'closing_cm': closingCm,
      'level_difference_cm': levelDifferenceCm,
      'calculated_level_consumption': calculatedLevelConsumption,
      'fuel_top_up': fuelTopUp,
      'net_reported_consumption': netReportedConsumption,
      'running_hours': runningHours,
      'consumption_per_hour': consumptionPerHour,
      'remarks': remarks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BoilerRecord.fromJson(Map<String, dynamic> json) {
    return BoilerRecord(
      recordId: json['record_id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      shift: json['shift']?.toString() ?? 'Shift A',
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? 'Operator',
      openingCm: (json['opening_cm'] as num?)?.toDouble() ?? 0.0,
      closingCm: (json['closing_cm'] as num?)?.toDouble() ?? 0.0,
      levelDifferenceCm: (json['level_difference_cm'] as num?)?.toDouble() ?? 0.0,
      calculatedLevelConsumption:
          (json['calculated_level_consumption'] as num?)?.toDouble() ?? 0.0,
      fuelTopUp: (json['fuel_top_up'] as num?)?.toDouble() ?? 0.0,
      netReportedConsumption:
          (json['net_reported_consumption'] as num?)?.toDouble() ?? 0.0,
      runningHours: (json['running_hours'] as num?)?.toDouble() ?? 0.0,
      consumptionPerHour: (json['consumption_per_hour'] as num?)?.toDouble() ?? 0.0,
      remarks: json['remarks']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  BoilerRecord copyWith({
    String? recordId,
    String? date,
    String? time,
    String? shift,
    String? employeeId,
    String? employeeName,
    double? openingCm,
    double? closingCm,
    double? levelDifferenceCm,
    double? calculatedLevelConsumption,
    double? fuelTopUp,
    double? netReportedConsumption,
    double? runningHours,
    double? consumptionPerHour,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BoilerRecord(
      recordId: recordId ?? this.recordId,
      date: date ?? this.date,
      time: time ?? this.time,
      shift: shift ?? this.shift,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      openingCm: openingCm ?? this.openingCm,
      closingCm: closingCm ?? this.closingCm,
      levelDifferenceCm: levelDifferenceCm ?? this.levelDifferenceCm,
      calculatedLevelConsumption:
          calculatedLevelConsumption ?? this.calculatedLevelConsumption,
      fuelTopUp: fuelTopUp ?? this.fuelTopUp,
      netReportedConsumption:
          netReportedConsumption ?? this.netReportedConsumption,
      runningHours: runningHours ?? this.runningHours,
      consumptionPerHour: consumptionPerHour ?? this.consumptionPerHour,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
