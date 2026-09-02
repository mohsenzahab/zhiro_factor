import '../../core/database/database_helper.dart';
import '../models/customer_model.dart';

/// Repository for Customer CRUD operations.
class CustomerRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Fetch all customers, optionally filtered by search query.
  Future<List<CustomerModel>> getAll({String? query}) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps;

    if (query != null && query.isNotEmpty) {
      maps = await db.query(
        'customers',
        where: 'name LIKE ? OR phone LIKE ? OR code LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'name ASC',
      );
    } else {
      maps = await db.query('customers', orderBy: 'name ASC');
    }

    return maps.map((m) => CustomerModel.fromMap(m)).toList();
  }

  /// Fetch a single customer by ID.
  Future<CustomerModel?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return CustomerModel.fromMap(maps.first);
  }

  /// Insert a new customer. Returns the new row ID.
  Future<int> insert(CustomerModel customer) async {
    final db = await _dbHelper.database;
    return await db.insert('customers', customer.toMap());
  }

  /// Update an existing customer.
  Future<int> update(CustomerModel customer) async {
    final db = await _dbHelper.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  /// Delete a customer by ID.
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  /// Get the next available customer code.
  Future<String> nextCode() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT code FROM customers WHERE code LIKE 'C%' ORDER BY code DESC LIMIT 1",
    );
    if (result.isEmpty) return 'C001';
    final lastCode = result.first['code'] as String;
    final num = int.tryParse(lastCode.substring(1)) ?? 0;
    return 'C${(num + 1).toString().padLeft(3, '0')}';
  }
}
