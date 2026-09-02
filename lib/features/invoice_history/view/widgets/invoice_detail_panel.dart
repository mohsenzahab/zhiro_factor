import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../../../data/models/invoice_model.dart';
import '../../../../data/models/invoice_item_model.dart';
import '../../../../data/repositories/invoice_repository.dart';

/// Expandable detail panel showing invoice items.
class InvoiceDetailPanel extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoiceDetailPanel({super.key, required this.invoice});

  @override
  State<InvoiceDetailPanel> createState() => _InvoiceDetailPanelState();
}

class _InvoiceDetailPanelState extends State<InvoiceDetailPanel> {
  List<InvoiceItemModel>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final repo = InvoiceRepository();
    final items = await repo.getItemsByInvoiceId(widget.invoice.id!);
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final items = _items ?? [];
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('آیتمی یافت نشد', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اقلام فاکتور ${widget.invoice.invoiceNumber}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
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
                return TableRow(
                  decoration: BoxDecoration(
                    color: i.isEven ? AppColors.tableRowEven : AppColors.tableRowOdd,
                  ),
                  children: [
                    _dataCell('${i + 1}'),
                    _dataCell(item.productName),
                    _dataCell(item.quantity.formattedInt),
                    _dataCell(item.unitPrice.formatted),
                    _dataCell(item.discountCalculatedAmount.formatted),
                    _dataCell(item.lineTotal.formatted,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent)),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.invoice.notes != null && widget.invoice.notes!.isNotEmpty)
            Text(
              'یادداشت: ${widget.invoice.notes}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
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
}
