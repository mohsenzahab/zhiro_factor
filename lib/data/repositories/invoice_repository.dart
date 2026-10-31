import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../core/extensions/number_extensions.dart';
import '../models/invoice_model.dart';
import '../models/invoice_item_model.dart';
import '../models/invoice_payment_model.dart';
import '../models/product_sale_record.dart';

/// Repository for Invoice CRUD with transactional item and payment management using Drift ORM.
class InvoiceRepository {
  final AppDatabase _db;

  InvoiceRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  /// Fetch all invoices with customer name join, optionally filtered.
  Future<List<InvoiceModel>> getAll({
    String? customerQuery,
    String? productQuery,
    String? status,
    String? category,
    String? dateFrom,
    String? dateTo,
  }) async {
    final q = _db.select(_db.invoices).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.invoices.customerId)),
    ]);

    if (customerQuery != null && customerQuery.isNotEmpty) {
      final clean = customerQuery.trim();
      final enQuery = clean.toEnglishDigits();
      final p1 = '%$clean%';
      final p2 = '%$enQuery%';
      if (enQuery != clean) {
        q.where(_db.customers.name.like(p1) |
            _db.invoices.invoiceNumber.like(p1) |
            _db.invoices.invoiceNumber.like(p2));
      } else {
        q.where(_db.customers.name.like(p1) | _db.invoices.invoiceNumber.like(p1));
      }
    }

    if (productQuery != null && productQuery.isNotEmpty) {
      final sub = _db.selectOnly(_db.invoiceItems)
        ..addColumns([_db.invoiceItems.invoiceId])
        ..where(_db.invoiceItems.productName.like('%$productQuery%'));
      q.where(_db.invoices.id.isInQuery(sub));
    }

    if (category != null && category.isNotEmpty) {
      final sub = _db.selectOnly(_db.invoiceItems)
        ..join([
          innerJoin(_db.products, _db.products.id.equalsExp(_db.invoiceItems.productId)),
        ])
        ..where(_db.products.category.equals(category))
        ..addColumns([_db.invoiceItems.invoiceId]);
      q.where(_db.invoices.id.isInQuery(sub));
    }

    if (status != null && status.isNotEmpty) {
      q.where(_db.invoices.status.equals(status));
    }
    if (dateFrom != null && dateFrom.isNotEmpty) {
      q.where(_db.invoices.date.isBiggerOrEqualValue(dateFrom));
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      q.where(_db.invoices.date.isSmallerOrEqualValue(dateTo));
    }

    q.orderBy([
      OrderingTerm.desc(_db.invoices.date),
      OrderingTerm.desc(_db.invoices.id),
    ]);

    final rows = await q.get();
    if (rows.isEmpty) return [];

    final invoicesList = rows.map((r) {
      final inv = r.readTable(_db.invoices);
      final cust = r.readTableOrNull(_db.customers);
      return (inv: inv, customerName: cust?.name);
    }).toList();

    final invoiceIds = invoicesList.map((pair) => pair.inv.id).toList();

    final itemRows = await (_db.select(_db.invoiceItems)
          ..where((i) => i.invoiceId.isIn(invoiceIds))
          ..orderBy([(i) => OrderingTerm.asc(i.id)]))
        .get();

    final itemsByInvoice = <int, List<InvoiceItemModel>>{};
    for (final im in itemRows) {
      final item = InvoiceItemModel(
        id: im.id,
        invoiceId: im.invoiceId,
        productId: im.productId,
        productName: im.productName,
        unitPrice: im.unitPrice,
        purchasePrice: im.purchasePrice,
        quantity: im.quantity,
        discountType: im.discountType,
        discountValue: im.discountValue,
        discountCalculatedAmount: im.discountCalculatedAmount,
        lineTotal: im.lineTotal,
      );
      itemsByInvoice.putIfAbsent(im.invoiceId, () => []).add(item);
    }

    final paymentRows = await (_db.select(_db.invoicePayments)
          ..where((p) => p.invoiceId.isIn(invoiceIds))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.date),
            (tbl) => OrderingTerm.asc(tbl.id),
          ]))
        .get();

    final paymentsByInvoice = <int, List<InvoicePaymentModel>>{};
    for (final pm in paymentRows) {
      final payment = InvoicePaymentModel(
        id: pm.id,
        invoiceId: pm.invoiceId,
        amount: pm.amount,
        date: pm.date,
        note: pm.note,
      );
      paymentsByInvoice.putIfAbsent(pm.invoiceId, () => []).add(payment);
    }

    return invoicesList.map((pair) {
      final inv = pair.inv;
      return InvoiceModel(
        id: inv.id,
        invoiceNumber: inv.invoiceNumber,
        customerId: inv.customerId,
        customerName: pair.customerName,
        date: inv.date,
        status: inv.status ?? 'در انتظار پرداخت',
        totalGross: inv.totalGross,
        totalDiscount: inv.totalDiscount,
        totalNet: inv.totalNet,
        overallDiscountType: inv.overallDiscountType,
        overallDiscountValue: inv.overallDiscountValue,
        overallDiscountAmount: inv.overallDiscountAmount,
        notes: inv.notes,
        items: itemsByInvoice[inv.id] ?? const [],
        payments: paymentsByInvoice[inv.id] ?? const [],
      );
    }).toList();
  }

  /// Fetch a single invoice by ID with all its items and payments.
  Future<InvoiceModel?> getById(int id) async {
    final q = _db.select(_db.invoices).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.invoices.customerId)),
    ])..where(_db.invoices.id.equals(id));

    final rows = await q.get();
    if (rows.isEmpty) return null;

    final inv = rows.first.readTable(_db.invoices);
    final cust = rows.first.readTableOrNull(_db.customers);

    final itemRows = await (_db.select(_db.invoiceItems)
          ..where((i) => i.invoiceId.equals(id))
          ..orderBy([(i) => OrderingTerm.asc(i.id)]))
        .get();

    final items = itemRows
        .map((im) => InvoiceItemModel(
              id: im.id,
              invoiceId: im.invoiceId,
              productId: im.productId,
              productName: im.productName,
              unitPrice: im.unitPrice,
              purchasePrice: im.purchasePrice,
              quantity: im.quantity,
              discountType: im.discountType,
              discountValue: im.discountValue,
              discountCalculatedAmount: im.discountCalculatedAmount,
              lineTotal: im.lineTotal,
            ))
        .toList();

    final paymentRows = await (_db.select(_db.invoicePayments)
          ..where((p) => p.invoiceId.equals(id))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.date),
            (tbl) => OrderingTerm.asc(tbl.id),
          ]))
        .get();

    final payments = paymentRows
        .map((pm) => InvoicePaymentModel(
              id: pm.id,
              invoiceId: pm.invoiceId,
              amount: pm.amount,
              date: pm.date,
              note: pm.note,
            ))
        .toList();

    return InvoiceModel(
      id: inv.id,
      invoiceNumber: inv.invoiceNumber,
      customerId: inv.customerId,
      customerName: cust?.name,
      date: inv.date,
      status: inv.status ?? 'در انتظار پرداخت',
      totalGross: inv.totalGross,
      totalDiscount: inv.totalDiscount,
      totalNet: inv.totalNet,
      overallDiscountType: inv.overallDiscountType,
      overallDiscountValue: inv.overallDiscountValue,
      overallDiscountAmount: inv.overallDiscountAmount,
      notes: inv.notes,
      items: items,
      payments: payments,
    );
  }

  /// Fetch items for a given invoice.
  Future<List<InvoiceItemModel>> getItemsByInvoiceId(int invoiceId) async {
    final rows = await (_db.select(_db.invoiceItems)
          ..where((i) => i.invoiceId.equals(invoiceId))
          ..orderBy([(i) => OrderingTerm.asc(i.id)]))
        .get();

    return rows
        .map((im) => InvoiceItemModel(
              id: im.id,
              invoiceId: im.invoiceId,
              productId: im.productId,
              productName: im.productName,
              unitPrice: im.unitPrice,
              purchasePrice: im.purchasePrice,
              quantity: im.quantity,
              discountType: im.discountType,
              discountValue: im.discountValue,
              discountCalculatedAmount: im.discountCalculatedAmount,
              lineTotal: im.lineTotal,
            ))
        .toList();
  }

  /// Fetch payments for a given invoice.
  Future<List<InvoicePaymentModel>> getPaymentsByInvoiceId(int invoiceId) async {
    final rows = await (_db.select(_db.invoicePayments)
          ..where((p) => p.invoiceId.equals(invoiceId))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.date),
            (tbl) => OrderingTerm.asc(tbl.id),
          ]))
        .get();

    return rows
        .map((pm) => InvoicePaymentModel(
              id: pm.id,
              invoiceId: pm.invoiceId,
              amount: pm.amount,
              date: pm.date,
              note: pm.note,
            ))
        .toList();
  }

  /// Save a new invoice with items and payments in a single transaction.
  /// Automatically deducts purchased quantities from product stock.
  Future<int> insert(InvoiceModel invoice) async {
    return await _db.transaction(() async {
      final invoiceId = await _db.into(_db.invoices).insert(
            InvoicesCompanion.insert(
              invoiceNumber: invoice.invoiceNumber.trim(),
              customerId: Value(invoice.customerId),
              date: invoice.date,
              status: Value(invoice.status),
              totalGross: invoice.totalGross,
              totalDiscount: invoice.totalDiscount,
              totalNet: invoice.totalNet,
              overallDiscountType: Value(invoice.overallDiscountType),
              overallDiscountValue: Value(invoice.overallDiscountValue),
              overallDiscountAmount: Value(invoice.overallDiscountAmount),
              notes: Value(invoice.notes?.trim()),
            ),
          );

      for (final item in invoice.items) {
        await _db.into(_db.invoiceItems).insert(
              InvoiceItemsCompanion.insert(
                invoiceId: invoiceId,
                productId: Value(item.productId),
                productName: item.productName.trim(),
                unitPrice: item.unitPrice,
                purchasePrice: Value(item.purchasePrice),
                quantity: Value(item.quantity),
                discountType: Value(item.discountType),
                discountValue: Value(item.discountValue),
                discountCalculatedAmount: Value(item.discountCalculatedAmount),
                lineTotal: item.lineTotal,
              ),
            );

        if (item.productId != null && item.quantity > 0) {
          await _db.customUpdate(
            'UPDATE products SET stock = stock - ? WHERE id = ? AND stock IS NOT NULL',
            variables: [Variable.withReal(item.quantity), Variable.withInt(item.productId!)],
            updates: {_db.products},
          );
        }
      }

      for (final payment in invoice.payments) {
        await _db.into(_db.invoicePayments).insert(
              InvoicePaymentsCompanion.insert(
                invoiceId: invoiceId,
                amount: payment.amount,
                date: payment.date,
                note: Value(payment.note?.trim()),
              ),
            );
      }

      return invoiceId;
    });
  }

  /// Update an existing invoice, its items, and its payments in a single transaction.
  /// Restores previous items' stock and deducts new items' stock.
  Future<void> update(InvoiceModel invoice) async {
    if (invoice.id == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.invoices)..where((i) => i.id.equals(invoice.id!))).write(
            InvoicesCompanion(
              invoiceNumber: Value(invoice.invoiceNumber.trim()),
              customerId: Value(invoice.customerId),
              date: Value(invoice.date),
              status: Value(invoice.status),
              totalGross: Value(invoice.totalGross),
              totalDiscount: Value(invoice.totalDiscount),
              totalNet: Value(invoice.totalNet),
              overallDiscountType: Value(invoice.overallDiscountType),
              overallDiscountValue: Value(invoice.overallDiscountValue),
              overallDiscountAmount: Value(invoice.overallDiscountAmount),
              notes: Value(invoice.notes?.trim()),
            ),
          );

      // Restore stock for previously saved items
      final oldItems = await (_db.select(_db.invoiceItems)
            ..where((i) => i.invoiceId.equals(invoice.id!)))
          .get();

      for (final oldItem in oldItems) {
        if (oldItem.productId != null && oldItem.quantity > 0) {
          await _db.customUpdate(
            'UPDATE products SET stock = stock + ? WHERE id = ? AND stock IS NOT NULL',
            variables: [Variable.withReal(oldItem.quantity), Variable.withInt(oldItem.productId!)],
            updates: {_db.products},
          );
        }
      }

      // Delete old items and re-insert
      await (_db.delete(_db.invoiceItems)..where((i) => i.invoiceId.equals(invoice.id!))).go();

      for (final item in invoice.items) {
        await _db.into(_db.invoiceItems).insert(
              InvoiceItemsCompanion.insert(
                invoiceId: invoice.id!,
                productId: Value(item.productId),
                productName: item.productName.trim(),
                unitPrice: item.unitPrice,
                purchasePrice: Value(item.purchasePrice),
                quantity: Value(item.quantity),
                discountType: Value(item.discountType),
                discountValue: Value(item.discountValue),
                discountCalculatedAmount: Value(item.discountCalculatedAmount),
                lineTotal: item.lineTotal,
              ),
            );

        if (item.productId != null && item.quantity > 0) {
          await _db.customUpdate(
            'UPDATE products SET stock = stock - ? WHERE id = ? AND stock IS NOT NULL',
            variables: [Variable.withReal(item.quantity), Variable.withInt(item.productId!)],
            updates: {_db.products},
          );
        }
      }

      // Re-insert payments if passed
      if (invoice.payments.isNotEmpty) {
        await (_db.delete(_db.invoicePayments)..where((p) => p.invoiceId.equals(invoice.id!))).go();
        for (final payment in invoice.payments) {
          await _db.into(_db.invoicePayments).insert(
                InvoicePaymentsCompanion.insert(
                  invoiceId: invoice.id!,
                  amount: payment.amount,
                  date: payment.date,
                  note: Value(payment.note?.trim()),
                ),
              );
        }
      }
    });
  }

  /// Add a single payment to an existing invoice directly and update invoice status.
  Future<int> addPayment(InvoicePaymentModel payment) async {
    return await _db.transaction(() async {
      final paymentId = await _db.into(_db.invoicePayments).insert(
            InvoicePaymentsCompanion.insert(
              invoiceId: payment.invoiceId!,
              amount: payment.amount,
              date: payment.date,
              note: Value(payment.note?.trim()),
            ),
          );

      if (payment.invoiceId != null) {
        final inv = await (_db.select(_db.invoices)..where((i) => i.id.equals(payment.invoiceId!))).getSingleOrNull();
        if (inv != null) {
          final totalNet = inv.totalNet;
          final currentStatus = inv.status ?? '';

          final sumExp = _db.invoicePayments.amount.sum();
          final paySumQuery = _db.selectOnly(_db.invoicePayments)
            ..addColumns([sumExp])
            ..where(_db.invoicePayments.invoiceId.equals(payment.invoiceId!));
          final paySumResult = await paySumQuery.getSingle();
          final totalPaid = paySumResult.read(sumExp) ?? 0.0;

          if (totalPaid >= totalNet && currentStatus != 'تسویه شده' && currentStatus != 'لغو شده') {
            await (_db.update(_db.invoices)..where((i) => i.id.equals(payment.invoiceId!))).write(
              const InvoicesCompanion(status: Value('تسویه شده')),
            );
          } else if (totalPaid > 0 && totalPaid < totalNet && (currentStatus == 'در انتظار پرداخت' || currentStatus == 'بیعانه')) {
            await (_db.update(_db.invoices)..where((i) => i.id.equals(payment.invoiceId!))).write(
              const InvoicesCompanion(status: Value('نسیه')),
            );
          }
        }
      }

      return paymentId;
    });
  }

  /// Delete a single payment from an invoice and re-check invoice status.
  Future<void> deletePayment(int paymentId) async {
    await _db.transaction(() async {
      final p = await (_db.select(_db.invoicePayments)..where((tbl) => tbl.id.equals(paymentId))).getSingleOrNull();
      if (p != null) {
        final invId = p.invoiceId;
        await (_db.delete(_db.invoicePayments)..where((tbl) => tbl.id.equals(paymentId))).go();

        final inv = await (_db.select(_db.invoices)..where((i) => i.id.equals(invId))).getSingleOrNull();
        if (inv != null) {
          final totalNet = inv.totalNet;
          final currentStatus = inv.status ?? '';

          final sumExp = _db.invoicePayments.amount.sum();
          final paySumQuery = _db.selectOnly(_db.invoicePayments)
            ..addColumns([sumExp])
            ..where(_db.invoicePayments.invoiceId.equals(invId));
          final paySumResult = await paySumQuery.getSingle();
          final totalPaid = paySumResult.read(sumExp) ?? 0.0;

          if (totalPaid < totalNet && currentStatus == 'تسویه شده') {
            await (_db.update(_db.invoices)..where((i) => i.id.equals(invId))).write(
              InvoicesCompanion(status: Value(totalPaid > 0 ? 'نسیه' : 'در انتظار پرداخت')),
            );
          }
        }
      }
    });
  }

  /// Delete an invoice by ID, restoring items' stock before deleting.
  Future<int> delete(int id) async {
    return await _db.transaction(() async {
      final oldItems = await (_db.select(_db.invoiceItems)..where((i) => i.invoiceId.equals(id))).get();

      for (final oldItem in oldItems) {
        if (oldItem.productId != null && oldItem.quantity > 0) {
          await _db.customUpdate(
            'UPDATE products SET stock = stock + ? WHERE id = ? AND stock IS NOT NULL',
            variables: [Variable.withReal(oldItem.quantity), Variable.withInt(oldItem.productId!)],
            updates: {_db.products},
          );
        }
      }

      await (_db.delete(_db.invoiceItems)..where((i) => i.invoiceId.equals(id))).go();
      await (_db.delete(_db.invoicePayments)..where((p) => p.invoiceId.equals(id))).go();
      return await (_db.delete(_db.invoices)..where((i) => i.id.equals(id))).go();
    });
  }

  /// Get the next invoice counter for generating invoice numbers.
  Future<int> nextCounter() async {
    final maxIdExp = _db.invoices.id.max();
    final query = _db.selectOnly(_db.invoices)..addColumns([maxIdExp]);
    final result = await query.getSingle();
    final maxId = result.read(maxIdExp);
    return (maxId ?? 0) + 1;
  }

  /// Get invoices for a specific customer.
  Future<List<InvoiceModel>> getByCustomerId(int customerId) async {
    final q = _db.select(_db.invoices).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.invoices.customerId)),
    ])
      ..where(_db.invoices.customerId.equals(customerId))
      ..orderBy([OrderingTerm.desc(_db.invoices.date)]);

    final rows = await q.get();

    return rows.map((r) {
      final inv = r.readTable(_db.invoices);
      final cust = r.readTableOrNull(_db.customers);
      return InvoiceModel(
        id: inv.id,
        invoiceNumber: inv.invoiceNumber,
        customerId: inv.customerId,
        customerName: cust?.name,
        date: inv.date,
        status: inv.status ?? 'در انتظار پرداخت',
        totalGross: inv.totalGross,
        totalDiscount: inv.totalDiscount,
        totalNet: inv.totalNet,
        overallDiscountType: inv.overallDiscountType,
        overallDiscountValue: inv.overallDiscountValue,
        overallDiscountAmount: inv.overallDiscountAmount,
        notes: inv.notes,
      );
    }).toList();
  }

  /// Fetch all sales of a specific product with customer and invoice info.
  Future<List<ProductSaleRecord>> getProductSales(
    int productId, {
    String? dateFrom,
    String? dateTo,
    String? status,
    String? query,
  }) async {
    final q = _db.select(_db.invoiceItems).join([
      innerJoin(_db.invoices, _db.invoices.id.equalsExp(_db.invoiceItems.invoiceId)),
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.invoices.customerId)),
      leftOuterJoin(_db.products, _db.products.id.equalsExp(_db.invoiceItems.productId)),
    ])..where(_db.invoiceItems.productId.equals(productId));

    if (dateFrom != null && dateFrom.isNotEmpty) {
      q.where(_db.invoices.date.isBiggerOrEqualValue(dateFrom));
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      q.where(_db.invoices.date.isSmallerOrEqualValue(dateTo));
    }
    if (status != null && status.isNotEmpty && status != 'همه') {
      q.where(_db.invoices.status.equals(status));
    }
    if (query != null && query.trim().isNotEmpty) {
      final clean = query.trim();
      final enQuery = clean.toEnglishDigits();
      final p1 = '%$clean%';
      final p2 = '%$enQuery%';
      if (enQuery != clean) {
        q.where(_db.customers.name.like(p1) |
            _db.invoices.invoiceNumber.like(p1) |
            _db.invoices.invoiceNumber.like(p2));
      } else {
        q.where(_db.customers.name.like(p1) | _db.invoices.invoiceNumber.like(p1));
      }
    }

    q.orderBy([
      OrderingTerm.desc(_db.invoices.date),
      OrderingTerm.desc(_db.invoices.id),
    ]);

    final rows = await q.get();

    return rows.map((r) {
      final ii = r.readTable(_db.invoiceItems);
      final inv = r.readTable(_db.invoices);
      final cust = r.readTableOrNull(_db.customers);
      final prod = r.readTableOrNull(_db.products);

      final buyPriceFallback = (prod?.currentBuyPrice != null && prod!.currentBuyPrice! > 0)
          ? prod.currentBuyPrice!
          : (prod?.buyPrice ?? 0.0);
      final itemPurchasePrice = ii.purchasePrice;
      final effectiveCost = itemPurchasePrice > 0 ? itemPurchasePrice : buyPriceFallback;

      return ProductSaleRecord(
        itemId: ii.id,
        invoiceId: inv.id,
        invoiceNumber: inv.invoiceNumber,
        date: inv.date,
        invoiceStatus: inv.status ?? 'تسویه شده',
        customerId: cust?.id,
        customerName: cust?.name,
        customerPhone: cust?.phone,
        productId: ii.productId ?? productId,
        productName: ii.productName,
        quantity: ii.quantity,
        unitPrice: ii.unitPrice,
        purchasePrice: effectiveCost,
        discountType: ii.discountType,
        discountValue: ii.discountValue,
        discountCalculatedAmount: ii.discountCalculatedAmount,
        lineTotal: ii.lineTotal,
        productUnit: prod?.unit ?? 'عدد',
      );
    }).toList();
  }
}
