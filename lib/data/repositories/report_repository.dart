import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';

/// Repository for dashboard KPIs and reporting aggregates using Drift ORM.
class ReportRepository {
  final AppDatabase _db;

  ReportRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  // ── Helper to build date + category WHERE clauses for Drift customSelect ─────
  static void _appendFilters(
    StringBuffer sql,
    List<Variable> variables, {
    required String dateCol,
    String? dateFrom,
    String? dateTo,
    String? category,
    String? itemAlias,
  }) {
    if (dateFrom != null && dateFrom.isNotEmpty) {
      sql.write(' AND $dateCol >= ?');
      variables.add(Variable.withString(dateFrom));
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      sql.write(' AND $dateCol <= ?');
      variables.add(Variable.withString(dateTo));
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
      variables.add(Variable.withString(category));
    }
  }

  /// KPI: Total gross sales for settled invoices only.
  Future<double> totalGrossSales({String? dateFrom, String? dateTo, String? category}) async {
    final query = _db.selectOnly(_db.invoices)
      ..addColumns([_db.invoices.totalGross.sum()]);
    query.where(_db.invoices.status.equals('تسویه شده'));
    if (dateFrom != null && dateFrom.isNotEmpty) {
      query.where(_db.invoices.date.isBiggerOrEqualValue(dateFrom));
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      query.where(_db.invoices.date.isSmallerOrEqualValue(dateTo));
    }
    if (category != null && category.isNotEmpty) {
      final sub = _db.selectOnly(_db.invoiceItems)
        ..join([
          innerJoin(_db.products, _db.products.id.equalsExp(_db.invoiceItems.productId)),
        ])
        ..where(_db.products.category.equals(category))
        ..addColumns([_db.invoiceItems.invoiceId]);
      query.where(_db.invoices.id.isInQuery(sub));
    }

    final row = await query.getSingle();
    return row.read(_db.invoices.totalGross.sum()) ?? 0.0;
  }

  /// KPI: Total net profit (سود خالص) for settled invoices only.
  /// Profit = sum(line_total - (quantity * effective_buy_price)).
  Future<double> totalNetProfit({String? dateFrom, String? dateTo, String? category}) async {
    final sql = StringBuffer('''
      SELECT COALESCE(SUM(
        ii.line_total - (ii.quantity * COALESCE(NULLIF(p.current_buy_price, 0), p.buy_price, 0))
      ), 0) as total_profit
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      LEFT JOIN products p ON ii.product_id = p.id
      WHERE i.status = 'تسویه شده'
    ''');
    final variables = <Variable>[];
    _appendFilters(sql, variables, dateCol: 'i.date', dateFrom: dateFrom, dateTo: dateTo, category: category, itemAlias: 'ii');

    final result = await _db.customSelect(
      sql.toString(),
      variables: variables,
      readsFrom: {_db.invoiceItems, _db.invoices, _db.products},
    ).get();
    return (result.first.data['total_profit'] as num?)?.toDouble() ?? 0.0;
  }

  /// KPI: Total discounts given on settled invoices.
  Future<double> totalDiscounts({String? dateFrom, String? dateTo, String? category}) async {
    final query = _db.selectOnly(_db.invoices)
      ..addColumns([_db.invoices.totalDiscount.sum()]);
    query.where(_db.invoices.status.equals('تسویه شده'));
    if (dateFrom != null && dateFrom.isNotEmpty) {
      query.where(_db.invoices.date.isBiggerOrEqualValue(dateFrom));
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      query.where(_db.invoices.date.isSmallerOrEqualValue(dateTo));
    }
    if (category != null && category.isNotEmpty) {
      final sub = _db.selectOnly(_db.invoiceItems)
        ..join([
          innerJoin(_db.products, _db.products.id.equalsExp(_db.invoiceItems.productId)),
        ])
        ..where(_db.products.category.equals(category))
        ..addColumns([_db.invoiceItems.invoiceId]);
      query.where(_db.invoices.id.isInQuery(sub));
    }

    final row = await query.getSingle();
    return row.read(_db.invoices.totalDiscount.sum()) ?? 0.0;
  }

  /// KPI: Buy costs breakdown for settled invoices (initial buy cost and current replacement cost).
  Future<({double initialCost, double currentCost})> totalBuyCosts({
    String? dateFrom,
    String? dateTo,
    String? category,
  }) async {
    final sql = StringBuffer('''
      SELECT 
        COALESCE(SUM(ii.quantity * COALESCE(p.buy_price, 0)), 0) as initial_cost,
        COALESCE(SUM(ii.quantity * COALESCE(NULLIF(p.current_buy_price, 0), p.buy_price, 0)), 0) as current_cost
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      LEFT JOIN products p ON ii.product_id = p.id
      WHERE i.status = 'تسویه شده'
    ''');
    final variables = <Variable>[];
    _appendFilters(sql, variables, dateCol: 'i.date', dateFrom: dateFrom, dateTo: dateTo, category: category, itemAlias: 'ii');

    final result = await _db.customSelect(
      sql.toString(),
      variables: variables,
      readsFrom: {_db.invoiceItems, _db.invoices, _db.products},
    ).get();
    final row = result.first.data;
    return (
      initialCost: (row['initial_cost'] as num?)?.toDouble() ?? 0.0,
      currentCost: (row['current_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// KPI: Summary of pending and deposit invoices (unsettled amounts and count).
  Future<Map<String, dynamic>> pendingSummary({String? dateFrom, String? dateTo, String? category}) async {
    final sql = StringBuffer('''
      SELECT 
        COUNT(*) as cnt,
        COALESCE(SUM(total_net - COALESCE((SELECT SUM(amount) FROM invoice_payments ip WHERE ip.invoice_id = i.id), 0)), 0) as total_amount
      FROM invoices i
      WHERE (i.status = 'در انتظار پرداخت' OR i.status = 'بیعانه' OR i.status = 'نسیه')
    ''');
    final variables = <Variable>[];
    _appendFilters(sql, variables, dateCol: 'i.date', dateFrom: dateFrom, dateTo: dateTo, category: category);

    final result = await _db.customSelect(
      sql.toString(),
      variables: variables,
      readsFrom: {_db.invoices, _db.invoicePayments},
    ).get();
    final row = result.first.data;
    return {
      'count': (row['cnt'] as int?) ?? 0,
      'amount': (row['total_amount'] as num?)?.toDouble() ?? 0.0,
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
    final variables = <Variable>[];
    _appendFilters(sql, variables, dateCol: 'i.date', dateFrom: dateFrom, dateTo: dateTo, category: category, itemAlias: 'ii');

    sql.write('''
      GROUP BY ii.product_id, ii.product_name
      ORDER BY total_quantity DESC
      LIMIT ?
    ''');
    variables.add(Variable.withInt(limit));

    final rows = await _db.customSelect(
      sql.toString(),
      variables: variables,
      readsFrom: {_db.invoiceItems, _db.invoices},
    ).get();
    return rows.map((r) => Map<String, dynamic>.from(r.data)).toList();
  }

  /// Best-selling products by revenue (settled invoices).
  Future<List<Map<String, dynamic>>> bestSellersByRevenue({
    int limit = 10,
    String? dateFrom,
    String? dateTo,
    String? category,
  }) async {
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
    final variables = <Variable>[];
    _appendFilters(sql, variables, dateCol: 'i.date', dateFrom: dateFrom, dateTo: dateTo, category: category, itemAlias: 'ii');

    sql.write('''
      GROUP BY ii.product_id, ii.product_name
      ORDER BY total_revenue DESC
      LIMIT ?
    ''');
    variables.add(Variable.withInt(limit));

    final rows = await _db.customSelect(
      sql.toString(),
      variables: variables,
      readsFrom: {_db.invoiceItems, _db.invoices},
    ).get();
    return rows.map((r) => Map<String, dynamic>.from(r.data)).toList();
  }

  /// Item-level sales ledger with date, product, status filtering and profit calculation.
  Future<List<Map<String, dynamic>>> salesLedger({
    String? dateFrom,
    String? dateTo,
    int? productId,
    String? status,
  }) async {
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
    final variables = <Variable>[];

    if (status != null && status.isNotEmpty && status != 'همه') {
      sql += ' AND i.status = ?';
      variables.add(Variable.withString(status));
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      sql += ' AND i.date >= ?';
      variables.add(Variable.withString(dateFrom));
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      sql += ' AND i.date <= ?';
      variables.add(Variable.withString(dateTo));
    }
    if (productId != null) {
      sql += ' AND ii.product_id = ?';
      variables.add(Variable.withInt(productId));
    }

    sql += ' ORDER BY i.date DESC, i.id DESC';

    final rows = await _db.customSelect(
      sql,
      variables: variables,
      readsFrom: {_db.invoiceItems, _db.invoices, _db.customers, _db.products},
    ).get();
    return rows.map((r) => Map<String, dynamic>.from(r.data)).toList();
  }

  /// Aggregated summary of the ledger for the specified filters.
  Future<Map<String, dynamic>> ledgerSummary({
    String? dateFrom,
    String? dateTo,
    String? status,
  }) async {
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
    final variables = <Variable>[];

    if (status != null && status.isNotEmpty && status != 'همه') {
      sql += ' AND i.status = ?';
      variables.add(Variable.withString(status));
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      sql += ' AND i.date >= ?';
      variables.add(Variable.withString(dateFrom));
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      sql += ' AND i.date <= ?';
      variables.add(Variable.withString(dateTo));
    }

    final result = await _db.customSelect(
      sql,
      variables: variables,
      readsFrom: {_db.invoiceItems, _db.invoices, _db.products},
    ).get();
    final row = result.first.data;
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
    final query = _db.select(_db.invoices).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.invoices.customerId)),
    ]);
    if (dateFrom != null && dateFrom.isNotEmpty) {
      query.where(_db.invoices.date.isBiggerOrEqualValue(dateFrom));
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      query.where(_db.invoices.date.isSmallerOrEqualValue(dateTo));
    }
    if (category != null && category.isNotEmpty) {
      final sub = _db.selectOnly(_db.invoiceItems)
        ..join([
          innerJoin(_db.products, _db.products.id.equalsExp(_db.invoiceItems.productId)),
        ])
        ..where(_db.products.category.equals(category))
        ..addColumns([_db.invoiceItems.invoiceId]);
      query.where(_db.invoices.id.isInQuery(sub));
    }

    query.orderBy([
      OrderingTerm.desc(_db.invoices.date),
      OrderingTerm.desc(_db.invoices.id),
    ]);
    query.limit(limit);

    final rows = await query.get();
    return rows.map((row) {
      final inv = row.readTable(_db.invoices);
      final cust = row.readTableOrNull(_db.customers);
      return {
        'id': inv.id,
        'invoice_number': inv.invoiceNumber,
        'customer_id': inv.customerId,
        'date': inv.date,
        'status': inv.status,
        'total_gross': inv.totalGross,
        'total_discount': inv.totalDiscount,
        'total_net': inv.totalNet,
        'notes': inv.notes,
        'customer_name': cust?.name,
      };
    }).toList();
  }
}
