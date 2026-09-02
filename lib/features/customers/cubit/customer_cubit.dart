import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repositories/customer_repository.dart';
import 'customer_state.dart';

class CustomerCubit extends Cubit<CustomerState> {
  final CustomerRepository _repository = CustomerRepository();

  CustomerCubit() : super(CustomerInitial());

  Future<void> loadCustomers({String? query}) async {
    emit(CustomerLoading());
    try {
      final customers = await _repository.getAll(query: query);
      emit(CustomerLoaded(customers: customers, searchQuery: query ?? ''));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> addCustomer(CustomerModel customer) async {
    try {
      await _repository.insert(customer);
      await loadCustomers();
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      await _repository.update(customer);
      await loadCustomers();
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      await _repository.delete(id);
      await loadCustomers();
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<String> getNextCode() async {
    return await _repository.nextCode();
  }
}
