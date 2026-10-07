import '../core/constants/app_constants.dart';

/// Models for Daily Batch Making Records & Dynamic Ingredient Formulations
///
/// Complies with relational database structure:
/// - `batch_records` table
/// - `batch_ingredients` table
class BatchIngredientModel {
  final String id;
  final String batchId;
  final String ingredientName;
  final double quantity;
  final String unit; // 'L', 'kg', 'g', 'ml', 'bags'

  const BatchIngredientModel({
    required this.id,
    required this.batchId,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'batch_id': batchId,
        'ingredient_name': ingredientName,
        'quantity': quantity,
        'unit': unit,
      };

  factory BatchIngredientModel.fromJson(Map<String, dynamic> json) =>
      BatchIngredientModel(
        id: json['id']?.toString() ?? '',
        batchId: json['batch_id']?.toString() ?? '',
        ingredientName: json['ingredient_name']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit']?.toString() ?? 'L',
      );

  BatchIngredientModel copyWith({
    String? id,
    String? batchId,
    String? ingredientName,
    double? quantity,
    String? unit,
  }) =>
      BatchIngredientModel(
        id: id ?? this.id,
        batchId: batchId ?? this.batchId,
        ingredientName: ingredientName ?? this.ingredientName,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
      );
}

class BatchRecordModel {
  final String id;
  final String productionDate; // 'YYYY-MM-DD'
  final String productId;
  final String productName;
  final String batchNumber;
  final double batchQuantity;
  final String batchUnit; // 'L', 'kg', 'pieces', 'crates'
  final String? shift;
  final String? operatorName;
  final String? notes;
  final String? siloId; // 'RMST' | 'PMST' | ...
  final double? fatPercent; // Fat % input from Daily Batch Making
  final List<BatchIngredientModel> ingredients;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BatchRecordModel({
    required this.id,
    required this.productionDate,
    required this.productId,
    required this.productName,
    required this.batchNumber,
    required this.batchQuantity,
    required this.batchUnit,
    this.shift,
    this.operatorName,
    this.notes,
    this.siloId,
    this.fatPercent,
    required this.ingredients,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'production_date': productionDate,
        'product_id': productId,
        'product_name': productName,
        'batch_number': batchNumber,
        'batch_quantity': batchQuantity,
        'batch_unit': batchUnit,
        'shift': shift,
        'operator_name': operatorName,
        'notes': notes,
        'silo_id': siloId,
        'fat_percent': fatPercent,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory BatchRecordModel.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now();
    final rawShift = json['shift']?.toString();
    final shift = (rawShift != null && AppConstants.isDateTimeValidForShift(createdAt, rawShift))
        ? rawShift
        : AppConstants.determineShift(createdAt);

    return BatchRecordModel(
      id: json['id']?.toString() ?? '',
      productionDate: json['production_date']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      batchNumber: json['batch_number']?.toString() ?? '',
      batchQuantity: (json['batch_quantity'] as num?)?.toDouble() ?? 0.0,
      batchUnit: json['batch_unit']?.toString() ?? 'L',
      shift: shift,
      operatorName: json['operator_name']?.toString(),
      notes: json['notes']?.toString(),
      siloId: json['silo_id']?.toString(),
      fatPercent: (json['fat_percent'] as num?)?.toDouble(),
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) =>
                  BatchIngredientModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: createdAt,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  BatchRecordModel copyWith({
    String? id,
    String? productionDate,
    String? productId,
    String? productName,
    String? batchNumber,
    double? batchQuantity,
    String? batchUnit,
    String? shift,
    String? operatorName,
    String? notes,
    String? siloId,
    double? fatPercent,
    List<BatchIngredientModel>? ingredients,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      BatchRecordModel(
        id: id ?? this.id,
        productionDate: productionDate ?? this.productionDate,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        batchNumber: batchNumber ?? this.batchNumber,
        batchQuantity: batchQuantity ?? this.batchQuantity,
        batchUnit: batchUnit ?? this.batchUnit,
        shift: shift ?? this.shift,
        operatorName: operatorName ?? this.operatorName,
        notes: notes ?? this.notes,
        siloId: siloId ?? this.siloId,
        fatPercent: fatPercent ?? this.fatPercent,
        ingredients: ingredients ?? this.ingredients,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Aggregated Daily Summary of all batches on a specific date
class DailyBatchSummary {
  final String date;
  final int totalBatches;
  final double totalQuantity;
  final List<String> productsProduced;
  final List<BatchRecordModel> batches;
  final Map<String, Map<String, double>> ingredientTotals; // Ingredient -> {Unit: Qty}

  const DailyBatchSummary({
    required this.date,
    required this.totalBatches,
    required this.totalQuantity,
    required this.productsProduced,
    required this.batches,
    required this.ingredientTotals,
  });

  factory DailyBatchSummary.fromBatches(
      String date, List<BatchRecordModel> batches) {
    double totalQty = 0;
    final products = <String>{};
    final Map<String, Map<String, double>> ingTotals = {};

    for (final b in batches) {
      totalQty += b.batchQuantity;
      products.add(b.productName);

      for (final ing in b.ingredients) {
        final name = ing.ingredientName.trim();
        final unit = ing.unit.trim();
        if (name.isEmpty) continue;

        ingTotals.putIfAbsent(name, () => {});
        final current = ingTotals[name]![unit] ?? 0.0;
        ingTotals[name]![unit] = current + ing.quantity;
      }
    }

    return DailyBatchSummary(
      date: date,
      totalBatches: batches.length,
      totalQuantity: totalQty,
      productsProduced: products.toList(),
      batches: batches,
      ingredientTotals: ingTotals,
    );
  }
}
