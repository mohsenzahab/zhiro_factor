import 'package:flutter_test/flutter_test.dart';
import 'package:sales_box/data/models/invoice_model.dart';
import 'package:sales_box/data/models/invoice_item_model.dart';
import 'package:sales_box/data/models/invoice_payment_model.dart';
import 'package:sales_box/features/invoice/cubit/invoice_cubit.dart';

void main() {
  group('Invoice Payments & Credit Tests', () {
    test('InvoicePaymentModel toMap and fromMap works correctly', () {
      final payment = InvoicePaymentModel(
        id: 1,
        invoiceId: 10,
        amount: 250000.0,
        date: '2026-10-10T10:00:00Z',
        note: 'کارت به کارت',
      );

      final map = payment.toMap();
      expect(map['id'], 1);
      expect(map['invoice_id'], 10);
      expect(map['amount'], 250000.0);
      expect(map['date'], '2026-10-10T10:00:00Z');
      expect(map['note'], 'کارت به کارت');

      final fromMap = InvoicePaymentModel.fromMap(map);
      expect(fromMap, equals(payment));
    });

    test('InvoiceModel paidAmount and remainingAmount calculate correctly', () {
      final payments = [
        const InvoicePaymentModel(amount: 300000.0, date: '2026-10-10'),
        const InvoicePaymentModel(amount: 200000.0, date: '2026-10-11'),
      ];

      final invoice = InvoiceModel(
        invoiceNumber: 'INV-100',
        date: '2026-10-10',
        status: 'نسیه',
        totalGross: 1000000.0,
        totalDiscount: 0.0,
        totalNet: 1000000.0,
        payments: payments,
      );

      expect(invoice.paidAmount, 500000.0);
      expect(invoice.remainingAmount, 500000.0);
      expect(invoice.isPartiallyPaid, isTrue);
      expect(invoice.isFullyPaid, isFalse);

      // Fully paid scenario
      final fullyPaidInvoice = invoice.copyWith(payments: [
        ...payments,
        const InvoicePaymentModel(amount: 500000.0, date: '2026-10-12'),
      ]);
      expect(fullyPaidInvoice.paidAmount, 1000000.0);
      expect(fullyPaidInvoice.remainingAmount, 0.0);
      expect(fullyPaidInvoice.isFullyPaid, isTrue);
      expect(fullyPaidInvoice.isPartiallyPaid, isFalse);

      // Default settled invoice with empty payments (cash/direct settled)
      const cashSettledInvoice = InvoiceModel(
        invoiceNumber: 'INV-101',
        date: '2026-10-10',
        status: 'تسویه شده',
        totalGross: 500000.0,
        totalDiscount: 0.0,
        totalNet: 500000.0,
        payments: [],
      );
      expect(cashSettledInvoice.paidAmount, 500000.0);
      expect(cashSettledInvoice.remainingAmount, 0.0);
      expect(cashSettledInvoice.isFullyPaid, isTrue);
      expect(cashSettledInvoice.isPartiallyPaid, isFalse);
    });

    test('InvoiceCubit auto-updates status on partial payment and settlement', () {
      final cubit = InvoiceCubit();

      // Add line item: 1,000,000 toman
      cubit.addDetailedItem(const InvoiceItemModel(
        productName: 'تست',
        unitPrice: 1000000.0,
        quantity: 1.0,
        lineTotal: 1000000.0,
      ));

      expect(cubit.state.totalNet, 1000000.0);
      expect(cubit.state.status, 'در انتظار پرداخت');
      expect(cubit.state.paidAmount, 0.0);
      expect(cubit.state.remainingAmount, 1000000.0);

      // Add partial payment of 400,000 -> status changes to 'نسیه'
      cubit.addPayment(const InvoicePaymentModel(
        amount: 400000.0,
        date: '2026-10-10',
        note: 'بیعانه اول',
      ));

      expect(cubit.state.paidAmount, 400000.0);
      expect(cubit.state.remainingAmount, 600000.0);
      expect(cubit.state.status, 'نسیه');

      // Add remaining payment of 600,000 -> status changes to 'تسویه شده'
      cubit.addPayment(const InvoicePaymentModel(
        amount: 600000.0,
        date: '2026-10-11',
        note: 'تسویه نهایی',
      ));

      expect(cubit.state.paidAmount, 1000000.0);
      expect(cubit.state.remainingAmount, 0.0);
      expect(cubit.state.status, 'تسویه شده');

      // Remove last payment -> status reverts back to 'نسیه'
      cubit.removePayment(1);
      expect(cubit.state.paidAmount, 400000.0);
      expect(cubit.state.remainingAmount, 600000.0);
      expect(cubit.state.status, 'نسیه');

      // Remove first payment -> status reverts back to 'در انتظار پرداخت'
      cubit.removePayment(0);
      expect(cubit.state.paidAmount, 0.0);
      expect(cubit.state.remainingAmount, 1000000.0);
      expect(cubit.state.status, 'در انتظار پرداخت');
    });
  });
}
