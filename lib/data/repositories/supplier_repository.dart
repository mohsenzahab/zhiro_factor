import '../../core/database/database_helper.dart';
import '../../core/extensions/number_extensions.dart';
import '../models/supplier_model.dart';

/// Repository for Supplier CRUD operations.
class SupplierRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Fetch all suppliers, optionally filtered by search query.
  Future<List<SupplierModel>> getAll({String? query}) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps;

    if (query != null && query.isNotEmpty) {
      final enQuery = query.toEnglishDigits();
      if (enQuery != query) {
        maps = await db.query(
          'suppliers',
          where: 'name LIKE ? OR phone LIKE ? OR code LIKE ? OR phone LIKE ? OR code LIKE ?',
          whereArgs: ['%$query%', '%$query%', '%$query%', '%$enQuery%', '%$enQuery%'],
          orderBy: 'name ASC',
        );
      } else {
        maps = await db.query(
          'suppliers',
          where: 'name LIKE ? OR phone LIKE ? OR code LIKE ?',
          whereArgs: ['%$query%', '%$query%', '%$query%'],
          orderBy: 'name ASC',
        );
      }
    } else {
      maps = await db.query('suppliers', orderBy: 'name ASC');
    }

    return maps.map((m) => SupplierModel.fromMap(m)).toList();
  }

  /// Fetch a single supplier by ID.
  Future<SupplierModel?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('suppliers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return SupplierModel.fromMap(maps.first);
  }

  /// Insert a new supplier. Returns the new row ID.
  Future<int> insert(SupplierModel supplier) async {
    final db = await _dbHelper.database;
    return await db.insert('suppliers', supplier.toMap());
  }

  /// Update an existing supplier.
  Future<int> update(SupplierModel supplier) async {
    final db = await _dbHelper.database;
    return await db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  /// Delete a supplier by ID.
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  /// Get the next available supplier code.
  Future<String> nextCode() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT code FROM suppliers WHERE code LIKE 'S%' ORDER BY code DESC LIMIT 1",
    );
    if (result.isEmpty) return 'S001';
    final lastCode = result.first['code'] as String;
    final num = int.tryParse(lastCode.substring(1)) ?? 0;
    return 'S${(num + 1).toString().padLeft(3, '0')}';
  }
}
