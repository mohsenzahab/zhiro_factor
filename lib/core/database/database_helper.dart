import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Singleton helper for SQLite database lifecycle.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;
  static const int _version = 1;
  static const String _dbName = 'zhirofactor.db';

  /// Returns the initialized database instance.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    // Initialize FFI for desktop platforms
    sqfliteFfiInit();
    final databaseFactory = databaseFactoryFfi;

    final Directory appDir = await getApplicationSupportDirectory();
    final String dbPath = p.join(appDir.path, _dbName);

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      ),
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign key support
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // ── Products Table ──────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE,
        name TEXT NOT NULL,
        category TEXT,
        price REAL NOT NULL,
        unit TEXT NOT NULL,
        stock REAL DEFAULT 0,
        is_temporary INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_products_code ON products(code)');
    await db.execute('CREATE INDEX idx_products_name ON products(name)');

    // ── Customers Table ─────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        notes TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_customers_code ON customers(code)');
    await db.execute('CREATE INDEX idx_customers_name ON customers(name)');

    // ── Invoices Table ──────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE NOT NULL,
        customer_id INTEGER,
        date TEXT NOT NULL,
        status TEXT,
        total_gross REAL NOT NULL,
        total_discount REAL NOT NULL,
        total_net REAL NOT NULL,
        notes TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');
    await db.execute('CREATE INDEX idx_invoices_number ON invoices(invoice_number)');
    await db.execute('CREATE INDEX idx_invoices_customer ON invoices(customer_id)');
    await db.execute('CREATE INDEX idx_invoices_date ON invoices(date)');
    await db.execute('CREATE INDEX idx_invoices_status ON invoices(status)');

    // ── Invoice Items Table ─────────────────────────────────────────
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity REAL NOT NULL DEFAULT 1.0,
        discount_type TEXT NOT NULL DEFAULT 'none',
        discount_value REAL NOT NULL DEFAULT 0.0,
        discount_calculated_amount REAL NOT NULL DEFAULT 0.0,
        line_total REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');
    await db.execute('CREATE INDEX idx_invoice_items_invoice ON invoice_items(invoice_id)');
    await db.execute('CREATE INDEX idx_invoice_items_product ON invoice_items(product_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  /// Closes the database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
