import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../core/extensions/number_extensions.dart';
import '../models/product_model.dart';

/// Repository for Product CRUD operations using Drift ORM.
class ProductRepository {
  final AppDatabase _db;

  ProductRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  /// Fetch all products with sold quantity joined, optionally filtered by search query.
  /// Resolves the supplier title (from products.supplier, suppliers table, or latest purchase).
  Future<List<ProductModel>> getAll({String? query}) async {
    const baseSql = '''
      SELECT 
        p.*, 
        COALESCE(s.total_sold, 0.0) as total_sold,
        COALESCE(sup_direct.name, NULLIF(p.supplier, ''), latest_purchase.supplier_name) as resolved_supplier
      FROM products p
      LEFT JOIN suppliers sup_direct ON (
        (p.supplier GLOB '[0-9]*' AND CAST(p.supplier AS INTEGER) = sup_direct.id)
        OR p.supplier = sup_direct.name
      )
      LEFT JOIN (
        SELECT 
          pi.product_id,
          sup.name as supplier_name,
          ROW_NUMBER() OVER (PARTITION BY pi.product_id ORDER BY pu.date DESC, pu.id DESC) as rn
        FROM purchase_items pi
        JOIN purchases pu ON pi.purchase_id = pu.id
        JOIN suppliers sup ON pu.supplier_id = sup.id
      ) latest_purchase ON p.id = latest_purchase.product_id AND latest_purchase.rn = 1
      LEFT JOIN (
        SELECT product_id, SUM(quantity) as total_sold
        FROM invoice_items
        WHERE product_id IS NOT NULL
        GROUP BY product_id
      ) s ON p.id = s.product_id
    ''';

    String sql = 'SELECT * FROM ($baseSql) AS p_sub';
    final variables = <Variable>[];

    if (query != null && query.isNotEmpty) {
      final clean = query.trim();
      final enQuery = clean.toEnglishDigits();
      final p1 = '%$clean%';
      final p2 = '%$enQuery%';

      if (enQuery != clean) {
        sql += ' WHERE name LIKE ? OR code LIKE ? OR code LIKE ? OR resolved_supplier LIKE ?';
        variables.addAll([
          Variable.withString(p1),
          Variable.withString(p1),
          Variable.withString(p2),
          Variable.withString(p1),
        ]);
      } else {
        sql += ' WHERE name LIKE ? OR code LIKE ? OR resolved_supplier LIKE ?';
        variables.addAll([
          Variable.withString(p1),
          Variable.withString(p1),
          Variable.withString(p1),
        ]);
      }
    }

    sql += ' ORDER BY name ASC';

    final rows = await _db.customSelect(sql, variables: variables, readsFrom: {
      _db.products,
      _db.suppliers,
      _db.purchases,
      _db.purchaseItems,
      _db.invoiceItems,
    }).get();

    return rows.map((r) => ProductModel.fromMap(r.data)).toList();
  }

  /// Fetch a single product by ID with sold quantity joined.
  Future<ProductModel?> getById(int id) async {
    const sql = '''
      SELECT 
        p.*, 
        COALESCE(s.total_sold, 0.0) as total_sold,
        COALESCE(sup_direct.name, NULLIF(p.supplier, ''), latest_purchase.supplier_name) as resolved_supplier
      FROM products p
      LEFT JOIN suppliers sup_direct ON (
        (p.supplier GLOB '[0-9]*' AND CAST(p.supplier AS INTEGER) = sup_direct.id)
        OR p.supplier = sup_direct.name
      )
      LEFT JOIN (
        SELECT 
          pi.product_id,
          sup.name as supplier_name,
          ROW_NUMBER() OVER (PARTITION BY pi.product_id ORDER BY pu.date DESC, pu.id DESC) as rn
        FROM purchase_items pi
        JOIN purchases pu ON pi.purchase_id = pu.id
        JOIN suppliers sup ON pu.supplier_id = sup.id
      ) latest_purchase ON p.id = latest_purchase.product_id AND latest_purchase.rn = 1
      LEFT JOIN (
        SELECT product_id, SUM(quantity) as total_sold
        FROM invoice_items
        WHERE product_id = ?
        GROUP BY product_id
      ) s ON p.id = s.product_id
      WHERE p.id = ?
    ''';

    final rows = await _db.customSelect(sql, variables: [
      Variable.withInt(id),
      Variable.withInt(id),
    ], readsFrom: {
      _db.products,
      _db.suppliers,
      _db.purchases,
      _db.purchaseItems,
      _db.invoiceItems,
    }).get();

    if (rows.isEmpty) return null;
    return ProductModel.fromMap(rows.first.data);
  }

  /// Insert a new product. Returns the new row ID.
  Future<int> insert(ProductModel product) async {
    final cleanCode = (product.code != null && product.code!.trim().isNotEmpty) ? product.code!.trim() : null;
    final cleanCategory = (product.category != null && product.category!.trim().isNotEmpty) ? product.category!.trim() : null;
    final cleanSupplier = (product.supplier != null && product.supplier!.trim().isNotEmpty) ? product.supplier!.trim() : null;

    return await _db.into(_db.products).insert(
          ProductsCompanion.insert(
            code: Value(cleanCode),
            name: product.name.trim(),
            category: Value(cleanCategory),
            buyPrice: product.buyPrice,
            currentBuyPrice: Value(product.currentBuyPrice),
            sellPrice: Value(product.sellPrice),
            unit: product.unit.trim(),
            stock: Value(product.stock),
            isTemporary: Value(product.isTemporary),
            createdAt: Value(product.createdAt ?? DateTime.now().toIso8601String()),
            buyDate: Value(product.buyDate),
            supplier: Value(cleanSupplier),
          ),
        );
  }

  /// Update an existing product. Returns rows affected.
  Future<int> update(ProductModel product) async {
    if (product.id == null) return 0;

    // Detect and log buy price modification in price_change_history
    final existingRow = await (_db.select(_db.products)..where((tbl) => tbl.id.equals(product.id!))).getSingleOrNull();
    if (existingRow != null) {
      final oldEffective = (existingRow.currentBuyPrice != null && existingRow.currentBuyPrice! > 0)
          ? existingRow.currentBuyPrice!
          : existingRow.buyPrice;
      final newEffective = product.effectiveBuyPrice;

      if (oldEffective > 0 && (newEffective - oldEffective).abs() > 0.001) {
        await _db.into(_db.priceChangeHistory).insert(
              PriceChangeHistoryCompanion.insert(
                productId: product.id!,
                oldPrice: oldEffective,
                newPrice: newEffective,
                changeAmount: newEffective - oldEffective,
                changeType: 'manual',
                changeSource: const Value('ویرایش دستی'),
                createdAt: DateTime.now().toIso8601String(),
              ),
            );
      }
    }

    final cleanCode = (product.code != null && product.code!.trim().isNotEmpty) ? product.code!.trim() : null;
    final cleanCategory = (product.category != null && product.category!.trim().isNotEmpty) ? product.category!.trim() : null;
    final cleanSupplier = (product.supplier != null && product.supplier!.trim().isNotEmpty) ? product.supplier!.trim() : null;

    return await (_db.update(_db.products)..where((tbl) => tbl.id.equals(product.id!))).write(
          ProductsCompanion(
            code: Value(cleanCode),
            name: Value(product.name.trim()),
            category: Value(cleanCategory),
            buyPrice: Value(product.buyPrice),
            currentBuyPrice: Value(product.currentBuyPrice),
            sellPrice: Value(product.sellPrice),
            unit: Value(product.unit.trim()),
            stock: Value(product.stock),
            isTemporary: Value(product.isTemporary),
            buyDate: Value(product.buyDate),
            supplier: Value(cleanSupplier),
          ),
        );
  }

  /// Check if a product code is already in use by another product.
  Future<bool> isCodeTaken(String code, {int? excludeId}) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return false;

    final q = _db.select(_db.products)..where((p) => p.code.equals(trimmed));
    if (excludeId != null) {
      q.where((p) => p.id.equals(excludeId).not());
    }

    final rows = await q.get();
    return rows.isNotEmpty;
  }

  /// Delete a product by ID. Safely sets invoice_items.product_id to NULL first.
  Future<int> delete(int id) async {
    return await _db.transaction(() async {
      await (_db.update(_db.invoiceItems)..where((i) => i.productId.equals(id))).write(
            const InvoiceItemsCompanion(productId: Value(null)),
          );
      await (_db.update(_db.purchaseItems)..where((i) => i.productId.equals(id))).write(
            const PurchaseItemsCompanion(productId: Value(null)),
          );
      await (_db.delete(_db.priceChangeHistory)..where((h) => h.productId.equals(id))).go();
      return await (_db.delete(_db.products)..where((p) => p.id.equals(id))).go();
    });
  }

  /// Delete multiple products by IDs safely within a transaction.
  Future<int> deleteMany(List<int> ids) async {
    if (ids.isEmpty) return 0;

    return await _db.transaction(() async {
      await (_db.update(_db.invoiceItems)..where((i) => i.productId.isIn(ids))).write(
            const InvoiceItemsCompanion(productId: Value(null)),
          );
      await (_db.update(_db.purchaseItems)..where((i) => i.productId.isIn(ids))).write(
            const PurchaseItemsCompanion(productId: Value(null)),
          );
      await (_db.delete(_db.priceChangeHistory)..where((h) => h.productId.isIn(ids))).go();
      return await (_db.delete(_db.products)..where((p) => p.id.isIn(ids))).go();
    });
  }

  /// Move multiple products to a new category (or uncategorized if null/empty).
  Future<int> updateCategoryForIds(List<int> ids, String? category) async {
    if (ids.isEmpty) return 0;
    final cleanCat = (category != null && category.trim().isNotEmpty) ? category.trim() : null;

    return await (_db.update(_db.products)..where((p) => p.id.isIn(ids))).write(
          ProductsCompanion(category: Value(cleanCat)),
        );
  }

  /// Adjust stock for a product (positive = add, negative = subtract).
  /// Preserves null (infinite) stock.
  Future<void> adjustStock(int productId, double delta) async {
    await _db.customUpdate(
      'UPDATE products SET stock = stock + ? WHERE id = ? AND stock IS NOT NULL',
      variables: [Variable.withReal(delta), Variable.withInt(productId)],
      updates: {_db.products},
    );
  }

  /// Get the next available product code.
  Future<String> nextCode() async {
    final row = await (_db.select(_db.products)
          ..where((p) => p.code.like('P%'))
          ..orderBy([(p) => OrderingTerm.desc(p.code)])
          ..limit(1))
        .getSingleOrNull();

    if (row == null || row.code == null) return 'P001';
    final lastCode = row.code!.toEnglishDigits();
    final num = int.tryParse(lastCode.substring(1)) ?? 0;
    return 'P${(num + 1).toString().padLeft(3, '0')}';
  }

  /// Get all distinct non-null categories.
  Future<List<String>> getDistinctCategories() async {
    final q = _db.selectOnly(_db.products, distinct: true)
      ..addColumns([_db.products.category])
      ..where(_db.products.category.isNotNull() & _db.products.category.equals('').not())
      ..orderBy([OrderingTerm.asc(_db.products.category)]);

    final rows = await q.get();
    return rows.map((r) => r.read(_db.products.category)!).toList();
  }

  /// Get all distinct non-null suppliers across products and suppliers table.
  Future<List<String>> getDistinctSuppliers() async {
    final rows = await _db.customSelect('''
      SELECT DISTINCT name FROM (
        SELECT supplier AS name FROM products WHERE supplier IS NOT NULL AND supplier != ''
        UNION
        SELECT name FROM suppliers WHERE name IS NOT NULL AND name != ''
      ) ORDER BY name ASC
    ''', readsFrom: {_db.products, _db.suppliers}).get();

    return rows.map((r) => r.read<String>('name')).toList();
  }

  /// Bulk import products. Returns the count of successfully imported rows.
  Future<int> importProducts(List<ProductModel> products) async {
    int count = 0;
    await _db.batch((batch) {
      for (final p in products) {
        final cleanCode = (p.code != null && p.code!.trim().isNotEmpty) ? p.code!.trim() : null;
        final cleanCat = (p.category != null && p.category!.trim().isNotEmpty) ? p.category!.trim() : null;
        final cleanSup = (p.supplier != null && p.supplier!.trim().isNotEmpty) ? p.supplier!.trim() : null;

        batch.insert(
          _db.products,
          ProductsCompanion.insert(
            code: Value(cleanCode),
            name: p.name.trim(),
            category: Value(cleanCat),
            buyPrice: p.buyPrice,
            currentBuyPrice: Value(p.currentBuyPrice),
            sellPrice: Value(p.sellPrice),
            unit: p.unit.trim(),
            stock: Value(p.stock),
            isTemporary: Value(p.isTemporary),
            createdAt: Value(p.createdAt ?? DateTime.now().toIso8601String()),
            buyDate: Value(p.buyDate),
            supplier: Value(cleanSup),
          ),
        );
        count++;
      }
    });
    return count;
  }

  /// Apply a profit percentage to products' sell prices.
  Future<int> bulkApplyProfitMargin(
    double percentage, {
    String? category,
    List<int>? productIds,
  }) async {
    const basePriceExpr = '(CASE WHEN current_buy_price IS NOT NULL AND current_buy_price > 0 THEN current_buy_price ELSE buy_price END)';
    const roundedExpr = '(CASE WHEN $basePriceExpr <= 0 THEN 0 ELSE MAX(5000, ROUND(($basePriceExpr * (1 + ? / 100.0)) / 5000.0) * 5000) END)';

    if (productIds != null && productIds.isNotEmpty) {
      final placeholders = List.filled(productIds.length, '?').join(',');
      return await _db.customUpdate(
        'UPDATE products SET sell_price = $roundedExpr WHERE id IN ($placeholders)',
        variables: [Variable.withReal(percentage), ...productIds.map((id) => Variable.withInt(id))],
        updates: {_db.products},
      );
    }

    if (category == null) {
      return await _db.customUpdate(
        'UPDATE products SET sell_price = $roundedExpr',
        variables: [Variable.withReal(percentage)],
        updates: {_db.products},
      );
    } else if (category == '__uncategorized__') {
      return await _db.customUpdate(
        "UPDATE products SET sell_price = $roundedExpr WHERE category IS NULL OR category = ''",
        variables: [Variable.withReal(percentage)],
        updates: {_db.products},
      );
    } else {
      return await _db.customUpdate(
        'UPDATE products SET sell_price = $roundedExpr WHERE category = ?',
        variables: [Variable.withReal(percentage), Variable.withString(category)],
        updates: {_db.products},
      );
    }
  }

  /// Batch apply a price adjustment percentage (positive or negative) to products.
  Future<int> bulkApplyPriceAdjustment(
    double percentage, {
    String? category,
    List<int>? productIds,
  }) async {
    final q = _db.select(_db.products);

    if (productIds != null && productIds.isNotEmpty) {
      q.where((p) => p.id.isIn(productIds));
    } else if (category == '__uncategorized__') {
      q.where((p) => p.category.isNull() | p.category.equals(''));
    } else if (category != null) {
      q.where((p) => p.category.equals(category));
    }

    final rows = await q.get();
    if (rows.isEmpty) return 0;

    int count = 0;
    await _db.batch((batch) {
      for (final row in rows) {
        final id = row.id;
        final buyPrice = row.buyPrice;
        final currentBuyPrice = row.currentBuyPrice;
        final sellPrice = row.sellPrice;

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
          _db.products,
          ProductsCompanion(
            currentBuyPrice: Value(newCurrentBuy),
            sellPrice: Value(newSellPrice),
          ),
          where: (p) => p.id.equals(id),
        );

        if ((newCurrentBuy - baseBuyPrice).abs() > 0.001) {
          final changeAmt = newCurrentBuy - baseBuyPrice;
          final source = percentage >= 0
              ? 'افزایش ${percentage.formatted}٪ گروهی'
              : 'کاهش ${percentage.abs().formatted}٪ گروهی';
          batch.insert(
            _db.priceChangeHistory,
            PriceChangeHistoryCompanion.insert(
              productId: id,
              oldPrice: baseBuyPrice,
              newPrice: newCurrentBuy,
              changeAmount: changeAmt,
              changeType: 'batch_adjustment',
              changeSource: Value(source),
              createdAt: DateTime.now().toIso8601String(),
            ),
          );
        }

        count++;
      }
    });

    return count;
  }

  /// Batch fetch product detail info including stock, total sold,
  /// current buy price, and FIFO initial buy price of oldest available inventory.
  Future<Map<int, ProductDetailInfo>> getProductsDetailInfo(List<int> productIds) async {
    if (productIds.isEmpty) return {};

    // 1. Fetch product master rows
    final productRows = await (_db.select(_db.products)..where((p) => p.id.isIn(productIds))).get();

    // 2. Fetch total sold per product across all invoices
    final soldQuery = _db.selectOnly(_db.invoiceItems)
      ..addColumns([_db.invoiceItems.productId, _db.invoiceItems.quantity.sum()])
      ..where(_db.invoiceItems.productId.isIn(productIds))
      ..groupBy([_db.invoiceItems.productId]);

    final soldRows = await soldQuery.get();
    final soldMap = <int, double>{};
    for (final r in soldRows) {
      final pid = r.read(_db.invoiceItems.productId);
      if (pid != null) {
        soldMap[pid] = r.read(_db.invoiceItems.quantity.sum()) ?? 0.0;
      }
    }

    // 3. Fetch purchase history in chronological order (FIFO)
    final purchaseQuery = _db.select(_db.purchaseItems).join([
      innerJoin(_db.purchases, _db.purchases.id.equalsExp(_db.purchaseItems.purchaseId)),
    ])
      ..where(_db.purchaseItems.productId.isIn(productIds))
      ..orderBy([
        OrderingTerm.asc(_db.purchases.date),
        OrderingTerm.asc(_db.purchases.id),
      ]);

    final purchaseRows = await purchaseQuery.get();
    final purchasesByProduct = <int, List<({double quantity, double unitPrice})>>{};
    for (final r in purchaseRows) {
      final pi = r.readTable(_db.purchaseItems);
      if (pi.productId != null) {
        purchasesByProduct.putIfAbsent(pi.productId!, () => []).add((
          quantity: pi.quantity,
          unitPrice: pi.unitPrice,
        ));
      }
    }

    final result = <int, ProductDetailInfo>{};
    for (final row in productRows) {
      final pid = row.id;
      final category = row.category;
      final stock = row.stock;
      final baseBuy = row.buyPrice;
      final currentBuyRaw = row.currentBuyPrice;
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

        if (initialStock > 0) {
          if (soldRemaining < initialStock) {
            initialBuy = baseBuy;
            batchFound = true;
          } else {
            soldRemaining -= initialStock;
          }
        }

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
