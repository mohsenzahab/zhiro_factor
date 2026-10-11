import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../shared/widgets/date_range_filter_bar.dart';
import 'invoice_history_state.dart';

class InvoiceHistoryCubit extends Cubit<InvoiceHistoryState> {
  final InvoiceRepository _repository;
  final ProductRepository _productRepo;
  final SettingsRepository _settingsRepo;

  String? _statusFilter;
  String? _customerQuery;
  String? _productQuery;
  String? _dateFrom;
  String? _dateTo;
  DateRangePreset _preset = DateRangePreset.thisMonth;
  String? _categoryFilter;
  List<String> _availableCategories = [];

  InvoiceHistoryCubit({
    InvoiceRepository? repository,
    ProductRepository? productRepo,
    SettingsRepository? settingsRepo,
  })  : _repository = repository ?? InvoiceRepository(),
        _productRepo = productRepo ?? ProductRepository(),
        _settingsRepo = settingsRepo ?? SettingsRepository.instance,
        super(InvoiceHistoryInitial());

  Future<void> loadInvoices({bool isInitial = false}) async {
    emit(InvoiceHistoryLoading());

    if (isInitial) {
      final saved = await _settingsRepo.loadInvoiceHistoryFilter();
      _preset = saved.preset;
      _categoryFilter = saved.category;

      switch (_preset) {
        case DateRangePreset.allTime:
          _dateFrom = null;
          _dateTo = null;
          break;
        case DateRangePreset.today:
          final range = JalaliUtils.todayRange;
          _dateFrom = range.$1;
          _dateTo = range.$2;
          break;
        case DateRangePreset.thisWeek:
          final range = JalaliUtils.thisWeekRange;
          _dateFrom = range.$1;
          _dateTo = range.$2;
          break;
        case DateRangePreset.thisMonth:
          final range = JalaliUtils.thisMonthRange;
          _dateFrom = range.$1;
          _dateTo = range.$2;
          break;
        case DateRangePreset.custom:
          _dateFrom = saved.customDateFrom;
          _dateTo = saved.customDateTo;
          break;
      }
    } else {
      await _settingsRepo.saveInvoiceHistoryFilter(
        preset: _preset,
        customDateFrom: _preset == DateRangePreset.custom ? _dateFrom : null,
        customDateTo: _preset == DateRangePreset.custom ? _dateTo : null,
        category: _categoryFilter,
      );
    }

    try {
      final results = await Future.wait([
        _repository.getAll(
          status: _statusFilter,
          customerQuery: _customerQuery,
          productQuery: _productQuery,
          category: _categoryFilter,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
        ),
        _productRepo.getDistinctCategories(),
      ]);

      final invoices = results[0] as List<InvoiceModel>;
      _availableCategories = results[1] as List<String>;

      emit(InvoiceHistoryLoaded(
        invoices: invoices,
        statusFilter: _statusFilter,
        customerQuery: _customerQuery,
        productQuery: _productQuery,
        preset: _preset,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        categoryFilter: _categoryFilter,
        availableCategories: _availableCategories,
      ));
    } catch (e) {
      emit(InvoiceHistoryError(e.toString()));
    }
  }

  void setDateRangeFilter({
    required DateRangePreset preset,
    String? dateFrom,
    String? dateTo,
  }) {
    _preset = preset;
    _dateFrom = dateFrom;
    _dateTo = dateTo;
    loadInvoices();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    loadInvoices();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    loadInvoices();
  }

  void setCustomerQuery(String? query) {
    _customerQuery = query;
    loadInvoices();
  }

  void setProductQuery(String? query) {
    _productQuery = query;
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
