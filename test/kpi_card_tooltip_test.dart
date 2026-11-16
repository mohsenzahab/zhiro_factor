import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_box/core/constants/app_strings.dart';
import 'package:sales_box/features/dashboard/view/widgets/kpi_card.dart';

void main() {
  group('KpiCard Help Tooltip Tests', () {
    testWidgets('renders help button with exclamation icon when helpTooltip is provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KpiCard(
              label: 'فروش ناخالص',
              value: '۱,۰۰۰,۰۰۰ تومان',
              subtitle: 'تسویه‌شده',
              icon: Icons.receipt_long,
              gradient: LinearGradient(colors: [Colors.blue, Colors.indigo]),
              helpTooltip: AppStrings.grossSalesTooltip,
            ),
          ),
        ),
      );

      // Verify exclamation mark icon is present
      final iconFinder = find.byIcon(Icons.priority_high_rounded);
      expect(iconFinder, findsOneWidget);

      // Verify Tooltip widget exists
      final tooltipFinder = find.byType(Tooltip);
      expect(tooltipFinder, findsOneWidget);

      // Tap the help button
      await tester.tap(iconFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify tooltip opens and contains content from grossSalesTooltip
      expect(find.textContaining('ارزش کل کالاهای فروخته‌شده'), findsOneWidget);
    });

    testWidgets('does not render help button when helpTooltip is null or empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KpiCard(
              label: 'فروش ناخالص',
              value: '۱,۰۰۰,۰۰۰ تومان',
              subtitle: 'تسویه‌شده',
              icon: Icons.receipt_long,
              gradient: LinearGradient(colors: [Colors.blue, Colors.indigo]),
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.priority_high_rounded);
      expect(iconFinder, findsNothing);
    });
  });
}

