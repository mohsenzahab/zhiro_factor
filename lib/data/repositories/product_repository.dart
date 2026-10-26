import 'package:sqflite_common/sqlite_api.dart';
import '../../core/database/database_helper.dart';
import '../../core/extensions/number_extensions.dart';
import '../models/product_model.dart';

/// Repository for Product CRUD operations.
class ProductRepository {
  final DatabaseHelper _dbHelper;
  final Database? _overrideDb;

  ProductRepository({DatabaseHelper? dbHelper, Database? db})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _overrideDb = db;

  Future<Database> get _database async => _overrideDb ?? await _dbHelper.database;

  Future<bool> _tableExists(DatabaseExecutor db, String tableName) async {
    final res = await db.rawQuery(
      "SELECT 1 FROM sqlite_master WHERE type='table' AND name = ?",
      [tableName],
    );
    return res.isNotEmpty;
  }

  /// Fetch all products with sold quantity joined, optionally filtered by search query.
  /// Resolves the supplier title (from products.supplier, suppliers table, or latest purchase).
  Future<List<ProductModel>> getAll({String? query}) async {
    final db = await _database;
    final hasSuppliers = await _tableExists(db, 'suppliers');
    final hasPurchases = hasSuppliers &&
        await _tableExists(db, 'purchases') &&
        await _tableExists(db, 'purchase_items');

    String supplierExpr;
    String joins = '';

    if (hasSuppliers) {
      joins += '''
        LEFT JOIN suppliers sup_direct ON (
          (p.supplier GLOB '[0-9]*' AND CAST(p.supplier AS INTEGER) = sup_direct.id)
          OR p.supplier = sup_direct.name
        )
      ''';
      if (hasPurchases) {
        joins += '''
          LEFT JOIN (
            SELECT 
              pi.product_id,
              sup.name as supplier_name,
              ROW_NUMBER() OVER (PARTITION BY pi.product_id ORDER BY pu.date DESC, pu.id DESC) as rn
            FROM purchase_items pi
            JOIN purchases pu ON pi.purchase_id = pu.id
            JOIN suppliers sup ON pu.supplier_id = sup.id
          ) latest_purchase ON p.id = latest_purchase.product_id AND latest_purchase.rn = 1
        ''';
        supplierExpr = 'COALESCE(sup_direct.name, NULLIF(p.supplier, \'\'), latest_purchase.supplier_name)';
      } else {
        supplierExpr = 'COALESCE(sup_direct.name, NULLIF(p.supplier, \'\'))';
      }
    } else {
      supplierExpr = 'p.supplier';
    }

    final baseSql = '''
      SELECT 
        p.*, 
        COALESCE(s.total_sold, 0.0) as total_sold,
        $supplierExpr as resolved_supplier
      FROM products p
      $joins
      LEFT JOIN (
        SELECT product_id, SUM(quantity) as total_sold
        FROM invoice_items
        WHERE product_id IS NOT NULL
        GROUP BY product_id
      ) s ON p.id = s.product_id
    ''';

    String sql = 'SELECT * FROM ($baseSql) AS p_sub';
    final args = <dynamic>[];

    if (query != null && query.isNotEmpty) {
      final enQuery = query.toEnglishDigits();
      if (enQuery != query) {
        sql += ' WHERE name LIKE ? OR code LIKE ? OR code LIKE ? OR resolved_supplier LIKE ?';
        args.addAll(['%$query%', '%$query%', '%$enQuery%', '%$query%']);
      } else {
        sql += ' WHERE name LIKE ? OR code LIKE ? OR resolved_supplier LIKE ?';
        args.addAll(['%$query%', '%$query%', '%$query%']);
      }
    }

    sql += ' ORDER BY name ASC';

    final maps = await db.rawQuery(sql, args);
    return maps.map((m) => ProductModel.fromMap(m)).toList();
  }

  /// Fetch a single product by ID with sold quantity joined.
  Future<ProductModel?> getById(int id) async {
    final db = await _database;
    final hasSuppliers = await _tableExists(db, 'suppliers');
    final hasPurchases = hasSuppliers &&
        await _tableExists(db, 'purchases') &&
        await _tableExists(db, 'purchase_items');

    String supplierExpr;
    String joins = '';

    if (hasSuppliers) {
      joins += '''
        LEFT JOIN suppliers sup_direct ON (
          (p.supplier GLOB '[0-9]*' AND CAST(p.supplier AS INTEGER) = sup_direct.id)
          OR p.supplier = sup_direct.name
        )
      ''';
      if (hasPurchases) {
        joins += '''
          LEFT JOIN (
            SELECT 
              pi.product_id,
              sup.name as supplier_name,
              ROW_NUMBER() OVER (PARTITION BY pi.product_id ORDER BY pu.date DESC, pu.id DESC) as rn
            FROM purchase_items pi
            JOIN purchases pu ON pi.purchase_id = pu.id
            JOIN suppliers sup ON pu.supplier_id = sup.id
          ) latest_purchase ON p.id = latest_purchase.product_id AND latest_purchase.rn = 1
        ''';
        supplierExpr = 'COALESCE(sup_direct.name, NULLIF(p.supplier, \'\'), latest_purchase.supplier_name)';
      } else {
        supplierExpr = 'COALESCE(sup_direct.name, NULLIF(p.supplier, \'\'))';
      }
    } else {
      supplierExpr = 'p.supplier';
    }

    final sql = '''
      SELECT 
        p.*, 
        COALESCE(s.total_sold, 0.0) as total_sold,
        $supplierExpr as resolved_supplier
      FROM products p
      $joins
      LEFT JOIN (
        SELECT product_id, SUM(quantity) as total_sold
        FROM invoice_items
        WHERE product_id = ?
        GROUP BY product_id
      ) s ON p.id = s.product_id
      WHERE p.id = ?
    ''';

    final maps = await db.rawQuery(sql, [id, id]);
    if (maps.isEmpty) return null;
    return ProductModel.fromMap(maps.first);
  }

  /// Insert a new product. Returns the new row ID.
  Future<int> insert(ProductModel product) async {
    final db = await _database;
    return await db.insert('products', product.toMap());
  }

  /// Update an existing product. Returns rows affected.
  Future<int> update(ProductModel product) async {
    final db = await _database;

    // Detect and log buy price modification in price_change_history
    if (product.id != null && await _tableExists(db, 'price_change_history')) {
      final existingRows = await db.query(
        'products',
        columns: ['buy_price', 'current_buy_price'],
        where: 'id = ?',
        whereArgs: [product.id],
      );
      if (existingRows.isNotEmpty) {
        final oldRow = existingRows.first;
        final oldBuy = (oldRow['buy_price'] as num?)?.toDouble() ?? 0.0;
        final oldCurBuy = (oldRow['current_buy_price'] as num?)?.toDouble();
        final oldEffective = (oldCurBuy != null && oldCurBuy > 0) ? oldCurBuy : oldBuy;
        final newEffective = product.effectiveBuyPrice;

        if (oldEffective > 0 && (newEffective - oldEffective).abs() > 0.001) {
          await db.insert('price_change_history', {
            'product_id': product.id,
            'old_price': oldEffective,
            'new_price': newEffective,
            'change_amount': newEffective - oldEffective,
            'change_type': 'manual',
            'change_source': 'ویرایش دستی',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
    }

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
    final db = await _database;
    final result = await db.rawQuery(
      'SELECT id FROM products WHERE code = ? AND (? IS NULL OR id != ?)',
      [trimmed, excludeId, excludeId],
    );
    return result.isNotEmpty;
  }

  /// Delete a product by ID. Safely sets invoice_items.product_id to NULL first.
  Future<int> delete(int id) async {
    final db = await _database;
    return await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE invoice_items SET product_id = NULL WHERE product_id = ?',
        [id],
      );
      await txn.rawUpdate(
        'UPDATE purchase_items SET product_id = NULL WHERE product_id = ?',
        [id],
      );
      if (await _tableExists(txn, 'price_change_history')) {
        await txn.delete('price_change_history', where: 'product_id = ?', whereArgs: [id]);
      }
      return await txn.delete('products', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Delete multiple products by IDs safely within a transaction.
  Future<int> deleteMany(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final db = await _database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE invoice_items SET product_id = NULL WHERE product_id IN ($placeholders)',
        ids,
      );
      await txn.rawUpdate(
        'UPDATE purchase_items SET product_id = NULL WHERE product_id IN ($placeholders)',
        ids,
      );
      if (await _tableExists(txn, 'price_change_history')) {
        await txn.rawDelete(
          'DELETE FROM price_change_history WHERE product_id IN ($placeholders)',
          ids,
        );
      }
      return await txn.rawDelete(
        'DELETE FROM products WHERE id IN ($placeholders)',
        ids,
      );
    });
  }

  /// Move multiple products to a new category (or uncategorized if null/empty).
  Future<int> updateCategoryForIds(List<int> ids, String? category) async {
    if (ids.isEmpty) return 0;
    final db = await _database;
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
    final db = await _database;
    await db.rawUpdate(
      'UPDATE products SET stock = stock + ? WHERE id = ? AND stock IS NOT NULL',
      [delta, productId],
    );
  }

  /// Get the next available product code.
  Future<String> nextCode() async {
    final db = await _database;
    final result = await db.rawQuery(
      "SELECT code FROM products WHERE code LIKE 'P%' ORDER BY code DESC LIMIT 1",
    );
    if (result.isEmpty) return 'P001';
    final lastCode = (result.first['code'] as String).toEnglishDigits();
    final num = int.tryParse(lastCode.substring(1)) ?? 0;
    return 'P${(num + 1).toString().padLeft(3, '0')}';
  }

  /// Get all distinct non-null categories.
  Future<List<String>> getDistinctCategories() async {
    final db = await _database;
    final result = await db.rawQuery(
      "SELECT DISTINCT category FROM products WHERE category IS NOT NULL AND category != '' ORDER BY category ASC",
    );
    return result.map((r) => r['category'] as String).toList();
  }

  /// Get all distinct non-null suppliers across products and suppliers table.
  Future<List<String>> getDistinctSuppliers() async {
    final db = await _database;
    final hasSuppliers = await _tableExists(db, 'suppliers');
    if (hasSuppliers) {
      final result = await db.rawQuery('''
        SELECT DISTINCT name FROM (
          SELECT supplier AS name FROM products WHERE supplier IS NOT NULL AND supplier != ''
          UNION
          SELECT name FROM suppliers WHERE name IS NOT NULL AND name != ''
        ) ORDER BY name ASC
      ''');
      return result.map((r) => r['name'] as String).toList();
    } else {
      final result = await db.rawQuery(
        "SELECT DISTINCT supplier FROM products WHERE supplier IS NOT NULL AND supplier != '' ORDER BY supplier ASC",
      );
      return result.map((r) => r['supplier'] as String).toList();
    }
  }

  /// Bulk import products. Returns the count of successfully imported rows.
  Future<int> importProducts(List<ProductModel> products) async {
    final db = await _database;
    int count = 0;
    await db.transaction((txn) async {
      for (final p in products) {
        await txn.insert('products', p.toMap());
        count++;
      }
    });
    return count;
  }

  /// Apply a profit percentage to products' sell prices.
  /// If [productIds] is provided and not empty, applies only to those specific products.
  /// Otherwise, if [category] is provided, applies only to that category (or uncategorized).
  /// If both are null/empty, applies to all products.
  /// Calculation is strictly based on current_buy_price (falling back to buy_price).
  /// The sell_price is always rounded to the nearest multiple of 5,000.
  Future<int> bulkApplyProfitMargin(
    double percentage, {
    String? category,
    List<int>? productIds,
  }) async {
    final db = await _database;
    const basePriceExpr = '(CASE WHEN current_buy_price IS NOT NULL AND current_buy_price > 0 THEN current_buy_price ELSE buy_price END)';
    const roundedExpr = '(CASE WHEN $basePriceExpr <= 0 THEN 0 ELSE MAX(5000, ROUND(($basePriceExpr * (1 + ? / 100.0)) / 5000.0) * 5000) END)';

    if (productIds != null && productIds.isNotEmpty) {
      final placeholders = List.filled(productIds.length, '?').join(',');
      return await db.rawUpdate(
        'UPDATE products SET sell_price = $roundedExpr WHERE id IN ($placeholders)',
        [percentage, ...productIds],
      );
    }

    if (category == null) {
      return await db.rawUpdate(
        'UPDATE products SET sell_price = $roundedExpr',
        [percentage],
      );
    } else if (category == '__uncategorized__') {
      return await db.rawUpdate(
        "UPDATE products SET sell_price = $roundedExpr WHERE category IS NULL OR category = ''",
        [percentage],
      );
    } else {
      return await db.rawUpdate(
        'UPDATE products SET sell_price = $roundedExpr WHERE category = ?',
        [percentage, category],
      );
    }
  }

  /// Batch apply a price adjustment percentage (positive or negative) to products.
  ///
  /// For each product:
  /// 1. The base buy price is current_buy_price if set and > 0, otherwise buy_price.
  /// 2. New current_buy_price = round(baseBuyPrice * (1 + percentage / 100)).
  ///    (If the product previously did not have a current_buy_price, this saves the adjusted
  ///     price into current_buy_price while preserving the original buy_price).
  /// 3. If sell_price is set and > 0 and baseBuyPrice > 0, the sell price is recalculated
  ///    using the previously established profit margin percentage relative to the new current buy price:
  ///    newSellPrice = (newCurrentBuyPrice * (sell_price / baseBuyPrice)).roundTo5000.
  ///
  /// Target scope:
  /// - [productIds] if not empty -> specific products.
  /// - [category] == '__uncategorized__' -> uncategorized products.
  /// - [category] != null -> products belonging to that category.
  /// - otherwise -> all products.
  Future<int> bulkApplyPriceAdjustment(
    double percentage, {
    String? category,
    List<int>? productIds,
  }) async {
    final db = await _database;

    String? whereClause;
    List<dynamic> whereArgs = [];

    if (productIds != null && productIds.isNotEmpty) {
      final placeholders = List.filled(productIds.length, '?').join(',');
      whereClause = 'id IN ($placeholders)';
      whereArgs = productIds;
    } else if (category == '__uncategorized__') {
      whereClause = "category IS NULL OR category = ''";
    } else if (category != null) {
      whereClause = 'category = ?';
      whereArgs = [category];
    }

    final rows = await db.query(
      'products',
      columns: ['id', 'buy_price', 'current_buy_price', 'sell_price'],
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    if (rows.isEmpty) return 0;

    final batch = db.batch();
    int count = 0;
    final hasHistoryTable = await _tableExists(db, 'price_change_history');

    for (final row in rows) {
      final id = row['id'] as int;
      final buyPrice = (row['buy_price'] as num?)?.toDouble() ?? 0.0;
      final currentBuyPrice = (row['current_buy_price'] as num?)?.toDouble();
      final sellPrice = (row['sell_price'] as num?)?.toDouble();

      final baseBuyPrice = (currentBuyPrice != null && currentBuyPrice > 0)
          ? currentBuyPrice
          : buyPrice;

      if (baseBuyPrice <= 0) continue;

      // 1. Calculate new current buy price
      final rawNewCurrentBuy = baseBuyPrice * (1.0 + percentage / 100.0);
      final newCurrentBuy = rawNewCurrentBuy.roundToDouble();

      // 2. Recalculate sell price with previously established profit margin percentage
      double? newSellPrice = sellPrice;
      if (sellPrice != null && sellPrice > 0) {
        final profitMarginRatio = sellPrice / baseBuyPrice;
        final rawNewSell = newCurrentBuy * profitMarginRatio;
        newSellPrice = rawNewSell.roundTo5000;
      }

      batch.update(
        'products',
        {
          'current_buy_price': newCurrentBuy,
          'sell_price': newSellPrice,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      // Record in price_change_history if table exists
      if (hasHistoryTable && (newCurrentBuy - baseBuyPrice).abs() > 0.001) {
        final changeAmt = newCurrentBuy - baseBuyPrice;
        final source = percentage >= 0
            ? 'افزایش ${percentage.formatted}٪ گروهی'
            : 'کاهش ${percentage.abs().formatted}٪ گروهی';
        batch.insert('price_change_history', {
          'product_id': id,
          'old_price': baseBuyPrice,
          'new_price': newCurrentBuy,
          'change_amount': changeAmt,
          'change_type': 'batch_adjustment',
          'change_source': source,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      count++;
    }

    if (count > 0) {
      await batch.commit(noResult: true);
    }
    return count;
  }

  /// Batch fetch product detail info including stock, total sold,
  /// current buy price, and FIFO initial buy price of oldest available inventory.
  Future<Map<int, ProductDetailInfo>> getProductsDetailInfo(List<int> productIds) async {
    if (productIds.isEmpty) return {};
    final db = await _database;
    final placeholders = List.filled(productIds.length, '?').join(',');

    // 1. Fetch product master rows
    final productRows = await db.rawQuery(
      'SELECT id, category, stock, buy_price, current_buy_price FROM products WHERE id IN ($placeholders)',
      productIds,
    );

    // 2. Fetch total sold per product across all invoices
    final soldRows = await db.rawQuery(
      'SELECT product_id, SUM(quantity) as total_sold FROM invoice_items WHERE product_id IN ($placeholders) GROUP BY product_id',
      productIds,
    );
    final soldMap = <int, double>{};
    for (final r in soldRows) {
      final pid = r['product_id'] as int?;
      if (pid != null) {
        soldMap[pid] = (r['total_sold'] as num?)?.toDouble() ?? 0.0;
      }
    }

    // 3. Fetch purchase history in chronological order (FIFO)
    final purchaseRows = await db.rawQuery('''
      SELECT pi.product_id, pi.quantity, pi.unit_price, p.date, p.id
      FROM purchase_items pi
      JOIN purchases p ON pi.purchase_id = p.id
      WHERE pi.product_id IN ($placeholders)
      ORDER BY p.date ASC, p.id ASC
    ''', productIds);

    final purchasesByProduct = <int, List<({double quantity, double unitPrice})>>{};
    for (final r in purchaseRows) {
      final pid = r['product_id'] as int?;
      if (pid != null) {
        purchasesByProduct.putIfAbsent(pid, () => []).add((
          quantity: (r['quantity'] as num).toDouble(),
          unitPrice: (r['unit_price'] as num).toDouble(),
        ));
      }
    }

    final result = <int, ProductDetailInfo>{};
    for (final row in productRows) {
      final pid = row['id'] as int;
      final category = row['category'] as String?;
      final stock = row['stock'] != null ? (row['stock'] as num).toDouble() : null;
      final baseBuy = (row['buy_price'] as num?)?.toDouble() ?? 0.0;
      final currentBuyRaw = (row['current_buy_price'] as num?)?.toDouble();
      final currentBuy = (currentBuyRaw != null && currentBuyRaw > 0) ? currentBuyRaw : baseBuy;
      final totalSold = soldMap[pid] ?? 0.0;

      // FIFO calculation for oldest batch available in warehouse:
      double initialBuy = baseBuy;
      if (stock != null && stock > 0) {
        final purchases = purchasesByProduct[pid] ?? [];
        final double totalPurchased = purchases.fold(0.0, (sum, p) => sum + p.quantity);
        final double initialStock = (stock + totalSold - totalPurchased).clamp(0.0, double.infinity);

        double soldRemaining = totalSold;
        bool batchFound = false;

        // Check if initial stock still has units remaining
        if (initialStock > 0) {
          if (soldRemaining < initialStock) {
            initialBuy = baseBuy;
            batchFound = true;
          } else {
            soldRemaining -= initialStock;
          }
        }

        // If initial stock was exhausted, check purchases chronologically
        if (!batchFound) {
          for (final p in purchases) {
            if (soldRemaining < p.quantity) {
              initialBuy = p.unitPrice;
              batchFound = true;
              break;
            } else {
              soldRemaining -= p.quantity;
            }
          }
        }

        if (!batchFound) {
          initialBuy = currentBuy;
        }
      }

      result[pid] = ProductDetailInfo(
        productId: pid,
        category: category,
        stock: stock,
        totalSold: totalSold,
        currentBuyPrice: currentBuy,
        initialBuyPrice: initialBuy,
      );
    }

    return result;
  }
}

/// Product details for tooltips and inventory inspection.
class ProductDetailInfo {
  final int productId;
  final String? category;
  final double? stock;
  final double totalSold;
  final double currentBuyPrice;
  final double initialBuyPrice;

  const ProductDetailInfo({
    required this.productId,
    this.category,
    this.stock,
    required this.totalSold,
    required this.currentBuyPrice,
    required this.initialBuyPrice,
  });
}

