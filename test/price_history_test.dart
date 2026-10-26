import 'package:flutter_test/flutter_test.dart';
import 'package:sales_box/data/models/price_change_model.dart';
import 'package:sales_box/features/products/cubit/price_history_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('PriceChangeModel Tests', () {
    test('Calculates positive percentage correctly', () {
      final model = PriceChangeModel(
        id: 1,
        productId: 10,
        oldPrice: 100000,
        newPrice: 120000,
        changeAmount: 20000,
        changeType: 'manual',
        createdAt: '2026-05-10T10:00:00.000',
      );

      expect(model.changePercent, equals(20.0));
      expect(model.isIncrease, isTrue);
      expect(model.isDecrease, isFalse);
      expect(model.changePercentDisplay, contains('۲۰٪'));
      expect(model.changeAmountDisplay, contains('۲۰,۰۰۰'));
      expect(model.changeTypeDisplay, equals('ویرایش دستی'));
    });

    test('Calculates negative percentage correctly', () {
      final model = PriceChangeModel(
        id: 2,
        productId: 10,
        oldPrice: 200000,
        newPrice: 170000,
        changeAmount: -30000,
        changeType: 'batch_adjustment',
        createdAt: '2026-05-10T10:00:00.000',
      );

      expect(model.changePercent, equals(-15.0));
      expect(model.isIncrease, isFalse);
      expect(model.isDecrease, isTrue);
      expect(model.changePercentDisplay, contains('-۱۵٪'));
      expect(model.changeAmountDisplay, contains('-۳۰,۰۰۰'));
      expect(model.changeTypeDisplay, equals('تغییر گروهی'));
    });

    test('Handles oldPrice 0 safely without division by zero', () {
      final model = PriceChangeModel(
        id: 3,
        productId: 10,
        oldPrice: 0,
        newPrice: 50000,
        changeAmount: 50000,
        changeType: 'manual',
        createdAt: '2026-05-10T10:00:00.000',
      );

      expect(model.changePercent, equals(0.0));
      expect(model.isIncrease, isTrue);
    });

    test('Serializes to and from map correctly', () {
      final model = PriceChangeModel(
        id: 5,
        productId: 20,
        productName: 'روغن موتور',
        productCode: 'OIL-1',
        category: 'روان‌کننده‌ها',
        oldPrice: 450000,
        newPrice: 500000,
        changeAmount: 50000,
        changeType: 'purchase',
        changeSource: 'فاکتور خرید P-100',
        createdAt: '2026-05-10T10:00:00.000',
      );

      final map = model.toMap();
      expect(map['product_id'], equals(20));
      expect(map['old_price'], equals(450000.0));
      expect(map['new_price'], equals(500000.0));
      expect(map['change_amount'], equals(50000.0));
      expect(map['change_type'], equals('purchase'));
      expect(map['change_source'], equals('فاکتور خرید P-100'));

      final restored = PriceChangeModel.fromMap({
        ...map,
        'product_name': 'روغن موتور',
        'product_code': 'OIL-1',
        'category': 'روان‌کننده‌ها',
      });
      expect(restored.productId, equals(20));
      expect(restored.productName, equals('روغن موتور'));
      expect(restored.changeSource, equals('فاکتور خرید P-100'));
    });
  });

  group('PriceHistoryCubit State & Filtering Tests', () {
    test('Sorts records ascending and descending across various columns', () {
      final records = [
        PriceChangeModel(
          id: 1,
          productId: 1,
          productName: 'ب',
          oldPrice: 100000,
          newPrice: 120000,
          changeAmount: 20000,
          changeType: 'manual',
          createdAt: '2026-01-01T00:00:00.000',
        ),
        PriceChangeModel(
          id: 2,
          productId: 2,
          productName: 'الف',
          oldPrice: 50000,
          newPrice: 80000,
          changeAmount: 30000,
          changeType: 'batch_adjustment',
          createdAt: '2026-01-02T00:00:00.000',
        ),
      ];

      // Sort by amount descending (default)
      var state = PriceHistoryLoaded(
        records: records,
        sortColumn: 'amount',
        isAscending: false,
      );
      expect(state.sortedRecords.first.id, equals(2)); // 30,000 > 20,000

      // Sort by amount ascending
      state = state.copyWith(isAscending: true);
      expect(state.sortedRecords.first.id, equals(1)); // 20,000 < 30,000

      // Sort by name ascending
      state = state.copyWith(sortColumn: 'name', isAscending: true);
      expect(state.sortedRecords.first.productName, equals('الف'));

      // Summary statistics
      expect(state.totalCount, equals(2));
      expect(state.maxIncreasePercent, greaterThan(0));
    });
  });
}
