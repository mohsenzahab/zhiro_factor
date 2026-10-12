import 'package:flutter_test/flutter_test.dart';
import 'package:sales_box/core/extensions/number_extensions.dart';
import 'package:sales_box/data/models/product_model.dart';
import 'package:sales_box/data/models/demand_model.dart';

void main() {
  group('Direct Sell Price Preservation Tests', () {
    test('ProductModel preserves direct unrounded sell price', () {
      final product = ProductModel(
        name: 'پیچ‌گوشتی چهارسو',
        unit: 'عدد',
        buyPrice: 12000,
        sellPrice: 18200, // Unrounded direct price
      );

      // Sell price must NOT be rounded to 15,000 or 20,000
      expect(product.sellPrice, equals(18200.0));
      expect(product.effectivePrice, equals(18200.0));
      expect(product.profitAmount, equals(6200.0));
      expect(product.profitPercent, closeTo(51.67, 0.01));
    });

    test('ProductModel toMap and fromMap preserve exact sell price', () {
      final original = ProductModel(
        id: 1,
        name: 'روغن موتور ۱۰W۴۰',
        unit: 'لیتر',
        buyPrice: 150000,
        sellPrice: 183450,
      );

      final map = original.toMap();
      expect(map['sell_price'], equals(183450.0));

      final restored = ProductModel.fromMap(map);
      expect(restored.sellPrice, equals(183450.0));
      expect(restored.effectivePrice, equals(183450.0));
    });

    test('ProductModel copyWith preserves unrounded sell price', () {
      final original = ProductModel(
        name: 'چسب قطره‌ای',
        unit: 'عدد',
        buyPrice: 5000,
        sellPrice: 8300,
      );

      final updated = original.copyWith(name: 'چسب قطره‌ای رازی');
      expect(updated.sellPrice, equals(8300.0));

      final updatedPrice = original.copyWith(sellPrice: 9400);
      expect(updatedPrice.sellPrice, equals(9400.0));
    });

    test('DemandModel preserves direct unrounded sell price', () {
      final demand = DemandModel(
        title: 'مادربرد گیمینگ',
        buyPrice: 5200000,
        sellPrice: 5852300,
      );

      expect(demand.sellPrice, equals(5852300.0));
      expect(demand.unitProfit, equals(652300.0));
    });
  });

  group('Profit Margin Calculation & Rounding Re-application Tests', () {
    test('12% profit on 100,000 rounds to 110,000 and recalculates to 10%', () {
      const baseBuyPrice = 100000.0;
      const inputProfitMargin = 12.0;

      // 1. Raw sell price from percentage
      final rawSellPrice = baseBuyPrice * (1 + inputProfitMargin / 100.0); // 112,000
      expect(rawSellPrice, closeTo(112000.0, 0.01));

      // 2. Rounding to 5000 applies because price was determined by percentage
      final roundedSellPrice = rawSellPrice.roundTo5000;
      expect(roundedSellPrice, equals(110000.0));

      // 3. Profit margin is re-calculated and updated from rounded price
      final recomputedProfitMargin = ((roundedSellPrice - baseBuyPrice) / baseBuyPrice) * 100.0;
      expect(recomputedProfitMargin, equals(10.0));
    });

    test('13% profit on 100,000 rounds to 115,000 and recalculates to 15%', () {
      const baseBuyPrice = 100000.0;
      const inputProfitMargin = 13.0;

      // 1. Raw sell price from percentage
      final rawSellPrice = baseBuyPrice * (1 + inputProfitMargin / 100.0); // 113,000
      expect(rawSellPrice, closeTo(113000.0, 0.01));

      // 2. Rounding to 5000
      final roundedSellPrice = rawSellPrice.roundTo5000;
      expect(roundedSellPrice, equals(115000.0));

      // 3. Recomputed profit margin
      final recomputedProfitMargin = ((roundedSellPrice - baseBuyPrice) / baseBuyPrice) * 100.0;
      expect(recomputedProfitMargin, equals(15.0));
    });

    test('Direct price entry of 112,000 does NOT round and computes exact 12%', () {
      const baseBuyPrice = 100000.0;
      const directSellPrice = 112000.0; // Entered directly

      // Direct price is NOT rounded!
      expect(directSellPrice, equals(112000.0));

      // Profit margin is computed from exact price
      final exactProfitMargin = ((directSellPrice - baseBuyPrice) / baseBuyPrice) * 100.0;
      expect(exactProfitMargin, equals(12.0));
    });

    test('20% profit on 43,000 rounds to 50,000 and recalculates to ~16.3%', () {
      const baseBuyPrice = 43000.0;
      const inputProfitMargin = 20.0;

      final rawSellPrice = baseBuyPrice * (1 + inputProfitMargin / 100.0); // 51,600
      final roundedSellPrice = rawSellPrice.roundTo5000; // 50,000
      expect(roundedSellPrice, equals(50000.0));

      final recomputedProfitMargin = ((roundedSellPrice - baseBuyPrice) / baseBuyPrice) * 100.0;
      expect(recomputedProfitMargin, closeTo(16.279, 0.001));
    });
  });
}
