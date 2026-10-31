import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../core/extensions/number_extensions.dart';
import '../models/customer_model.dart';

/// Repository for Customer CRUD operations using Drift ORM.
class CustomerRepository {
  final AppDatabase _db;

  CustomerRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  /// Fetch all customers, optionally filtered by search query.
  Future<List<CustomerModel>> getAll({String? query}) async {
    final q = _db.select(_db.customers);

    if (query != null && query.isNotEmpty) {
      final enQuery = query.toEnglishDigits();
      final p1 = '%$query%';
      final p2 = '%$enQuery%';
      if (enQuery != query) {
        q.where((c) =>
            c.name.like(p1) |
            c.phone.like(p1) |
            c.code.like(p1) |
            c.phone.like(p2) |
            c.code.like(p2));
      } else {
        q.where((c) => c.name.like(p1) | c.phone.like(p1) | c.code.like(p1));
      }
    }

    q.orderBy([(c) => OrderingTerm.asc(c.name)]);
    final rows = await q.get();

    return rows
        .map((r) => CustomerModel(
              id: r.id,
              code: r.code,
              name: r.name,
              phone: r.phone,
              address: r.address,
              notes: r.notes,
            ))
        .toList();
  }

  /// Fetch a single customer by ID.
  Future<CustomerModel?> getById(int id) async {
    final row = await (_db.select(_db.customers)..where((c) => c.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return CustomerModel(
      id: row.id,
      code: row.code,
      name: row.name,
      phone: row.phone,
      address: row.address,
      notes: row.notes,
    );
  }

  /// Insert a new customer. Returns the new row ID.
  Future<int> insert(CustomerModel customer) async {
    final cleanCode = (customer.code != null && customer.code!.trim().isNotEmpty) ? customer.code!.trim() : null;
    return await _db.into(_db.customers).insert(
          CustomersCompanion.insert(
            code: Value(cleanCode),
            name: customer.name.trim(),
            phone: Value(customer.phone?.trim()),
            address: Value(customer.address?.trim()),
            notes: Value(customer.notes?.trim()),
          ),
        );
  }

  /// Update an existing customer.
  Future<int> update(CustomerModel customer) async {
    if (customer.id == null) return 0;
    final cleanCode = (customer.code != null && customer.code!.trim().isNotEmpty) ? customer.code!.trim() : null;
    return await (_db.update(_db.customers)..where((c) => c.id.equals(customer.id!))).write(
          CustomersCompanion(
            code: Value(cleanCode),
            name: Value(customer.name.trim()),
            phone: Value(customer.phone?.trim()),
            address: Value(customer.address?.trim()),
            notes: Value(customer.notes?.trim()),
          ),
        );
  }

  /// Delete a customer by ID.
  Future<int> delete(int id) async {
    return await (_db.delete(_db.customers)..where((c) => c.id.equals(id))).go();
  }

  /// Get the next available customer code.
  Future<String> nextCode() async {
    final row = await (_db.select(_db.customers)
          ..where((c) => c.code.like('C%'))
          ..orderBy([(c) => OrderingTerm.desc(c.code)])
          ..limit(1))
        .getSingleOrNull();

    if (row == null || row.code == null) return 'C001';
    final lastCode = row.code!.toEnglishDigits();
    final num = int.tryParse(lastCode.substring(1)) ?? 0;
    return 'C${(num + 1).toString().padLeft(3, '0')}';
  }
}
