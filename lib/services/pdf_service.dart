import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/extensions/number_extensions.dart';
import '../core/utils/jalali_utils.dart';
import '../data/models/business_settings_model.dart';
import '../data/models/invoice_model.dart';
import '../data/repositories/invoice_repository.dart';
import '../data/repositories/settings_repository.dart';
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

  /// Generate PDF bytes from an invoice model (exposed for testing).
  @visibleForTesting
  static Future<Uint8List> generateFromModelForTesting(InvoiceModel invoice) =>
      _generateFromModel(invoice);

  static Future<Uint8List> _generateFromState(InvoiceState state) async {
    final fonts = await _loadFonts();
    final bizSettings = await SettingsRepository.instance.loadSettings();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fonts.regular,
        bold: fonts.bold,
      ),
    );

    final jalaliDate = state.date.isNotEmpty
        ? JalaliUtils.format(JalaliUtils.fromIso(state.date))
        : '---';

    final watermarkName = bizSettings.showNameOnInvoice && bizSettings.businessName.isNotEmpty
        ? bizSettings.businessName
        : 'ژیروفاکتور';

    // Description widget (if enabled)
    final descriptionWidget = _buildDescriptionBlock(fonts, bizSettings);

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(24),
      buildBackground: (context) => _buildWatermark(fonts, watermarkName),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (context) {
          if (context.pageNumber == 1) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildPdfHeader(fonts, state.invoiceNumber, jalaliDate,
                      state.selectedCustomer?.name ?? '---', state.status, bizSettings),
                  // Description at top (after header, before items)
                  if (descriptionWidget != null && bizSettings.descriptionPosition == 'top') ...[
                    pw.SizedBox(height: 8),
                    descriptionWidget,
                  ],
                ],
              ),
            );
          }
          return _buildContinuationHeader(fonts, watermarkName, state.invoiceNumber, context.pageNumber);
        },
        footer: (context) => _buildFooter(fonts, context),
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
            // Description at bottom (after totals)
            if (descriptionWidget != null && bizSettings.descriptionPosition == 'bottom') ...[
              pw.SizedBox(height: 14),
              descriptionWidget,
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> _generateFromModel(InvoiceModel invoice) async {
    final fonts = await _loadFonts();
    final bizSettings = await SettingsRepository.instance.loadSettings();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fonts.regular,
        bold: fonts.bold,
      ),
    );

    final jalaliDate = JalaliUtils.format(JalaliUtils.fromIso(invoice.date));
    final itemDiscount = (invoice.totalDiscount - invoice.overallDiscountAmount).clamp(0.0, double.infinity);

    final watermarkName = bizSettings.showNameOnInvoice && bizSettings.businessName.isNotEmpty
        ? bizSettings.businessName
        : 'ژیروفاکتور';

    final descriptionWidget = _buildDescriptionBlock(fonts, bizSettings);

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(24),
      buildBackground: (context) => _buildWatermark(fonts, watermarkName),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (context) {
          if (context.pageNumber == 1) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildPdfHeader(fonts, invoice.invoiceNumber, jalaliDate,
                      invoice.customerName ?? '---', invoice.status, bizSettings),
                  if (descriptionWidget != null && bizSettings.descriptionPosition == 'top') ...[
                    pw.SizedBox(height: 8),
                    descriptionWidget,
                  ],
                ],
              ),
            );
          }
          return _buildContinuationHeader(fonts, watermarkName, invoice.invoiceNumber, context.pageNumber);
        },
        footer: (context) => _buildFooter(fonts, context),
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
            if (descriptionWidget != null && bizSettings.descriptionPosition == 'bottom') ...[
              pw.SizedBox(height: 14),
              descriptionWidget,
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ── Font Loading ────────────────────────────────────────────────────

  static Future<({pw.Font regular, pw.Font bold})> _loadFonts() async {
    if (_cachedRegularFont != null && _cachedBoldFont != null) {
      return (regular: _cachedRegularFont!, bold: _cachedBoldFont!);
    }

    pw.Font? regular;
    pw.Font? bold;

    // 1. Vazirmatn bundled assets (primary — standard Unicode with full Persian & Latin support)
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

    // 4. Fallback to Windows system font (Tahoma)
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

    // 5. Ultimate fallback
    regular ??= pw.Font.helvetica();
    bold ??= regular;

    _cachedRegularFont = regular;
    _cachedBoldFont = bold;

    return (regular: regular, bold: bold);
  }

  // ── PDF Building Blocks ─────────────────────────────────────────────

  /// Build a diagonal watermark with the business name.
  static pw.Widget _buildWatermark(({pw.Font regular, pw.Font bold}) fonts, String text) {
    return pw.FullPage(
      ignoreMargins: true,
      child: pw.Center(
        child: pw.Transform.rotate(
          angle: -math.pi / 6, // ~30 degrees diagonal
          child: pw.Opacity(
            opacity: 0.06,
            child: pw.Text(
              text,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 72,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build description block (no label, just the text).
  static pw.Widget? _buildDescriptionBlock(
      ({pw.Font regular, pw.Font bold}) fonts, BusinessSettingsModel bizSettings) {
    if (!bizSettings.showDescriptionOnInvoice || bizSettings.description.isEmpty) {
      return null;
    }
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        bizSettings.description,
        style: pw.TextStyle(font: fonts.regular, fontSize: 8.5, color: PdfColors.grey700, lineSpacing: 4),
      ),
    );
  }

  /// Continuation header for pages 2+.
  static pw.Widget _buildContinuationHeader(
      ({pw.Font regular, pw.Font bold}) fonts, String brandName, String invoiceNumber, int pageNumber) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('$brandName (ادامه فاکتور)',
              style: pw.TextStyle(font: fonts.bold, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          pw.Text('شماره فاکتور: ${invoiceNumber.toPersianDigits()}  |  صفحه ${pageNumber.toString().toPersianDigits()}',
              style: pw.TextStyle(font: fonts.regular, fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  /// Page footer with page numbers.
  static pw.Widget _buildFooter(({pw.Font regular, pw.Font bold}) fonts, pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      alignment: pw.Alignment.center,
      child: pw.Text(
        'صفحه ${context.pageNumber.toString().toPersianDigits()} از ${context.pagesCount.toString().toPersianDigits()}',
        style: pw.TextStyle(font: fonts.regular, fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  /// Main invoice header (page 1 only).
  static pw.Widget _buildPdfHeader(
      ({pw.Font regular, pw.Font bold}) fonts, String invoiceNumber, String date, String customer, String status, BusinessSettingsModel bizSettings) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          // ── Business name + Invoice title ─────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  bizSettings.showNameOnInvoice && bizSettings.businessName.isNotEmpty
                      ? bizSettings.businessName
                      : 'ژیروفاکتور',
                  style: pw.TextStyle(font: fonts.bold, fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
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
              pw.Text('شماره فاکتور: ${invoiceNumber.toPersianDigits()}',
                  style: pw.TextStyle(font: fonts.regular, fontSize: 10.5)),
              pw.Text('تاریخ: ${date.toPersianDigits()}', style: pw.TextStyle(font: fonts.regular, fontSize: 10.5)),
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

  /// Items table with RTL column order.
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

    // RTL column order: right → left (جمع سطر، تخفیف، قیمت واحد، تعداد، نام کالا، ردیف)
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(font: fonts.bold, fontSize: 9.5, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(font: fonts.regular, fontSize: 9),
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.center,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(1.6),
        1: const pw.FlexColumnWidth(1.3),
        2: const pw.FlexColumnWidth(1.6),
        3: const pw.FixedColumnWidth(46),
        4: const pw.FlexColumnWidth(3.2),
        5: const pw.FixedColumnWidth(42),
      },
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      headers: ['جمع سطر', 'تخفیف', 'قیمت واحد', 'تعداد', 'نام کالا', 'ردیف'],
      data: items.asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;
        return [
          (item['line_total'] as num).toDouble().formatted,
          (item['discount_calculated_amount'] as num).toDouble().formatted,
          (item['unit_price'] as num).toDouble().formatted,
          (item['quantity'] as num).toDouble().formattedInt,
          item['product_name']?.toString() ?? '',
          (i + 1).toString().toPersianDigits(),
        ];
      }).toList(),
    );
  }

  /// Totals summary box (right-aligned for RTL).
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
      alignment: pw.Alignment.centerRight,
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
                      ? 'تخفیف کلی (${overallDiscountValue.toInt().toString().toPersianDigits()}٪):'
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
