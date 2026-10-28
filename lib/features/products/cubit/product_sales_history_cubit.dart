import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../shared/widgets/date_range_filter_bar.dart';
import 'product_sales_history_state.dart';

/// Cubit managing loading and filtering of sales records for a specific product.
class ProductSalesHistoryCubit extends Cubit<ProductSalesHistoryState> {
  final int productId;
  final InvoiceRepository _invoiceRepo;
  final ProductRepository _productRepo;

  ProductSalesHistoryCubit({
    required this.productId,
    InvoiceRepository? invoiceRepo,
    ProductRepository? productRepo,
  })  : _invoiceRepo = invoiceRepo ?? InvoiceRepository(),
        _productRepo = productRepo ?? ProductRepository(),
        super(const ProductSalesHistoryState());

  /// Load product info and sales records with optional filters.
  Future<void> load({
    DateRangePreset? preset,
    String? dateFrom,
    String? dateTo,
    String? status,
    String? query,
    bool forceReloadProduct = false,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      ProductModel? product = state.product;
      if (product == null || forceReloadProduct) {
        product = await _productRepo.getById(productId);
      }

      final effectivePreset = preset ?? state.preset;
      final effectiveDateFrom = dateFrom ?? (preset != null ? null : state.dateFrom);
      final effectiveDateTo = dateTo ?? (preset != null ? null : state.dateTo);
      final effectiveStatus = status ?? state.statusFilter;
      final effectiveQuery = query ?? state.searchQuery;

      final sales = await _invoiceRepo.getProductSales(
        productId,
        dateFrom: effectiveDateFrom,
        dateTo: effectiveDateTo,
        status: effectiveStatus,
        query: effectiveQuery,
      );

      emit(state.copyWith(
        product: product,
        sales: sales,
        isLoading: false,
        preset: effectivePreset,
        dateFrom: effectiveDateFrom,
        dateTo: effectiveDateTo,
        clearDateFrom: effectiveDateFrom == null,
        clearDateTo: effectiveDateTo == null,
        statusFilter: effectiveStatus,
        clearStatusFilter: effectiveStatus == null,
        searchQuery: effectiveQuery,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Change date range filter.
  Future<void> setDateRange({
    required DateRangePreset preset,
    String? dateFrom,
    String? dateTo,
  }) async {
    await load(
      preset: preset,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  /// Change status filter (e.g. 'تسویه شده', 'در انتظار پرداخت', etc., or null for all).
  Future<void> setStatusFilter(String? status) async {
    await load(status: status);
  }

  /// Change search query.
  Future<void> setSearchQuery(String query) async {
    await load(query: query);
  }

  /// Refresh both product details and sales.
  Future<void> refresh() async {
    await load(forceReloadProduct: true);
  }
}

