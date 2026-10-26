import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../../../data/models/price_change_model.dart';
import '../../../../services/export_service.dart';
import '../../../../shared/widgets/date_range_filter_bar.dart';
import '../../cubit/price_history_cubit.dart';
import '../../cubit/price_history_state.dart';

/// Full-featured modal dialog to view and filter product buy price history.
class PriceHistoryDialog extends StatefulWidget {
  final int? productId;
  final String? productName;

  const PriceHistoryDialog({
    super.key,
    this.productId,
    this.productName,
  });

  static Future<void> show(
    BuildContext context, {
    int? productId,
    String? productName,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider(
        create: (_) => PriceHistoryCubit()
          ..loadHistory(
            productId: productId,
            productName: productName,
          ),
        child: PriceHistoryDialog(
          productId: productId,
          productName: productName,
        ),
      ),
    );
  }

  @override
  State<PriceHistoryDialog> createState() => _PriceHistoryDialogState();
}

class _PriceHistoryDialogState extends State<PriceHistoryDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  String _selectedType = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val, BuildContext context) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<PriceHistoryCubit>().filter(searchQuery: val);
      }
    });
  }

  Future<void> _exportExcel(BuildContext context, List<PriceChangeModel> records) async {
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('داده‌ای برای خروجی اکسل یافت نشد')),
      );
      return;
    }
    try {
      await ExportService.exportPriceHistoryExcel(records);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خروجی اکسل با موفقیت ذخیره شد (${records.length.formattedInt} رکورد)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ذخیره اکسل: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColors.surfaceDark,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.dividerDark),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 1100,
            maxHeight: screenSize.height * 0.9,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const Divider(height: 1, color: AppColors.dividerDark),
              Expanded(
                child: BlocBuilder<PriceHistoryCubit, PriceHistoryState>(
                  builder: (context, state) {
                    if (state is PriceHistoryLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    }
                    if (state is PriceHistoryError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(
                              'خطا در بارگذاری تاریخچه: ${state.message}',
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.tonal(
                              onPressed: () => context.read<PriceHistoryCubit>().refresh(),
                              child: const Text('تلاش مجدد'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (state is PriceHistoryLoaded) {
                      return Column(
                        children: [
                          _buildSummaryCards(state),
                          _buildFilterBar(context, state),
                          const Divider(height: 1, color: AppColors.dividerDark),
                          Expanded(child: _buildTable(context, state)),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              const Divider(height: 1, color: AppColors.dividerDark),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<PriceHistoryCubit, PriceHistoryState>(
      builder: (context, state) {
        String title = AppStrings.priceChangeHistory;
        String subtitle = AppStrings.priceChangeHistorySubtitle;
        bool hasProductFilter = false;

        if (state is PriceHistoryLoaded && state.filterProductId != null) {
          hasProductFilter = true;
          title = '${AppStrings.priceHistoryForProduct}: ${state.filterProductName ?? 'کد ${state.filterProductId}'}';
          subtitle = 'مشاهده سوابق تغییرات قیمت برای این کالا';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: AppColors.cardDarkAlt,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasProductFilter) ...[
                OutlinedButton.icon(
                  onPressed: () => context.read<PriceHistoryCubit>().clearProductFilter(),
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('مشاهده همه کالاها', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                tooltip: AppStrings.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(PriceHistoryLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.cardDark.withValues(alpha: 0.6),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              label: AppStrings.totalPriceChanges,
              value: '${state.totalCount.formattedInt} رکورد',
              icon: Icons.list_alt_rounded,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMetricTile(
              label: AppStrings.averageChangePercent,
              value: state.averagePercent.percentDisplay,
              icon: Icons.percent,
              color: state.averagePercent >= 0 ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMetricTile(
              label: AppStrings.maxIncrease,
              value: state.maxIncreasePercent > 0 ? '+${state.maxIncreasePercent.percentDisplay}' : '۰٪',
              icon: Icons.trending_up_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMetricTile(
              label: AppStrings.maxDecrease,
              value: state.maxDecreasePercent < 0 ? state.maxDecreasePercent.percentDisplay : '۰٪',
              icon: Icons.trending_down_rounded,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, PriceHistoryLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Search input
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'جستجوی نام یا کد کالا...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                context.read<PriceHistoryCubit>().filter(searchQuery: '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (v) => _onSearchChanged(v, context),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Change type filter dropdown
              SizedBox(
                height: 38,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    prefixIcon: Icon(Icons.filter_list, size: 18),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('همه نوع تغییرات', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'manual', child: Text('ویرایش دستی', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'batch_adjustment', child: Text('تغییر گروهی', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'purchase', child: Text('فاکتور خرید', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedType = val);
                      context.read<PriceHistoryCubit>().filter(changeType: val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Refresh button
              IconButton.filledTonal(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'بازخوانی',
                onPressed: () => context.read<PriceHistoryCubit>().refresh(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date range filter presets & picker
          DateRangeFilterBar(
            initialPreset: DateRangePreset.allTime,
            initialDateFrom: state.dateFrom,
            initialDateTo: state.dateTo,
            onRangeChanged: ({required preset, dateFrom, dateTo}) {
              context.read<PriceHistoryCubit>().filter(
                    dateFrom: dateFrom,
                    dateTo: dateTo,
                    clearDates: preset == DateRangePreset.allTime,
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, PriceHistoryLoaded state) {
    final records = state.sortedRecords;

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 56,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              AppStrings.noPriceChangeHistory,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 38,
            dataRowMaxHeight: 46,
            horizontalMargin: 16,
            columnSpacing: 18,
            headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
            columns: [
              const DataColumn(
                label: Text('ردیف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              DataColumn(
                label: _buildSortableHeader('کد کالا', 'code', state),
                onSort: (_, _) => context.read<PriceHistoryCubit>().setSorting('code'),
              ),
              DataColumn(
                label: _buildSortableHeader('نام کالا', 'name', state),
                onSort: (_, _) => context.read<PriceHistoryCubit>().setSorting('name'),
              ),
              const DataColumn(
                label: Text('دسته‌بندی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              DataColumn(
                label: _buildSortableHeader('قیمت قبلی', 'old_price', state),
                numeric: true,
                onSort: (_, _) => context.read<PriceHistoryCubit>().setSorting('old_price'),
              ),
              DataColumn(
                label: _buildSortableHeader('قیمت جدید', 'new_price', state),
                numeric: true,
                onSort: (_, _) => context.read<PriceHistoryCubit>().setSorting('new_price'),
              ),
              DataColumn(
                label: _buildSortableHeader('میزان تغییر', 'amount', state),
                numeric: true,
                onSort: (_, _) => context.read<PriceHistoryCubit>().setSorting('amount'),
              ),
              DataColumn(
                label: _buildSortableHeader('درصد تغییر', 'percent', state),
                numeric: true,
                onSort: (_, _) => context.read<PriceHistoryCubit>().setSorting('percent'),
              ),
              const DataColumn(
                label: Text('نوع تغییر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const DataColumn(
                label: Text('منبع / شرح', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              DataColumn(
                label: _buildSortableHeader('تاریخ و ساعت', 'date', state),
                onSort: (_, _) => context.read<PriceHistoryCubit>().setSorting('date'),
              ),
            ],
            rows: List.generate(records.length, (index) {
              final r = records[index];
              final isEven = index % 2 == 0;
              final rowColor = isEven ? AppColors.tableRowEven : AppColors.tableRowOdd;

              return DataRow(
                color: WidgetStateProperty.all(rowColor),
                cells: [
                  DataCell(Text((index + 1).formattedInt, style: const TextStyle(fontSize: 12))),
                  DataCell(Text(r.productCode?.toPersianDigits() ?? '-', style: const TextStyle(fontSize: 12))),
                  DataCell(
                    Text(
                      r.productName ?? 'کالای حذف‌شده',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: r.productName != null ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                  ),
                  DataCell(Text(r.category ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                  DataCell(Text(r.oldPrice.toman, style: const TextStyle(fontSize: 12))),
                  DataCell(Text(r.newPrice.toman, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  DataCell(
                    Text(
                      r.changeAmountDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: r.isIncrease
                            ? AppColors.success
                            : (r.isDecrease ? AppColors.error : AppColors.textMuted),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (r.isIncrease
                                ? AppColors.success
                                : (r.isDecrease ? AppColors.error : AppColors.textMuted))
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        r.changePercentDisplay,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: r.isIncrease
                              ? AppColors.success
                              : (r.isDecrease ? AppColors.error : AppColors.textMuted),
                        ),
                      ),
                    ),
                  ),
                  DataCell(_buildTypeChip(r.changeType)),
                  DataCell(
                    Text(
                      r.changeSource ?? '-',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                  DataCell(
                    Text(
                      r.createdAtJalaliWithTime,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSortableHeader(String label, String column, PriceHistoryLoaded state) {
    final isSelected = state.sortColumn == column;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          isSelected
              ? (state.isAscending ? Icons.arrow_upward : Icons.arrow_downward)
              : Icons.unfold_more,
          size: 14,
          color: isSelected ? AppColors.primary : AppColors.textMuted,
        ),
      ],
    );
  }

  Widget _buildTypeChip(String changeType) {
    Color bg;
    Color fg;
    String label;

    switch (changeType) {
      case 'manual':
        bg = AppColors.info.withValues(alpha: 0.15);
        fg = AppColors.info;
        label = 'ویرایش دستی';
        break;
      case 'batch_adjustment':
        bg = AppColors.accent.withValues(alpha: 0.15);
        fg = AppColors.accent;
        label = 'تغییر گروهی';
        break;
      case 'purchase':
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
        label = 'فاکتور خرید';
        break;
      default:
        bg = AppColors.dividerDark;
        fg = AppColors.textSecondary;
        label = changeType;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return BlocBuilder<PriceHistoryCubit, PriceHistoryState>(
      builder: (context, state) {
        final records = state is PriceHistoryLoaded ? state.sortedRecords : <PriceChangeModel>[];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Text(
                'تعداد کل رکوردهای نمایش: ${records.length.formattedInt}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: records.isNotEmpty ? () => _exportExcel(context, records) : null,
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('خروجی اکسل'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(AppStrings.close),
              ),
            ],
          ),
        );
      },
    );
  }
}
