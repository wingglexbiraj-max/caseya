import '../core/constants/app_constants.dart';

class ProductionRecord {
  final String recordId;
  final String date;
  final String time;
  final String shift;
  final String employeeId;
  final String employeeName;
  final String productId;
  final String productName;
  final String batchNo;
  final double quantityProduced;
  final String unit;
  final double cratesProduced;
  final int piecesProduced;
  final String? standardizationRecordId;
  final double? fatPercent;
  final double? snfPercent;
  final String remarks;

  const ProductionRecord({
    required this.recordId,
    required this.date,
    required this.time,
    required this.shift,
    required this.employeeId,
    required this.employeeName,
    required this.productId,
    required this.productName,
    required this.batchNo,
    required this.quantityProduced,
    required this.unit,
    required this.cratesProduced,
    this.piecesProduced = 0,
    this.standardizationRecordId,
    this.fatPercent,
    this.snfPercent,
    this.remarks = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'record_id': recordId,
      'date': date,
      'time': time,
      'shift': shift,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'product_id': productId,
      'product_name': productName,
      'batch_no': batchNo,
      'quantity_produced': quantityProduced,
      'unit': unit,
      'crates_produced': cratesProduced,
      'pieces_produced': piecesProduced,
      'standardization_record_id': standardizationRecordId,
      'fat_percent': fatPercent,
      'snf_percent': snfPercent,
      'remarks': remarks,
    };
  }

  factory ProductionRecord.fromJson(Map<String, dynamic> json) {
    final rawShift = json['shift']?.toString() ?? 'Shift A';
    final rawTime = json['time']?.toString() ?? '';
    final shift = AppConstants.sanitizeShiftForTime(rawShift, rawTime);

    return ProductionRecord(
      recordId: json['record_id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: rawTime,
      shift: shift,
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? 'Operator',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      batchNo: json['batch_no']?.toString() ?? '',
      quantityProduced: (json['quantity_produced'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit']?.toString() ?? 'Litres',
      cratesProduced: (json['crates_produced'] as num?)?.toDouble() ?? 0.0,
      piecesProduced: (json['pieces_produced'] as num?)?.toInt() ?? 0,
      standardizationRecordId: json['standardization_record_id']?.toString(),
      fatPercent: (json['fat_percent'] as num?)?.toDouble(),
      snfPercent: (json['snf_percent'] as num?)?.toDouble(),
      remarks: json['remarks']?.toString() ?? '',
    );
  }
}

class DispatchItem {
  final String productId;
  final String productName;
  final double quantity;
  final double crates;
  final String unit;

  const DispatchItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.crates,
    required this.unit,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'crates': crates,
        'unit': unit,
      };

  factory DispatchItem.fromJson(Map<String, dynamic> json) => DispatchItem(
        productId: json['product_id']?.toString() ?? '',
        productName: json['product_name']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
        crates: (json['crates'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit']?.toString() ?? 'Litres',
      );
}

class DispatchRecord {
  final String recordId;
  final String date;
  final String time;
  final String vehicleNo;
  final String route;
  final String driverName;
  final String employeeId;
  final String employeeName;
  final List<DispatchItem> items;
  final double totalCrates;
  final double totalVolume;
  final String remarks;

  const DispatchRecord({
    required this.recordId,
    required this.date,
    required this.time,
    required this.vehicleNo,
    required this.route,
    required this.driverName,
    required this.employeeId,
    required this.employeeName,
    required this.items,
    required this.totalCrates,
    required this.totalVolume,
    this.remarks = '',
  });

  Map<String, dynamic> toJson() => {
        'record_id': recordId,
        'date': date,
        'time': time,
        'vehicle_no': vehicleNo,
        'route': route,
        'driver_name': driverName,
        'employee_id': employeeId,
        'employee_name': employeeName,
        'items': items.map((i) => i.toJson()).toList(),
        'total_crates': totalCrates,
        'total_volume': totalVolume,
        'remarks': remarks,
      };

  factory DispatchRecord.fromJson(Map<String, dynamic> json) => DispatchRecord(
        recordId: json['record_id']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
        vehicleNo: json['vehicle_no']?.toString() ?? '',
        route: json['route']?.toString() ?? '',
        driverName: json['driver_name']?.toString() ?? '',
        employeeId: json['employee_id']?.toString() ?? '',
        employeeName: json['employee_name']?.toString() ?? 'Dispatch Officer',
        items: (json['items'] as List<dynamic>?)
                ?.map((i) => DispatchItem.fromJson(i as Map<String, dynamic>))
                .toList() ??
            [],
        totalCrates: (json['total_crates'] as num?)?.toDouble() ?? 0.0,
        totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0.0,
        remarks: json['remarks']?.toString() ?? '',
      );
}

class PackagingRecord {
  final String recordId;
  final String date;
  final String shift;
  final String machineNo;
  final String filmRollNo;
  final String productName;
  final double filmConsumedKg;
  final double filmWastageKg;
  final int pouchesPacked;
  final double wastagePercent;

  const PackagingRecord({
    required this.recordId,
    required this.date,
    required this.shift,
    required this.machineNo,
    required this.filmRollNo,
    required this.productName,
    required this.filmConsumedKg,
    required this.filmWastageKg,
    required this.pouchesPacked,
    required this.wastagePercent,
  });

  Map<String, dynamic> toJson() => {
        'record_id': recordId,
        'date': date,
        'shift': shift,
        'machine_no': machineNo,
        'film_roll_no': filmRollNo,
        'product_name': productName,
        'film_consumed_kg': filmConsumedKg,
        'film_wastage_kg': filmWastageKg,
        'pouches_packed': pouchesPacked,
        'wastage_percent': wastagePercent,
      };

  factory PackagingRecord.fromJson(Map<String, dynamic> json) => PackagingRecord(
        recordId: json['record_id']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        shift: json['shift']?.toString() ?? 'Shift A',
        machineNo: json['machine_no']?.toString() ?? 'FPM-01',
        filmRollNo: json['film_roll_no']?.toString() ?? '',
        productName: json['product_name']?.toString() ?? '',
        filmConsumedKg: (json['film_consumed_kg'] as num?)?.toDouble() ?? 0.0,
        filmWastageKg: (json['film_wastage_kg'] as num?)?.toDouble() ?? 0.0,
        pouchesPacked: (json['pouches_packed'] as num?)?.toInt() ?? 0,
        wastagePercent: (json['wastage_percent'] as num?)?.toDouble() ?? 0.0,
      );
}

class StockRecord {
  final String productId;
  final String productName;
  final String category;
  final int pieces;
  final double crates;
  final double volumeLitres;
  final String unit;
  final double minThresholdLitres;
  final DateTime lastUpdated;

  const StockRecord({
    required this.productId,
    required this.productName,
    required this.category,
    required this.pieces,
    required this.crates,
    required this.volumeLitres,
    required this.unit,
    required this.minThresholdLitres,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'category': category,
        'pieces': pieces,
        'crates': crates,
        'volume_litres': volumeLitres,
        'unit': unit,
        'min_threshold_litres': minThresholdLitres,
        'last_updated': lastUpdated.toIso8601String(),
      };

  factory StockRecord.fromJson(Map<String, dynamic> json) => StockRecord(
        productId: json['product_id']?.toString() ?? '',
        productName: json['product_name']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        pieces: (json['pieces'] as num?)?.toInt() ?? 0,
        crates: (json['crates'] as num?)?.toDouble() ?? 0.0,
        volumeLitres: (json['volume_litres'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit']?.toString() ?? 'Litres',
        minThresholdLitres: (json['min_threshold_litres'] as num?)?.toDouble() ?? 100.0,
        lastUpdated: json['last_updated'] != null
            ? DateTime.tryParse(json['last_updated'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class AuditLog {
  final String logId;
  final DateTime timestamp;
  final String employeeId;
  final String employeeName;
  final String action; // e.g. "RECORD_CREATED", "CALCULATION_PERFORMED", "RECORD_DELETED"
  final String module; // "Boiler", "Standardization", "ProductCalculator", etc.
  final String details;

  const AuditLog({
    required this.logId,
    required this.timestamp,
    required this.employeeId,
    required this.employeeName,
    required this.action,
    required this.module,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'log_id': logId,
        'timestamp': timestamp.toIso8601String(),
        'employee_id': employeeId,
        'employee_name': employeeName,
        'action': action,
        'module': module,
        'details': details,
      };

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        logId: json['log_id']?.toString() ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
        employeeId: json['employee_id']?.toString() ?? '',
        employeeName: json['employee_name']?.toString() ?? '',
        action: json['action']?.toString() ?? '',
        module: json['module']?.toString() ?? '',
        details: json['details']?.toString() ?? '',
      );
}
