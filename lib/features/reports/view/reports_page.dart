import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/export_service.dart';
import '../cubit/report_cubit.dart';
import '../cubit/report_state.dart';
import 'widgets/sales_ledger_table.dart';

/// Reports page with sales ledger and export options.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReportCubit()..loadLedger(),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
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

          // ── Ledger Table ────────────────────────────────────
          Expanded(
            child: BlocBuilder<ReportCubit, ReportState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return SalesLedgerTable(data: state.ledgerData);
              },
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
