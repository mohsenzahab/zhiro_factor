import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../cubit/invoice_cubit.dart';
import '../../cubit/invoice_state.dart';

/// Invoice footer with live totals, overall discount, and save/print buttons.
class InvoiceFooter extends StatelessWidget {
  final VoidCallback? onPrint;

  const InvoiceFooter({super.key, this.onPrint});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceCubit, InvoiceState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.dividerDark),
          ),
          child: Column(
            children: [
              // ── Overall Discount Row ─────────────────────────
              _OverallDiscountRow(state: state),
              const SizedBox(height: 16),

              Row(
                children: [
                  // ── Totals ──────────────────────────────────────
                  Expanded(
                    child: Row(
                      children: [
                        _TotalCard(
                          label: AppStrings.totalGross,
                          value: state.totalGross.toman,
                          color: AppColors.textPrimary,
                          icon: Icons.receipt,
                        ),
                        const SizedBox(width: 12),
                        _TotalCard(
                          label: AppStrings.totalDiscount,
                          value: state.totalDiscount.toman,
                          color: AppColors.warning,
                          icon: Icons.discount_outlined,
                        ),
                        const SizedBox(width: 12),
                        _TotalCard(
                          label: AppStrings.finalPayable,
                          value: state.totalNet.toman,
                          color: AppColors.accent,
                          icon: Icons.payments_outlined,
                          isHighlighted: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // ── Actions ─────────────────────────────────────
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 160,
                        child: ElevatedButton.icon(
                          onPressed: state.isSaving
                              ? null
                              : () async {
                                    await context.read<InvoiceCubit>().save();
                                    if (context.mounted) {
                                      final newState = context.read<InvoiceCubit>().state;
                                      if (newState.errorMessage != null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(newState.errorMessage!),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                          icon: state.isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save, size: 20),
                          label: Text(AppStrings.saveInvoice),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 160,
                        child: OutlinedButton.icon(
                          onPressed: onPrint,
                          icon: const Icon(Icons.print, size: 20),
                          label: const Text(AppStrings.printInvoice),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Inline row for applying an overall discount to the entire invoice.
class _OverallDiscountRow extends StatelessWidget {
  final InvoiceState state;

  const _OverallDiscountRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InvoiceCubit>();
    final hasDiscount = state.overallDiscountType != 'none';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasDiscount
            ? AppColors.warning.withValues(alpha: 0.06)
            : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasDiscount
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.dividerDark,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.discount,
            size: 18,
            color: hasDiscount ? AppColors.warning : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            AppStrings.overallDiscount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: hasDiscount ? AppColors.warning : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 16),

          // Discount Type Dropdown
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String>(
              value: state.overallDiscountType,
              isExpanded: true,
              isDense: true,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              dropdownColor: AppColors.cardDark,
              items: const [
                DropdownMenuItem(value: 'none', child: Text(AppStrings.discountNone)),
                DropdownMenuItem(value: 'percentage', child: Text(AppStrings.discountPercentage)),
                DropdownMenuItem(value: 'amount', child: Text(AppStrings.discountFixed)),
              ],
              onChanged: (v) {
                if (v != null) cubit.setOverallDiscountType(v);
              },
            ),
          ),
          const SizedBox(width: 12),

          // Discount Value Input (only if type != 'none')
          if (state.overallDiscountType != 'none') ...[
            SizedBox(
              width: 120,
              child: _OverallDiscountField(
                value: state.overallDiscountValue,
                suffix: state.overallDiscountType == 'percentage' ? '%' : AppStrings.toman,
                onChanged: cubit.setOverallDiscountValue,
              ),
            ),
            const SizedBox(width: 16),
            // Show calculated amount
            Text(
              'تخفیف: ${state.overallDiscountAmount.formatted}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const Spacer(),

          // Subtotal after item discounts (before overall)
          if (hasDiscount && state.totalItemDiscount > 0)
            Text(
              '${AppStrings.subtotalBeforeOverallDiscount}: ${state.subtotalAfterItemDiscounts.formatted}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}

/// Compact text field for entering overall discount value.
class _OverallDiscountField extends StatefulWidget {
  final double value;
  final String suffix;
  final ValueChanged<double> onChanged;

  const _OverallDiscountField({
    required this.value,
    required this.suffix,
    required this.onChanged,
  });

  @override
  State<_OverallDiscountField> createState() => _OverallDiscountFieldState();
}

class _OverallDiscountFieldState extends State<_OverallDiscountField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(covariant _OverallDiscountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final newText = _format(widget.value);
      if (_ctrl.text != newText) {
        _ctrl.text = newText;
      }
    }
  }

  String _format(double v) {
    if (v == 0) return '';
    if (v == v.toInt().toDouble()) return v.toInt().toString().toPersianDigits();
    return v.toStringAsFixed(1).toPersianDigits();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        hintText: AppStrings.overallDiscountValue,
        suffixText: widget.suffix,
        suffixStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.cardDark,
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
          borderSide: BorderSide(color: AppColors.warning),
        ),
      ),
      onChanged: (text) {
        final parsed = text.tryParseFormatted();
        widget.onChanged(parsed ?? 0.0);
      },
    );
  }
}

class _TotalCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isHighlighted;

  const _TotalCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isHighlighted ? color.withValues(alpha: 0.08) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isHighlighted ? color.withValues(alpha: 0.3) : AppColors.dividerDark,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
