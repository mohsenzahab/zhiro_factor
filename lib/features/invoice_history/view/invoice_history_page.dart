import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../services/pdf_service.dart';
import '../cubit/invoice_history_cubit.dart';
import '../cubit/invoice_history_state.dart';
import 'widgets/invoice_filter_bar.dart';
import 'widgets/invoice_detail_panel.dart';

/// Invoice history explorer page.
class InvoiceHistoryPage extends StatelessWidget {
  final void Function(int invoiceId)? onEditInvoice;

  const InvoiceHistoryPage({super.key, this.onEditInvoice});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InvoiceHistoryCubit()..loadInvoices(),
      child: _InvoiceHistoryView(onEditInvoice: onEditInvoice),
    );
  }
}

class _InvoiceHistoryView extends StatefulWidget {
  final void Function(int invoiceId)? onEditInvoice;

  const _InvoiceHistoryView({this.onEditInvoice});

  @override
  State<_InvoiceHistoryView> createState() => _InvoiceHistoryViewState();
}

class _InvoiceHistoryViewState extends State<_InvoiceHistoryView> {
  final _searchCtrl = TextEditingController();
  int? _expandedInvoiceId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ───────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.history, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                AppStrings.navInvoiceHistory,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Filters ─────────────────────────────────────────
          BlocBuilder<InvoiceHistoryCubit, InvoiceHistoryState>(
            builder: (context, state) {
              return InvoiceFilterBar(
                statusFilter: state is InvoiceHistoryLoaded ? state.statusFilter : null,
                onStatusChanged: (s) => context.read<InvoiceHistoryCubit>().setStatusFilter(s),
                onSearchChanged: (q) => context.read<InvoiceHistoryCubit>().setCustomerQuery(q),
                searchController: _searchCtrl,
              );
            },
          ),
          const SizedBox(height: 16),

          // ── Table ───────────────────────────────────────────
          Expanded(
            child: BlocBuilder<InvoiceHistoryCubit, InvoiceHistoryState>(
              builder: (context, state) {
                if (state is InvoiceHistoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is InvoiceHistoryError) {
                  return Center(child: Text(state.message));
                }
                if (state is InvoiceHistoryLoaded) {
                  if (state.invoices.isEmpty) {
                    return const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'فاکتوری یافت نشد',
                    );
                  }
                  return _buildInvoiceList(context, state);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceList(BuildContext context, InvoiceHistoryLoaded state) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        itemCount: state.invoices.length,
        itemBuilder: (context, index) {
          final inv = state.invoices[index];
          final isExpanded = _expandedInvoiceId == inv.id;
          final jalaliDate = _tryFormatDate(inv.date);

          return Column(
            children: [
              Container(
                color: index.isEven ? AppColors.tableRowEven : AppColors.tableRowOdd,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _expandedInvoiceId = isExpanded ? null : inv.id;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Expand icon
                        AnimatedRotation(
                          turns: isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.chevron_left, size: 20, color: AppColors.textMuted),
                        ),
                        const SizedBox(width: 12),

                        // Invoice Number
                        SizedBox(
                          width: 140,
                          child: Text(
                            inv.invoiceNumber,
                            style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
                          ),
                        ),

                        // Date
                        SizedBox(
                          width: 100,
                          child: Text(jalaliDate, style: const TextStyle(fontSize: 13)),
                        ),

                        // Customer
                        Expanded(
                          child: Text(
                            inv.customerName ?? '---',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Gross
                        SizedBox(
                          width: 120,
                          child: Text(
                            inv.totalGross.formatted,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),

                        // Discount
                        SizedBox(
                          width: 100,
                          child: Text(
                            inv.totalDiscount.formatted,
                            style: const TextStyle(fontSize: 13, color: AppColors.warning),
                          ),
                        ),

                        // Net
                        SizedBox(
                          width: 120,
                          child: Text(
                            inv.totalNet.formatted,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ),

                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.statusColor(inv.status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            inv.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.statusColor(inv.status),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Actions
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: AppColors.info,
                          tooltip: AppStrings.editInvoice,
                          onPressed: () => widget.onEditInvoice?.call(inv.id!),
                        ),
                        IconButton(
                          icon: const Icon(Icons.print_outlined, size: 18),
                          color: AppColors.textSecondary,
                          tooltip: AppStrings.printInvoice,
                          onPressed: () => _printInvoice(context, inv.id!),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: AppColors.error,
                          tooltip: AppStrings.deleteInvoice,
                          onPressed: () => _deleteInvoice(context, inv.id!),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Expanded detail
              if (isExpanded) InvoiceDetailPanel(invoice: inv),
              if (index < state.invoices.length - 1)
                Divider(height: 1, color: AppColors.dividerDark),
            ],
          );
        },
      ),
    );
  }

  String _tryFormatDate(String dateStr) {
    try {
      final jalali = JalaliUtils.fromIso(dateStr);
      return JalaliUtils.format(jalali);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _deleteInvoice(BuildContext context, int id) async {
    final confirmed = await ConfirmDialog.show(context, message: 'آیا از حذف این فاکتور اطمینان دارید؟');
    if (confirmed && context.mounted) {
      context.read<InvoiceHistoryCubit>().deleteInvoice(id);
    }
  }

  Future<void> _printInvoice(BuildContext context, int invoiceId) async {
    await PdfService.printInvoiceById(context, invoiceId);
  }
}
