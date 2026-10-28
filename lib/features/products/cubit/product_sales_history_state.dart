import 'package:equatable/equatable.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/product_sale_record.dart';
import '../../../shared/widgets/date_range_filter_bar.dart';

/// State for the product sales history screen.
class ProductSalesHistoryState extends Equatable {
  final ProductModel? product;
  final List<ProductSaleRecord> sales;
  final bool isLoading;
  final String? error;
  final DateRangePreset preset;
  final String? dateFrom;
  final String? dateTo;
  final String? statusFilter;
  final String searchQuery;

  const ProductSalesHistoryState({
    this.product,
    this.sales = const [],
    this.isLoading = false,
    this.error,
    this.preset = DateRangePreset.allTime,
    this.dateFrom,
    this.dateTo,
    this.statusFilter,
    this.searchQuery = '',
  });

  /// Total quantity of this product sold in the filtered period.
  double get filteredTotalQuantity =>
      sales.fold(0.0, (sum, s) => sum + s.quantity);

  /// Total sales revenue in the filtered period.
  double get filteredTotalSales =>
      sales.fold(0.0, (sum, s) => sum + s.lineTotal);

  /// Total gross discount given on this product in the filtered period.
  double get filteredTotalDiscount =>
      sales.fold(0.0, (sum, s) => sum + s.discountCalculatedAmount);

  /// Total net profit earned on this product in the filtered period.
  double get filteredTotalProfit =>
      sales.fold(0.0, (sum, s) => sum + s.profitAmount);

  /// Number of distinct invoices represented in filtered sales.
  int get filteredInvoiceCount =>
      sales.map((s) => s.invoiceId).toSet().length;

  ProductSalesHistoryState copyWith({
    ProductModel? product,
    List<ProductSaleRecord>? sales,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateRangePreset? preset,
    String? dateFrom,
    bool clearDateFrom = false,
    String? dateTo,
    bool clearDateTo = false,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
  }) {
    return ProductSalesHistoryState(
      product: product ?? this.product,
      sales: sales ?? this.sales,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      preset: preset ?? this.preset,
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        product,
        sales,
        isLoading,
        error,
        preset,
        dateFrom,
        dateTo,
        statusFilter,
        searchQuery,
      ];
}

