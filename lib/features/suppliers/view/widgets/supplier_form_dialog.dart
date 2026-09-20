import 'package:flutter/material.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/extensions/number_extensions.dart';
import '../../../../../data/models/supplier_model.dart';

class SupplierFormDialog extends StatefulWidget {
  final String nextCode;
  final SupplierModel? supplier;
  final String? initialName;

  const SupplierFormDialog({
    super.key,
    required this.nextCode,
    this.supplier,
    this.initialName,
  });

  static Future<SupplierModel?> show(
    BuildContext context, {
    required String nextCode,
    SupplierModel? supplier,
    String? initialName,
  }) {
    return showDialog<SupplierModel>(
      context: context,
      builder: (context) => SupplierFormDialog(
        nextCode: nextCode,
        supplier: supplier,
        initialName: initialName,
      ),
    );
  }

  @override
  State<SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<SupplierFormDialog> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    final isEdit = widget.supplier != null;
    _codeCtrl = TextEditingController(text: isEdit ? widget.supplier!.code : widget.nextCode);
    _nameCtrl = TextEditingController(
        text: isEdit ? widget.supplier!.name : (widget.initialName ?? ''));
    _phoneCtrl = TextEditingController(text: isEdit ? widget.supplier!.phone : '');
    _addressCtrl = TextEditingController(text: isEdit ? widget.supplier!.address : '');
    _notesCtrl = TextEditingController(text: isEdit ? widget.supplier!.notes : '');
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.supplier != null;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Row(
          children: [
            Icon(isEdit ? Icons.edit : Icons.add_business, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(isEdit ? AppStrings.editSupplier : AppStrings.createNewSupplier),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.supplierCode,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                autofocus: !isEdit,
                decoration: const InputDecoration(
                  labelText: AppStrings.supplierName,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.supplierPhone,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: AppStrings.supplierAddress,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: AppStrings.supplierNotes,
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(
                context,
                SupplierModel(
                  id: widget.supplier?.id,
                  code: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim().toEnglishDigits(),
                  name: name,
                  phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim().toEnglishDigits(),
                  address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
                  notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                ),
              );
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}
