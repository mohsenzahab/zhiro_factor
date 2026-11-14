import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import 'package:prokit/utils/number_extensions.dart';
import '../../../core/responsive/responsive_breakpoints.dart';
import '../../../services/export_service.dart';
import '../../../shared/widgets/date_range_filter_bar.dart';
import '../../../shared/widgets/responsive_kpi_grid.dart';
import '../../../shared/widgets/responsive_page_header.dart';
import '../cubit/report_cubit.dart';
import '../cubit/report_state.dart';
import 'widgets/sales_ledger_table.dart';

/// Reports page with sales ledger and export options.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReportCubit()..loadLedger(isInitial: true),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportCubit, ReportState>(
      builder: (context, state) {
        return Padding(
          padding: context.responsivePagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header & Exports ──────────────────────────────────
              ResponsivePageHeader(
                title: AppStrings.salesLedger,
                icon: Icons.analytics,
                iconColor: AppColors.primary,
                actions: [
                  OutlinedButton.icon(
                    onPressed: () => _exportCsv(context),
                    icon: const Icon(Icons.file_download, size: 18),
                    label: const Text(AppStrings.exportCsv),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _exportExcel(context),
                    icon: const Icon(Icons.table_chart, size: 18),
                    label: const Text(AppStrings.exportExcel),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Date Range Filter Bar ─────────────────────────────
              DateRangeFilterBar(
                initialPreset: state.preset,
                initialDateFrom: state.dateFrom,
                initialDateTo: state.dateTo,
                onRangeChanged: ({required preset, dateFrom, dateTo}) {
                  context.read<ReportCubit>().loadLedger(
                        dateFrom: dateFrom,
                        dateTo: dateTo,
                        preset: preset,
                      );
                },
              ),
              const SizedBox(height: 12),

              // ── Status Filter Chips ───────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('وضعیت فاکتور:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    const SizedBox(width: 10),
                    _buildStatusChip(context, state, null, 'همه'),
                    const SizedBox(width: 8),
                    _buildStatusChip(context, state, AppStrings.statusSettled, AppStrings.statusSettled),
                    const SizedBox(width: 8),
                    _buildStatusChip(context, state, AppStrings.statusPending, AppStrings.statusPending),
                    const SizedBox(width: 8),
                    _buildStatusChip(context, state, AppStrings.statusDeposit, AppStrings.statusDeposit),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Summary Cards ─────────────────────────────────────
              ResponsiveKpiGrid(
                minItemWidth: 200,
                children: [
                  _buildSummaryCard(
                    label: 'فروش این دوره',
                    value: state.totalSales.toman,
                    icon: Icons.receipt_long,
                    color: AppColors.primary,
                  ),
                  _buildSummaryCard(
                    label: 'سود این دوره',
                    value: state.totalProfit.toman,
                    icon: Icons.trending_up,
                    color: AppColors.success,
                    isHighlighted: true,
                  ),
                  _buildSummaryCard(
                    label: 'تخفیفات این دوره',
                    value: state.totalDiscount.toman,
                    icon: Icons.discount_outlined,
                    color: AppColors.warning,
                  ),
                  _buildSummaryCard(
                    label: 'تعداد کل اقلام',
                    value: '${state.itemsCount.formattedInt} سطر (${state.totalQuantity.formattedInt} عدد)',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.info,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Ledger Table ──────────────────────────────────────
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SalesLedgerTable(data: state.ledgerData),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    ReportState state,
    String? statusValue,
    String label,
  ) {
    final isSelected = (state.status == null && statusValue == null) ||
        (state.status == statusValue);

    return InkWell(
      onTap: () => context.read<ReportCubit>().setStatus(statusValue),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (statusValue != null
                  ? AppColors.statusColor(statusValue).withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.2))
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (statusValue != null
                    ? AppColors.statusColor(statusValue)
                    : AppColors.primary)
                : AppColors.dividerDark,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? (statusValue != null
                    ? AppColors.statusColor(statusValue)
                    : AppColors.primary)
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted ? color.withValues(alpha: 0.5) : AppColors.dividerDark,
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted ? color : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final state = context.read<ReportCubit>().state;
    try {
      await ExportService.exportCsv(state.ledgerData);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فایل CSV با موفقیت ذخیره شد')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _exportExcel(BuildContext context) async {
    final state = context.read<ReportCubit>().state;
    try {
      await ExportService.exportExcel(state.ledgerData);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فایل اکسل با موفقیت ذخیره شد')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: ${e.toString()}')),
        );
      }
    }
  }
}
