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
  final double addedQty; // newly received inward stock added by user
  final String lastUpdated; // date & time when this item was last received or updated
  final String details; // e.g. '2,500 pcs / box'
  final IconData icon;
  final double? criticalLimit; // Threshold below which stock is Critical
  final double? adequateLimit; // Threshold above which stock is Adequate
  final String? limitDescription; // Canonical description of limits

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
    this.addedQty = 0.0,
    this.lastUpdated = '06 Oct 2026 • 08:00 AM',
    required this.details,
    required this.icon,
    this.criticalLimit,
    this.adequateLimit,
    this.limitDescription,
  });

  /// Current available quantity after inward additions and production deductions
  double get remainingQty {
    final rem = (initialTotalQty + addedQty) - consumedQty;
    return rem > 0 ? rem : 0.0;
  }

  /// Current packages remaining based on itemsPerPackage
  double get remainingPackages {
    if (itemsPerPackage <= 0) return 0.0;
    return remainingQty / itemsPerPackage;
  }

  /// Whether any quantity of this item has been deducted
  bool get hasConsumption => consumedQty > 0.0001;

  /// Whether any inward stock has been added to this item
  bool get hasAddedStock => addedQty > 0.0001;

  /// Dynamic status based on defined limits or remaining stock level
  String get status {
    if (criticalLimit != null && adequateLimit != null) {
      if (remainingQty < criticalLimit!) {
        return 'Critical';
      }
      if (remainingQty <= adequateLimit!) {
        return 'Low';
      }
      return 'Adequate';
    }

    if (remainingQty <= 0) {
      return 'Critical';
    }
    // Fallback: Low stock if less than 20% of initial baseline
    if (remainingQty < (initialTotalQty * 0.20)) {
      return 'Low';
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
    double? addedQty,
    String? lastUpdated,
    String? details,
    IconData? icon,
    double? criticalLimit,
    double? adequateLimit,
    String? limitDescription,
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
      addedQty: addedQty ?? this.addedQty,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      details: details ?? this.details,
      icon: icon ?? this.icon,
      criticalLimit: criticalLimit ?? this.criticalLimit,
      adequateLimit: adequateLimit ?? this.adequateLimit,
      limitDescription: limitDescription ?? this.limitDescription,
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
        'added_qty': addedQty,
        'last_updated': lastUpdated,
        'details': details,
        'critical_limit': criticalLimit,
        'adequate_limit': adequateLimit,
        'limit_description': limitDescription,
      };
}

/// Ledger entry recording an inward stock receipt added by the user
class InwardStockEntry {
  final String id;
  final String itemId;
  final String itemName;
  final double quantity; // in baseUnit
  final double packages; // in packagingUnit
  final String unit;
  final String packagingUnit;
  final String date;
  final String time;
  final String notes;

  const InwardStockEntry({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.packages,
    required this.unit,
    required this.packagingUnit,
    required this.date,
    required this.time,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': itemId,
        'itemName': itemName,
        'quantity': quantity,
        'packages': packages,
        'unit': unit,
        'packagingUnit': packagingUnit,
        'date': date,
        'time': time,
        'notes': notes,
      };

  factory InwardStockEntry.fromJson(Map<String, dynamic> json) => InwardStockEntry(
        id: json['id'] ?? '',
        itemId: json['itemId'] ?? '',
        itemName: json['itemName'] ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
        packages: (json['packages'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit'] ?? '',
        packagingUnit: json['packagingUnit'] ?? '',
        date: json['date'] ?? '',
        time: json['time'] ?? '',
        notes: json['notes'] ?? '',
      );
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
