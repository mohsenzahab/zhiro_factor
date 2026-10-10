import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../../../core/utils/jalali_utils.dart';
import '../../../../data/models/invoice_payment_model.dart';
import '../../../../data/repositories/invoice_repository.dart';

/// Modal dialog for viewing, adding, and removing partial payments (دریافتی‌ها / نسیه).
/// Supports both in-memory list (used by InvoiceCubit) and direct database persistence (used by InvoiceHistory).
class InvoicePaymentsDialog extends StatefulWidget {
  final int? invoiceId;
  final String invoiceNumber;
  final double totalNet;
  final String? status;
  final List<InvoicePaymentModel> initialPayments;
  final void Function(InvoicePaymentModel payment)? onPaymentAdded;
  final void Function(int index, InvoicePaymentModel payment)? onPaymentRemoved;
  final VoidCallback? onPaymentsChanged;

  const InvoicePaymentsDialog({
    super.key,
    this.invoiceId,
    required this.invoiceNumber,
    required this.totalNet,
    this.status,
    required this.initialPayments,
    this.onPaymentAdded,
    this.onPaymentRemoved,
    this.onPaymentsChanged,
  });

  /// Open dialog from invoice creation/editing (cubit mode).
  static Future<void> showForEditor({
    required BuildContext context,
    int? invoiceId,
    required String invoiceNumber,
    required double totalNet,
    String? status,
    required List<InvoicePaymentModel> payments,
    required void Function(InvoicePaymentModel) onPaymentAdded,
    required void Function(int index, InvoicePaymentModel) onPaymentRemoved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => InvoicePaymentsDialog(
        invoiceId: invoiceId,
        invoiceNumber: invoiceNumber,
        totalNet: totalNet,
        status: status,
        initialPayments: payments,
        onPaymentAdded: onPaymentAdded,
        onPaymentRemoved: onPaymentRemoved,
      ),
    );
  }

  /// Open dialog for an existing invoice directly in database (history mode).
  static Future<void> showForSavedInvoice({
    required BuildContext context,
    required int invoiceId,
    required String invoiceNumber,
    required double totalNet,
    String? status,
    required List<InvoicePaymentModel> payments,
    VoidCallback? onPaymentsChanged,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => InvoicePaymentsDialog(
        invoiceId: invoiceId,
        invoiceNumber: invoiceNumber,
        totalNet: totalNet,
        status: status,
        initialPayments: payments,
        onPaymentsChanged: onPaymentsChanged,
      ),
    );
  }

  @override
  State<InvoicePaymentsDialog> createState() => _InvoicePaymentsDialogState();
}

class _InvoicePaymentsDialogState extends State<InvoicePaymentsDialog> {
  late List<InvoicePaymentModel> _payments;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  bool get _isSettled =>
      widget.status == 'تسویه شده' ||
      (widget.totalNet > 0 &&
          _payments.isNotEmpty &&
          _payments.fold(0.0, (sum, p) => sum + p.amount) >= widget.totalNet);

  double get _totalPaid {
    if (_isSettled && _payments.isEmpty) {
      return widget.totalNet;
    }
    return _payments.fold(0.0, (sum, p) => sum + p.amount);
  }

  double get _remaining => _isSettled ? 0.0 : (widget.totalNet - _totalPaid).clamp(0.0, double.infinity);

  @override
  void initState() {
    super.initState();
    _payments = List<InvoicePaymentModel>.from(widget.initialPayments);
    _prefillRemainingAmount();
  }

  void _prefillRemainingAmount() {
    if (_remaining > 0) {
      _amountCtrl.text = _remaining.toInt().toString();
    } else {
      _amountCtrl.clear();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final jalali = Jalali.fromDateTime(_selectedDate);
    final picked = await showPersianDatePicker(
      context: context,
      initialDate: jalali,
      firstDate: Jalali(1400, 1, 1),
      lastDate: Jalali(1450, 12, 29),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked.toDateTime();
      });
    }
  }

  Future<void> _handleAddPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final rawAmount = _amountCtrl.text.trim().toEnglishDigits().replaceAll(',', '');
    final amount = double.tryParse(rawAmount) ?? 0.0;
    if (amount <= 0) return;

    setState(() => _isSaving = true);

    final payment = InvoicePaymentModel(
      invoiceId: widget.invoiceId,
      amount: amount,
      date: _selectedDate.toIso8601String(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    try {
      if (widget.invoiceId != null && widget.onPaymentsChanged != null) {
        // Direct database mode
        final repo = InvoiceRepository();
        final newId = await repo.addPayment(payment);
        final persistedPayment = payment.copyWith(id: newId);
        setState(() {
          _payments.add(persistedPayment);
        });
        widget.onPaymentsChanged?.call();
      } else {
        // In-memory editor mode
        setState(() {
          _payments.add(payment);
        });
        widget.onPaymentAdded?.call(payment);
      }

      _noteCtrl.clear();
      _prefillRemainingAmount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.paymentSuccess),
            backgroundColor: AppColors.statusSettled,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDeletePayment(int index) async {
    final payment = _payments[index];

    if (widget.invoiceId != null && payment.id != null && widget.onPaymentsChanged != null) {
      // Direct database mode
      final repo = InvoiceRepository();
      await repo.deletePayment(payment.id!);
      setState(() {
        _payments.removeAt(index);
      });
      widget.onPaymentsChanged?.call();
    } else {
      // In-memory editor mode
      setState(() {
        _payments.removeAt(index);
      });
      widget.onPaymentRemoved?.call(index, payment);
    }

    _prefillRemainingAmount();
  }

  @override
  Widget build(BuildContext context) {
    final jalaliDateStr = JalaliUtils.format(Jalali.fromDateTime(_selectedDate));

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title & Close ─────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.statusCredit.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.statusCredit, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppStrings.paymentsAndCredit} - فاکتور ${widget.invoiceNumber.toPersianDigits()}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'ثبت و مدیریت مبالغ دریافتی و مانده نسیه مشتری',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Summary KPI Cards ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.dividerDark),
                ),
                child: Row(
                  children: [
                    _buildSummaryItem(
                      label: AppStrings.finalPayable,
                      value: widget.totalNet.toman,
                      color: AppColors.textPrimary,
                      icon: Icons.receipt_long,
                    ),
                    Container(width: 1, height: 40, color: AppColors.dividerDark),
                    _buildSummaryItem(
                      label: AppStrings.paidAmount,
                      value: _totalPaid.toman,
                      color: AppColors.statusSettled,
                      icon: Icons.check_circle_outline,
                    ),
                    Container(width: 1, height: 40, color: AppColors.dividerDark),
                    _buildSummaryItem(
                      label: AppStrings.remainingAmount,
                      value: _remaining.toman,
                      color: _remaining > 0 ? AppColors.statusCredit : AppColors.textMuted,
                      icon: Icons.pending_actions_outlined,
                      isHighlighted: _remaining > 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Add Payment Form or Settled Banner ────────────────────
              if (_isSettled || _remaining <= 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.statusSettled.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.statusSettled.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle_outline, color: AppColors.statusSettled, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'این فاکتور کاملاً تسویه شده است و مانده‌ای برای پرداخت ندارد.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusSettled,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardDarkAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.dividerDark),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Row(
                        children: [
                          const Icon(Icons.add_circle_outline, size: 18, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.newPayment,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.accent),
                          ),
                          const Spacer(),
                          if (_remaining > 0)
                            TextButton.icon(
                              onPressed: () {
                                _amountCtrl.text = _remaining.toInt().toString();
                              },
                              icon: const Icon(Icons.done_all, size: 16),
                              label: const Text(AppStrings.settleAll, style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.statusSettled,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Amount
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _amountCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: AppStrings.paymentAmount,
                                hintText: 'مبلغ به تومان...',
                                suffixText: 'تومان',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'مبلغ الزامی است';
                                final num = double.tryParse(v.toEnglishDigits()) ?? 0;
                                if (num <= 0) return 'مبلغ نامعتبر است';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Date picker button
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(8),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  isDense: true,
                                  labelText: AppStrings.paymentDate,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  suffixIcon: const Icon(Icons.calendar_today, size: 16),
                                ),
                                child: Text(
                                  jalaliDateStr,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Note / Method
                          Expanded(
                            child: TextFormField(
                              controller: _noteCtrl,
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: AppStrings.paymentNote,
                                hintText: 'مثلا کارت‌به‌کارت، چک، نقدی...',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _isSaving ? null : _handleAddPayment,
                            icon: _isSaving
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.save_outlined, size: 18),
                            label: const Text(AppStrings.addPayment),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusCredit,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Payments List ──────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.history, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    'تاریخچه مبالغ دریافتی (${_payments.length.toString().toPersianDigits()})',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Expanded(
                child: _payments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.payments_outlined, size: 40, color: AppColors.textMuted),
                            SizedBox(height: 8),
                            Text(AppStrings.noPayments, style: TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _payments.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final p = _payments[index];
                          final pJalali = JalaliUtils.format(JalaliUtils.fromIso(p.date));

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.cardDark,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.dividerDark),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusSettled.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.arrow_downward, color: AppColors.statusSettled, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            p.amount.toman,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.statusSettled,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            pJalali,
                                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                      if (p.note != null && p.note!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          p.note!,
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                  tooltip: 'حذف این دریافتی',
                                  onPressed: () => _handleDeletePayment(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardDark,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  ),
                  child: const Text('بستن'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    bool isHighlighted = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: isHighlighted ? 14 : 13,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
