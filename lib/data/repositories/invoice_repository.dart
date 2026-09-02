import '../../core/database/database_helper.dart';
import '../models/invoice_model.dart';
import '../models/invoice_item_model.dart';

/// Repository for Invoice CRUD with transactional item management.
class InvoiceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Fetch all invoices with customer name join, optionally filtered.
  Future<List<InvoiceModel>> getAll({
    String? customerQuery,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    final db = await _dbHelper.database;

    String sql = '''
      SELECT i.*, c.name as customer_name
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id
      WHERE 1=1
    ''';
    final args = <dynamic>[];

    if (customerQuery != null && customerQuery.isNotEmpty) {
      sql += ' AND (c.name LIKE ? OR i.invoice_number LIKE ?)';
      args.addAll(['%$customerQuery%', '%$customerQuery%']);
    }
    if (status != null && status.isNotEmpty) {
      sql += ' AND i.status = ?';
      args.add(status);
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      sql += ' AND i.date >= ?';
      args.add(dateFrom);
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      sql += ' AND i.date <= ?';
      args.add(dateTo);
    }

    sql += ' ORDER BY i.date DESC, i.id DESC';

    final maps = await db.rawQuery(sql, args);
    return maps.map((m) => InvoiceModel.fromMap(m)).toList();
  }

  /// Fetch a single invoice by ID with all its items.
  Future<InvoiceModel?> getById(int id) async {
    final db = await _dbHelper.database;
    final invoiceMaps = await db.rawQuery('''
      SELECT i.*, c.name as customer_name
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id
      WHERE i.id = ?
    ''', [id]);

    if (invoiceMaps.isEmpty) return null;

    final itemMaps = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [id],
      orderBy: 'id ASC',
    );

    final items = itemMaps.map((m) => InvoiceItemModel.fromMap(m)).toList();
    return InvoiceModel.fromMap(invoiceMaps.first, items: items);
  }

  /// Fetch items for a given invoice.
  Future<List<InvoiceItemModel>> getItemsByInvoiceId(int invoiceId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'id ASC',
    );
    return maps.map((m) => InvoiceItemModel.fromMap(m)).toList();
  }

  /// Save a new invoice with items in a single transaction.
  /// Returns the new invoice ID.
  Future<int> insert(InvoiceModel invoice) async {
    final db = await _dbHelper.database;
    late int invoiceId;

    await db.transaction((txn) async {
      invoiceId = await txn.insert('invoices', invoice.toMap());

      for (final item in invoice.items) {
        final itemMap = item.copyWith(invoiceId: invoiceId).toMap();
        await txn.insert('invoice_items', itemMap);
      }
    });

    return invoiceId;
  }

  /// Update an existing invoice and its items in a single transaction.
  Future<void> update(InvoiceModel invoice) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        'invoices',
        invoice.toMap(),
        where: 'id = ?',
        whereArgs: [invoice.id],
      );

      // Delete old items and re-insert
      await txn.delete(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoice.id],
      );

      for (final item in invoice.items) {
        final itemMap = item.copyWith(invoiceId: invoice.id).toMap();
        // Remove the item id so it gets auto-incremented
        itemMap.remove('id');
        await txn.insert('invoice_items', itemMap);
      }
    });
  }

  /// Delete an invoice by ID (cascade deletes items via FK).
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    // First delete items (in case PRAGMA foreign_keys is off)
    await db.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
    return await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  /// Get the next invoice counter for generating invoice numbers.
  Future<int> nextCounter() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT MAX(id) as max_id FROM invoices');
    final maxId = result.first['max_id'] as int?;
    return (maxId ?? 0) + 1;
  }

  /// Get invoices for a specific customer.
  Future<List<InvoiceModel>> getByCustomerId(int customerId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT i.*, c.name as customer_name
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id
      WHERE i.customer_id = ?
      ORDER BY i.date DESC
    ''', [customerId]);
    return maps.map((m) => InvoiceModel.fromMap(m)).toList();
  }
}
