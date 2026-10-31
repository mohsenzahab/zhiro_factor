import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../core/extensions/number_extensions.dart';
import '../models/purchase_model.dart';
import '../models/purchase_item_model.dart';

/// Repository for Purchase CRUD with transactional item management and stock updates using Drift ORM.
class PurchaseRepository {
  final AppDatabase _db;

  PurchaseRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  /// Fetch all purchases with supplier name join, optionally filtered.
  Future<List<PurchaseModel>> getAll({
    String? supplierQuery,
    int? supplierId,
    int? productId,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    final q = _db.select(_db.purchases).join([
      leftOuterJoin(_db.suppliers, _db.suppliers.id.equalsExp(_db.purchases.supplierId)),
      if (productId != null)
        innerJoin(_db.purchaseItems, _db.purchaseItems.purchaseId.equalsExp(_db.purchases.id)),
    ]);

    if (supplierQuery != null && supplierQuery.isNotEmpty) {
      final enQuery = supplierQuery.toEnglishDigits();
      final p1 = '%$supplierQuery%';
      final p2 = '%$enQuery%';
      if (enQuery != supplierQuery) {
        q.where(_db.suppliers.name.like(p1) |
            _db.purchases.purchaseNumber.like(p1) |
            _db.purchases.purchaseNumber.like(p2));
      } else {
        q.where(_db.suppliers.name.like(p1) | _db.purchases.purchaseNumber.like(p1));
      }
    }

    if (status != null && status.isNotEmpty) {
      q.where(_db.purchases.status.equals(status));
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      q.where(_db.purchases.date.isBiggerOrEqualValue(dateFrom));
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      q.where(_db.purchases.date.isSmallerOrEqualValue(dateTo));
    }
    if (supplierId != null) {
      q.where(_db.purchases.supplierId.equals(supplierId));
    }
    if (productId != null) {
      q.where(_db.purchaseItems.productId.equals(productId));
    }

    q.orderBy([
      OrderingTerm.desc(_db.purchases.date),
      OrderingTerm.desc(_db.purchases.id),
    ]);

    final rows = await q.get();
    if (rows.isEmpty) return [];

    // Distinct purchases by ID
    final seenIds = <int>{};
    final purchasesList = <({PurchaseEntry p, String? supplierName})>[];
    for (final r in rows) {
      final p = r.readTable(_db.purchases);
      if (seenIds.add(p.id)) {
        final s = r.readTableOrNull(_db.suppliers);
        purchasesList.add((p: p, supplierName: s?.name));
      }
    }

    final purchaseIds = seenIds.toList();
    final itemRows = await (_db.select(_db.purchaseItems)
          ..where((i) => i.purchaseId.isIn(purchaseIds))
          ..orderBy([(i) => OrderingTerm.asc(i.id)]))
        .get();

    final itemsByPurchase = <int, List<PurchaseItemModel>>{};
    for (final im in itemRows) {
      final item = PurchaseItemModel(
        id: im.id,
        purchaseId: im.purchaseId,
        productId: im.productId,
        productName: im.productName,
        unitPrice: im.unitPrice,
        quantity: im.quantity,
        lineTotal: im.lineTotal,
      );
      itemsByPurchase.putIfAbsent(im.purchaseId, () => []).add(item);
    }

    return purchasesList.map((pair) {
      final p = pair.p;
      return PurchaseModel(
        id: p.id,
        purchaseNumber: p.purchaseNumber,
        supplierId: p.supplierId,
        supplierName: pair.supplierName,
        date: p.date,
        status: p.status ?? 'در انتظار پرداخت',
        totalAmount: p.totalAmount,
        shippingCost: p.shippingCost,
        extraCosts: p.extraCosts,
        totalNet: p.totalNet,
        notes: p.notes,
        items: itemsByPurchase[p.id] ?? const [],
      );
    }).toList();
  }

  /// Fetch a single purchase by ID with all its items.
  Future<PurchaseModel?> getById(int id) async {
    final q = _db.select(_db.purchases).join([
      leftOuterJoin(_db.suppliers, _db.suppliers.id.equalsExp(_db.purchases.supplierId)),
    ])..where(_db.purchases.id.equals(id));

    final rows = await q.get();
    if (rows.isEmpty) return null;

    final p = rows.first.readTable(_db.purchases);
    final s = rows.first.readTableOrNull(_db.suppliers);

    final itemRows = await (_db.select(_db.purchaseItems)
          ..where((i) => i.purchaseId.equals(id))
          ..orderBy([(i) => OrderingTerm.asc(i.id)]))
        .get();

    final items = itemRows
        .map((im) => PurchaseItemModel(
              id: im.id,
              purchaseId: im.purchaseId,
              productId: im.productId,
              productName: im.productName,
              unitPrice: im.unitPrice,
              quantity: im.quantity,
              lineTotal: im.lineTotal,
            ))
        .toList();

    return PurchaseModel(
      id: p.id,
      purchaseNumber: p.purchaseNumber,
      supplierId: p.supplierId,
      supplierName: s?.name,
      date: p.date,
      status: p.status ?? 'در انتظار پرداخت',
      totalAmount: p.totalAmount,
      shippingCost: p.shippingCost,
      extraCosts: p.extraCosts,
      totalNet: p.totalNet,
      notes: p.notes,
      items: items,
    );
  }

  /// Save a new purchase with items in a single transaction.
  /// Automatically adds purchased quantities to product stock and updates current_buy_price.
  Future<int> insert(PurchaseModel purchase) async {
    return await _db.transaction(() async {
      final purchaseId = await _db.into(_db.purchases).insert(
            PurchasesCompanion.insert(
              purchaseNumber: purchase.purchaseNumber.trim(),
              supplierId: Value(purchase.supplierId),
              date: purchase.date,
              status: Value(purchase.status),
              totalAmount: Value(purchase.totalAmount),
              shippingCost: Value(purchase.shippingCost),
              extraCosts: Value(purchase.extraCosts),
              totalNet: Value(purchase.totalNet),
              notes: Value(purchase.notes?.trim()),
            ),
          );

      for (final item in purchase.items) {
        await _db.into(_db.purchaseItems).insert(
              PurchaseItemsCompanion.insert(
                purchaseId: purchaseId,
                productId: Value(item.productId),
                productName: item.productName.trim(),
                unitPrice: item.unitPrice,
                quantity: Value(item.quantity),
                lineTotal: item.lineTotal,
              ),
            );

        if (item.productId != null && item.quantity > 0) {
          await _db.customUpdate(
            'UPDATE products SET stock = COALESCE(stock, 0) + ? WHERE id = ?',
            variables: [Variable.withReal(item.quantity), Variable.withInt(item.productId!)],
            updates: {_db.products},
          );

          if (item.unitPrice > 0) {
            final pRow = await (_db.select(_db.products)..where((tbl) => tbl.id.equals(item.productId!))).getSingleOrNull();
            if (pRow != null) {
              final oldEffective = (pRow.currentBuyPrice != null && pRow.currentBuyPrice! > 0)
                  ? pRow.currentBuyPrice!
                  : pRow.buyPrice;

              if (oldEffective > 0 && (item.unitPrice - oldEffective).abs() > 0.001) {
                await _db.into(_db.priceChangeHistory).insert(
                      PriceChangeHistoryCompanion.insert(
                        productId: item.productId!,
                        oldPrice: oldEffective,
                        newPrice: item.unitPrice,
                        changeAmount: item.unitPrice - oldEffective,
                        changeType: 'purchase',
                        changeSource: Value('فاکتور خرید ${purchase.purchaseNumber}'),
                        createdAt: DateTime.now().toIso8601String(),
                      ),
                    );
              }
            }
          }

          await (_db.update(_db.products)..where((tbl) => tbl.id.equals(item.productId!))).write(
            ProductsCompanion(
              currentBuyPrice: Value(item.unitPrice),
            ),
          );
        }
      }

      return purchaseId;
    });
  }

  /// Update an existing purchase and its items in a single transaction.
  /// Restores previous items' stock and applies new items' stock.
  Future<void> update(PurchaseModel purchase) async {
    if (purchase.id == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.purchases)..where((p) => p.id.equals(purchase.id!))).write(
            PurchasesCompanion(
              purchaseNumber: Value(purchase.purchaseNumber.trim()),
              supplierId: Value(purchase.supplierId),
              date: Value(purchase.date),
              status: Value(purchase.status),
              totalAmount: Value(purchase.totalAmount),
              shippingCost: Value(purchase.shippingCost),
              extraCosts: Value(purchase.extraCosts),
              totalNet: Value(purchase.totalNet),
              notes: Value(purchase.notes?.trim()),
            ),
          );

      // Restore stock for previously saved items
      final oldItems = await (_db.select(_db.purchaseItems)
            ..where((i) => i.purchaseId.equals(purchase.id!)))
          .get();

      for (final oldItem in oldItems) {
        if (oldItem.productId != null && oldItem.quantity > 0) {
          await _db.customUpdate(
            'UPDATE products SET stock = MAX(0, COALESCE(stock, 0) - ?) WHERE id = ?',
            variables: [Variable.withReal(oldItem.quantity), Variable.withInt(oldItem.productId!)],
            updates: {_db.products},
          );
        }
      }

      // Delete old items
      await (_db.delete(_db.purchaseItems)..where((i) => i.purchaseId.equals(purchase.id!))).go();

      // Insert new items
      for (final item in purchase.items) {
        await _db.into(_db.purchaseItems).insert(
              PurchaseItemsCompanion.insert(
                purchaseId: purchase.id!,
                productId: Value(item.productId),
                productName: item.productName.trim(),
                unitPrice: item.unitPrice,
                quantity: Value(item.quantity),
                lineTotal: item.lineTotal,
              ),
            );

        if (item.productId != null && item.quantity > 0) {
          await _db.customUpdate(
            'UPDATE products SET stock = COALESCE(stock, 0) + ? WHERE id = ?',
            variables: [Variable.withReal(item.quantity), Variable.withInt(item.productId!)],
            updates: {_db.products},
          );

          if (item.unitPrice > 0) {
            final pRow = await (_db.select(_db.products)..where((tbl) => tbl.id.equals(item.productId!))).getSingleOrNull();
            if (pRow != null) {
              final oldEffective = (pRow.currentBuyPrice != null && pRow.currentBuyPrice! > 0)
                  ? pRow.currentBuyPrice!
                  : pRow.buyPrice;

              if (oldEffective > 0 && (item.unitPrice - oldEffective).abs() > 0.001) {
                await _db.into(_db.priceChangeHistory).insert(
                      PriceChangeHistoryCompanion.insert(
                        productId: item.productId!,
                        oldPrice: oldEffective,
                        newPrice: item.unitPrice,
                        changeAmount: item.unitPrice - oldEffective,
                        changeType: 'purchase',
                        changeSource: Value('فاکتور خرید ${purchase.purchaseNumber}'),
                        createdAt: DateTime.now().toIso8601String(),
                      ),
                    );
              }
            }
          }

          await (_db.update(_db.products)..where((tbl) => tbl.id.equals(item.productId!))).write(
            ProductsCompanion(
              currentBuyPrice: Value(item.unitPrice),
            ),
          );
        }
      }
    });
  }

  /// Delete a purchase by ID, restoring items' stock before deleting.
  Future<int> delete(int id) async {
    return await _db.transaction(() async {
      final oldItems = await (_db.select(_db.purchaseItems)..where((i) => i.purchaseId.equals(id))).get();

      for (final oldItem in oldItems) {
        if (oldItem.productId != null && oldItem.quantity > 0) {
          await _db.customUpdate(
            'UPDATE products SET stock = MAX(0, COALESCE(stock, 0) - ?) WHERE id = ?',
            variables: [Variable.withReal(oldItem.quantity), Variable.withInt(oldItem.productId!)],
            updates: {_db.products},
          );
        }
      }

      await (_db.delete(_db.purchaseItems)..where((i) => i.purchaseId.equals(id))).go();
      return await (_db.delete(_db.purchases)..where((p) => p.id.equals(id))).go();
    });
  }

  /// Get the next purchase counter for generating purchase numbers.
  Future<int> nextCounter() async {
    final maxIdExp = _db.purchases.id.max();
    final query = _db.selectOnly(_db.purchases)..addColumns([maxIdExp]);
    final result = await query.getSingle();
    final maxId = result.read(maxIdExp);
    return (maxId ?? 0) + 1;
  }

  /// Get purchases that contain a specific product.
  Future<List<PurchaseModel>> getByProductId(int productId) async {
    final purchaseIdsQuery = _db.selectOnly(_db.purchaseItems, distinct: true)
      ..addColumns([_db.purchaseItems.purchaseId])
      ..where(_db.purchaseItems.productId.equals(productId));

    final purchaseIdsRows = await purchaseIdsQuery.get();
    final ids = purchaseIdsRows.map((r) => r.read(_db.purchaseItems.purchaseId)!).toList();
    if (ids.isEmpty) return [];

    final q = _db.select(_db.purchases).join([
      leftOuterJoin(_db.suppliers, _db.suppliers.id.equalsExp(_db.purchases.supplierId)),
    ])
      ..where(_db.purchases.id.isIn(ids))
      ..orderBy([OrderingTerm.desc(_db.purchases.date)]);

    final rows = await q.get();

    final itemRows = await (_db.select(_db.purchaseItems)
          ..where((i) => i.purchaseId.isIn(ids))
          ..orderBy([(i) => OrderingTerm.asc(i.id)]))
        .get();

    final itemsByPurchase = <int, List<PurchaseItemModel>>{};
    for (final im in itemRows) {
      final item = PurchaseItemModel(
        id: im.id,
        purchaseId: im.purchaseId,
        productId: im.productId,
        productName: im.productName,
        unitPrice: im.unitPrice,
        quantity: im.quantity,
        lineTotal: im.lineTotal,
      );
      itemsByPurchase.putIfAbsent(im.purchaseId, () => []).add(item);
    }

    return rows.map((r) {
      final p = r.readTable(_db.purchases);
      final s = r.readTableOrNull(_db.suppliers);
      return PurchaseModel(
        id: p.id,
        purchaseNumber: p.purchaseNumber,
        supplierId: p.supplierId,
        supplierName: s?.name,
        date: p.date,
        status: p.status ?? 'در انتظار پرداخت',
        totalAmount: p.totalAmount,
        shippingCost: p.shippingCost,
        extraCosts: p.extraCosts,
        totalNet: p.totalNet,
        notes: p.notes,
        items: itemsByPurchase[p.id] ?? const [],
      );
    }).toList();
  }
}
