// lib/models/equipment_model.dart

enum EquipmentStatus { normal, damaged, repairing, disposed, lost }

extension EquipmentStatusExt on EquipmentStatus {
  String get value {
    switch (this) {
      case EquipmentStatus.normal:
        return 'normal';
      case EquipmentStatus.damaged:
        return 'damaged';
      case EquipmentStatus.repairing:
        return 'repairing';
      case EquipmentStatus.disposed:
        return 'disposed';
      case EquipmentStatus.lost:
        return 'lost';
    }
  }

  String get label {
    switch (this) {
      case EquipmentStatus.normal:
        return 'ปกติ';
      case EquipmentStatus.damaged:
        return 'ชำรุด';
      case EquipmentStatus.repairing:
        return 'รอซ่อม';
      case EquipmentStatus.disposed:
        return 'จำหน่ายออก';
      case EquipmentStatus.lost:
        return 'สูญหาย';
    }
  }

  static EquipmentStatus fromString(String v) {
    switch (v) {
      case 'damaged':
        return EquipmentStatus.damaged;
      case 'repairing':
        return EquipmentStatus.repairing;
      case 'disposed':
        return EquipmentStatus.disposed;
      case 'lost':
        return EquipmentStatus.lost;
      default:
        return EquipmentStatus.normal;
    }
  }
}

class EquipmentModel {
  final String id;
  final String assetCode;
  final String name;
  final String brand;
  final String model;
  final String category;
  final String description;
  final String location;
  final EquipmentStatus status;
  final String? imageUrl;
  final String? serialNumber;
  final double? purchasePrice;
  final DateTime? purchaseDate;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  EquipmentModel({
    required this.id,
    required this.assetCode,
    required this.name,
    required this.brand,
    required this.model,
    required this.category,
    required this.description,
    required this.location,
    required this.status,
    this.imageUrl,
    this.serialNumber,
    this.purchasePrice,
    this.purchaseDate,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EquipmentModel.fromMap(Map<String, dynamic> map, String id) {
    return EquipmentModel(
      id: id,
      assetCode: map['assetCode'] ?? '',
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      status: EquipmentStatusExt.fromString(map['status'] ?? 'normal'),
      imageUrl: map['imageUrl'],
      serialNumber: map['serialNumber'],
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble(),
      purchaseDate: map['purchaseDate'] != null
          ? DateTime.tryParse(map['purchaseDate'])
          : null,
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'assetCode': assetCode,
        'name': name,
        'brand': brand,
        'model': model,
        'category': category,
        'description': description,
        'location': location,
        'status': status.value,
        'imageUrl': imageUrl,
        'serialNumber': serialNumber,
        'purchasePrice': purchasePrice,
        'purchaseDate': purchaseDate?.toIso8601String(),
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  EquipmentModel copyWith({
    String? assetCode,
    String? name,
    String? brand,
    String? model,
    String? category,
    String? description,
    String? location,
    EquipmentStatus? status,
    String? imageUrl,
    String? serialNumber,
    double? purchasePrice,
    DateTime? purchaseDate,
  }) {
    return EquipmentModel(
      id: id,
      assetCode: assetCode ?? this.assetCode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      category: category ?? this.category,
      description: description ?? this.description,
      location: location ?? this.location,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      serialNumber: serialNumber ?? this.serialNumber,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
