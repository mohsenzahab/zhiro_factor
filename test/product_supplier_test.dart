import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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
    late Database db;
    late ProductRepository repository;

    setUp(() async {
      db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('''
        CREATE TABLE products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT,
          name TEXT NOT NULL,
          category TEXT,
          buy_price REAL NOT NULL,
          current_buy_price REAL,
          sell_price REAL,
          unit TEXT NOT NULL,
          stock REAL,
          created_at TEXT,
          buy_date TEXT,
          supplier TEXT,
          is_temporary INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE suppliers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT,
          name TEXT NOT NULL,
          phone TEXT,
          address TEXT,
          notes TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE purchases (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          purchase_number TEXT NOT NULL,
          supplier_id INTEGER,
          date TEXT NOT NULL,
          FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
        )
      ''');
      await db.execute('''
        CREATE TABLE purchase_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          purchase_id INTEGER NOT NULL,
          product_id INTEGER,
          product_name TEXT NOT NULL,
          unit_price REAL NOT NULL,
          quantity REAL NOT NULL,
          line_total REAL NOT NULL,
          FOREIGN KEY (purchase_id) REFERENCES purchases(id)
        )
      ''');
      await db.execute('''
        CREATE TABLE invoice_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER,
          quantity REAL NOT NULL
        )
      ''');

      // Seed Suppliers
      await db.insert('suppliers', {'id': 1, 'code': 'S001', 'name': 'شرکت فناوری البرز'});
      await db.insert('suppliers', {'id': 2, 'code': 'S002', 'name': 'بازرگانی پارس گستر'});

      // Product 1: Direct supplier name
      await db.insert('products', {
        'id': 1,
        'code': 'P001',
        'name': 'کابل HDMI',
        'category': 'جانبی',
        'buy_price': 50000.0,
        'unit': 'عدد',
        'supplier': 'فروشگاه سپهر',
      });

      // Product 2: Supplier stored as supplier ID '1'
      await db.insert('products', {
        'id': 2,
        'code': 'P002',
        'name': 'کیبورد بیاند',
        'category': 'جانبی',
        'buy_price': 350000.0,
        'unit': 'عدد',
        'supplier': '1',
      });

      // Product 3: No direct supplier in products, but purchased via purchase with supplier 2
      await db.insert('products', {
        'id': 3,
        'code': 'P003',
        'name': 'موس اپتیکال',
        'category': 'جانبی',
        'buy_price': 120000.0,
        'unit': 'عدد',
        'supplier': null,
      });
      await db.insert('purchases', {
        'id': 100,
        'purchase_number': 'PUR-001',
        'supplier_id': 2,
        'date': '2026-10-15',
      });
      await db.insert('purchase_items', {
        'id': 1001,
        'purchase_id': 100,
        'product_id': 3,
        'product_name': 'موس اپتیکال',
        'unit_price': 120000.0,
        'quantity': 10.0,
        'line_total': 1200000.0,
      });

      // Product 4: No supplier at all
      await db.insert('products', {
        'id': 4,
        'code': 'P004',
        'name': 'پد الکلی',
        'category': 'مصرفی',
        'buy_price': 5000.0,
        'unit': 'بسته',
        'supplier': null,
      });

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
