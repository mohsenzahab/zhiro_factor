import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/import_service.dart';

/// Dialog for mapping file columns to database product fields.
/// Shows a preview of the file data and lets the user assign each DB field
/// to a file column via dropdown menus. Saves the mapping for future imports.
class ImportMappingDialog extends StatefulWidget {
  final ImportFileData fileData;

  const ImportMappingDialog({super.key, required this.fileData});

  /// Show the dialog. Returns the confirmed [ImportColumnMapping] or null if cancelled.
  static Future<ImportColumnMapping?> show(
    BuildContext context,
    ImportFileData fileData,
  ) {
    return showDialog<ImportColumnMapping>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ImportMappingDialog(fileData: fileData),
    );
  }

  @override
  State<ImportMappingDialog> createState() => _ImportMappingDialogState();
}

class _ImportMappingDialogState extends State<ImportMappingDialog> {
  late Map<String, int> _mapping;
  bool _loadingPreset = true;

  @override
  void initState() {
    super.initState();
    _mapping = {};
    _loadSavedMapping();
  }

  Future<void> _loadSavedMapping() async {
    final saved = await ImportColumnMapping.load(widget.fileData.fileType);
    setState(() {
      if (saved != null) {
        // Use saved mapping, but validate indices against actual header count
        _mapping = {};
        for (final field in ImportColumnMapping.dbFields) {
          final idx = saved.mapping[field] ?? -1;
          _mapping[field] = (idx >= 0 && idx < widget.fileData.headers.length) ? idx : -1;
        }
      } else {
        // Default mapping: assign columns in order
        final defaultMap = ImportColumnMapping.defaultMapping(widget.fileData.headers.length);
        _mapping = Map.from(defaultMap.mapping);
      }
      _loadingPreset = false;
    });
  }

  void _confirm() async {
    // Validate: at least 'name' must be mapped
    if ((_mapping['name'] ?? -1) < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فیلد «نام کالا» باید حتماً تنظیم شود'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final mapping = ImportColumnMapping(_mapping);

    // Save for next time
    await mapping.save(widget.fileData.fileType);

    if (mounted) Navigator.of(context).pop(mapping);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 700,
          height: 600,
          child: _loadingPreset
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // ── Mapping Controls ──────────────────
                            _buildMappingSection(),
                            const SizedBox(height: 16),
                            // ── Data Preview ──────────────────────
                            Expanded(child: _buildPreviewTable()),
                          ],
                        ),
                      ),
                    ),
                    _buildFooter(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.settings_input_component, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تنظیم ستون‌ها',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'هر فیلد دیتابیس را به ستون مناسب فایل متصل کنید',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.fileData.rows.length} ردیف • ${widget.fileData.headers.length} ستون',
              style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'نقشه‌برداری ستون‌ها',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _resetToDefault,
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('بازنشانی', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ImportColumnMapping.dbFields.map((field) {
              return _buildFieldMapping(field);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldMapping(String dbField) {
    final label = ImportColumnMapping.dbFieldLabels[dbField] ?? dbField;
    final currentIndex = _mapping[dbField] ?? -1;
    final isRequired = dbField == 'name';

    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRequired && currentIndex < 0
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.dividerDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isRequired)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentIndex >= 0 ? AppColors.accent : AppColors.error,
                  ),
                ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            value: currentIndex,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 13),
            items: [
              const DropdownMenuItem(
                value: -1,
                child: Text(
                  '— بدون انتخاب —',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
              ...List.generate(widget.fileData.headers.length, (index) {
                final header = widget.fileData.headers[index];
                return DropdownMenuItem(
                  value: index,
                  child: Text(
                    '[$index] $header',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (value) {
              setState(() => _mapping[dbField] = value ?? -1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTable() {
    final previewRows = widget.fileData.rows.take(5).toList();
    if (previewRows.isEmpty) {
      return const Center(
        child: Text('پیش‌نمایش داده‌ای موجود نیست', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dividerDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.cardDark,
            child: Row(
              children: [
                const Icon(Icons.preview, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  'پیش‌نمایش (${previewRows.length} ردیف اول)',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowHeight: 36,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 36,
                  columnSpacing: 16,
                  horizontalMargin: 12,
                  headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
                  columns: [
                    // Show mapped DB field names as column headers
                    ...ImportColumnMapping.dbFields.map((field) {
                      final idx = _mapping[field] ?? -1;
                      final label = ImportColumnMapping.dbFieldLabels[field] ?? field;
                      return DataColumn(
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            if (idx >= 0 && idx < widget.fileData.headers.length)
                              Text(
                                '← ${widget.fileData.headers[idx]}',
                                style: TextStyle(fontSize: 9, color: AppColors.accent),
                              )
                            else
                              Text('—', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                          ],
                        ),
                      );
                    }),
                  ],
                  rows: previewRows.map((row) {
                    return DataRow(
                      cells: ImportColumnMapping.dbFields.map((field) {
                        final idx = _mapping[field] ?? -1;
                        String value = '';
                        if (idx >= 0 && idx < row.length) {
                          value = row[idx];
                        }
                        return DataCell(
                          Text(
                            value,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: AppColors.dividerDark)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            'تنظیمات ذخیره می‌شود و دفعه بعد به صورت پیش‌فرض بارگذاری خواهد شد',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check, size: 18),
            label: Text('ورود ${widget.fileData.rows.length} کالا'),
          ),
        ],
      ),
    );
  }

  void _resetToDefault() {
    setState(() {
      final defaultMap = ImportColumnMapping.defaultMapping(widget.fileData.headers.length);
      _mapping = Map.from(defaultMap.mapping);
    });
  }
}
