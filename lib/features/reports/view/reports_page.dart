import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../services/export_service.dart';
import '../../../shared/widgets/date_range_filter_bar.dart';
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header & Exports ──────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.analytics, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.salesLedger,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _exportCsv(context),
                    icon: const Icon(Icons.file_download, size: 18),
                    label: const Text(AppStrings.exportCsv),
                  ),
                  const SizedBox(width: 8),
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
              Row(
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
              const SizedBox(height: 16),

              // ── Summary Cards ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      label: 'فروش این دوره',
                      value: state.totalSales.toman,
                      icon: Icons.receipt_long,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      label: 'سود این دوره',
                      value: state.totalProfit.toman,
                      icon: Icons.trending_up,
                      color: AppColors.success,
                      isHighlighted: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      label: 'تخفیفات این دوره',
                      value: state.totalDiscount.toman,
                      icon: Icons.discount_outlined,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      label: 'تعداد کل اقلام',
                      value: '${state.itemsCount.formattedInt} سطر (${state.totalQuantity.formattedInt} عدد)',
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.info,
                    ),
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
