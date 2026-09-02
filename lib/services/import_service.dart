import 'dart:io';
import 'package:excel_plus/excel_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../data/models/product_model.dart';

/// Service for importing products from CSV and Excel files.
class ImportService {
  ImportService._();

  /// Import products from a CSV file. Returns a list of ProductModels.
  /// Expected CSV columns: code, name, category, price, unit, stock
  static Future<List<ProductModel>?> importFromCsv() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'انتخاب فایل CSV',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return null;

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();

    if (lines.length < 2) return []; // header + at least one row

    final products = <ProductModel>[];
    // Skip header row
    for (int i = 1; i < lines.length; i++) {
      final cols = _parseCsvLine(lines[i]);
      if (cols.length < 4) continue; // need at minimum: code, name, price, unit

      products.add(ProductModel(
        code: cols.isNotEmpty ? cols[0].trim() : null,
        name: cols.length > 1 ? cols[1].trim() : 'بدون نام',
        category: cols.length > 2 && cols[2].trim().isNotEmpty ? cols[2].trim() : null,
        price: cols.length > 3 ? (double.tryParse(cols[3].trim().replaceAll(',', '')) ?? 0) : 0,
        unit: cols.length > 4 && cols[4].trim().isNotEmpty ? cols[4].trim() : 'عدد',
        stock: cols.length > 5 ? (double.tryParse(cols[5].trim().replaceAll(',', '')) ?? 0) : 0,
      ));
    }

    return products;
  }

  /// Import products from an Excel (.xlsx) file. Returns a list of ProductModels.
  /// Expected columns: code, name, category, price, unit, stock
  static Future<List<ProductModel>?> importFromExcel() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'انتخاب فایل اکسل',
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null || result.files.isEmpty) return null;

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    final products = <ProductModel>[];

    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.length < 2) continue;

      // Skip header row (index 0)
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        String cellStr(int idx) {
          if (idx >= row.length || row[idx] == null) return '';
          return row[idx]!.value?.toString().trim() ?? '';
        }

        double cellNum(int idx) {
          final s = cellStr(idx).replaceAll(',', '');
          return double.tryParse(s) ?? 0;
        }

        final name = cellStr(1);
        if (name.isEmpty) continue;

        products.add(ProductModel(
          code: cellStr(0).isNotEmpty ? cellStr(0) : null,
          name: name,
          category: cellStr(2).isNotEmpty ? cellStr(2) : null,
          price: cellNum(3),
          unit: cellStr(4).isNotEmpty ? cellStr(4) : 'عدد',
          stock: cellNum(5),
        ));
      }
      break; // Only process the first sheet
    }

    return products;
  }

  /// Parse a CSV line handling quoted fields.
  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    final buffer = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }
}
