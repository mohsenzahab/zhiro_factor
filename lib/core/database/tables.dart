import 'package:drift/drift.dart';

// ── 1. Products Table ────────────────────────────────────────────────────────
@TableIndex(name: 'idx_products_code', columns: {#code})
@TableIndex(name: 'idx_products_name', columns: {#name})
@DataClassName('ProductEntry')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().nullable().unique()();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();
  RealColumn get buyPrice => real()();
  RealColumn get currentBuyPrice => real().nullable()();
  RealColumn get sellPrice => real().nullable()();
  TextColumn get unit => text()();
  RealColumn get stock => real().nullable().withDefault(const Constant(0.0))();
  BoolColumn get isTemporary => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get buyDate => text().nullable()();
  TextColumn get supplier => text().nullable()();
}

// ── 2. Customers Table ───────────────────────────────────────────────────────
@TableIndex(name: 'idx_customers_code', columns: {#code})
@TableIndex(name: 'idx_customers_name', columns: {#name})
@DataClassName('CustomerEntry')
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().nullable().unique()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
}

// ── 3. Invoices Table ────────────────────────────────────────────────────────
@TableIndex(name: 'idx_invoices_number', columns: {#invoiceNumber})
@TableIndex(name: 'idx_invoices_customer', columns: {#customerId})
@TableIndex(name: 'idx_invoices_date', columns: {#date})
@TableIndex(name: 'idx_invoices_status', columns: {#status})
@DataClassName('InvoiceEntry')
class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text().unique()();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  TextColumn get date => text()();
  TextColumn get status => text().nullable()();
  RealColumn get totalGross => real()();
  RealColumn get totalDiscount => real()();
  RealColumn get totalNet => real()();
  TextColumn get overallDiscountType => text().withDefault(const Constant('none'))();
  RealColumn get overallDiscountValue => real().withDefault(const Constant(0.0))();
  RealColumn get overallDiscountAmount => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
}

// ── 4. Invoice Items Table ───────────────────────────────────────────────────
@TableIndex(name: 'idx_invoice_items_invoice', columns: {#invoiceId})
@TableIndex(name: 'idx_invoice_items_product', columns: {#productId})
@DataClassName('InvoiceItemEntry')
class InvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(Invoices, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().nullable().references(Products, #id)();
  TextColumn get productName => text()();
  RealColumn get unitPrice => real()();
  RealColumn get purchasePrice => real().withDefault(const Constant(0.0))();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  TextColumn get discountType => text().withDefault(const Constant('none'))();
  RealColumn get discountValue => real().withDefault(const Constant(0.0))();
  RealColumn get discountCalculatedAmount => real().withDefault(const Constant(0.0))();
  RealColumn get lineTotal => real()();
}

// ── 5. Invoice Payments Table ────────────────────────────────────────────────
@TableIndex(name: 'idx_invoice_payments_invoice', columns: {#invoiceId})
@TableIndex(name: 'idx_invoice_payments_date', columns: {#date})
@DataClassName('InvoicePaymentEntry')
class InvoicePayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(Invoices, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();
  TextColumn get date => text()();
  TextColumn get note => text().nullable()();
}

// ── 6. Preset Templates Table ────────────────────────────────────────────────
@DataClassName('PresetTemplateEntry')
class PresetTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get createdAt => text().nullable()();
}

// ── 7. Preset Template Items Table ───────────────────────────────────────────
@TableIndex(name: 'idx_preset_items_template', columns: {#templateId})
@DataClassName('PresetTemplateItemEntry')
class PresetTemplateItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(PresetTemplates, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().nullable()();
  TextColumn get productName => text()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  RealColumn get unitPrice => real().withDefault(const Constant(0.0))();
}

// ── 8. Suppliers Table ───────────────────────────────────────────────────────
@TableIndex(name: 'idx_suppliers_code', columns: {#code})
@TableIndex(name: 'idx_suppliers_name', columns: {#name})
@DataClassName('SupplierEntry')
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().nullable().unique()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
}

// ── 9. Purchases Table ───────────────────────────────────────────────────────
@TableIndex(name: 'idx_purchases_number', columns: {#purchaseNumber})
@TableIndex(name: 'idx_purchases_supplier', columns: {#supplierId})
@TableIndex(name: 'idx_purchases_date', columns: {#date})
@DataClassName('PurchaseEntry')
class Purchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get purchaseNumber => text().unique()();
  IntColumn get supplierId => integer().nullable().references(Suppliers, #id)();
  TextColumn get date => text()();
  TextColumn get status => text().nullable()();
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  RealColumn get shippingCost => real().withDefault(const Constant(0.0))();
  RealColumn get extraCosts => real().withDefault(const Constant(0.0))();
  RealColumn get totalNet => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
}

// ── 10. Purchase Items Table ─────────────────────────────────────────────────
@TableIndex(name: 'idx_purchase_items_purchase', columns: {#purchaseId})
@TableIndex(name: 'idx_purchase_items_product', columns: {#productId})
@DataClassName('PurchaseItemEntry')
class PurchaseItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseId => integer().references(Purchases, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().nullable().references(Products, #id)();
  TextColumn get productName => text()();
  RealColumn get unitPrice => real()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  RealColumn get lineTotal => real()();
}

// ── 11. Demands Table ────────────────────────────────────────────────────────
@TableIndex(name: 'idx_demands_status', columns: {#status})
@TableIndex(name: 'idx_demands_category', columns: {#category})
@DataClassName('DemandEntry')
class Demands extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get category => text().nullable()();
  RealColumn get buyPrice => real().nullable()();
  RealColumn get sellPrice => real().nullable()();
  TextColumn get status => text().withDefault(const Constant('تهیه نشده'))();
  RealColumn get targetQuantity => real().withDefault(const Constant(1.0))();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
}

// ── 12. Demand Requests Table ────────────────────────────────────────────────
@TableIndex(name: 'idx_demand_requests_demand', columns: {#demandId})
@TableIndex(name: 'idx_demand_requests_date', columns: {#requestDate})
@DataClassName('DemandRequestEntry')
class DemandRequests extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get demandId => integer().references(Demands, #id, onDelete: KeyAction.cascade)();
  TextColumn get requestDate => text()();
  TextColumn get note => text().nullable()();
}

// ── 13. Price Change History Table ───────────────────────────────────────────
@TableIndex(name: 'idx_price_history_product', columns: {#productId})
@TableIndex(name: 'idx_price_history_date', columns: {#createdAt})
@DataClassName('PriceChangeEntry')
class PriceChangeHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id, onDelete: KeyAction.cascade)();
  RealColumn get oldPrice => real()();
  RealColumn get newPrice => real()();
  RealColumn get changeAmount => real()();
  TextColumn get changeType => text()();
  TextColumn get changeSource => text().nullable()();
  TextColumn get createdAt => text()();
}

