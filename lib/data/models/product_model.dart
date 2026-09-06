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
  final double totalSold;

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
    this.totalSold = 0.0,
  }) : sellPrice = sellPrice?.roundTo5000;

  /// The price used in invoices: sell price if set, otherwise buy price.
  double get effectivePrice => (sellPrice ?? buyPrice).roundTo5000;

  /// The active base buy price (current buy price if set and > 0, otherwise initial buy price).
  double get effectiveBuyPrice => (currentBuyPrice != null && currentBuyPrice! > 0) ? currentBuyPrice! : buyPrice;

  /// Profit amount per unit (sellPrice - effectiveBuyPrice).
  double get profitAmount => effectivePrice - effectiveBuyPrice;

  /// Profit margin percentage relative to effective buy price.
  double get profitPercent => effectiveBuyPrice > 0 ? ((profitAmount / effectiveBuyPrice) * 100.0) : 0.0;

  /// Formatted profit amount display (e.g. "+۱۵,۰۰۰ تومان" or "-۵,۰۰۰ تومان").
  String get profitAmountDisplay => '${profitAmount >= 0 ? '+' : ''}${profitAmount.round().formatted} تومان';

  /// Formatted profit percent display (e.g. "۲۵٪").
  String get profitPercentDisplay => '${profitPercent.toStringAsFixed(profitPercent % 1 == 0 ? 0 : 1)}٪';

  /// User-facing string representation of total units sold.
  String get totalSoldDisplay => totalSold == totalSold.roundToDouble() ? totalSold.toInt().formattedInt : totalSold.formatted;

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
      totalSold: (map['total_sold'] as num?)?.toDouble() ?? 0.0,
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
    double? totalSold,
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
      totalSold: totalSold ?? this.totalSold,
    );
  }

  @override
  List<Object?> get props => [id, code, name, category, buyPrice, currentBuyPrice, sellPrice, unit, stock, createdAt, buyDate, supplier, isTemporary, totalSold];
}
