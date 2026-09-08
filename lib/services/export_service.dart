import 'dart:convert';
import 'dart:io';
import 'package:excel_plus/excel_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../data/models/product_model.dart';

/// Service for exporting data to Excel and CSV files.
class ExportService {
  ExportService._();

  /// Export products list to Excel (.xlsx).
  static Future<void> exportProductsExcel(List<ProductModel> products) async {
    if (products.isEmpty) throw Exception('داده‌ای برای خروجی وجود ندارد');

    final excel = Excel.createExcel();
    final sheet = excel['لیست کالاها'];

    // Header row
    sheet.appendRow([
      TextCellValue('ردیف'),
      TextCellValue('کد کالا'),
      TextCellValue('نام کالا'),
      TextCellValue('دسته‌بندی'),
      TextCellValue('قیمت خرید'),
      TextCellValue('قیمت فروش'),
      TextCellValue('واحد'),
      TextCellValue('موجودی'),
      TextCellValue('سود هر واحد'),
      TextCellValue('درصد سود'),
      TextCellValue('تعداد فروخته شده'),
      TextCellValue('تامین‌کننده'),
    ]);

    // Data rows
    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(p.code ?? ''),
        TextCellValue(p.name),
        TextCellValue(p.category ?? ''),
        DoubleCellValue(p.effectiveBuyPrice),
        DoubleCellValue(p.effectivePrice),
        TextCellValue(p.unit),
        p.isInfiniteStock
            ? TextCellValue('نامحدود')
            : DoubleCellValue(p.stock ?? 0),
        DoubleCellValue(p.profitAmount),
        DoubleCellValue(double.parse(p.profitPercent.toStringAsFixed(1))),
        DoubleCellValue(p.totalSold),
        TextCellValue(p.supplier ?? ''),
      ]);
    }

    // Remove default sheet
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) throw Exception('خطا در ساخت فایل اکسل');

    await _saveFile(bytes, 'لیست_کالاها.xlsx', ['xlsx']);
  }

  /// Export products list to CSV.
  static Future<void> exportProductsCsv(List<ProductModel> products) async {
    if (products.isEmpty) throw Exception('داده‌ای برای خروجی وجود ندارد');

    final buffer = StringBuffer();
    // BOM for Excel UTF-8 compatibility
    buffer.write('\uFEFF');

    // Header
    buffer.writeln('ردیف,کد کالا,نام کالا,دسته‌بندی,قیمت خرید,قیمت فروش,واحد,موجودی,سود هر واحد,درصد سود,تعداد فروخته شده,تامین‌کننده');

    // Data
    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      buffer.writeln([
        i + 1,
        _csvEscape(p.code ?? ''),
        _csvEscape(p.name),
        _csvEscape(p.category ?? ''),
        p.effectiveBuyPrice,
        p.effectivePrice,
        _csvEscape(p.unit),
        p.isInfiniteStock ? 'نامحدود' : (p.stock ?? 0),
        p.profitAmount,
        p.profitPercent.toStringAsFixed(1),
        p.totalSold,
        _csvEscape(p.supplier ?? ''),
      ].join(','));
    }

    final bytes = utf8.encode(buffer.toString());
    await _saveFile(bytes, 'لیست_کالاها.csv', ['csv']);
  }

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

    final bytes = utf8.encode(buffer.toString());
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
      String filePath = result;
      if (extensions.isNotEmpty && !filePath.toLowerCase().endsWith('.${extensions.first.toLowerCase()}')) {
        filePath = '$filePath.${extensions.first}';
      }
      final file = File(filePath);
      await file.writeAsBytes(bytes);
    }
  }
}
