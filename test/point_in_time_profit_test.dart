import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_box/core/database/app_database.dart';
import 'package:sales_box/data/models/invoice_model.dart';
import 'package:sales_box/data/models/invoice_item_model.dart';
import 'package:sales_box/data/models/purchase_model.dart';
import 'package:sales_box/data/models/purchase_item_model.dart';
import 'package:sales_box/data/repositories/invoice_repository.dart';
import 'package:sales_box/data/repositories/product_repository.dart';
import 'package:sales_box/data/repositories/purchase_repository.dart';
import 'package:sales_box/data/repositories/report_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late ProductRepository productRepo;
  late InvoiceRepository invoiceRepo;
  late PurchaseRepository purchaseRepo;
  late ReportRepository reportRepo;

  setUp(() async {
    db = AppDatabase.memory();
    productRepo = ProductRepository(db: db);
    invoiceRepo = InvoiceRepository(db: db);
    purchaseRepo = PurchaseRepository(db: db);
    reportRepo = ReportRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Point-in-time current buy price accurately compares price change vs purchase dates', () async {
    // 1. Create a product on 2026-01-01 with initial buyPrice: 10,000
    final productId = await db.into(db.products).insert(
          ProductsCompanion.insert(
            name: 'کالای تست تاریخچه',
            unit: 'عدد',
            buyPrice: 10000.0,
            sellPrice: const Value(20000.0),
            stock: const Value(100.0),
          ),
        );

    // 2. Sale 1 on 2026-02-01 (before any purchase or price change)
    // Cost at this date should be initial buyPrice: 10,000
    final priceAtSale1 = await productRepo.getEffectiveBuyPriceAtDate(productId, '2026-02-01T10:00:00.000');
    expect(priceAtSale1, equals(10000.0));

    // 3. Purchase on 2026-03-01 with unitPrice: 12,000
    await purchaseRepo.insert(
      PurchaseModel(
        purchaseNumber: 'PUR-001',
        date: '2026-03-01T10:00:00.000',
        status: 'تسویه شده',
        totalAmount: 120000.0,
        totalNet: 120000.0,
        items: [
          const PurchaseItemModel(
            productId: 1,
            productName: 'کالای تست تاریخچه',
            unitPrice: 12000.0,
            quantity: 10.0,
            lineTotal: 120000.0,
          ),
        ],
      ),
    );

    // Sale 2 on 2026-03-15 (after purchase at 12,000, before price change)
    // Cost at this date should be 12,000
    final priceAtSale2 = await productRepo.getEffectiveBuyPriceAtDate(productId, '2026-03-15T10:00:00.000');
    expect(priceAtSale2, equals(12000.0));

    // 4. Price change on 2026-04-01 to 15,000
    await db.into(db.priceChangeHistory).insert(
          PriceChangeHistoryCompanion.insert(
            productId: productId,
            oldPrice: 12000.0,
            newPrice: 15000.0,
            changeAmount: 3000.0,
            changeType: 'manual',
            createdAt: '2026-04-01T10:00:00.000',
          ),
        );

    // Sale 3 on 2026-04-15 (after price change at 15,000, since 2026-04-01 > 2026-03-01)
    // Cost at this date should be 15,000
    final priceAtSale3 = await productRepo.getEffectiveBuyPriceAtDate(productId, '2026-04-15T10:00:00.000');
    expect(priceAtSale3, equals(15000.0));

    // 5. Another purchase on 2026-05-01 with unitPrice: 14,000 (after the 15,000 price change)
    await purchaseRepo.insert(
      PurchaseModel(
        purchaseNumber: 'PUR-002',
        date: '2026-05-01T10:00:00.000',
        status: 'تسویه شده',
        totalAmount: 140000.0,
        totalNet: 140000.0,
        items: [
          const PurchaseItemModel(
            productId: 1,
            productName: 'کالای تست تاریخچه',
            unitPrice: 14000.0,
            quantity: 10.0,
            lineTotal: 140000.0,
          ),
        ],
      ),
    );

    // Sale 4 on 2026-05-15 (latest event is purchase on 2026-05-01 > price change on 2026-04-01)
    // Cost at this date should be 14,000
    final priceAtSale4 = await productRepo.getEffectiveBuyPriceAtDate(productId, '2026-05-15T10:00:00.000');
    expect(priceAtSale4, equals(14000.0));

    // 6. Verify totalBuyCosts in ReportRepository with invoices across these dates
    await invoiceRepo.insert(
      InvoiceModel(
        invoiceNumber: 'INV-1',
        date: '2026-02-01T10:00:00.000',
        status: 'تسویه شده',
        totalGross: 20000.0,
        totalDiscount: 0.0,
        totalNet: 20000.0,
        items: [
          const InvoiceItemModel(
            productId: 1,
            productName: 'کالای تست تاریخچه',
            unitPrice: 20000.0,
            purchasePrice: 10000.0,
            quantity: 1.0,
            lineTotal: 20000.0,
          ),
        ],
      ),
    );

    await invoiceRepo.insert(
      InvoiceModel(
        invoiceNumber: 'INV-3',
        date: '2026-04-15T10:00:00.000',
        status: 'تسویه شده',
        totalGross: 25000.0,
        totalDiscount: 0.0,
        totalNet: 25000.0,
        items: [
          const InvoiceItemModel(
            productId: 1,
            productName: 'کالای تست تاریخچه',
            unitPrice: 25000.0,
            purchasePrice: 12000.0, // Historical buy price at time of sale
            quantity: 1.0,
            lineTotal: 25000.0,
          ),
        ],
      ),
    );

    final costs = await reportRepo.totalBuyCosts();
    // INV-1 currentCost at 2026-02-01: 10,000
    // INV-3 currentCost at 2026-04-15: 15,000
    // Total currentCost = 25,000
    expect(costs.currentCost, equals(25000.0));
    // Initial costs: 10,000 + 12,000 = 22,000
    expect(costs.initialCost, equals(22000.0));
  });
}

