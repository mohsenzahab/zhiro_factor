import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../shared/widgets/date_range_filter_bar.dart';
import 'report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  final ReportRepository _repo = ReportRepository();

  ReportCubit() : super(const ReportState());

  Future<void> loadLedger({
    String? dateFrom,
    String? dateTo,
    DateRangePreset? preset,
    String? status,
    bool isInitial = false,
  }) async {
    String? effectiveFrom = dateFrom ?? state.dateFrom;
    String? effectiveTo = dateTo ?? state.dateTo;
    DateRangePreset effectivePreset = preset ?? state.preset;
    String? effectiveStatus = status ?? state.status;

    if (isInitial && dateFrom == null && dateTo == null) {
      final range = JalaliUtils.thisMonthRange;
      effectiveFrom = range.$1;
      effectiveTo = range.$2;
      effectivePreset = DateRangePreset.thisMonth;
    } else if (preset == DateRangePreset.allTime) {
      effectiveFrom = null;
      effectiveTo = null;
    }

    emit(state.copyWith(
      isLoading: true,
      dateFrom: effectiveFrom,
      dateTo: effectiveTo,
      clearDates: effectiveFrom == null && effectiveTo == null,
      preset: effectivePreset,
      status: effectiveStatus,
    ));

    try {
      final results = await Future.wait([
        _repo.salesLedger(
          dateFrom: effectiveFrom,
          dateTo: effectiveTo,
          status: effectiveStatus,
        ),
        _repo.ledgerSummary(
          dateFrom: effectiveFrom,
          dateTo: effectiveTo,
          status: effectiveStatus,
        ),
      ]);

      final ledger = results[0] as List<Map<String, dynamic>>;
      final summary = results[1] as Map<String, dynamic>;

      emit(state.copyWith(
        isLoading: false,
        ledgerData: ledger,
        itemsCount: summary['items_count'] as int,
        totalQuantity: summary['total_quantity'] as double,
        totalSales: summary['total_sales'] as double,
        totalDiscount: summary['total_discount'] as double,
        totalProfit: summary['total_profit'] as double,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void setStatus(String? status) {
    loadLedger(status: status);
  }
}
