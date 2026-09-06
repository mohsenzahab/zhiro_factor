import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../../../core/utils/jalali_utils.dart';

/// Sales ledger table showing item-level sales data.
class SalesLedgerTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const SalesLedgerTable({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('داده‌ای برای نمایش وجود ندارد', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowHeight: 48,
            dataRowMinHeight: 42,
            dataRowMaxHeight: 48,
            columnSpacing: 20,
            horizontalMargin: 16,
            headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
            columns: const [
              DataColumn(label: Text('ردیف')),
              DataColumn(label: Text('نام کالا')),
              DataColumn(label: Text('شماره فاکتور')),
              DataColumn(label: Text('تاریخ')),
              DataColumn(label: Text('مشتری')),
              DataColumn(label: Text('وضعیت')),
              DataColumn(label: Text('تعداد')),
              DataColumn(label: Text('قیمت واحد')),
              DataColumn(label: Text('تخفیف')),
              DataColumn(label: Text('جمع سطر')),
              DataColumn(label: Text('سود سطر')),
            ],
            rows: List.generate(data.length, (index) {
              final row = data[index];
              final dateStr = row['date'] as String? ?? '';
              final status = row['invoice_status'] as String? ?? '';
              final profit = (row['profit'] as num?)?.toDouble() ?? 0.0;
              String jalali;
              try {
                jalali = JalaliUtils.format(JalaliUtils.fromIso(dateStr));
              } catch (_) {
                jalali = dateStr;
              }

              return DataRow(
                color: WidgetStateProperty.all(
                  index.isEven ? AppColors.tableRowEven : AppColors.tableRowOdd,
                ),
                cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(Text(
                    row['product_name'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  )),
                  DataCell(Text(
                    row['invoice_number'] as String? ?? '',
                    style: const TextStyle(fontSize: 12),
                  )),
                  DataCell(Text(jalali, style: const TextStyle(fontSize: 12))),
                  DataCell(Text(row['customer_name'] as String? ?? '---')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.statusColor(status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusColor(status),
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text((row['quantity'] as num?)?.toDouble().formattedInt ?? '')),
                  DataCell(Text((row['unit_price'] as num?)?.toDouble().formatted ?? '')),
                  DataCell(Text(
                    (row['discount_calculated_amount'] as num?)?.toDouble().formatted ?? '0',
                    style: const TextStyle(color: AppColors.warning),
                  )),
                  DataCell(Text(
                    (row['line_total'] as num?)?.toDouble().formatted ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent),
                  )),
                  DataCell(
                    Text(
                      profit.formatted,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: profit > 0
                            ? AppColors.success
                            : (profit < 0 ? AppColors.error : AppColors.textMuted),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
