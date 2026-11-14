import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_box/core/database/app_database.dart';
import 'package:sales_box/data/models/invoice_model.dart';
import 'package:sales_box/data/models/invoice_item_model.dart';
import 'package:sales_box/data/repositories/invoice_repository.dart';
import 'package:sales_box/data/repositories/product_repository.dart';
import 'package:sales_box/data/repositories/report_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase db;
  late ProductRepository productRepo;
  late InvoiceRepository invoiceRepo;
  late ReportRepository reportRepo;

  setUp(() async {
    db = AppDatabase.memory();
    productRepo = ProductRepository(db: db);
    invoiceRepo = InvoiceRepository(db: db);
    reportRepo = ReportRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Price increases do not distort profit calculations of past sales in dashboard and invoice history', () async {
    // 1. Create a product with buyPrice: 10,000 and sellPrice: 16,000
    final productId = await db.into(db.products).insert(
          ProductsCompanion.insert(
            name: 'کالای تست سود',
            unit: 'عدد',
            buyPrice: 10000.0,
            sellPrice: const Value(16000.0),
            stock: const Value(100.0),
          ),
        );

    // 2. Sell 2 units in an invoice (revenue: 32,000, buy cost: 20,000 -> profit: 12,000)
    final invoice = InvoiceModel(
      invoiceNumber: 'INV-TEST-001',
      date: '2026-05-01T10:00:00.000',
      status: 'تسویه شده',
      totalGross: 32000.0,
      totalDiscount: 0.0,
      totalNet: 32000.0,
      items: [
        InvoiceItemModel(
          productId: productId,
          productName: 'کالای تست سود',
          unitPrice: 16000.0,
          purchasePrice: 10000.0, // Purchase price at time of sale
          quantity: 2.0,
          lineTotal: 32000.0,
        ),
      ],
    );

    await invoiceRepo.insert(invoice);

    // 3. Verify initial profit calculations
    final profitBefore = await reportRepo.totalNetProfit();
    expect(profitBefore, equals(12000.0));

    final costsBefore = await reportRepo.totalBuyCosts();
    expect(costsBefore.initialCost, equals(20000.0));
    expect(costsBefore.currentCost, equals(20000.0));

    final ledgerBefore = await reportRepo.salesLedger();
    expect(ledgerBefore.first['profit'], equals(12000.0));

    final invoicesBefore = await invoiceRepo.getAll();
    expect(invoicesBefore.first.totalProfitAmount, equals(12000.0));

    final salesHistoryBefore = await invoiceRepo.getProductSales(productId);
    expect(salesHistoryBefore.first.profitAmount, equals(12000.0));

    // 4. NOW INCREASE PRODUCT PRICE by +50% (current buy price becomes 15,000, sell price becomes 24,000)
    final affectedCount = await productRepo.bulkApplyPriceAdjustment(50.0, productIds: [productId]);
    expect(affectedCount, equals(1));

    final updatedProduct = await productRepo.getById(productId);
    expect(updatedProduct?.currentBuyPrice, equals(15000.0));
    expect(updatedProduct?.buyPrice, equals(10000.0)); // original buy price untouched

    // 5. VERIFY THAT PAST PROFITS REMAIN 100% UNTOUCHED AND ACCURATE!

    // Dashboard Total Net Profit MUST STILL BE 12,000 (NOT 32,000 - 30,000 = 2,000!)
    final profitAfter = await reportRepo.totalNetProfit();
    expect(profitAfter, equals(12000.0), reason: 'Dashboard profit must reflect historical purchase cost');

    // Dashboard Buy Costs:
    // initialCost (actual cost) must remain 20,000!
    // currentCost (replacement cost) reflects today price 30,000!
    final costsAfter = await reportRepo.totalBuyCosts();
    expect(costsAfter.initialCost, equals(20000.0), reason: 'Actual purchase cost of past sales must remain 20,000');
    expect(costsAfter.currentCost, equals(30000.0), reason: 'Replacement cost is 30,000');

    // Sales Ledger Table profit must remain 12,000!
    final ledgerAfter = await reportRepo.salesLedger();
    expect(ledgerAfter.first['profit'], equals(12000.0), reason: 'Ledger profit row must remain 12,000');

    // Ledger Summary total profit must remain 12,000!
    final summaryAfter = await reportRepo.ledgerSummary();
    expect(summaryAfter['total_profit'], equals(12000.0));

    // Invoice History invoice profit must remain 12,000!
    final invoicesAfter = await invoiceRepo.getAll();
    expect(invoicesAfter.first.totalProfitAmount, equals(12000.0));
    expect(invoicesAfter.first.items.first.purchasePrice, equals(10000.0));

    // Product Sales History must remain 12,000!
    final salesHistoryAfter = await invoiceRepo.getProductSales(productId);
    expect(salesHistoryAfter.first.profitAmount, equals(12000.0));
    expect(salesHistoryAfter.first.purchasePrice, equals(10000.0));
  });

  test('Past sales without recorded purchase_price fallback to product buy_price instead of new current_buy_price', () async {
    // Legacy invoice item with purchase_price = 0
    final productId = await db.into(db.products).insert(
          ProductsCompanion.insert(
            name: 'کالای قدیمی',
            unit: 'عدد',
            buyPrice: 20000.0,
            sellPrice: const Value(30000.0),
            stock: const Value(50.0),
          ),
        );

    final invId = await db.into(db.invoices).insert(
          InvoicesCompanion.insert(
            invoiceNumber: 'INV-LEGACY-01',
            date: '2026-01-01T10:00:00.000',
            status: const Value('تسویه شده'),
            totalGross: 30000.0,
            totalDiscount: 0.0,
            totalNet: 30000.0,
          ),
        );

    await db.into(db.invoiceItems).insert(
          InvoiceItemsCompanion.insert(
            invoiceId: invId,
            productId: Value(productId),
            productName: 'کالای قدیمی',
            unitPrice: 30000.0,
            purchasePrice: const Value(0.0), // Unrecorded / legacy
            quantity: const Value(1.0),
            lineTotal: 30000.0,
          ),
        );

    // Increase product price by 100% -> currentBuyPrice becomes 40,000
    await productRepo.bulkApplyPriceAdjustment(100.0, productIds: [productId]);

    // Profit must fall back to original buyPrice (20,000), giving 30,000 - 20,000 = 10,000 profit
    // It must NOT use currentBuyPrice (40,000), which would produce -10,000 profit!
    final profit = await reportRepo.totalNetProfit();
    expect(profit, equals(10000.0));

    final ledger = await reportRepo.salesLedger();
    expect(ledger.first['profit'], equals(10000.0));

    final invoices = await invoiceRepo.getAll();
    expect(invoices.first.totalProfitAmount, equals(10000.0));

    final history = await invoiceRepo.getProductSales(productId);
    expect(history.first.profitAmount, equals(10000.0));
  });
}
