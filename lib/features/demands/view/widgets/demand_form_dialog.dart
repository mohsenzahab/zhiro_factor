import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../../../core/utils/jalali_utils.dart';
import '../../../../data/models/demand_model.dart';
import '../../../../data/repositories/product_repository.dart';

/// Dialog for creating or editing a Demand item.
class DemandFormDialog extends StatefulWidget {
  final DemandModel? demand;
  final List<String> availableCategories;

  const DemandFormDialog({
    super.key,
    this.demand,
    this.availableCategories = const [],
  });

  static Future<DemandModel?> show(
    BuildContext context, {
    DemandModel? demand,
    List<String> availableCategories = const [],
  }) {
    return showDialog<DemandModel>(
      context: context,
      builder: (_) => DemandFormDialog(
        demand: demand,
        availableCategories: availableCategories,
      ),
    );
  }

  @override
  State<DemandFormDialog> createState() => _DemandFormDialogState();
}

class _DemandFormDialogState extends State<DemandFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productRepo = ProductRepository();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _targetQtyCtrl;
  late final TextEditingController _buyPriceCtrl;
  late final TextEditingController _sellPriceCtrl;
  late final TextEditingController _initialCountCtrl;
  late final TextEditingController _notesCtrl;

  late String _status;
  String? _requestDate;
  List<String> _categories = [];

  bool get _isEditing => widget.demand != null;

  @override
  void initState() {
    super.initState();
    final d = widget.demand;

    _titleCtrl = TextEditingController(text: d?.title ?? '');
    _categoryCtrl = TextEditingController(text: d?.category ?? '');
    _targetQtyCtrl = TextEditingController(
      text: d != null ? d.targetQuantity.formatted : '۱',
    );
    _buyPriceCtrl = TextEditingController(
      text: d?.buyPrice != null ? d!.buyPrice!.round().toString().toPersianDigits() : '',
    );
    _sellPriceCtrl = TextEditingController(
      text: d?.sellPrice != null ? d!.sellPrice!.round().toString().toPersianDigits() : '',
    );
    _initialCountCtrl = TextEditingController(text: '۱');
    _notesCtrl = TextEditingController(text: d?.notes ?? '');

    _status = d?.status ?? DemandModel.statusPending;
    _requestDate = d?.latestRequestDate ?? DateTime.now().toIso8601String();

    _categories = List<String>.from(widget.availableCategories);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _productRepo.getDistinctCategories();
    if (mounted) {
      setState(() {
        _categories = {..._categories, ...cats}.toList()..sort();
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _targetQtyCtrl.dispose();
    _buyPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _initialCountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRequestDate() async {
    final initialJalali = _requestDate != null
        ? JalaliUtils.toJalali(_requestDate!)
        : Jalali.now();

    final picked = await showPersianDatePicker(
      context: context,
      initialDate: initialJalali,
      firstDate: Jalali(1400, 1, 1),
      lastDate: Jalali(1450, 12, 29),
    );

    if (picked != null) {
      setState(() {
        _requestDate = JalaliUtils.toIso(picked);
      });
    }
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleCtrl.text.trim();
    final category = _categoryCtrl.text.trim().isNotEmpty ? _categoryCtrl.text.trim() : null;
    final targetQty = _targetQtyCtrl.text.tryParseFormatted() ?? 1.0;
    final buyPrice = _buyPriceCtrl.text.tryParseFormatted();
    final sellPrice = _sellPriceCtrl.text.tryParseFormatted();
    final notes = _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null;

    if (_isEditing) {
      final updated = widget.demand!.copyWith(
        title: title,
        category: category,
        targetQuantity: targetQty,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        clearBuyPrice: buyPrice == null,
        clearSellPrice: sellPrice == null,
        status: _status,
        notes: notes,
      );
      Navigator.of(context).pop(updated);
    } else {
      final initialCount = (_initialCountCtrl.text.tryParseFormatted() ?? 1.0).toInt().clamp(1, 1000);
      final reqDate = _requestDate ?? DateTime.now().toIso8601String();
      final requestDates = List.filled(initialCount, reqDate);

      final newDemand = DemandModel(
        title: title,
        category: category,
        targetQuantity: targetQty,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        status: _status,
        notes: notes,
        requestDates: requestDates,
      );
      Navigator.of(context).pop(newDemand);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buyVal = _buyPriceCtrl.text.tryParseFormatted() ?? 0.0;
    final sellVal = _sellPriceCtrl.text.tryParseFormatted() ?? 0.0;
    final targetQty = _targetQtyCtrl.text.tryParseFormatted() ?? 1.0;
    final requiredCapital = buyVal * targetQty;
    final unitProfit = (sellVal > 0 && buyVal > 0) ? (sellVal - buyVal) : null;
    final totalProfit = unitProfit != null ? unitProfit * targetQty : null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.playlist_add_check, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isEditing ? 'ویرایش نیازمندی' : 'افزودن کالا یا خدمت به لیست نیازمندی‌ها',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: AppColors.textMuted,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Scrollable Form Fields ─────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Title (Name)
                          TextFormField(
                            controller: _titleCtrl,
                            autofocus: !_isEditing,
                            decoration: InputDecoration(
                              labelText: 'نام کالا یا خدمت *',
                              hintText: 'مثلاً: آچار آلن سایز ۸ یا تعویض روغن هیدرولیک...',
                              prefixIcon: const Icon(Icons.label_outline, size: 20),
                              filled: true,
                              fillColor: AppColors.surfaceDark,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'نام کالا یا خدمت الزامی است' : null,
                          ),
                          const SizedBox(height: 16),

                          // 2. Category & Target Quantity
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category with autocomplete
                              Expanded(
                                flex: 3,
                                child: Autocomplete<String>(
                                  optionsBuilder: (textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return _categories;
                                    }
                                    return _categories.where((cat) =>
                                        cat.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                  },
                                  initialValue: TextEditingValue(text: _categoryCtrl.text),
                                  onSelected: (selection) {
                                    _categoryCtrl.text = selection;
                                  },
                                  fieldViewBuilder: (ctx, fieldCtrl, focusNode, onFieldSubmitted) {
                                    // Keep _categoryCtrl synced
                                    fieldCtrl.addListener(() {
                                      _categoryCtrl.text = fieldCtrl.text;
                                    });
                                    return TextFormField(
                                      controller: fieldCtrl,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        labelText: 'دسته‌بندی (اختیاری)',
                                        hintText: 'انتخاب یا تایپ دسته‌بندی...',
                                        prefixIcon: const Icon(Icons.category_outlined, size: 20),
                                        filled: true,
                                        fillColor: AppColors.surfaceDark,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Target Quantity
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _targetQtyCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'تعداد خرید *',
                                    hintText: '۱',
                                    prefixIcon: const Icon(Icons.numbers_outlined, size: 20),
                                    filled: true,
                                    fillColor: AppColors.surfaceDark,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) {
                                    final n = v?.tryParseFormatted();
                                    if (n == null || n <= 0) return 'حداقل ۱ عدد';
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 3. Buy & Sell Prices
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _buyPriceCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'قیمت خرید تخمینی (تومان)',
                                    hintText: 'اختیاری',
                                    prefixIcon: const Icon(Icons.shopping_cart_outlined, size: 20),
                                    filled: true,
                                    fillColor: AppColors.surfaceDark,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onChanged: (v) {
                                    final n = v.tryParseFormatted();
                                    if (n != null) {
                                      _buyPriceCtrl.value = TextEditingValue(
                                        text: n.round().toString().toPersianDigits(),
                                        selection: TextSelection.collapsed(
                                          offset: n.round().toString().toPersianDigits().length,
                                        ),
                                      );
                                    }
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _sellPriceCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'قیمت فروش تخمینی (تومان)',
                                    hintText: 'اختیاری',
                                    prefixIcon: const Icon(Icons.sell_outlined, size: 20),
                                    filled: true,
                                    fillColor: AppColors.surfaceDark,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onChanged: (v) {
                                    final n = v.tryParseFormatted();
                                    if (n != null) {
                                      _sellPriceCtrl.value = TextEditingValue(
                                        text: n.round().toString().toPersianDigits(),
                                        selection: TextSelection.collapsed(
                                          offset: n.round().toString().toPersianDigits().length,
                                        ),
                                      );
                                    }
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 4. Live Calculation Card (Capital & Profit Preview)
                          if (buyVal > 0 || sellVal > 0)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppColors.cardDarkAlt,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.dividerDark),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('سرمایه مورد نیاز:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      const SizedBox(height: 4),
                                      Text(
                                        requiredCapital > 0 ? requiredCapital.toman : '---',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.warning),
                                      ),
                                    ],
                                  ),
                                  Container(height: 28, width: 1, color: AppColors.dividerDark),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('سود واحد:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      const SizedBox(height: 4),
                                      Text(
                                        unitProfit != null ? unitProfit.toman : '---',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: (unitProfit ?? 0) >= 0 ? AppColors.accent : AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(height: 28, width: 1, color: AppColors.dividerDark),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('سود کل پیش‌بینی شده:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      const SizedBox(height: 4),
                                      Text(
                                        totalProfit != null ? totalProfit.toman : '---',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: (totalProfit ?? 0) >= 0 ? AppColors.accent : AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          // 5. Status Selector
                          const Text('وضعیت تأمین:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: DemandModel.allStatuses.map((st) {
                              final isSel = _status == st;
                              Color badgeColor;
                              if (st == DemandModel.statusPending) {
                                badgeColor = AppColors.warning;
                              } else if (st == DemandModel.statusInPreparation) {
                                badgeColor = AppColors.info;
                              } else {
                                badgeColor = AppColors.statusSettled;
                              }
                              return ChoiceChip(
                                label: Text(st),
                                selected: isSel,
                                selectedColor: badgeColor.withValues(alpha: 0.25),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  color: isSel ? badgeColor : AppColors.textSecondary,
                                ),
                                side: BorderSide(color: isSel ? badgeColor : AppColors.dividerDark),
                                onSelected: (sel) {
                                  if (sel) setState(() => _status = st);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // 6. Initial Request Count & Date (Only when creating)
                          if (!_isEditing) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _initialCountCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'تعداد درخواست اولیه',
                                      hintText: '۱',
                                      prefixIcon: const Icon(Icons.repeat, size: 20),
                                      filled: true,
                                      fillColor: AppColors.surfaceDark,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    validator: (v) {
                                      final n = v?.tryParseFormatted();
                                      if (n == null || n < 1) return 'حداقل ۱ بار';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: _pickRequestDate,
                                    borderRadius: BorderRadius.circular(10),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'تاریخ درخواست',
                                        prefixIcon: const Icon(Icons.calendar_month_outlined, size: 20),
                                        filled: true,
                                        fillColor: AppColors.surfaceDark,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: Text(
                                        _requestDate != null
                                            ? JalaliUtils.formatIso(_requestDate!)
                                            : JalaliUtils.formatIso(DateTime.now().toIso8601String()),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 7. Notes
                          TextFormField(
                            controller: _notesCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'توضیحات و مشخصات (اختیاری)',
                              hintText: 'مشخصات فنی، شماره تماس مشتری متقاضی یا برند خاص...',
                              prefixIcon: const Icon(Icons.notes, size: 20),
                              filled: true,
                              fillColor: AppColors.surfaceDark,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Actions Footer ─────────────────────────────────
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('انصراف'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _onSave,
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(_isEditing ? 'ذخیره تغییرات' : 'افزودن به نیازمندی‌ها'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
