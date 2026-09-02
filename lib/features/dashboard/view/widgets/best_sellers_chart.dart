import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/number_extensions.dart';

/// Best sellers table/chart widget for dashboard.
class BestSellersChart extends StatelessWidget {
  final List<Map<String, dynamic>> byVolume;
  final List<Map<String, dynamic>> byRevenue;

  const BestSellersChart({
    super.key,
    required this.byVolume,
    required this.byRevenue,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dividerDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.bestSellers,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TabBar(
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              tabs: const [
                Tab(text: AppStrings.byVolume),
                Tab(text: AppStrings.byRevenue),
              ],
            ),
            SizedBox(
              height: 300,
              child: TabBarView(
                children: [
                  _buildList(byVolume, isVolume: true),
                  _buildList(byRevenue, isVolume: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> data, {required bool isVolume}) {
    if (data.isEmpty) {
      return const Center(
        child: Text('داده‌ای موجود نیست', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    final maxValue = data.isNotEmpty
        ? (data.first[isVolume ? 'total_quantity' : 'total_revenue'] as num).toDouble()
        : 1.0;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final name = item['product_name'] as String;
        final quantity = (item['total_quantity'] as num).toDouble();
        final revenue = (item['total_revenue'] as num).toDouble();
        final displayValue = isVolume ? quantity : revenue;
        final progress = maxValue > 0 ? displayValue / maxValue : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppColors.dividerDark,
                    valueColor: AlwaysStoppedAnimation(
                      HSLColor.fromAHSL(
                        1.0,
                        180 + (index * 20).toDouble(),
                        0.7,
                        0.5,
                      ).toColor(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isVolume ? quantity.formattedInt : revenue.toman,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
