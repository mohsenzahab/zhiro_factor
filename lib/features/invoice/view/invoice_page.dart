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
import 'widgets/preset_template_dialog.dart';
import 'widgets/invoice_items_grid.dart';
import 'widgets/invoice_footer.dart';
import 'widgets/invoice_preview_dialog.dart';
import 'widgets/invoice_item_form_dialog.dart';
import '../../../shared/widgets/app_scaffold.dart';

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

class _InvoiceView extends StatefulWidget {
  final int? editInvoiceId;
  final VoidCallback? onSavedAndGoBack;

  const _InvoiceView({this.editInvoiceId, this.onSavedAndGoBack});

  @override
  State<_InvoiceView> createState() => _InvoiceViewState();
}

class _InvoiceViewState extends State<_InvoiceView> {
  @override
  void initState() {
    super.initState();
    // Register global interceptor for sidebar navigation
    AppScaffoldState.onWillNavigateAway = _onWillNavigateAway;
  }

  @override
  void dispose() {
    // Clear global interceptor when leaving
    AppScaffoldState.onWillNavigateAway = null;
    super.dispose();
  }

  Future<bool> _onWillNavigateAway() async {
    final state = context.read<InvoiceCubit>().state;
    // Only warn if not saved and has data (items or customer)
    if (!state.isSaved && (state.items.isNotEmpty || state.selectedCustomer != null)) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('فاکتور ذخیره نشده است', style: TextStyle(color: AppColors.error)),
          content: const Text('آیا مطمئن هستید که می‌خواهید خارج شوید؟ اطلاعات ثبت شده از دست خواهد رفت.', style: TextStyle(color: AppColors.textPrimary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('خروج و حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return shouldLeave ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final canPop = await _onWillNavigateAway();
        if (canPop && context.mounted) {
          // If we are editing, we can go back
          if (widget.editInvoiceId != null && widget.onSavedAndGoBack != null) {
            widget.onSavedAndGoBack!();
          }
        }
      },
      child: BlocListener<InvoiceCubit, InvoiceState>(
        listenWhen: (prev, curr) => !prev.isSaved && curr.isSaved,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فاکتور با موفقیت ذخیره شد')),
          );
          if (widget.editInvoiceId != null && widget.onSavedAndGoBack != null) {
            // Editing existing invoice → go back to history
            widget.onSavedAndGoBack!();
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
                      widget.editInvoiceId != null ? AppStrings.editInvoice : AppStrings.newInvoice,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    _ShortcutBadge(label: 'Ctrl+S', description: AppStrings.save),
                    const SizedBox(width: 8),
                    _ShortcutBadge(label: 'F2', description: AppStrings.addItem),
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
                const SizedBox(height: 8),

                // ── Add Item & Load Template Buttons ──────────────
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _addProduct(context, detailed: false),
                      icon: const Icon(Icons.flash_on, size: 20),
                      label: const Text('سریع'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _addProduct(context, detailed: true),
                      icon: const Icon(Icons.edit_note, size: 20),
                      label: const Text('دقیق'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _loadTemplate(context),
                      icon: const Icon(Icons.library_books_outlined, size: 18),
                      label: const Text(AppStrings.loadTemplate),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                      ),
                    ),
                    const Spacer(),
                    BlocBuilder<InvoiceCubit, InvoiceState>(
                      builder: (context, state) {
                        if (state.items.isEmpty) return const SizedBox.shrink();
                        return TextButton.icon(
                          onPressed: () => _saveAsTemplate(context),
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text(AppStrings.saveAsTemplate),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Footer ────────────────────────────────────────
                InvoiceFooter(
                  onPrint: () => _previewInvoice(context),
                  onQuickPrint: () => _quickPrintInvoice(context),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Future<void> _addProduct(BuildContext context, {bool detailed = false}) async {
    final product = await ProductSearchDialog.show(context);
    if (product != null && context.mounted) {
      if (detailed) {
        final item = await InvoiceItemFormDialog.show(context, product);
        if (item != null && context.mounted) {
          context.read<InvoiceCubit>().addDetailedItem(item);
        }
      } else {
        context.read<InvoiceCubit>().addItem(product);
      }
    }
  }

  Future<void> _previewInvoice(BuildContext context) async {
    final state = context.read<InvoiceCubit>().state;
    if (state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فاکتور خالی است')),
      );
      return;
    }
    await InvoicePreviewDialog.showFromState(context, state);
  }

  Future<void> _quickPrintInvoice(BuildContext context) async {
    final state = context.read<InvoiceCubit>().state;
    if (state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فاکتور خالی است')),
      );
      return;
    }
    await PdfService.printInvoice(state);
  }

  Future<void> _loadTemplate(BuildContext context) async {
    final template = await PresetTemplateDialog.show(context);
    if (template != null && context.mounted) {
      context.read<InvoiceCubit>().loadFromTemplate(template);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.templateLoaded)),
      );
    }
  }

  Future<void> _saveAsTemplate(BuildContext context) async {
    final name = await SaveAsTemplateDialog.show(context);
    if (name != null && name.isNotEmpty && context.mounted) {
      await context.read<InvoiceCubit>().saveAsTemplate(name);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.templateSaved)),
        );
      }
    }
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
