class LabRecord {
  final String recordId;
  final String date; // YYYY-MM-DD
  final String sampleTime; // HH:mm AM/PM
  final String batchOrSiloNo; // e.g. Silo 02, Tanker TK-14
  final double milkQuantity; // Litres available in silo
  final double fatPercent;
  final double snfPercent;
  final double clr; // Corrected Lactometer Reading
  final double acidity; // % lactic acid
  final double temperature; // °C
  final String analystName;
  final String remarks;

  const LabRecord({
    required this.recordId,
    required this.date,
    required this.sampleTime,
    required this.batchOrSiloNo,
    required this.milkQuantity,
    required this.fatPercent,
    required this.snfPercent,
    required this.clr,
    required this.acidity,
    required this.temperature,
    required this.analystName,
    this.remarks = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'record_id': recordId,
      'date': date,
      'sample_time': sampleTime,
      'batch_or_silo_no': batchOrSiloNo,
      'milk_quantity': milkQuantity,
      'fat_percent': fatPercent,
      'snf_percent': snfPercent,
      'clr': clr,
      'acidity': acidity,
      'temperature': temperature,
      'analyst_name': analystName,
      'remarks': remarks,
    };
  }

  factory LabRecord.fromJson(Map<String, dynamic> json) {
    return LabRecord(
      recordId: json['record_id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      sampleTime: json['sample_time']?.toString() ?? '',
      batchOrSiloNo: json['batch_or_silo_no']?.toString() ?? '',
      milkQuantity: (json['milk_quantity'] as num?)?.toDouble() ?? 0.0,
      fatPercent: (json['fat_percent'] as num?)?.toDouble() ?? 0.0,
      snfPercent: (json['snf_percent'] as num?)?.toDouble() ?? 0.0,
      clr: (json['clr'] as num?)?.toDouble() ?? 0.0,
      acidity: (json['acidity'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      analystName: json['analyst_name']?.toString() ?? 'QC Lab Analyst',
      remarks: json['remarks']?.toString() ?? '',
    );
  }
}
