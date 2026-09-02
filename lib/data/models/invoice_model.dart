import 'package:equatable/equatable.dart';
import 'invoice_item_model.dart';

/// Invoice data model with embedded line items.
class InvoiceModel extends Equatable {
  final int? id;
  final String invoiceNumber;
  final int? customerId;
  final String? customerName; // Joined from customers table (read-only)
  final String date; // ISO 8601 string
  final String status;
  final double totalGross;
  final double totalDiscount;
  final double totalNet;
  final String? notes;
  final List<InvoiceItemModel> items;

  const InvoiceModel({
    this.id,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    required this.date,
    required this.status,
    required this.totalGross,
    required this.totalDiscount,
    required this.totalNet,
    this.notes,
    this.items = const [],
  });

  factory InvoiceModel.fromMap(Map<String, dynamic> map, {List<InvoiceItemModel>? items}) {
    return InvoiceModel(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String?,
      date: map['date'] as String,
      status: map['status'] as String? ?? 'در انتظار پرداخت',
      totalGross: (map['total_gross'] as num).toDouble(),
      totalDiscount: (map['total_discount'] as num).toDouble(),
      totalNet: (map['total_net'] as num).toDouble(),
      notes: map['notes'] as String?,
      items: items ?? const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'date': date,
      'status': status,
      'total_gross': totalGross,
      'total_discount': totalDiscount,
      'total_net': totalNet,
      'notes': notes,
    };
  }

  InvoiceModel copyWith({
    int? id,
    String? invoiceNumber,
    int? customerId,
    String? customerName,
    String? date,
    String? status,
    double? totalGross,
    double? totalDiscount,
    double? totalNet,
    String? notes,
    List<InvoiceItemModel>? items,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      date: date ?? this.date,
      status: status ?? this.status,
      totalGross: totalGross ?? this.totalGross,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      totalNet: totalNet ?? this.totalNet,
      notes: notes ?? this.notes,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        customerId,
        customerName,
        date,
        status,
        totalGross,
        totalDiscount,
        totalNet,
        notes,
        items,
      ];
}
