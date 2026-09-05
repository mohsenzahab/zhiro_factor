import 'package:flutter/material.dart';
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
                label: const Text(AppStrings.applyProfitMargin),
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
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
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
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowHeight: 48,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 52,
              columnSpacing: 24,
              horizontalMargin: 16,
              headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
              columns: const [
                DataColumn(label: Text(AppStrings.productCode)),
                DataColumn(label: Text(AppStrings.productName)),
                DataColumn(label: Text(AppStrings.productCategory)),
                DataColumn(label: Text(AppStrings.productBuyPrice)),
                DataColumn(label: Text(AppStrings.productSellPrice)),
                DataColumn(label: Text(AppStrings.productUnit)),
                DataColumn(label: Text(AppStrings.productStock)),
                DataColumn(label: Text('')), // Actions
              ],
              rows: List.generate(products.length, (index) {
                final p = products[index];
                return DataRow(
                  color: WidgetStateProperty.all(
                    index.isEven ? AppColors.tableRowEven : AppColors.tableRowOdd,
                  ),
                  cells: [
                    DataCell(Text(p.code ?? '')),
                    DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500))),
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
                    DataCell(Text(p.buyPrice.toman)),
                    DataCell(Text(p.sellPrice != null ? p.sellPrice!.toman : '-')),
                    DataCell(Text(p.unit)),
                    DataCell(Text(p.stock.formattedInt)),
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

  Future<void> _applyProfitMargin(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(AppStrings.applyProfitMargin),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'درصد سود مورد نظر را برای محاسبه قیمت فروش بر اساس قیمت خرید وارد کنید:',
                  style: TextStyle(fontSize: 13),
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
      await context.read<ProductCubit>().applyProfitMargin(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.profitMarginApplied)),
        );
      }
    }
  }
}

