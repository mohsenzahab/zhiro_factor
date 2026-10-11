import '../../core/database/database_helper.dart';
import '../../core/extensions/number_extensions.dart';
import '../models/demand_model.dart';
import '../models/product_model.dart';
import 'product_repository.dart';

/// Repository for managing Demands and customer request history.
class DemandRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ProductRepository _productRepo;

  DemandRepository({ProductRepository? productRepo})
      : _productRepo = productRepo ?? ProductRepository();

  /// Fetch all demands filtered by status, category, search query and sorted.
  Future<List<DemandModel>> getAll({
    String? status,
    String? category,
    String? query,
    String sortBy = 'demandCount', // 'demandCount', 'newest', 'profit', 'capital', 'title'
  }) async {
    final db = await _dbHelper.database;

    final whereClauses = <String>[];
    final args = <dynamic>[];

    if (status != null && status.isNotEmpty) {
      whereClauses.add('d.status = ?');
      args.add(status);
    }

    if (category != null && category.isNotEmpty) {
      if (category == 'بدون دسته‌بندی') {
        whereClauses.add('(d.category IS NULL OR d.category = "")');
      } else {
        whereClauses.add('d.category = ?');
        args.add(category);
      }
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim();
      final enQuery = q.toEnglishDigits();
      if (enQuery != q) {
        whereClauses.add('(d.title LIKE ? OR d.notes LIKE ? OR d.category LIKE ? OR d.title LIKE ?)');
        args.addAll(['%$q%', '%$q%', '%$q%', '%$enQuery%']);
      } else {
        whereClauses.add('(d.title LIKE ? OR d.notes LIKE ? OR d.category LIKE ?)');
        args.addAll(['%$q%', '%$q%', '%$q%']);
      }
    }

    final whereSql = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final sql = 'SELECT d.* FROM demands d $whereSql ORDER BY d.id DESC';

    final demandRows = await db.rawQuery(sql, args);
    if (demandRows.isEmpty) return [];

    final demandIds = demandRows.map((r) => r['id'] as int).toList();
    final placeholders = List.filled(demandIds.length, '?').join(',');

    final requestRows = await db.rawQuery('''
      SELECT demand_id, request_date
      FROM demand_requests
      WHERE demand_id IN ($placeholders)
      ORDER BY request_date ASC
    ''', demandIds);

    final requestsByDemand = <int, List<String>>{};
    for (final r in requestRows) {
      final did = r['demand_id'] as int;
      final date = r['request_date'] as String;
      requestsByDemand.putIfAbsent(did, () => []).add(date);
    }

    final demands = demandRows.map((row) {
      final id = row['id'] as int;
      final requestDates = requestsByDemand[id] ?? [];
      return DemandModel.fromMap(row, requestDates: requestDates);
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
    final db = await _dbHelper.database;
    final rows = await db.query('demands', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;

    final requestRows = await db.query(
      'demand_requests',
      where: 'demand_id = ?',
      whereArgs: [id],
      orderBy: 'request_date ASC',
    );
    final requestDates = requestRows.map((r) => r['request_date'] as String).toList();

    return DemandModel.fromMap(rows.first, requestDates: requestDates);
  }

  /// Insert a new demand and record its initial request dates.
  Future<int> insert(DemandModel demand, {int initialCount = 1, String? initialDate}) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final date = initialDate ?? now;

    return await db.transaction((txn) async {
      final map = demand.toMap();
      map['created_at'] = now;
      map['updated_at'] = now;
      final demandId = await txn.insert('demands', map);

      // Insert initial request dates
      final count = initialCount.clamp(1, 1000);
      for (int i = 0; i < count; i++) {
        await txn.insert('demand_requests', {
          'demand_id': demandId,
          'request_date': date,
          'note': 'ثبت اولیه',
        });
      }

      return demandId;
    });
  }

  /// Update demand properties.
  Future<int> update(DemandModel demand) async {
    if (demand.id == null) return 0;
    final db = await _dbHelper.database;
    final map = demand.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();

    return await db.update('demands', map, where: 'id = ?', whereArgs: [demand.id]);
  }

  /// Update status of a demand.
  Future<int> updateStatus(int demandId, String newStatus) async {
    final db = await _dbHelper.database;
    return await db.update(
      'demands',
      {
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [demandId],
    );
  }

  /// Increment customer requests count by adding a timestamped request event (+ button).
  Future<void> addRequest(int demandId, {String? requestDate, String? note}) async {
    final db = await _dbHelper.database;
    final date = requestDate ?? DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.insert('demand_requests', {
        'demand_id': demandId,
        'request_date': date,
        'note': note,
      });
      await txn.update(
        'demands',
        {'updated_at': date},
        where: 'id = ?',
        whereArgs: [demandId],
      );
    });
  }

  /// Decrement customer requests count by removing the most recent request event (- button).
  /// Ensures at least 1 request record remains (returns false if count <= 1).
  Future<bool> removeLatestRequest(int demandId) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      final rows = await txn.rawQuery('''
        SELECT id FROM demand_requests
        WHERE demand_id = ?
        ORDER BY request_date DESC, id DESC
      ''', [demandId]);

      if (rows.length <= 1) {
        return false; // Keep at least one request record
      }

      final latestId = rows.first['id'] as int;
      await txn.delete('demand_requests', where: 'id = ?', whereArgs: [latestId]);
      await txn.update(
        'demands',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [demandId],
      );
      return true;
    });
  }

  /// Delete a demand and its associated requests.
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      await txn.delete('demand_requests', where: 'demand_id = ?', whereArgs: [id]);
      return await txn.delete('demands', where: 'id = ?', whereArgs: [id]);
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
