import '../../core/database/database_helper.dart';
import '../../core/extensions/number_extensions.dart';
import '../models/invoice_model.dart';
import '../models/invoice_item_model.dart';
import '../models/invoice_payment_model.dart';

/// Repository for Invoice CRUD with transactional item and payment management.
class InvoiceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Fetch all invoices with customer name join, optionally filtered.
  Future<List<InvoiceModel>> getAll({
    String? customerQuery,
    String? productQuery,
    String? status,
    String? category,
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
      final enQuery = customerQuery.toEnglishDigits();
      if (enQuery != customerQuery) {
        sql += ' AND (c.name LIKE ? OR i.invoice_number LIKE ? OR i.invoice_number LIKE ?)';
        args.addAll(['%$customerQuery%', '%$customerQuery%', '%$enQuery%']);
      } else {
        sql += ' AND (c.name LIKE ? OR i.invoice_number LIKE ?)';
        args.addAll(['%$customerQuery%', '%$customerQuery%']);
      }
    }
    if (productQuery != null && productQuery.isNotEmpty) {
      sql += ''' AND EXISTS (
        SELECT 1 FROM invoice_items ii 
        WHERE ii.invoice_id = i.id 
        AND ii.product_name LIKE ?
      )''';
      args.add('%$productQuery%');
    }
    if (category != null && category.isNotEmpty) {
      sql += ''' AND EXISTS (
        SELECT 1 FROM invoice_items ii
        JOIN products p ON p.id = ii.product_id
        WHERE ii.invoice_id = i.id AND p.category = ?
      )''';
      args.add(category);
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
    if (maps.isEmpty) return [];

    // Batch load items and payments for all returned invoices
    final invoiceIds = maps.map((m) => m['id'] as int).toList();
    final placeholders = List.filled(invoiceIds.length, '?').join(',');

    final itemMaps = await db.rawQuery(
      'SELECT * FROM invoice_items WHERE invoice_id IN ($placeholders) ORDER BY id ASC',
      invoiceIds,
    );
    final itemsByInvoice = <int, List<InvoiceItemModel>>{};
    for (final im in itemMaps) {
      final item = InvoiceItemModel.fromMap(im);
      if (item.invoiceId != null) {
        itemsByInvoice.putIfAbsent(item.invoiceId!, () => []).add(item);
      }
    }

    final paymentMaps = await db.rawQuery(
      'SELECT * FROM invoice_payments WHERE invoice_id IN ($placeholders) ORDER BY date ASC, id ASC',
      invoiceIds,
    );
    final paymentsByInvoice = <int, List<InvoicePaymentModel>>{};
    for (final pm in paymentMaps) {
      final payment = InvoicePaymentModel.fromMap(pm);
      if (payment.invoiceId != null) {
        paymentsByInvoice.putIfAbsent(payment.invoiceId!, () => []).add(payment);
      }
    }

    return maps.map((m) {
      final id = m['id'] as int?;
      return InvoiceModel.fromMap(
        m,
        items: id != null ? itemsByInvoice[id] : null,
        payments: id != null ? paymentsByInvoice[id] : null,
      );
    }).toList();
  }

  /// Fetch a single invoice by ID with all its items and payments.
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

    final paymentMaps = await db.query(
      'invoice_payments',
      where: 'invoice_id = ?',
      whereArgs: [id],
      orderBy: 'date ASC, id ASC',
    );
    final payments = paymentMaps.map((m) => InvoicePaymentModel.fromMap(m)).toList();

    return InvoiceModel.fromMap(invoiceMaps.first, items: items, payments: payments);
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

  /// Fetch payments for a given invoice.
  Future<List<InvoicePaymentModel>> getPaymentsByInvoiceId(int invoiceId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'invoice_payments',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'date ASC, id ASC',
    );
    return maps.map((m) => InvoicePaymentModel.fromMap(m)).toList();
  }

  /// Save a new invoice with items and payments in a single transaction.
  /// Automatically deducts purchased quantities from product stock (unless stock is infinite/null).
  /// Returns the new invoice ID.
  Future<int> insert(InvoiceModel invoice) async {
    final db = await _dbHelper.database;
    late int invoiceId;

    await db.transaction((txn) async {
      invoiceId = await txn.insert('invoices', invoice.toMap());

      for (final item in invoice.items) {
        final itemMap = item.copyWith(invoiceId: invoiceId).toMap();
        itemMap.remove('id');
        await txn.insert('invoice_items', itemMap);

        // Deduct purchased quantity from product stock
        if (item.productId != null && item.quantity > 0) {
          await txn.rawUpdate(
            'UPDATE products SET stock = stock - ? WHERE id = ? AND stock IS NOT NULL',
            [item.quantity, item.productId],
          );
        }
      }

      for (final payment in invoice.payments) {
        final pMap = payment.copyWith(invoiceId: invoiceId).toMap();
        pMap.remove('id');
        await txn.insert('invoice_payments', pMap);
      }
    });

    return invoiceId;
  }

  /// Update an existing invoice, its items, and its payments in a single transaction.
  /// Restores previous items' stock and deducts new items' stock.
  Future<void> update(InvoiceModel invoice) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        'invoices',
        invoice.toMap(),
        where: 'id = ?',
        whereArgs: [invoice.id],
      );

      // Restore stock for previously saved items
      final oldItems = await txn.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoice.id],
      );
      for (final oldItem in oldItems) {
        final pid = oldItem['product_id'] as int?;
        final qty = (oldItem['quantity'] as num?)?.toDouble() ?? 0.0;
        if (pid != null && qty > 0) {
          await txn.rawUpdate(
            'UPDATE products SET stock = stock + ? WHERE id = ? AND stock IS NOT NULL',
            [qty, pid],
          );
        }
      }

      // Delete old items and re-insert
      await txn.delete(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoice.id],
      );

      for (final item in invoice.items) {
        final itemMap = item.copyWith(invoiceId: invoice.id).toMap();
        itemMap.remove('id');
        await txn.insert('invoice_items', itemMap);

        // Deduct new items' stock
        if (item.productId != null && item.quantity > 0) {
          await txn.rawUpdate(
            'UPDATE products SET stock = stock - ? WHERE id = ? AND stock IS NOT NULL',
            [item.quantity, item.productId],
          );
        }
      }

      // Sync payments
      await txn.delete(
        'invoice_payments',
        where: 'invoice_id = ?',
        whereArgs: [invoice.id],
      );
      for (final payment in invoice.payments) {
        final pMap = payment.copyWith(invoiceId: invoice.id).toMap();
        pMap.remove('id');
        await txn.insert('invoice_payments', pMap);
      }
    });
  }

  /// Add a single payment to an existing invoice directly and update invoice status.
  Future<int> addPayment(InvoicePaymentModel payment) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      final pMap = payment.toMap();
      pMap.remove('id');
      final paymentId = await txn.insert('invoice_payments', pMap);

      if (payment.invoiceId != null) {
        final invList = await txn.query('invoices', where: 'id = ?', whereArgs: [payment.invoiceId]);
        if (invList.isNotEmpty) {
          final totalNet = (invList.first['total_net'] as num).toDouble();
          final currentStatus = invList.first['status'] as String? ?? '';
          final paySumResult = await txn.rawQuery(
            'SELECT SUM(amount) as sum_amount FROM invoice_payments WHERE invoice_id = ?',
            [payment.invoiceId],
          );
          final totalPaid = (paySumResult.first['sum_amount'] as num?)?.toDouble() ?? 0.0;

          if (totalPaid >= totalNet && currentStatus != 'تسویه شده' && currentStatus != 'لغو شده') {
            await txn.update(
              'invoices',
              {'status': 'تسویه شده'},
              where: 'id = ?',
              whereArgs: [payment.invoiceId],
            );
          } else if (totalPaid > 0 && totalPaid < totalNet && (currentStatus == 'در انتظار پرداخت' || currentStatus == 'بیعانه')) {
            await txn.update(
              'invoices',
              {'status': 'نسیه'},
              where: 'id = ?',
              whereArgs: [payment.invoiceId],
            );
          }
        }
      }

      return paymentId;
    });
  }

  /// Delete a single payment from an invoice and re-check invoice status.
  Future<void> deletePayment(int paymentId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final pList = await txn.query('invoice_payments', where: 'id = ?', whereArgs: [paymentId]);
      if (pList.isNotEmpty) {
        final invId = pList.first['invoice_id'] as int?;
        await txn.delete('invoice_payments', where: 'id = ?', whereArgs: [paymentId]);

        if (invId != null) {
          final invList = await txn.query('invoices', where: 'id = ?', whereArgs: [invId]);
          if (invList.isNotEmpty) {
            final totalNet = (invList.first['total_net'] as num).toDouble();
            final currentStatus = invList.first['status'] as String? ?? '';
            final paySumResult = await txn.rawQuery(
              'SELECT SUM(amount) as sum_amount FROM invoice_payments WHERE invoice_id = ?',
              [invId],
            );
            final totalPaid = (paySumResult.first['sum_amount'] as num?)?.toDouble() ?? 0.0;

            if (totalPaid < totalNet && currentStatus == 'تسویه شده') {
              await txn.update(
                'invoices',
                {'status': totalPaid > 0 ? 'نسیه' : 'در انتظار پرداخت'},
                where: 'id = ?',
                whereArgs: [invId],
              );
            }
          }
        }
      }
    });
  }

  /// Delete an invoice by ID, restoring items' stock before deleting.
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      // Restore stock for items of the deleted invoice
      final oldItems = await txn.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [id],
      );
      for (final oldItem in oldItems) {
        final pid = oldItem['product_id'] as int?;
        final qty = (oldItem['quantity'] as num?)?.toDouble() ?? 0.0;
        if (pid != null && qty > 0) {
          await txn.rawUpdate(
            'UPDATE products SET stock = stock + ? WHERE id = ? AND stock IS NOT NULL',
            [qty, pid],
          );
        }
      }

      // Delete items, payments and invoice
      await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
      await txn.delete('invoice_payments', where: 'invoice_id = ?', whereArgs: [id]);
      return await txn.delete('invoices', where: 'id = ?', whereArgs: [id]);
    });
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
