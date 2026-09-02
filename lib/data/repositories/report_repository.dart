import '../../core/database/database_helper.dart';

/// Repository for dashboard KPIs and reporting aggregates.
class ReportRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// KPI: Total gross sales (sum of total_gross for non-cancelled invoices).
  Future<double> totalGrossSales() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(total_gross), 0) as total FROM invoices WHERE status != 'لغو شده'",
    );
    return (result.first['total'] as num).toDouble();
  }

  /// KPI: Total net revenue.
  Future<double> totalNetRevenue() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(total_net), 0) as total FROM invoices WHERE status != 'لغو شده'",
    );
    return (result.first['total'] as num).toDouble();
  }

  /// KPI: Total discounts given.
  Future<double> totalDiscounts() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(total_discount), 0) as total FROM invoices WHERE status != 'لغو شده'",
    );
    return (result.first['total'] as num).toDouble();
  }

  /// KPI: Count of outstanding (unsettled) invoices.
  Future<int> outstandingCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM invoices WHERE status = 'در انتظار پرداخت' OR status = 'بیعانه'",
    );
    return (result.first['cnt'] as int);
  }

  /// Best-selling products by quantity.
  Future<List<Map<String, dynamic>>> bestSellersByVolume({int limit = 10}) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT 
        ii.product_name,
        ii.product_id,
        SUM(ii.quantity) as total_quantity,
        SUM(ii.line_total) as total_revenue
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      WHERE i.status != 'لغو شده'
      GROUP BY ii.product_id, ii.product_name
      ORDER BY total_quantity DESC
      LIMIT ?
    ''', [limit]);
  }

  /// Best-selling products by revenue.
  Future<List<Map<String, dynamic>>> bestSellersByRevenue({int limit = 10}) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT 
        ii.product_name,
        ii.product_id,
        SUM(ii.quantity) as total_quantity,
        SUM(ii.line_total) as total_revenue
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      WHERE i.status != 'لغو شده'
      GROUP BY ii.product_id, ii.product_name
      ORDER BY total_revenue DESC
      LIMIT ?
    ''', [limit]);
  }

  /// Item-level sales ledger with optional date filtering.
  Future<List<Map<String, dynamic>>> salesLedger({
    String? dateFrom,
    String? dateTo,
    int? productId,
  }) async {
    final db = await _dbHelper.database;

    String sql = '''
      SELECT 
        ii.product_name,
        ii.product_id,
        i.invoice_number,
        i.date,
        c.name as customer_name,
        ii.quantity,
        ii.unit_price,
        ii.discount_calculated_amount,
        ii.line_total
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      LEFT JOIN customers c ON i.customer_id = c.id
      WHERE i.status != 'لغو شده'
    ''';
    final args = <dynamic>[];

    if (dateFrom != null && dateFrom.isNotEmpty) {
      sql += ' AND i.date >= ?';
      args.add(dateFrom);
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      sql += ' AND i.date <= ?';
      args.add(dateTo);
    }
    if (productId != null) {
      sql += ' AND ii.product_id = ?';
      args.add(productId);
    }

    sql += ' ORDER BY i.date DESC, i.id DESC';

    return await db.rawQuery(sql, args);
  }

  /// Recent invoices for dashboard.
  Future<List<Map<String, dynamic>>> recentInvoices({int limit = 5}) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT i.*, c.name as customer_name
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id
      ORDER BY i.date DESC, i.id DESC
      LIMIT ?
    ''', [limit]);
  }
}
