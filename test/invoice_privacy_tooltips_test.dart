import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_box/data/models/invoice_item_model.dart';
import 'package:sales_box/features/invoice/cubit/invoice_state.dart';
import 'package:sales_box/shared/widgets/privacy_tooltip.dart';

void main() {
  group('Privacy Tooltip & Profit Calculation Tests', () {
    test('PrivacyTooltip default waitDuration is 1.2 seconds for privacy protection', () {
      const tooltip = PrivacyTooltip(
        message: 'دسته‌بندی: نوشیدنی',
        child: Text('آبمیوه'),
      );
      expect(tooltip.waitDuration, equals(const Duration(milliseconds: 1200)));
    });

    test('InvoiceState profit calculations compute cost, profit, and percentage correctly', () {
      const items = [
        InvoiceItemModel(
          id: 1,
          productName: 'کالای ۱',
          unitPrice: 15000,
          purchasePrice: 10000,
          quantity: 2,
          lineTotal: 30000,
        ),
        InvoiceItemModel(
          id: 2,
          productName: 'کالای ۲',
          unitPrice: 20000,
          purchasePrice: 12000,
          quantity: 1,
          lineTotal: 20000,
        ),
      ];

      // totalGross = 50,000, totalCost = 10,000*2 + 12,000 = 32,000
      // totalNet = 50,000, totalProfit = 18,000
      // totalProfitPercentage = (18,000 / 32,000) * 100 = 56.25%
      const state = InvoiceState(
        items: items,
        overallDiscountType: 'none',
        overallDiscountValue: 0,
      );

      expect(state.totalGross, equals(50000.0));
      expect(state.totalCost, equals(32000.0));
      expect(state.totalProfit, equals(18000.0));
      expect(state.totalProfitPercentage, closeTo(56.25, 0.01));
    });

    test('InvoiceState profit calculations with invoice-level discount', () {
      const items = [
        InvoiceItemModel(
          id: 1,
          productName: 'کالا',
          unitPrice: 10000,
          purchasePrice: 6000,
          quantity: 1,
          lineTotal: 10000,
        ),
      ];

      // Discount: 2000 toman fixed discount
      // totalNet = 8000, cost = 6000, profit = 2000
      // profitPercentage = (2000 / 6000) * 100 = 33.33%
      const state = InvoiceState(
        items: items,
        overallDiscountType: 'amount',
        overallDiscountValue: 2000,
      );

      expect(state.totalNet, equals(8000.0));
      expect(state.totalCost, equals(6000.0));
      expect(state.totalProfit, equals(2000.0));
      expect(state.totalProfitPercentage, closeTo(33.33, 0.01));
    });

    testWidgets('PrivacyTooltip renders in widget tree and wraps child with Tooltip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrivacyTooltip(
              message: 'اطلاعات محرمانه سود',
              child: Text('قیمت کالا'),
            ),
          ),
        ),
      );

      expect(find.text('قیمت کالا'), findsOneWidget);
      final tooltipFinder = find.byType(Tooltip);
      expect(tooltipFinder, findsOneWidget);

      final tooltipWidget = tester.widget<Tooltip>(tooltipFinder);
      expect(tooltipWidget.message, equals('اطلاعات محرمانه سود'));
      expect(tooltipWidget.waitDuration, equals(const Duration(milliseconds: 1200)));
    });
  });
}
