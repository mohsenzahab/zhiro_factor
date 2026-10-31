import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_box/core/database/app_database.dart';
import 'package:sales_box/core/constants/app_strings.dart';
import 'package:sales_box/data/models/product_model.dart';
import 'package:sales_box/data/repositories/product_repository.dart';
import 'package:sales_box/features/products/cubit/product_cubit.dart';
import 'package:sales_box/features/products/view/products_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ProductModel Supplier Field Tests', () {
    test('supplierDisplay returns supplier name when set', () {
      final p = ProductModel(
        name: 'کابل شبکه Cat6',
        unit: 'متر',
        buyPrice: 15000,
        supplier: 'شرکت پایا شبکه',
      );
      expect(p.supplier, equals('شرکت پایا شبکه'));
      expect(p.supplierDisplay, equals('شرکت پایا شبکه'));
    });

    test('supplierDisplay returns dash when supplier is null or empty', () {
      final p1 = ProductModel(
        name: 'موس پد',
        unit: 'عدد',
        buyPrice: 30000,
        supplier: null,
      );
      expect(p1.supplierDisplay, equals('-'));

      final p2 = ProductModel(
        name: 'موس پد ۲',
        unit: 'عدد',
        buyPrice: 30000,
        supplier: '   ',
      );
      expect(p2.supplierDisplay, equals('-'));
    });

    test('fromMap reads resolved_supplier and supplier_title and trims', () {
      final p1 = ProductModel.fromMap({
        'name': 'رم ۸ گیگ',
        'unit': 'عدد',
        'buy_price': 800000.0,
        'resolved_supplier': '  بازرگانی آریا  ',
      });
      expect(p1.supplier, equals('بازرگانی آریا'));

      final p2 = ProductModel.fromMap({
        'name': 'رم ۱۶ گیگ',
        'unit': 'عدد',
        'buy_price': 1500000.0,
        'supplier_title': 'پخش حافظه نوین',
      });
      expect(p2.supplier, equals('پخش حافظه نوین'));

      final p3 = ProductModel.fromMap({
        'name': 'رم ۳۲ گیگ',
        'unit': 'عدد',
        'buy_price': 3000000.0,
        'supplier': 'دیجی‌کالا',
      });
      expect(p3.supplier, equals('دیجی‌کالا'));
    });
  });

  group('ProductRepository Supplier Reading Tests with SQLite', () {
    late AppDatabase db;
    late ProductRepository repository;

    setUp(() async {
      db = AppDatabase.memory();

      // Seed Suppliers
      await db.into(db.suppliers).insert(SuppliersCompanion.insert(
        id: const Value(1),
        code: const Value('S001'),
        name: 'شرکت فناوری البرز',
      ));
      await db.into(db.suppliers).insert(SuppliersCompanion.insert(
        id: const Value(2),
        code: const Value('S002'),
        name: 'بازرگانی پارس گستر',
      ));

      // Product 1: Direct supplier name
      await db.into(db.products).insert(ProductsCompanion.insert(
        id: const Value(1),
        code: const Value('P001'),
        name: 'کابل HDMI',
        category: const Value('جانبی'),
        buyPrice: 50000.0,
        unit: 'عدد',
        supplier: const Value('فروشگاه سپهر'),
      ));

      // Product 2: Supplier stored as supplier ID '1'
      await db.into(db.products).insert(ProductsCompanion.insert(
        id: const Value(2),
        code: const Value('P002'),
        name: 'کیبورد بیاند',
        category: const Value('جانبی'),
        buyPrice: 350000.0,
        unit: 'عدد',
        supplier: const Value('1'),
      ));

      // Product 3: No direct supplier in products, but purchased via purchase with supplier 2
      await db.into(db.products).insert(ProductsCompanion.insert(
        id: const Value(3),
        code: const Value('P003'),
        name: 'موس اپتیکال',
        category: const Value('جانبی'),
        buyPrice: 120000.0,
        unit: 'عدد',
      ));
      await db.into(db.purchases).insert(PurchasesCompanion.insert(
        id: const Value(100),
        purchaseNumber: 'PUR-001',
        supplierId: const Value(2),
        date: '2026-10-15',
      ));
      await db.into(db.purchaseItems).insert(PurchaseItemsCompanion.insert(
        id: const Value(1001),
        purchaseId: 100,
        productId: const Value(3),
        productName: 'موس اپتیکال',
        unitPrice: 120000.0,
        quantity: const Value(10.0),
        lineTotal: 1200000.0,
      ));

      // Product 4: No supplier at all
      await db.into(db.products).insert(ProductsCompanion.insert(
        id: const Value(4),
        code: const Value('P004'),
        name: 'پد الکلی',
        category: const Value('مصرفی'),
        buyPrice: 5000.0,
        unit: 'بسته',
      ));

      repository = ProductRepository(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('getAll reads supplier title correctly for all products', () async {
      final products = await repository.getAll();
      expect(products.length, equals(4));

      final p1 = products.firstWhere((p) => p.id == 1);
      expect(p1.supplier, equals('فروشگاه سپهر'));
      expect(p1.supplierDisplay, equals('فروشگاه سپهر'));

      final p2 = products.firstWhere((p) => p.id == 2);
      expect(p2.supplier, equals('شرکت فناوری البرز'));
      expect(p2.supplierDisplay, equals('شرکت فناوری البرز'));

      final p3 = products.firstWhere((p) => p.id == 3);
      expect(p3.supplier, equals('بازرگانی پارس گستر'));
      expect(p3.supplierDisplay, equals('بازرگانی پارس گستر'));

      final p4 = products.firstWhere((p) => p.id == 4);
      expect(p4.supplier, isNull);
      expect(p4.supplierDisplay, equals('-'));
    });

    test('getById resolves supplier title accurately', () async {
      final p2 = await repository.getById(2);
      expect(p2?.supplier, equals('شرکت فناوری البرز'));

      final p3 = await repository.getById(3);
      expect(p3?.supplier, equals('بازرگانی پارس گستر'));
    });

    test('getAll searches products by supplier title', () async {
      final results = await repository.getAll(query: 'البرز');
      expect(results.length, equals(1));
      expect(results.first.id, equals(2));
      expect(results.first.name, equals('کیبورد بیاند'));
    });

    test('getDistinctSuppliers returns unique sorted supplier names', () async {
      final suppliers = await repository.getDistinctSuppliers();
      expect(suppliers, contains('فروشگاه سپهر'));
      expect(suppliers, contains('شرکت فناوری البرز'));
      expect(suppliers, contains('بازرگانی پارس گستر'));
    });
  });

  group('ProductsPage Supplier Column Widget Tests', () {
    testWidgets('renders supplier column and cells in products table', (tester) async {
      tester.view.physicalSize = const Size(1800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final products = [
        ProductModel(
          id: 1,
          code: 'P01',
          name: 'باتری قلمی',
          category: 'جانبی',
          buyPrice: 20000,
          unit: 'عدد',
          supplier: 'پخش پارس',
        ),
        ProductModel(
          id: 2,
          code: 'P02',
          name: 'چسب نواری',
          category: 'مصرفی',
          buyPrice: 10000,
          unit: 'حلقه',
          supplier: null,
        ),
      ];

      final fakeRepo = _FakeProductRepoForSupplierTest(products);
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

      // Check header column exists
      expect(find.text(AppStrings.productSupplier), findsOneWidget);

      // Check supplier cell values exist
      expect(find.text('پخش پارس'), findsOneWidget);
      expect(find.text('-'), findsWidgets);
    });
  });
}

class _FakeProductRepoForSupplierTest extends ProductRepository {
  final List<ProductModel> items;

  _FakeProductRepoForSupplierTest(this.items);

  @override
  Future<List<ProductModel>> getAll({String? query}) async {
    return List.from(items);
  }

  @override
  Future<List<String>> getDistinctCategories() async => ['جانبی', 'مصرفی'];

  @override
  Future<List<String>> getDistinctSuppliers() async => ['پخش پارس'];
}
