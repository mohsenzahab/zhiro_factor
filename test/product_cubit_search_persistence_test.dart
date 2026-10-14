import 'package:flutter_test/flutter_test.dart';
import 'package:sales_box/data/models/product_model.dart';
import 'package:sales_box/data/repositories/product_repository.dart';
import 'package:sales_box/features/products/cubit/product_cubit.dart';
import 'package:sales_box/features/products/cubit/product_state.dart';

class FakeProductRepository extends ProductRepository {
  List<ProductModel> items = [];

  FakeProductRepository(List<ProductModel> initial) : items = List.from(initial);

  @override
  Future<List<ProductModel>> getAll({String? query}) async {
    if (query != null && query.isNotEmpty) {
      return items.where((p) => p.name.contains(query)).toList();
    }
    return List.from(items);
  }

  @override
  Future<int> insert(ProductModel product) async {
    items.add(product);
    return product.id ?? 1;
  }

  @override
  Future<int> update(ProductModel product) async {
    final idx = items.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      items[idx] = product;
    } else {
      items.add(product);
    }
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    items.removeWhere((p) => p.id == id);
    return 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final initialProducts = [
    ProductModel(id: 1, name: 'روغن موتور کاسترول', buyPrice: 200000, sellPrice: 240000, unit: 'لیتر'),
    ProductModel(id: 2, name: 'روغن گیربکس', buyPrice: 150000, sellPrice: 180000, unit: 'لیتر'),
    ProductModel(id: 3, name: 'فیلتر هوا', buyPrice: 50000, sellPrice: 65000, unit: 'عدد'),
    ProductModel(id: 4, name: 'فیلتر روغن', buyPrice: 60000, sellPrice: 75000, unit: 'عدد'),
  ];

  group('ProductCubit Search & State Persistence Tests', () {
    test('Initial load emits ProductLoading then ProductLoaded', () async {
      final fakeRepo = FakeProductRepository(initialProducts);
      final cubit = ProductCubit(repository: fakeRepo);
      expect(cubit.state, isA<ProductInitial>());

      final states = <ProductState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadProducts();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, greaterThanOrEqualTo(2));
      expect(states.first, isA<ProductLoading>());
      expect(states.last, isA<ProductLoaded>());
      expect((states.last as ProductLoaded).products.length, equals(4));

      await sub.cancel();
      await cubit.close();
    });

    test('updateProduct preserves searchQuery and does NOT emit ProductLoading', () async {
      final fakeRepo = FakeProductRepository(initialProducts);
      final cubit = ProductCubit(repository: fakeRepo);

      // Search for 'روغن' (matches 3 items: روغن موتور کاسترول, روغن گیربکس, فیلتر روغن)
      await cubit.loadProducts(query: 'روغن');
      expect(cubit.state, isA<ProductLoaded>());
      final loadedWithSearch = cubit.state as ProductLoaded;
      expect(loadedWithSearch.searchQuery, equals('روغن'));
      expect(loadedWithSearch.products.length, equals(3));

      // Monitor states during update
      final states = <ProductState>[];
      final sub = cubit.stream.listen(states.add);

      // Edit item #1 (change price)
      final updatedProduct = initialProducts[0].copyWith(sellPrice: 270000);
      await cubit.updateProduct(updatedProduct);
      await Future.delayed(const Duration(milliseconds: 20));

      // Must NOT emit ProductLoading!
      expect(states.any((s) => s is ProductLoading), isFalse);

      // Must still be ProductLoaded with searchQuery 'روغن' and only 3 matching items
      expect(cubit.state, isA<ProductLoaded>());
      final finalLoaded = cubit.state as ProductLoaded;
      expect(finalLoaded.searchQuery, equals('روغن'));
      expect(finalLoaded.products.length, equals(3));
      expect(finalLoaded.products.firstWhere((p) => p.id == 1).sellPrice, equals(270000));

      await sub.cancel();
      await cubit.close();
    });

    test('addProduct and deleteProduct also preserve active searchQuery', () async {
      final fakeRepo = FakeProductRepository(initialProducts);
      final cubit = ProductCubit(repository: fakeRepo);

      await cubit.loadProducts(query: 'فیلتر');
      expect((cubit.state as ProductLoaded).searchQuery, equals('فیلتر'));
      expect((cubit.state as ProductLoaded).products.length, equals(2));

      // Add another filter
      final newFilter = ProductModel(id: 5, name: 'فیلتر کابین', buyPrice: 40000, sellPrice: 55000, unit: 'عدد');
      await cubit.addProduct(newFilter);
      await Future.delayed(const Duration(milliseconds: 20));

      // Still filtered by 'فیلتر' (now 3 matching items)
      expect((cubit.state as ProductLoaded).searchQuery, equals('فیلتر'));
      expect((cubit.state as ProductLoaded).products.length, equals(3));

      // Delete item 3
      await cubit.deleteProduct(3);
      await Future.delayed(const Duration(milliseconds: 20));

      expect((cubit.state as ProductLoaded).searchQuery, equals('فیلتر'));
      expect((cubit.state as ProductLoaded).products.length, equals(2));

      await cubit.close();
    });
  });
}
