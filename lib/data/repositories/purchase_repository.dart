import '../../core/database/database_helper.dart';
import '../../core/extensions/number_extensions.dart';
import '../models/purchase_model.dart';
import '../models/purchase_item_model.dart';

/// Repository for Purchase CRUD with transactional item management and stock updates.
class PurchaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Fetch all purchases with supplier name join, optionally filtered.
  Future<List<PurchaseModel>> getAll({
    String? supplierQuery,
    int? supplierId,
    int? productId,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    final db = await _dbHelper.database;

    String sql = '''
      SELECT DISTINCT p.*, s.name as supplier_name
      FROM purchases p
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      ${productId != null ? 'INNER JOIN purchase_items pi ON p.id = pi.purchase_id' : ''}
      WHERE 1=1
    ''';
    final args = <dynamic>[];

    if (supplierQuery != null && supplierQuery.isNotEmpty) {
      final enQuery = supplierQuery.toEnglishDigits();
      if (enQuery != supplierQuery) {
        sql += ' AND (s.name LIKE ? OR p.purchase_number LIKE ? OR p.purchase_number LIKE ?)';
        args.addAll(['%$supplierQuery%', '%$supplierQuery%', '%$enQuery%']);
      } else {
        sql += ' AND (s.name LIKE ? OR p.purchase_number LIKE ?)';
        args.addAll(['%$supplierQuery%', '%$supplierQuery%']);
      }
    }
    if (status != null && status.isNotEmpty) {
      sql += ' AND p.status = ?';
      args.add(status);
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      sql += ' AND p.date >= ?';
      args.add(dateFrom);
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      sql += ' AND p.date <= ?';
      args.add(dateTo);
    }
    if (supplierId != null) {
      sql += ' AND p.supplier_id = ?';
      args.add(supplierId);
    }
    if (productId != null) {
      sql += ' AND pi.product_id = ?';
      args.add(productId);
    }

    sql += ' ORDER BY p.date DESC, p.id DESC';

    final maps = await db.rawQuery(sql, args);
    if (maps.isEmpty) return [];

    // Batch load items for all returned purchases
    final purchaseIds = maps.map((m) => m['id'] as int).toList();
    final placeholders = List.filled(purchaseIds.length, '?').join(',');
    final itemMaps = await db.rawQuery(
      'SELECT * FROM purchase_items WHERE purchase_id IN ($placeholders) ORDER BY id ASC',
      purchaseIds,
    );
    final itemsByPurchase = <int, List<PurchaseItemModel>>{};
    for (final im in itemMaps) {
      final item = PurchaseItemModel.fromMap(im);
      if (item.purchaseId != null) {
        itemsByPurchase.putIfAbsent(item.purchaseId!, () => []).add(item);
      }
    }
    return maps.map((m) {
      final id = m['id'] as int?;
      return PurchaseModel.fromMap(m, items: id != null ? itemsByPurchase[id] : null);
    }).toList();
  }

  /// Fetch a single purchase by ID with all its items.
  Future<PurchaseModel?> getById(int id) async {
    final db = await _dbHelper.database;
    final purchaseMaps = await db.rawQuery('''
      SELECT p.*, s.name as supplier_name
      FROM purchases p
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.id = ?
    ''', [id]);

    if (purchaseMaps.isEmpty) return null;

    final itemMaps = await db.query(
      'purchase_items',
      where: 'purchase_id = ?',
      whereArgs: [id],
      orderBy: 'id ASC',
    );

    final items = itemMaps.map((m) => PurchaseItemModel.fromMap(m)).toList();
    return PurchaseModel.fromMap(purchaseMaps.first, items: items);
  }

  /// Save a new purchase with items in a single transaction.
  /// Automatically adds purchased quantities to product stock and updates current_buy_price.
  /// Returns the new purchase ID.
  Future<int> insert(PurchaseModel purchase) async {
    final db = await _dbHelper.database;
    late int purchaseId;

    await db.transaction((txn) async {
      purchaseId = await txn.insert('purchases', purchase.toMap());

      for (final item in purchase.items) {
        final itemMap = item.copyWith(purchaseId: purchaseId).toMap();
        itemMap.remove('id');
        await txn.insert('purchase_items', itemMap);

        // Add purchased quantity to product stock
        if (item.productId != null && item.quantity > 0) {
          await txn.rawUpdate(
            'UPDATE products SET stock = COALESCE(stock, 0) + ? WHERE id = ?',
            [item.quantity, item.productId],
          );
          // Update current_buy_price to the latest purchase price
          await txn.rawUpdate(
            'UPDATE products SET current_buy_price = ? WHERE id = ?',
            [item.unitPrice, item.productId],
          );
        }
      }
    });

    return purchaseId;
  }

  /// Update an existing purchase and its items in a single transaction.
  /// Restores previous items' stock and applies new items' stock.
  Future<void> update(PurchaseModel purchase) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        'purchases',
        purchase.toMap(),
        where: 'id = ?',
        whereArgs: [purchase.id],
      );

      // Restore stock for previously saved items
      final oldItems = await txn.query(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [purchase.id],
      );
      for (final oldItem in oldItems) {
        final pid = oldItem['product_id'] as int?;
        final qty = (oldItem['quantity'] as num?)?.toDouble() ?? 0.0;
        if (pid != null && qty > 0) {
          await txn.rawUpdate(
            'UPDATE products SET stock = MAX(0, COALESCE(stock, 0) - ?) WHERE id = ?',
            [qty, pid],
          );
        }
      }

      // Delete old items and re-insert
      await txn.delete(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [purchase.id],
      );

      for (final item in purchase.items) {
        final itemMap = item.copyWith(purchaseId: purchase.id).toMap();
        itemMap.remove('id');
        await txn.insert('purchase_items', itemMap);

        // Add new items' stock
        if (item.productId != null && item.quantity > 0) {
          await txn.rawUpdate(
            'UPDATE products SET stock = COALESCE(stock, 0) + ? WHERE id = ?',
            [item.quantity, item.productId],
          );
          // Update current_buy_price to the latest purchase price
          await txn.rawUpdate(
            'UPDATE products SET current_buy_price = ? WHERE id = ?',
            [item.unitPrice, item.productId],
          );
        }
      }
    });
  }

  /// Delete a purchase by ID, restoring items' stock before deleting.
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      // Restore stock for items of the deleted purchase
      final oldItems = await txn.query(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [id],
      );
      for (final oldItem in oldItems) {
        final pid = oldItem['product_id'] as int?;
        final qty = (oldItem['quantity'] as num?)?.toDouble() ?? 0.0;
        if (pid != null && qty > 0) {
          await txn.rawUpdate(
            'UPDATE products SET stock = MAX(0, COALESCE(stock, 0) - ?) WHERE id = ?',
            [qty, pid],
          );
        }
      }

      // Delete items and purchase
      await txn.delete('purchase_items', where: 'purchase_id = ?', whereArgs: [id]);
      return await txn.delete('purchases', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Get the next purchase counter for generating purchase numbers.
  Future<int> nextCounter() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT MAX(id) as max_id FROM purchases');
    final maxId = result.first['max_id'] as int?;
    return (maxId ?? 0) + 1;
  }

  /// Get purchases that contain a specific product.
  Future<List<PurchaseModel>> getByProductId(int productId) async {
    final db = await _dbHelper.database;
    final purchaseIds = await db.rawQuery(
      'SELECT DISTINCT purchase_id FROM purchase_items WHERE product_id = ?',
      [productId],
    );
    if (purchaseIds.isEmpty) return [];

    final ids = purchaseIds.map((m) => m['purchase_id'] as int).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final maps = await db.rawQuery('''
      SELECT p.*, s.name as supplier_name
      FROM purchases p
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.id IN ($placeholders)
      ORDER BY p.date DESC
    ''', ids);

    // Also load items for context
    final itemMaps = await db.rawQuery(
      'SELECT * FROM purchase_items WHERE purchase_id IN ($placeholders) ORDER BY id ASC',
      ids,
    );
    final itemsByPurchase = <int, List<PurchaseItemModel>>{};
    for (final im in itemMaps) {
      final item = PurchaseItemModel.fromMap(im);
      if (item.purchaseId != null) {
        itemsByPurchase.putIfAbsent(item.purchaseId!, () => []).add(item);
      }
    }

    return maps.map((m) {
      final id = m['id'] as int?;
      return PurchaseModel.fromMap(m, items: id != null ? itemsByPurchase[id] : null);
    }).toList();
  }
}
