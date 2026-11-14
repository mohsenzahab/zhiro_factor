import 'package:flutter_test/flutter_test.dart';
import 'package:sales_box/features/dashboard/cubit/dashboard_state.dart';

void main() {
  group('DashboardState Profit Calculations', () {
    test('Calculates profit percentages correctly when buy costs are identical', () {
      const state = DashboardState(
        totalGross: 125000.0,
        totalProfit: 25000.0,
        totalInitialBuyCost: 100000.0,
        totalCurrentBuyCost: 100000.0,
      );

      expect(state.profitPercentOfCost, closeTo(25.0, 0.001));
      expect(state.profitPercentOfSales, closeTo(20.0, 0.001));
      expect(state.totalCurrentProfit, equals(25000.0));
      expect(state.profitPercentOfCurrentCost, closeTo(25.0, 0.001));
    });

    test('Calculates replacement profit and current markup when buy costs differ', () {
      const state = DashboardState(
        totalGross: 150000.0,
        totalProfit: 50000.0, // Sold at 150k, bought historically at 100k
        totalInitialBuyCost: 100000.0,
        totalCurrentBuyCost: 120000.0, // Replacement buy cost is now 120k
      );

      // Historical markup: 50,000 / 100,000 = 50%
      expect(state.profitPercentOfCost, closeTo(50.0, 0.001));

      // Margin on sales: 50,000 / 150,000 = 33.333%
      expect(state.profitPercentOfSales, closeTo(33.333, 0.01));

      // Replacement profit: (50,000 + 100,000) - 120,000 = 30,000
      expect(state.totalCurrentProfit, equals(30000.0));

      // Current markup: 30,000 / 120,000 = 25%
      expect(state.profitPercentOfCurrentCost, closeTo(25.0, 0.001));
    });

    test('Handles zero buy costs gracefully without division by zero', () {
      const state = DashboardState(
        totalGross: 50000.0,
        totalProfit: 50000.0,
        totalInitialBuyCost: 0.0,
        totalCurrentBuyCost: 0.0,
      );

      expect(state.profitPercentOfCost, equals(0.0));
      expect(state.profitPercentOfCurrentCost, equals(0.0));
      expect(state.totalCurrentProfit, equals(50000.0));
      expect(state.profitPercentOfSales, equals(100.0));
    });
  });
}

