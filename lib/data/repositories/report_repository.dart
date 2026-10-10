import '../../core/database/database_helper.dart';

/// Repository for dashboard KPIs and reporting aggregates.
class ReportRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ── Helper to build date + category WHERE clauses ────────────────────
  /// Appends date and category filters to [sql] and returns the args list.
  /// [dateCol] is the date column reference (e.g. 'date' or 'i.date').
  /// If [needsItemJoin] is true, the caller already JOINs invoice_items;
  /// otherwise this helper will add a sub-query filter.
  static void _appendFilters(
    StringBuffer sql,
    List<dynamic> args, {
    required String dateCol,
    String? dateFrom,
    String? dateTo,
    String? category,
    String? itemAlias,
  }) {
    if (dateFrom != null && dateFrom.isNotEmpty) {
      sql.write(' AND $dateCol >= ?');
      args.add(dateFrom);
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      sql.write(' AND $dateCol <= ?');
      args.add(dateTo);
    }
    if (category != null && category.isNotEmpty) {
      if (itemAlias != null) {
        // Already joining invoice_items as [itemAlias]
        sql.write(' AND EXISTS (SELECT 1 FROM products _p WHERE _p.id = $itemAlias.product_id AND _p.category = ?)');
      } else {
        // Invoice-level query without item join
        sql.write(''' AND EXISTS (
          SELECT 1 FROM invoice_items _ii
          JOIN products _p ON _p.id = _ii.product_id
          WHERE _ii.invoice_id = i.id AND _p.category = ?
        )''');
      }
      args.add(category);
    }
  }

  /// KPI: Total gross sales for settled invoices only.
  Future<double> totalGrossSales({String? dateFrom, String? dateTo, String? category}) async {
    final db = await _dbHelper.database;
    final sql = StringBuffer("SELECT COALESCE(SUM(total_gross), 0) as total FROM invoices i WHERE i.status = 'تسویه شده'");
    final args = <dynamic>[];
    _appendFilters(sql, args, dateCol: 'i.date', dateFrom: dateFrom, dateTo: dateTo, category: category);

    final result = await db.rawQuery(sql.toString(), args);
    return (result.first['total'] as num).toDouble();
  }

  /// KPI: Total net profit (سود خالص) for settled invoices only.
  /// Profit = sum(line_total - (quantity * effective_buy_price)).
  Future<double> totalNetProfit({String? dateFrom, String? dateTo, String? category}) async {
    final db = await _dbHelper.database;
    final sql = StringBuffer('''
      SELECT COALESCE(SUM(
        ii.line_total - (ii.quantity * COALESCE(NULLIF(p.current_buy_price, 0), p.buy_price, 0))
      ), 0) as total_profit
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      LEFT JOIN products p ON ii.product_id = p.id
      WHERE i.status = 'تسویه شده'
    ''');
    final args = <dynamic>[];
    _appendFilters(sql, args, dateCol: 'i.date', dateFrom: dateFrom, dateTo: dateTo, category: category, itemAlias: 'ii');

    final result = await db.rawQuery(sql.toString(), args);
    return (result.first['total_profit'] as num).toDouble();
  }

  /// KPI: Total discounts given on settled invoices.
  Future<double> totalDiscounts({String? dateFrom, String? dateTo, String? category}) async {
    final db = await _dbHelper.database;
    final sql = StringBuffer("SELECT COALESCE(SUM(total_discount), 0) as total FROM invoices i WHERE i.status = 'تسویه شده'");
    final args = <dynamic>[];
    _appendFilters(sql, args, dateCol: 'i.date', dateFrom: dateFrom, dateTo: dateTo, category: category);

    final result = await db.rawQuery(sql.toString(), args);
    return (result.first['total'] as num).toDouble();
  }

  /// KPI: Buy costs breakdown for settled invoices (initial buy cost and current replacement cost).
  Future<({double initialCost, double currentCost})> totalBuyCosts({
    String? dateFrom,
    String? dateTo,
    String? category,
  }) async {
    final db = await _dbHelper.database;
    final sql = StringBuffer('''
      SELECT 
        COALESCE(SUM(ii.quantity * COALESCE(p.buy_price, 0)), 0) as initial_cost,
        COALESCE(SUM(ii.quantity * COALESCE(NULLIF(p.current_buy_price, 0), p.buy_price, 0)), 0) as current_cost
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      LEFT JOIN products p ON ii.product_id = p.id
      WHERE i.status = 'تسویه شده'
    ''');
    final args = <dynamic>[];
    _appendFilters(sql, args, dateCol: 'i.date', dateFrom: dateFrom, dateTo: dateTo, category: category, itemAlias: 'ii');

    final result = await db.rawQuery(sql.toString(), args);
    final row = result.first;
    return (
      initialCost: (row['initial_cost'] as num).toDouble(),
      currentCost: (row['current_cost'] as num).toDouble(),
    );
  }

  /// KPI: Summary of pending and deposit invoices (unsettled amounts and count).
  Future<Map<String, dynamic>> pendingSummary({String? dateFrom, String? dateTo, String? category}) async {
    final db = await _dbHelper.database;
    final sql = StringBuffer('''
      SELECT 
        COUNT(*) as cnt,
        COALESCE(SUM(total_net - COALESCE((SELECT SUM(amount) FROM invoice_payments ip WHERE ip.invoice_id = i.id), 0)), 0) as total_amount
      FROM invoices i
      WHERE (i.status = 'در انتظار پرداخت' OR i.status = 'بیعانه' OR i.status = 'نسیه')
    ''');
    final args = <dynamic>[];
    _appendFilters(sql, args, dateCol: 'i.date', dateFrom: dateFrom, dateTo: dateTo, category: category);

    final result = await db.rawQuery(sql.toString(), args);
    return {
      'count': (result.first['cnt'] as int?) ?? 0,
      'amount': (result.first['total_amount'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// KPI: Count of outstanding (unsettled) invoices.
  Future<int> outstandingCount({String? dateFrom, String? dateTo, String? category}) async {
    final summary = await pendingSummary(dateFrom: dateFrom, dateTo: dateTo, category: category);
    return summary['count'] as int;
  }

  /// Best-selling products by quantity (settled invoices).
  Future<List<Map<String, dynamic>>> bestSellersByVolume({
    int limit = 10,
    String? dateFrom,
    String? dateTo,
    String? category,
  }) async {
    final db = await _dbHelper.database;
    final sql = StringBuffer('''
      SELECT 
        ii.product_name,
        ii.product_id,
        SUM(ii.quantity) as total_quantity,
        SUM(ii.line_total) as total_revenue
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      LEFT JOIN products p ON ii.product_id = p.id
      WHERE i.status = 'تسویه شده'
    ''');
    final args = <dynamic>[];
    _appendFilters(sql, args, dateCol: 'i.date', dateFrom: dateFrom, dateTo: dateTo, category: category, itemAlias: 'ii');

    sql.write('''
      GROUP BY ii.product_id, ii.product_name
      ORDER BY total_quantity DESC
      LIMIT ?
    ''');
    args.add(limit);

    return await db.rawQuery(sql.toString(), args);
  }

  /// Best-selling products by revenue (settled invoices).
  Future<List<Map<String, dynamic>>> bestSellersByRevenue({
    int limit = 10,
    String? dateFrom,
    String? dateTo,
    String? category,
  }) async {
    final db = await _dbHelper.database;
    final sql = StringBuffer('''
      SELECT 
        ii.product_name,
        ii.product_id,
        SUM(ii.quantity) as total_quantity,
        SUM(ii.line_total) as total_revenue
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      LEFT JOIN products p ON ii.product_id = p.id
      WHERE i.status = 'تسویه شده'
    ''');
    final args = <dynamic>[];
    _appendFilters(sql, args, dateCol: 'i.date', dateFrom: dateFrom, dateTo: dateTo, category: category, itemAlias: 'ii');

    sql.write('''
      GROUP BY ii.product_id, ii.product_name
      ORDER BY total_revenue DESC
      LIMIT ?
    ''');
    args.add(limit);

    return await db.rawQuery(sql.toString(), args);
  }

  /// Item-level sales ledger with date, product, status filtering and profit calculation.
  Future<List<Map<String, dynamic>>> salesLedger({
    String? dateFrom,
    String? dateTo,
    int? productId,
    String? status,
  }) async {
    final db = await _dbHelper.database;

    String sql = '''
      SELECT 
        ii.product_name,
        ii.product_id,
        i.invoice_number,
        i.date,
        i.status as invoice_status,
        c.name as customer_name,
        ii.quantity,
        ii.unit_price,
        ii.discount_calculated_amount,
        ii.line_total,
        ROUND(ii.line_total - (ii.quantity * COALESCE(NULLIF(p.current_buy_price, 0), p.buy_price, 0))) as profit
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      LEFT JOIN customers c ON i.customer_id = c.id
      LEFT JOIN products p ON ii.product_id = p.id
      WHERE i.status != 'لغو شده'
    ''';
    final args = <dynamic>[];

    if (status != null && status.isNotEmpty && status != 'همه') {
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
    if (productId != null) {
      sql += ' AND ii.product_id = ?';
      args.add(productId);
    }

    sql += ' ORDER BY i.date DESC, i.id DESC';

    return await db.rawQuery(sql, args);
  }

  /// Aggregated summary of the ledger for the specified filters.
  Future<Map<String, dynamic>> ledgerSummary({
    String? dateFrom,
    String? dateTo,
    String? status,
  }) async {
    final db = await _dbHelper.database;

    String sql = '''
      SELECT 
        COUNT(ii.id) as items_count,
        COALESCE(SUM(ii.quantity), 0) as total_quantity,
        COALESCE(SUM(ii.line_total), 0) as total_sales,
        COALESCE(SUM(ii.discount_calculated_amount), 0) as total_discount,
        COALESCE(SUM(
          ii.line_total - (ii.quantity * COALESCE(NULLIF(p.current_buy_price, 0), p.buy_price, 0))
        ), 0) as total_profit
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      LEFT JOIN products p ON ii.product_id = p.id
      WHERE i.status != 'لغو شده'
    ''';
    final args = <dynamic>[];

    if (status != null && status.isNotEmpty && status != 'همه') {
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

    final result = await db.rawQuery(sql, args);
    final row = result.first;
    return {
      'items_count': (row['items_count'] as int?) ?? 0,
      'total_quantity': (row['total_quantity'] as num?)?.toDouble() ?? 0.0,
      'total_sales': (row['total_sales'] as num?)?.toDouble() ?? 0.0,
      'total_discount': (row['total_discount'] as num?)?.toDouble() ?? 0.0,
      'total_profit': (row['total_profit'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// Recent invoices with optional date and category filtering.
  Future<List<Map<String, dynamic>>> recentInvoices({
    int limit = 5,
    String? dateFrom,
    String? dateTo,
    String? category,
  }) async {
    final db = await _dbHelper.database;
    final sql = StringBuffer('''
      SELECT i.*, c.name as customer_name
      FROM invoices i
      LEFT JOIN customers c ON i.customer_id = c.id
      WHERE 1=1
    ''');
    final args = <dynamic>[];
    _appendFilters(sql, args, dateCol: 'i.date', dateFrom: dateFrom, dateTo: dateTo, category: category);

    sql.write(' ORDER BY i.date DESC, i.id DESC LIMIT ?');
    args.add(limit);

    return await db.rawQuery(sql.toString(), args);
  }
}
