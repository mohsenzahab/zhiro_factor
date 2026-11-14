import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import 'package:prokit/utils/number_extensions.dart';
import '../../../core/responsive/responsive_breakpoints.dart';
import '../../../shared/widgets/category_filter_bar.dart';
import '../../../shared/widgets/date_range_filter_bar.dart';
import '../../../shared/widgets/responsive_kpi_grid.dart';
import '../../../shared/widgets/responsive_page_header.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import 'widgets/kpi_card.dart';
import 'widgets/best_sellers_chart.dart';

/// Dashboard page with KPIs, best sellers, and recent invoices.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit()..loadDashboard(isInitial: true),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final isCompact = context.isHandheld;

        return Padding(
          padding: context.responsivePagePadding,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Responsive Header ───────────────────────────
                ResponsivePageHeader(
                  title: AppStrings.navDashboard,
                  icon: Icons.dashboard,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => context.read<DashboardCubit>().loadDashboard(
                            dateFrom: state.dateFrom,
                            dateTo: state.dateTo,
                            preset: state.preset,
                          ),
                      tooltip: 'بروزرسانی',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Date Range Filter Bar ───────────────────────
                DateRangeFilterBar(
                  initialPreset: state.preset,
                  initialDateFrom: state.dateFrom,
                  initialDateTo: state.dateTo,
                  onRangeChanged: ({required preset, dateFrom, dateTo}) {
                    context.read<DashboardCubit>().loadDashboard(
                          dateFrom: dateFrom,
                          dateTo: dateTo,
                          preset: preset,
                        );
                  },
                ),
                const SizedBox(height: 12),

                // ── Unified Category Filter Bar ─────────────────
                if (state.availableCategories.isNotEmpty) ...[
                  CategoryFilterBar(
                    categories: state.availableCategories,
                    selectedCategory: state.categoryFilter,
                    onCategorySelected: (cat) => context.read<DashboardCubit>().setCategoryFilter(cat),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Responsive KPI Cards Grid ───────────────────
                ResponsiveKpiGrid(
                  minItemWidth: 240,
                  children: [
                    // Gross Sales (Settled)
                    KpiCard(
                      label: AppStrings.totalGrossSales,
                      value: state.totalGross.toman,
                      subtitle: 'تسویه‌شده',
                      icon: Icons.receipt_long,
                      gradient: AppColors.kpiCardGradient1,
                      details: [
                        KpiDetailItem(
                          label: AppStrings.totalInitialBuyCost,
                          value: state.totalInitialBuyCost.toman,
                        ),
                        KpiDetailItem(
                          label: AppStrings.totalCurrentBuyCost,
                          value: state.totalCurrentBuyCost.toman,
                        ),
                      ],
                    ),

                    // Net Profit (Settled)
                    KpiCard(
                      label: AppStrings.netProfit,
                      value: state.totalProfit.toman,
                      subtitle: state.profitPercentOfCost > 0
                          ? '${state.profitPercentOfCost.percentDisplay} حاشیه سود'
                          : 'تسویه‌شده',
                      icon: Icons.trending_up,
                      gradient: AppColors.kpiCardGradient2,
                      details: [
                        KpiDetailItem(
                          label: AppStrings.profitPercentCost,
                          value: state.profitPercentOfCost.percentDisplay,
                        ),
                        KpiDetailItem(
                          label: AppStrings.profitPercentCurrentCost,
                          value: state.profitPercentOfCurrentCost.percentDisplay,
                        ),
                        KpiDetailItem(
                          label: AppStrings.profitPercentSales,
                          value: state.profitPercentOfSales.percentDisplay,
                        ),
                        if (state.totalCurrentBuyCost > 0 &&
                            state.totalCurrentBuyCost != state.totalInitialBuyCost)
                          KpiDetailItem(
                            label: AppStrings.totalCurrentProfit,
                            value: state.totalCurrentProfit.toman,
                          ),
                      ],
                    ),

                    // Pending / Deposit Invoices
                    KpiCard(
                      label: AppStrings.pendingAndDeposit,
                      value: state.pendingAmount.toman,
                      subtitle: '${state.pendingCount.formattedInt} فاکتور',
                      icon: Icons.pending_actions,
                      gradient: AppColors.kpiCardGradient4,
                      details: [
                        KpiDetailItem(
                          label: 'تعداد فاکتورها',
                          value: '${state.pendingCount.formattedInt} مورد',
                        ),
                        KpiDetailItem(
                          label: 'میانگین هر فاکتور',
                          value: state.pendingCount > 0
                              ? (state.pendingAmount / state.pendingCount).toman
                              : '۰ تومان',
                        ),
                      ],
                    ),

                    // Discounts (Settled)
                    KpiCard(
                      label: AppStrings.settledDiscounts,
                      value: state.totalDiscounts.toman,
                      subtitle: state.discountPercentOfSales > 0
                          ? '${state.discountPercentOfSales.percentDisplay} تخفیف'
                          : 'تسویه‌شده',
                      icon: Icons.discount_outlined,
                      gradient: AppColors.kpiCardGradient3,
                      details: [
                        KpiDetailItem(
                          label: AppStrings.discountPercentSales,
                          value: state.discountPercentOfSales.percentDisplay,
                        ),
                        KpiDetailItem(
                          label: AppStrings.netSalesAfterDiscount,
                          value: state.netSales.toman,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Best Sellers + Recent Invoices ──────────────
                if (isCompact) ...[
                  BestSellersChart(
                    byVolume: state.bestSellersByVolume,
                    byRevenue: state.bestSellersByRevenue,
                  ),
                  const SizedBox(height: 16),
                  _buildRecentInvoices(context, state),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Best sellers
                      Expanded(
                        flex: 3,
                        child: BestSellersChart(
                          byVolume: state.bestSellersByVolume,
                          byRevenue: state.bestSellersByRevenue,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Recent invoices
                      Expanded(
                        flex: 2,
                        child: _buildRecentInvoices(context, state),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentInvoices(BuildContext context, DashboardState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.history, color: AppColors.info, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppStrings.recentInvoices,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.dividerDark),
          if (state.recentInvoices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'فاکتوری در این بازه یافت نشد',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ...state.recentInvoices.asMap().entries.map((entry) {
              final i = entry.key;
              final inv = entry.value;
              final status = inv['status'] as String? ?? '';
              return Container(
                decoration: BoxDecoration(
                  border: i > 0
                      ? const Border(
                          top: BorderSide(color: AppColors.dividerDark, width: 0.5),
                        )
                      : null,
                ),
                child: ListTile(
                  dense: true,
                  title: Row(
                    children: [
                      Text(
                        inv['invoice_number'] as String? ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            color: _statusColor(status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    inv['customer_name'] as String? ?? 'مشتری آزاد',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  trailing: Text(
                    ((inv['total_net'] as num?)?.toDouble() ?? 0).toman,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'تسویه شده':
        return AppColors.success;
      case 'در انتظار پرداخت':
        return AppColors.warning;
      case 'بیعانه':
        return AppColors.info;
      case 'لغو شده':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }
}
