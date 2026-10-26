import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/price_change_repository.dart';
import 'price_history_state.dart';

class PriceHistoryCubit extends Cubit<PriceHistoryState> {
  final PriceChangeRepository _repository;

  PriceHistoryCubit({PriceChangeRepository? repository})
      : _repository = repository ?? PriceChangeRepository(),
        super(PriceHistoryInitial());

  Future<void> loadHistory({
    int? productId,
    String? productName,
    String? searchQuery,
    String? changeType,
    String? dateFrom,
    String? dateTo,
  }) async {
    emit(PriceHistoryLoading());
    try {
      final records = await _repository.getAll(
        productId: productId,
        query: searchQuery,
        changeType: changeType,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

      emit(PriceHistoryLoaded(
        records: records,
        filterProductId: productId,
        filterProductName: productName,
        searchQuery: searchQuery ?? '',
        filterChangeType: changeType ?? 'all',
        dateFrom: dateFrom,
        dateTo: dateTo,
      ));
    } catch (e) {
      emit(PriceHistoryError(e.toString()));
    }
  }

  Future<void> filter({
    String? searchQuery,
    String? changeType,
    String? dateFrom,
    String? dateTo,
    bool clearDates = false,
  }) async {
    final currentState = state;
    int? prodId;
    String? prodName;
    String curQuery = '';
    String curType = 'all';
    String? curDateFrom;
    String? curDateTo;
    String sortCol = 'date';
    bool isAsc = false;

    if (currentState is PriceHistoryLoaded) {
      prodId = currentState.filterProductId;
      prodName = currentState.filterProductName;
      curQuery = searchQuery ?? currentState.searchQuery;
      curType = changeType ?? currentState.filterChangeType;
      curDateFrom = clearDates ? null : (dateFrom ?? currentState.dateFrom);
      curDateTo = clearDates ? null : (dateTo ?? currentState.dateTo);
      sortCol = currentState.sortColumn;
      isAsc = currentState.isAscending;
    } else {
      curQuery = searchQuery ?? '';
      curType = changeType ?? 'all';
      curDateFrom = clearDates ? null : dateFrom;
      curDateTo = clearDates ? null : dateTo;
    }

    try {
      final records = await _repository.getAll(
        productId: prodId,
        query: curQuery,
        changeType: curType,
        dateFrom: curDateFrom,
        dateTo: curDateTo,
      );

      emit(PriceHistoryLoaded(
        records: records,
        filterProductId: prodId,
        filterProductName: prodName,
        searchQuery: curQuery,
        filterChangeType: curType,
        dateFrom: curDateFrom,
        dateTo: curDateTo,
        sortColumn: sortCol,
        isAscending: isAsc,
      ));
    } catch (e) {
      emit(PriceHistoryError(e.toString()));
    }
  }

  Future<void> clearProductFilter() async {
    if (state is! PriceHistoryLoaded) return;
    final curr = state as PriceHistoryLoaded;
    await loadHistory(
      productId: null,
      productName: null,
      searchQuery: curr.searchQuery,
      changeType: curr.filterChangeType,
      dateFrom: curr.dateFrom,
      dateTo: curr.dateTo,
    );
  }

  void setSorting(String column) {
    if (state is! PriceHistoryLoaded) return;
    final curr = state as PriceHistoryLoaded;
    if (curr.sortColumn == column) {
      emit(curr.copyWith(isAscending: !curr.isAscending));
    } else {
      emit(curr.copyWith(sortColumn: column, isAscending: false));
    }
  }

  Future<void> refresh() async {
    if (state is PriceHistoryLoaded) {
      final curr = state as PriceHistoryLoaded;
      await loadHistory(
        productId: curr.filterProductId,
        productName: curr.filterProductName,
        searchQuery: curr.searchQuery,
        changeType: curr.filterChangeType,
        dateFrom: curr.dateFrom,
        dateTo: curr.dateTo,
      );
    } else {
      await loadHistory();
    }
  }
}
