import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/extensions/number_extensions.dart';
import '../core/utils/jalali_utils.dart';
import '../data/models/invoice_model.dart';
import '../data/repositories/invoice_repository.dart';
import '../features/invoice/cubit/invoice_state.dart';

/// Service for generating and printing invoice PDFs.
class PdfService {
  PdfService._();

  static pw.Font? _cachedRegularFont;
  static pw.Font? _cachedBoldFont;

  /// Print an invoice from current editor state.
  static Future<void> printInvoice(BuildContext context, InvoiceState state) async {
    final pdfData = await _generateFromState(state);
    await Printing.layoutPdf(onLayout: (_) => pdfData);
  }

  /// Print an invoice by loading it from the database.
  static Future<void> printInvoiceById(BuildContext context, int invoiceId) async {
    final repo = InvoiceRepository();
    final invoice = await repo.getById(invoiceId);
    if (invoice == null) return;
    final pdfData = await _generateFromModel(invoice);
    await Printing.layoutPdf(onLayout: (_) => pdfData);
  }

  static Future<Uint8List> _generateFromState(InvoiceState state) async {
    final fonts = await _loadFonts();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fonts.regular,
        bold: fonts.bold,
      ),
    );

    final jalaliDate = state.date.isNotEmpty
        ? JalaliUtils.format(JalaliUtils.fromIso(state.date))
        : '---';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(24),
        header: (context) {
          if (context.pageNumber == 1) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 14),
              child: _buildPdfHeader(fonts, state.invoiceNumber, jalaliDate,
                  state.selectedCustomer?.name ?? '---', state.status),
            );
          }
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('ژیروفاکتور (ادامه فاکتور)',
                    style: pw.TextStyle(font: fonts.bold, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.Text('شماره فاکتور: ${state.invoiceNumber}  |  صفحه ${context.pageNumber}',
                    style: pw.TextStyle(font: fonts.regular, fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'صفحه ${context.pageNumber} از ${context.pagesCount}',
              style: pw.TextStyle(font: fonts.regular, fontSize: 8, color: PdfColors.grey600),
            ),
          );
        },
        build: (context) {
          return [
            _buildItemsTable(fonts, state.items.map((item) => {
              'product_name': item.productName,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'discount_calculated_amount': item.discountCalculatedAmount,
              'line_total': item.lineTotal,
            }).toList()),
            pw.SizedBox(height: 14),
            _buildTotals(
              font: fonts.regular,
              boldFont: fonts.bold,
              gross: state.totalGross,
              itemDiscount: state.totalItemDiscount,
              overallDiscountAmount: state.overallDiscountAmount,
              overallDiscountType: state.overallDiscountType,
              overallDiscountValue: state.overallDiscountValue,
              totalDiscount: state.totalDiscount,
              net: state.totalNet,
            ),
            if (state.notes != null && state.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Text('یادداشت: ${state.notes}',
                  style: pw.TextStyle(font: fonts.regular, fontSize: 10, color: PdfColors.grey700)),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> _generateFromModel(InvoiceModel invoice) async {
    final fonts = await _loadFonts();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fonts.regular,
        bold: fonts.bold,
      ),
    );

    final jalaliDate = JalaliUtils.format(JalaliUtils.fromIso(invoice.date));
    final itemDiscount = (invoice.totalDiscount - invoice.overallDiscountAmount).clamp(0.0, double.infinity);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(24),
        header: (context) {
          if (context.pageNumber == 1) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 14),
              child: _buildPdfHeader(fonts, invoice.invoiceNumber, jalaliDate,
                  invoice.customerName ?? '---', invoice.status),
            );
          }
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('ژیروفاکتور (ادامه فاکتور)',
                    style: pw.TextStyle(font: fonts.bold, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.Text('شماره فاکتور: ${invoice.invoiceNumber}  |  صفحه ${context.pageNumber}',
                    style: pw.TextStyle(font: fonts.regular, fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'صفحه ${context.pageNumber} از ${context.pagesCount}',
              style: pw.TextStyle(font: fonts.regular, fontSize: 8, color: PdfColors.grey600),
            ),
          );
        },
        build: (context) {
          return [
            _buildItemsTable(fonts, invoice.items.map((item) => {
              'product_name': item.productName,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'discount_calculated_amount': item.discountCalculatedAmount,
              'line_total': item.lineTotal,
            }).toList()),
            pw.SizedBox(height: 14),
            _buildTotals(
              font: fonts.regular,
              boldFont: fonts.bold,
              gross: invoice.totalGross,
              itemDiscount: itemDiscount,
              overallDiscountAmount: invoice.overallDiscountAmount,
              overallDiscountType: invoice.overallDiscountType,
              overallDiscountValue: invoice.overallDiscountValue,
              totalDiscount: invoice.totalDiscount,
              net: invoice.totalNet,
            ),
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Text('یادداشت: ${invoice.notes}',
                  style: pw.TextStyle(font: fonts.regular, fontSize: 10, color: PdfColors.grey700)),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<({pw.Font regular, pw.Font bold})> _loadFonts() async {
    if (_cachedRegularFont != null && _cachedBoldFont != null) {
      return (regular: _cachedRegularFont!, bold: _cachedBoldFont!);
    }

    pw.Font? regular;
    pw.Font? bold;

    // 1. Try bundled assets (fastest & works completely offline)
    try {
      final regData = await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf');
      regular = pw.Font.ttf(regData);
    } catch (_) {}

    try {
      final boldData = await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf');
      bold = pw.Font.ttf(boldData);
    } catch (_) {}

    // 2. Fallback to PdfGoogleFonts
    if (regular == null) {
      try {
        regular = await PdfGoogleFonts.vazirmatnRegular();
      } catch (_) {}
    }
    if (bold == null) {
      try {
        bold = await PdfGoogleFonts.vazirmatnBold();
      } catch (_) {}
    }

    // 3. Fallback to Windows system font (Tahoma)
    if (Platform.isWindows && (regular == null || bold == null)) {
      try {
        final tahoma = File(r'C:\Windows\Fonts\tahoma.ttf');
        if (tahoma.existsSync()) {
          final bytes = tahoma.readAsBytesSync();
          final font = pw.Font.ttf(bytes.buffer.asByteData());
          regular ??= font;
          bold ??= font;
        }
      } catch (_) {}
    }

    // 4. Ultimate fallback
    regular ??= pw.Font.helvetica();
    bold ??= regular;

    _cachedRegularFont = regular;
    _cachedBoldFont = bold;

    return (regular: regular, bold: bold);
  }

  static pw.Widget _buildPdfHeader(
      ({pw.Font regular, pw.Font bold}) fonts, String invoiceNumber, String date, String customer, String status) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('ژیروفاکتور',
                  style: pw.TextStyle(font: fonts.bold, fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text('فاکتور فروش',
                  style: pw.TextStyle(font: fonts.regular, fontSize: 15, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('شماره فاکتور: $invoiceNumber',
                  style: pw.TextStyle(font: fonts.regular, fontSize: 10.5)),
              pw.Text('تاریخ: $date', style: pw.TextStyle(font: fonts.regular, fontSize: 10.5)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('مشتری: $customer', style: pw.TextStyle(font: fonts.regular, fontSize: 10.5)),
              pw.Text('وضعیت: $status', style: pw.TextStyle(font: fonts.regular, fontSize: 10.5)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(({pw.Font regular, pw.Font bold}) fonts, List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Text('هیچ کالایی در این فاکتور ثبت نشده است',
            style: pw.TextStyle(font: fonts.regular, fontSize: 11, color: PdfColors.grey600)),
      );
    }

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(font: fonts.bold, fontSize: 9.5, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(font: fonts.regular, fontSize: 9),
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
      },
      columnWidths: {
        0: const pw.FixedColumnWidth(42),
        1: const pw.FlexColumnWidth(3.2),
        2: const pw.FixedColumnWidth(46),
        3: const pw.FlexColumnWidth(1.6),
        4: const pw.FlexColumnWidth(1.3),
        5: const pw.FlexColumnWidth(1.6),
      },
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      headers: ['ردیف', 'نام کالا', 'تعداد', 'قیمت واحد', 'تخفیف', 'جمع سطر'],
      data: items.asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;
        return [
          '${i + 1}',
          item['product_name']?.toString() ?? '',
          (item['quantity'] as num).toDouble().formattedInt,
          (item['unit_price'] as num).toDouble().formatted,
          (item['discount_calculated_amount'] as num).toDouble().formatted,
          (item['line_total'] as num).toDouble().formatted,
        ];
      }).toList(),
    );
  }

  static pw.Widget _buildTotals({
    required pw.Font font,
    required pw.Font boldFont,
    required double gross,
    required double itemDiscount,
    required double overallDiscountAmount,
    required String overallDiscountType,
    required double overallDiscountValue,
    required double totalDiscount,
    required double net,
  }) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      child: pw.Container(
          width: 260,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            children: [
              _totalRow(font, 'جمع کل ناخالص:', gross.toman),
              if (itemDiscount > 0 && overallDiscountAmount > 0) ...[
                pw.SizedBox(height: 4),
                _totalRow(font, 'تخفیف اقلام:', itemDiscount.toman, color: PdfColors.orange),
              ],
              if (overallDiscountAmount > 0) ...[
                pw.SizedBox(height: 4),
                _totalRow(
                  font,
                  overallDiscountType == 'percentage'
                      ? 'تخفیف کلی (${overallDiscountValue.toInt()}%):'
                      : 'تخفیف کلی:',
                  overallDiscountAmount.toman,
                  color: PdfColors.orange,
                ),
              ],
              if (totalDiscount > 0) ...[
                pw.SizedBox(height: 4),
                _totalRow(font, 'مجموع تخفیفات:', totalDiscount.toman, color: PdfColors.orange),
              ],
              pw.Divider(color: PdfColors.grey300),
              _totalRow(boldFont, 'مبلغ قابل پرداخت:', net.toman,
                  fontWeight: pw.FontWeight.bold, fontSize: 12),
            ],
          ),
        ),
      );
    }

  static pw.Widget _totalRow(pw.Font font, String label, String value,
      {PdfColor? color, pw.FontWeight? fontWeight, double? fontSize}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                font: font,
                fontSize: fontSize ?? 10,
                fontWeight: fontWeight,
                color: color ?? PdfColors.black)),
        pw.Text(value,
            style: pw.TextStyle(
                font: font,
                fontSize: fontSize ?? 10,
                fontWeight: fontWeight,
                color: color ?? PdfColors.black)),
      ],
    );
  }
}
