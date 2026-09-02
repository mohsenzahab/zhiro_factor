import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../cubit/invoice_cubit.dart';
import '../../cubit/invoice_state.dart';

/// Invoice line items data grid with inline editing.
class InvoiceItemsGrid extends StatelessWidget {
  const InvoiceItemsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceCubit, InvoiceState>(
      builder: (context, state) {
        if (state.items.isEmpty) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dividerDark),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_shopping_cart,
                      size: 48, color: AppColors.textMuted.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text(
                    'کالایی به فاکتور اضافه نشده است',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'از دکمه «${AppStrings.addItem}» یا کلید F2 استفاده کنید',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
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
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                columnSpacing: 16,
                horizontalMargin: 12,
                headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
                columns: const [
                  DataColumn(label: Text(AppStrings.rowNumber)),
                  DataColumn(label: Text(AppStrings.productCode)),
                  DataColumn(label: Text(AppStrings.productName)),
                  DataColumn(label: Text(AppStrings.quantity)),
                  DataColumn(label: Text(AppStrings.unitPrice)),
                  DataColumn(label: Text(AppStrings.discountType)),
                  DataColumn(label: Text(AppStrings.discountValue)),
                  DataColumn(label: Text(AppStrings.discountAmount)),
                  DataColumn(label: Text(AppStrings.lineTotal)),
                  DataColumn(label: Text('')), // Delete
                ],
                rows: List.generate(state.items.length, (index) {
                  final item = state.items[index];
                  return DataRow(
                    color: WidgetStateProperty.all(
                      index.isEven ? AppColors.tableRowEven : AppColors.tableRowOdd,
                    ),
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(Text(item.productId?.toString() ?? '-')),
                      DataCell(Text(item.productName,
                          style: const TextStyle(fontWeight: FontWeight.w500))),
                      // Quantity
                      DataCell(_InlineNumberField(
                        value: item.quantity,
                        onChanged: (v) => context.read<InvoiceCubit>().updateItemQuantity(index, v),
                      )),
                      // Unit Price
                      DataCell(_InlineNumberField(
                        value: item.unitPrice,
                        onChanged: (v) => context.read<InvoiceCubit>().updateItemPrice(index, v),
                      )),
                      // Discount Type
                      DataCell(
                        DropdownButton<String>(
                          value: item.discountType,
                          underline: const SizedBox.shrink(),
                          isDense: true,
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                          dropdownColor: AppColors.cardDark,
                          items: const [
                            DropdownMenuItem(value: 'none', child: Text(AppStrings.discountNone)),
                            DropdownMenuItem(
                                value: 'percentage', child: Text(AppStrings.discountPercentage)),
                            DropdownMenuItem(
                                value: 'amount', child: Text(AppStrings.discountFixed)),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              context.read<InvoiceCubit>().updateItemDiscountType(index, v);
                            }
                          },
                        ),
                      ),
                      // Discount Value
                      DataCell(
                        item.discountType == 'none'
                            ? const Text('-')
                            : _InlineNumberField(
                                value: item.discountValue,
                                onChanged: (v) => context
                                    .read<InvoiceCubit>()
                                    .updateItemDiscountValue(index, v),
                              ),
                      ),
                      // Calculated discount
                      DataCell(Text(item.discountCalculatedAmount.formatted,
                          style: TextStyle(color: AppColors.warning, fontSize: 12))),
                      // Line Total
                      DataCell(Text(
                        item.lineTotal.formatted,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      )),
                      // Delete
                      DataCell(IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: AppColors.error,
                        tooltip: AppStrings.delete,
                        onPressed: () => context.read<InvoiceCubit>().removeItem(index),
                      )),
                    ],
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Compact inline number editing field for the grid.
class _InlineNumberField extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _InlineNumberField({required this.value, required this.onChanged});

  @override
  State<_InlineNumberField> createState() => _InlineNumberFieldState();
}

class _InlineNumberFieldState extends State<_InlineNumberField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(covariant _InlineNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final newText = _format(widget.value);
      if (_ctrl.text != newText) {
        _ctrl.text = newText;
      }
    }
  }

  String _format(double v) {
    if (v == v.toInt().toDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          filled: true,
          fillColor: AppColors.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: AppColors.dividerDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: AppColors.dividerDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
        onChanged: (text) {
          final parsed = double.tryParse(text.replaceAll(',', ''));
          if (parsed != null) widget.onChanged(parsed);
        },
      ),
    );
  }
}
