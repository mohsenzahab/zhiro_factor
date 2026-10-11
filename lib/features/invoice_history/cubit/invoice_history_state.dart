import 'package:equatable/equatable.dart';
import '../../../data/models/invoice_model.dart';
import '../../../shared/widgets/date_range_filter_bar.dart';

abstract class InvoiceHistoryState extends Equatable {
  const InvoiceHistoryState();
  @override
  List<Object?> get props => [];
}

class InvoiceHistoryInitial extends InvoiceHistoryState {}

class InvoiceHistoryLoading extends InvoiceHistoryState {}

class InvoiceHistoryLoaded extends InvoiceHistoryState {
  final List<InvoiceModel> invoices;
  final String? statusFilter;
  final String? customerQuery;
  final String? productQuery;
  final DateRangePreset? preset;
  final String? dateFrom;
  final String? dateTo;
  final String? categoryFilter;
  final List<String> availableCategories;

  DateRangePreset get effectivePreset => preset ?? DateRangePreset.thisMonth;

  const InvoiceHistoryLoaded({
    required this.invoices,
    this.statusFilter,
    this.customerQuery,
    this.productQuery,
    this.preset = DateRangePreset.thisMonth,
    this.dateFrom,
    this.dateTo,
    this.categoryFilter,
    this.availableCategories = const [],
  });

  @override
  List<Object?> get props => [
        invoices,
        statusFilter,
        customerQuery,
        productQuery,
        preset,
        dateFrom,
        dateTo,
        categoryFilter,
        availableCategories,
      ];
}

class InvoiceHistoryError extends InvoiceHistoryState {
  final String message;
  const InvoiceHistoryError(this.message);
  @override
  List<Object?> get props => [message];
}
