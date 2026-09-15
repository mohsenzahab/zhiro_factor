import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/purchase_model.dart';
import '../../../data/repositories/purchase_repository.dart';

/// State for purchase history list.
class PurchaseHistoryState extends Equatable {
  final List<PurchaseModel> purchases;
  final bool isLoading;
  final String? error;

  const PurchaseHistoryState({
    this.purchases = const [],
    this.isLoading = false,
    this.error,
  });

  PurchaseHistoryState copyWith({
    List<PurchaseModel>? purchases,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PurchaseHistoryState(
      purchases: purchases ?? this.purchases,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [purchases, isLoading, error];
}

/// Cubit for loading and filtering purchase history.
class PurchaseHistoryCubit extends Cubit<PurchaseHistoryState> {
  final PurchaseRepository _repository = PurchaseRepository();

  PurchaseHistoryCubit() : super(const PurchaseHistoryState());

  /// Load all purchases with optional filters.
  Future<void> load({
    String? supplierQuery,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final purchases = await _repository.getAll(
        supplierQuery: supplierQuery,
        status: status,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      emit(state.copyWith(purchases: purchases, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Delete a purchase by ID and reload.
  Future<void> deletePurchase(int id) async {
    await _repository.delete(id);
    await load();
  }
}
