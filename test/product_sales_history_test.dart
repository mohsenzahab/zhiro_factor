import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_box/core/constants/app_strings.dart';
import 'package:sales_box/core/extensions/number_extensions.dart';
import 'package:sales_box/data/models/product_model.dart';
import 'package:sales_box/data/models/product_sale_record.dart';
import 'package:sales_box/data/repositories/invoice_repository.dart';
import 'package:sales_box/data/repositories/product_repository.dart';
import 'package:sales_box/features/products/cubit/product_cubit.dart';
import 'package:sales_box/features/products/cubit/product_sales_history_cubit.dart';
import 'package:sales_box/features/products/cubit/product_sales_history_state.dart';
import 'package:sales_box/features/products/view/product_sales_history_page.dart';
import 'package:sales_box/features/products/view/products_page.dart';
import 'package:sales_box/shared/widgets/date_range_filter_bar.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeProductSalesInvoiceRepo extends InvoiceRepository {
  final List<ProductSaleRecord> sales;
  _FakeProductSalesInvoiceRepo(this.sales);

  @override
  Future<List<ProductSaleRecord>> getProductSales(
    int productId, {
    String? dateFrom,
    String? dateTo,
    String? status,
    String? query,
  }) async {
    return sales;
  }
}

class _FakeProductSalesProductRepo extends ProductRepository {
  final ProductModel product;
  _FakeProductSalesProductRepo(this.product);

  @override
  Future<ProductModel?> getById(int id) async => product;

  @override
  Future<List<ProductModel>> getAll({String? query}) async => [product];
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ProductSaleRecord Model Tests', () {
    test('Calculates profit amount and percentage correctly', () {
      const record = ProductSaleRecord(
        itemId: 1,
        invoiceId: 10,
        invoiceNumber: 'INV-100',
        date: '2026-10-25T10:00:00.000',
        invoiceStatus: 'تسویه شده',
        customerId: 5,
        customerName: 'رضا کریمی',
        productId: 2,
        productName: 'لامپ ال‌ای‌دی',
        quantity: 4.0,
        unitPrice: 50000.0,
        purchasePrice: 35000.0,
        discountType: 'none',
        discountValue: 0.0,
        discountCalculatedAmount: 0.0,
        lineTotal: 200000.0,
        productUnit: 'عدد',
      );

      expect(record.profitAmount, equals(60000.0));
      expect(record.profitPercentage, closeTo(42.857, 0.01));
      expect(record.customerDisplay, equals('رضا کریمی'));
      expect(record.quantityDisplay, equals('۴ عدد'));
      expect(record.unitPriceDisplay, contains('۵۰,۰۰۰'));
      expect(record.lineTotalDisplay, contains('۲۰۰,۰۰۰'));
    });

    test('Serializes to and from Map with purchase price fallback correctly', () {
      final map = {
        'item_id': 12,
        'invoice_id': 105,
        'invoice_number': 'INV-200',
        'date': '2026-10-20T14:30:00.000',
        'invoice_status': 'نسیه',
        'customer_id': null,
        'customer_name': null,
        'customer_phone': null,
        'product_id': 9,
        'product_name': 'فیلتر روغن',
        'quantity': 2.0,
        'unit_price': 80000.0,
        'purchase_price': 0.0,
        'buy_price': 60000.0,
        'current_buy_price': 65000.0,
        'discount_type': 'amount',
        'discount_value': 10000.0,
        'discount_calculated_amount': 10000.0,
        'line_total': 150000.0,
        'product_unit': 'بسته',
      };

      final record = ProductSaleRecord.fromMap(map);
      expect(record.itemId, equals(12));
      expect(record.invoiceNumber, equals('INV-200'));
      expect(record.customerDisplay, equals('مشتری نقدی / عمومی'));
      expect(record.purchasePrice, equals(65000.0));
      expect(record.productUnit, equals('بسته'));
      expect(record.quantityDisplay, equals('۲ بسته'));
      expect(record.profitAmount, equals(150000.0 - (2 * 65000.0)));
    });
  });

  group('ProductSalesHistoryState Computed Stats Tests', () {
    test('Computes totals across sales correctly', () {
      const s1 = ProductSaleRecord(
        itemId: 1,
        invoiceId: 10,
        invoiceNumber: 'INV-10',
        date: '2026-10-20T10:00:00.000',
        invoiceStatus: 'تسویه شده',
        productId: 1,
        productName: 'کالا ۱',
        quantity: 5.0,
        unitPrice: 10000.0,
        purchasePrice: 6000.0,
        discountType: 'none',
        discountValue: 0.0,
        discountCalculatedAmount: 0.0,
        lineTotal: 50000.0,
      );

      const s2 = ProductSaleRecord(
        itemId: 2,
        invoiceId: 10,
        invoiceNumber: 'INV-10',
        date: '2026-10-20T10:00:00.000',
        invoiceStatus: 'تسویه شده',
        productId: 1,
        productName: 'کالا ۱',
        quantity: 3.0,
        unitPrice: 10000.0,
        purchasePrice: 6000.0,
        discountType: 'amount',
        discountValue: 5000.0,
        discountCalculatedAmount: 5000.0,
        lineTotal: 25000.0,
      );

      const s3 = ProductSaleRecord(
        itemId: 3,
        invoiceId: 20,
        invoiceNumber: 'INV-20',
        date: '2026-10-22T12:00:00.000',
        invoiceStatus: 'در انتظار پرداخت',
        productId: 1,
        productName: 'کالا ۱',
        quantity: 2.0,
        unitPrice: 12000.0,
        purchasePrice: 6000.0,
        discountType: 'none',
        discountValue: 0.0,
        discountCalculatedAmount: 0.0,
        lineTotal: 24000.0,
      );

      const state = ProductSalesHistoryState(
        sales: [s1, s2, s3],
      );

      expect(state.filteredTotalQuantity, equals(10.0));
      expect(state.filteredTotalSales, equals(99000.0));
      expect(state.filteredTotalDiscount, equals(5000.0));
      expect(state.filteredTotalProfit, equals(39000.0));
      expect(state.filteredInvoiceCount, equals(2));
    });
  });

  group('InvoiceRepository.getProductSales Database Integration Tests', () {
    late Database db;
    late InvoiceRepository repo;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE customers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              phone TEXT
            )
          ''');
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
              stock REAL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE invoices (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              invoice_number TEXT NOT NULL,
              customer_id INTEGER,
              date TEXT NOT NULL,
              status TEXT NOT NULL,
              total_gross REAL NOT NULL,
              total_discount REAL NOT NULL,
              total_net REAL NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE invoice_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              invoice_id INTEGER NOT NULL,
              product_id INTEGER NOT NULL,
              product_name TEXT NOT NULL,
              unit_price REAL NOT NULL,
              purchase_price REAL NOT NULL,
              quantity REAL NOT NULL,
              discount_type TEXT NOT NULL DEFAULT 'none',
              discount_value REAL NOT NULL DEFAULT 0.0,
              discount_calculated_amount REAL NOT NULL DEFAULT 0.0,
              line_total REAL NOT NULL
            )
          ''');
        },
      );

      await db.insert('customers', {'id': 1, 'name': 'امیر حسینی', 'phone': '09123456789'});

      await db.insert('products', {
        'id': 10,
        'code': 'P-10',
        'name': 'چای ماسالا',
        'category': 'نوشیدنی',
        'buy_price': 80000.0,
        'current_buy_price': 90000.0,
        'sell_price': 120000.0,
        'unit': 'بسته',
        'stock': 15.0,
      });

      await db.insert('products', {
        'id': 20,
        'code': 'P-20',
        'name': 'قهوه اسپرسو',
        'category': 'نوشیدنی',
        'buy_price': 150000.0,
        'current_buy_price': 160000.0,
        'sell_price': 200000.0,
        'unit': 'کیلو',
        'stock': 5.0,
      });

      await db.insert('invoices', {
        'id': 100,
        'invoice_number': 'F-100',
        'customer_id': 1,
        'date': '2026-10-10T10:00:00.000',
        'status': 'تسویه شده',
        'total_gross': 240000.0,
        'total_discount': 0.0,
        'total_net': 240000.0,
      });
      await db.insert('invoice_items', {
        'invoice_id': 100,
        'product_id': 10,
        'product_name': 'چای ماسالا',
        'unit_price': 120000.0,
        'purchase_price': 90000.0,
        'quantity': 2.0,
        'discount_type': 'none',
        'discount_value': 0.0,
        'discount_calculated_amount': 0.0,
        'line_total': 240000.0,
      });

      await db.insert('invoices', {
        'id': 101,
        'invoice_number': 'F-101',
        'customer_id': null,
        'date': '2026-10-20T12:00:00.000',
        'status': 'در انتظار پرداخت',
        'total_gross': 360000.0,
        'total_discount': 10000.0,
        'total_net': 350000.0,
      });
      await db.insert('invoice_items', {
        'invoice_id': 101,
        'product_id': 10,
        'product_name': 'چای ماسالا',
        'unit_price': 120000.0,
        'purchase_price': 90000.0,
        'quantity': 3.0,
        'discount_type': 'amount',
        'discount_value': 10000.0,
        'discount_calculated_amount': 10000.0,
        'line_total': 350000.0,
      });

      await db.insert('invoices', {
        'id': 102,
        'invoice_number': 'F-102',
        'customer_id': 1,
        'date': '2026-10-25T14:00:00.000',
        'status': 'تسویه شده',
        'total_gross': 200000.0,
        'total_discount': 0.0,
        'total_net': 200000.0,
      });
      await db.insert('invoice_items', {
        'invoice_id': 102,
        'product_id': 20,
        'product_name': 'قهوه اسپرسو',
        'unit_price': 200000.0,
        'purchase_price': 160000.0,
        'quantity': 1.0,
        'discount_type': 'none',
        'discount_value': 0.0,
        'discount_calculated_amount': 0.0,
        'line_total': 200000.0,
      });

      repo = InvoiceRepository(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Fetches all sales for the target product only', () async {
      final sales = await repo.getProductSales(10);
      expect(sales.length, equals(2));
      expect(sales[0].invoiceNumber, equals('F-101'));
      expect(sales[1].invoiceNumber, equals('F-100'));
      expect(sales[0].productUnit, equals('بسته'));
      expect(sales[1].customerName, equals('امیر حسینی'));
    });

    test('Filters product sales by date range', () async {
      final sales = await repo.getProductSales(
        10,
        dateFrom: '2026-10-15T00:00:00.000',
        dateTo: '2026-10-30T23:59:59.000',
      );
      expect(sales.length, equals(1));
      expect(sales.first.invoiceNumber, equals('F-101'));
    });

    test('Filters product sales by invoice status', () async {
      final sales = await repo.getProductSales(10, status: 'تسویه شده');
      expect(sales.length, equals(1));
      expect(sales.first.invoiceNumber, equals('F-100'));
    });

    test('Filters product sales by customer query or invoice number', () async {
      final byCustomer = await repo.getProductSales(10, query: 'امیر');
      expect(byCustomer.length, equals(1));
      expect(byCustomer.first.invoiceNumber, equals('F-100'));

      final byInvoice = await repo.getProductSales(10, query: '101');
      expect(byInvoice.length, equals(1));
      expect(byInvoice.first.invoiceNumber, equals('F-101'));
    });
  });

  group('ProductSalesHistoryCubit & View Widget Tests', () {
    final sampleProduct = ProductModel(
      id: 50,
      code: 'P-50',
      name: 'کیک شکلاتی',
      category: 'شیرینی‌جات',
      buyPrice: 40000.0,
      currentBuyPrice: 45000.0,
      sellPrice: 70000.0,
      unit: 'عدد',
      stock: 20.0,
    );

    const sampleSale = ProductSaleRecord(
      itemId: 1,
      invoiceId: 500,
      invoiceNumber: 'INV-500',
      date: '2026-10-24T11:00:00.000',
      invoiceStatus: 'تسویه شده',
      customerId: 1,
      customerName: 'سارا احمدی',
      productId: 50,
      productName: 'کیک شکلاتی',
      unitPrice: 70000.0,
      purchasePrice: 45000.0,
      quantity: 3.0,
      discountType: 'none',
      discountValue: 0.0,
      discountCalculatedAmount: 0.0,
      lineTotal: 210000.0,
      productUnit: 'عدد',
    );

    test('ProductSalesHistoryCubit loads product and sales data correctly', () async {
      final invoiceRepo = _FakeProductSalesInvoiceRepo([sampleSale]);
      final productRepo = _FakeProductSalesProductRepo(sampleProduct);
      final cubit = ProductSalesHistoryCubit(
        productId: 50,
        invoiceRepo: invoiceRepo,
        productRepo: productRepo,
      );

      await cubit.load();
      expect(cubit.state.product?.name, equals('کیک شکلاتی'));
      expect(cubit.state.sales.length, equals(1));
      expect(cubit.state.filteredTotalQuantity, equals(3.0));
      expect(cubit.state.filteredTotalSales, equals(210000.0));
      expect(cubit.state.filteredTotalProfit, equals(210000.0 - (3 * 45000.0)));
    });

    testWidgets(
      'ProductSalesHistoryPage displays summary stats, sales table, and invoice number click triggers callback',
      (tester) async {
        tester.view.physicalSize = const Size(1800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final invoiceRepo = _FakeProductSalesInvoiceRepo([sampleSale]);
        final productRepo = _FakeProductSalesProductRepo(sampleProduct);
        final cubit = ProductSalesHistoryCubit(
          productId: 50,
          invoiceRepo: invoiceRepo,
          productRepo: productRepo,
        );
        await cubit.load();

        int? clickedInvoiceId;
        bool backClicked = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: ProductSalesHistoryPage(
                  productId: 50,
                  cubit: cubit,
                  onBack: () => backClicked = true,
                  onViewInvoice: (id) => clickedInvoiceId = id,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify product name and summary KPI stats are visible
        expect(find.textContaining('کیک شکلاتی'), findsWidgets);
        expect(find.text(AppStrings.totalSoldLabel), findsOneWidget);
        expect(find.text(AppStrings.remainingStock), findsOneWidget);
        expect(find.text(AppStrings.currentBuyPriceLabel), findsOneWidget);
        expect(find.text(AppStrings.currentSellPriceLabel), findsOneWidget);

        // Verify stock display '۲۰ عدد'
        expect(find.textContaining('۲۰ عدد'), findsWidgets);

        // Verify current buy price and sell price
        expect(find.textContaining('۴۵,۰۰۰ تومان'), findsWidgets);
        expect(find.textContaining('۷۰,۰۰۰ تومان'), findsWidgets);

        // Verify sales record details
        expect(find.text('سارا احمدی'), findsOneWidget);
        expect(find.text('INV-500'.toPersianDigits()), findsOneWidget);
        expect(find.text('تسویه شده'), findsWidgets);
        expect(find.text('۳ عدد'), findsOneWidget);

        // Tap on invoice number
        await tester.tap(find.text('INV-500'.toPersianDigits()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(clickedInvoiceId, equals(500));

        // Tap on back button
        await tester.tap(find.text(AppStrings.backToProducts));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(backClicked, isTrue);
      },
    );

    testWidgets('ProductsPage displays sales history button and clicking it calls onViewProductSales', (tester) async {
      tester.view.physicalSize = const Size(2400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int? salesProductId;

      final productRepo = _FakeProductSalesProductRepo(sampleProduct);
      final productCubit = ProductCubit(repository: productRepo);
      await productCubit.loadProducts();

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: ProductsPage(
                cubit: productCubit,
                onViewProductSales: (id) => salesProductId = id,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify sales history icon button is present
      final salesHistoryBtn = find.byTooltip(AppStrings.viewProductSales);
      expect(salesHistoryBtn, findsOneWidget);

      // Scroll to ensure visible and tap the sales history button
      await tester.ensureVisible(salesHistoryBtn);
      await tester.pump();
      await tester.tap(salesHistoryBtn, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(salesProductId, equals(50));
    });
  });
}
