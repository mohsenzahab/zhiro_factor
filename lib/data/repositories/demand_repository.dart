import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../core/extensions/number_extensions.dart';
import '../models/demand_model.dart';
import '../models/product_model.dart';
import 'product_repository.dart';

/// Repository for managing Demands and customer request history using Drift ORM.
class DemandRepository {
  final AppDatabase _db;
  final ProductRepository _productRepo;

  DemandRepository({AppDatabase? db, ProductRepository? productRepo})
      : _db = db ?? AppDatabase.instance,
        _productRepo = productRepo ?? ProductRepository(db: db);

  /// Fetch all demands filtered by status, category, search query and sorted.
  Future<List<DemandModel>> getAll({
    String? status,
    String? category,
    String? query,
    String sortBy = 'demandCount', // 'demandCount', 'newest', 'profit', 'capital', 'title'
  }) async {
    final q = _db.select(_db.demands);

    if (status != null && status.isNotEmpty) {
      q.where((d) => d.status.equals(status));
    }

    if (category != null && category.isNotEmpty) {
      if (category == 'بدون دسته‌بندی') {
        q.where((d) => d.category.isNull() | d.category.equals(''));
      } else {
        q.where((d) => d.category.equals(category));
      }
    }

    if (query != null && query.trim().isNotEmpty) {
      final clean = query.trim();
      final enClean = clean.toEnglishDigits();
      final p1 = '%$clean%';
      final p2 = '%$enClean%';

      if (enClean != clean) {
        q.where((d) =>
            d.title.like(p1) |
            d.notes.like(p1) |
            d.category.like(p1) |
            d.title.like(p2));
      } else {
        q.where((d) => d.title.like(p1) | d.notes.like(p1) | d.category.like(p1));
      }
    }

    q.orderBy([(d) => OrderingTerm.desc(d.id)]);
    final demandRows = await q.get();
    if (demandRows.isEmpty) return [];

    final demandIds = demandRows.map((r) => r.id).toList();

    final requestRows = await (_db.select(_db.demandRequests)
          ..where((r) => r.demandId.isIn(demandIds))
          ..orderBy([(r) => OrderingTerm.asc(r.requestDate)]))
        .get();

    final requestsByDemand = <int, List<String>>{};
    for (final r in requestRows) {
      requestsByDemand.putIfAbsent(r.demandId, () => []).add(r.requestDate);
    }

    final demands = demandRows.map((row) {
      final requestDates = requestsByDemand[row.id] ?? [];
      return DemandModel(
        id: row.id,
        title: row.title,
        category: row.category,
        buyPrice: row.buyPrice,
        sellPrice: row.sellPrice,
        status: row.status,
        targetQuantity: row.targetQuantity,
        notes: row.notes,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        requestDates: requestDates,
      );
    }).toList();

    // Apply in-memory sorting
    switch (sortBy) {
      case 'demandCount':
        demands.sort((a, b) {
          final cmp = b.requestCount.compareTo(a.requestCount);
          if (cmp != 0) return cmp;
          return (b.id ?? 0).compareTo(a.id ?? 0);
        });
        break;
      case 'newest':
        demands.sort((a, b) {
          final dateA = a.latestRequestDate ?? a.createdAt;
          final dateB = b.latestRequestDate ?? b.createdAt;
          return dateB.compareTo(dateA);
        });
        break;
      case 'profit':
        demands.sort((a, b) {
          final profitA = a.totalProjectedProfit ?? -1.0;
          final profitB = b.totalProjectedProfit ?? -1.0;
          return profitB.compareTo(profitA);
        });
        break;
      case 'capital':
        demands.sort((a, b) {
          return b.requiredCapital.compareTo(a.requiredCapital);
        });
        break;
      case 'title':
        demands.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    return demands;
  }

  /// Get single demand with all its request dates.
  Future<DemandModel?> getById(int id) async {
    final row = await (_db.select(_db.demands)..where((d) => d.id.equals(id))).getSingleOrNull();
    if (row == null) return null;

    final requestRows = await (_db.select(_db.demandRequests)
          ..where((r) => r.demandId.equals(id))
          ..orderBy([(r) => OrderingTerm.asc(r.requestDate)]))
        .get();

    final requestDates = requestRows.map((r) => r.requestDate).toList();

    return DemandModel(
      id: row.id,
      title: row.title,
      category: row.category,
      buyPrice: row.buyPrice,
      sellPrice: row.sellPrice,
      status: row.status,
      targetQuantity: row.targetQuantity,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      requestDates: requestDates,
    );
  }

  /// Insert a new demand and record its initial request dates.
  Future<int> insert(DemandModel demand, {int initialCount = 1, String? initialDate}) async {
    final now = DateTime.now().toIso8601String();
    final date = initialDate ?? now;

    return await _db.transaction(() async {
      final demandId = await _db.into(_db.demands).insert(
            DemandsCompanion.insert(
              title: demand.title.trim(),
              category: Value(demand.category?.trim()),
              buyPrice: Value(demand.buyPrice),
              sellPrice: Value(demand.sellPrice),
              status: Value(demand.status),
              targetQuantity: Value(demand.targetQuantity),
              notes: Value(demand.notes?.trim()),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final count = initialCount.clamp(1, 1000);
      for (int i = 0; i < count; i++) {
        await _db.into(_db.demandRequests).insert(
              DemandRequestsCompanion.insert(
                demandId: demandId,
                requestDate: date,
                note: const Value('ثبت اولیه'),
              ),
            );
      }

      return demandId;
    });
  }

  /// Update demand properties.
  Future<int> update(DemandModel demand) async {
    if (demand.id == null) return 0;
    final now = DateTime.now().toIso8601String();

    return await (_db.update(_db.demands)..where((d) => d.id.equals(demand.id!))).write(
          DemandsCompanion(
            title: Value(demand.title.trim()),
            category: Value(demand.category?.trim()),
            buyPrice: Value(demand.buyPrice),
            sellPrice: Value(demand.sellPrice),
            status: Value(demand.status),
            targetQuantity: Value(demand.targetQuantity),
            notes: Value(demand.notes?.trim()),
            updatedAt: Value(now),
          ),
        );
  }

  /// Update status of a demand.
  Future<int> updateStatus(int demandId, String newStatus) async {
    final now = DateTime.now().toIso8601String();
    return await (_db.update(_db.demands)..where((d) => d.id.equals(demandId))).write(
          DemandsCompanion(
            status: Value(newStatus),
            updatedAt: Value(now),
          ),
        );
  }

  /// Increment customer requests count by adding a timestamped request event (+ button).
  Future<void> addRequest(int demandId, {String? requestDate, String? note}) async {
    final date = requestDate ?? DateTime.now().toIso8601String();

    await _db.transaction(() async {
      await _db.into(_db.demandRequests).insert(
            DemandRequestsCompanion.insert(
              demandId: demandId,
              requestDate: date,
              note: Value(note),
            ),
          );
      await (_db.update(_db.demands)..where((d) => d.id.equals(demandId))).write(
            DemandsCompanion(
              updatedAt: Value(date),
            ),
          );
    });
  }

  /// Decrement customer requests count by removing the most recent request event (- button).
  /// Ensures at least 1 request record remains (returns false if count <= 1).
  Future<bool> removeLatestRequest(int demandId) async {
    return await _db.transaction(() async {
      final rows = await (_db.select(_db.demandRequests)
            ..where((r) => r.demandId.equals(demandId))
            ..orderBy([
              (tbl) => OrderingTerm.desc(tbl.requestDate),
              (tbl) => OrderingTerm.desc(tbl.id),
            ]))
          .get();

      if (rows.length <= 1) {
        return false;
      }

      final latestId = rows.first.id;
      await (_db.delete(_db.demandRequests)..where((r) => r.id.equals(latestId))).go();
      await (_db.update(_db.demands)..where((d) => d.id.equals(demandId))).write(
            DemandsCompanion(
              updatedAt: Value(DateTime.now().toIso8601String()),
            ),
          );
      return true;
    });
  }

  /// Delete a demand and its associated requests.
  Future<int> delete(int id) async {
    return await _db.transaction(() async {
      await (_db.delete(_db.demandRequests)..where((r) => r.demandId.equals(id))).go();
      return await (_db.delete(_db.demands)..where((d) => d.id.equals(id))).go();
    });
  }

  /// Convert a procured demand directly into a Product in the products inventory.
  Future<int> convertToProduct(DemandModel demand) async {
    final product = ProductModel(
      name: demand.title,
      category: demand.category,
      buyPrice: demand.buyPrice ?? 0.0,
      sellPrice: demand.sellPrice,
      stock: demand.targetQuantity,
      unit: 'عدد',
    );

    final productId = await _productRepo.insert(product);
    if (demand.id != null) {
      await updateStatus(demand.id!, DemandModel.statusProcured);
    }
    return productId;
  }
}
