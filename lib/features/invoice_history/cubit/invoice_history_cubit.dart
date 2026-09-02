import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/invoice_repository.dart';
import 'invoice_history_state.dart';

class InvoiceHistoryCubit extends Cubit<InvoiceHistoryState> {
  final InvoiceRepository _repository = InvoiceRepository();

  String? _statusFilter;
  String? _customerQuery;
  String? _dateFrom;
  String? _dateTo;

  InvoiceHistoryCubit() : super(InvoiceHistoryInitial());

  Future<void> loadInvoices() async {
    emit(InvoiceHistoryLoading());
    try {
      final invoices = await _repository.getAll(
        status: _statusFilter,
        customerQuery: _customerQuery,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );
      emit(InvoiceHistoryLoaded(
        invoices: invoices,
        statusFilter: _statusFilter,
        customerQuery: _customerQuery,
      ));
    } catch (e) {
      emit(InvoiceHistoryError(e.toString()));
    }
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    loadInvoices();
  }

  void setCustomerQuery(String? query) {
    _customerQuery = query;
    loadInvoices();
  }

  void setDateRange(String? from, String? to) {
    _dateFrom = from;
    _dateTo = to;
    loadInvoices();
  }

  Future<void> deleteInvoice(int id) async {
    try {
      await _repository.delete(id);
      await loadInvoices();
    } catch (e) {
      emit(InvoiceHistoryError(e.toString()));
    }
  }
}
