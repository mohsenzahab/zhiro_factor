import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../services/pdf_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/date_range_filter_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/privacy_tooltip.dart';
import '../cubit/invoice_history_cubit.dart';
import '../cubit/invoice_history_state.dart';
import '../../../data/models/invoice_model.dart';
import 'widgets/invoice_filter_bar.dart';
import 'widgets/invoice_detail_panel.dart';
import '../../invoice/view/widgets/invoice_preview_dialog.dart';

/// Invoice history explorer page.
class InvoiceHistoryPage extends StatelessWidget {
  final void Function(int invoiceId)? onEditInvoice;

  const InvoiceHistoryPage({super.key, this.onEditInvoice});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InvoiceHistoryCubit()..loadInvoices(isInitial: true),
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
  final _productSearchCtrl = TextEditingController();
  int? _expandedInvoiceId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _productSearchCtrl.dispose();
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
              final loaded = state is InvoiceHistoryLoaded ? state : null;
              final preset = loaded?.effectivePreset ?? DateRangePreset.thisMonth;
              final dateFrom = loaded?.dateFrom;
              final dateTo = loaded?.dateTo;
              final categoryFilter = loaded?.categoryFilter;
              final availableCategories = loaded?.availableCategories ?? const [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Date Range Filter Bar ───────────────────────
                  DateRangeFilterBar(
                    initialPreset: preset,
                    initialDateFrom: dateFrom,
                    initialDateTo: dateTo,
                    onRangeChanged: ({required preset, dateFrom, dateTo}) {
                      context.read<InvoiceHistoryCubit>().setDateRangeFilter(
                            preset: preset,
                            dateFrom: dateFrom,
                            dateTo: dateTo,
                          );
                    },
                  ),
                  const SizedBox(height: 12),

                  // ── Category Filter ────────────────────────────
                  if (availableCategories.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.category_outlined, size: 18, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        const Text('دسته‌بندی:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        const SizedBox(width: 8),
                        _CategoryChip(
                          label: 'همه',
                          isSelected: categoryFilter == null,
                          onTap: () => context.read<InvoiceHistoryCubit>().setCategoryFilter(null),
                        ),
                        const SizedBox(width: 6),
                        ...availableCategories.map((cat) => Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _CategoryChip(
                                label: cat,
                                isSelected: categoryFilter == cat,
                                onTap: () => context.read<InvoiceHistoryCubit>().setCategoryFilter(cat),
                              ),
                            )),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Search & Status Filters ───────────────────
                  InvoiceFilterBar(
                    statusFilter: loaded?.statusFilter,
                    onStatusChanged: (s) => context.read<InvoiceHistoryCubit>().setStatusFilter(s),
                    onSearchChanged: (q) => context.read<InvoiceHistoryCubit>().setCustomerQuery(q),
                    searchController: _searchCtrl,
                    onProductSearchChanged: (q) => context.read<InvoiceHistoryCubit>().setProductQuery(q),
                    productSearchController: _productSearchCtrl,
                  ),
                ],
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
          final hasProductSearch = state.productQuery != null && state.productQuery!.isNotEmpty;
          final isExpanded = hasProductSearch || _expandedInvoiceId == inv.id;
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
                            inv.invoiceNumber.toPersianDigits(),
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
                          child: PrivacyTooltip(
                            message: 'سود: ${inv.totalProfitAmount.formatted} تومان (${inv.totalProfitPercentage.toStringAsFixed(1).toPersianDigits()}٪)',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  inv.totalNet.formatted,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
                                  ),
                                ),
                                if (inv.paidAmount > 0 && inv.remainingAmount > 0)
                                  Text(
                                    'مانده: ${inv.remainingAmount.formatted}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.statusCredit,
                                    ),
                                  ),
                              ],
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
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          color: AppColors.primary,
                          tooltip: AppStrings.previewInvoice,
                          onPressed: () => _previewInvoice(context, inv),
                        ),
                        IconButton(
                          icon: const Icon(Icons.print_outlined, size: 18),
                          color: AppColors.textSecondary,
                          tooltip: AppStrings.quickPrint,
                          onPressed: () => _quickPrintInvoice(context, inv),
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
              if (isExpanded)
                InvoiceDetailPanel(
                  invoice: inv,
                  highlightQuery: state.productQuery,
                  onPaymentsChanged: () => context.read<InvoiceHistoryCubit>().loadInvoices(),
                ),
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

  Future<void> _previewInvoice(BuildContext context, InvoiceModel invoice) async {
    if (invoice.id != null) {
      await InvoicePreviewDialog.showFromId(context, invoice.id!);
    } else {
      await InvoicePreviewDialog.showFromModel(context, invoice);
    }
  }

  Future<void> _quickPrintInvoice(BuildContext context, InvoiceModel invoice) async {
    if (invoice.id != null) {
      await PdfService.printInvoiceById(invoice.id!);
    } else {
      await PdfService.printInvoiceFromModel(invoice);
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.dividerDark,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
