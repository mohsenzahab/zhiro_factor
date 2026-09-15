import 'dart:io';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/constants/app_strings.dart';
import '../core/extensions/number_extensions.dart';
import '../core/utils/jalali_utils.dart';
import '../data/models/invoice_model.dart';
import '../data/repositories/invoice_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../features/invoice/cubit/invoice_state.dart';

/// Data class passed to the background isolate for PDF generation.
class PdfDocumentParams {
  final Uint8List regularFontBytes;
  final Uint8List boldFontBytes;
  final String pageFormat; // 'a4' or 'a5'
  final String businessName;
  final String description;
  final bool showNameOnInvoice;
  final bool showDescriptionOnInvoice;
  final String descriptionPosition;
  final String invoiceNumber;
  final String date;
  final String customerName;
  final String status;
  final String? notes;
  final List<Map<String, dynamic>> items;
  final double totalGross;
  final double totalItemDiscount;
  final double overallDiscountAmount;
  final String overallDiscountType;
  final double overallDiscountValue;
  final double totalDiscount;
  final double totalNet;

  const PdfDocumentParams({
    required this.regularFontBytes,
    required this.boldFontBytes,
    this.pageFormat = 'a4',
    required this.businessName,
    required this.description,
    required this.showNameOnInvoice,
    required this.showDescriptionOnInvoice,
    required this.descriptionPosition,
    required this.invoiceNumber,
    required this.date,
    required this.customerName,
    required this.status,
    required this.notes,
    required this.items,
    required this.totalGross,
    required this.totalItemDiscount,
    required this.overallDiscountAmount,
    required this.overallDiscountType,
    required this.overallDiscountValue,
    required this.totalDiscount,
    required this.totalNet,
  });
}

/// Service for generating and printing invoice PDFs.
class PdfService {
  PdfService._();

  static Uint8List? _cachedRegularBytes;
  static Uint8List? _cachedBoldBytes;

  /// Load font raw bytes once, cached in memory.
  static Future<({Uint8List regular, Uint8List bold})> _loadFontBytes() async {
    if (_cachedRegularBytes != null && _cachedBoldBytes != null) {
      return (regular: _cachedRegularBytes!, bold: _cachedBoldBytes!);
    }

    Uint8List? regular;
    Uint8List? bold;

    // 1. Bundle asset Vazirmatn
    try {
      final regData = await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf');
      regular = regData.buffer.asUint8List();
    } catch (_) {}

    try {
      final boldData = await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf');
      bold = boldData.buffer.asUint8List();
    } catch (_) {}

    // 2. Fallback to Windows system font Tahoma if available
    if (Platform.isWindows && (regular == null || bold == null)) {
      try {
        final winDir = Platform.environment['WINDIR'] ?? r'C:\Windows';
        final tahomaFile = File('$winDir\\Fonts\\tahoma.ttf');
        final tahomabdFile = File('$winDir\\Fonts\\tahomabd.ttf');
        if (await tahomaFile.exists()) {
          regular ??= await tahomaFile.readAsBytes();
        }
        if (await tahomabdFile.exists()) {
          bold ??= await tahomabdFile.readAsBytes();
        }
      } catch (_) {}
    }

    _cachedRegularBytes = regular ?? Uint8List(0);
    _cachedBoldBytes = bold ?? Uint8List(0);

    return (regular: _cachedRegularBytes!, bold: _cachedBoldBytes!);
  }

  /// Generate PDF bytes from an editor state in a background isolate.
  static Future<Uint8List> generateFromState(InvoiceState state, {String? pageFormat}) async {
    final fontBytes = await _loadFontBytes();
    final bizSettings = await SettingsRepository.instance.loadSettings();
    final format = pageFormat ?? bizSettings.defaultPageFormat;

    final jalaliDate = state.date.isNotEmpty
        ? JalaliUtils.format(JalaliUtils.fromIso(state.date))
        : '---';

    final params = PdfDocumentParams(
      regularFontBytes: fontBytes.regular,
      boldFontBytes: fontBytes.bold,
      pageFormat: format,
      businessName: bizSettings.businessName,
      description: bizSettings.description,
      showNameOnInvoice: bizSettings.showNameOnInvoice,
      showDescriptionOnInvoice: bizSettings.showDescriptionOnInvoice,
      descriptionPosition: bizSettings.descriptionPosition,
      invoiceNumber: state.invoiceNumber,
      date: jalaliDate,
      customerName: state.selectedCustomer?.name ?? '---',
      status: state.status,
      notes: state.notes,
      items: state.items.map((item) => {
        'product_name': item.productName,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'discount_calculated_amount': item.discountCalculatedAmount,
        'line_total': item.lineTotal,
      }).toList(),
      totalGross: state.totalGross,
      totalItemDiscount: state.totalItemDiscount,
      overallDiscountAmount: state.overallDiscountAmount,
      overallDiscountType: state.overallDiscountType,
      overallDiscountValue: state.overallDiscountValue,
      totalDiscount: state.totalDiscount,
      totalNet: state.totalNet,
    );

    return compute(_generatePdfInIsolate, params);
  }

  /// Generate PDF bytes from an InvoiceModel in a background isolate.
  static Future<Uint8List> generateFromModel(InvoiceModel invoice, {String? pageFormat}) async {
    InvoiceModel effectiveInvoice = invoice;
    if (effectiveInvoice.items.isEmpty && effectiveInvoice.id != null) {
      final repo = InvoiceRepository();
      final loaded = await repo.getById(effectiveInvoice.id!);
      if (loaded != null && loaded.items.isNotEmpty) {
        effectiveInvoice = loaded;
      }
    }

    final fontBytes = await _loadFontBytes();
    final bizSettings = await SettingsRepository.instance.loadSettings();
    final format = pageFormat ?? bizSettings.defaultPageFormat;

    final jalaliDate = JalaliUtils.format(JalaliUtils.fromIso(effectiveInvoice.date));
    final itemDiscount = (effectiveInvoice.totalDiscount - effectiveInvoice.overallDiscountAmount).clamp(0.0, double.infinity);

    final params = PdfDocumentParams(
      regularFontBytes: fontBytes.regular,
      boldFontBytes: fontBytes.bold,
      pageFormat: format,
      businessName: bizSettings.businessName,
      description: bizSettings.description,
      showNameOnInvoice: bizSettings.showNameOnInvoice,
      showDescriptionOnInvoice: bizSettings.showDescriptionOnInvoice,
      descriptionPosition: bizSettings.descriptionPosition,
      invoiceNumber: effectiveInvoice.invoiceNumber,
      date: jalaliDate,
      customerName: effectiveInvoice.customerName ?? '---',
      status: effectiveInvoice.status,
      notes: effectiveInvoice.notes,
      items: effectiveInvoice.items.map((item) => {
        'product_name': item.productName,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'discount_calculated_amount': item.discountCalculatedAmount,
        'line_total': item.lineTotal,
      }).toList(),
      totalGross: effectiveInvoice.totalGross,
      totalItemDiscount: itemDiscount,
      overallDiscountAmount: effectiveInvoice.overallDiscountAmount,
      overallDiscountType: effectiveInvoice.overallDiscountType,
      overallDiscountValue: effectiveInvoice.overallDiscountValue,
      totalDiscount: effectiveInvoice.totalDiscount,
      totalNet: effectiveInvoice.totalNet,
    );

    return compute(_generatePdfInIsolate, params);
  }

  /// Backward-compatible alias for unit testing.
  @visibleForTesting
  static Future<Uint8List> generateFromModelForTesting(InvoiceModel invoice, {String? pageFormat}) =>
      generateFromModel(invoice, pageFormat: pageFormat);

  /// Quick print an invoice directly from state without opening preview dialog.
  static Future<void> printInvoice(InvoiceState state, {String? pageFormat}) async {
    final pdfData = await generateFromState(state, pageFormat: pageFormat);
    await Printing.layoutPdf(
      name: 'فاکتور_${state.invoiceNumber}',
      onLayout: (_) => pdfData,
    );
  }

  /// Quick print an invoice directly from model without opening preview dialog.
  static Future<void> printInvoiceFromModel(InvoiceModel invoice, {String? pageFormat}) async {
    final pdfData = await generateFromModel(invoice, pageFormat: pageFormat);
    await Printing.layoutPdf(
      name: 'فاکتور_${invoice.invoiceNumber}',
      onLayout: (_) => pdfData,
    );
  }

  /// Print an invoice by loading it from the database.
  static Future<void> printInvoiceById(int invoiceId, {String? pageFormat}) async {
    final repo = InvoiceRepository();
    final invoice = await repo.getById(invoiceId);
    if (invoice == null) return;
    await printInvoiceFromModel(invoice, pageFormat: pageFormat);
  }

  /// Save PDF bytes directly to disk via file picker dialog (bypassing print spooler).
  static Future<String?> savePdfToFile(Uint8List pdfData, {String? defaultFileName}) async {
    final fileName = defaultFileName ?? 'فاکتور_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final outputFilePath = await FilePicker.platform.saveFile(
      dialogTitle: AppStrings.savePdf,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (outputFilePath == null) return null;
    final finalPath = outputFilePath.toLowerCase().endsWith('.pdf') ? outputFilePath : '$outputFilePath.pdf';
    final file = File(finalPath);
    await file.writeAsBytes(pdfData);
    return file.path;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background Isolate Generation (Pure Dart — Runs off Main Thread)
// ─────────────────────────────────────────────────────────────────────────────

Future<Uint8List> _generatePdfInIsolate(PdfDocumentParams params) async {
  pw.Font regular;
  pw.Font bold;

  if (params.regularFontBytes.isNotEmpty) {
    regular = pw.Font.ttf(ByteData.view(params.regularFontBytes.buffer));
  } else {
    regular = pw.Font.helvetica();
  }

  if (params.boldFontBytes.isNotEmpty) {
    bold = pw.Font.ttf(ByteData.view(params.boldFontBytes.buffer));
  } else {
    bold = pw.Font.helveticaBold();
  }

  final fonts = (regular: regular, bold: bold);
  final isA5 = params.pageFormat.toLowerCase() == 'a5';
  final pageFormat = isA5 ? PdfPageFormat.a5 : PdfPageFormat.a4;
  final margin = isA5 ? const pw.EdgeInsets.all(14) : const pw.EdgeInsets.all(24);

  final watermarkName = params.showNameOnInvoice && params.businessName.isNotEmpty
      ? params.businessName
      : 'ژیروفاکتور';

  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(
      base: fonts.regular,
      bold: fonts.bold,
    ),
  );

  final pageTheme = pw.PageTheme(
    pageFormat: pageFormat,
    textDirection: pw.TextDirection.rtl,
    margin: margin,
    buildBackground: (context) => _buildWatermark(fonts, watermarkName, isA5: isA5),
  );

  final descriptionWidget = _buildDescriptionBlock(
    fonts,
    description: params.description,
    showDescription: params.showDescriptionOnInvoice,
    isA5: isA5,
  );

  pdf.addPage(
    pw.MultiPage(
      pageTheme: pageTheme,
      header: (context) {
        if (context.pageNumber == 1) {
          return pw.Container(
            margin: pw.EdgeInsets.only(bottom: isA5 ? 8 : 14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPdfHeader(
                  fonts,
                  invoiceNumber: params.invoiceNumber,
                  date: params.date,
                  customer: params.customerName,
                  status: params.status,
                  businessName: params.businessName,
                  showName: params.showNameOnInvoice,
                  isA5: isA5,
                ),
                if (descriptionWidget != null && params.descriptionPosition == 'top') ...[
                  pw.SizedBox(height: isA5 ? 6 : 8),
                  descriptionWidget,
                ],
              ],
            ),
          );
        }
        return _buildContinuationHeader(
          fonts,
          watermarkName,
          params.invoiceNumber,
          context.pageNumber,
          isA5: isA5,
        );
      },
      footer: (context) => _buildFooter(fonts, context),
      build: (context) {
        final bottomDescription = (params.showDescriptionOnInvoice && params.descriptionPosition == 'bottom')
            ? params.description
            : null;
        final hasLeftContent = (bottomDescription != null && bottomDescription.trim().isNotEmpty) ||
            (params.notes != null && params.notes!.trim().isNotEmpty);

        final totalsBox = _buildTotals(
          font: fonts.regular,
          boldFont: fonts.bold,
          gross: params.totalGross,
          itemDiscount: params.totalItemDiscount,
          overallDiscountAmount: params.overallDiscountAmount,
          overallDiscountType: params.overallDiscountType,
          overallDiscountValue: params.overallDiscountValue,
          totalDiscount: params.totalDiscount,
          net: params.totalNet,
          isA5: isA5,
        );

        return [
          _buildItemsTable(fonts, params.items, isA5: isA5),
          pw.SizedBox(height: isA5 ? 8 : 12),
          // ── Bottom section: Totals (Right) + Description (Left) ──
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // In RTL, 1st child is on the Right: Totals Box
              totalsBox,
              pw.SizedBox(width: isA5 ? 8 : 14),
              // In RTL, 2nd child is on the Left: Description & Notes
              if (hasLeftContent)
                pw.Expanded(
                  child: _buildDescriptionBox(
                    fonts: fonts,
                    description: bottomDescription,
                    notes: params.notes,
                    isA5: isA5,
                  ),
                )
              else
                pw.Spacer(),
            ],
          ),
        ];
      },
    ),
  );

  return pdf.save();
}

pw.Widget _buildWatermark(({pw.Font regular, pw.Font bold}) fonts, String text, {required bool isA5}) {
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
              fontSize: isA5 ? 44 : 72,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey,
            ),
          ),
        ),
      ),
    ),
  );
}

pw.Widget? _buildDescriptionBlock(
  ({pw.Font regular, pw.Font bold}) fonts, {
  required String description,
  required bool showDescription,
  required bool isA5,
}) {
  if (!showDescription || description.isEmpty) return null;

  return pw.Container(
    width: double.infinity,
    padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: isA5 ? 4 : 6),
    child: pw.Text(
      description,
      style: pw.TextStyle(
        font: fonts.regular,
        fontSize: isA5 ? 7.5 : 8.5,
        color: PdfColors.grey700,
        lineSpacing: isA5 ? 3 : 4,
      ),
    ),
  );
}

pw.Widget _buildContinuationHeader(
  ({pw.Font regular, pw.Font bold}) fonts,
  String brandName,
  String invoiceNumber,
  int pageNumber, {
  required bool isA5,
}) {
  return pw.Container(
    margin: pw.EdgeInsets.only(bottom: isA5 ? 6 : 10),
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          '$brandName (ادامه فاکتور)',
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: isA5 ? 8.5 : 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.Text(
          'شماره فاکتور: ${invoiceNumber.toPersianDigits()}  |  صفحه ${pageNumber.toString().toPersianDigits()}',
          style: pw.TextStyle(
            font: fonts.regular,
            fontSize: isA5 ? 7.5 : 9,
            color: PdfColors.grey600,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _buildFooter(({pw.Font regular, pw.Font bold}) fonts, pw.Context context) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 8),
    alignment: pw.Alignment.center,
    child: pw.Text(
      'صفحه ${context.pageNumber.toString().toPersianDigits()} از ${context.pagesCount.toString().toPersianDigits()}',
      style: pw.TextStyle(font: fonts.regular, fontSize: 8, color: PdfColors.grey600),
    ),
  );
}

pw.Widget _buildPdfHeader(
  ({pw.Font regular, pw.Font bold}) fonts, {
  required String invoiceNumber,
  required String date,
  required String customer,
  required String status,
  required String businessName,
  required bool showName,
  required bool isA5,
}) {
  final displayName = showName && businessName.isNotEmpty ? businessName : 'ژیروفاکتور';

  return pw.Container(
    padding: pw.EdgeInsets.all(isA5 ? 9 : 14),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400),
      borderRadius: pw.BorderRadius.circular(isA5 ? 6 : 8),
    ),
    child: pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                displayName,
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: isA5 ? 14 : 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(
              'فاکتور فروش',
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: isA5 ? 11 : 15,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: isA5 ? 6 : 10),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: isA5 ? 4 : 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'شماره فاکتور: ${invoiceNumber.toPersianDigits()}',
              style: pw.TextStyle(font: fonts.regular, fontSize: isA5 ? 8.5 : 10.5),
            ),
            pw.Text(
              'تاریخ: ${date.toPersianDigits()}',
              style: pw.TextStyle(font: fonts.regular, fontSize: isA5 ? 8.5 : 10.5),
            ),
          ],
        ),
        pw.SizedBox(height: isA5 ? 2 : 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'مشتری: $customer',
              style: pw.TextStyle(font: fonts.regular, fontSize: isA5 ? 8.5 : 10.5),
            ),
            pw.Text(
              'وضعیت: $status',
              style: pw.TextStyle(font: fonts.regular, fontSize: isA5 ? 8.5 : 10.5),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _buildItemsTable(
  ({pw.Font regular, pw.Font bold}) fonts,
  List<Map<String, dynamic>> items, {
  required bool isA5,
}) {
  if (items.isEmpty) {
    return pw.Container(
      padding: pw.EdgeInsets.all(isA5 ? 12 : 20),
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        'هیچ کالایی در این فاکتور ثبت نشده است',
        style: pw.TextStyle(
          font: fonts.regular,
          fontSize: isA5 ? 9 : 11,
          color: PdfColors.grey600,
        ),
      ),
    );
  }

  // RTL column order: right → left (جمع سطر، تخفیف، قیمت واحد، تعداد، نام کالا، ردیف)
  return pw.TableHelper.fromTextArray(
    headerStyle: pw.TextStyle(
      font: fonts.bold,
      fontSize: isA5 ? 7.5 : 9.5,
      fontWeight: pw.FontWeight.bold,
    ),
    cellStyle: pw.TextStyle(
      font: fonts.regular,
      fontSize: isA5 ? 7.0 : 9.0,
    ),
    headerAlignment: pw.Alignment.center,
    cellAlignment: pw.Alignment.center,
    cellPadding: isA5
        ? const pw.EdgeInsets.symmetric(horizontal: 2.5, vertical: 3)
        : const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    headerPadding: isA5
        ? const pw.EdgeInsets.symmetric(horizontal: 2.5, vertical: 4)
        : const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
    cellAlignments: {
      0: pw.Alignment.center,
      1: pw.Alignment.center,
      2: pw.Alignment.center,
      3: pw.Alignment.center,
      4: pw.Alignment.centerRight,
      5: pw.Alignment.center,
    },
    columnWidths: isA5
        ? {
            0: const pw.FlexColumnWidth(1.6),
            1: const pw.FlexColumnWidth(1.2),
            2: const pw.FlexColumnWidth(1.6),
            3: const pw.FixedColumnWidth(32),
            4: const pw.FlexColumnWidth(2.8),
            5: const pw.FixedColumnWidth(26),
          }
        : {
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

pw.Widget _buildTotals({
  required pw.Font font,
  required pw.Font boldFont,
  required double gross,
  required double itemDiscount,
  required double overallDiscountAmount,
  required String overallDiscountType,
  required double overallDiscountValue,
  required double totalDiscount,
  required double net,
  required bool isA5,
}) {
  return pw.Container(
    width: isA5 ? 200 : 260,
    padding: pw.EdgeInsets.all(isA5 ? 8 : 12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      children: [
        _totalRow(font, 'جمع کل ناخالص:', gross.toman, fontSize: isA5 ? 8.5 : 10),
        if (itemDiscount > 0 && overallDiscountAmount > 0) ...[
          pw.SizedBox(height: isA5 ? 2 : 4),
          _totalRow(font, 'تخفیف اقلام:', itemDiscount.toman, color: PdfColors.orange, fontSize: isA5 ? 8.5 : 10),
        ],
        if (overallDiscountAmount > 0) ...[
          pw.SizedBox(height: isA5 ? 2 : 4),
          _totalRow(
            font,
            overallDiscountType == 'percentage'
                ? 'تخفیف کلی (${overallDiscountValue.toInt().toString().toPersianDigits()}٪):'
                : 'تخفیف کلی:',
            overallDiscountAmount.toman,
            color: PdfColors.orange,
            fontSize: isA5 ? 8.5 : 10,
          ),
        ],
        if (totalDiscount > 0) ...[
          pw.SizedBox(height: isA5 ? 2 : 4),
          _totalRow(font, 'مجموع تخفیفات:', totalDiscount.toman, color: PdfColors.orange, fontSize: isA5 ? 8.5 : 10),
        ],
        pw.Divider(color: PdfColors.grey300),
        _totalRow(
          boldFont,
          'مبلغ قابل پرداخت:',
          net.toman,
          fontWeight: pw.FontWeight.bold,
          fontSize: isA5 ? 9.5 : 12,
        ),
      ],
    ),
  );
}

pw.Widget _buildDescriptionBox({
  required ({pw.Font regular, pw.Font bold}) fonts,
  required String? description,
  required String? notes,
  required bool isA5,
}) {
  final hasDesc = description != null && description.trim().isNotEmpty;
  final hasNotes = notes != null && notes.trim().isNotEmpty;

  if (!hasDesc && !hasNotes) {
    return pw.SizedBox();
  }

  return pw.Container(
    padding: pw.EdgeInsets.all(isA5 ? 8 : 12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      borderRadius: pw.BorderRadius.circular(6),
      color: PdfColors.grey100,
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        if (hasDesc) ...[
          pw.Text(
            description.trim(),
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: isA5 ? 7.5 : 9.0,
              color: PdfColors.grey800,
              lineSpacing: isA5 ? 2.5 : 3.5,
            ),
          ),
        ],
        if (hasDesc && hasNotes) pw.SizedBox(height: isA5 ? 6 : 8),
        if (hasNotes) ...[
          pw.Text(
            'یادداشت: ${notes.trim()}',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: isA5 ? 7.5 : 9.0,
              color: PdfColors.grey700,
              lineSpacing: isA5 ? 2.5 : 3.5,
            ),
          ),
        ],
      ],
    ),
  );
}

pw.Widget _totalRow(
  pw.Font font,
  String label,
  String value, {
  PdfColor? color,
  pw.FontWeight? fontWeight,
  double? fontSize,
}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize ?? 10,
          fontWeight: fontWeight,
          color: color ?? PdfColors.black,
        ),
      ),
      pw.Text(
        value,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize ?? 10,
          fontWeight: fontWeight,
          color: color ?? PdfColors.black,
        ),
      ),
    ],
  );
}
