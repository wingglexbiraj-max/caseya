import 'product_model.dart';
import '../services/calculation_service.dart';
import '../core/utils/formatters.dart';

/// Single product item inside a vehicle dispatch transaction
class DispatchItem {
  final String id;
  final String dispatchId;
  final String productId;
  final String productName;
  final String shortCode;
  final String itemCode;
  final String inputMode; // 'Crates', 'Pieces', 'Litres', 'Kg'
  final double inputQuantity;
  final double crates;
  final int pieces;
  final double normalizedQuantity; // Litres or Kg
  final String normalizedUnit; // 'Litres', 'Kg'
  final double packSize;
  final String packSizeDisplay;
  final int piecesPerCrate;
  final DateTime createdAt;

  const DispatchItem({
    required this.id,
    required this.dispatchId,
    required this.productId,
    required this.productName,
    required this.shortCode,
    required this.itemCode,
    required this.inputMode,
    required this.inputQuantity,
    required this.crates,
    required this.pieces,
    required this.normalizedQuantity,
    required this.normalizedUnit,
    required this.packSize,
    required this.packSizeDisplay,
    required this.piecesPerCrate,
    required this.createdAt,
  });

  /// Factory helper that converts an input using ProductModel metadata
  /// and snapshots the metadata so future Product Master updates never corrupt historical dispatches.
  factory DispatchItem.fromInput({
    required String id,
    required String dispatchId,
    required ProductModel product,
    required String inputMode,
    required double inputQuantity,
    DateTime? createdAt,
  }) {
    final calc = CalculationService.calculateProduct(
      product: product,
      inputMode: inputMode,
      inputQuantity: inputQuantity,
    );

    final normalizedUnit = product.baseUnitLabel; // 'Litres' or 'Kg'

    return DispatchItem(
      id: id,
      dispatchId: dispatchId,
      productId: product.productId,
      productName: product.productName,
      shortCode: product.shortCode,
      itemCode: product.itemCode,
      inputMode: inputMode,
      inputQuantity: inputQuantity,
      crates: calc.crates,
      pieces: calc.pieces,
      normalizedQuantity: calc.totalQuantity,
      normalizedUnit: normalizedUnit,
      packSize: product.packSize,
      packSizeDisplay: product.packSizeDisplay,
      piecesPerCrate: product.piecesPerCrate,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dispatch_id': dispatchId,
      'product_id': productId,
      'product_name': productName,
      'short_code': shortCode,
      'item_code': itemCode,
      'input_mode': inputMode,
      'input_quantity': inputQuantity,
      'crates': crates,
      'pieces': pieces,
      'normalized_quantity': normalizedQuantity,
      'normalized_unit': normalizedUnit,
      'pack_size': packSize,
      'pack_size_display': packSizeDisplay,
      'pieces_per_crate': piecesPerCrate,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DispatchItem.fromJson(Map<String, dynamic> json) {
    return DispatchItem(
      id: json['id']?.toString() ?? '',
      dispatchId: json['dispatch_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      shortCode: json['short_code']?.toString() ?? '',
      itemCode: json['item_code']?.toString() ?? '',
      inputMode: json['input_mode']?.toString() ?? 'Crates',
      inputQuantity: (json['input_quantity'] as num?)?.toDouble() ?? 0.0,
      crates: (json['crates'] as num?)?.toDouble() ?? 0.0,
      pieces: (json['pieces'] as num?)?.toInt() ?? 0,
      normalizedQuantity: (json['normalized_quantity'] as num?)?.toDouble() ?? 0.0,
      normalizedUnit: json['normalized_unit']?.toString() ?? 'Litres',
      packSize: (json['pack_size'] as num?)?.toDouble() ?? 0.0,
      packSizeDisplay: json['pack_size_display']?.toString() ?? '',
      piecesPerCrate: (json['pieces_per_crate'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  DispatchItem copyWith({
    String? id,
    String? dispatchId,
    String? productId,
    String? productName,
    String? shortCode,
    String? itemCode,
    String? inputMode,
    double? inputQuantity,
    double? crates,
    int? pieces,
    double? normalizedQuantity,
    String? normalizedUnit,
    double? packSize,
    String? packSizeDisplay,
    int? piecesPerCrate,
    DateTime? createdAt,
  }) {
    return DispatchItem(
      id: id ?? this.id,
      dispatchId: dispatchId ?? this.dispatchId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      shortCode: shortCode ?? this.shortCode,
      itemCode: itemCode ?? this.itemCode,
      inputMode: inputMode ?? this.inputMode,
      inputQuantity: inputQuantity ?? this.inputQuantity,
      crates: crates ?? this.crates,
      pieces: pieces ?? this.pieces,
      normalizedQuantity: normalizedQuantity ?? this.normalizedQuantity,
      normalizedUnit: normalizedUnit ?? this.normalizedUnit,
      packSize: packSize ?? this.packSize,
      packSizeDisplay: packSizeDisplay ?? this.packSizeDisplay,
      piecesPerCrate: piecesPerCrate ?? this.piecesPerCrate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get formattedQuantity =>
      inputMode == 'Pieces'
          ? formattedPieces
          : (inputMode == 'Crates' ? formattedCrates : formattedQuantityWithUnit);

  String get shortUnit => normalizedUnit == 'Litres' ? 'L' : 'kg';

  String get formattedQuantityWithUnit =>
      '${Formatters.formatSmart(normalizedQuantity)} $shortUnit';

  String get formattedCrates =>
      crates == crates.roundToDouble() ? '${crates.toInt()} crates' : '${Formatters.formatSmart(crates)} crates';

  String get formattedPieces => '$pieces pcs';
}

/// Parent record for a vehicle dispatch containing multiple product lines
class VehicleDispatch {
  final String id;
  final String dispatchDate; // YYYY-MM-DD
  final String distributorName;
  final String vehicleNumber;
  final String driverName;
  final String route;
  final String dispatchTime; // e.g. 08:35 AM
  final String remarks;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DispatchItem> items;
  final int productCrates;
  final int milkCrates;

  const VehicleDispatch({
    required this.id,
    required this.dispatchDate,
    required this.distributorName,
    required this.vehicleNumber,
    this.driverName = '',
    this.route = '',
    required this.dispatchTime,
    this.remarks = '',
    this.status = 'Dispatched',
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.productCrates = 0,
    this.milkCrates = 0,
  });

  String get recordedBy => createdBy;
  DateTime get dispatchedAt => createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dispatch_date': dispatchDate,
      'distributor_name': distributorName,
      'vehicle_number': vehicleNumber,
      'driver_name': driverName,
      'route': route,
      'dispatch_time': dispatchTime,
      'remarks': remarks,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'product_crates': productCrates,
      'milk_crates': milkCrates,
    };
  }

  factory VehicleDispatch.fromJson(Map<String, dynamic> json) {
    return VehicleDispatch(
      id: json['id']?.toString() ?? '',
      dispatchDate: json['dispatch_date']?.toString() ?? '',
      distributorName: json['distributor_name']?.toString() ?? '',
      vehicleNumber: json['vehicle_number']?.toString() ?? '',
      driverName: json['driver_name']?.toString() ?? '',
      route: json['route']?.toString() ?? '',
      dispatchTime: json['dispatch_time']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Dispatched',
      createdBy: json['created_by']?.toString() ?? 'Dispatch Officer',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => DispatchItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      productCrates: (json['product_crates'] as num?)?.toInt() ?? (json['productCrates'] as num?)?.toInt() ?? 0,
      milkCrates: (json['milk_crates'] as num?)?.toInt() ?? (json['milkCrates'] as num?)?.toInt() ?? 0,
    );
  }

  VehicleDispatch copyWith({
    String? id,
    String? dispatchDate,
    String? distributorName,
    String? vehicleNumber,
    String? driverName,
    String? route,
    String? dispatchTime,
    String? remarks,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<DispatchItem>? items,
    int? productCrates,
    int? milkCrates,
  }) {
    return VehicleDispatch(
      id: id ?? this.id,
      dispatchDate: dispatchDate ?? this.dispatchDate,
      distributorName: distributorName ?? this.distributorName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      driverName: driverName ?? this.driverName,
      route: route ?? this.route,
      dispatchTime: dispatchTime ?? this.dispatchTime,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      productCrates: productCrates ?? this.productCrates,
      milkCrates: milkCrates ?? this.milkCrates,
    );
  }

  /// Aggregated metrics for this vehicle
  double get totalCrates => (productCrates + milkCrates) > 0
      ? (productCrates + milkCrates).toDouble()
      : items.fold(0.0, (acc, item) => acc + item.crates);
  int get totalPieces => items.fold(0, (acc, item) => acc + item.pieces);

  /// Liquid total in Litres
  double get totalLitres => items
      .where((i) => i.normalizedUnit.toLowerCase().startsWith('l'))
      .fold(0.0, (acc, item) => acc + item.normalizedQuantity);

  /// Solid/Curd total in Kilograms
  double get totalKg => items
      .where((i) => i.normalizedUnit.toLowerCase().startsWith('k'))
      .fold(0.0, (acc, item) => acc + item.normalizedQuantity);

  int get productLineCount => items.length;

  String get summaryLabel {
    final crateStr = totalCrates == totalCrates.roundToDouble()
        ? '${totalCrates.toInt()}'
        : Formatters.formatSmart(totalCrates);
    return '$productLineCount ${productLineCount == 1 ? 'Product' : 'Products'} • $crateStr Crates';
  }
}

/// Consolidated daily summary per product
class DailyDispatchProductSummary {
  final String productId;
  final String productName;
  final String shortCode;
  final String itemCode;
  final String packSizeDisplay;
  final double totalCrates;
  final int totalPieces;
  final double totalQuantity;
  final String normalizedUnit;
  final int vehicleCount;
  final int distributorCount;
  final double revenue;

  const DailyDispatchProductSummary({
    required this.productId,
    required this.productName,
    required this.shortCode,
    required this.itemCode,
    required this.packSizeDisplay,
    required this.totalCrates,
    required this.totalPieces,
    required this.totalQuantity,
    required this.normalizedUnit,
    required this.vehicleCount,
    required this.distributorCount,
    this.revenue = 0.0,
  });

  String get shortUnit => normalizedUnit == 'Litres' ? 'L' : 'kg';

  String get formattedQuantity =>
      totalQuantity > 0 ? '${Formatters.formatSmart(totalQuantity)} $shortUnit' : '—';

  String get formattedCrates =>
      totalCrates > 0
          ? (totalCrates == totalCrates.roundToDouble()
              ? '${totalCrates.toInt()} crates'
              : '${Formatters.formatSmart(totalCrates)} crates')
          : '—';

  String get formattedPieces => totalPieces > 0 ? '$totalPieces pcs' : '—';

  /// Standard pieces per box according to packaging specifications:
  /// - P80 & S80: 24 pcs / box
  /// - P200 & S200: 12 pcs / box
  /// - P400 & S400: 6 pcs / box
  /// - Paneer: 20 pcs / box
  int? get piecesPerBox {
    final name = productName.trim().toLowerCase();
    final code = shortCode.trim().toLowerCase();

    if (code == 'p80' || code == 's80' || name == 'p80' || name == 's80' || name.startsWith('p80 ') || name.startsWith('s80 ') || name.contains('s80') || name.contains('p80')) {
      return 24;
    }
    if (code == 'p200' || code == 's200' || name == 'p200' || name == 's200' || name.startsWith('p200 ') || name.startsWith('s200 ') || name.contains('s200') || name.contains('p200')) {
      return 12;
    }
    if (code == 'p400' || code == 's400' || name == 'p400' || name == 's400' || name.startsWith('p400 ') || name.startsWith('s400 ') || name.contains('s400') || name.contains('p400')) {
      return 6;
    }
    if (code == 'paneer' || name == 'paneer' || name.contains('paneer')) {
      return 20;
    }
    return null;
  }

  /// Calculates total boxes based on total pieces and packaging standard
  double? get totalBoxes {
    final ppb = piecesPerBox;
    if (ppb == null || totalPieces <= 0) return null;
    return totalPieces / ppb;
  }

  /// Formatted box display string (e.g. "10 boxes" or "—")
  String get formattedBoxes {
    final ppb = piecesPerBox;
    if (ppb == null || totalPieces <= 0) return '—';
    final boxes = totalPieces / ppb;
    if (boxes <= 0) return '—';
    return boxes == boxes.roundToDouble()
        ? '${boxes.toInt()} boxes'
        : '${Formatters.formatSmart(boxes)} boxes';
  }

  String get formattedRevenue =>
      revenue > 0 ? '₹${Formatters.formatSmart(revenue)}' : '—';
}
