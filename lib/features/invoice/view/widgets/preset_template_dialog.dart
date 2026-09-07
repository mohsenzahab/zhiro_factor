import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../../../data/models/preset_template_model.dart';
import '../../../../data/repositories/preset_template_repository.dart';

/// Dialog for selecting a preset template (pre-invoice) to load into invoice.
class PresetTemplateDialog extends StatefulWidget {
  const PresetTemplateDialog({super.key});

  /// Shows the dialog and returns the selected template, or null if cancelled.
  static Future<PresetTemplateModel?> show(BuildContext context) {
    return showDialog<PresetTemplateModel>(
      context: context,
      builder: (_) => const PresetTemplateDialog(),
    );
  }

  @override
  State<PresetTemplateDialog> createState() => _PresetTemplateDialogState();
}

class _PresetTemplateDialogState extends State<PresetTemplateDialog> {
  final _repo = PresetTemplateRepository();
  List<PresetTemplateModel> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _loading = true);
    _templates = await _repo.getAll();
    setState(() => _loading = false);
  }

  Future<void> _deleteTemplate(PresetTemplateModel template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: Text(AppStrings.deleteTemplate),
          content: Text('آیا از حذف «${template.name}» اطمینان دارید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(AppStrings.delete, style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && template.id != null) {
      await _repo.delete(template.id!);
      _loadTemplates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 500,
          height: 480,
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.library_books, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.presetTemplates,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // ── Templates List ─────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _templates.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.library_books_outlined,
                                    size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                const Text(
                                  AppStrings.noTemplates,
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'از صفحه فاکتور می‌توانید فاکتور فعلی را بعنوان پیش‌فاکتور ذخیره کنید',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _templates.length,
                            separatorBuilder: (_, _) =>
                                Divider(height: 1, color: AppColors.dividerDark),
                            itemBuilder: (context, index) {
                              final template = _templates[index];
                              return ListTile(
                                onTap: () => Navigator.of(context).pop(template),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${template.items.length}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  template.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${template.items.length} ${AppStrings.templateItems} • ${template.items.fold<double>(0, (s, i) => s + i.unitPrice * i.quantity).formatted}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  color: AppColors.error,
                                  tooltip: AppStrings.deleteTemplate,
                                  onPressed: () => _deleteTemplate(template),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for saving current invoice items as a preset template.
class SaveAsTemplateDialog extends StatefulWidget {
  const SaveAsTemplateDialog({super.key});

  /// Shows the dialog and returns the template name, or null if cancelled.
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const SaveAsTemplateDialog(),
    );
  }

  @override
  State<SaveAsTemplateDialog> createState() => _SaveAsTemplateDialogState();
}

class _SaveAsTemplateDialogState extends State<SaveAsTemplateDialog> {
  final _nameCtrl = TextEditingController();
  bool _valid = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.save_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(AppStrings.saveAsTemplate),
          ],
        ),
        content: SizedBox(
          width: 350,
          child: TextField(
            controller: _nameCtrl,
            autofocus: true,
            onChanged: (v) => setState(() => _valid = v.trim().isNotEmpty),
            onSubmitted: (_) {
              if (_valid) Navigator.pop(context, _nameCtrl.text.trim());
            },
            decoration: InputDecoration(
              hintText: AppStrings.enterTemplateName,
              labelText: AppStrings.templateName,
              prefixIcon: const Icon(Icons.label_outline, size: 20),
              filled: true,
              fillColor: AppColors.cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.dividerDark),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: _valid ? () => Navigator.pop(context, _nameCtrl.text.trim()) : null,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}
