/// Model for Milk Stock log entries recorded from Lab or Silo reception.
class MilkStockEntry {
  final String id;
  final DateTime recordedAt;
  final double pmstStockLitres;
  final double rmstStockLitres;
  final String? notes;
  final String? recordedBy;

  const MilkStockEntry({
    required this.id,
    required this.recordedAt,
    required this.pmstStockLitres,
    required this.rmstStockLitres,
    this.notes,
    this.recordedBy,
  });

  double get totalStockLitres => pmstStockLitres + rmstStockLitres;

  Map<String, dynamic> toJson() => {
        'id': id,
        'recorded_at': recordedAt.toIso8601String(),
        'pmst_stock_litres': pmstStockLitres,
        'rmst_stock_litres': rmstStockLitres,
        'notes': notes,
        'recorded_by': recordedBy,
      };

  factory MilkStockEntry.fromJson(Map<String, dynamic> json) => MilkStockEntry(
        id: json['id']?.toString() ?? '',
        recordedAt: DateTime.tryParse(json['recorded_at']?.toString() ?? '') ??
            DateTime.now(),
        pmstStockLitres: (json['pmst_stock_litres'] as num?)?.toDouble() ?? 0.0,
        rmstStockLitres: (json['rmst_stock_litres'] as num?)?.toDouble() ?? 0.0,
        notes: json['notes']?.toString(),
        recordedBy: json['recorded_by']?.toString(),
      );

  MilkStockEntry copyWith({
    String? id,
    DateTime? recordedAt,
    double? pmstStockLitres,
    double? rmstStockLitres,
    String? notes,
    String? recordedBy,
  }) =>
      MilkStockEntry(
        id: id ?? this.id,
        recordedAt: recordedAt ?? this.recordedAt,
        pmstStockLitres: pmstStockLitres ?? this.pmstStockLitres,
        rmstStockLitres: rmstStockLitres ?? this.rmstStockLitres,
        notes: notes ?? this.notes,
        recordedBy: recordedBy ?? this.recordedBy,
      );
}
