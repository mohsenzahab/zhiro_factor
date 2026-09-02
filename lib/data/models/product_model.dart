import 'package:equatable/equatable.dart';

/// Product data model.
class ProductModel extends Equatable {
  final int? id;
  final String? code;
  final String name;
  final String? category;
  final double price;
  final String unit;
  final double stock;
  final String? createdAt;
  final bool isTemporary;

  const ProductModel({
    this.id,
    this.code,
    required this.name,
    this.category,
    required this.price,
    required this.unit,
    this.stock = 0,
    this.createdAt,
    this.isTemporary = false,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      code: map['code'] as String?,
      name: map['name'] as String,
      category: map['category'] as String?,
      price: (map['price'] as num).toDouble(),
      unit: map['unit'] as String,
      stock: (map['stock'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] as String?,
      isTemporary: (map['is_temporary'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'name': name,
      'category': category,
      'price': price,
      'unit': unit,
      'stock': stock,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'is_temporary': isTemporary ? 1 : 0,
    };
  }

  ProductModel copyWith({
    int? id,
    String? code,
    String? name,
    String? category,
    double? price,
    String? unit,
    double? stock,
    String? createdAt,
    bool? isTemporary,
  }) {
    return ProductModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
      isTemporary: isTemporary ?? this.isTemporary,
    );
  }

  @override
  List<Object?> get props => [id, code, name, category, price, unit, stock, createdAt, isTemporary];
}

