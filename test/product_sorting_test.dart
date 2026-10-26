import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_box/core/constants/app_strings.dart';
import 'package:sales_box/data/models/product_model.dart';
import 'package:sales_box/data/repositories/product_repository.dart';
import 'package:sales_box/features/products/cubit/product_cubit.dart';
import 'package:sales_box/features/products/view/products_page.dart';

class _FakeProductRepoForSortTest extends ProductRepository {
  final List<ProductModel> items;

  _FakeProductRepoForSortTest(this.items);

  @override
  Future<List<ProductModel>> getAll({String? query}) async {
    if (query != null && query.isNotEmpty) {
      return items.where((p) => p.name.contains(query)).toList();
    }
    return List.from(items);
  }
}

void main() {
  group('ProductsPage Column Sorting Tests', () {
    testWidgets('sorts products by name ascending and descending when header is tapped', (tester) async {
      tester.view.physicalSize = const Size(1800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final products = [
        ProductModel(
          id: 1,
          code: '01',
          name: 'آچار',
          category: 'ابزار',
          buyPrice: 10000,
          unit: 'عدد',
        ),
        ProductModel(
          id: 2,
          code: '02',
          name: 'پیچ‌گوشتی',
          category: 'ابزار',
          buyPrice: 20000,
          unit: 'عدد',
        ),
        ProductModel(
          id: 3,
          code: '03',
          name: 'بست',
          category: 'ابزار',
          buyPrice: 5000,
          unit: 'عدد',
        ),
      ];

      final fakeRepo = _FakeProductRepoForSortTest(products);
      final cubit = ProductCubit(repository: fakeRepo);
      await cubit.loadProducts();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductsPage(cubit: cubit),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final dataTableFinder = find.byType(DataTable);
      expect(dataTableFinder, findsOneWidget);

      DataTable dataTable = tester.widget<DataTable>(dataTableFinder);
      expect(dataTable.sortColumnIndex, 1);
      expect(dataTable.sortAscending, true);

      // Verify initial sorted order (Ascending by Name: آچار -> بست -> پیچ‌گوشتی)
      List<DataRow> rows = dataTable.rows;
      expect((rows[0].key as ValueKey).value, 1); // آچار
      expect((rows[1].key as ValueKey).value, 3); // بست
      expect((rows[2].key as ValueKey).value, 2); // پیچ‌گوشتی

      // Tap Name column header to sort descending
      final nameHeaderFinder = find.text(AppStrings.productName);
      await tester.tap(nameHeaderFinder);
      await tester.pumpAndSettle();

      dataTable = tester.widget<DataTable>(dataTableFinder);
      expect(dataTable.sortColumnIndex, 1);
      expect(dataTable.sortAscending, false);

      rows = dataTable.rows;
      expect((rows[0].key as ValueKey).value, 2); // پیچ‌گوشتی
      expect((rows[1].key as ValueKey).value, 3); // بست
      expect((rows[2].key as ValueKey).value, 1); // آچار

      // Tap Name column header again to sort ascending
      await tester.tap(nameHeaderFinder);
      await tester.pumpAndSettle();

      dataTable = tester.widget<DataTable>(dataTableFinder);
      expect(dataTable.sortColumnIndex, 1);
      expect(dataTable.sortAscending, true);

      rows = dataTable.rows;
      expect((rows[0].key as ValueKey).value, 1); // آچار
      expect((rows[1].key as ValueKey).value, 3); // بست
      expect((rows[2].key as ValueKey).value, 2); // پیچ‌گوشتی

      // Tap Buy Price column header to sort by price
      final priceHeaderFinder = find.text(AppStrings.productBuyPrice);
      await tester.tap(priceHeaderFinder);
      await tester.pumpAndSettle();

      dataTable = tester.widget<DataTable>(dataTableFinder);
      expect(dataTable.sortColumnIndex, 4);
      expect(dataTable.sortAscending, true);

      rows = dataTable.rows;
      expect((rows[0].key as ValueKey).value, 3); // بست (5,000)
      expect((rows[1].key as ValueKey).value, 1); // آچار (10,000)
      expect((rows[2].key as ValueKey).value, 2); // پیچ‌گوشتی (20,000)
    });
  });
}
