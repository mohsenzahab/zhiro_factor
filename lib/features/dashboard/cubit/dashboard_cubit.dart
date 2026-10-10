import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../shared/widgets/date_range_filter_bar.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final ReportRepository _repo = ReportRepository();
  final ProductRepository _productRepo = ProductRepository();

  DashboardCubit() : super(const DashboardState());

  Future<void> loadDashboard({
    String? dateFrom,
    String? dateTo,
    DateRangePreset? preset,
    bool isInitial = false,
  }) async {
    // If initial load and no dates given, default to thisMonth
    String? effectiveFrom = dateFrom;
    String? effectiveTo = dateTo;
    DateRangePreset effectivePreset = preset ?? state.preset;

    if (isInitial && effectiveFrom == null && effectiveTo == null) {
      final range = JalaliUtils.thisMonthRange;
      effectiveFrom = range.$1;
      effectiveTo = range.$2;
      effectivePreset = DateRangePreset.thisMonth;
    } else if (preset == DateRangePreset.allTime) {
      effectiveFrom = null;
      effectiveTo = null;
    }

    final category = state.categoryFilter;

    emit(state.copyWith(
      isLoading: true,
      dateFrom: effectiveFrom,
      dateTo: effectiveTo,
      clearDates: effectiveFrom == null && effectiveTo == null,
      preset: effectivePreset,
    ));

    try {
      final results = await Future.wait([
        _repo.totalGrossSales(dateFrom: effectiveFrom, dateTo: effectiveTo, category: category),
        _repo.totalNetProfit(dateFrom: effectiveFrom, dateTo: effectiveTo, category: category),
        _repo.totalDiscounts(dateFrom: effectiveFrom, dateTo: effectiveTo, category: category),
        _repo.pendingSummary(dateFrom: effectiveFrom, dateTo: effectiveTo, category: category),
        _repo.bestSellersByVolume(dateFrom: effectiveFrom, dateTo: effectiveTo, category: category),
        _repo.bestSellersByRevenue(dateFrom: effectiveFrom, dateTo: effectiveTo, category: category),
        _repo.recentInvoices(dateFrom: effectiveFrom, dateTo: effectiveTo, category: category),
        _repo.totalBuyCosts(dateFrom: effectiveFrom, dateTo: effectiveTo, category: category),
        _productRepo.getDistinctCategories(),
      ]);

      final pending = results[3] as Map<String, dynamic>;
      final buyCosts = results[7] as ({double initialCost, double currentCost});
      final categories = results[8] as List<String>;

      emit(state.copyWith(
        isLoading: false,
        totalGross: results[0] as double,
        totalProfit: results[1] as double,
        totalDiscounts: results[2] as double,
        pendingCount: pending['count'] as int,
        pendingAmount: pending['amount'] as double,
        bestSellersByVolume: results[4] as List<Map<String, dynamic>>,
        bestSellersByRevenue: results[5] as List<Map<String, dynamic>>,
        recentInvoices: results[6] as List<Map<String, dynamic>>,
        totalInitialBuyCost: buyCosts.initialCost,
        totalCurrentBuyCost: buyCosts.currentCost,
        availableCategories: categories,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void setCategoryFilter(String? category) {
    emit(state.copyWith(
      categoryFilter: category,
      clearCategory: category == null,
    ));
    loadDashboard(
      dateFrom: state.dateFrom,
      dateTo: state.dateTo,
      preset: state.preset,
    );
  }
}
