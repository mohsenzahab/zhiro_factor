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

    final pdfBytesA4 = await PdfService.generateFromModelForTesting(invoice, pageFormat: 'a4');
    expect(pdfBytesA4, isNotNull);
    expect(pdfBytesA4.length, greaterThan(1000));

    final pdfBytesA5 = await PdfService.generateFromModelForTesting(invoice, pageFormat: 'a5');
    expect(pdfBytesA5, isNotNull);
    expect(pdfBytesA5.length, greaterThan(1000));
  });

  test('Generating PDF for A5 format produces valid bytes', () async {
    final invoice = InvoiceModel(
      invoiceNumber: 'INV-A5',
      date: '2026-09-10T11:00:00.000',
      status: 'پرداخت شده',
      totalGross: 50000,
      totalDiscount: 5000,
      totalNet: 45000,
      customerName: 'تست A5',
      items: [
        InvoiceItemModel(
          invoiceId: 1,
          productName: 'کالای A5',
          quantity: 2,
          unitPrice: 25000,
          discountCalculatedAmount: 5000,
          lineTotal: 45000,
        ),
      ],
    );

    final bytes = await PdfService.generateFromModelForTesting(invoice, pageFormat: 'a5');
    expect(bytes, isNotNull);
    expect(bytes.length, greaterThan(500));
  });
}
