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
    final map = product.toMap();
    map.remove('id'); // Do not update primary key
    return await db.update(
      'products',
      map,
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// Check if a product code is already in use by another product.
  Future<bool> isCodeTaken(String code, {int? excludeId}) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return false;
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT id FROM products WHERE code = ? AND (? IS NULL OR id != ?)',
      [trimmed, excludeId, excludeId],
    );
    return result.isNotEmpty;
  }

  /// Delete a product by ID. Safely sets invoice_items.product_id to NULL first.
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE invoice_items SET product_id = NULL WHERE product_id = ?',
        [id],
      );
      return await txn.delete('products', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Delete multiple products by IDs safely within a transaction.
  Future<int> deleteMany(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final db = await _dbHelper.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE invoice_items SET product_id = NULL WHERE product_id IN ($placeholders)',
        ids,
      );
      return await txn.rawDelete(
        'DELETE FROM products WHERE id IN ($placeholders)',
        ids,
      );
    });
  }

  /// Move multiple products to a new category (or uncategorized if null/empty).
  Future<int> updateCategoryForIds(List<int> ids, String? category) async {
    if (ids.isEmpty) return 0;
    final db = await _dbHelper.database;
    final cleanCat = (category != null && category.trim().isNotEmpty) ? category.trim() : null;
    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.rawUpdate(
      'UPDATE products SET category = ? WHERE id IN ($placeholders)',
      [cleanCat, ...ids],
    );
  }

  /// Adjust stock for a product (positive = add, negative = subtract).
  /// Preserves null (infinite) stock.
  Future<void> adjustStock(int productId, double delta) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE products SET stock = stock + ? WHERE id = ? AND stock IS NOT NULL',
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

  /// Apply a profit percentage to products, optionally filtered by category.
  /// Calculation is strictly based on current_buy_price (falling back to buy_price if null or 0).
  /// The sell_price is always rounded to the nearest integer.
  Future<int> bulkApplyProfitMargin(double percentage, {String? category}) async {
    final db = await _dbHelper.database;
    const basePriceExpr = '(CASE WHEN current_buy_price IS NOT NULL AND current_buy_price > 0 THEN current_buy_price ELSE buy_price END)';
    if (category == null) {
      return await db.rawUpdate(
        'UPDATE products SET sell_price = ROUND($basePriceExpr * (1 + ? / 100.0))',
        [percentage],
      );
    } else if (category == '__uncategorized__') {
      return await db.rawUpdate(
        "UPDATE products SET sell_price = ROUND($basePriceExpr * (1 + ? / 100.0)) WHERE category IS NULL OR category = ''",
        [percentage],
      );
    } else {
      return await db.rawUpdate(
        'UPDATE products SET sell_price = ROUND($basePriceExpr * (1 + ? / 100.0)) WHERE category = ?',
        [percentage, category],
      );
    }
  }
}

