import 'package:flutter_test/flutter_test.dart';
import 'package:sales_box/data/models/demand_model.dart';
import 'package:sales_box/features/demands/cubit/demand_state.dart';

void main() {
  group('DemandModel Tests', () {
    test('Calculates capital, profit, and margin correctly', () {
      final demand = DemandModel(
        id: 1,
        title: 'کابل HDMI ۵ متری',
        category: 'الکترونیک',
        buyPrice: 80000,
        sellPrice: 120000,
        targetQuantity: 5,
        status: DemandModel.statusPending,
        requestDates: const ['2026-09-01T10:00:00Z', '2026-09-15T12:00:00Z', '2026-10-01T14:00:00Z'],
      );

      // Capital: 80,000 * 5 = 400,000
      expect(demand.requiredCapital, equals(400000.0));
      // Unit profit: 120,000 - 80,000 = 40,000
      expect(demand.unitProfit, equals(40000.0));
      // Total projected profit: 40,000 * 5 = 200,000
      expect(demand.totalProjectedProfit, equals(200000.0));
      // Margin: (40,000 / 80,000) * 100 = 50%
      expect(demand.profitMargin, equals(50.0));
      // Request count: 3
      expect(demand.requestCount, equals(3));
      // First and latest request dates
      expect(demand.firstRequestDate, equals('2026-09-01T10:00:00Z'));
      expect(demand.latestRequestDate, equals('2026-10-01T14:00:00Z'));
    });

    test('Handles optional buyPrice and sellPrice gracefully', () {
      final demand = DemandModel(
        id: 2,
        title: 'خدمت تعمیر پاور کامپیوتر',
        status: DemandModel.statusInPreparation,
        targetQuantity: 1,
        requestDates: const ['2026-10-10T12:00:00Z'],
      );

      expect(demand.buyPrice, isNull);
      expect(demand.sellPrice, isNull);
      expect(demand.requiredCapital, equals(0.0));
      expect(demand.unitProfit, isNull);
      expect(demand.totalProjectedProfit, isNull);
      expect(demand.profitMargin, isNull);
      expect(demand.requestCount, equals(1));
    });

    test('Serialization toMap and fromMap works accurately', () {
      final demand = DemandModel(
        id: 10,
        title: 'اسپری روان‌کننده WD-40',
        category: 'ابزار',
        buyPrice: 50000,
        sellPrice: 75000,
        status: DemandModel.statusProcured,
        targetQuantity: 3,
        notes: 'مشتری متقاضی: آقای احمدی',
        requestDates: const ['2026-10-01T08:00:00Z', '2026-10-05T09:00:00Z'],
      );

      final map = demand.toMap();
      expect(map['title'], equals('اسپری روان‌کننده WD-40'));
      expect(map['category'], equals('ابزار'));
      expect(map['buy_price'], equals(50000.0));
      expect(map['sell_price'], equals(75000.0));
      expect(map['status'], equals(DemandModel.statusProcured));
      expect(map['target_quantity'], equals(3.0));
      expect(map['notes'], equals('مشتری متقاضی: آقای احمدی'));

      final restored = DemandModel.fromMap(map, requestDates: demand.requestDates);
      expect(restored.title, equals(demand.title));
      expect(restored.requestCount, equals(2));
      expect(restored.status, equals(DemandModel.statusProcured));
    });
  });

  group('DemandState KPI Calculations Tests', () {
    test('Calculates total capital and projected profit for active demands only', () {
      final demands = [
        DemandModel(
          id: 1,
          title: 'مورد ۱ (تهیه نشده)',
          buyPrice: 10000,
          sellPrice: 15000,
          targetQuantity: 2,
          status: DemandModel.statusPending,
          requestDates: const ['2026-10-01T10:00:00Z', '2026-10-02T10:00:00Z'],
        ),
        DemandModel(
          id: 2,
          title: 'مورد ۲ (در حال تهیه)',
          buyPrice: 20000,
          sellPrice: 30000,
          targetQuantity: 3,
          status: DemandModel.statusInPreparation,
          requestDates: const ['2026-10-03T10:00:00Z'],
        ),
        DemandModel(
          id: 3,
          title: 'مورد ۳ (تهیه شده)',
          buyPrice: 50000,
          sellPrice: 80000,
          targetQuantity: 1,
          status: DemandModel.statusProcured,
          requestDates: const ['2026-09-01T10:00:00Z'],
        ),
      ];

      final state = DemandState(demands: demands);

      expect(state.totalDemandsCount, equals(3));
      expect(state.totalRequestsCount, equals(4)); // 2 + 1 + 1

      // Active demands = item 1 & item 2 (pending + inPreparation)
      expect(state.activeDemands.length, equals(2));

      // Capital: (10,000 * 2) + (20,000 * 3) = 20,000 + 60,000 = 80,000 (excludes item 3 which is procured)
      expect(state.totalRequiredCapital, equals(80000.0));

      // Projected Profit: (5,000 * 2) + (10,000 * 3) = 10,000 + 30,000 = 40,000
      expect(state.totalProjectedProfit, equals(40000.0));

      // Top demanded item = item 1 (2 requests)
      expect(state.topDemandedItem?.id, equals(1));

      // Status counts
      expect(state.pendingCount, equals(1));
      expect(state.inPreparationCount, equals(1));
      expect(state.procuredCount, equals(1));
    });
  });
}
