import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../services/import_service.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';
import 'widgets/product_form_dialog.dart';
import 'widgets/import_mapping_dialog.dart';

/// Products management page with CRUD data table.
class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductCubit()..loadProducts(),
      child: const _ProductsView(),
    );
  }
}

class _ProductsView extends StatefulWidget {
  const _ProductsView();

  @override
  State<_ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<_ProductsView> {
  final _searchCtrl = TextEditingController();
  final Set<int> _selectedIds = {};
  String? _selectedCategory;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.inventory_2, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                AppStrings.navProducts,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Spacer(),
              SearchField(
                hintText: AppStrings.searchProduct,
                controller: _searchCtrl,
                onChanged: (q) => context.read<ProductCubit>().loadProducts(query: q),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.file_upload_outlined, color: AppColors.accent),
                tooltip: AppStrings.importProducts,
                onSelected: (value) {
                  if (value == 'csv') _importCsv(context);
                  if (value == 'excel') _importExcel(context);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'csv', child: Text(AppStrings.importFromCsv)),
                  const PopupMenuItem(value: 'excel', child: Text(AppStrings.importFromExcel)),
                ],
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _applyProfitMargin(context),
                icon: const Icon(Icons.percent, size: 18),
                label: Text(
                  _selectedIds.isNotEmpty
                      ? '${AppStrings.applyProfitMargin} (${_selectedIds.length.formattedInt} انتخاب‌شده)'
                      : (_selectedCategory == null
                          ? AppStrings.applyProfitMargin
                          : '${AppStrings.applyProfitMargin} ($_currentCategoryDisplayName)'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _addProduct(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(AppStrings.addProduct),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Table ───────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ProductError) {
                  return Center(child: Text(state.message));
                }
                if (state is ProductLoaded) {
                  if (state.products.isEmpty) {
                    return const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: AppStrings.noData,
                    );
                  }

                  // Clean up any stale selected IDs
                  _selectedIds.removeWhere((id) => !state.products.any((p) => p.id == id));

                  final displayedProducts = state.products.where((p) {
                    if (_selectedCategory == null) return true;
                    if (_selectedCategory == '__uncategorized__') {
                      return p.category == null || p.category!.trim().isEmpty;
                    }
                    return p.category?.trim() == _selectedCategory;
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCategoryFilterBar(state.products),
                      const SizedBox(height: 16),
                      if (_selectedIds.isNotEmpty) ...[
                        _buildBatchActionBar(context, state.products),
                        const SizedBox(height: 12),
                      ],
                      Expanded(
                        child: displayedProducts.isEmpty
                            ? const EmptyState(
                                icon: Icons.category_outlined,
                                title: 'کالایی در این دسته‌بندی یافت نشد',
                                subtitle: 'برای مشاهده همه کالاها، دسته‌بندی «همه» را انتخاب کنید',
                              )
                            : _buildTable(context, displayedProducts),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterBar(List<ProductModel> allProducts) {
    final Map<String, int> categoryCounts = {};
    int uncategorizedCount = 0;
    for (final p in allProducts) {
      final cat = p.category?.trim();
      if (cat != null && cat.isNotEmpty) {
        categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
      } else {
        uncategorizedCount++;
      }
    }
    final sortedCategories = categoryCounts.keys.toList()..sort();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            '${AppStrings.productCategory}:',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip(
                    label: AppStrings.all,
                    count: allProducts.length,
                    isSelected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  ...sortedCategories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: _buildCategoryChip(
                        label: cat,
                        count: categoryCounts[cat]!,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedCategory = isSelected ? null : cat;
                          });
                        },
                      ),
                    );
                  }),
                  if (uncategorizedCount > 0)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: _buildCategoryChip(
                        label: AppStrings.uncategorized,
                        count: uncategorizedCount,
                        isSelected: _selectedCategory == '__uncategorized__',
                        onTap: () {
                          setState(() {
                            _selectedCategory =
                                _selectedCategory == '__uncategorized__' ? null : '__uncategorized__';
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.18)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.dividerDark,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 14, color: AppColors.primary),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : AppColors.cardDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.formattedInt,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<ProductModel> products) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              showCheckboxColumn: true,
              headingRowHeight: 48,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 52,
              columnSpacing: 20,
              horizontalMargin: 16,
              headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
              onSelectAll: (selected) {
                setState(() {
                  if (selected == true) {
                    for (final p in products) {
                      if (p.id != null) _selectedIds.add(p.id!);
                    }
                  } else {
                    for (final p in products) {
                      if (p.id != null) _selectedIds.remove(p.id!);
                    }
                  }
                });
              },
              columns: const [
                DataColumn(label: Text(AppStrings.productCode)),
                DataColumn(label: Text(AppStrings.productName)),
                DataColumn(label: Text(AppStrings.productCategory)),
                DataColumn(label: Text(AppStrings.productBuyPrice)),
                DataColumn(label: Text(AppStrings.productCurrentBuyPrice)),
                DataColumn(label: Text(AppStrings.productSellPrice)),
                DataColumn(label: Text(AppStrings.profitAmount)),
                DataColumn(label: Text(AppStrings.profitMargin)),
                DataColumn(label: Text(AppStrings.productUnit)),
                DataColumn(label: Text(AppStrings.productStock)),
                DataColumn(label: Text(AppStrings.soldCount)),
                DataColumn(label: Text('')), // Actions
              ],
              rows: List.generate(products.length, (index) {
                final p = products[index];
                final isSelected = p.id != null && _selectedIds.contains(p.id);
                return DataRow(
                  selected: isSelected,
                  onSelectChanged: (selected) {
                    if (p.id == null) return;
                    setState(() {
                      if (selected == true) {
                        _selectedIds.add(p.id!);
                      } else {
                        _selectedIds.remove(p.id!);
                      }
                    });
                  },
                  color: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primary.withValues(alpha: 0.15);
                    }
                    return index.isEven ? AppColors.tableRowEven : AppColors.tableRowOdd;
                  }),
                  cells: [
                    DataCell(
                      _EditableTableCell(
                        displayValue: p.code ?? '-',
                        rawValue: p.code ?? '',
                        minWidth: 55,
                        tooltip: 'کلیک برای ویرایش کد کالا',
                        onSave: (val) {
                          final clean = val.trim();
                          context.read<ProductCubit>().updateProduct(
                                p.copyWith(code: clean.isEmpty ? null : clean),
                              );
                        },
                      ),
                    ),
                    DataCell(
                      _EditableTableCell(
                        displayValue: p.name,
                        rawValue: p.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        minWidth: 120,
                        tooltip: 'کلیک برای ویرایش نام کالا',
                        onSave: (val) {
                          final clean = val.trim();
                          if (clean.isNotEmpty) {
                            context.read<ProductCubit>().updateProduct(
                                  p.copyWith(name: clean),
                                );
                          }
                        },
                      ),
                    ),
                    DataCell(
                      InkWell(
                        onTap: () {
                          final cat = p.category?.trim();
                          if (cat != null && cat.isNotEmpty) {
                            setState(() {
                              _selectedCategory = (_selectedCategory == cat) ? null : cat;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: Text(
                            p.category ?? '',
                            style: TextStyle(
                              color: (p.category != null && p.category!.trim().isNotEmpty)
                                  ? (_selectedCategory == p.category?.trim()
                                      ? AppColors.primary
                                      : AppColors.textSecondary)
                                  : AppColors.textMuted,
                              fontWeight: _selectedCategory == p.category?.trim()
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      _EditableTableCell(
                        displayValue: p.buyPrice.toman,
                        rawValue: p.buyPrice.round().toString(),
                        isNumber: true,
                        minWidth: 75,
                        tooltip: 'کلیک برای ویرایش قیمت خرید اولیه',
                        onSave: (val) {
                          final parsed = double.tryParse(val.replaceAll(',', '').trim());
                          if (parsed != null && parsed >= 0) {
                            context.read<ProductCubit>().updateProduct(
                                  p.copyWith(buyPrice: parsed),
                                );
                          }
                        },
                      ),
                    ),
                    DataCell(
                      _EditableTableCell(
                        displayValue: p.currentBuyPrice != null ? p.currentBuyPrice!.toman : p.buyPrice.toman,
                        rawValue: p.currentBuyPrice != null
                            ? p.currentBuyPrice!.round().toString()
                            : p.buyPrice.round().toString(),
                        isNumber: true,
                        minWidth: 75,
                        tooltip: 'کلیک برای ویرایش قیمت خرید روز',
                        onSave: (val) {
                          final parsed = double.tryParse(val.replaceAll(',', '').trim());
                          if (parsed != null && parsed >= 0) {
                            context.read<ProductCubit>().updateProduct(
                                  p.copyWith(currentBuyPrice: parsed),
                                );
                          }
                        },
                      ),
                    ),
                    DataCell(
                      _EditableTableCell(
                        displayValue: p.sellPrice != null ? p.sellPrice!.toman : '-',
                        rawValue: p.sellPrice != null ? p.sellPrice!.round().toString() : '',
                        isNumber: true,
                        minWidth: 75,
                        tooltip: 'کلیک برای ویرایش قیمت فروش (رند به ۵۰۰۰)',
                        onSave: (val) {
                          final parsed = double.tryParse(val.replaceAll(',', '').trim());
                          if (parsed != null && parsed >= 0) {
                            context.read<ProductCubit>().updateProduct(
                                  p.copyWith(sellPrice: parsed.roundTo5000),
                                );
                          }
                        },
                      ),
                    ),
                    DataCell(
                      Text(
                        p.profitAmountDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: p.profitAmount > 0
                              ? AppColors.success
                              : (p.profitAmount < 0 ? AppColors.error : AppColors.textMuted),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (p.profitPercent > 0
                                  ? AppColors.success
                                  : (p.profitPercent < 0 ? AppColors.error : AppColors.textMuted))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p.profitPercentDisplay,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: p.profitPercent > 0
                                ? AppColors.success
                                : (p.profitPercent < 0 ? AppColors.error : AppColors.textMuted),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      _EditableTableCell(
                        displayValue: p.unit,
                        rawValue: p.unit,
                        minWidth: 35,
                        tooltip: 'کلیک برای ویرایش واحد',
                        onSave: (val) {
                          final clean = val.trim();
                          if (clean.isNotEmpty) {
                            context.read<ProductCubit>().updateProduct(
                                  p.copyWith(unit: clean),
                                );
                          }
                        },
                      ),
                    ),
                    DataCell(
                      _EditableTableCell(
                        displayValue: p.stockDisplay,
                        rawValue: p.isInfiniteStock ? '' : (p.stock != null ? p.stock!.round().toString() : '0'),
                        isNumber: true,
                        minWidth: 55,
                        tooltip: 'کلیک برای ویرایش موجودی (خالی = نامحدود)',
                        customDisplay: p.isInfiniteStock
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.all_inclusive, size: 13, color: AppColors.accent),
                                    SizedBox(width: 4),
                                    Text(
                                      AppStrings.infinite,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                        onSave: (val) {
                          final clean = val.replaceAll(',', '').trim();
                          if (clean.isEmpty || clean == 'نامحدود' || clean == '-') {
                            context.read<ProductCubit>().updateProduct(
                                  p.copyWith(clearStock: true),
                                );
                          } else {
                            final parsed = double.tryParse(clean);
                            if (parsed != null) {
                              context.read<ProductCubit>().updateProduct(
                                    p.copyWith(stock: parsed),
                                  );
                            }
                          }
                        },
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.totalSold > 0
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${p.totalSoldDisplay} ${p.unit}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: p.totalSold > 0 ? FontWeight.w600 : FontWeight.normal,
                            color: p.totalSold > 0 ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: AppColors.info,
                          tooltip: AppStrings.edit,
                          onPressed: () => _editProduct(context, p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: AppColors.error,
                          tooltip: AppStrings.delete,
                          onPressed: () => _deleteProduct(context, p.id!),
                        ),
                      ],
                    )),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBatchActionBar(BuildContext context, List<ProductModel> allProducts) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _selectedIds.length.formattedInt,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            AppStrings.selectedCount,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const Spacer(),
          // Apply profit margin to selected
          FilledButton.tonalIcon(
            onPressed: () => _applyProfitMargin(context),
            icon: const Icon(Icons.percent, size: 18),
            label: const Text(AppStrings.applyProfitMargin),
          ),
          const SizedBox(width: 8),
          // Move to Category
          FilledButton.tonalIcon(
            onPressed: () => _batchMoveCategory(context, allProducts),
            icon: const Icon(Icons.drive_file_move_outlined, size: 18),
            label: const Text(AppStrings.moveToCategory),
          ),
          const SizedBox(width: 8),
          // Batch Delete
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.85),
              foregroundColor: Colors.white,
            ),
            onPressed: () => _batchDelete(context),
            icon: const Icon(Icons.delete_sweep_outlined, size: 18),
            label: const Text(AppStrings.deleteSelected),
          ),
          const SizedBox(width: 8),
          // Clear Selection
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: AppStrings.clearSelection,
            onPressed: () => setState(() => _selectedIds.clear()),
          ),
        ],
      ),
    );
  }

  Future<void> _batchMoveCategory(BuildContext context, List<ProductModel> allProducts) async {
    final categories = allProducts
        .map((p) => p.category?.trim())
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();

    final targetCategory = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        String? chosenCategory;
        bool setUncategorized = false;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text(
                  '${AppStrings.moveToCategory} (${_selectedIds.length.formattedInt} کالا)',
                ),
                content: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'دسته‌بندی مقصد را انتخاب کنید یا نام جدید وارد نمایید:',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(AppStrings.uncategorized),
                          subtitle: const Text('حذف دسته‌بندی از کالاهای انتخاب‌شده'),
                          value: setUncategorized,
                          onChanged: (v) {
                            setModalState(() {
                              setUncategorized = v ?? false;
                              if (setUncategorized) {
                                chosenCategory = null;
                                ctrl.clear();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        if (!setUncategorized) ...[
                          TextField(
                            controller: ctrl,
                            decoration: const InputDecoration(
                              labelText: 'نام دسته‌بندی',
                              hintText: AppStrings.enterNewCategory,
                              prefixIcon: Icon(Icons.category_outlined, size: 18),
                            ),
                            onChanged: (text) {
                              setModalState(() {
                                chosenCategory = text.trim().isEmpty ? null : text.trim();
                              });
                            },
                          ),
                          if (categories.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'دسته‌بندی‌های موجود:',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: categories.map((cat) {
                                final isSelected = chosenCategory == cat;
                                return ChoiceChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (selected) {
                                        chosenCategory = cat;
                                        ctrl.text = cat;
                                      } else if (chosenCategory == cat) {
                                        chosenCategory = null;
                                        ctrl.clear();
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(AppStrings.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (setUncategorized) {
                        Navigator.of(ctx).pop('__uncategorized__');
                      } else {
                        final catName = ctrl.text.trim();
                        if (catName.isNotEmpty) {
                          Navigator.of(ctx).pop(catName);
                        }
                      }
                    },
                    child: const Text(AppStrings.confirm),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (targetCategory != null && context.mounted) {
      final cubit = context.read<ProductCubit>();
      final ids = _selectedIds.toList();
      final newCat = targetCategory == '__uncategorized__' ? null : targetCategory;
      final count = await cubit.moveProductsCategory(ids, newCat);
      if (context.mounted) {
        setState(() => _selectedIds.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newCat == null
                  ? '$count کالا به بخش «${AppStrings.uncategorized}» منتقل شدند'
                  : '$count کالا به دسته‌بندی «$newCat» منتقل شدند',
            ),
          ),
        );
      }
    }
  }

  Future<void> _batchDelete(BuildContext context) async {
    final count = _selectedIds.length;
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'حذف گروهی کالاها',
      message: 'آیا از حذف ${count.formattedInt} کالای انتخاب‌شده اطمینان دارید؟\nاین عملیات غیرقابل بازگشت است، اما اطلاعات فاکتورهای قبلی حفظ می‌شوند.',
      confirmLabel: AppStrings.deleteSelected,
    );

    if (confirmed && context.mounted) {
      final ids = _selectedIds.toList();
      final deletedCount = await context.read<ProductCubit>().deleteProducts(ids);
      if (context.mounted) {
        setState(() => _selectedIds.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deletedCount ${AppStrings.batchDeleteSuccess}'),
          ),
        );
      }
    }
  }

  Future<void> _addProduct(BuildContext context) async {
    final cubit = context.read<ProductCubit>();
    final nextCode = await cubit.getNextCode();
    if (!context.mounted) return;
    final product = await ProductFormDialog.show(context, nextCode: nextCode);
    if (product != null) {
      cubit.addProduct(product);
    }
  }

  Future<void> _editProduct(BuildContext context, product) async {
    final result = await ProductFormDialog.show(context, product: product);
    if (result != null && context.mounted) {
      context.read<ProductCubit>().updateProduct(result);
    }
  }

  Future<void> _deleteProduct(BuildContext context, int id) async {
    final confirmed = await ConfirmDialog.show(context);
    if (confirmed && context.mounted) {
      context.read<ProductCubit>().deleteProduct(id);
    }
  }

  Future<void> _importCsv(BuildContext context) async {
    await _importWithMapping(context, isCsv: true);
  }

  Future<void> _importExcel(BuildContext context) async {
    await _importWithMapping(context, isCsv: false);
  }

  Future<void> _importWithMapping(BuildContext context, {required bool isCsv}) async {
    try {
      // Step 1: Read the file
      final fileData = isCsv
          ? await ImportService.readCsvFile()
          : await ImportService.readExcelFile();

      if (fileData == null || fileData.rows.isEmpty) return;
      if (!context.mounted) return;

      // Step 2: Show the mapping dialog
      final mapping = await ImportMappingDialog.show(context, fileData);
      if (mapping == null) return; // User cancelled

      // Step 3: Apply mapping and import
      final products = ImportService.applyMapping(fileData, mapping);
      if (products.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('هیچ کالای معتبری در فایل یافت نشد')),
          );
        }
        return;
      }

      final repo = ProductRepository();
      final count = await repo.importProducts(products);

      if (context.mounted) {
        context.read<ProductCubit>().loadProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count ${AppStrings.importSuccess}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: ${e.toString()}')),
        );
      }
    }
  }

  String get _currentCategoryDisplayName {
    if (_selectedCategory == null) return AppStrings.all;
    if (_selectedCategory == '__uncategorized__') return AppStrings.uncategorized;
    return _selectedCategory!;
  }

  Future<void> _applyProfitMargin(BuildContext context) async {
    final controller = TextEditingController();
    final targetCategory = _selectedCategory;
    final categoryName = _currentCategoryDisplayName;
    final hasSelection = _selectedIds.isNotEmpty;
    final selectedCount = _selectedIds.length;

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.percent, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              const Text(AppStrings.applyProfitMargin),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasSelection ? Icons.checklist_rtl_outlined : Icons.category_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasSelection ? 'هدف اعمال سود: ' : 'دسته‌بندی هدف: ',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Expanded(
                        child: Text(
                          hasSelection
                              ? '$selectedCount کالای انتخاب‌شده (${targetCategory != null ? categoryName : 'از کل کالاها'})'
                              : categoryName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  hasSelection
                      ? 'درصد سود مورد نظر را برای $selectedCount کالای انتخاب‌شده وارد کنید:'
                      : (targetCategory == null
                          ? 'درصد سود مورد نظر را برای همه کالاها وارد کنید:'
                          : 'درصد سود مورد نظر را برای کالاهای دسته‌بندی «$categoryName» وارد کنید:'),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: AppStrings.profitMargin,
                    hintText: 'مثلاً ۲۰ برای ۲۰٪ سود',
                    suffixText: '٪',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(controller.text.trim());
                if (val != null) {
                  Navigator.of(ctx).pop(val);
                }
              },
              child: const Text(AppStrings.confirm),
            ),
          ],
        ),
      ),
    );

    if (result != null && context.mounted) {
      final selectedList = hasSelection ? _selectedIds.toList() : null;
      final updatedCount = await context.read<ProductCubit>().applyProfitMargin(
        result,
        category: targetCategory,
        productIds: selectedList,
      );
      if (context.mounted) {
        if (hasSelection) {
          setState(() => _selectedIds.clear());
        }
        final msg = hasSelection
            ? 'درصد سود روی $selectedCount کالای انتخاب‌شده ($updatedCount مورد) اعمال شد'
            : (targetCategory == null
                ? 'درصد سود روی همه کالاها ($updatedCount مورد) اعمال شد'
                : 'درصد سود روی کالاهای «$categoryName» ($updatedCount مورد) اعمال شد');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }
}

/// Compact inline editable cell for data tables.
/// Displays value with subtle hover indicator; click to edit directly with Enter or unfocus to save.
class _EditableTableCell extends StatefulWidget {
  final String displayValue;
  final String rawValue;
  final ValueChanged<String> onSave;
  final bool isNumber;
  final TextStyle? style;
  final String? tooltip;
  final Widget? customDisplay;
  final double minWidth;

  const _EditableTableCell({
    required this.displayValue,
    required this.rawValue,
    required this.onSave,
    this.isNumber = false,
    this.style,
    this.tooltip,
    this.customDisplay,
    this.minWidth = 60,
  });

  @override
  State<_EditableTableCell> createState() => _EditableTableCellState();
}

class _EditableTableCellState extends State<_EditableTableCell> {
  bool _isEditing = false;
  late final TextEditingController _ctrl;
  late final FocusNode _focusNode;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.rawValue);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _submit();
    }
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text != widget.rawValue.trim()) {
      widget.onSave(text);
    }
    if (mounted) {
      setState(() => _isEditing = false);
    }
  }

  void _cancel() {
    _ctrl.text = widget.rawValue;
    if (mounted) {
      setState(() => _isEditing = false);
    }
  }

  @override
  void didUpdateWidget(covariant _EditableTableCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rawValue != oldWidget.rawValue && !_isEditing) {
      _ctrl.text = widget.rawValue;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return SizedBox(
        width: widget.minWidth + 36,
        height: 34,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): _cancel,
          },
          child: TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            autofocus: true,
            keyboardType: widget.isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            textAlign: widget.isNumber ? TextAlign.center : TextAlign.start,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip ?? 'کلیک برای ویرایش سریع',
        waitDuration: const Duration(milliseconds: 500),
        child: InkWell(
          onTap: () {
            _ctrl.text = widget.rawValue;
            setState(() => _isEditing = true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _focusNode.requestFocus();
              _ctrl.selection = TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
            });
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _isHovered ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.customDisplay ??
                    Text(
                      widget.displayValue,
                      style: widget.style,
                    ),
                if (_isHovered) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit,
                    size: 11,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

