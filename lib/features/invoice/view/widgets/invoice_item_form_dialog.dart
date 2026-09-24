import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/invoice_item_model.dart';

class InvoiceItemFormDialog extends StatefulWidget {
  final ProductModel product;

  const InvoiceItemFormDialog({super.key, required this.product});

  static Future<InvoiceItemModel?> show(BuildContext context, ProductModel product) {
    return showDialog<InvoiceItemModel>(
      context: context,
      builder: (_) => InvoiceItemFormDialog(product: product),
    );
  }

  @override
  State<InvoiceItemFormDialog> createState() => _InvoiceItemFormDialogState();
}

class _InvoiceItemFormDialogState extends State<InvoiceItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _priceCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _discountValueCtrl;

  String _discountType = 'none';
  double _lineTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(text: widget.product.effectivePrice.formatted);
    _qtyCtrl = TextEditingController(text: '۱');
    _discountValueCtrl = TextEditingController(text: '۰');

    _priceCtrl.addListener(_recalculate);
    _qtyCtrl.addListener(_recalculate);
    _discountValueCtrl.addListener(_recalculate);

    _recalculate();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _discountValueCtrl.dispose();
    super.dispose();
  }

  void _recalculate() {
    final price = _priceCtrl.text.tryParseFormatted() ?? 0.0;
    final qty = _qtyCtrl.text.tryParseFormatted() ?? 1.0;
    final discValue = _discountValueCtrl.text.tryParseFormatted() ?? 0.0;

    double grossTotal = price * qty;
    double calculatedDisc = 0.0;

    if (_discountType == 'amount') {
      calculatedDisc = discValue;
    } else if (_discountType == 'percentage') {
      calculatedDisc = grossTotal * (discValue / 100.0);
    }

    setState(() {
      _lineTotal = grossTotal - calculatedDisc;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final price = _priceCtrl.text.tryParseFormatted() ?? widget.product.effectivePrice;
    final qty = _qtyCtrl.text.tryParseFormatted() ?? 1.0;
    final discValue = _discountValueCtrl.text.tryParseFormatted() ?? 0.0;

    final baseItem = InvoiceItemModel(
      productId: widget.product.id,
      productName: widget.product.name,
      unitPrice: price,
      purchasePrice: widget.product.effectiveBuyPrice,
      quantity: qty,
      discountType: _discountType,
      discountValue: discValue,
      lineTotal: 0, // Will be computed by recalculate()
    );

    Navigator.pop(context, baseItem.recalculate());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Row(
                  children: [
                    const Icon(Icons.edit_note, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'جزئیات دقیق کالا',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Product Name
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.dividerDark),
                  ),
                  child: Text(
                    widget.product.name,
                    style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                // Unit Price & Quantity
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _priceCtrl,
                        label: 'قیمت واحد',
                        suffixText: 'تومان',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _buildTextField(
                        controller: _qtyCtrl,
                        label: 'تعداد',
                        isFloat: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Discount Type
                DropdownButtonFormField<String>(
                  value: _discountType,
                  decoration: InputDecoration(
                    labelText: 'نوع تخفیف',
                    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.dividerDark)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.dividerDark)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  dropdownColor: AppColors.cardDark,
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('بدون تخفیف')),
                    DropdownMenuItem(value: 'amount', child: Text('مبلغ ثابت')),
                    DropdownMenuItem(value: 'percentage', child: Text('درصدی')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _discountType = v ?? 'none';
                      _discountValueCtrl.text = '۰';
                      _recalculate();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Discount Value
                if (_discountType != 'none') ...[
                  _buildTextField(
                    controller: _discountValueCtrl,
                    label: _discountType == 'amount' ? 'مبلغ تخفیف' : 'درصد تخفیف',
                    suffixText: _discountType == 'amount' ? 'تومان' : '٪',
                  ),
                  const SizedBox(height: 16),
                ],

                // Line Total Preview
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'جمع کل خط:',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_lineTotal.formatted} تومان',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('افزودن به فاکتور', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? suffixText,
    bool isFloat = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\.\u06F0-\u06F9]')),
      ],
      onChanged: (val) {
        if (!isFloat) {
          final clean = val.toEnglishDigits().replaceAll(RegExp(r'[^0-9]'), '');
          if (clean.isNotEmpty) {
            final formatted = double.parse(clean).formatted;
            if (val != formatted) {
              controller.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          }
        }
      },
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffixText,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        suffixStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppColors.cardDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.dividerDark)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.dividerDark)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'الزامی';
        final val = v.tryParseFormatted();
        if (val == null) return 'نامعتبر';
        if (val < 0) return 'منفی؟';
        return null;
      },
    );
  }
}
