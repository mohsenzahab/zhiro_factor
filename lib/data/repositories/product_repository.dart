import '../../core/database/database_helper.dart';
import '../models/product_model.dart';

/// Repository for Product CRUD operations.
class ProductRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Fetch all products, optionally filtered by search query.
  Future<List<ProductModel>> getAll({String? query}) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps;

    if (query != null && query.isNotEmpty) {
      maps = await db.query(
        'products',
        where: 'name LIKE ? OR code LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'name ASC',
      );
    } else {
      maps = await db.query('products', orderBy: 'name ASC');
    }

    return maps.map((m) => ProductModel.fromMap(m)).toList();
  }

  /// Fetch a single product by ID.
  Future<ProductModel?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ProductModel.fromMap(maps.first);
  }

  /// Insert a new product. Returns the new row ID.
  Future<int> insert(ProductModel product) async {
    final db = await _dbHelper.database;
    return await db.insert('products', product.toMap());
  }

  /// Update an existing product. Returns rows affected.
  Future<int> update(ProductModel product) async {
    final db = await _dbHelper.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// Delete a product by ID. Returns rows affected.
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  /// Adjust stock for a product (positive = add, negative = subtract).
  Future<void> adjustStock(int productId, double delta) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE products SET stock = stock + ? WHERE id = ?',
      [delta, productId],
    );
  }

  /// Get the next available product code.
  Future<String> nextCode() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT code FROM products WHERE code LIKE 'P%' ORDER BY code DESC LIMIT 1",
    );
    if (result.isEmpty) return 'P001';
    final lastCode = result.first['code'] as String;
    final num = int.tryParse(lastCode.substring(1)) ?? 0;
    return 'P${(num + 1).toString().padLeft(3, '0')}';
  }

  /// Get all distinct non-null categories.
  Future<List<String>> getDistinctCategories() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT DISTINCT category FROM products WHERE category IS NOT NULL AND category != '' ORDER BY category ASC",
    );
    return result.map((r) => r['category'] as String).toList();
  }

  /// Bulk import products. Returns the count of successfully imported rows.
  Future<int> importProducts(List<ProductModel> products) async {
    final db = await _dbHelper.database;
    int count = 0;
    await db.transaction((txn) async {
      for (final p in products) {
        await txn.insert('products', p.toMap());
        count++;
      }
    });
    return count;
  }

  /// Apply a profit percentage to all products.
  /// Sets sell_price = current_buy_price (or buy_price) * (1 + percentage / 100) for all products.
  Future<void> bulkApplyProfitMargin(double percentage) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE products SET sell_price = COALESCE(current_buy_price, buy_price) * (1 + ? / 100.0)',
      [percentage],
    );
  }
}

