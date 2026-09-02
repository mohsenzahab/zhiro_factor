import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/customer_model.dart';

/// Dialog for adding/editing a customer.
class CustomerFormDialog extends StatefulWidget {
  final CustomerModel? customer;
  final String? nextCode;

  const CustomerFormDialog({super.key, this.customer, this.nextCode});

  static Future<CustomerModel?> show(
    BuildContext context, {
    CustomerModel? customer,
    String? nextCode,
  }) {
    return showDialog<CustomerModel>(
      context: context,
      builder: (_) => CustomerFormDialog(customer: customer, nextCode: nextCode),
    );
  }

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _notesCtrl;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _codeCtrl = TextEditingController(text: c?.code ?? widget.nextCode ?? '');
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final customer = CustomerModel(
      id: widget.customer?.id,
      code: _codeCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    Navigator.of(context).pop(customer);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(_isEditing ? AppStrings.editCustomer : AppStrings.addCustomer),
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
                          decoration: const InputDecoration(labelText: AppStrings.customerCode),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(labelText: AppStrings.customerName),
                          validator: (v) => v == null || v.trim().isEmpty ? AppStrings.fieldRequired : null,
                          autofocus: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(labelText: AppStrings.customerPhone),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(labelText: AppStrings.customerAddress),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(labelText: AppStrings.customerNotes),
                    maxLines: 2,
                  ),
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
            child: Text(_isEditing ? AppStrings.save : AppStrings.addCustomer),
          ),
        ],
      ),
    );
  }
}
