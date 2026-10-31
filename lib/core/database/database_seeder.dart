import 'package:drift/drift.dart';
import 'app_database.dart';

/// Seeds initial mock data on first run using Drift ORM.
class DatabaseSeeder {
  DatabaseSeeder._();

  /// Check if data exists, seed if empty.
  static Future<void> seedIfEmpty([AppDatabase? database]) async {
    final db = database ?? AppDatabase.instance;
    final count = await (db.selectOnly(db.products)..addColumns([db.products.id.count()]))
        .map((row) => row.read(db.products.id.count()))
        .getSingle();
    if ((count ?? 0) > 0) return; // Already seeded

    await _seedProducts(db);
    await _seedCustomers(db);
    await _seedInvoices(db);
  }

  static Future<void> _seedProducts(AppDatabase db) async {
    final products = [
      ProductsCompanion.insert(
        name: 'لپ‌تاپ ایسوس VivoBook',
        unit: 'دستگاه',
        buyPrice: 45000000.0,
        code: const Value('P001'),
        category: const Value('الکترونیک'),
        stock: const Value(15.0),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
      ProductsCompanion.insert(
        name: 'موس بی‌سیم لاجیتک',
        unit: 'عدد',
        buyPrice: 1200000.0,
        code: const Value('P002'),
        category: const Value('جانبی'),
        stock: const Value(50.0),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
      ProductsCompanion.insert(
        name: 'کیبورد مکانیکال ردراگون',
        unit: 'عدد',
        buyPrice: 3500000.0,
        code: const Value('P003'),
        category: const Value('جانبی'),
        stock: const Value(30.0),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
      ProductsCompanion.insert(
        name: 'مانیتور سامسونگ 27 اینچ',
        unit: 'دستگاه',
        buyPrice: 18000000.0,
        code: const Value('P004'),
        category: const Value('الکترونیک'),
        stock: const Value(8.0),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
      ProductsCompanion.insert(
        name: 'هدفون بلوتوثی سونی',
        unit: 'عدد',
        buyPrice: 8500000.0,
        code: const Value('P005'),
        category: const Value('جانبی'),
        stock: const Value(25.0),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
      ProductsCompanion.insert(
        name: 'فلش مموری 64 گیگ سن‌دیسک',
        unit: 'عدد',
        buyPrice: 450000.0,
        code: const Value('P006'),
        category: const Value('ذخیره‌سازی'),
        stock: const Value(100.0),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
      ProductsCompanion.insert(
        name: 'هارد اکسترنال 1 ترابایت',
        unit: 'عدد',
        buyPrice: 5200000.0,
        code: const Value('P007'),
        category: const Value('ذخیره‌سازی'),
        stock: const Value(12.0),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
      ProductsCompanion.insert(
        name: 'کابل شارژ تایپ سی',
        unit: 'عدد',
        buyPrice: 250000.0,
        code: const Value('P008'),
        category: const Value('جانبی'),
        stock: const Value(200.0),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
      ProductsCompanion.insert(
        name: 'وب‌کم لاجیتک C920',
        unit: 'عدد',
        buyPrice: 6800000.0,
        code: const Value('P009'),
        category: const Value('الکترونیک'),
        stock: const Value(18.0),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
      ProductsCompanion.insert(
        name: 'پرینتر اپسون L3250',
        unit: 'دستگاه',
        buyPrice: 12500000.0,
        code: const Value('P010'),
        category: const Value('الکترونیک'),
        stock: const Value(5.0),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
      ProductsCompanion.insert(
        name: 'اسپیکر بلوتوثی JBL',
        unit: 'عدد',
        buyPrice: 4200000.0,
        code: const Value('P011'),
        category: const Value('جانبی'),
        stock: const Value(22.0),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
      ProductsCompanion.insert(
        name: 'پاوربانک 20000 شیائومی',
        unit: 'عدد',
        buyPrice: 2800000.0,
        code: const Value('P012'),
        category: const Value('جانبی'),
        stock: const Value(35.0),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
      ProductsCompanion.insert(
        name: 'خدمات نصب ویندوز',
        unit: 'پروژه',
        buyPrice: 500000.0,
        code: const Value('P013'),
        category: const Value('خدمات'),
        stock: const Value(999.0),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
      ProductsCompanion.insert(
        name: 'مشاوره فنی (ساعتی)',
        unit: 'ساعت',
        buyPrice: 800000.0,
        code: const Value('P014'),
        category: const Value('خدمات'),
        stock: const Value(999.0),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
      ProductsCompanion.insert(
        name: 'کارتریج پرینتر HP',
        unit: 'عدد',
        buyPrice: 1800000.0,
        code: const Value('P015'),
        category: const Value('مواد مصرفی'),
        stock: const Value(40.0),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
    ];

    await db.batch((batch) {
      batch.insertAll(db.products, products);
    });
  }

  static Future<void> _seedCustomers(AppDatabase db) async {
    final customers = [
      CustomersCompanion.insert(
        name: 'شرکت فناوری آینده',
        code: const Value('C001'),
        phone: const Value('021-88776655'),
        address: const Value('تهران، خیابان ولیعصر، پلاک 120'),
        notes: const Value('مشتری ویژه'),
      ),
      CustomersCompanion.insert(
        name: 'محمد رضایی',
        code: const Value('C002'),
        phone: const Value('09121234567'),
        address: const Value('اصفهان، خیابان چهارباغ'),
      ),
      CustomersCompanion.insert(
        name: 'فروشگاه دیجیتال نوین',
        code: const Value('C003'),
        phone: const Value('021-44332211'),
        address: const Value('تهران، بازار موبایل علاءالدین'),
        notes: const Value('خرید عمده'),
      ),
      CustomersCompanion.insert(
        name: 'علی احمدی',
        code: const Value('C004'),
        phone: const Value('09357654321'),
        address: const Value('شیراز، بلوار زند'),
      ),
      CustomersCompanion.insert(
        name: 'مؤسسه آموزشی دانش‌پژوهان',
        code: const Value('C005'),
        phone: const Value('031-36251478'),
        address: const Value('اصفهان، خیابان مشتاق'),
        notes: const Value('قرارداد سالانه'),
      ),
      CustomersCompanion.insert(
        name: 'سارا محمدی',
        code: const Value('C006'),
        phone: const Value('09198765432'),
        address: const Value('مشهد، بلوار وکیل‌آباد'),
      ),
      CustomersCompanion.insert(
        name: 'شرکت مهندسی پارس‌سازه',
        code: const Value('C007'),
        phone: const Value('021-22334455'),
        address: const Value('تهران، سعادت‌آباد'),
        notes: const Value('نیاز به فاکتور رسمی'),
      ),
      CustomersCompanion.insert(
        name: 'حسین کریمی',
        code: const Value('C008'),
        phone: const Value('09361112233'),
        address: const Value('تبریز، خیابان آزادی'),
      ),
    ];

    await db.batch((batch) {
      batch.insertAll(db.customers, customers);
    });
  }

  static Future<void> _seedInvoices(AppDatabase db) async {
    // Invoice 1: Settled
    final inv1Id = await db.into(db.invoices).insert(InvoicesCompanion.insert(
      invoiceNumber: 'INV-0506-0001',
      customerId: const Value(1),
      date: DateTime(2026, 8, 20).toIso8601String(),
      status: const Value('تسویه شده'),
      totalGross: 52400000.0,
      totalDiscount: 2400000.0,
      totalNet: 50000000.0,
      notes: const Value('فاکتور خرید تجهیزات دفتر'),
    ));

    await db.batch((batch) {
      batch.insertAll(db.invoiceItems, [
        InvoiceItemsCompanion.insert(
          invoiceId: inv1Id,
          productId: const Value(1),
          productName: 'لپ‌تاپ ایسوس VivoBook',
          unitPrice: 45000000.0,
          quantity: const Value(1.0),
          discountType: const Value('percentage'),
          discountValue: const Value(5.0),
          discountCalculatedAmount: const Value(2250000.0),
          lineTotal: 42750000.0,
        ),
        InvoiceItemsCompanion.insert(
          invoiceId: inv1Id,
          productId: const Value(2),
          productName: 'موس بی‌سیم لاجیتک',
          unitPrice: 1200000.0,
          quantity: const Value(2.0),
          discountType: const Value('none'),
          discountValue: const Value(0.0),
          discountCalculatedAmount: const Value(0.0),
          lineTotal: 2400000.0,
        ),
        InvoiceItemsCompanion.insert(
          invoiceId: inv1Id,
          productId: const Value(3),
          productName: 'کیبورد مکانیکال ردراگون',
          unitPrice: 3500000.0,
          quantity: const Value(2.0),
          discountType: const Value('amount'),
          discountValue: const Value(150000.0),
          discountCalculatedAmount: const Value(150000.0),
          lineTotal: 6850000.0,
        ),
      ]);
    });

    // Invoice 2: Pending
    final inv2Id = await db.into(db.invoices).insert(InvoicesCompanion.insert(
      invoiceNumber: 'INV-0506-0002',
      customerId: const Value(3),
      date: DateTime(2026, 8, 25).toIso8601String(),
      status: const Value('در انتظار پرداخت'),
      totalGross: 36000000.0,
      totalDiscount: 1800000.0,
      totalNet: 34200000.0,
    ));

    await db.into(db.invoiceItems).insert(InvoiceItemsCompanion.insert(
      invoiceId: inv2Id,
      productId: const Value(4),
      productName: 'مانیتور سامسونگ 27 اینچ',
      unitPrice: 18000000.0,
      quantity: const Value(2.0),
      discountType: const Value('percentage'),
      discountValue: const Value(5.0),
      discountCalculatedAmount: const Value(1800000.0),
      lineTotal: 34200000.0,
    ));

    // Invoice 3: Deposit
    final inv3Id = await db.into(db.invoices).insert(InvoicesCompanion.insert(
      invoiceNumber: 'INV-0506-0003',
      customerId: const Value(5),
      date: DateTime(2026, 8, 28).toIso8601String(),
      status: const Value('بیعانه'),
      totalGross: 26300000.0,
      totalDiscount: 0.0,
      totalNet: 26300000.0,
      notes: const Value('بیعانه 10 میلیون دریافت شد'),
    ));

    await db.batch((batch) {
      batch.insertAll(db.invoiceItems, [
        InvoiceItemsCompanion.insert(
          invoiceId: inv3Id,
          productId: const Value(5),
          productName: 'هدفون بلوتوثی سونی',
          unitPrice: 8500000.0,
          quantity: const Value(3.0),
          discountType: const Value('none'),
          discountValue: const Value(0.0),
          discountCalculatedAmount: const Value(0.0),
          lineTotal: 25500000.0,
        ),
        InvoiceItemsCompanion.insert(
          invoiceId: inv3Id,
          productId: const Value(14),
          productName: 'مشاوره فنی (ساعتی)',
          unitPrice: 800000.0,
          quantity: const Value(1.0),
          discountType: const Value('none'),
          discountValue: const Value(0.0),
          discountCalculatedAmount: const Value(0.0),
          lineTotal: 800000.0,
        ),
      ]);
    });

    // Invoice 4: Settled
    final inv4Id = await db.into(db.invoices).insert(InvoicesCompanion.insert(
      invoiceNumber: 'INV-0506-0004',
      customerId: const Value(2),
      date: DateTime(2026, 8, 15).toIso8601String(),
      status: const Value('تسویه شده'),
      totalGross: 6050000.0,
      totalDiscount: 250000.0,
      totalNet: 5800000.0,
    ));

    await db.batch((batch) {
      batch.insertAll(db.invoiceItems, [
        InvoiceItemsCompanion.insert(
          invoiceId: inv4Id,
          productId: const Value(7),
          productName: 'هارد اکسترنال 1 ترابایت',
          unitPrice: 5200000.0,
          quantity: const Value(1.0),
          discountType: const Value('amount'),
          discountValue: const Value(200000.0),
          discountCalculatedAmount: const Value(200000.0),
          lineTotal: 5000000.0,
        ),
        InvoiceItemsCompanion.insert(
          invoiceId: inv4Id,
          productId: const Value(8),
          productName: 'کابل شارژ تایپ سی',
          unitPrice: 250000.0,
          quantity: const Value(2.0),
          discountType: const Value('percentage'),
          discountValue: const Value(10.0),
          discountCalculatedAmount: const Value(50000.0),
          lineTotal: 450000.0,
        ),
        InvoiceItemsCompanion.insert(
          invoiceId: inv4Id,
          productId: const Value(6),
          productName: 'فلش مموری 64 گیگ سن‌دیسک',
          unitPrice: 450000.0,
          quantity: const Value(1.0),
          discountType: const Value('none'),
          discountValue: const Value(0.0),
          discountCalculatedAmount: const Value(0.0),
          lineTotal: 450000.0,
        ),
      ]);
    });

    // Invoice 5: Cancelled
    await db.into(db.invoices).insert(InvoicesCompanion.insert(
      invoiceNumber: 'INV-0506-0005',
      customerId: const Value(4),
      date: DateTime(2026, 8, 10).toIso8601String(),
      status: const Value('لغو شده'),
      totalGross: 12500000.0,
      totalDiscount: 0.0,
      totalNet: 12500000.0,
      notes: const Value('مشتری انصراف داد'),
    ));
  }
}
