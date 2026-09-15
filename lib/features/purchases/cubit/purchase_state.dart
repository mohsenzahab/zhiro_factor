import 'package:equatable/equatable.dart';
import '../../../data/models/purchase_item_model.dart';
import '../../../data/models/supplier_model.dart';

/// Purchase editor state.
class PurchaseState extends Equatable {
  final int? editingPurchaseId;
  final String purchaseNumber;
  final String date; // ISO 8601
  final SupplierModel? selectedSupplier;
  final String status;
  final List<PurchaseItemModel> items;
  final double shippingCost;
  final double extraCosts;
  final String? notes;
  final bool isSaving;
  final bool isSaved;
  final String? errorMessage;

  const PurchaseState({
    this.editingPurchaseId,
    this.purchaseNumber = '',
    this.date = '',
    this.selectedSupplier,
    this.status = 'در انتظار پرداخت',
    this.items = const [],
    this.shippingCost = 0.0,
    this.extraCosts = 0.0,
    this.notes,
    this.isSaving = false,
    this.isSaved = false,
    this.errorMessage,
  });

  /// Total amount = sum of line totals.
  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.lineTotal);
  }

  /// Total net = totalAmount + shippingCost + extraCosts.
  double get totalNet => totalAmount + shippingCost + extraCosts;

  PurchaseState copyWith({
    int? editingPurchaseId,
    String? purchaseNumber,
    String? date,
    SupplierModel? selectedSupplier,
    bool clearSupplier = false,
    String? status,
    List<PurchaseItemModel>? items,
    double? shippingCost,
    double? extraCosts,
    String? notes,
    bool? isSaving,
    bool? isSaved,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PurchaseState(
      editingPurchaseId: editingPurchaseId ?? this.editingPurchaseId,
      purchaseNumber: purchaseNumber ?? this.purchaseNumber,
      date: date ?? this.date,
      selectedSupplier: clearSupplier ? null : (selectedSupplier ?? this.selectedSupplier),
      status: status ?? this.status,
      items: items ?? this.items,
      shippingCost: shippingCost ?? this.shippingCost,
      extraCosts: extraCosts ?? this.extraCosts,
      notes: notes ?? this.notes,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        editingPurchaseId,
        purchaseNumber,
        date,
        selectedSupplier,
        status,
        items,
        shippingCost,
        extraCosts,
        notes,
        isSaving,
        isSaved,
        errorMessage,
      ];
}
