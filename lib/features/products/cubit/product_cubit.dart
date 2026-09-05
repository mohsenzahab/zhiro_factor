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
      final currentQuery = state is ProductLoaded ? (state as ProductLoaded).searchQuery : null;
      await loadProducts(query: currentQuery);
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  /// Batch delete multiple products by IDs.
  Future<int> deleteProducts(List<int> ids) async {
    try {
      final count = await _repository.deleteMany(ids);
      final currentQuery = state is ProductLoaded ? (state as ProductLoaded).searchQuery : null;
      await loadProducts(query: currentQuery);
      return count;
    } catch (e) {
      emit(ProductError(e.toString()));
      return 0;
    }
  }

  /// Move multiple products to a target category.
  Future<int> moveProductsCategory(List<int> ids, String? newCategory) async {
    try {
      final count = await _repository.updateCategoryForIds(ids, newCategory);
      final currentQuery = state is ProductLoaded ? (state as ProductLoaded).searchQuery : null;
      await loadProducts(query: currentQuery);
      return count;
    } catch (e) {
      emit(ProductError(e.toString()));
      return 0;
    }
  }

  Future<String> getNextCode() async {
    return await _repository.nextCode();
  }

  /// Apply profit margin percentage to products' sell prices.
  /// If [productIds] is provided, only updates those specific products.
  /// Otherwise filters by [category] if provided, or all products if null.
  Future<int> applyProfitMargin(
    double percentage, {
    String? category,
    List<int>? productIds,
  }) async {
    try {
      final updatedCount = await _repository.bulkApplyProfitMargin(
        percentage,
        category: category,
        productIds: productIds,
      );
      final currentQuery = state is ProductLoaded ? (state as ProductLoaded).searchQuery : null;
      await loadProducts(query: currentQuery);
      return updatedCount;
    } catch (e) {
      emit(ProductError(e.toString()));
      return 0;
    }
  }
}
