import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/supplier_model.dart';
import '../../../data/repositories/supplier_repository.dart';
import 'supplier_state.dart';

class SupplierCubit extends Cubit<SupplierState> {
  final SupplierRepository _repository = SupplierRepository();

  SupplierCubit() : super(SupplierLoading());

  Future<void> loadSuppliers({String? query}) async {
    emit(SupplierLoading());
    try {
      final suppliers = await _repository.getAll(query: query);
      emit(SupplierLoaded(suppliers));
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> addSupplier(SupplierModel supplier) async {
    try {
      await _repository.insert(supplier);
      await loadSuppliers();
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> updateSupplier(SupplierModel supplier) async {
    try {
      await _repository.update(supplier);
      await loadSuppliers();
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      await _repository.delete(id);
      await loadSuppliers();
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }
}
