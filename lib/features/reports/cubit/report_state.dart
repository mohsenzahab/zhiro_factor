import 'package:equatable/equatable.dart';
import '../../../shared/widgets/date_range_filter_bar.dart';

class ReportState extends Equatable {
  final bool isLoading;
  final List<Map<String, dynamic>> ledgerData;
  final String? dateFrom;
  final String? dateTo;
  final DateRangePreset preset;
  final String? status;
  final double totalSales;
  final double totalProfit;
  final double totalDiscount;
  final double totalQuantity;
  final int itemsCount;

  const ReportState({
    this.isLoading = false,
    this.ledgerData = const [],
    this.dateFrom,
    this.dateTo,
    this.preset = DateRangePreset.thisMonth,
    this.status,
    this.totalSales = 0,
    this.totalProfit = 0,
    this.totalDiscount = 0,
    this.totalQuantity = 0,
    this.itemsCount = 0,
  });

  ReportState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? ledgerData,
    String? dateFrom,
    String? dateTo,
    bool clearDates = false,
    DateRangePreset? preset,
    String? status,
    bool clearStatus = false,
    double? totalSales,
    double? totalProfit,
    double? totalDiscount,
    double? totalQuantity,
    int? itemsCount,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      ledgerData: ledgerData ?? this.ledgerData,
      dateFrom: clearDates ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDates ? null : (dateTo ?? this.dateTo),
      preset: preset ?? this.preset,
      status: clearStatus ? null : (status ?? this.status),
      totalSales: totalSales ?? this.totalSales,
      totalProfit: totalProfit ?? this.totalProfit,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      itemsCount: itemsCount ?? this.itemsCount,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        ledgerData,
        dateFrom,
        dateTo,
        preset,
        status,
        totalSales,
        totalProfit,
        totalDiscount,
        totalQuantity,
        itemsCount,
      ];
}
