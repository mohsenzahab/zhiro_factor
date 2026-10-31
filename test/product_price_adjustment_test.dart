import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_box/core/database/app_database.dart';
import 'package:sales_box/core/extensions/number_extensions.dart';
import 'package:sales_box/data/models/product_model.dart';
import 'package:sales_box/data/repositories/product_repository.dart';
import 'package:sales_box/features/products/cubit/product_cubit.dart';
import 'package:sales_box/features/products/cubit/product_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Batch Price Adjustment - Calculation & Business Logic Tests', () {
    test('Product without currentBuyPrice applies percentage to buyPrice and sets currentBuyPrice', () {
      final product = ProductModel(
        id: 1,
        name: 'کابل HDMI',
        unit: 'عدد',
        buyPrice: 100000,
        currentBuyPrice: null,
        sellPrice: 120000, // 20% profit margin
      );

      const percentage = 10.0; // +10%

      // 1. Base buy price is buyPrice
      final baseBuyPrice = (product.currentBuyPrice != null && product.currentBuyPrice! > 0)
          ? product.currentBuyPrice!
          : product.buyPrice;
      expect(baseBuyPrice, equals(100000.0));

      // 2. New current buy price = 100,000 * 1.1 = 110,000
      final newCurrentBuy = (baseBuyPrice * (1 + percentage / 100.0)).roundToDouble();
      expect(newCurrentBuy, equals(110000.0));

      // 3. Sell price recalculated using previous profit margin (20%) on new current buy price:
      // profitRatio = 120,000 / 100,000 = 1.2
      // rawNewSell = 110,000 * 1.2 = 132,000
      // 132,000.roundTo5000 = 130,000
      final profitRatio = product.sellPrice! / baseBuyPrice;
      final rawNewSell = newCurrentBuy * profitRatio;
      final newSellPrice = rawNewSell.roundTo5000;
      expect(newSellPrice, equals(130000.0));

      // 4. Verify initial buyPrice remains untouched
      expect(product.buyPrice, equals(100000.0));
    });

    test('Product with existing currentBuyPrice applies percentage to currentBuyPrice', () {
      final product = ProductModel(
        id: 2,
        name: 'موس بی‌سیم',
        unit: 'عدد',
        buyPrice: 80000,
        currentBuyPrice: 100000,
        sellPrice: 130000, // 30% profit margin relative to 100,000
      );

      const percentage = 10.0; // +10%

      final baseBuyPrice = (product.currentBuyPrice != null && product.currentBuyPrice! > 0)
          ? product.currentBuyPrice!
          : product.buyPrice;
      expect(baseBuyPrice, equals(100000.0));

      // New current buy price = 100,000 * 1.1 = 110,000
      final newCurrentBuy = (baseBuyPrice * (1 + percentage / 100.0)).roundToDouble();
      expect(newCurrentBuy, equals(110000.0));

      // Recalculated sell price: 110,000 * (130,000 / 100,000) = 110,000 * 1.3 = 143,000
      // 143,000.roundTo5000 = 145,000
      final profitRatio = product.sellPrice! / baseBuyPrice;
      final rawNewSell = newCurrentBuy * profitRatio;
      final newSellPrice = rawNewSell.roundTo5000;
      expect(newSellPrice, equals(145000.0));

      // Initial buyPrice stays 80,000
      expect(product.buyPrice, equals(80000.0));
    });

    test('Negative percentage reduces price and recalculates sell price accordingly', () {
      final product = ProductModel(
        id: 3,
        name: 'پد موس',
        unit: 'عدد',
        buyPrice: 100000,
        currentBuyPrice: null,
        sellPrice: 120000, // 20% profit margin
      );

      const percentage = -10.0; // -10% decrease

      final baseBuyPrice = product.effectiveBuyPrice;
      final newCurrentBuy = (baseBuyPrice * (1 + percentage / 100.0)).roundToDouble();
      expect(newCurrentBuy, equals(90000.0));

      // rawNewSell = 90,000 * 1.2 = 108,000
      // 108,000.roundTo5000 = 110,000
      final profitRatio = product.sellPrice! / baseBuyPrice;
      final rawNewSell = newCurrentBuy * profitRatio;
      final newSellPrice = rawNewSell.roundTo5000;
      expect(newSellPrice, equals(110000.0));
    });

    test('Product without sellPrice leaves sellPrice null after price adjustment', () {
      final product = ProductModel(
        id: 4,
        name: 'سیم لحیم',
        unit: 'متر',
        buyPrice: 50000,
        currentBuyPrice: null,
        sellPrice: null,
      );

      const percentage = 20.0;
      final baseBuyPrice = product.effectiveBuyPrice;
      final newCurrentBuy = (baseBuyPrice * (1 + percentage / 100.0)).roundToDouble();
      expect(newCurrentBuy, equals(60000.0));

      double? newSellPrice = product.sellPrice;
      if (product.sellPrice != null && product.sellPrice! > 0) {
        final profitRatio = product.sellPrice! / baseBuyPrice;
        newSellPrice = (newCurrentBuy * profitRatio).roundTo5000;
      }
      expect(newSellPrice, isNull);
    });
  });

  group('SQLite In-Memory Integration - bulkApplyPriceAdjustment', () {
    late AppDatabase db;
    late ProductRepository repository;

    setUp(() async {
      db = AppDatabase.memory();

      // Seed 4 test products
      // 1. Initial buy 100,000, no current buy, sell 120,000 (cat: جانبی)
      await db.into(db.products).insert(ProductsCompanion.insert(
        id: const Value(1),
        code: const Value('P1'),
        name: 'کابل تایپ سی',
        category: const Value('جانبی'),
        buyPrice: 100000.0,
        sellPrice: const Value(120000.0),
        unit: 'عدد',
      ));
      // 2. Initial buy 80,000, current buy 100,000, sell 130,000 (cat: جانبی)
      await db.into(db.products).insert(ProductsCompanion.insert(
        id: const Value(2),
        code: const Value('P2'),
        name: 'کیبورد',
        category: const Value('جانبی'),
        buyPrice: 80000.0,
        currentBuyPrice: const Value(100000.0),
        sellPrice: const Value(130000.0),
        unit: 'عدد',
      ));
      // 3. Initial buy 200,000, no current buy, sell 250,000 (cat: سخت‌افزار)
      await db.into(db.products).insert(ProductsCompanion.insert(
        id: const Value(3),
        code: const Value('P3'),
        name: 'رم ۸ گیگ',
        category: const Value('سخت‌افزار'),
        buyPrice: 200000.0,
        sellPrice: const Value(250000.0),
        unit: 'عدد',
      ));
      // 4. Initial buy 50,000, no current buy, no sell price (uncategorized)
      await db.into(db.products).insert(ProductsCompanion.insert(
        id: const Value(4),
        code: const Value('P4'),
        name: 'پیچ قاب',
        buyPrice: 50000.0,
        unit: 'بسته',
      ));

      repository = ProductRepository(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Applies percentage to specific productIds only', () async {
      // Apply +10% to product 1 only
      final updated = await repository.bulkApplyPriceAdjustment(10.0, productIds: [1]);
      expect(updated, equals(1));

      final p1 = await repository.getById(1);
      expect(p1!.buyPrice, equals(100000.0)); // original preserved
      expect(p1.currentBuyPrice, equals(110000.0)); // adjusted price stored in currentBuyPrice
      expect(p1.sellPrice, equals(130000.0)); // 110,000 * 1.2 = 132,000 -> rounded to 130,000

      // Product 2 must be untouched
      final p2 = await repository.getById(2);
      expect(p2!.currentBuyPrice, equals(100000.0));
      expect(p2.sellPrice, equals(130000.0));
    });

    test('Applies percentage to specific category only', () async {
      // Apply +10% to category 'جانبی' (products 1 and 2)
      final updated = await repository.bulkApplyPriceAdjustment(10.0, category: 'جانبی');
      expect(updated, equals(2));

      final p1 = await repository.getById(1);
      expect(p1!.currentBuyPrice, equals(110000.0));
      expect(p1.sellPrice, equals(130000.0));

      final p2 = await repository.getById(2);
      expect(p2!.buyPrice, equals(80000.0));
      expect(p2.currentBuyPrice, equals(110000.0)); // 100,000 * 1.1
      expect(p2.sellPrice, equals(145000.0)); // 110,000 * 1.3 = 143,000 -> rounded to 145,000

      // Product 3 in 'سخت‌افزار' must NOT be changed
      final p3 = await repository.getById(3);
      expect(p3!.currentBuyPrice, isNull);
      expect(p3.sellPrice, equals(250000.0));
    });

    test('Applies percentage to uncategorized products', () async {
      // Apply +20% to __uncategorized__ (product 4)
      final updated = await repository.bulkApplyPriceAdjustment(20.0, category: '__uncategorized__');
      expect(updated, equals(1));

      final p4 = await repository.getById(4);
      expect(p4!.buyPrice, equals(50000.0));
      expect(p4.currentBuyPrice, equals(60000.0));
      expect(p4.sellPrice, isNull); // still null
    });

    test('Applies price decrease (-10%) to all products', () async {
      final updated = await repository.bulkApplyPriceAdjustment(-10.0);
      expect(updated, equals(4));

      final p1 = await repository.getById(1);
      expect(p1!.currentBuyPrice, equals(90000.0));
      expect(p1.sellPrice, equals(110000.0)); // 90,000 * 1.2 = 108,000 -> 110,000

      final p2 = await repository.getById(2);
      expect(p2!.currentBuyPrice, equals(90000.0)); // 100,000 * 0.9 = 90,000
      expect(p2.sellPrice, equals(115000.0)); // 90,000 * 1.3 = 117,000 -> 115,000

      final p3 = await repository.getById(3);
      expect(p3!.currentBuyPrice, equals(180000.0)); // 200,000 * 0.9 = 180,000
      // 180,000 * (250,000 / 200,000) = 180,000 * 1.25 = 225,000 -> 225,000
      expect(p3.sellPrice, equals(225000.0));
    });
  });

  group('ProductCubit Integration - applyPriceAdjustment', () {
    late AppDatabase db;
    late ProductRepository repository;

    setUp(() async {
      db = AppDatabase.memory();

      await db.into(db.products).insert(ProductsCompanion.insert(
        id: const Value(1),
        code: const Value('P1'),
        name: 'روغن موتور توتال',
        category: const Value('روغن'),
        buyPrice: 100000.0,
        sellPrice: const Value(130000.0),
        unit: 'لیتر',
      ));

      repository = ProductRepository(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Cubit applyPriceAdjustment updates products and preserves active search query', () async {
      final cubit = ProductCubit(repository: repository);
      await cubit.loadProducts(query: 'توتال');

      expect(cubit.state, isA<ProductLoaded>());
      final initialLoaded = cubit.state as ProductLoaded;
      expect(initialLoaded.searchQuery, equals('توتال'));
      expect(initialLoaded.products.length, equals(1));

      final updatedCount = await cubit.applyPriceAdjustment(10.0, productIds: [1]);
      expect(updatedCount, equals(1));

      expect(cubit.state, isA<ProductLoaded>());
      final updatedLoaded = cubit.state as ProductLoaded;
      expect(updatedLoaded.searchQuery, equals('توتال'));
      expect(updatedLoaded.products.first.currentBuyPrice, equals(110000.0));
      expect(updatedLoaded.products.first.sellPrice, equals(145000.0));
    });
  });
}
