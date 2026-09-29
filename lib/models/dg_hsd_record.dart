class DgHsdRecord {
  final String recordId;
  final String date; // YYYY-MM-DD
  final String time; // HH:mm AM/PM
  final String shift;
  final String employeeId;
  final String employeeName;
  final double fuelAdded; // Litres of HSD added
  final double startPercentage; // Tank start % (0-100)
  final double endPercentage; // Tank end % (0-100)
  final double percentageDrop; // start % - end %
  final double fuelConsumption; // Manual user input: Litres
  final double kwh; // Manual user input: kWh units generated
  final double runningHours; // Manual user input: DG running hours
  final double consumptionPerHour; // L/hr (fuelConsumption / runningHours)
  final double unitsPerLitre; // kWh/L (kwh / fuelConsumption)
  final String remarks; // Note
  final DateTime createdAt;
  final DateTime updatedAt;

  const DgHsdRecord({
    required this.recordId,
    required this.date,
    required this.time,
    required this.shift,
    required this.employeeId,
    required this.employeeName,
    required this.fuelAdded,
    required this.startPercentage,
    required this.endPercentage,
    required this.percentageDrop,
    required this.fuelConsumption,
    required this.kwh,
    required this.runningHours,
    required this.consumptionPerHour,
    required this.unitsPerLitre,
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
      'fuel_added': fuelAdded,
      'start_percentage': startPercentage,
      'end_percentage': endPercentage,
      'percentage_drop': percentageDrop,
      'fuel_consumption': fuelConsumption,
      'kwh': kwh,
      'running_hours': runningHours,
      'consumption_per_hour': consumptionPerHour,
      'units_per_litre': unitsPerLitre,
      'remarks': remarks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DgHsdRecord.fromJson(Map<String, dynamic> json) {
    return DgHsdRecord(
      recordId: json['record_id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      shift: json['shift']?.toString() ?? 'Shift A (06:00 - 14:00)',
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? 'Operator',
      fuelAdded: (json['fuel_added'] as num?)?.toDouble() ?? 0.0,
      startPercentage: (json['start_percentage'] as num?)?.toDouble() ?? 0.0,
      endPercentage: (json['end_percentage'] as num?)?.toDouble() ?? 0.0,
      percentageDrop: (json['percentage_drop'] as num?)?.toDouble() ?? 0.0,
      fuelConsumption: (json['fuel_consumption'] as num?)?.toDouble() ?? 0.0,
      kwh: (json['kwh'] as num?)?.toDouble() ?? 0.0,
      runningHours: (json['running_hours'] as num?)?.toDouble() ?? 0.0,
      consumptionPerHour: (json['consumption_per_hour'] as num?)?.toDouble() ?? 0.0,
      unitsPerLitre: (json['units_per_litre'] as num?)?.toDouble() ?? 0.0,
      remarks: json['remarks']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  DgHsdRecord copyWith({
    String? recordId,
    String? date,
    String? time,
    String? shift,
    String? employeeId,
    String? employeeName,
    double? fuelAdded,
    double? startPercentage,
    double? endPercentage,
    double? percentageDrop,
    double? fuelConsumption,
    double? kwh,
    double? runningHours,
    double? consumptionPerHour,
    double? unitsPerLitre,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DgHsdRecord(
      recordId: recordId ?? this.recordId,
      date: date ?? this.date,
      time: time ?? this.time,
      shift: shift ?? this.shift,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      fuelAdded: fuelAdded ?? this.fuelAdded,
      startPercentage: startPercentage ?? this.startPercentage,
      endPercentage: endPercentage ?? this.endPercentage,
      percentageDrop: percentageDrop ?? this.percentageDrop,
      fuelConsumption: fuelConsumption ?? this.fuelConsumption,
      kwh: kwh ?? this.kwh,
      runningHours: runningHours ?? this.runningHours,
      consumptionPerHour: consumptionPerHour ?? this.consumptionPerHour,
      unitsPerLitre: unitsPerLitre ?? this.unitsPerLitre,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
