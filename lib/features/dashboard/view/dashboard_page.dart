import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../shared/widgets/date_range_filter_bar.dart';
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

        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title & Refresh ─────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.dashboard, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.navDashboard,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
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
                const SizedBox(height: 20),

                // ── KPI Cards ───────────────────────────────────
                Row(
                  children: [
                    // Gross Sales (Settled)
                    Expanded(
                      child: KpiCard(
                        label: AppStrings.totalGrossSales,
                        value: state.totalGross.toman,
                        subtitle: 'تسویه‌شده',
                        icon: Icons.receipt_long,
                        gradient: AppColors.kpiCardGradient1,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Net Profit (سود خالص)
                    Expanded(
                      child: KpiCard(
                        label: AppStrings.netProfit,
                        value: state.totalProfit.toman,
                        subtitle: 'سود واقعی',
                        icon: Icons.trending_up,
                        gradient: AppColors.kpiCardGradient2,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Pending / Deposit Invoices
                    Expanded(
                      child: KpiCard(
                        label: AppStrings.pendingAndDeposit,
                        value: state.pendingAmount.toman,
                        subtitle: '${state.pendingCount} فاکتور',
                        icon: Icons.pending_actions,
                        gradient: AppColors.kpiCardGradient4,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Discounts (Settled)
                    Expanded(
                      child: KpiCard(
                        label: AppStrings.settledDiscounts,
                        value: state.totalDiscounts.toman,
                        subtitle: 'تسویه‌شده',
                        icon: Icons.discount_outlined,
                        gradient: AppColors.kpiCardGradient3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Best Sellers + Recent Invoices ──────────────
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
                            ...state.recentInvoices.asMap().entries.map((entry) {
                              final i = entry.key;
                              final inv = entry.value;
                              final status = inv['status'] as String? ?? '';
                              return Container(
                                color: i.isEven ? AppColors.tableRowEven : AppColors.tableRowOdd,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            inv['invoice_number'] as String? ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            inv['customer_name'] as String? ?? '---',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          (inv['total_net'] as num?)?.toDouble().toman ?? '---',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors.statusColor(status).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.statusColor(status),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
