import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../cubit/purchase_history_cubit.dart';
import '../../../data/models/purchase_model.dart';

/// Purchase history explorer page.
class PurchaseHistoryPage extends StatelessWidget {
  final void Function(int purchaseId)? onEditPurchase;
  final int? productId;
  final int? supplierId;

  const PurchaseHistoryPage({
    super.key,
    this.onEditPurchase,
    this.productId,
    this.supplierId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PurchaseHistoryCubit()..load(productId: productId, supplierId: supplierId),
      child: _PurchaseHistoryView(onEditPurchase: onEditPurchase),
    );
  }
}

class _PurchaseHistoryView extends StatefulWidget {
  final void Function(int purchaseId)? onEditPurchase;

  const _PurchaseHistoryView({this.onEditPurchase});

  @override
  State<_PurchaseHistoryView> createState() => _PurchaseHistoryViewState();
}

class _PurchaseHistoryViewState extends State<_PurchaseHistoryView> {
  final _searchCtrl = TextEditingController();
  int? _expandedPurchaseId;

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
              Icon(Icons.history, color: AppColors.accent, size: 28),
              const SizedBox(width: 12),
              Text(
                AppStrings.purchaseHistory,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Filters ─────────────────────────────────────────
          BlocBuilder<PurchaseHistoryCubit, PurchaseHistoryState>(
            builder: (context, state) {
              return _PurchaseFilterBar(
                onSearchChanged: (q) => context.read<PurchaseHistoryCubit>().load(
                      supplierQuery: q,
                      productId: context.findAncestorWidgetOfExactType<PurchaseHistoryPage>()?.productId,
                      supplierId: context.findAncestorWidgetOfExactType<PurchaseHistoryPage>()?.supplierId,
                    ),
                searchController: _searchCtrl,
              );
            },
          ),
          const SizedBox(height: 16),

          // ── Table ───────────────────────────────────────────
          Expanded(
            child: BlocBuilder<PurchaseHistoryCubit, PurchaseHistoryState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.error != null) {
                  return Center(child: Text(state.error!));
                }
                if (state.purchases.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'خریدی یافت نشد',
                  );
                }
                return _buildPurchaseList(context, state.purchases);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseList(BuildContext context, List<PurchaseModel> purchases) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        itemCount: purchases.length,
        itemBuilder: (context, index) {
          final purchase = purchases[index];
          final isExpanded = _expandedPurchaseId == purchase.id;
          final jalaliDate = _tryFormatDate(purchase.date);

          return Column(
            children: [
              Container(
                color: index.isEven ? AppColors.tableRowEven : AppColors.tableRowOdd,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _expandedPurchaseId = isExpanded ? null : purchase.id;
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

                        // Purchase Number
                        SizedBox(
                          width: 140,
                          child: Text(
                            purchase.purchaseNumber.toPersianDigits(),
                            style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
                          ),
                        ),

                        // Date
                        SizedBox(
                          width: 100,
                          child: Text(jalaliDate, style: const TextStyle(fontSize: 13)),
                        ),

                        // Supplier Name
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.textMuted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  purchase.supplierName ?? '---',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status Badge
                        SizedBox(
                          width: 120,
                          child: _StatusBadge(status: purchase.status),
                        ),

                        // Net Total
                        SizedBox(
                          width: 130,
                          child: Text(
                            '${purchase.totalNet.round().formatted} تومان',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent),
                            textAlign: TextAlign.left,
                          ),
                        ),

                        // Actions Menu
                        const SizedBox(width: 8),
                        _buildActionMenu(context, purchase),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Expanded Detail Panel ──
              if (isExpanded) _PurchaseDetailPanel(purchase: purchase),

              if (index < purchases.length - 1)
                const Divider(height: 1, thickness: 1, color: AppColors.dividerDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context, PurchaseModel purchase) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
      splashRadius: 20,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: AppColors.cardDark,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(AppStrings.editPurchase, style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              SizedBox(width: 8),
              Text(AppStrings.deletePurchase, style: TextStyle(fontSize: 13, color: AppColors.error)),
            ],
          ),
        ),
      ],
      onSelected: (val) {
        if (val == 'edit') {
          if (widget.onEditPurchase != null && purchase.id != null) {
            widget.onEditPurchase!(purchase.id!);
          }
        } else if (val == 'delete') {
          _confirmDelete(context, purchase);
        }
      },
    );
  }

  void _confirmDelete(BuildContext context, PurchaseModel purchase) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: AppStrings.deletePurchase,
      message: 'آیا از حذف فاکتور خرید ${purchase.purchaseNumber.toPersianDigits()} اطمینان دارید؟',
      confirmLabel: AppStrings.delete,
    );
    if (confirm == true && context.mounted && purchase.id != null) {
      await context.read<PurchaseHistoryCubit>().deletePurchase(purchase.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.purchaseDeleted)),
        );
      }
    }
  }

  String _tryFormatDate(String iso) {
    if (iso.isEmpty) return '---';
    try {
      final j = JalaliUtils.fromIso(iso);
      return JalaliUtils.format(j);
    } catch (_) {
      return iso;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Filter Bar
// ═══════════════════════════════════════════════════════════════════

class _PurchaseFilterBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final TextEditingController searchController;

  const _PurchaseFilterBar({
    required this.onSearchChanged,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 40,
              child: TextFormField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  hintText: AppStrings.searchPurchase,
                  prefixIcon: Icon(Icons.search, size: 20),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Status Badge
// ═══════════════════════════════════════════════════════════════════

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Detail Panel
// ═══════════════════════════════════════════════════════════════════

class _PurchaseDetailPanel extends StatelessWidget {
  final PurchaseModel purchase;

  const _PurchaseDetailPanel({required this.purchase});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardDarkAlt,
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Items table
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اقلام فاکتور خرید',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.dividerDark),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          border: Border(bottom: BorderSide(color: AppColors.dividerDark)),
                        ),
                        child: Row(
                          children: [
                            _headerCell('ردیف', flex: 1),
                            _headerCell('کالا', flex: 3),
                            _headerCell('تعداد', flex: 1),
                            _headerCell('فی (تومان)', flex: 2),
                            _headerCell('جمع (تومان)', flex: 2),
                          ],
                        ),
                      ),
                      // Rows
                      if (purchase.items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('بدون آیتم', style: TextStyle(color: AppColors.textMuted)),
                        ),
                      ...List.generate(purchase.items.length, (i) {
                        final item = purchase.items[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: i < purchase.items.length - 1
                                ? Border(bottom: BorderSide(color: AppColors.dividerDark))
                                : null,
                          ),
                          child: Row(
                            children: [
                              _cell('${i + 1}'.toPersianDigits(), flex: 1),
                              _cell(item.productName, flex: 3),
                              _cell(
                                item.quantity == item.quantity.roundToDouble()
                                    ? item.quantity.toInt().toString().toPersianDigits()
                                    : item.quantity.toString().toPersianDigits(),
                                flex: 1,
                              ),
                              _cell(item.unitPrice.round().formatted, flex: 2),
                              _cell(item.lineTotal.round().formatted, flex: 2, isBold: true),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),

          // Summary column
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'خلاصه فاکتور',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.dividerDark),
                  ),
                  child: Column(
                    children: [
                      _summaryRow('جمع اقلام:', purchase.totalAmount),
                      if (purchase.shippingCost > 0)
                        _summaryRow('هزینه ارسال:', purchase.shippingCost),
                      if (purchase.extraCosts > 0)
                        _summaryRow('هزینه‌های اضافی:', purchase.extraCosts),
                      const Divider(color: AppColors.dividerDark, height: 24),
                      _summaryRow('مبلغ نهایی:', purchase.totalNet, isTotal: true),
                    ],
                  ),
                ),
                if (purchase.notes != null && purchase.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('یادداشت',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    purchase.notes!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _cell(String text, {required int flex, bool isBold = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            '${amount.round().formatted} تومان',
            style: TextStyle(
              fontSize: isTotal ? 14 : 13,
              color: isTotal ? AppColors.accent : AppColors.textPrimary,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
