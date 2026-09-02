import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repository = ProductRepository();

  ProductCubit() : super(ProductInitial());

  Future<void> loadProducts({String? query}) async {
    emit(ProductLoading());
    try {
      final products = await _repository.getAll(query: query);
      emit(ProductLoaded(products: products, searchQuery: query ?? ''));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      await _repository.insert(product);
      await loadProducts();
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      await _repository.update(product);
      await loadProducts();
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _repository.delete(id);
      await loadProducts();
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<String> getNextCode() async {
    return await _repository.nextCode();
  }
}
