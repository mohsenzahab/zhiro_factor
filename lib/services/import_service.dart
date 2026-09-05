import 'dart:convert';
import 'dart:io';
import 'package:excel_plus/excel_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/product_model.dart';

/// Represents raw data read from a file: column headers + data rows.
class ImportFileData {
  final String fileType; // 'csv' or 'excel'
  final List<String> headers;
  final List<List<String>> rows;

  const ImportFileData({
    required this.fileType,
    required this.headers,
    required this.rows,
  });
}

/// Column mapping: maps a DB field key to a file column index.
/// An index of -1 means "skip / not mapped".
class ImportColumnMapping {
  final Map<String, int> mapping; // dbField -> fileColumnIndex

  const ImportColumnMapping(this.mapping);

  /// All DB fields that can be mapped.
  static const List<String> dbFields = [
    'code',
    'name',
    'category',
    'buy_price',
    'sell_price',
    'unit',
    'stock',
  ];

  /// Persian labels for DB fields.
  static const Map<String, String> dbFieldLabels = {
    'code': 'کد کالا',
    'name': 'نام کالا (الزامی)',
    'category': 'دسته‌بندی',
    'buy_price': 'قیمت خرید',
    'sell_price': 'قیمت فروش',
    'unit': 'واحد',
    'stock': 'موجودی',
  };

  /// Save mapping to SharedPreferences.
  Future<void> save(String fileType) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = mapping.map((k, v) => MapEntry(k, v));
    await prefs.setString('import_mapping_$fileType', jsonEncode(jsonMap));
  }

  /// Load saved mapping from SharedPreferences.
  static Future<ImportColumnMapping?> load(String fileType) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('import_mapping_$fileType');
    if (jsonStr == null) return null;
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final map = decoded.map((k, v) => MapEntry(k, v as int));
      if (!map.containsKey('buy_price') && map.containsKey('price')) {
        map['buy_price'] = map['price']!;
      }
      return ImportColumnMapping(map);
    } catch (_) {
      return null;
    }
  }

  /// Create a default mapping that assigns columns 0-5 to fields in order.
  static ImportColumnMapping defaultMapping(int headerCount) {
    final map = <String, int>{};
    for (int i = 0; i < dbFields.length; i++) {
      map[dbFields[i]] = i < headerCount ? i : -1;
    }
    return ImportColumnMapping(map);
  }
}

/// Service for importing products from CSV and Excel files.
class ImportService {
  ImportService._();

  // ──────────────────────────────────────────────────────────────
  // Step 1: Pick & Read file → return raw headers + rows
  // ──────────────────────────────────────────────────────────────

  /// Pick a CSV file and return its raw data.
  static Future<ImportFileData?> readCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'انتخاب فایل CSV',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return null;

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();

    if (lines.isEmpty) return null;

    final headers = _parseCsvLine(lines[0]).map((h) => h.trim()).toList();
    final rows = <List<String>>[];
    for (int i = 1; i < lines.length; i++) {
      rows.add(_parseCsvLine(lines[i]).map((c) => c.trim()).toList());
    }

    return ImportFileData(fileType: 'csv', headers: headers, rows: rows);
  }

  /// Pick an Excel file and return its raw data.
  static Future<ImportFileData?> readExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'انتخاب فایل اکسل',
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null || result.files.isEmpty) return null;

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) continue;

      // First row = headers
      final headers = sheet.rows[0]
          .map((cell) => cell?.value?.toString().trim() ?? '')
          .toList();

      final rows = <List<String>>[];
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;
        rows.add(
          row.map((cell) => cell?.value?.toString().trim() ?? '').toList(),
        );
      }

      return ImportFileData(fileType: 'excel', headers: headers, rows: rows);
    }

    return null;
  }

  // ──────────────────────────────────────────────────────────────
  // Step 2: Apply mapping to raw data → produce ProductModels
  // ──────────────────────────────────────────────────────────────

  /// Convert raw file rows to ProductModels using the given column mapping.
  static List<ProductModel> applyMapping(
    ImportFileData data,
    ImportColumnMapping mapping,
  ) {
    final products = <ProductModel>[];

    for (final row in data.rows) {
      String getField(String key) {
        final idx = mapping.mapping[key] ?? -1;
        if (idx < 0 || idx >= row.length) return '';
        return row[idx].trim();
      }

      double getNum(String key) {
        final s = getField(key).replaceAll(',', '');
        return double.tryParse(s) ?? 0;
      }

      final name = getField('name');
      if (name.isEmpty) continue; // name is required

      final buyPriceNum = (mapping.mapping.containsKey('buy_price') && (mapping.mapping['buy_price'] ?? -1) >= 0)
          ? getNum('buy_price')
          : getNum('price');
      final sellPriceNum = (mapping.mapping.containsKey('sell_price') && (mapping.mapping['sell_price'] ?? -1) >= 0)
          ? getNum('sell_price')
          : null;

      products.add(ProductModel(
        code: getField('code').isNotEmpty ? getField('code') : null,
        name: name,
        category: getField('category').isNotEmpty ? getField('category') : null,
        buyPrice: buyPriceNum,
        currentBuyPrice: buyPriceNum,
        sellPrice: sellPriceNum != null && sellPriceNum > 0 ? sellPriceNum : null,
        unit: getField('unit').isNotEmpty ? getField('unit') : 'عدد',
        stock: getNum('stock'),
      ));
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
