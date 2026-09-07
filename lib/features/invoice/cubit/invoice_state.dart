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

  /// Invoice-level overall discount type: 'none', 'percentage', 'amount'
  final String overallDiscountType;

  /// The raw value entered by user (percentage number or fixed toman amount)
  final double overallDiscountValue;

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
    this.overallDiscountType = 'none',
    this.overallDiscountValue = 0.0,
  });

  /// Total gross = sum of (unitPrice * quantity) for all items.
  double get totalGross {
    return items.fold(0.0, (sum, item) => sum + (item.unitPrice * item.quantity));
  }

  /// Total line-item discount = sum of discountCalculatedAmount for all items.
  double get totalItemDiscount {
    return items.fold(0.0, (sum, item) => sum + item.discountCalculatedAmount);
  }

  /// Subtotal after item-level discounts (before overall discount).
  double get subtotalAfterItemDiscounts => totalGross - totalItemDiscount;

  /// Calculated overall discount amount based on type and value.
  double get overallDiscountAmount {
    if (overallDiscountType == 'none' || overallDiscountValue <= 0) return 0.0;
    if (overallDiscountType == 'percentage') {
      return subtotalAfterItemDiscounts * (overallDiscountValue / 100.0);
    }
    // 'amount' — fixed toman value, capped at subtotal
    return overallDiscountValue.clamp(0, subtotalAfterItemDiscounts);
  }

  /// Total discount = line-item discounts + overall discount.
  double get totalDiscount => totalItemDiscount + overallDiscountAmount;

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
    String? overallDiscountType,
    double? overallDiscountValue,
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
      overallDiscountType: overallDiscountType ?? this.overallDiscountType,
      overallDiscountValue: overallDiscountValue ?? this.overallDiscountValue,
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
        overallDiscountType,
        overallDiscountValue,
      ];
}
