import 'package:equatable/equatable.dart';
import '../../../data/models/demand_model.dart';

/// State for the Demand management feature.
class DemandState extends Equatable {
  final bool isLoading;
  final List<DemandModel> demands;
  final List<String> availableCategories;
  final String? statusFilter;
  final String? categoryFilter;
  final String? searchQuery;
  final String sortBy;
  final String? errorMessage;

  const DemandState({
    this.isLoading = false,
    this.demands = const [],
    this.availableCategories = const [],
    this.statusFilter,
    this.categoryFilter,
    this.searchQuery,
    this.sortBy = 'demandCount',
    this.errorMessage,
  });

  /// Total count of demands matching current filters.
  int get totalDemandsCount => demands.length;

  /// Total customer request events across all filtered demands.
  int get totalRequestsCount => demands.fold(0, (sum, d) => sum + d.requestCount);

  /// Items that are pending or in preparation ('تهیه نشده' یا 'در حال تهیه').
  List<DemandModel> get activeDemands =>
      demands.where((d) => d.status != DemandModel.statusProcured).toList();

  /// Total required capital for all active demands (تهیه نشده و در حال تهیه).
  double get totalRequiredCapital =>
      activeDemands.fold(0.0, (sum, d) => sum + d.requiredCapital);

  /// Total projected profit for all active demands (تهیه نشده و در حال تهیه).
  double get totalProjectedProfit =>
      activeDemands.fold(0.0, (sum, d) => sum + (d.totalProjectedProfit ?? 0.0));

  /// Most requested demand item.
  DemandModel? get topDemandedItem {
    if (demands.isEmpty) return null;
    return demands.reduce((curr, next) => curr.requestCount >= next.requestCount ? curr : next);
  }

  /// Counts by status.
  int get pendingCount => demands.where((d) => d.status == DemandModel.statusPending).length;
  int get inPreparationCount => demands.where((d) => d.status == DemandModel.statusInPreparation).length;
  int get procuredCount => demands.where((d) => d.status == DemandModel.statusProcured).length;

  DemandState copyWith({
    bool? isLoading,
    List<DemandModel>? demands,
    List<String>? availableCategories,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? categoryFilter,
    bool clearCategoryFilter = false,
    String? searchQuery,
    bool clearSearchQuery = false,
    String? sortBy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DemandState(
      isLoading: isLoading ?? this.isLoading,
      demands: demands ?? this.demands,
      availableCategories: availableCategories ?? this.availableCategories,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      categoryFilter: clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      sortBy: sortBy ?? this.sortBy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        demands,
        availableCategories,
        statusFilter,
        categoryFilter,
        searchQuery,
        sortBy,
        errorMessage,
      ];
}
