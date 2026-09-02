import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../cubit/invoice_cubit.dart';
import '../../cubit/invoice_state.dart';

/// Invoice footer with live totals and save/print buttons.
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
          child: Row(
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
                    const SizedBox(width: 16),
                    _TotalCard(
                      label: AppStrings.totalDiscount,
                      value: state.totalDiscount.toman,
                      color: AppColors.warning,
                      icon: Icons.discount_outlined,
                    ),
                    const SizedBox(width: 16),
                    _TotalCard(
                      label: AppStrings.totalNet,
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
        );
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
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
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
