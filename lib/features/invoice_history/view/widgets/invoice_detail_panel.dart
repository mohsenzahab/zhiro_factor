import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../../../core/utils/jalali_utils.dart';
import '../../../../data/models/invoice_model.dart';
import '../../../../data/models/invoice_item_model.dart';
import '../../../../data/models/invoice_payment_model.dart';
import '../../../../data/repositories/invoice_repository.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../../../shared/widgets/privacy_tooltip.dart';
import '../../../invoice/view/widgets/invoice_payments_dialog.dart';

/// Expandable detail panel showing invoice items and payment history / credit status.
class InvoiceDetailPanel extends StatefulWidget {
  final InvoiceModel invoice;
  final String? highlightQuery;
  final VoidCallback? onPaymentsChanged;

  const InvoiceDetailPanel({
    super.key,
    required this.invoice,
    this.highlightQuery,
    this.onPaymentsChanged,
  });

  @override
  State<InvoiceDetailPanel> createState() => _InvoiceDetailPanelState();
}

class _InvoiceDetailPanelState extends State<InvoiceDetailPanel> {
  List<InvoiceItemModel>? _items;
  List<InvoicePaymentModel>? _payments;
  Map<int, ProductDetailInfo> _productDetails = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final repo = InvoiceRepository();
    final items = await repo.getItemsByInvoiceId(widget.invoice.id!);
    final payments = await repo.getPaymentsByInvoiceId(widget.invoice.id!);

    final productRepo = ProductRepository();
    final productIds = items.map((e) => e.productId).whereType<int>().toSet().toList();
    final productDetails = await productRepo.getProductsDetailInfo(productIds);

    if (mounted) {
      setState(() {
        _items = items;
        _payments = payments;
        _productDetails = productDetails;
        _loading = false;
      });
    }
  }

  void _openPaymentsDialog() {
    InvoicePaymentsDialog.showForSavedInvoice(
      context: context,
      invoiceId: widget.invoice.id!,
      invoiceNumber: widget.invoice.invoiceNumber,
      totalNet: widget.invoice.totalNet,
      status: widget.invoice.status,
      payments: _payments ?? widget.invoice.payments,
      onPaymentsChanged: () {
        _loadDetails();
        widget.onPaymentsChanged?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final allItems = _items ?? [];
    final items = (widget.highlightQuery != null && widget.highlightQuery!.isNotEmpty)
        ? allItems.where((item) => item.productName.contains(widget.highlightQuery!)).toList()
        : allItems;

    final currentPayments = _payments ?? widget.invoice.payments;
    final isSettled = widget.invoice.status == 'تسویه شده' ||
        (widget.invoice.totalNet > 0 &&
            currentPayments.fold(0.0, (sum, p) => sum + p.amount) >= widget.invoice.totalNet);
    final totalPaid = isSettled && currentPayments.isEmpty
        ? widget.invoice.totalNet
        : currentPayments.fold(0.0, (sum, p) => sum + p.amount);
    final remaining = isSettled ? 0.0 : (widget.invoice.totalNet - totalPaid).clamp(0.0, double.infinity);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Items Header ─────────────────────────────────────────
          Row(
            children: [
              Text(
                'اقلام فاکتور ${widget.invoice.invoiceNumber.toPersianDigits()}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Spacer(),
              // Payments quick action or Settled badge
              if (!isSettled)
                OutlinedButton.icon(
                  onPressed: _openPaymentsDialog,
                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                  label: Text(
                    currentPayments.isNotEmpty
                        ? 'مدیریت دریافتی‌ها (${currentPayments.length.toString().toPersianDigits()})'
                        : AppStrings.addPayment,
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusCredit,
                    side: BorderSide(color: AppColors.statusCredit.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                )
              else if (currentPayments.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _openPaymentsDialog,
                  icon: const Icon(Icons.receipt_long_outlined, size: 16),
                  label: Text(
                    'مشاهده دریافتی‌ها (${currentPayments.length.toString().toPersianDigits()})',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusSettled,
                    side: BorderSide(color: AppColors.statusSettled.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.statusSettled.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.statusSettled.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle_outline, size: 14, color: AppColors.statusSettled),
                      SizedBox(width: 4),
                      Text(
                        'تسویه کامل',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.statusSettled),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Items Table ──────────────────────────────────────────
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('آیتمی یافت نشد', style: TextStyle(color: AppColors.textMuted)),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(0.5),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
                5: FlexColumnWidth(1),
              },
              border: TableBorder.all(color: AppColors.dividerDark, width: 0.5),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: AppColors.tableHeader),
                  children: [
                    _headerCell('ردیف'),
                    _headerCell('نام کالا'),
                    _headerCell('تعداد'),
                    _headerCell('قیمت واحد'),
                    _headerCell('تخفیف'),
                    _headerCell('جمع'),
                  ],
                ),
                ...items.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  final isHighlighted = widget.highlightQuery != null &&
                      widget.highlightQuery!.isNotEmpty &&
                      item.productName.contains(widget.highlightQuery!);

                  Color rowColor = i.isEven ? AppColors.tableRowEven : AppColors.tableRowOdd;
                  if (isHighlighted) {
                    rowColor = Colors.green.withValues(alpha: 0.2);
                  }

                  return TableRow(
                    decoration: BoxDecoration(color: rowColor),
                    children: [
                      // 0: Row Index
                      _dataCell('${i + 1}'.toPersianDigits()),

                      // 1: Product Name -> Product Category Tooltip
                      Builder(builder: (_) {
                        final detail = item.productId != null ? _productDetails[item.productId!] : null;
                        final categoryText = (detail?.category != null && detail!.category!.trim().isNotEmpty)
                            ? detail.category!
                            : 'عمومی / بدون دسته‌بندی';
                        final tooltipMsg = 'دسته‌بندی: $categoryText';
                        return _tooltipCell(
                          child: Text(item.productName, style: const TextStyle(fontSize: 12)),
                          tooltipMessage: tooltipMsg,
                        );
                      }),

                      // 2: Quantity -> Stock remaining & Total sold Tooltip
                      Builder(builder: (_) {
                        final detail = item.productId != null ? _productDetails[item.productId!] : null;
                        final stockText = detail != null
                            ? (detail.stock != null ? detail.stock!.formattedInt : 'نامحدود')
                            : 'نامشخص';
                        final soldText = detail != null
                            ? detail.totalSold.formattedInt
                            : item.quantity.formattedInt;
                        final tooltipMsg = 'مانده در انبار: $stockText عدد\nکل فروخته شده: $soldText عدد';
                        return _tooltipCell(
                          child: Text(item.quantity.formattedInt, style: const TextStyle(fontSize: 12)),
                          tooltipMessage: tooltipMsg,
                        );
                      }),

                      // 3: Unit Price -> Current buy price + profit, and FIFO initial buy price
                      Builder(builder: (_) {
                        final detail = item.productId != null ? _productDetails[item.productId!] : null;
                        final currBuy = detail?.currentBuyPrice ?? item.purchasePrice;
                        final profitOnCurr = item.unitPrice - currBuy;
                        final profitPctOnCurr = currBuy > 0 ? (profitOnCurr / currBuy) * 100.0 : 0.0;
                        final initBuy = detail?.initialBuyPrice ?? item.purchasePrice;
                        final tooltipMsg = 'قیمت خرید کنونی: ${currBuy.formatted} تومان\n'
                            'سود (روی خرید کنونی): ${profitOnCurr.formatted} تومان (${profitPctOnCurr.toStringAsFixed(1).toPersianDigits()}٪)\n'
                            'قیمت خرید اولیه: ${initBuy.formatted} تومان';
                        return _tooltipCell(
                          child: Text(item.unitPrice.formatted, style: const TextStyle(fontSize: 12)),
                          tooltipMessage: tooltipMsg,
                        );
                      }),

                      // 4: Discount -> Discount percentage on initial buy and current buy
                      Builder(builder: (_) {
                        final detail = item.productId != null ? _productDetails[item.productId!] : null;
                        final currBuy = detail?.currentBuyPrice ?? item.purchasePrice;
                        final initBuy = detail?.initialBuyPrice ?? item.purchasePrice;
                        final discAmount = item.discountCalculatedAmount;
                        String tooltipMsg;
                        if (discAmount <= 0) {
                          tooltipMsg = 'تخفیف: ۰ تومان (۰٪)';
                        } else {
                          final unitDisc = item.quantity > 0 ? discAmount / item.quantity : discAmount;
                          final pctOnCurr = currBuy > 0 ? (unitDisc / currBuy) * 100.0 : 0.0;
                          final pctOnInit = initBuy > 0 ? (unitDisc / initBuy) * 100.0 : 0.0;
                          tooltipMsg = 'مبلغ تخفیف: ${discAmount.formatted} تومان\n'
                              'درصد از خرید کنونی: ${pctOnCurr.toStringAsFixed(1).toPersianDigits()}٪\n'
                              'درصد از خرید اولیه: ${pctOnInit.toStringAsFixed(1).toPersianDigits()}٪';
                        }
                        return _tooltipCell(
                          child: Text(item.discountCalculatedAmount.formatted, style: const TextStyle(fontSize: 12)),
                          tooltipMessage: tooltipMsg,
                        );
                      }),

                      // 5: Line Total -> Profit with privacy delay
                      _tooltipCell(
                        child: Text(
                          item.lineTotal.formatted,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent, fontSize: 12),
                        ),
                        tooltipMessage: 'سود: ${item.profitAmount.formatted} تومان (${item.profitPercentage.toStringAsFixed(1).toPersianDigits()}٪)',
                      ),
                    ],
                  );
                }),
              ],
            ),
          const SizedBox(height: 12),

          // ── Payments & Credit Summary Box ─────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.dividerDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isSettled ? Icons.check_circle_outline : Icons.payments_outlined,
                      size: 16,
                      color: isSettled ? AppColors.statusSettled : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isSettled ? 'وضعیت تسویه:' : 'وضعیت تسویه و نسیه:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSettled ? AppColors.statusSettled : AppColors.textSecondary,
                      ),
                    ),
                    if (isSettled) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.statusSettled.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'تسویه کامل',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.statusSettled),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      isSettled ? 'کل مبلغ فاکتور: ${widget.invoice.totalNet.toman}' : 'کل قابل پرداخت: ${widget.invoice.totalNet.toman}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      isSettled ? 'پرداختی: ${totalPaid.toman}' : 'دریافتی: ${totalPaid.toman}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusSettled,
                      ),
                    ),
                    if (!isSettled) ...[
                      const SizedBox(width: 14),
                      Text(
                        'مانده: ${remaining.toman}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: remaining > 0 ? AppColors.statusCredit : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                if (currentPayments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.dividerDark),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: currentPayments.map((p) {
                      final jalali = JalaliUtils.format(JalaliUtils.fromIso(p.date));
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.dividerDark),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_downward, size: 12, color: AppColors.statusSettled),
                            const SizedBox(width: 4),
                            Text(
                              p.amount.toman,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.statusSettled),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              jalali,
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                            if (p.note != null && p.note!.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${p.note})',
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          if (widget.invoice.notes != null && widget.invoice.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'یادداشت: ${widget.invoice.notes}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary)),
    );
  }

  Widget _dataCell(String text, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, style: style ?? const TextStyle(fontSize: 12)),
    );
  }

  Widget _tooltipCell({
    required Widget child,
    String? tooltipMessage,
  }) {
    final paddingChild = Padding(
      padding: const EdgeInsets.all(8),
      child: child,
    );
    if (tooltipMessage != null && tooltipMessage.isNotEmpty) {
      return PrivacyTooltip(
        message: tooltipMessage,
        child: paddingChild,
      );
    }
    return paddingChild;
  }
}
