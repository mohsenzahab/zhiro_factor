import 'package:sqflite_common/sqlite_api.dart';
import 'database_helper.dart';

/// Seeds initial mock data on first run.
class DatabaseSeeder {
  DatabaseSeeder._();

  /// Check if data exists, seed if empty.
  static Future<void> seedIfEmpty() async {
    final db = await DatabaseHelper.instance.database;
    final count = (await db.rawQuery('SELECT COUNT(*) as c FROM products')).first['c'] as int;
    if (count > 0) return; // Already seeded

    await _seedProducts(db);
    await _seedCustomers(db);
    await _seedInvoices(db);
  }

  static Future<void> _seedProducts(Database db) async {
    final products = [
      {'code': 'P001', 'name': 'لپ‌تاپ ایسوس VivoBook', 'category': 'الکترونیک', 'price': 45000000.0, 'unit': 'دستگاه', 'stock': 15.0},
      {'code': 'P002', 'name': 'موس بی‌سیم لاجیتک', 'category': 'جانبی', 'price': 1200000.0, 'unit': 'عدد', 'stock': 50.0},
      {'code': 'P003', 'name': 'کیبورد مکانیکال ردراگون', 'category': 'جانبی', 'price': 3500000.0, 'unit': 'عدد', 'stock': 30.0},
      {'code': 'P004', 'name': 'مانیتور سامسونگ 27 اینچ', 'category': 'الکترونیک', 'price': 18000000.0, 'unit': 'دستگاه', 'stock': 8.0},
      {'code': 'P005', 'name': 'هدفون بلوتوثی سونی', 'category': 'جانبی', 'price': 8500000.0, 'unit': 'عدد', 'stock': 25.0},
      {'code': 'P006', 'name': 'فلش مموری 64 گیگ سن‌دیسک', 'category': 'ذخیره‌سازی', 'price': 450000.0, 'unit': 'عدد', 'stock': 100.0},
      {'code': 'P007', 'name': 'هارد اکسترنال 1 ترابایت', 'category': 'ذخیره‌سازی', 'price': 5200000.0, 'unit': 'عدد', 'stock': 12.0},
      {'code': 'P008', 'name': 'کابل شارژ تایپ سی', 'category': 'جانبی', 'price': 250000.0, 'unit': 'عدد', 'stock': 200.0},
      {'code': 'P009', 'name': 'وب‌کم لاجیتک C920', 'category': 'الکترونیک', 'price': 6800000.0, 'unit': 'عدد', 'stock': 18.0},
      {'code': 'P010', 'name': 'پرینتر اپسون L3250', 'category': 'الکترونیک', 'price': 12500000.0, 'unit': 'دستگاه', 'stock': 5.0},
      {'code': 'P011', 'name': 'اسپیکر بلوتوثی JBL', 'category': 'جانبی', 'price': 4200000.0, 'unit': 'عدد', 'stock': 22.0},
      {'code': 'P012', 'name': 'پاوربانک 20000 شیائومی', 'category': 'جانبی', 'price': 2800000.0, 'unit': 'عدد', 'stock': 35.0},
      {'code': 'P013', 'name': 'خدمات نصب ویندوز', 'category': 'خدمات', 'price': 500000.0, 'unit': 'پروژه', 'stock': 999.0},
      {'code': 'P014', 'name': 'مشاوره فنی (ساعتی)', 'category': 'خدمات', 'price': 800000.0, 'unit': 'ساعت', 'stock': 999.0},
      {'code': 'P015', 'name': 'کارتریج پرینتر HP', 'category': 'مواد مصرفی', 'price': 1800000.0, 'unit': 'عدد', 'stock': 40.0},
    ];

    for (final p in products) {
      p['created_at'] = DateTime.now().toIso8601String();
      await db.insert('products', p);
    }
  }

  static Future<void> _seedCustomers(Database db) async {
    final customers = [
      {'code': 'C001', 'name': 'شرکت فناوری آینده', 'phone': '021-88776655', 'address': 'تهران، خیابان ولیعصر، پلاک 120', 'notes': 'مشتری ویژه'},
      {'code': 'C002', 'name': 'محمد رضایی', 'phone': '09121234567', 'address': 'اصفهان، خیابان چهارباغ', 'notes': ''},
      {'code': 'C003', 'name': 'فروشگاه دیجیتال نوین', 'phone': '021-44332211', 'address': 'تهران، بازار موبایل علاءالدین', 'notes': 'خرید عمده'},
      {'code': 'C004', 'name': 'علی احمدی', 'phone': '09357654321', 'address': 'شیراز، بلوار زند', 'notes': ''},
      {'code': 'C005', 'name': 'مؤسسه آموزشی دانش‌پژوهان', 'phone': '031-36251478', 'address': 'اصفهان، خیابان مشتاق', 'notes': 'قرارداد سالانه'},
      {'code': 'C006', 'name': 'سارا محمدی', 'phone': '09198765432', 'address': 'مشهد، بلوار وکیل‌آباد', 'notes': ''},
      {'code': 'C007', 'name': 'شرکت مهندسی پارس‌سازه', 'phone': '021-22334455', 'address': 'تهران، سعادت‌آباد', 'notes': 'نیاز به فاکتور رسمی'},
      {'code': 'C008', 'name': 'حسین کریمی', 'phone': '09361112233', 'address': 'تبریز، خیابان آزادی', 'notes': ''},
    ];

    for (final c in customers) {
      await db.insert('customers', c);
    }
  }

  static Future<void> _seedInvoices(Database db) async {
    // Invoice 1: Settled
    final inv1Id = await db.insert('invoices', {
      'invoice_number': 'INV-0506-0001',
      'customer_id': 1,
      'date': DateTime(2026, 8, 20).toIso8601String(),
      'status': 'تسویه شده',
      'total_gross': 52400000.0,
      'total_discount': 2400000.0,
      'total_net': 50000000.0,
      'notes': 'فاکتور خرید تجهیزات دفتر',
    });
    await db.insert('invoice_items', {
      'invoice_id': inv1Id, 'product_id': 1, 'product_name': 'لپ‌تاپ ایسوس VivoBook',
      'unit_price': 45000000.0, 'quantity': 1.0, 'discount_type': 'percentage',
      'discount_value': 5.0, 'discount_calculated_amount': 2250000.0, 'line_total': 42750000.0,
    });
    await db.insert('invoice_items', {
      'invoice_id': inv1Id, 'product_id': 2, 'product_name': 'موس بی‌سیم لاجیتک',
      'unit_price': 1200000.0, 'quantity': 2.0, 'discount_type': 'none',
      'discount_value': 0.0, 'discount_calculated_amount': 0.0, 'line_total': 2400000.0,
    });
    await db.insert('invoice_items', {
      'invoice_id': inv1Id, 'product_id': 3, 'product_name': 'کیبورد مکانیکال ردراگون',
      'unit_price': 3500000.0, 'quantity': 2.0, 'discount_type': 'amount',
      'discount_value': 150000.0, 'discount_calculated_amount': 150000.0, 'line_total': 6850000.0,
    });

    // Invoice 2: Pending
    final inv2Id = await db.insert('invoices', {
      'invoice_number': 'INV-0506-0002',
      'customer_id': 3,
      'date': DateTime(2026, 8, 25).toIso8601String(),
      'status': 'در انتظار پرداخت',
      'total_gross': 36000000.0,
      'total_discount': 1800000.0,
      'total_net': 34200000.0,
      'notes': '',
    });
    await db.insert('invoice_items', {
      'invoice_id': inv2Id, 'product_id': 4, 'product_name': 'مانیتور سامسونگ 27 اینچ',
      'unit_price': 18000000.0, 'quantity': 2.0, 'discount_type': 'percentage',
      'discount_value': 5.0, 'discount_calculated_amount': 1800000.0, 'line_total': 34200000.0,
    });

    // Invoice 3: Deposit
    final inv3Id = await db.insert('invoices', {
      'invoice_number': 'INV-0506-0003',
      'customer_id': 5,
      'date': DateTime(2026, 8, 28).toIso8601String(),
      'status': 'بیعانه',
      'total_gross': 26300000.0,
      'total_discount': 0.0,
      'total_net': 26300000.0,
      'notes': 'بیعانه 10 میلیون دریافت شد',
    });
    await db.insert('invoice_items', {
      'invoice_id': inv3Id, 'product_id': 5, 'product_name': 'هدفون بلوتوثی سونی',
      'unit_price': 8500000.0, 'quantity': 3.0, 'discount_type': 'none',
      'discount_value': 0.0, 'discount_calculated_amount': 0.0, 'line_total': 25500000.0,
    });
    await db.insert('invoice_items', {
      'invoice_id': inv3Id, 'product_id': 14, 'product_name': 'مشاوره فنی (ساعتی)',
      'unit_price': 800000.0, 'quantity': 1.0, 'discount_type': 'none',
      'discount_value': 0.0, 'discount_calculated_amount': 0.0, 'line_total': 800000.0,
    });

    // Invoice 4: Settled
    final inv4Id = await db.insert('invoices', {
      'invoice_number': 'INV-0506-0004',
      'customer_id': 2,
      'date': DateTime(2026, 8, 15).toIso8601String(),
      'status': 'تسویه شده',
      'total_gross': 6050000.0,
      'total_discount': 250000.0,
      'total_net': 5800000.0,
      'notes': '',
    });
    await db.insert('invoice_items', {
      'invoice_id': inv4Id, 'product_id': 7, 'product_name': 'هارد اکسترنال 1 ترابایت',
      'unit_price': 5200000.0, 'quantity': 1.0, 'discount_type': 'amount',
      'discount_value': 200000.0, 'discount_calculated_amount': 200000.0, 'line_total': 5000000.0,
    });
    await db.insert('invoice_items', {
      'invoice_id': inv4Id, 'product_id': 8, 'product_name': 'کابل شارژ تایپ سی',
      'unit_price': 250000.0, 'quantity': 2.0, 'discount_type': 'percentage',
      'discount_value': 10.0, 'discount_calculated_amount': 50000.0, 'line_total': 450000.0,
    });
    await db.insert('invoice_items', {
      'invoice_id': inv4Id, 'product_id': 6, 'product_name': 'فلش مموری 64 گیگ سن‌دیسک',
      'unit_price': 450000.0, 'quantity': 1.0, 'discount_type': 'none',
      'discount_value': 0.0, 'discount_calculated_amount': 0.0, 'line_total': 450000.0,
    });

    // Invoice 5: Cancelled
    await db.insert('invoices', {
      'invoice_number': 'INV-0506-0005',
      'customer_id': 4,
      'date': DateTime(2026, 8, 10).toIso8601String(),
      'status': 'لغو شده',
      'total_gross': 12500000.0,
      'total_discount': 0.0,
      'total_net': 12500000.0,
      'notes': 'مشتری انصراف داد',
    });
  }
}
