import 'package:equatable/equatable.dart';

/// Product data model.
class ProductModel extends Equatable {
  final int? id;
  final String? code;
  final String name;
  final String? category;
  final double buyPrice;
  final double? currentBuyPrice;
  final double? sellPrice;
  final String unit;
  final double stock;
  final String? createdAt;
  final String? buyDate;
  final String? supplier;
  final bool isTemporary;

  const ProductModel({
    this.id,
    this.code,
    required this.name,
    this.category,
    required this.buyPrice,
    this.currentBuyPrice,
    this.sellPrice,
    required this.unit,
    this.stock = 0,
    this.createdAt,
    this.buyDate,
    this.supplier,
    this.isTemporary = false,
  });

  /// The price used in invoices: sell price if set, otherwise buy price.
  double get effectivePrice => sellPrice ?? buyPrice;

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      code: map['code'] as String?,
      name: map['name'] as String,
      category: map['category'] as String?,
      buyPrice: (map['buy_price'] as num).toDouble(),
      currentBuyPrice: map['current_buy_price'] != null ? (map['current_buy_price'] as num).toDouble() : null,
      sellPrice: map['sell_price'] != null ? (map['sell_price'] as num).toDouble() : null,
      unit: map['unit'] as String,
      stock: (map['stock'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] as String?,
      buyDate: map['buy_date'] as String?,
      supplier: map['supplier'] as String?,
      isTemporary: (map['is_temporary'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'name': name,
      'category': category,
      'buy_price': buyPrice,
      'current_buy_price': currentBuyPrice,
      'sell_price': sellPrice,
      'unit': unit,
      'stock': stock,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'buy_date': buyDate,
      'supplier': supplier,
      'is_temporary': isTemporary ? 1 : 0,
    };
  }

  ProductModel copyWith({
    int? id,
    String? code,
    String? name,
    String? category,
    double? buyPrice,
    double? currentBuyPrice,
    double? sellPrice,
    bool clearSellPrice = false,
    String? unit,
    double? stock,
    String? createdAt,
    String? buyDate,
    String? supplier,
    bool? isTemporary,
  }) {
    return ProductModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      buyPrice: buyPrice ?? this.buyPrice,
      currentBuyPrice: currentBuyPrice ?? this.currentBuyPrice,
      sellPrice: clearSellPrice ? null : (sellPrice ?? this.sellPrice),
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
      buyDate: buyDate ?? this.buyDate,
      supplier: supplier ?? this.supplier,
      isTemporary: isTemporary ?? this.isTemporary,
    );
  }

  @override
  List<Object?> get props => [id, code, name, category, buyPrice, currentBuyPrice, sellPrice, unit, stock, createdAt, buyDate, supplier, isTemporary];
}
