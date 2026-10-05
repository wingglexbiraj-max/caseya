class SiloModel {
  final String id;
  final String name;
  final String description;
  final double capacityLitres;
  final bool isActive;
  final double currentStockLitres;
  final DateTime? lastStockUpdated;

  const SiloModel({
    required this.id,
    required this.name,
    required this.description,
    this.capacityLitres = 50000.0,
    this.isActive = true,
    this.currentStockLitres = 0.0,
    this.lastStockUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'capacity_litres': capacityLitres,
      'is_active': isActive,
      'current_stock_litres': currentStockLitres,
      'last_stock_updated': lastStockUpdated?.toIso8601String(),
    };
  }

  factory SiloModel.fromJson(Map<String, dynamic> json) {
    return SiloModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      capacityLitres: (json['capacity_litres'] as num?)?.toDouble() ?? 50000.0,
      isActive: json['is_active'] as bool? ?? true,
      currentStockLitres: (json['current_stock_litres'] as num?)?.toDouble() ?? 0.0,
      lastStockUpdated: DateTime.tryParse(json['last_stock_updated']?.toString() ?? ''),
    );
  }

  SiloModel copyWith({
    String? id,
    String? name,
    String? description,
    double? capacityLitres,
    bool? isActive,
    double? currentStockLitres,
    DateTime? lastStockUpdated,
  }) {
    return SiloModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      capacityLitres: capacityLitres ?? this.capacityLitres,
      isActive: isActive ?? this.isActive,
      currentStockLitres: currentStockLitres ?? this.currentStockLitres,
      lastStockUpdated: lastStockUpdated ?? this.lastStockUpdated,
    );
  }

  static const List<SiloModel> defaultSilos = [
    SiloModel(
      id: 'RMST',
      name: 'RMST',
      description: 'Raw Milk Storage Tank',
      capacityLitres: 40000.0,
      currentStockLitres: 12500.0,
    ),
    SiloModel(
      id: 'PMST',
      name: 'PMST',
      description: 'Pasteurized Milk Storage Tank',
      capacityLitres: 35000.0,
      currentStockLitres: 8200.0,
    ),
  ];
}
