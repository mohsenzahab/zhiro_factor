import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../data/models/demand_model.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../cubit/demand_cubit.dart';
import '../cubit/demand_state.dart';
import 'widgets/demand_form_dialog.dart';
import 'widgets/demand_history_dialog.dart';

/// Demands / Wishlist management page.
class DemandsPage extends StatelessWidget {
  const DemandsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DemandCubit()..loadDemands(),
      child: const _DemandsView(),
    );
  }
}

class _DemandsView extends StatefulWidget {
  const _DemandsView();

  @override
  State<_DemandsView> createState() => _DemandsViewState();
}

class _DemandsViewState extends State<_DemandsView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddDialog(BuildContext context, DemandState state) async {
    final cubit = context.read<DemandCubit>();
    final newDemand = await DemandFormDialog.show(
      context,
      availableCategories: state.availableCategories,
    );

    if (newDemand != null) {
      final success = await cubit.addDemand(
        newDemand,
        initialCount: newDemand.requestCount,
        initialDate: newDemand.firstRequestDate,
      );
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('نیازمندی با موفقیت افزوده شد'),
            backgroundColor: AppColors.statusSettled,
          ),
        );
      }
    }
  }

  void _openEditDialog(BuildContext context, DemandModel demand, DemandState state) async {
    final cubit = context.read<DemandCubit>();
    final updated = await DemandFormDialog.show(
      context,
      demand: demand,
      availableCategories: state.availableCategories,
    );

    if (updated != null) {
      final success = await cubit.updateDemand(updated);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('نیازمندی با موفقیت به‌روزرسانی شد'),
            backgroundColor: AppColors.statusSettled,
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, DemandModel demand) async {
    final cubit = context.read<DemandCubit>();
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'حذف نیازمندی',
      message: 'آیا از حذف نیازمندی «${demand.title}» و کلیه سوابق درخواست‌های آن اطمینان دارید؟',
      confirmLabel: 'حذف',
    );

    if (confirmed == true && demand.id != null) {
      final success = await cubit.deleteDemand(demand.id!);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('نیازمندی حذف شد'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _confirmConvertToProduct(BuildContext context, DemandModel demand) async {
    final cubit = context.read<DemandCubit>();
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'تبدیل به کالای موجود در انبار',
      message: 'کالای «${demand.title}» با موجودی ${demand.targetQuantity.formatted} عدد به فهرست رسمی کالاهای فروشگاه اضافه خواهد شد و وضعیت نیازمندی به «تهیه شده» تغییر می‌کند. ادامه می‌دهید؟',
      confirmLabel: 'تبدیل و ثبت در کالاها',
    );

    if (confirmed == true) {
      final productId = await cubit.convertToProduct(demand);
      if (context.mounted && productId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('کالا با موفقیت به انبار افزوده شد و وضعیت نیازمندی به «تهیه شده» تغییر یافت'),
            backgroundColor: AppColors.statusSettled,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DemandCubit, DemandState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Title & Add Button ───────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.checklist_rtl, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'لیست نیازمندی‌ها (کالاهای درخواستی مشتریان)',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'ثبت کالاها و خدماتی که مشتریان متقاضی آن بوده‌اند تا بر اساس میزان تقاضا و سود تهیه شوند',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openAddDialog(context, state),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('افزودن نیازمندی'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── KPI Summary Cards ───────────────────────────────
              _buildKpiSummaryRow(state),
              const SizedBox(height: 20),

              // ── Filter Bar & Search ─────────────────────────────
              _buildFilterBar(context, state),
              const SizedBox(height: 16),

              // ── Demands List ────────────────────────────────────
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.demands.isEmpty
                        ? const EmptyState(
                            icon: Icons.checklist_rtl_outlined,
                            title: 'هیچ نیازمندی ثبت نشده است',
                          )
                        : _buildDemandList(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiSummaryRow(DemandState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 36) / 4;
        return Row(
          children: [
            // 1. Total Demands & Requests
            _KpiCard(
              width: cardWidth,
              title: 'کل اقلام و تقاضاها',
              value: '${state.totalDemandsCount.toString().toPersianDigits()} مورد',
              subtitle: '${state.totalRequestsCount.toString().toPersianDigits()} بار درخواست مشتریان',
              icon: Icons.playlist_add_check,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),

            // 2. Total Required Capital
            _KpiCard(
              width: cardWidth,
              title: 'سرمایه مورد نیاز',
              value: state.totalRequiredCapital.toman,
              subtitle: 'جهت تأمین ${state.activeDemands.length.toString().toPersianDigits()} مورد تهیه نشده',
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.warning,
            ),
            const SizedBox(width: 12),

            // 3. Projected Total Profit
            _KpiCard(
              width: cardWidth,
              title: 'سود کل پیش‌بینی شده',
              value: state.totalProjectedProfit.toman,
              subtitle: 'از فروش اقلام در حال تهیه و تهیه نشده',
              icon: Icons.trending_up,
              color: AppColors.accent,
            ),
            const SizedBox(width: 12),

            // 4. Top Demanded Item
            _KpiCard(
              width: cardWidth,
              title: 'پرتقاضاترین مورد',
              value: state.topDemandedItem?.title ?? '---',
              subtitle: state.topDemandedItem != null
                  ? '${state.topDemandedItem!.requestCount.toString().toPersianDigits()} بار درخواست (${state.topDemandedItem!.averageRequestsPerMonthDisplay})'
                  : 'بدون تقاضا',
              icon: Icons.star_outline,
              color: const Color(0xFFFF9800),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(BuildContext context, DemandState state) {
    final cubit = context.read<DemandCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Row & Search & Sort
        Row(
          children: [
            // Status segmented pills
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.dividerDark),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusFilterPill(
                    label: 'همه',
                    count: state.demands.length,
                    isSelected: state.statusFilter == null,
                    onTap: () => cubit.setStatusFilter(null),
                  ),
                  _StatusFilterPill(
                    label: DemandModel.statusPending,
                    count: state.pendingCount,
                    color: AppColors.warning,
                    isSelected: state.statusFilter == DemandModel.statusPending,
                    onTap: () => cubit.setStatusFilter(DemandModel.statusPending),
                  ),
                  _StatusFilterPill(
                    label: DemandModel.statusInPreparation,
                    count: state.inPreparationCount,
                    color: AppColors.info,
                    isSelected: state.statusFilter == DemandModel.statusInPreparation,
                    onTap: () => cubit.setStatusFilter(DemandModel.statusInPreparation),
                  ),
                  _StatusFilterPill(
                    label: DemandModel.statusProcured,
                    count: state.procuredCount,
                    color: AppColors.statusSettled,
                    isSelected: state.statusFilter == DemandModel.statusProcured,
                    onTap: () => cubit.setStatusFilter(DemandModel.statusProcured),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Search Field
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => cubit.setSearchQuery(v),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'جستجوی نام کالا/خدمت یا یادداشت...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              cubit.setSearchQuery(null);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.dividerDark),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.dividerDark),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Sort Selector
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.dividerDark),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: state.sortBy,
                  icon: const Icon(Icons.sort, size: 18, color: AppColors.textMuted),
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  dropdownColor: AppColors.cardDark,
                  items: const [
                    DropdownMenuItem(value: 'demandCount', child: Text('بیشترین تقاضا')),
                    DropdownMenuItem(value: 'newest', child: Text('جدیدترین درخواست')),
                    DropdownMenuItem(value: 'profit', child: Text('بیشترین سود پیش‌بینی شده')),
                    DropdownMenuItem(value: 'capital', child: Text('بیشترین سرمایه مورد نیاز')),
                    DropdownMenuItem(value: 'title', child: Text('نام کالا (الفبا)')),
                  ],
                  onChanged: (val) {
                    if (val != null) cubit.setSortBy(val);
                  },
                ),
              ),
            ),
          ],
        ),

        // Category Filter Chips
        if (state.availableCategories.isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.category_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                const Text('دسته‌بندی:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'همه',
                  isSelected: state.categoryFilter == null,
                  onTap: () => cubit.setCategoryFilter(null),
                ),
                const SizedBox(width: 6),
                ...state.availableCategories.map((cat) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _CategoryChip(
                        label: cat,
                        isSelected: state.categoryFilter == cat,
                        onTap: () => cubit.setCategoryFilter(cat),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDemandList(BuildContext context, DemandState state) {
    return ListView.builder(
      itemCount: state.demands.length,
      itemBuilder: (context, index) {
        final demand = state.demands[index];
        return _DemandCard(
          key: ValueKey('demand_${demand.id}'),
          demand: demand,
          onEdit: () => _openEditDialog(context, demand, state),
          onDelete: () => _confirmDelete(context, demand),
          onConvertToProduct: () => _confirmConvertToProduct(context, demand),
        );
      },
    );
  }
}

/// Rich, interactive card for an individual demand item.
class _DemandCard extends StatelessWidget {
  final DemandModel demand;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onConvertToProduct;

  const _DemandCard({
    super.key,
    required this.demand,
    required this.onEdit,
    required this.onDelete,
    required this.onConvertToProduct,
  });

  Color _statusColor(String status) {
    switch (status) {
      case DemandModel.statusPending:
        return AppColors.warning;
      case DemandModel.statusInPreparation:
        return AppColors.info;
      case DemandModel.statusProcured:
        return AppColors.statusSettled;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DemandCubit>();
    final statusColor = _statusColor(demand.status);
    final hasBuy = demand.buyPrice != null && demand.buyPrice! > 0;
    final hasSell = demand.sellPrice != null && demand.sellPrice! > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: demand.status == DemandModel.statusInPreparation
              ? AppColors.info.withValues(alpha: 0.3)
              : AppColors.dividerDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Title, Category, Status Badge & Actions ─────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              Expanded(
                child: Row(
                  children: [
                    Text(
                      demand.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (demand.category != null && demand.category!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.dividerDark),
                        ),
                        child: Text(
                          demand.category!,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Status Dropdown Menu
              PopupMenuButton<String>(
                tooltip: 'تغییر وضعیت',
                initialValue: demand.status,
                onSelected: (newStatus) {
                  if (demand.id != null) cubit.updateStatus(demand.id!, newStatus);
                },
                itemBuilder: (context) => DemandModel.allStatuses.map((st) {
                  final col = _statusColor(st);
                  return PopupMenuItem(
                    value: st,
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: col),
                        const SizedBox(width: 8),
                        Text(st, style: TextStyle(fontSize: 12, color: col, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        demand.status,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 16, color: statusColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Convert to Product Button
              IconButton(
                icon: const Icon(Icons.inventory_2_outlined, size: 18),
                color: AppColors.accent,
                tooltip: 'تبدیل به کالا در انبار',
                onPressed: onConvertToProduct,
              ),

              // Edit Button
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.info,
                tooltip: 'ویرایش نیازمندی',
                onPressed: onEdit,
              ),

              // Delete Button
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.error,
                tooltip: 'حذف',
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Row 2: Customer Request Counter & Timeline Stats ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.dividerDark),
            ),
            child: Row(
              children: [
                // Quick + and - counter buttons
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.dividerDark),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minus button
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        color: demand.requestCount > 1 ? AppColors.warning : AppColors.textMuted,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        tooltip: 'کاهش آخرین درخواست',
                        onPressed: demand.requestCount > 1 && demand.id != null
                            ? () async {
                                final removed = await cubit.decrementRequest(demand.id!);
                                if (!removed && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('حداقل یک تاریخ درخواست باید حفظ شود'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              }
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '${demand.requestCount.toString().toPersianDigits()} درخواست',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                        ),
                      ),
                      // Plus button
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        color: AppColors.primary,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        tooltip: 'ثبت تقاضای جدید (+۱)',
                        onPressed: demand.id != null
                            ? () {
                                cubit.incrementRequest(demand.id!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('یک تقاضای جدید برای «${demand.title}» ثبت شد'),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Timeline stats: Earliest, Latest, Average monthly
                if (demand.firstRequestDate != null) ...[
                  _MetaTag(
                    icon: Icons.first_page,
                    label: 'اولین: ${JalaliUtils.formatIso(demand.firstRequestDate!)}',
                  ),
                  const SizedBox(width: 10),
                ],
                if (demand.latestRequestDate != null) ...[
                  _MetaTag(
                    icon: Icons.last_page,
                    label: 'آخرین: ${JalaliUtils.formatIso(demand.latestRequestDate!)}',
                  ),
                  const SizedBox(width: 10),
                ],
                _MetaTag(
                  icon: Icons.speed,
                  label: 'میانگین: ${demand.averageRequestsPerMonthDisplay}',
                  highlightColor: AppColors.info,
                ),
                const Spacer(),

                // Full dates history button
                TextButton.icon(
                  onPressed: () => DemandHistoryDialog.show(context, demand: demand, cubit: cubit),
                  icon: const Icon(Icons.calendar_month_outlined, size: 15),
                  label: const Text('مشاهده تاریخ‌ها', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Row 3: Financial & Procurement Metrics ──────────────
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Target quantity
              _FinancialMetric(
                label: 'تعداد هدف خرید:',
                value: '${demand.targetQuantity.formatted} عدد',
                color: AppColors.textPrimary,
              ),

              // Buy price
              _FinancialMetric(
                label: 'قیمت خرید:',
                value: hasBuy ? demand.buyPrice!.toman : 'تعیین نشده',
                color: hasBuy ? AppColors.textPrimary : AppColors.textMuted,
              ),

              // Sell price
              _FinancialMetric(
                label: 'قیمت فروش:',
                value: hasSell ? demand.sellPrice!.toman : 'تعیین نشده',
                color: hasSell ? AppColors.textPrimary : AppColors.textMuted,
              ),

              // Required capital
              _FinancialMetric(
                label: 'سرمایه مورد نیاز:',
                value: demand.requiredCapital > 0 ? demand.requiredCapital.toman : '---',
                color: demand.requiredCapital > 0 ? AppColors.warning : AppColors.textMuted,
                isBold: true,
              ),

              // Unit profit
              if (demand.unitProfit != null)
                _FinancialMetric(
                  label: 'سود واحد:',
                  value: '${demand.unitProfit!.toman} (${demand.profitMargin?.toStringAsFixed(1).toPersianDigits()}٪)',
                  color: demand.unitProfit! >= 0 ? AppColors.accent : AppColors.error,
                ),

              // Total projected profit
              if (demand.totalProjectedProfit != null)
                _FinancialMetric(
                  label: 'سود کل پیش‌بینی شده:',
                  value: demand.totalProjectedProfit!.toman,
                  color: demand.totalProjectedProfit! >= 0 ? AppColors.accent : AppColors.error,
                  isBold: true,
                ),
            ],
          ),

          // Notes
          if (demand.notes != null && demand.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.notes, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    demand.notes!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? highlightColor;

  const _MetaTag({required this.icon, required this.label, this.highlightColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: highlightColor ?? AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: highlightColor ?? AppColors.textMuted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _FinancialMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _FinancialMetric({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatusFilterPill extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusFilterPill({
    required this.label,
    required this.count,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withValues(alpha: 0.3) : AppColors.cardDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString().toPersianDigits(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? activeColor : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.dividerDark,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
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
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
