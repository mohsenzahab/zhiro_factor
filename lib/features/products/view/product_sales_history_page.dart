import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../data/models/product_model.dart';
import '../../../services/export_service.dart';
import '../../../shared/widgets/date_range_filter_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../invoice/view/widgets/invoice_preview_dialog.dart';
import '../cubit/product_sales_history_cubit.dart';
import '../cubit/product_sales_history_state.dart';

/// Product sales history explorer page.
class ProductSalesHistoryPage extends StatelessWidget {
  final int? productId;
  final VoidCallback onBack;
  final void Function(int invoiceId) onViewInvoice;
  final ProductSalesHistoryCubit? cubit;

  const ProductSalesHistoryPage({
    super.key,
    required this.productId,
    required this.onBack,
    required this.onViewInvoice,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (productId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('کالایی انتخاب نشده است', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_forward),
              label: const Text(AppStrings.backToProducts),
            ),
          ],
        ),
      );
    }

    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _ProductSalesHistoryView(
          onBack: onBack,
          onViewInvoice: onViewInvoice,
        ),
      );
    }

    return BlocProvider(
      create: (_) => ProductSalesHistoryCubit(productId: productId!)..load(),
      child: _ProductSalesHistoryView(
        onBack: onBack,
        onViewInvoice: onViewInvoice,
      ),
    );
  }
}

class _ProductSalesHistoryView extends StatefulWidget {
  final VoidCallback onBack;
  final void Function(int invoiceId) onViewInvoice;

  const _ProductSalesHistoryView({
    required this.onBack,
    required this.onViewInvoice,
  });

  @override
  State<_ProductSalesHistoryView> createState() => _ProductSalesHistoryViewState();
}

class _ProductSalesHistoryViewState extends State<_ProductSalesHistoryView> {
  final _searchCtrl = TextEditingController();
  late final ScrollController _horizontalScrollCtrl;
  late final ScrollController _verticalScrollCtrl;

  @override
  void initState() {
    super.initState();
    _horizontalScrollCtrl = ScrollController();
    _verticalScrollCtrl = ScrollController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _horizontalScrollCtrl.dispose();
    _verticalScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _exportExcel(BuildContext context, ProductSalesHistoryState state) async {
    if (state.product == null || state.sales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('داده‌ای برای خروجی وجود ندارد')),
      );
      return;
    }
    try {
      await ExportService.exportProductSalesExcel(state.product!, state.sales);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فایل اکسل با موفقیت ذخیره شد')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره فایل اکسل: $e')),
        );
      }
    }
  }

  Future<void> _exportCsv(BuildContext context, ProductSalesHistoryState state) async {
    if (state.product == null || state.sales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('داده‌ای برای خروجی وجود ندارد')),
      );
      return;
    }
    try {
      await ExportService.exportProductSalesCsv(state.product!, state.sales);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فایل CSV با موفقیت ذخیره شد')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره فایل CSV: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductSalesHistoryCubit, ProductSalesHistoryState>(
      builder: (context, state) {
        final product = state.product;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Bar ──────────────────────────────────────────────
              _buildHeader(context, state, product),
              const SizedBox(height: 16),

              // ── Summary KPI Cards Row ───────────────────────────────────
              if (product != null) ...[
                _buildSummaryKpiCards(context, state, product),
                const SizedBox(height: 16),
              ],

              // ── Date Range Filter Bar ───────────────────────────────────
              DateRangeFilterBar(
                initialPreset: state.preset,
                initialDateFrom: state.dateFrom,
                initialDateTo: state.dateTo,
                onRangeChanged: ({required preset, dateFrom, dateTo}) {
                  context.read<ProductSalesHistoryCubit>().setDateRange(
                        preset: preset,
                        dateFrom: dateFrom,
                        dateTo: dateTo,
                      );
                },
              ),
              const SizedBox(height: 12),

              // ── Search & Status Filters ─────────────────────────────────
              _buildSearchAndStatusFilters(context, state),
              const SizedBox(height: 16),

              // ── Main Content: Table / Empty / Loading ───────────────────
              Expanded(
                child: _buildBody(context, state, product),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ProductSalesHistoryState state,
    ProductModel? product,
  ) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text(AppStrings.backToProducts),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        const SizedBox(width: 14),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  product != null ? 'تاریخچه فروش «${product.name}»' : AppStrings.productSalesHistory,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (product?.code != null && product!.code!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.dividerDark),
                    ),
                    child: Text(
                      'کد: ${product.code!.toPersianDigits()}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
                if (product?.category != null && product!.category!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      product.category!,
                      style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              AppStrings.productSalesHistorySubtitle,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const Spacer(),
        // Exports & Refresh
        OutlinedButton.icon(
          onPressed: () => _exportCsv(context, state),
          icon: const Icon(Icons.description_outlined, size: 18, color: Colors.blueGrey),
          label: const Text(AppStrings.exportCsv),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _exportExcel(context, state),
          icon: const Icon(Icons.table_chart_outlined, size: 18, color: Colors.green),
          label: const Text(AppStrings.exportExcel),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'بروزرسانی',
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () => context.read<ProductSalesHistoryCubit>().refresh(),
        ),
      ],
    );
  }

  Widget _buildSummaryKpiCards(
    BuildContext context,
    ProductSalesHistoryState state,
    ProductModel product,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            // 1. تعداد فروش (Total Sold)
            Expanded(
              child: _KpiStatCard(
                title: AppStrings.totalSoldLabel,
                value: '${product.totalSoldDisplay} ${product.unit}',
                subtitle: 'فروش در دوره انتخابی: ${state.filteredTotalQuantity.formattedInt} ${product.unit}',
                icon: Icons.point_of_sale_rounded,
                accentColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),

            // 2. باقی مانده در انبار (Remaining Stock)
            Expanded(
              child: _KpiStatCard(
                title: AppStrings.remainingStock,
                value: product.isInfiniteStock ? 'نامحدود' : '${product.stockDisplay} ${product.unit}',
                subtitle: product.isInfiniteStock
                    ? 'موجودی نامحدود'
                    : (product.stock != null && product.stock! <= 0 ? 'اتمام موجودی در انبار' : 'موجود در انبار'),
                icon: Icons.inventory_2_outlined,
                accentColor: product.isInfiniteStock
                    ? AppColors.accent
                    : (product.stock != null && product.stock! <= 0 ? AppColors.error : AppColors.info),
              ),
            ),
            const SizedBox(width: 12),

            // 3. قیمت خرید کنونی (Current Buy Price)
            Expanded(
              child: _KpiStatCard(
                title: AppStrings.currentBuyPriceLabel,
                value: product.effectiveBuyPrice.toman,
                subtitle: 'قیمت خرید اولیه: ${product.buyPrice.toman}',
                icon: Icons.shopping_bag_outlined,
                accentColor: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),

            // 4. قیمت فروش کنونی (Current Sell Price)
            Expanded(
              child: _KpiStatCard(
                title: AppStrings.currentSellPriceLabel,
                value: (product.sellPrice ?? 0).toman,
                subtitle: 'سود واحد: ${product.profitAmountDisplay} (${product.profitPercentDisplay})',
                icon: Icons.sell_outlined,
                accentColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),

            // 5. مجموع فروش دوره (Period Sales)
            Expanded(
              child: _KpiStatCard(
                title: AppStrings.periodSalesTotal,
                value: state.filteredTotalSales.toman,
                subtitle: 'سود دوره: ${state.filteredTotalProfit.toman}',
                icon: Icons.analytics_outlined,
                accentColor: AppColors.accent,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndStatusFilters(
    BuildContext context,
    ProductSalesHistoryState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Row(
        children: [
          // Search Field
          SizedBox(
            width: 280,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) {
                if (_verticalScrollCtrl.hasClients) {
                  _verticalScrollCtrl.jumpTo(0);
                }
                context.read<ProductSalesHistoryCubit>().setSearchQuery(val);
              },
              decoration: InputDecoration(
                hintText: AppStrings.searchCustomerOrInvoice,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchCtrl,
                  builder: (_, v, _) {
                    if (v.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        context.read<ProductSalesHistoryCubit>().setSearchQuery('');
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Status Chips
          const Icon(Icons.filter_list, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 6),
          const Text('وضعیت:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(width: 8),
          _buildStatusChip(context, state, null, 'همه'),
          const SizedBox(width: 6),
          _buildStatusChip(context, state, AppStrings.statusSettled, AppStrings.statusSettled),
          const SizedBox(width: 6),
          _buildStatusChip(context, state, AppStrings.statusPending, AppStrings.statusPending),
          const SizedBox(width: 6),
          _buildStatusChip(context, state, AppStrings.statusDeposit, AppStrings.statusDeposit),
          const SizedBox(width: 6),
          _buildStatusChip(context, state, AppStrings.statusCredit, AppStrings.statusCredit),

          const Spacer(),
          // Row counter badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dividerDark),
            ),
            child: Text(
              '${state.sales.length.formattedInt} ردیف در ${state.filteredInvoiceCount.formattedInt} فاکتور',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    ProductSalesHistoryState state,
    String? status,
    String label,
  ) {
    final isSelected = state.statusFilter == status;
    return InkWell(
      onTap: () => context.read<ProductSalesHistoryCubit>().setStatusFilter(status),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.dividerDark,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProductSalesHistoryState state,
    ProductModel? product,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.read<ProductSalesHistoryCubit>().refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      );
    }

    if (state.sales.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: AppStrings.noProductSalesHistory,
        subtitle: 'برای این کالا در بازه زمانی و فیلترهای انتخابی فاکتوری ثبت نشده است',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        controller: _horizontalScrollCtrl,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalScrollCtrl,
          scrollDirection: Axis.horizontal,
          child: Scrollbar(
            controller: _verticalScrollCtrl,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalScrollCtrl,
              scrollDirection: Axis.vertical,
              child: DataTable(
                headingRowHeight: 48,
                dataRowMinHeight: 46,
                dataRowMaxHeight: 52,
                columnSpacing: 22,
                horizontalMargin: 16,
                headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
                columns: const [
                  DataColumn(label: Text('ردیف')),
                  DataColumn(label: Text(AppStrings.invoiceNumber)),
                  DataColumn(label: Text(AppStrings.invoiceDate)),
                  DataColumn(label: Text(AppStrings.customerName)),
                  DataColumn(label: Text(AppStrings.invoiceStatus)),
                  DataColumn(label: Text(AppStrings.quantity)),
                  DataColumn(label: Text(AppStrings.unitPrice)),
                  DataColumn(label: Text(AppStrings.discountAmount)),
                  DataColumn(label: Text(AppStrings.lineTotal)),
                  DataColumn(label: Text(AppStrings.rowProfit)),
                  DataColumn(label: Text('')), // Actions
                ],
                rows: List.generate(state.sales.length, (index) {
                  final sale = state.sales[index];
                  final isEven = index.isEven;

                  return DataRow(
                    color: WidgetStateProperty.all(
                      isEven ? AppColors.tableRowEven : AppColors.tableRowOdd,
                    ),
                    cells: [
                      // 1. ردیف
                      DataCell(
                        Text('${index + 1}'.toPersianDigits(), style: const TextStyle(fontSize: 12)),
                      ),

                      // 2. شماره فاکتور (Clickable button to navigate directly to the invoice)
                      DataCell(
                        Tooltip(
                          message: '${AppStrings.clickToOpenInvoice} (${sale.invoiceNumber.toPersianDigits()})',
                          child: InkWell(
                            onTap: () => widget.onViewInvoice(sale.invoiceId),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.receipt_long, size: 15, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    sale.invoiceNumber.toPersianDigits(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.open_in_new, size: 13, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 3. تاریخ
                      DataCell(
                        Text(sale.jalaliDate, style: const TextStyle(fontSize: 13)),
                      ),

                      // 4. مشتری
                      DataCell(
                        Tooltip(
                          message: sale.customerPhone != null && sale.customerPhone!.isNotEmpty
                              ? 'تلفن: ${sale.customerPhone!.toPersianDigits()}'
                              : sale.customerDisplay,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_outline, size: 15, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                sale.customerDisplay,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 5. وضعیت فاکتور
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.statusColor(sale.invoiceStatus).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.statusColor(sale.invoiceStatus).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            sale.invoiceStatus,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.statusColor(sale.invoiceStatus),
                            ),
                          ),
                        ),
                      ),

                      // 6. تعداد
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sale.quantityDisplay,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                      // 7. قیمت واحد
                      DataCell(
                        Text(sale.unitPriceDisplay, style: const TextStyle(fontSize: 12)),
                      ),

                      // 8. تخفیف
                      DataCell(
                        sale.discountCalculatedAmount > 0
                            ? Tooltip(
                                message: 'تخفیف: ${sale.discountCalculatedAmount.formatted} تومان',
                                child: Text(
                                  sale.discountCalculatedAmount.formatted,
                                  style: const TextStyle(fontSize: 12, color: AppColors.warning),
                                ),
                              )
                            : const Text('۰', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ),

                      // 9. مبلغ کل سطر
                      DataCell(
                        Text(
                          sale.lineTotalDisplay,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),

                      // 10. سود سطر
                      DataCell(
                        Tooltip(
                          message: 'هزینه خرید: ${(sale.purchasePrice * sale.quantity).formatted} تومان\n'
                              'سود: ${sale.profitAmount.formatted} تومان (${sale.profitPercentage.toStringAsFixed(1).toPersianDigits()}٪)',
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (sale.profitAmount >= 0 ? AppColors.success : AppColors.error)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sale.profitDisplay,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: sale.profitAmount >= 0 ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 11. عملیات
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              color: AppColors.info,
                              tooltip: 'مشاهده و ویرایش فاکتور',
                              onPressed: () => widget.onViewInvoice(sale.invoiceId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 18),
                              color: AppColors.primary,
                              tooltip: 'پیش‌نمایش فاکتور',
                              onPressed: () => InvoicePreviewDialog.showFromId(context, sale.invoiceId),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Internal summary KPI card.
class _KpiStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _KpiStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

