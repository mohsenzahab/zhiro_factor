import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/demand_model.dart';
import '../../../data/repositories/demand_repository.dart';
import '../../../data/repositories/product_repository.dart';
import 'demand_state.dart';

/// Cubit managing Demand list state and interactions.
class DemandCubit extends Cubit<DemandState> {
  final DemandRepository _repository;
  final ProductRepository _productRepo;

  DemandCubit({
    DemandRepository? repository,
    ProductRepository? productRepo,
  })  : _repository = repository ?? DemandRepository(),
        _productRepo = productRepo ?? ProductRepository(),
        super(const DemandState());

  /// Load all demands and categories based on current state filters.
  Future<void> loadDemands() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final results = await Future.wait([
        _repository.getAll(
          status: state.statusFilter,
          category: state.categoryFilter,
          query: state.searchQuery,
          sortBy: state.sortBy,
        ),
        _productRepo.getDistinctCategories(),
      ]);

      final demands = results[0] as List<DemandModel>;
      final categories = results[1] as List<String>;

      // Also gather any categories that exist in demands but not in products yet
      final demandCategories = demands
          .map((d) => d.category)
          .whereType<String>()
          .where((c) => c.trim().isNotEmpty)
          .toSet();
      final mergedCategories = {...categories, ...demandCategories}.toList()..sort();

      emit(state.copyWith(
        isLoading: false,
        demands: demands,
        availableCategories: mergedCategories,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در بارگذاری نیازمندی‌ها: $e',
      ));
    }
  }

  /// Change status filter ('تهیه نشده', 'در حال تهیه', 'تهیه شده' or null for all).
  void setStatusFilter(String? status) {
    if (status == state.statusFilter) return;
    emit(state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
    ));
    loadDemands();
  }

  /// Change category filter.
  void setCategoryFilter(String? category) {
    if (category == state.categoryFilter) return;
    emit(state.copyWith(
      categoryFilter: category,
      clearCategoryFilter: category == null,
    ));
    loadDemands();
  }

  /// Update search query.
  void setSearchQuery(String? query) {
    emit(state.copyWith(
      searchQuery: query,
      clearSearchQuery: query == null || query.isEmpty,
    ));
    loadDemands();
  }

  /// Update sort criteria.
  void setSortBy(String sortBy) {
    if (sortBy == state.sortBy) return;
    emit(state.copyWith(sortBy: sortBy));
    loadDemands();
  }

  /// Add a new demand item.
  Future<bool> addDemand(DemandModel demand, {int initialCount = 1, String? initialDate}) async {
    try {
      await _repository.insert(demand, initialCount: initialCount, initialDate: initialDate);
      await loadDemands();
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'خطا در افزودن نیازمندی: $e'));
      return false;
    }
  }

  /// Update an existing demand.
  Future<bool> updateDemand(DemandModel demand) async {
    try {
      await _repository.update(demand);
      await loadDemands();
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'خطا در ویرایش نیازمندی: $e'));
      return false;
    }
  }

  /// Delete a demand.
  Future<bool> deleteDemand(int id) async {
    try {
      await _repository.delete(id);
      await loadDemands();
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'خطا در حذف نیازمندی: $e'));
      return false;
    }
  }

  /// Increment customer request counter (+ button).
  Future<void> incrementRequest(int demandId, {String? requestDate}) async {
    try {
      await _repository.addRequest(demandId, requestDate: requestDate);
      await loadDemands();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'خطا در افزایش درخواست: $e'));
    }
  }

  /// Decrement customer request counter (- button).
  Future<bool> decrementRequest(int demandId) async {
    try {
      final success = await _repository.removeLatestRequest(demandId);
      if (success) {
        await loadDemands();
      }
      return success;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'خطا در کاهش درخواست: $e'));
      return false;
    }
  }

  /// Quick status update.
  Future<void> updateStatus(int demandId, String newStatus) async {
    try {
      await _repository.updateStatus(demandId, newStatus);
      await loadDemands();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'خطا در تغییر وضعیت: $e'));
    }
  }

  /// Convert a procured demand into an official Product in inventory.
  Future<int?> convertToProduct(DemandModel demand) async {
    try {
      final productId = await _repository.convertToProduct(demand);
      await loadDemands();
      return productId;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'خطا در تبدیل به کالا: $e'));
      return null;
    }
  }
}
