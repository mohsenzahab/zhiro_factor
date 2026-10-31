import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../core/extensions/number_extensions.dart';
import '../models/price_change_model.dart';

/// Repository for managing price change history records using Drift ORM.
class PriceChangeRepository {
  final AppDatabase _db;

  PriceChangeRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  /// Insert a single price change history record. Returns the new row ID.
  Future<int> insert(PriceChangeModel model) async {
    return await _db.into(_db.priceChangeHistory).insert(
          PriceChangeHistoryCompanion.insert(
            productId: model.productId,
            oldPrice: model.oldPrice,
            newPrice: model.newPrice,
            changeAmount: model.changeAmount,
            changeType: model.changeType,
            changeSource: Value(model.changeSource),
            createdAt: model.createdAt,
          ),
        );
  }

  /// Bulk insert price change history records in a batch.
  Future<void> insertBatch(List<PriceChangeModel> models) async {
    if (models.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAll(
        _db.priceChangeHistory,
        models.map((model) => PriceChangeHistoryCompanion.insert(
              productId: model.productId,
              oldPrice: model.oldPrice,
              newPrice: model.newPrice,
              changeAmount: model.changeAmount,
              changeType: model.changeType,
              changeSource: Value(model.changeSource),
              createdAt: model.createdAt,
            )),
      );
    });
  }

  /// Fetch price change records with product details, optionally filtered.
  Future<List<PriceChangeModel>> getAll({
    int? productId,
    String? query,
    String? changeType,
    String? dateFrom,
    String? dateTo,
  }) async {
    final q = _db.select(_db.priceChangeHistory).join([
      leftOuterJoin(_db.products, _db.products.id.equalsExp(_db.priceChangeHistory.productId)),
    ]);

    if (productId != null) {
      q.where(_db.priceChangeHistory.productId.equals(productId));
    }

    if (query != null && query.trim().isNotEmpty) {
      final clean = query.trim();
      final enClean = clean.toEnglishDigits();
      final p1 = '%$clean%';
      final p2 = '%$enClean%';

      if (enClean != clean) {
        q.where(_db.products.name.like(p1) |
            _db.products.code.like(p1) |
            _db.products.code.like(p2));
      } else {
        q.where(_db.products.name.like(p1) | _db.products.code.like(p1));
      }
    }

    if (changeType != null && changeType.isNotEmpty && changeType != 'all') {
      q.where(_db.priceChangeHistory.changeType.equals(changeType));
    }

    if (dateFrom != null && dateFrom.isNotEmpty) {
      q.where(_db.priceChangeHistory.createdAt.isBiggerOrEqualValue(dateFrom));
    }

    if (dateTo != null && dateTo.isNotEmpty) {
      q.where(_db.priceChangeHistory.createdAt.isSmallerOrEqualValue(dateTo));
    }

    q.orderBy([
      OrderingTerm.desc(_db.priceChangeHistory.createdAt),
      OrderingTerm.desc(_db.priceChangeHistory.id),
    ]);

    final rows = await q.get();

    return rows.map((row) {
      final h = row.readTable(_db.priceChangeHistory);
      final p = row.readTableOrNull(_db.products);

      return PriceChangeModel(
        id: h.id,
        productId: h.productId,
        productName: p?.name,
        productCode: p?.code,
        category: p?.category,
        oldPrice: h.oldPrice,
        newPrice: h.newPrice,
        changeAmount: h.changeAmount,
        changeType: h.changeType,
        changeSource: h.changeSource,
        createdAt: h.createdAt,
      );
    }).toList();
  }

  /// Fetch the latest price change record for a specific product.
  Future<PriceChangeModel?> getLastChangeForProduct(int productId) async {
    final q = _db.select(_db.priceChangeHistory).join([
      leftOuterJoin(_db.products, _db.products.id.equalsExp(_db.priceChangeHistory.productId)),
    ])
      ..where(_db.priceChangeHistory.productId.equals(productId))
      ..orderBy([
        OrderingTerm.desc(_db.priceChangeHistory.createdAt),
        OrderingTerm.desc(_db.priceChangeHistory.id),
      ])
      ..limit(1);

    final rows = await q.get();
    if (rows.isEmpty) return null;

    final row = rows.first;
    final h = row.readTable(_db.priceChangeHistory);
    final p = row.readTableOrNull(_db.products);

    return PriceChangeModel(
      id: h.id,
      productId: h.productId,
      productName: p?.name,
      productCode: p?.code,
      category: p?.category,
      oldPrice: h.oldPrice,
      newPrice: h.newPrice,
      changeAmount: h.changeAmount,
      changeType: h.changeType,
      changeSource: h.changeSource,
      createdAt: h.createdAt,
    );
  }

  /// Delete all price change history for a product.
  Future<int> deleteByProductId(int productId) async {
    return await (_db.delete(_db.priceChangeHistory)
          ..where((h) => h.productId.equals(productId)))
        .go();
  }

  /// Delete a specific price change record.
  Future<int> delete(int id) async {
    return await (_db.delete(_db.priceChangeHistory)..where((h) => h.id.equals(id))).go();
  }
}
