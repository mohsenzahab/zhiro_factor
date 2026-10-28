import 'package:equatable/equatable.dart';
import '../../core/extensions/number_extensions.dart';
import '../../core/utils/jalali_utils.dart';

/// Represents a single sales record (item in a customer invoice) for a specific product.
class ProductSaleRecord extends Equatable {
  final int itemId;
  final int invoiceId;
  final String invoiceNumber;
  final String date;
  final String invoiceStatus;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final int productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double purchasePrice;
  final String discountType;
  final double discountValue;
  final double discountCalculatedAmount;
  final double lineTotal;
  final String productUnit;

  const ProductSaleRecord({
    required this.itemId,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.date,
    required this.invoiceStatus,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.purchasePrice,
    required this.discountType,
    required this.discountValue,
    required this.discountCalculatedAmount,
    required this.lineTotal,
    this.productUnit = 'عدد',
  });

  /// Profit amount for this line item (lineTotal - (quantity * purchasePrice)).
  double get profitAmount => lineTotal - (quantity * purchasePrice);

  /// Profit percentage relative to purchase cost.
  double get profitPercentage {
    final cost = quantity * purchasePrice;
    if (cost <= 0) return 100.0;
    return (profitAmount / cost) * 100.0;
  }

  /// Display customer name or fallback.
  String get customerDisplay =>
      (customerName != null && customerName!.trim().isNotEmpty) ? customerName!.trim() : 'مشتری نقدی / عمومی';

  /// Formatted Persian Jalali date string.
  String get jalaliDate => JalaliUtils.formatIso(date);

  /// User-friendly quantity display with unit.
  String get quantityDisplay => '${quantity.formattedInt} $productUnit';

  /// User-friendly formatted unit price.
  String get unitPriceDisplay => unitPrice.toman;

  /// User-friendly formatted line total.
  String get lineTotalDisplay => lineTotal.toman;

  /// Formatted profit display.
  String get profitDisplay => '${profitAmount >= 0 ? '+' : ''}${profitAmount.round().formatted} تومان';

  factory ProductSaleRecord.fromMap(Map<String, dynamic> map) {
    final buyPriceFallback = (map['current_buy_price'] as num?)?.toDouble() ??
        (map['buy_price'] as num?)?.toDouble() ??
        0.0;
    final itemPurchasePrice = (map['purchase_price'] as num?)?.toDouble() ?? 0.0;
    final effectiveCost = itemPurchasePrice > 0 ? itemPurchasePrice : buyPriceFallback;

    return ProductSaleRecord(
      itemId: map['item_id'] as int,
      invoiceId: map['invoice_id'] as int,
      invoiceNumber: (map['invoice_number'] as String?) ?? '',
      date: (map['date'] as String?) ?? '',
      invoiceStatus: (map['invoice_status'] as String?) ?? 'تسویه شده',
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      productId: map['product_id'] as int,
      productName: (map['product_name'] as String?) ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: effectiveCost,
      discountType: (map['discount_type'] as String?) ?? 'none',
      discountValue: (map['discount_value'] as num?)?.toDouble() ?? 0.0,
      discountCalculatedAmount: (map['discount_calculated_amount'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (map['line_total'] as num?)?.toDouble() ?? 0.0,
      productUnit: (map['product_unit'] as String?)?.trim().isNotEmpty == true
          ? (map['product_unit'] as String).trim()
          : 'عدد',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'invoice_id': invoiceId,
      'invoice_number': invoiceNumber,
      'date': date,
      'invoice_status': invoiceStatus,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'purchase_price': purchasePrice,
      'discount_type': discountType,
      'discount_value': discountValue,
      'discount_calculated_amount': discountCalculatedAmount,
      'line_total': lineTotal,
      'product_unit': productUnit,
    };
  }

  @override
  List<Object?> get props => [
        itemId,
        invoiceId,
        invoiceNumber,
        date,
        invoiceStatus,
        customerId,
        customerName,
        productId,
        quantity,
        unitPrice,
        purchasePrice,
        discountCalculatedAmount,
        lineTotal,
      ];
}

