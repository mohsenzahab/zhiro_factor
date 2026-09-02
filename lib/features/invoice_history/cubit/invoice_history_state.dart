import 'package:equatable/equatable.dart';
import '../../../data/models/invoice_model.dart';

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

  const InvoiceHistoryLoaded({
    required this.invoices,
    this.statusFilter,
    this.customerQuery,
  });

  @override
  List<Object?> get props => [invoices, statusFilter, customerQuery];
}

class InvoiceHistoryError extends InvoiceHistoryState {
  final String message;
  const InvoiceHistoryError(this.message);
  @override
  List<Object?> get props => [message];
}
