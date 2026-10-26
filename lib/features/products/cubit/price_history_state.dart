import 'package:equatable/equatable.dart';
import '../../../data/models/price_change_model.dart';

abstract class PriceHistoryState extends Equatable {
  const PriceHistoryState();

  @override
  List<Object?> get props => [];
}

class PriceHistoryInitial extends PriceHistoryState {}

class PriceHistoryLoading extends PriceHistoryState {}

class PriceHistoryLoaded extends PriceHistoryState {
  final List<PriceChangeModel> records;
  final int? filterProductId;
  final String? filterProductName;
  final String searchQuery;
  final String filterChangeType; // 'all' | 'manual' | 'batch_adjustment' | 'purchase'
  final String? dateFrom;
  final String? dateTo;
  final String sortColumn; // 'date' | 'name' | 'amount' | 'percent' | 'old_price' | 'new_price'
  final bool isAscending;

  const PriceHistoryLoaded({
    required this.records,
    this.filterProductId,
    this.filterProductName,
    this.searchQuery = '',
    this.filterChangeType = 'all',
    this.dateFrom,
    this.dateTo,
    this.sortColumn = 'date',
    this.isAscending = false,
  });

  /// Filtered and sorted list ready for UI rendering.
  List<PriceChangeModel> get sortedRecords {
    final list = List<PriceChangeModel>.from(records);

    list.sort((a, b) {
      int comparison = 0;
      switch (sortColumn) {
        case 'date':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'name':
          comparison = (a.productName ?? '').compareTo(b.productName ?? '');
          break;
        case 'amount':
          comparison = a.changeAmount.compareTo(b.changeAmount);
          break;
        case 'percent':
          comparison = a.changePercent.compareTo(b.changePercent);
          break;
        case 'old_price':
          comparison = a.oldPrice.compareTo(b.oldPrice);
          break;
        case 'new_price':
          comparison = a.newPrice.compareTo(b.newPrice);
          break;
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
      }
      return isAscending ? comparison : -comparison;
    });

    return list;
  }

  int get totalCount => records.length;

  double get averagePercent {
    if (records.isEmpty) return 0.0;
    final sum = records.fold<double>(0.0, (acc, r) => acc + r.changePercent);
    return sum / records.length;
  }

  double get maxIncreasePercent {
    if (records.isEmpty) return 0.0;
    return records.fold<double>(0.0, (m, r) => r.changePercent > m ? r.changePercent : m);
  }

  double get maxDecreasePercent {
    if (records.isEmpty) return 0.0;
    return records.fold<double>(0.0, (m, r) => r.changePercent < m ? r.changePercent : m);
  }

  PriceHistoryLoaded copyWith({
    List<PriceChangeModel>? records,
    int? filterProductId,
    bool clearProductId = false,
    String? filterProductName,
    bool clearProductName = false,
    String? searchQuery,
    String? filterChangeType,
    String? dateFrom,
    bool clearDateFrom = false,
    String? dateTo,
    bool clearDateTo = false,
    String? sortColumn,
    bool? isAscending,
  }) {
    return PriceHistoryLoaded(
      records: records ?? this.records,
      filterProductId: clearProductId ? null : (filterProductId ?? this.filterProductId),
      filterProductName: clearProductName ? null : (filterProductName ?? this.filterProductName),
      searchQuery: searchQuery ?? this.searchQuery,
      filterChangeType: filterChangeType ?? this.filterChangeType,
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      sortColumn: sortColumn ?? this.sortColumn,
      isAscending: isAscending ?? this.isAscending,
    );
  }

  @override
  List<Object?> get props => [
        records,
        filterProductId,
        filterProductName,
        searchQuery,
        filterChangeType,
        dateFrom,
        dateTo,
        sortColumn,
        isAscending,
      ];
}

class PriceHistoryError extends PriceHistoryState {
  final String message;

  const PriceHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
