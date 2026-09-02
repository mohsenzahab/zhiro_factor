import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/report_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final ReportRepository _repo = ReportRepository();

  DashboardCubit() : super(const DashboardState());

  Future<void> loadDashboard() async {
    emit(state.copyWith(isLoading: true));
    try {
      final results = await Future.wait([
        _repo.totalGrossSales(),
        _repo.totalNetRevenue(),
        _repo.totalDiscounts(),
        _repo.outstandingCount(),
        _repo.bestSellersByVolume(),
        _repo.bestSellersByRevenue(),
        _repo.recentInvoices(),
      ]);

      emit(DashboardState(
        isLoading: false,
        totalGross: results[0] as double,
        totalNet: results[1] as double,
        totalDiscounts: results[2] as double,
        outstandingCount: results[3] as int,
        bestSellersByVolume: results[4] as List<Map<String, dynamic>>,
        bestSellersByRevenue: results[5] as List<Map<String, dynamic>>,
        recentInvoices: results[6] as List<Map<String, dynamic>>,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }
}
