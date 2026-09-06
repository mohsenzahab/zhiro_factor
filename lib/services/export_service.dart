import 'dart:io';
import 'package:excel_plus/excel_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

/// Service for exporting data to Excel and CSV files.
class ExportService {
  ExportService._();

  /// Export sales ledger data to Excel (.xlsx).
  static Future<void> exportExcel(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) throw Exception('داده‌ای برای خروجی وجود ندارد');

    final excel = Excel.createExcel();
    final sheet = excel['گزارش فروش'];

    // Header row
    sheet.appendRow([
      TextCellValue('ردیف'),
      TextCellValue('نام کالا'),
      TextCellValue('شماره فاکتور'),
      TextCellValue('تاریخ'),
      TextCellValue('مشتری'),
      TextCellValue('وضعیت'),
      TextCellValue('تعداد'),
      TextCellValue('قیمت واحد'),
      TextCellValue('تخفیف'),
      TextCellValue('جمع سطر'),
      TextCellValue('سود سطر'),
    ]);

    // Data rows
    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(row['product_name']?.toString() ?? ''),
        TextCellValue(row['invoice_number']?.toString() ?? ''),
        TextCellValue(row['date']?.toString() ?? ''),
        TextCellValue(row['customer_name']?.toString() ?? ''),
        TextCellValue(row['invoice_status']?.toString() ?? ''),
        DoubleCellValue((row['quantity'] as num?)?.toDouble() ?? 0),
        DoubleCellValue((row['unit_price'] as num?)?.toDouble() ?? 0),
        DoubleCellValue((row['discount_calculated_amount'] as num?)?.toDouble() ?? 0),
        DoubleCellValue((row['line_total'] as num?)?.toDouble() ?? 0),
        DoubleCellValue((row['profit'] as num?)?.toDouble() ?? 0),
      ]);
    }

    // Remove default sheet
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) throw Exception('خطا در ساخت فایل اکسل');

    await _saveFile(bytes, 'گزارش_فروش.xlsx', ['xlsx']);
  }

  /// Export sales ledger data to CSV.
  static Future<void> exportCsv(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) throw Exception('داده‌ای برای خروجی وجود ندارد');

    final buffer = StringBuffer();

    // BOM for Excel UTF-8 compatibility
    buffer.write('\uFEFF');

    // Header
    buffer.writeln('ردیف,نام کالا,شماره فاکتور,تاریخ,مشتری,وضعیت,تعداد,قیمت واحد,تخفیف,جمع سطر,سود سطر');

    // Data
    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      buffer.writeln([
        i + 1,
        _csvEscape(row['product_name']?.toString() ?? ''),
        _csvEscape(row['invoice_number']?.toString() ?? ''),
        _csvEscape(row['date']?.toString() ?? ''),
        _csvEscape(row['customer_name']?.toString() ?? ''),
        _csvEscape(row['invoice_status']?.toString() ?? ''),
        (row['quantity'] as num?)?.toDouble() ?? 0,
        (row['unit_price'] as num?)?.toDouble() ?? 0,
        (row['discount_calculated_amount'] as num?)?.toDouble() ?? 0,
        (row['line_total'] as num?)?.toDouble() ?? 0,
        (row['profit'] as num?)?.toDouble() ?? 0,
      ].join(','));
    }

    final bytes = buffer.toString().codeUnits;
    await _saveFile(bytes, 'گزارش_فروش.csv', ['csv']);
  }

  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static Future<void> _saveFile(List<int> bytes, String defaultName, List<String> extensions) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'ذخیره فایل',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: extensions,
    );

    if (result != null) {
      final file = File(result);
      await file.writeAsBytes(bytes);
    }
  }
}
