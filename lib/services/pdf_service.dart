import 'dart:typed_data';
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
    final font = await _loadFont();
    final pdf = pw.Document();

    final jalaliDate = state.date.isNotEmpty
        ? JalaliUtils.format(JalaliUtils.fromIso(state.date))
        : '---';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(font, state.invoiceNumber, jalaliDate,
                  state.selectedCustomer?.name ?? '---', state.status),
              pw.SizedBox(height: 20),
              _buildItemsTable(font, state.items.map((item) => {
                'product_name': item.productName,
                'quantity': item.quantity,
                'unit_price': item.unitPrice,
                'discount_calculated_amount': item.discountCalculatedAmount,
                'line_total': item.lineTotal,
              }).toList()),
              pw.SizedBox(height: 20),
              _buildTotals(font, state.totalGross, state.totalDiscount, state.totalNet),
              if (state.notes != null && state.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text('یادداشت: ${state.notes}',
                    style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
              ],
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> _generateFromModel(InvoiceModel invoice) async {
    final font = await _loadFont();
    final pdf = pw.Document();

    final jalaliDate = JalaliUtils.format(JalaliUtils.fromIso(invoice.date));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(font, invoice.invoiceNumber, jalaliDate,
                  invoice.customerName ?? '---', invoice.status),
              pw.SizedBox(height: 20),
              _buildItemsTable(font, invoice.items.map((item) => {
                'product_name': item.productName,
                'quantity': item.quantity,
                'unit_price': item.unitPrice,
                'discount_calculated_amount': item.discountCalculatedAmount,
                'line_total': item.lineTotal,
              }).toList()),
              pw.SizedBox(height: 20),
              _buildTotals(font, invoice.totalGross, invoice.totalDiscount, invoice.totalNet),
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text('یادداشت: ${invoice.notes}',
                    style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
              ],
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<pw.Font> _loadFont() async {
    // Try to load a bundled font, fallback to a basic one
    try {
      final fontData = await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf');
      return pw.Font.ttf(fontData);
    } catch (_) {
      // Fallback — the printing package includes basic fonts
      return pw.Font.helvetica();
    }
  }

  static pw.Widget _buildPdfHeader(
      pw.Font font, String invoiceNumber, String date, String customer, String status) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
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
                  style: pw.TextStyle(font: font, fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.Text('فاکتور فروش',
                  style: pw.TextStyle(font: font, fontSize: 16, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('شماره فاکتور: $invoiceNumber',
                  style: pw.TextStyle(font: font, fontSize: 11)),
              pw.Text('تاریخ: $date', style: pw.TextStyle(font: font, fontSize: 11)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('مشتری: $customer', style: pw.TextStyle(font: font, fontSize: 11)),
              pw.Text('وضعیت: $status', style: pw.TextStyle(font: font, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(pw.Font font, List<Map<String, dynamic>> items) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(font: font, fontSize: 10),
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.center,
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
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

  static pw.Widget _buildTotals(pw.Font font, double gross, double discount, double net) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      child: pw.Container(
        width: 250,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          children: [
            _totalRow(font, 'جمع کل ناخالص:', gross.toman),
            pw.SizedBox(height: 4),
            _totalRow(font, 'مجموع تخفیفات:', discount.toman, color: PdfColors.orange),
            pw.Divider(color: PdfColors.grey300),
            _totalRow(font, 'مبلغ خالص پرداختی:', net.toman,
                fontWeight: pw.FontWeight.bold, fontSize: 13),
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
