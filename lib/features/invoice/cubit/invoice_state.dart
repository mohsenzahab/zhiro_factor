import 'package:equatable/equatable.dart';
import '../../../data/models/invoice_item_model.dart';
import '../../../data/models/customer_model.dart';

/// Invoice editor state.
class InvoiceState extends Equatable {
  final int? editingInvoiceId;
  final String invoiceNumber;
  final String date; // ISO 8601
  final CustomerModel? selectedCustomer;
  final String status;
  final List<InvoiceItemModel> items;
  final String? notes;
  final bool isSaving;
  final bool isSaved;
  final String? errorMessage;

  const InvoiceState({
    this.editingInvoiceId,
    this.invoiceNumber = '',
    this.date = '',
    this.selectedCustomer,
    this.status = 'در انتظار پرداخت',
    this.items = const [],
    this.notes,
    this.isSaving = false,
    this.isSaved = false,
    this.errorMessage,
  });

  /// Total gross = sum of (unitPrice * quantity) for all items.
  double get totalGross {
    return items.fold(0.0, (sum, item) => sum + (item.unitPrice * item.quantity));
  }

  /// Total discount = sum of discountCalculatedAmount for all items.
  double get totalDiscount {
    return items.fold(0.0, (sum, item) => sum + item.discountCalculatedAmount);
  }

  /// Total net = totalGross - totalDiscount.
  double get totalNet => totalGross - totalDiscount;

  InvoiceState copyWith({
    int? editingInvoiceId,
    String? invoiceNumber,
    String? date,
    CustomerModel? selectedCustomer,
    bool clearCustomer = false,
    String? status,
    List<InvoiceItemModel>? items,
    String? notes,
    bool? isSaving,
    bool? isSaved,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InvoiceState(
      editingInvoiceId: editingInvoiceId ?? this.editingInvoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      status: status ?? this.status,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        editingInvoiceId,
        invoiceNumber,
        date,
        selectedCustomer,
        status,
        items,
        notes,
        isSaving,
        isSaved,
        errorMessage,
      ];
}
