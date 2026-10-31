import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    Customers,
    Invoices,
    InvoiceItems,
    InvoicePayments,
    PresetTemplates,
    PresetTemplateItems,
    Suppliers,
    Purchases,
    PurchaseItems,
    Demands,
    DemandRequests,
    PriceChangeHistory,
  ],
)
class AppDatabase extends _$AppDatabase {
  static const int currentVersion = 11;
  static const String dbName = 'zhirofactor.db';

  static AppDatabase? _instance;

  /// Global singleton instance for the app.
  static AppDatabase get instance => _instance ??= AppDatabase._();

  /// Allow overriding the singleton for testing.
  static set instance(AppDatabase db) => _instance = db;

  AppDatabase._() : super(_openConnection());

  /// Named constructor for dependency injection and tests (in-memory or custom executor).
  AppDatabase.forTesting(super.e);

  /// Get the full path to the database file.
  static Future<String> getDatabasePath() async {
    final Directory appDir = await getApplicationSupportDirectory();
    return p.join(appDir.path, dbName);
  }

  /// Create an in-memory database instance for testing.
  factory AppDatabase.memory() => AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (db) {
            db.execute('PRAGMA foreign_keys = ON');
          },
        ),
      );

  @override
  int get schemaVersion => currentVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Migration v1 → v2: add is_temporary column to products
          if (from < 2) {
            await m.addColumn(products, products.isTemporary);
          }
          // Migration v2 → v3: add sell_price
          if (from < 3) {
            await m.addColumn(products, products.sellPrice);
          }
          // Migration v3 → v4: add current_buy_price, buy_date, supplier
          if (from < 4) {
            await m.addColumn(products, products.currentBuyPrice);
            await m.addColumn(products, products.buyDate);
            await m.addColumn(products, products.supplier);
          }
          // Migration v4 → v5: add preset template tables
          if (from < 5) {
            await m.createTable(presetTemplates);
            await m.createTable(presetTemplateItems);
          }
          // Migration v5 → v6: add invoice-level overall discount columns
          if (from < 6) {
            await m.addColumn(invoices, invoices.overallDiscountType);
            await m.addColumn(invoices, invoices.overallDiscountValue);
            await m.addColumn(invoices, invoices.overallDiscountAmount);
          }
          // Migration v6 → v7: add suppliers, purchases, and purchase_items tables
          if (from < 7) {
            await m.createTable(suppliers);
            await m.createTable(purchases);
            await m.createTable(purchaseItems);
          }
          // Migration v7 → v8: add purchase_price to invoice_items
          if (from < 8) {
            await m.addColumn(invoiceItems, invoiceItems.purchasePrice);
          }
          // Migration v8 → v9: add invoice_payments table
          if (from < 9) {
            await m.createTable(invoicePayments);
          }
          // Migration v9 → v10: add demands and demand_requests tables
          if (from < 10) {
            await m.createTable(demands);
            await m.createTable(demandRequests);
          }
          // Migration v10 → v11: add price_change_history table
          if (from < 11) {
            await m.createTable(priceChangeHistory);
          }
        },
        beforeOpen: (OpeningDetails details) async {
          // Enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON');

          // Sanitize any empty string codes to NULL so they don't violate UNIQUE constraint
          await customStatement("UPDATE products SET code = NULL WHERE code = ''");
          await customStatement("UPDATE customers SET code = NULL WHERE code = ''");
          await customStatement("UPDATE suppliers SET code = NULL WHERE code = ''");

          // Ensure all existing sell prices are rounded to multiples of 5,000
          await customStatement(
            "UPDATE products SET sell_price = CASE WHEN sell_price <= 0 THEN 0 ELSE MAX(5000, ROUND(sell_price / 5000.0) * 5000) END WHERE sell_price IS NOT NULL",
          );
        },
      );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final Directory appDir = await getApplicationSupportDirectory();
      final String dbPath = p.join(appDir.path, dbName);

      // Perform automatic rolling backup before opening
      await _autoBackup(appDir, dbPath);

      final file = File(dbPath);
      return NativeDatabase.createInBackground(file);
    });
  }

  /// Automatically creates a timestamped backup copy in the backups/ folder.
  /// Retains the last 5 backups to avoid unbounded disk usage.
  static Future<void> _autoBackup(Directory appDir, String dbPath) async {
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) return;
    try {
      final backupDir = Directory(p.join(appDir.path, 'backups'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final backupFile = File(p.join(backupDir.path, 'zhirofactor_backup_$dateStr.db'));
      await dbFile.copy(backupFile.path);

      final backupFiles = backupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.db'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      if (backupFiles.length > 5) {
        for (final oldFile in backupFiles.skip(5)) {
          try {
            await oldFile.delete();
          } catch (_) {}
        }
      }
    } catch (_) {
      // Backup failure must not prevent database opening
    }
  }
}
