import 'package:equatable/equatable.dart';

/// Represents a partial payment (دریافتی / قسط / تسویه مرحله‌ای) for an invoice.
class InvoicePaymentModel extends Equatable {
  final int? id;
  final int? invoiceId;
  final double amount;
  final String date; // ISO 8601 string or date
  final String? note;

  const InvoicePaymentModel({
    this.id,
    this.invoiceId,
    required this.amount,
    required this.date,
    this.note,
  });

  factory InvoicePaymentModel.fromMap(Map<String, dynamic> map) {
    return InvoicePaymentModel(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] as String,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      'amount': amount,
      'date': date,
      'note': note,
    };
  }

  InvoicePaymentModel copyWith({
    int? id,
    int? invoiceId,
    double? amount,
    String? date,
    String? note,
  }) {
    return InvoicePaymentModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [id, invoiceId, amount, date, note];
}
