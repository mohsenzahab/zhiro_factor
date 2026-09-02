import 'package:shamsi_date/shamsi_date.dart';
import 'jalali_utils.dart';

/// Generates unique invoice numbers in the format: INV-YYMM-XXXX
/// where YY = Jalali year (last 2 digits), MM = month, XXXX = sequential counter.
class InvoiceNumberGenerator {
  InvoiceNumberGenerator._();

  /// Generates a new invoice number from the current date and a counter value.
  ///
  /// [counter] is the sequential number of the invoice (from DB max query + 1).
  static String generate(int counter) {
    final now = Jalali.now();
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final seq = counter.toString().padLeft(4, '0');
    return 'INV-$yy$mm-$seq';
  }

  /// Extracts the counter part from an invoice number string.
  static int? extractCounter(String invoiceNumber) {
    try {
      final parts = invoiceNumber.split('-');
      if (parts.length != 3) return null;
      return int.tryParse(parts[2]);
    } catch (_) {
      return null;
    }
  }
}
