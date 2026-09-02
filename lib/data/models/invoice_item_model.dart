import 'package:equatable/equatable.dart';

/// Single line item within an invoice.
class InvoiceItemModel extends Equatable {
  final int? id;
  final int? invoiceId;
  final int? productId;
  final String productName;
  final double unitPrice;
  final double quantity;
  final String discountType; // 'none', 'percentage', 'amount'
  final double discountValue;
  final double discountCalculatedAmount;
  final double lineTotal;

  const InvoiceItemModel({
    this.id,
    this.invoiceId,
    this.productId,
    required this.productName,
    required this.unitPrice,
    this.quantity = 1.0,
    this.discountType = 'none',
    this.discountValue = 0.0,
    this.discountCalculatedAmount = 0.0,
    required this.lineTotal,
  });

  /// Recalculates discount and line total from current values.
  InvoiceItemModel recalculate() {
    final gross = unitPrice * quantity;
    double discCalc = 0;
    switch (discountType) {
      case 'percentage':
        discCalc = gross * (discountValue / 100.0);
        break;
      case 'amount':
        discCalc = discountValue;
        break;
      default:
        discCalc = 0;
    }
    // Ensure discount doesn't exceed gross
    if (discCalc > gross) discCalc = gross;
    final net = gross - discCalc;
    return copyWith(
      discountCalculatedAmount: discCalc,
      lineTotal: net < 0 ? 0 : net,
    );
  }

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    return InvoiceItemModel(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      productId: map['product_id'] as int?,
      productName: map['product_name'] as String,
      unitPrice: (map['unit_price'] as num).toDouble(),
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      discountType: map['discount_type'] as String? ?? 'none',
      discountValue: (map['discount_value'] as num?)?.toDouble() ?? 0.0,
      discountCalculatedAmount: (map['discount_calculated_amount'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (map['line_total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'discount_type': discountType,
      'discount_value': discountValue,
      'discount_calculated_amount': discountCalculatedAmount,
      'line_total': lineTotal,
    };
  }

  InvoiceItemModel copyWith({
    int? id,
    int? invoiceId,
    int? productId,
    String? productName,
    double? unitPrice,
    double? quantity,
    String? discountType,
    double? discountValue,
    double? discountCalculatedAmount,
    double? lineTotal,
  }) {
    return InvoiceItemModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountCalculatedAmount: discountCalculatedAmount ?? this.discountCalculatedAmount,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }

  @override
  List<Object?> get props => [
        id,
        invoiceId,
        productId,
        productName,
        unitPrice,
        quantity,
        discountType,
        discountValue,
        discountCalculatedAmount,
        lineTotal,
      ];
}
