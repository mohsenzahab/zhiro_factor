import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/database/database_helper.dart';
import '../../core/extensions/number_extensions.dart';
import '../models/price_change_model.dart';

/// Repository for managing price change history records.
class PriceChangeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Database> get _database => _dbHelper.database;

  /// Insert a single price change history record. Returns the new row ID.
  Future<int> insert(PriceChangeModel model) async {
    final db = await _database;
    return await db.insert('price_change_history', model.toMap());
  }

  /// Bulk insert price change history records in a batch.
  Future<void> insertBatch(List<PriceChangeModel> models) async {
    if (models.isEmpty) return;
    final db = await _database;
    final batch = db.batch();
    for (final model in models) {
      batch.insert('price_change_history', model.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Fetch price change records with product details, optionally filtered.
  Future<List<PriceChangeModel>> getAll({
    int? productId,
    String? query,
    String? changeType,
    String? dateFrom,
    String? dateTo,
  }) async {
    final db = await _database;

    String sql = '''
      SELECT 
        h.id,
        h.product_id,
        p.name AS product_name,
        p.code AS product_code,
        p.category AS category,
        h.old_price,
        h.new_price,
        h.change_amount,
        h.change_type,
        h.change_source,
        h.created_at
      FROM price_change_history h
      LEFT JOIN products p ON h.product_id = p.id
      WHERE 1=1
    ''';
    final args = <dynamic>[];

    if (productId != null) {
      sql += ' AND h.product_id = ?';
      args.add(productId);
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim();
      final enQuery = q.toEnglishDigits();
      if (enQuery != q) {
        sql += ' AND (p.name LIKE ? OR p.code LIKE ? OR p.code LIKE ?)';
        args.addAll(['%$q%', '%$q%', '%$enQuery%']);
      } else {
        sql += ' AND (p.name LIKE ? OR p.code LIKE ?)';
        args.addAll(['%$q%', '%$q%']);
      }
    }

    if (changeType != null && changeType.isNotEmpty && changeType != 'all') {
      sql += ' AND h.change_type = ?';
      args.add(changeType);
    }

    if (dateFrom != null && dateFrom.isNotEmpty) {
      sql += ' AND h.created_at >= ?';
      args.add(dateFrom);
    }

    if (dateTo != null && dateTo.isNotEmpty) {
      sql += ' AND h.created_at <= ?';
      args.add(dateTo);
    }

    sql += ' ORDER BY h.created_at DESC, h.id DESC';

    final maps = await db.rawQuery(sql, args);
    return maps.map((m) => PriceChangeModel.fromMap(m)).toList();
  }

  /// Fetch the latest price change record for a specific product.
  Future<PriceChangeModel?> getLastChangeForProduct(int productId) async {
    final db = await _database;
    final maps = await db.rawQuery('''
      SELECT 
        h.id,
        h.product_id,
        p.name AS product_name,
        p.code AS product_code,
        p.category AS category,
        h.old_price,
        h.new_price,
        h.change_amount,
        h.change_type,
        h.change_source,
        h.created_at
      FROM price_change_history h
      LEFT JOIN products p ON h.product_id = p.id
      WHERE h.product_id = ?
      ORDER BY h.created_at DESC, h.id DESC
      LIMIT 1
    ''', [productId]);

    if (maps.isEmpty) return null;
    return PriceChangeModel.fromMap(maps.first);
  }

  /// Delete all price change history for a product.
  Future<int> deleteByProductId(int productId) async {
    final db = await _database;
    return await db.delete(
      'price_change_history',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  /// Delete a specific price change record.
  Future<int> delete(int id) async {
    final db = await _database;
    return await db.delete(
      'price_change_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
