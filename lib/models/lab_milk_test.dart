class LabMilkTest {
  final String id;
  final String testDate; // YYYY-MM-DD
  final String testTime; // e.g. 08:35 AM
  final String siloId; // RMST, PMST, SILO_1, SILO_2
  final String siloName;
  final double fatPercentage;
  final double snfPercentage;
  final String labUserId;
  final String labUserName;
  final String remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LabMilkTest({
    required this.id,
    required this.testDate,
    required this.testTime,
    required this.siloId,
    required this.siloName,
    required this.fatPercentage,
    required this.snfPercentage,
    required this.labUserId,
    required this.labUserName,
    this.remarks = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'test_date': testDate,
      'test_time': testTime,
      'silo_id': siloId,
      'silo_name': siloName,
      'fat_percentage': fatPercentage,
      'snf_percentage': snfPercentage,
      'lab_user_id': labUserId,
      'lab_user_name': labUserName,
      'remarks': remarks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory LabMilkTest.fromJson(Map<String, dynamic> json) {
    return LabMilkTest(
      id: json['id']?.toString() ?? '',
      testDate: json['test_date']?.toString() ?? '',
      testTime: json['test_time']?.toString() ?? '',
      siloId: json['silo_id']?.toString() ?? 'PMST',
      siloName: json['silo_name']?.toString() ?? 'PMST',
      fatPercentage: (json['fat_percentage'] as num?)?.toDouble() ?? 0.0,
      snfPercentage: (json['snf_percentage'] as num?)?.toDouble() ?? 0.0,
      labUserId: json['lab_user_id']?.toString() ?? '',
      labUserName: json['lab_user_name']?.toString() ?? 'Lab Analyst',
      remarks: json['remarks']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  LabMilkTest copyWith({
    String? id,
    String? testDate,
    String? testTime,
    String? siloId,
    String? siloName,
    double? fatPercentage,
    double? snfPercentage,
    String? labUserId,
    String? labUserName,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LabMilkTest(
      id: id ?? this.id,
      testDate: testDate ?? this.testDate,
      testTime: testTime ?? this.testTime,
      siloId: siloId ?? this.siloId,
      siloName: siloName ?? this.siloName,
      fatPercentage: fatPercentage ?? this.fatPercentage,
      snfPercentage: snfPercentage ?? this.snfPercentage,
      labUserId: labUserId ?? this.labUserId,
      labUserName: labUserName ?? this.labUserName,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isFatValid => fatPercentage > 0;
  bool get isSnfValid => snfPercentage > 0;
  bool get isValid => isFatValid && isSnfValid && siloId.isNotEmpty && testDate.isNotEmpty;

  /// Flags unusually high or low Fat outside typical dairy plant range (2.0% - 10.0%)
  bool get isFatUnusual => fatPercentage < 2.0 || fatPercentage > 10.0;

  /// Flags unusually high or low SNF outside typical dairy plant range (7.0% - 11.0%)
  bool get isSnfUnusual => snfPercentage < 7.0 || snfPercentage > 11.0;
}
