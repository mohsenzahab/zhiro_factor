import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../data/models/supplier_model.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../invoice/view/widgets/product_search_dialog.dart';
import '../../suppliers/view/widgets/supplier_form_dialog.dart';
import '../cubit/purchase_cubit.dart';
import '../cubit/purchase_state.dart';

/// Main purchase creation/editing page.
class PurchasePage extends StatelessWidget {
  final int? editPurchaseId;
  final VoidCallback? onSavedAndGoBack;

  const PurchasePage({super.key, this.editPurchaseId, this.onSavedAndGoBack});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = PurchaseCubit();
        if (editPurchaseId != null) {
          cubit.loadExisting(editPurchaseId!);
        } else {
          cubit.initNew();
        }
        return cubit;
      },
      child: _PurchaseView(
        editPurchaseId: editPurchaseId,
        onSavedAndGoBack: onSavedAndGoBack,
      ),
    );
  }
}

class _PurchaseView extends StatelessWidget {
  final int? editPurchaseId;
  final VoidCallback? onSavedAndGoBack;

  const _PurchaseView({this.editPurchaseId, this.onSavedAndGoBack});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PurchaseCubit, PurchaseState>(
      listenWhen: (prev, curr) => !prev.isSaved && curr.isSaved,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.purchaseSaved)),
        );
        if (editPurchaseId != null && onSavedAndGoBack != null) {
          onSavedAndGoBack!();
        } else {
          context.read<PurchaseCubit>().reset();
        }
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.f2): () => _addProduct(context),
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
              context.read<PurchaseCubit>().save(),
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
                    Icon(Icons.shopping_cart, color: AppColors.accent, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      editPurchaseId != null ? AppStrings.editPurchase : AppStrings.newPurchase,
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
                _PurchaseHeader(),
                const SizedBox(height: 16),

                // ── Items Grid ────────────────────────────────────
                Expanded(
                  child: _PurchaseItemsGrid(),
                ),
                const SizedBox(height: 8),

                // ── Add Item Button ──────────────────────────────
                Row(
                  children: [
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
                const SizedBox(height: 16),

                // ── Footer ────────────────────────────────────────
                _PurchaseFooter(),
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
      context.read<PurchaseCubit>().addItem(product);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Purchase Header: number, date, supplier, status
// ═══════════════════════════════════════════════════════════════════

class _PurchaseHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PurchaseCubit, PurchaseState>(
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
              // Purchase Number
              Expanded(
                child: _buildField(
                  context,
                  label: AppStrings.purchaseNumber,
                  child: TextFormField(
                    initialValue: state.purchaseNumber,
                    onChanged: (v) => context.read<PurchaseCubit>().setPurchaseNumber(v),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Date Picker
              Expanded(
                child: _buildField(
                  context,
                  label: AppStrings.purchaseDate,
                  child: InkWell(
                    onTap: () => _pickDate(context),
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        state.date.isNotEmpty
                            ? JalaliUtils.format(JalaliUtils.fromIso(state.date))
                            : '---',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Supplier Search with Create
              Expanded(
                flex: 2,
                child: _buildField(
                  context,
                  label: AppStrings.selectSupplier,
                  child: _SupplierSearchField(
                    initialSupplier: state.selectedSupplier,
                    onSelected: (s) => context.read<PurchaseCubit>().setSupplier(s),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Status Dropdown
              Expanded(
                child: _buildField(
                  context,
                  label: AppStrings.invoiceStatus,
                  child: DropdownButtonFormField<String>(
                    initialValue: state.status,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: AppStrings.purchaseStatuses.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.statusColor(s),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) context.read<PurchaseCubit>().setStatus(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField(BuildContext context, {required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final cubit = context.read<PurchaseCubit>();
    final currentJalali = cubit.state.date.isNotEmpty
        ? JalaliUtils.fromIso(cubit.state.date)
        : Jalali.now();

    final picked = await showPersianDatePicker(
      context: context,
      initialDate: currentJalali,
      firstDate: Jalali(1400),
      lastDate: Jalali(1430),
    );

    if (picked != null) {
      cubit.setDate(JalaliUtils.toIso(picked));
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Supplier Search Field (similar to Customer Search)
// ═══════════════════════════════════════════════════════════════════

class _SupplierSearchField extends StatefulWidget {
  final SupplierModel? initialSupplier;
  final ValueChanged<SupplierModel?> onSelected;

  const _SupplierSearchField({this.initialSupplier, required this.onSelected});

  @override
  State<_SupplierSearchField> createState() => _SupplierSearchFieldState();
}

class _SupplierSearchFieldState extends State<_SupplierSearchField> {
  final SupplierRepository _repo = SupplierRepository();
  final _focusNode = FocusNode();
  late final TextEditingController _controller;
  SupplierModel? _selectedSupplier;
  List<SupplierModel> _suggestions = [];
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _selectedSupplier = widget.initialSupplier;
    _controller = TextEditingController(text: widget.initialSupplier?.name ?? '');
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _SupplierSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSupplier != oldWidget.initialSupplier) {
      _selectedSupplier = widget.initialSupplier;
      _controller.text = widget.initialSupplier?.name ?? '';
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        _hideOverlay();
        final text = _controller.text.trim();
        if (text.isNotEmpty && (_selectedSupplier == null || _selectedSupplier!.name != text)) {
          setState(() {
            _selectedSupplier = null;
            _controller.clear();
          });
          widget.onSelected(null);
        }
      });
    }
  }

  Future<void> _showCreateSupplierDialog(String typedName) async {
    final nextCode = await _repo.nextCode();
    if (!mounted) return;

    final result = await SupplierFormDialog.show(
      context,
      nextCode: nextCode,
      initialName: typedName,
    );

    if (result != null && mounted) {
      final newId = await _repo.insert(result);
      final saved = result.copyWith(id: newId);
      setState(() {
        _selectedSupplier = saved;
        _controller.text = saved.name;
      });
      widget.onSelected(saved);
    } else {
      setState(() {
        _selectedSupplier = null;
        _controller.clear();
      });
      widget.onSelected(null);
    }
  }

  Future<void> _onTextChanged(String text) async {
    if (text.isEmpty) {
      _hideSuggestions();
      return;
    }
    _suggestions = await _repo.getAll(query: text);
    _showSuggestionsOverlay();
  }

  void _selectSupplier(SupplierModel supplier) {
    _selectedSupplier = supplier;
    _controller.text = supplier.name;
    widget.onSelected(supplier);
    _hideOverlay();
  }

  void _showSuggestionsOverlay() {
    _hideOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _suggestions = [];
    _hideOverlay();
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    ..._suggestions.map((s) => ListTile(
                          dense: true,
                          title: Text(s.name),
                          subtitle: Text(s.phone ?? '', style: const TextStyle(fontSize: 11)),
                          leading: const Icon(Icons.local_shipping, size: 20),
                          onTap: () => _selectSupplier(s),
                        )),
                    Divider(height: 1, color: AppColors.dividerDark),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.add_business, size: 20, color: AppColors.accent),
                      title: Text(
                        '${AppStrings.createNewSupplier}: «${_controller.text}»',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () {
                        _hideOverlay();
                        _showCreateSupplierDialog(_controller.text.trim());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onTextChanged,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          hintText: 'نام تأمین‌کننده را تایپ کنید...',
          suffixIcon: _selectedSupplier != null
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    _selectedSupplier = null;
                    _controller.clear();
                    widget.onSelected(null);
                  },
                )
              : const Icon(Icons.local_shipping_outlined, size: 18),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Purchase Items Grid
// ═══════════════════════════════════════════════════════════════════

class _PurchaseItemsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PurchaseCubit, PurchaseState>(
      builder: (context, state) {
        if (state.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_basket_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  'کالایی اضافه نشده\nبرای افزودن کالا، دکمه «${AppStrings.addItem}» را بزنید یا F2 فشار دهید',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.dividerDark),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.tableHeader,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    _headerCell('ردیف', flex: 1),
                    _headerCell('نام کالا', flex: 3),
                    _headerCell('قیمت واحد', flex: 2),
                    _headerCell('تعداد', flex: 1),
                    _headerCell('جمع سطر', flex: 2),
                    const SizedBox(width: 40), // delete button space
                  ],
                ),
              ),

              // Items
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    final isEven = index % 2 == 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: isEven ? AppColors.tableRowEven : AppColors.tableRowOdd,
                      child: Row(
                        children: [
                          // Row number
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${index + 1}'.toPersianDigits(),
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          // Product name
                          Expanded(
                            flex: 3,
                            child: Text(
                              item.productName,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Unit price
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 36,
                              child: TextFormField(
                                initialValue: item.unitPrice.round().toString().toPersianDigits(),
                                onFieldSubmitted: (v) {
                                  final price = double.tryParse(v.toEnglishDigits());
                                  if (price != null) {
                                    context.read<PurchaseCubit>().updateItemPrice(index, price);
                                  }
                                },
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  suffixText: 'تومان',
                                ),
                                style: const TextStyle(fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          // Quantity
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 36,
                              child: TextFormField(
                                initialValue: item.quantity == item.quantity.roundToDouble()
                                    ? item.quantity.toInt().toString().toPersianDigits()
                                    : item.quantity.toString().toPersianDigits(),
                                onFieldSubmitted: (v) {
                                  final qty = double.tryParse(v.toEnglishDigits());
                                  if (qty != null && qty > 0) {
                                    context.read<PurchaseCubit>().updateItemQuantity(index, qty);
                                  }
                                },
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                style: const TextStyle(fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          // Line total
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${item.lineTotal.round().formatted} تومان',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Delete button
                          SizedBox(
                            width: 40,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              onPressed: () => context.read<PurchaseCubit>().removeItem(index),
                              splashRadius: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Purchase Footer: notes, costs, totals, save
// ═══════════════════════════════════════════════════════════════════

class _PurchaseFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PurchaseCubit, PurchaseState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.dividerDark),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Notes
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.purchaseNotes,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: state.notes ?? '',
                      maxLines: 3,
                      onChanged: (v) => context.read<PurchaseCubit>().setNotes(v),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'یادداشت برای این خرید...',
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Right: Costs & Totals
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shipping Cost
                    Row(
                      children: [
                        Expanded(
                          child: Text(AppStrings.shippingCost,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ),
                        SizedBox(
                          width: 160,
                          child: TextFormField(
                            initialValue: state.shippingCost > 0
                                ? state.shippingCost.round().toString().toPersianDigits()
                                : '',
                            onChanged: (v) {
                              final val = double.tryParse(v.toEnglishDigits()) ?? 0;
                              context.read<PurchaseCubit>().setShippingCost(val);
                            },
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              suffixText: 'تومان',
                              hintText: '۰',
                            ),
                            style: const TextStyle(fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Extra Costs
                    Row(
                      children: [
                        Expanded(
                          child: Text(AppStrings.extraCosts,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ),
                        SizedBox(
                          width: 160,
                          child: TextFormField(
                            initialValue: state.extraCosts > 0
                                ? state.extraCosts.round().toString().toPersianDigits()
                                : '',
                            onChanged: (v) {
                              final val = double.tryParse(v.toEnglishDigits()) ?? 0;
                              context.read<PurchaseCubit>().setExtraCosts(val);
                            },
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              suffixText: 'تومان',
                              hintText: '۰',
                            ),
                            style: const TextStyle(fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: AppColors.dividerDark),
                    const SizedBox(height: 8),

                    // Items Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppStrings.purchaseItemsTotal,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text('${state.totalAmount.round().formatted} تومان',
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Net Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppStrings.purchaseNetTotal,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.accent)),
                        Text('${state.totalNet.round().formatted} تومان',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.accent)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Save Button
              Column(
                children: [
                  if (state.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                  SizedBox(
                    height: 48,
                    width: 160,
                    child: ElevatedButton.icon(
                      onPressed: state.isSaving ? null : () => context.read<PurchaseCubit>().save(),
                      icon: state.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(state.isSaving ? AppStrings.loading : AppStrings.savePurchase),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

// ═══════════════════════════════════════════════════════════════════
// Shortcut Badge
// ═══════════════════════════════════════════════════════════════════

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
