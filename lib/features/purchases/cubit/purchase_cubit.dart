import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/purchase_model.dart';
import '../../../data/models/purchase_item_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/supplier_model.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../../../core/extensions/number_extensions.dart';
import 'purchase_state.dart';

class PurchaseCubit extends Cubit<PurchaseState> {
  final PurchaseRepository _repository = PurchaseRepository();

  PurchaseCubit() : super(const PurchaseState());

  /// Initialize a new purchase with auto-generated number and current date.
  Future<void> initNew() async {
    final counter = await _repository.nextCounter();
    final purchaseNumber = 'PUR-${counter.toString().padLeft(4, '0')}';
    emit(PurchaseState(
      purchaseNumber: purchaseNumber,
      date: DateTime.now().toIso8601String(),
      status: 'در انتظار پرداخت',
    ));
  }

  /// Load an existing purchase for editing.
  Future<void> loadExisting(int purchaseId) async {
    final purchase = await _repository.getById(purchaseId);
    if (purchase == null) return;

    emit(PurchaseState(
      editingPurchaseId: purchase.id,
      purchaseNumber: purchase.purchaseNumber,
      date: purchase.date,
      selectedSupplier: purchase.supplierId != null
          ? SupplierModel(id: purchase.supplierId, name: purchase.supplierName ?? '')
          : null,
      status: purchase.status,
      items: purchase.items,
      shippingCost: purchase.shippingCost,
      extraCosts: purchase.extraCosts,
      notes: purchase.notes,
    ));
  }

  void setPurchaseNumber(String number) {
    emit(state.copyWith(purchaseNumber: number));
  }

  void setDate(String isoDate) {
    emit(state.copyWith(date: isoDate));
  }

  void setSupplier(SupplierModel? supplier) {
    if (supplier == null) {
      emit(state.copyWith(clearSupplier: true));
    } else {
      emit(state.copyWith(selectedSupplier: supplier));
    }
  }

  void setStatus(String status) {
    emit(state.copyWith(status: status));
  }

  void setNotes(String notes) {
    emit(state.copyWith(notes: notes));
  }

  void setShippingCost(double cost) {
    emit(state.copyWith(shippingCost: cost));
  }

  void setExtraCosts(double cost) {
    emit(state.copyWith(extraCosts: cost));
  }

  /// Add a product as a new line item using its buy price.
  void addItem(ProductModel product) {
    final item = PurchaseItemModel(
      productId: product.id,
      productName: product.name,
      unitPrice: product.effectiveBuyPrice,
      quantity: 1.0,
      lineTotal: product.effectiveBuyPrice,
    );
    emit(state.copyWith(items: [...state.items, item]));
  }

  /// Add a custom item (new product being purchased).
  void addCustomItem(String name, double unitPrice, double quantity) {
    final item = PurchaseItemModel(
      productName: name,
      unitPrice: unitPrice,
      quantity: quantity,
      lineTotal: unitPrice * quantity,
    );
    emit(state.copyWith(items: [...state.items, item]));
  }

  /// Remove an item at index.
  void removeItem(int index) {
    final items = List<PurchaseItemModel>.from(state.items);
    items.removeAt(index);
    emit(state.copyWith(items: items));
  }

  /// Update quantity for item at index.
  void updateItemQuantity(int index, double quantity) {
    final items = List<PurchaseItemModel>.from(state.items);
    items[index] = items[index].copyWith(quantity: quantity).recalculate();
    emit(state.copyWith(items: items));
  }

  /// Update unit price for item at index.
  void updateItemPrice(int index, double price) {
    final items = List<PurchaseItemModel>.from(state.items);
    items[index] = items[index].copyWith(unitPrice: price).recalculate();
    emit(state.copyWith(items: items));
  }

  /// Save the purchase (insert or update).
  Future<void> save() async {
    if (state.items.isEmpty) {
      emit(state.copyWith(errorMessage: 'حداقل یک کالا باید به خرید اضافه شود'));
      return;
    }

    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final purchase = PurchaseModel(
        id: state.editingPurchaseId,
        purchaseNumber: state.purchaseNumber.toEnglishDigits(),
        supplierId: state.selectedSupplier?.id,
        supplierName: state.selectedSupplier?.name,
        date: state.date,
        status: state.status,
        totalAmount: state.totalAmount,
        shippingCost: state.shippingCost,
        extraCosts: state.extraCosts,
        totalNet: state.totalNet,
        notes: state.notes,
        items: state.items,
      );

      if (state.editingPurchaseId != null) {
        await _repository.update(purchase);
      } else {
        await _repository.insert(purchase);
      }

      emit(state.copyWith(isSaving: false, isSaved: true));
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  /// Reset to a fresh new purchase.
  Future<void> reset() async {
    await initNew();
  }
}
