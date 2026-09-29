class SiloModel {
  final String id;
  final String name;
  final String description;
  final double capacityLitres;
  final bool isActive;

  const SiloModel({
    required this.id,
    required this.name,
    required this.description,
    this.capacityLitres = 50000.0,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'capacity_litres': capacityLitres,
      'is_active': isActive,
    };
  }

  factory SiloModel.fromJson(Map<String, dynamic> json) {
    return SiloModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      capacityLitres: (json['capacity_litres'] as num?)?.toDouble() ?? 50000.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  SiloModel copyWith({
    String? id,
    String? name,
    String? description,
    double? capacityLitres,
    bool? isActive,
  }) {
    return SiloModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      capacityLitres: capacityLitres ?? this.capacityLitres,
      isActive: isActive ?? this.isActive,
    );
  }

  static const List<SiloModel> defaultSilos = [
    SiloModel(
      id: 'RMST',
      name: 'RMST',
      description: 'Raw Milk Storage Tank (Reception)',
      capacityLitres: 40000.0,
    ),
    SiloModel(
      id: 'PMST',
      name: 'PMST',
      description: 'Pasteurized Milk Storage Tank',
      capacityLitres: 35000.0,
    ),
    SiloModel(
      id: 'SILO_1',
      name: 'Silo 1',
      description: 'Process Storage Silo #01',
      capacityLitres: 60000.0,
    ),
    SiloModel(
      id: 'SILO_2',
      name: 'Silo 2',
      description: 'Process Storage Silo #02',
      capacityLitres: 60000.0,
    ),
  ];
}
