import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_units.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/jalali_utils.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/repositories/product_repository.dart';

/// Dialog for adding/editing a product.
/// When [showTemporaryOption] is true, shows a toggle for temp vs permanent product.
class ProductFormDialog extends StatefulWidget {
  final ProductModel? product;
  final String? nextCode;
  final bool showTemporaryOption;
  final String? initialName;

  const ProductFormDialog({
    super.key,
    this.product,
    this.nextCode,
    this.showTemporaryOption = false,
    this.initialName,
  });

  /// Shows the dialog and returns the product if saved.
  static Future<ProductModel?> show(
    BuildContext context, {
    ProductModel? product,
    String? nextCode,
    bool showTemporaryOption = false,
    String? initialName,
  }) {
    return showDialog<ProductModel>(
      context: context,
      builder: (_) => ProductFormDialog(
        product: product,
        nextCode: nextCode,
        showTemporaryOption: showTemporaryOption,
        initialName: initialName,
      ),
    );
  }

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ProductRepository();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _buyPriceCtrl;
  late final TextEditingController _currentBuyPriceCtrl;
  late final TextEditingController _sellPriceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _supplierCtrl;
  late String _selectedUnit;
  String? _buyDate;
  bool _isTemporary = false;
  List<String> _categories = [];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _codeCtrl = TextEditingController(text: p?.code ?? widget.nextCode ?? '');
    _nameCtrl = TextEditingController(text: p?.name ?? widget.initialName ?? '');
    _categoryCtrl = TextEditingController(text: p?.category ?? '');
    _buyPriceCtrl = TextEditingController(text: p != null ? p.buyPrice.toStringAsFixed(0) : '');
    _currentBuyPriceCtrl = TextEditingController(text: p?.currentBuyPrice != null ? p!.currentBuyPrice!.toStringAsFixed(0) : '');
    _sellPriceCtrl = TextEditingController(text: p?.sellPrice != null ? p!.sellPrice!.toStringAsFixed(0) : '');
    _stockCtrl = TextEditingController(text: p != null ? p.stock.toStringAsFixed(0) : '0');
    _supplierCtrl = TextEditingController(text: p?.supplier ?? '');
    _selectedUnit = p?.unit ?? AppUnits.defaultUnit;
    _buyDate = p?.buyDate;
    _isTemporary = p?.isTemporary ?? false;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _repo.getDistinctCategories();
    if (mounted) setState(() => _categories = cats);
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _buyPriceCtrl.dispose();
    _currentBuyPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _stockCtrl.dispose();
    _supplierCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final sellPriceText = _sellPriceCtrl.text.replaceAll(',', '').trim();
    final currentBuyPriceText = _currentBuyPriceCtrl.text.replaceAll(',', '').trim();
    final buyPrice = double.parse(_buyPriceCtrl.text.replaceAll(',', ''));

    final product = ProductModel(
      id: widget.product?.id,
      code: _codeCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
      buyPrice: buyPrice,
      currentBuyPrice: currentBuyPriceText.isNotEmpty ? double.tryParse(currentBuyPriceText) : buyPrice,
      sellPrice: sellPriceText.isNotEmpty ? double.tryParse(sellPriceText) : null,
      unit: _selectedUnit,
      stock: double.tryParse(_stockCtrl.text.replaceAll(',', '')) ?? 0,
      createdAt: widget.product?.createdAt,
      buyDate: _buyDate,
      supplier: _supplierCtrl.text.trim().isEmpty ? null : _supplierCtrl.text.trim(),
      isTemporary: _isTemporary,
    );

    Navigator.of(context).pop(product);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(_isEditing ? AppStrings.editProduct : AppStrings.addProduct),
        content: SizedBox(
          width: 450,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _codeCtrl,
                          decoration: const InputDecoration(labelText: AppStrings.productCode),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(labelText: AppStrings.productName),
                          validator: (v) => v == null || v.trim().isEmpty ? AppStrings.fieldRequired : null,
                          autofocus: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Category autocomplete
                      Expanded(
                        child: Autocomplete<String>(
                          initialValue: TextEditingValue(text: _categoryCtrl.text),
                          optionsBuilder: (textEditingValue) {
                            if (textEditingValue.text.isEmpty) return _categories;
                            return _categories.where(
                              (c) => c.contains(textEditingValue.text),
                            );
                          },
                          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                            // Keep sync with our controller
                            controller.addListener(() => _categoryCtrl.text = controller.text);
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(labelText: AppStrings.productCategory),
                            );
                          },
                          onSelected: (value) {
                            _categoryCtrl.text = value;
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topRight,
                              child: Material(
                                elevation: 8,
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(10),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final cat = options.elementAt(index);
                                      return ListTile(
                                        dense: true,
                                        title: Text(cat),
                                        leading: const Icon(Icons.category, size: 18),
                                        onTap: () => onSelected(cat),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: const InputDecoration(labelText: AppStrings.productUnit),
                          items: AppUnits.all
                              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedUnit = v ?? AppUnits.defaultUnit),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _buyPriceCtrl,
                          decoration: const InputDecoration(
                            labelText: AppStrings.productBuyPrice,
                            suffixText: AppStrings.toman,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return AppStrings.fieldRequired;
                            if (double.tryParse(v.replaceAll(',', '')) == null) return AppStrings.invalidNumber;
                            return null;
                          },
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _currentBuyPriceCtrl,
                          decoration: const InputDecoration(
                            labelText: AppStrings.productCurrentBuyPrice,
                            suffixText: AppStrings.toman,
                            hintText: 'در صورت خالی بودن برابر قیمت اولیه است',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              if (double.tryParse(v.replaceAll(',', '')) == null) return AppStrings.invalidNumber;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sellPriceCtrl,
                          decoration: const InputDecoration(
                            labelText: AppStrings.productSellPrice,
                            suffixText: AppStrings.toman,
                            hintText: 'اختیاری',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              if (double.tryParse(v.replaceAll(',', '')) == null) return AppStrings.invalidNumber;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stockCtrl,
                          decoration: const InputDecoration(labelText: AppStrings.productStock),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _supplierCtrl,
                          decoration: const InputDecoration(labelText: AppStrings.productSupplier),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showPersianDatePicker(
                              context: context,
                              initialDate: _buyDate != null ? JalaliUtils.fromIso(_buyDate!) : Jalali.now(),
                              firstDate: Jalali(1300, 1),
                              lastDate: Jalali(1450, 12),
                            );
                            if (picked != null) {
                              setState(() => _buyDate = JalaliUtils.toIso(picked));
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: AppStrings.productBuyDate,
                              suffixIcon: Icon(Icons.calendar_today, size: 18),
                            ),
                            child: Text(
                              _buyDate != null ? JalaliUtils.format(JalaliUtils.fromIso(_buyDate!)) : '---',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Temp / Permanent toggle — only visible from invoice product search
                  if (widget.showTemporaryOption) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.dividerDark),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Text(AppStrings.productType,
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          const Spacer(),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: false, label: Text(AppStrings.permanentProduct), icon: Icon(Icons.save_outlined, size: 16)),
                              ButtonSegment(value: true, label: Text(AppStrings.tempProduct), icon: Icon(Icons.timer_outlined, size: 16)),
                            ],
                            selected: {_isTemporary},
                            onSelectionChanged: (v) => setState(() => _isTemporary = v.first),
                            style: ButtonStyle(
                              textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: _submit,
            child: Text(_isEditing ? AppStrings.save : AppStrings.addProduct),
          ),
        ],
      ),
    );
  }
}
