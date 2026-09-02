import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/report_repository.dart';
import 'report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  final ReportRepository _repo = ReportRepository();

  ReportCubit() : super(const ReportState());

  Future<void> loadLedger({String? dateFrom, String? dateTo}) async {
    emit(state.copyWith(isLoading: true, dateFrom: dateFrom, dateTo: dateTo));
    try {
      final data = await _repo.salesLedger(dateFrom: dateFrom, dateTo: dateTo);
      emit(state.copyWith(isLoading: false, ledgerData: data));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }
}
