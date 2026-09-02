import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../services/import_service.dart';
import '../../../data/repositories/product_repository.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';
import 'widgets/product_form_dialog.dart';

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
                  return _buildTable(context, state);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, ProductLoaded state) {
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
                DataColumn(label: Text(AppStrings.productPrice)),
                DataColumn(label: Text(AppStrings.productUnit)),
                DataColumn(label: Text(AppStrings.productStock)),
                DataColumn(label: Text('')), // Actions
              ],
              rows: List.generate(state.products.length, (index) {
                final p = state.products[index];
                return DataRow(
                  color: WidgetStateProperty.all(
                    index.isEven ? AppColors.tableRowEven : AppColors.tableRowOdd,
                  ),
                  cells: [
                    DataCell(Text(p.code ?? '')),
                    DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(p.category ?? '')),
                    DataCell(Text(p.price.toman)),
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
    try {
      final products = await ImportService.importFromCsv();
      if (products == null || products.isEmpty) return;
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

  Future<void> _importExcel(BuildContext context) async {
    try {
      final products = await ImportService.importFromExcel();
      if (products == null || products.isEmpty) return;
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
}
