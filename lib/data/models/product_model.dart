import 'package:equatable/equatable.dart';
import '../../core/extensions/number_extensions.dart';

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
  final double? stock;
  final String? createdAt;
  final String? buyDate;
  final String? supplier;
  final bool isTemporary;

  ProductModel({
    this.id,
    this.code,
    required this.name,
    this.category,
    required this.buyPrice,
    this.currentBuyPrice,
    double? sellPrice,
    required this.unit,
    this.stock,
    this.createdAt,
    this.buyDate,
    this.supplier,
    this.isTemporary = false,
  }) : sellPrice = sellPrice?.roundTo5000;

  /// The price used in invoices: sell price if set, otherwise buy price.
  double get effectivePrice => (sellPrice ?? buyPrice).roundTo5000;

  /// Whether the stock is infinite/unlimited.
  /// Recognizes null, infinity, or legacy 9999 placeholder.
  bool get isInfiniteStock => stock == null || stock!.isInfinite || stock == 9999;

  /// User-facing string representation of stock.
  String get stockDisplay => isInfiniteStock ? 'نامحدود' : stock!.formattedInt;

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      code: (map['code'] as String?)?.trim().isNotEmpty == true ? (map['code'] as String).trim() : null,
      name: map['name'] as String,
      category: map['category'] as String?,
      buyPrice: (map['buy_price'] as num).toDouble(),
      currentBuyPrice: map['current_buy_price'] != null ? (map['current_buy_price'] as num).toDouble() : null,
      sellPrice: map['sell_price'] != null ? (map['sell_price'] as num).toDouble().roundTo5000 : null,
      unit: map['unit'] as String,
      stock: (map['stock'] as num?)?.toDouble(),
      createdAt: map['created_at'] as String?,
      buyDate: map['buy_date'] as String?,
      supplier: map['supplier'] as String?,
      isTemporary: (map['is_temporary'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    final cleanCode = (code != null && code!.trim().isNotEmpty) ? code!.trim() : null;
    final cleanCategory = (category != null && category!.trim().isNotEmpty) ? category!.trim() : null;
    final cleanSupplier = (supplier != null && supplier!.trim().isNotEmpty) ? supplier!.trim() : null;
    return {
      if (id != null) 'id': id,
      'code': cleanCode,
      'name': name.trim(),
      'category': cleanCategory,
      'buy_price': buyPrice,
      'current_buy_price': currentBuyPrice,
      'sell_price': sellPrice?.roundTo5000,
      'unit': unit,
      'stock': isInfiniteStock ? null : stock,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'buy_date': buyDate,
      'supplier': cleanSupplier,
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
    bool clearStock = false,
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
      sellPrice: clearSellPrice ? null : (sellPrice != null ? sellPrice.roundTo5000 : this.sellPrice?.roundTo5000),
      unit: unit ?? this.unit,
      stock: clearStock ? null : (stock ?? this.stock),
      createdAt: createdAt ?? this.createdAt,
      buyDate: buyDate ?? this.buyDate,
      supplier: supplier ?? this.supplier,
      isTemporary: isTemporary ?? this.isTemporary,
    );
  }

  @override
  List<Object?> get props => [id, code, name, category, buyPrice, currentBuyPrice, sellPrice, unit, stock, createdAt, buyDate, supplier, isTemporary];
}
