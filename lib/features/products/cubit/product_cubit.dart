import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repository;

  ProductCubit({ProductRepository? repository})
      : _repository = repository ?? ProductRepository(),
        super(ProductInitial());

  String? _getCurrentQuery() {
    if (state is ProductLoaded) {
      final q = (state as ProductLoaded).searchQuery.trim();
      if (q.isNotEmpty) return q;
    }
    return null;
  }

  Future<void> loadProducts({String? query, bool? silent}) async {
    final shouldBeSilent = silent ?? (state is ProductLoaded);
    if (!shouldBeSilent) {
      emit(ProductLoading());
    }
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
      final currentQuery = _getCurrentQuery();
      final products = await _repository.getAll(query: currentQuery);
      emit(ProductLoaded(products: products, searchQuery: currentQuery ?? ''));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      await _repository.update(product);
      final currentQuery = _getCurrentQuery();
      final products = await _repository.getAll(query: currentQuery);
      emit(ProductLoaded(products: products, searchQuery: currentQuery ?? ''));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _repository.delete(id);
      final currentQuery = _getCurrentQuery();
      final products = await _repository.getAll(query: currentQuery);
      emit(ProductLoaded(products: products, searchQuery: currentQuery ?? ''));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  /// Batch delete multiple products by IDs.
  Future<int> deleteProducts(List<int> ids) async {
    try {
      final count = await _repository.deleteMany(ids);
      final currentQuery = _getCurrentQuery();
      final products = await _repository.getAll(query: currentQuery);
      emit(ProductLoaded(products: products, searchQuery: currentQuery ?? ''));
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
      final currentQuery = _getCurrentQuery();
      final products = await _repository.getAll(query: currentQuery);
      emit(ProductLoaded(products: products, searchQuery: currentQuery ?? ''));
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
      final currentQuery = _getCurrentQuery();
      final products = await _repository.getAll(query: currentQuery);
      emit(ProductLoaded(products: products, searchQuery: currentQuery ?? ''));
      return updatedCount;
    } catch (e) {
      emit(ProductError(e.toString()));
      return 0;
    }
  }
}
