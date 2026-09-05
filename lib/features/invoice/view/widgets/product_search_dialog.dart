import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../../products/view/widgets/product_form_dialog.dart';

/// Fast product search modal for adding items to invoice.
/// Always shows a "Create Product" button at the bottom of the list.
class ProductSearchDialog extends StatefulWidget {
  const ProductSearchDialog({super.key});

  /// Shows the dialog and returns the selected product.
  static Future<ProductModel?> show(BuildContext context) {
    return showDialog<ProductModel>(
      context: context,
      builder: (_) => const ProductSearchDialog(),
    );
  }

  @override
  State<ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<ProductSearchDialog> {
  final _repo = ProductRepository();
  final _searchCtrl = TextEditingController();
  List<ProductModel> _results = [];
  bool _loading = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    _results = await _repo.getAll();
    setState(() => _loading = false);
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    _results = await _repo.getAll(query: query);
    _selectedIndex = 0;
    setState(() => _loading = false);
  }

  void _selectProduct(ProductModel product) {
    Navigator.of(context).pop(product);
  }

  /// Opens the product form dialog to create a new product.
  /// The [showTemporaryOption] is set to true so the user can choose temp vs perm.
  Future<void> _createProduct() async {
    final nextCode = await _repo.nextCode();
    if (!mounted) return;

    final product = await ProductFormDialog.show(
      context,
      nextCode: nextCode,
      showTemporaryOption: true,
      initialName: _searchCtrl.text.trim(),
    );

    if (product != null) {
      // Save to DB (even temp products get saved, but flagged)
      final newId = await _repo.insert(product);
      final savedProduct = product.copyWith(id: newId);
      if (mounted) {
        _selectProduct(savedProduct);
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 550,
          height: 520,
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.search, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.addItem,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'F2',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      onChanged: _search,
                      onSubmitted: (_) {
                        if (_results.isNotEmpty) {
                          _selectProduct(_results[_selectedIndex]);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'کد یا نام کالا را وارد کنید...',
                        prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.dividerDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Results ───────────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildResultsList(),
              ),

              // ── Create Product Button (always visible) ────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(top: BorderSide(color: AppColors.dividerDark)),
                ),
                child: InkWell(
                  onTap: _createProduct,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, color: AppColors.accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.createProduct,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _searchCtrl.text.isNotEmpty
                                  ? 'ساخت «${_searchCtrl.text}» به عنوان کالای جدید'
                                  : 'تعریف کالای جدید برای افزودن به فاکتور',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text(
              'کالایی یافت نشد',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            const Text(
              'از دکمه پایین برای ساخت کالای جدید استفاده کنید',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _results.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.dividerDark),
      itemBuilder: (context, index) {
        final p = _results[index];
        final isSelected = index == _selectedIndex;
        return ListTile(
          selected: isSelected,
          selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
          dense: true,
          onTap: () => _selectProduct(p),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.isTemporary
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: p.isTemporary
                  ? const Icon(Icons.timer_outlined, size: 18, color: AppColors.warning)
                  : Text(
                      p.code ?? '#',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
          title: Text(
            p.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '${p.effectivePrice.toman} • ${p.unit} • موجودی: ${p.stock.formattedInt}',
            style: const TextStyle(fontSize: 11),
          ),
          trailing: const Icon(
            Icons.add_circle_outline,
            size: 20,
            color: AppColors.accent,
          ),
        );
      },
    );
  }
}
