import 'package:flutter/material.dart';

/// Represents an item in the CASEYA Plant Inventory Stock.
class InventoryItemModel {
  final String id;
  final String name;
  final String category; // 'Cups', 'Aluminium Foil', 'Ingredients', 'Poly Roll', 'Serving Material'
  final String baseUnit; // 'pcs', 'lids', 'kg', 'Rolls'
  final String packagingUnit; // 'Boxes', 'Bags', 'Rolls'
  final double itemsPerPackage; // e.g. 2500 pcs/box, 50 kg/bag, 1 roll/roll
  final double initialPackages; // baseline package count
  final double initialTotalQty; // baseline total quantity
  final double consumedQty; // dynamically deducted from production & batch records
  final String details; // e.g. '2,500 pcs / box'
  final IconData icon;

  const InventoryItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.baseUnit,
    required this.packagingUnit,
    required this.itemsPerPackage,
    required this.initialPackages,
    required this.initialTotalQty,
    this.consumedQty = 0.0,
    required this.details,
    required this.icon,
  });

  /// Current available quantity after production and batch deductions
  double get remainingQty {
    final rem = initialTotalQty - consumedQty;
    return rem > 0 ? rem : 0.0;
  }

  /// Current packages remaining based on itemsPerPackage
  double get remainingPackages {
    if (itemsPerPackage <= 0) return 0.0;
    return remainingQty / itemsPerPackage;
  }

  /// Whether any quantity of this item has been deducted
  bool get hasConsumption => consumedQty > 0.0001;

  /// Dynamic status based on remaining stock level
  String get status {
    if (remainingQty <= 0) {
      return 'Out of Stock Alert';
    }
    // Low stock if less than 20% of initial baseline
    if (remainingQty < (initialTotalQty * 0.20)) {
      return 'Low Stock Alert';
    }
    return 'Adequate';
  }

  InventoryItemModel copyWith({
    String? id,
    String? name,
    String? category,
    String? baseUnit,
    String? packagingUnit,
    double? itemsPerPackage,
    double? initialPackages,
    double? initialTotalQty,
    double? consumedQty,
    String? details,
    IconData? icon,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      baseUnit: baseUnit ?? this.baseUnit,
      packagingUnit: packagingUnit ?? this.packagingUnit,
      itemsPerPackage: itemsPerPackage ?? this.itemsPerPackage,
      initialPackages: initialPackages ?? this.initialPackages,
      initialTotalQty: initialTotalQty ?? this.initialTotalQty,
      consumedQty: consumedQty ?? this.consumedQty,
      details: details ?? this.details,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'base_unit': baseUnit,
        'packaging_unit': packagingUnit,
        'items_per_package': itemsPerPackage,
        'initial_packages': initialPackages,
        'initial_total_qty': initialTotalQty,
        'consumed_qty': consumedQty,
        'details': details,
      };
}

/// Ledger entry recording an individual deduction from inventory
class StockDeductionEntry {
  final String id;
  final String date;
  final String time;
  final String source; // 'Production Register' | 'Milk Standardization' | 'Daily Batch Making'
  final String referenceId; // recordId or batchNo
  final String batchNo;
  final String productName;
  final String inventoryItemId;
  final String inventoryItemName;
  final double quantityDeducted;
  final String unit;
  final bool isCrossVerified;
  final String notes;

  const StockDeductionEntry({
    required this.id,
    required this.date,
    required this.time,
    required this.source,
    required this.referenceId,
    required this.batchNo,
    required this.productName,
    required this.inventoryItemId,
    required this.inventoryItemName,
    required this.quantityDeducted,
    required this.unit,
    this.isCrossVerified = false,
    this.notes = '',
  });
}
