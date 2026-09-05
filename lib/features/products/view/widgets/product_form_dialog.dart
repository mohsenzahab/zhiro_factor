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
  late final TextEditingController _profitMarginCtrl;
  late final TextEditingController _sellPriceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _supplierCtrl;
  late String _selectedUnit;
  String? _buyDate;
  bool _isTemporary = false;
  bool _isInfiniteStock = false;
  List<String> _categories = [];
  bool _isAutoCalculating = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _codeCtrl = TextEditingController(text: p?.code ?? widget.nextCode ?? '');
    _nameCtrl = TextEditingController(text: p?.name ?? widget.initialName ?? '');
    _categoryCtrl = TextEditingController(text: p?.category ?? '');
    _buyPriceCtrl = TextEditingController(text: p != null ? p.buyPrice.round().toString() : '');
    _currentBuyPriceCtrl = TextEditingController(
      text: p?.currentBuyPrice != null ? p!.currentBuyPrice!.round().toString() : '',
    );

    // Initial profit margin percentage based on current buy price (or buy price)
    String initialProfitMargin = '';
    if (p != null && p.sellPrice != null) {
      final basePrice = (p.currentBuyPrice != null && p.currentBuyPrice! > 0)
          ? p.currentBuyPrice!
          : p.buyPrice;
      if (basePrice > 0) {
        final pct = ((p.sellPrice! - basePrice) / basePrice) * 100.0;
        initialProfitMargin = pct % 1 == 0 ? pct.toStringAsFixed(0) : pct.toStringAsFixed(1);
      }
    }
    _profitMarginCtrl = TextEditingController(text: initialProfitMargin);
    _sellPriceCtrl = TextEditingController(
      text: p?.sellPrice != null ? p!.sellPrice!.round().toString() : '',
    );
    _isInfiniteStock = p?.isInfiniteStock ?? false;
    _stockCtrl = TextEditingController(
      text: (p != null && !p.isInfiniteStock && p.stock != null)
          ? p.stock!.round().toString()
          : (_isInfiniteStock ? '' : '0'),
    );
    _supplierCtrl = TextEditingController(text: p?.supplier ?? '');
    _selectedUnit = p?.unit ?? AppUnits.defaultUnit;
    _buyDate = p?.buyDate;
    _isTemporary = p?.isTemporary ?? false;
    _loadCategories();

    _currentBuyPriceCtrl.addListener(_onBuyPriceOrCurrentBuyPriceChanged);
    _buyPriceCtrl.addListener(_onBuyPriceOrCurrentBuyPriceChanged);
    _profitMarginCtrl.addListener(_onProfitMarginChanged);
    _sellPriceCtrl.addListener(_onSellPriceChanged);
  }

  Future<void> _loadCategories() async {
    final cats = await _repo.getDistinctCategories();
    if (mounted) setState(() => _categories = cats);
  }

  double _getBaseBuyPrice() {
    final curText = _currentBuyPriceCtrl.text.replaceAll(',', '').trim();
    final curVal = double.tryParse(curText);
    if (curVal != null && curVal > 0) return curVal;
    final buyText = _buyPriceCtrl.text.replaceAll(',', '').trim();
    return double.tryParse(buyText) ?? 0;
  }

  void _onBuyPriceOrCurrentBuyPriceChanged() {
    if (_isAutoCalculating) return;
    final pctText = _profitMarginCtrl.text.replaceAll(',', '').trim();
    final pct = double.tryParse(pctText);
    final basePrice = _getBaseBuyPrice();
    if (pct != null && basePrice > 0) {
      _isAutoCalculating = true;
      final roundedSell = (basePrice * (1 + pct / 100.0)).roundToDouble();
      _sellPriceCtrl.text = roundedSell.round().toString();
      _isAutoCalculating = false;
    }
  }

  void _onProfitMarginChanged() {
    if (_isAutoCalculating) return;
    final pctText = _profitMarginCtrl.text.replaceAll(',', '').trim();
    final pct = double.tryParse(pctText);
    final basePrice = _getBaseBuyPrice();
    if (pct != null && basePrice > 0) {
      _isAutoCalculating = true;
      final roundedSell = (basePrice * (1 + pct / 100.0)).roundToDouble();
      _sellPriceCtrl.text = roundedSell.round().toString();
      _isAutoCalculating = false;
    }
  }

  void _onSellPriceChanged() {
    if (_isAutoCalculating) return;
    final sellText = _sellPriceCtrl.text.replaceAll(',', '').trim();
    final sell = double.tryParse(sellText);
    final basePrice = _getBaseBuyPrice();
    if (sell != null && basePrice > 0) {
      _isAutoCalculating = true;
      final pct = ((sell - basePrice) / basePrice) * 100.0;
      _profitMarginCtrl.text = pct % 1 == 0 ? pct.toStringAsFixed(0) : pct.toStringAsFixed(1);
      _isAutoCalculating = false;
    }
  }

  @override
  void dispose() {
    _currentBuyPriceCtrl.removeListener(_onBuyPriceOrCurrentBuyPriceChanged);
    _buyPriceCtrl.removeListener(_onBuyPriceOrCurrentBuyPriceChanged);
    _profitMarginCtrl.removeListener(_onProfitMarginChanged);
    _sellPriceCtrl.removeListener(_onSellPriceChanged);
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _buyPriceCtrl.dispose();
    _currentBuyPriceCtrl.dispose();
    _profitMarginCtrl.dispose();
    _sellPriceCtrl.dispose();
    _stockCtrl.dispose();
    _supplierCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final codeText = _codeCtrl.text.trim();
    final cleanCode = codeText.isEmpty ? null : codeText;

    // Check unique product code
    if (cleanCode != null) {
      final isTaken = await _repo.isCodeTaken(cleanCode, excludeId: widget.product?.id);
      if (isTaken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('کد کالا تکراری است. لطفاً کد دیگری انتخاب کنید.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    final sellPriceText = _sellPriceCtrl.text.replaceAll(',', '').trim();
    final currentBuyPriceText = _currentBuyPriceCtrl.text.replaceAll(',', '').trim();
    final buyPrice = double.parse(_buyPriceCtrl.text.replaceAll(',', ''));

    final currentBuyPrice = currentBuyPriceText.isNotEmpty ? double.tryParse(currentBuyPriceText) : buyPrice;
    final sellPriceRaw = sellPriceText.isNotEmpty ? double.tryParse(sellPriceText) : null;
    // Always round sell price
    final sellPrice = sellPriceRaw?.roundToDouble();

    final product = ProductModel(
      id: widget.product?.id,
      code: cleanCode,
      name: _nameCtrl.text.trim(),
      category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
      buyPrice: buyPrice,
      currentBuyPrice: currentBuyPrice,
      sellPrice: sellPrice,
      unit: _selectedUnit,
      stock: _isInfiniteStock ? null : (double.tryParse(_stockCtrl.text.replaceAll(',', '')) ?? 0.0),
      createdAt: widget.product?.createdAt,
      buyDate: _buyDate,
      supplier: _supplierCtrl.text.trim().isEmpty ? null : _supplierCtrl.text.trim(),
      isTemporary: _isTemporary,
    );

    if (mounted) {
      Navigator.of(context).pop(product);
    }
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _currentBuyPriceCtrl,
                          decoration: const InputDecoration(
                            labelText: AppStrings.productCurrentBuyPrice,
                            suffixText: AppStrings.toman,
                            hintText: 'مبنای محاسبه سود فروش',
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
                          controller: _profitMarginCtrl,
                          decoration: const InputDecoration(
                            labelText: AppStrings.profitMargin,
                            suffixText: '٪',
                            hintText: 'مثلاً ۲۰',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sellPriceCtrl,
                          decoration: const InputDecoration(
                            labelText: AppStrings.productSellPrice,
                            suffixText: AppStrings.toman,
                            hintText: 'گرد به عدد صحیح',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _stockCtrl,
                              enabled: !_isInfiniteStock,
                              decoration: InputDecoration(
                                labelText: AppStrings.productStock,
                                hintText: _isInfiniteStock ? AppStrings.infiniteStock : '۰',
                                prefixIcon: _isInfiniteStock
                                    ? const Icon(Icons.all_inclusive, color: AppColors.accent, size: 20)
                                    : null,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isInfiniteStock = !_isInfiniteStock;
                                  if (_isInfiniteStock) {
                                    _stockCtrl.clear();
                                  } else if (_stockCtrl.text.isEmpty) {
                                    _stockCtrl.text = '0';
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: _isInfiniteStock,
                                        activeColor: AppColors.accent,
                                        onChanged: (val) {
                                          setState(() {
                                            _isInfiniteStock = val ?? false;
                                            if (_isInfiniteStock) {
                                              _stockCtrl.clear();
                                            } else if (_stockCtrl.text.isEmpty) {
                                              _stockCtrl.text = '0';
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.all_inclusive, size: 16, color: AppColors.accent),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppStrings.infiniteStock,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: _isInfiniteStock ? FontWeight.w600 : FontWeight.normal,
                                        color: _isInfiniteStock ? AppColors.accent : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _supplierCtrl,
                          decoration: const InputDecoration(labelText: AppStrings.productSupplier),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
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
