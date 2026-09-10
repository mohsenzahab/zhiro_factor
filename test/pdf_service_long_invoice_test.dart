import 'package:flutter_test/flutter_test.dart';
import 'package:sales_box/data/models/invoice_item_model.dart';
import 'package:sales_box/data/models/invoice_model.dart';
import 'package:sales_box/services/pdf_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Generating PDF for long invoice (60 items) does not crash and produces valid bytes', () async {
    final items = List.generate(
      60,
      (i) => InvoiceItemModel(
        invoiceId: 1,
        productId: i + 1,
        productName: 'کالای تستی شماره ${i + 1}',
        quantity: (i + 1).toDouble(),
        unitPrice: 10000.0 * (i + 1),
        discountCalculatedAmount: 500.0,
        lineTotal: 10000.0 * (i + 1) * (i + 1) - 500.0,
      ),
    );

    final invoice = InvoiceModel(
      invoiceNumber: 'INV-1001',
      date: '2026-09-10T11:00:00.000',
      status: 'پرداخت شده',
      totalGross: 50000000,
      totalDiscount: 30000,
      totalNet: 49970000,
      customerName: 'مشتری تست با فاکتور طولانی',
      notes: 'توضیحات فاکتور طولانی چند صفحه‌ای',
      items: items,
    );

    final pdfBytes = await PdfService.generateFromModelForTesting(invoice);

    expect(pdfBytes, isNotNull);
    expect(pdfBytes.length, greaterThan(1000));
  });
}
