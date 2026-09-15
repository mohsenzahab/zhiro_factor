import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../../../data/models/invoice_model.dart';
import '../../../../data/repositories/invoice_repository.dart';
import '../../../../data/repositories/settings_repository.dart';
import '../../../../services/pdf_service.dart';
import '../../cubit/invoice_state.dart';

/// Full-screen or large modal dialog for previewing invoices before printing or saving.
class InvoicePreviewDialog extends StatefulWidget {
  final InvoiceState? state;
  final InvoiceModel? invoice;
  final int? invoiceId;

  const InvoicePreviewDialog({
    super.key,
    this.state,
    this.invoice,
    this.invoiceId,
  }) : assert(state != null || invoice != null || invoiceId != null);

  /// Show dialog from editor state.
  static Future<void> showFromState(BuildContext context, InvoiceState state) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => InvoicePreviewDialog(state: state),
    );
  }

  /// Show dialog from invoice model.
  static Future<void> showFromModel(BuildContext context, InvoiceModel invoice) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => InvoicePreviewDialog(invoice: invoice),
    );
  }

  /// Show dialog by loading invoice ID from database.
  static Future<void> showFromId(BuildContext context, int invoiceId) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => InvoicePreviewDialog(invoiceId: invoiceId),
    );
  }

  @override
  State<InvoicePreviewDialog> createState() => _InvoicePreviewDialogState();
}

class _InvoicePreviewDialogState extends State<InvoicePreviewDialog> {
  String _pageFormat = 'a4';
  Uint8List? _pdfBytes;
  bool _loading = true;
  String? _errorMessage;
  InvoiceModel? _loadedInvoice;

  @override
  void initState() {
    super.initState();
    _initAndGenerate();
  }

  Future<void> _initAndGenerate() async {
    setState(() => _loading = true);
    try {
      final settings = await SettingsRepository.instance.loadSettings();
      _pageFormat = settings.defaultPageFormat;

      final repo = InvoiceRepository();
      if (widget.invoiceId != null) {
        _loadedInvoice = await repo.getById(widget.invoiceId!);
      } else if (widget.invoice != null) {
        if (widget.invoice!.items.isEmpty && widget.invoice!.id != null) {
          _loadedInvoice = await repo.getById(widget.invoice!.id!);
        } else {
          _loadedInvoice = widget.invoice;
        }
      }

      await _generatePdf();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'خطا در بارگذاری پیش‌نمایش: $e';
        });
      }
    }
  }

  Future<void> _generatePdf() async {
    setState(() => _loading = true);
    try {
      Uint8List bytes;
      if (widget.state != null) {
        bytes = await PdfService.generateFromState(widget.state!, pageFormat: _pageFormat);
      } else {
        final inv = _loadedInvoice ?? widget.invoice;
        if (inv == null) throw Exception('فاکتور یافت نشد');
        bytes = await PdfService.generateFromModel(inv, pageFormat: _pageFormat);
      }

      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _loading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'خطا در تولید PDF: $e';
        });
      }
    }
  }

  String get _invoiceNumber {
    if (widget.state != null) return widget.state!.invoiceNumber;
    if (widget.invoice != null) return widget.invoice!.invoiceNumber;
    if (_loadedInvoice != null) return _loadedInvoice!.invoiceNumber;
    return '';
  }

  Future<void> _saveFile() async {
    if (_pdfBytes == null) return;
    try {
      final savedPath = await PdfService.savePdfToFile(
        _pdfBytes!,
        defaultFileName: 'فاکتور_${_invoiceNumber.isNotEmpty ? _invoiceNumber : "جدید"}.pdf',
      );
      if (savedPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.pdfSavedSuccess),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.pdfSaveError}: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _print() async {
    if (_pdfBytes == null) return;
    await Printing.layoutPdf(
      name: 'فاکتور_$_invoiceNumber',
      onLayout: (_) => _pdfBytes!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardDark,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 960,
          height: 820,
          child: Column(
            children: [
              // ── Top Toolbar ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  border: Border(bottom: BorderSide(color: AppColors.dividerDark)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      '${AppStrings.previewInvoice} ${_invoiceNumber.toPersianDigits()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 24),

                    // ── A4 / A5 Format Switcher ────────────────────
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'a4',
                          label: Text(AppStrings.pageFormatA4),
                          icon: Icon(Icons.article_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: 'a5',
                          label: Text(AppStrings.pageFormatA5),
                          icon: Icon(Icons.menu_book_outlined, size: 16),
                        ),
                      ],
                      selected: {_pageFormat},
                      onSelectionChanged: (v) {
                        _pageFormat = v.first;
                        _generatePdf();
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary.withValues(alpha: 0.2);
                          }
                          return AppColors.surfaceDark;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary;
                          }
                          return AppColors.textMuted;
                        }),
                        side: WidgetStateProperty.all(
                          const BorderSide(color: AppColors.dividerDark),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // ── Save PDF directly ──────────────────────────
                    OutlinedButton.icon(
                      onPressed: _pdfBytes == null || _loading ? null : _saveFile,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text(AppStrings.savePdf),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ── Print Button ───────────────────────────────
                    ElevatedButton.icon(
                      onPressed: _pdfBytes == null || _loading ? null : _print,
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text(AppStrings.printInvoice),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ── Close Button ───────────────────────────────
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: AppStrings.close,
                    ),
                  ],
                ),
              ),

              // ── Preview Content ──────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(strokeWidth: 2.5),
                            SizedBox(height: 16),
                            Text(
                              'در حال آماده‌سازی و رندر فاکتور...',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : (_errorMessage != null
                        ? Center(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          )
                        : Directionality(
                            textDirection: TextDirection.ltr, // Viewer toolbar works in LTR
                            child: PdfPreview(
                              build: (format) async => _pdfBytes!,
                              canChangePageFormat: false,
                              canChangeOrientation: false,
                              canDebug: false,
                              allowPrinting: false, // We have our custom button
                              allowSharing: false,  // We have custom save button
                              previewPageMargin: const EdgeInsets.all(16),
                              loadingWidget: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
