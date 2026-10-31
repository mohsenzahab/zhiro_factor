import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../core/extensions/number_extensions.dart';
import '../models/supplier_model.dart';

/// Repository for Supplier CRUD operations using Drift ORM.
class SupplierRepository {
  final AppDatabase _db;

  SupplierRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  /// Fetch all suppliers, optionally filtered by search query.
  Future<List<SupplierModel>> getAll({String? query}) async {
    final q = _db.select(_db.suppliers);

    if (query != null && query.isNotEmpty) {
      final enQuery = query.toEnglishDigits();
      final p1 = '%$query%';
      final p2 = '%$enQuery%';
      if (enQuery != query) {
        q.where((s) =>
            s.name.like(p1) |
            s.phone.like(p1) |
            s.code.like(p1) |
            s.phone.like(p2) |
            s.code.like(p2));
      } else {
        q.where((s) => s.name.like(p1) | s.phone.like(p1) | s.code.like(p1));
      }
    }

    q.orderBy([(s) => OrderingTerm.asc(s.name)]);
    final rows = await q.get();

    return rows
        .map((r) => SupplierModel(
              id: r.id,
              code: r.code,
              name: r.name,
              phone: r.phone,
              address: r.address,
              notes: r.notes,
            ))
        .toList();
  }

  /// Fetch a single supplier by ID.
  Future<SupplierModel?> getById(int id) async {
    final row = await (_db.select(_db.suppliers)..where((s) => s.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return SupplierModel(
      id: row.id,
      code: row.code,
      name: row.name,
      phone: row.phone,
      address: row.address,
      notes: row.notes,
    );
  }

  /// Insert a new supplier. Returns the new row ID.
  Future<int> insert(SupplierModel supplier) async {
    final cleanCode = (supplier.code != null && supplier.code!.trim().isNotEmpty) ? supplier.code!.trim() : null;
    return await _db.into(_db.suppliers).insert(
          SuppliersCompanion.insert(
            code: Value(cleanCode),
            name: supplier.name.trim(),
            phone: Value(supplier.phone?.trim()),
            address: Value(supplier.address?.trim()),
            notes: Value(supplier.notes?.trim()),
          ),
        );
  }

  /// Update an existing supplier.
  Future<int> update(SupplierModel supplier) async {
    if (supplier.id == null) return 0;
    final cleanCode = (supplier.code != null && supplier.code!.trim().isNotEmpty) ? supplier.code!.trim() : null;
    return await (_db.update(_db.suppliers)..where((s) => s.id.equals(supplier.id!))).write(
          SuppliersCompanion(
            code: Value(cleanCode),
            name: Value(supplier.name.trim()),
            phone: Value(supplier.phone?.trim()),
            address: Value(supplier.address?.trim()),
            notes: Value(supplier.notes?.trim()),
          ),
        );
  }

  /// Delete a supplier by ID.
  Future<int> delete(int id) async {
    return await (_db.delete(_db.suppliers)..where((s) => s.id.equals(id))).go();
  }

  /// Get the next available supplier code.
  Future<String> nextCode() async {
    final row = await (_db.select(_db.suppliers)
          ..where((s) => s.code.like('S%'))
          ..orderBy([(s) => OrderingTerm.desc(s.code)])
          ..limit(1))
        .getSingleOrNull();

    if (row == null || row.code == null) return 'S001';
    final lastCode = row.code!.toEnglishDigits();
    final num = int.tryParse(lastCode.substring(1)) ?? 0;
    return 'S${(num + 1).toString().padLeft(3, '0')}';
  }
}
