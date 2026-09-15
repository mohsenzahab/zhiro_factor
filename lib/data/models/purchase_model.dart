import 'package:equatable/equatable.dart';
import 'purchase_item_model.dart';

/// Purchase (فاکتور خرید) data model with embedded line items.
class PurchaseModel extends Equatable {
  final int? id;
  final String purchaseNumber;
  final int? supplierId;
  final String? supplierName; // Joined from suppliers table (read-only)
  final String date; // ISO 8601 string
  final String status;
  final double totalAmount; // Sum of line items
  final double shippingCost;
  final double extraCosts;
  final double totalNet; // totalAmount + shippingCost + extraCosts
  final String? notes;
  final List<PurchaseItemModel> items;

  const PurchaseModel({
    this.id,
    required this.purchaseNumber,
    this.supplierId,
    this.supplierName,
    required this.date,
    required this.status,
    required this.totalAmount,
    this.shippingCost = 0.0,
    this.extraCosts = 0.0,
    required this.totalNet,
    this.notes,
    this.items = const [],
  });

  factory PurchaseModel.fromMap(Map<String, dynamic> map, {List<PurchaseItemModel>? items}) {
    return PurchaseModel(
      id: map['id'] as int?,
      purchaseNumber: map['purchase_number'] as String,
      supplierId: map['supplier_id'] as int?,
      supplierName: map['supplier_name'] as String?,
      date: map['date'] as String,
      status: map['status'] as String? ?? 'در انتظار پرداخت',
      totalAmount: (map['total_amount'] as num).toDouble(),
      shippingCost: (map['shipping_cost'] as num?)?.toDouble() ?? 0.0,
      extraCosts: (map['extra_costs'] as num?)?.toDouble() ?? 0.0,
      totalNet: (map['total_net'] as num).toDouble(),
      notes: map['notes'] as String?,
      items: items ?? const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'purchase_number': purchaseNumber,
      'supplier_id': supplierId,
      'date': date,
      'status': status,
      'total_amount': totalAmount,
      'shipping_cost': shippingCost,
      'extra_costs': extraCosts,
      'total_net': totalNet,
      'notes': notes,
    };
  }

  PurchaseModel copyWith({
    int? id,
    String? purchaseNumber,
    int? supplierId,
    String? supplierName,
    String? date,
    String? status,
    double? totalAmount,
    double? shippingCost,
    double? extraCosts,
    double? totalNet,
    String? notes,
    List<PurchaseItemModel>? items,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      purchaseNumber: purchaseNumber ?? this.purchaseNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      date: date ?? this.date,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      shippingCost: shippingCost ?? this.shippingCost,
      extraCosts: extraCosts ?? this.extraCosts,
      totalNet: totalNet ?? this.totalNet,
      notes: notes ?? this.notes,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
        id,
        purchaseNumber,
        supplierId,
        supplierName,
        date,
        status,
        totalAmount,
        shippingCost,
        extraCosts,
        totalNet,
        notes,
        items,
      ];
}
