import 'package:equatable/equatable.dart';

/// Single line item within a purchase.
class PurchaseItemModel extends Equatable {
  final int? id;
  final int? purchaseId;
  final int? productId;
  final String productName;
  final double unitPrice;
  final double quantity;
  final double lineTotal;

  const PurchaseItemModel({
    this.id,
    this.purchaseId,
    this.productId,
    required this.productName,
    required this.unitPrice,
    this.quantity = 1.0,
    required this.lineTotal,
  });

  /// Recalculates line total from current values.
  PurchaseItemModel recalculate() {
    final total = unitPrice * quantity;
    return copyWith(lineTotal: total < 0 ? 0 : total);
  }

  factory PurchaseItemModel.fromMap(Map<String, dynamic> map) {
    return PurchaseItemModel(
      id: map['id'] as int?,
      purchaseId: map['purchase_id'] as int?,
      productId: map['product_id'] as int?,
      productName: map['product_name'] as String,
      unitPrice: (map['unit_price'] as num).toDouble(),
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      lineTotal: (map['line_total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (purchaseId != null) 'purchase_id': purchaseId,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'line_total': lineTotal,
    };
  }

  PurchaseItemModel copyWith({
    int? id,
    int? purchaseId,
    int? productId,
    String? productName,
    double? unitPrice,
    double? quantity,
    double? lineTotal,
  }) {
    return PurchaseItemModel(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }

  @override
  List<Object?> get props => [
        id,
        purchaseId,
        productId,
        productName,
        unitPrice,
        quantity,
        lineTotal,
      ];
}
