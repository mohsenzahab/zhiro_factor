import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/pdf_service.dart';
import '../cubit/invoice_cubit.dart';
import '../cubit/invoice_state.dart';
import 'widgets/invoice_header.dart';
import 'widgets/product_search_dialog.dart';
import 'widgets/invoice_items_grid.dart';
import 'widgets/invoice_footer.dart';

/// Main invoice creation/editing page.
class InvoicePage extends StatelessWidget {
  final int? editInvoiceId;
  final VoidCallback? onSavedAndGoBack;

  const InvoicePage({super.key, this.editInvoiceId, this.onSavedAndGoBack});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = InvoiceCubit();
        if (editInvoiceId != null) {
          cubit.loadExisting(editInvoiceId!);
        } else {
          cubit.initNew();
        }
        return cubit;
      },
      child: _InvoiceView(
        editInvoiceId: editInvoiceId,
        onSavedAndGoBack: onSavedAndGoBack,
      ),
    );
  }
}

class _InvoiceView extends StatelessWidget {
  final int? editInvoiceId;
  final VoidCallback? onSavedAndGoBack;

  const _InvoiceView({this.editInvoiceId, this.onSavedAndGoBack});

  @override
  Widget build(BuildContext context) {
    return BlocListener<InvoiceCubit, InvoiceState>(
      listenWhen: (prev, curr) => !prev.isSaved && curr.isSaved,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فاکتور با موفقیت ذخیره شد')),
        );
        if (editInvoiceId != null && onSavedAndGoBack != null) {
          // Editing existing invoice → go back to history
          onSavedAndGoBack!();
        } else {
          // New invoice → reset form
          context.read<InvoiceCubit>().reset();
        }
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.f2): () => _addProduct(context),
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
              context.read<InvoiceCubit>().save(),
        },
        child: Focus(
          autofocus: true,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title Bar ─────────────────────────────────────
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      editInvoiceId != null ? AppStrings.editInvoice : AppStrings.newInvoice,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    _ShortcutBadge(label: 'Ctrl+S', description: AppStrings.save),
                    const SizedBox(width: 8),
                    _ShortcutBadge(label: 'F2', description: AppStrings.addItem),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _addProduct(context),
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text(AppStrings.addItem),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Header ────────────────────────────────────────
                const InvoiceHeader(),
                const SizedBox(height: 16),

                // ── Items Grid ────────────────────────────────────
                Expanded(
                  child: const InvoiceItemsGrid(),
                ),
                const SizedBox(height: 16),

                // ── Footer ────────────────────────────────────────
                InvoiceFooter(
                  onPrint: () => _printInvoice(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addProduct(BuildContext context) async {
    final product = await ProductSearchDialog.show(context);
    if (product != null && context.mounted) {
      context.read<InvoiceCubit>().addItem(product);
    }
  }

  Future<void> _printInvoice(BuildContext context) async {
    final state = context.read<InvoiceCubit>().state;
    if (state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فاکتور خالی است')),
      );
      return;
    }
    await PdfService.printInvoice(context, state);
  }
}

class _ShortcutBadge extends StatelessWidget {
  final String label;
  final String description;

  const _ShortcutBadge({required this.label, required this.description});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.dividerDark),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
