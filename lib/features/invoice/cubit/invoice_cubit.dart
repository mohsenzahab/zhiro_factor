import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/invoice_item_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/preset_template_model.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/preset_template_repository.dart';
import '../../../core/utils/invoice_number_generator.dart';
import 'invoice_state.dart';

class InvoiceCubit extends Cubit<InvoiceState> {
  final InvoiceRepository _repository = InvoiceRepository();
  final PresetTemplateRepository _templateRepo = PresetTemplateRepository();

  InvoiceCubit() : super(const InvoiceState());

  /// Initialize a new invoice with auto-generated number and current date.
  Future<void> initNew() async {
    final counter = await _repository.nextCounter();
    final invoiceNumber = InvoiceNumberGenerator.generate(counter);
    emit(InvoiceState(
      invoiceNumber: invoiceNumber,
      date: DateTime.now().toIso8601String(),
      status: 'در انتظار پرداخت',
    ));
  }

  /// Load an existing invoice for editing.
  Future<void> loadExisting(int invoiceId) async {
    final invoice = await _repository.getById(invoiceId);
    if (invoice == null) return;

    emit(InvoiceState(
      editingInvoiceId: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      date: invoice.date,
      selectedCustomer: invoice.customerId != null
          ? CustomerModel(id: invoice.customerId, name: invoice.customerName ?? '')
          : null,
      status: invoice.status,
      items: invoice.items,
      notes: invoice.notes,
      overallDiscountType: invoice.overallDiscountType,
      overallDiscountValue: invoice.overallDiscountValue,
    ));
  }

  void setInvoiceNumber(String number) {
    emit(state.copyWith(invoiceNumber: number));
  }

  void setDate(String isoDate) {
    emit(state.copyWith(date: isoDate));
  }

  void setCustomer(CustomerModel? customer) {
    if (customer == null) {
      emit(state.copyWith(clearCustomer: true));
    } else {
      emit(state.copyWith(selectedCustomer: customer));
    }
  }

  void setStatus(String status) {
    emit(state.copyWith(status: status));
  }

  void setNotes(String notes) {
    emit(state.copyWith(notes: notes));
  }

  /// Set the invoice-level overall discount type.
  void setOverallDiscountType(String type) {
    emit(state.copyWith(
      overallDiscountType: type,
      overallDiscountValue: 0.0, // Reset value when type changes
    ));
  }

  /// Set the invoice-level overall discount value.
  void setOverallDiscountValue(double value) {
    emit(state.copyWith(overallDiscountValue: value));
  }

  /// Add a product as a new line item.
  void addItem(ProductModel product) {
    final item = InvoiceItemModel(
      productId: product.id,
      productName: product.name,
      unitPrice: product.effectivePrice,
      quantity: 1.0,
      discountType: 'none',
      discountValue: 0.0,
      discountCalculatedAmount: 0.0,
      lineTotal: product.effectivePrice,
    );
    emit(state.copyWith(items: [...state.items, item]));
  }

  /// Remove an item at index.
  void removeItem(int index) {
    final items = List<InvoiceItemModel>.from(state.items);
    items.removeAt(index);
    emit(state.copyWith(items: items));
  }

  /// Update quantity for item at index.
  void updateItemQuantity(int index, double quantity) {
    final items = List<InvoiceItemModel>.from(state.items);
    items[index] = items[index].copyWith(quantity: quantity).recalculate();
    emit(state.copyWith(items: items));
  }

  /// Update unit price for item at index.
  void updateItemPrice(int index, double price) {
    final items = List<InvoiceItemModel>.from(state.items);
    items[index] = items[index].copyWith(unitPrice: price).recalculate();
    emit(state.copyWith(items: items));
  }

  /// Update discount type for item at index.
  void updateItemDiscountType(int index, String type) {
    final items = List<InvoiceItemModel>.from(state.items);
    items[index] = items[index].copyWith(discountType: type, discountValue: 0).recalculate();
    emit(state.copyWith(items: items));
  }

  /// Update discount value for item at index.
  void updateItemDiscountValue(int index, double value) {
    final items = List<InvoiceItemModel>.from(state.items);
    items[index] = items[index].copyWith(discountValue: value).recalculate();
    emit(state.copyWith(items: items));
  }

  /// Save the invoice (insert or update).
  Future<void> save() async {
    if (state.items.isEmpty) {
      emit(state.copyWith(errorMessage: 'حداقل یک کالا باید به فاکتور اضافه شود'));
      return;
    }

    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final invoice = InvoiceModel(
        id: state.editingInvoiceId,
        invoiceNumber: state.invoiceNumber,
        customerId: state.selectedCustomer?.id,
        customerName: state.selectedCustomer?.name,
        date: state.date,
        status: state.status,
        totalGross: state.totalGross,
        totalDiscount: state.totalDiscount,
        totalNet: state.totalNet,
        overallDiscountType: state.overallDiscountType,
        overallDiscountValue: state.overallDiscountValue,
        overallDiscountAmount: state.overallDiscountAmount,
        notes: state.notes,
        items: state.items,
      );

      if (state.editingInvoiceId != null) {
        await _repository.update(invoice);
      } else {
        await _repository.insert(invoice);
      }

      emit(state.copyWith(isSaving: false, isSaved: true));
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  /// Load items from a preset template and add them to the current invoice.
  void loadFromTemplate(PresetTemplateModel template) {
    final newItems = template.items.map((ti) {
      return InvoiceItemModel(
        productId: ti.productId,
        productName: ti.productName,
        unitPrice: ti.unitPrice,
        quantity: ti.quantity,
        discountType: 'none',
        discountValue: 0.0,
        discountCalculatedAmount: 0.0,
        lineTotal: ti.unitPrice * ti.quantity,
      );
    }).toList();

    emit(state.copyWith(items: [...state.items, ...newItems]));
  }

  /// Save current invoice items as a preset template.
  Future<void> saveAsTemplate(String name) async {
    final templateItems = state.items.map((item) {
      return PresetTemplateItem(
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
      );
    }).toList();

    final template = PresetTemplateModel(
      name: name,
      items: templateItems,
    );

    await _templateRepo.insert(template);
  }

  /// Reset to a fresh new invoice.
  Future<void> reset() async {
    await initNew();
  }
}
