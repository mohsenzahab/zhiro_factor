import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../cubit/supplier_cubit.dart';
import '../cubit/supplier_state.dart';
import 'widgets/supplier_form_dialog.dart';
import '../../../data/repositories/supplier_repository.dart';

/// Suppliers management page.
class SuppliersPage extends StatelessWidget {
  final void Function(int supplierId)? onViewSupplierPurchases;

  const SuppliersPage({super.key, this.onViewSupplierPurchases});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SupplierCubit()..loadSuppliers(),
      child: _SuppliersView(onViewSupplierPurchases: onViewSupplierPurchases),
    );
  }
}

class _SuppliersView extends StatefulWidget {
  final void Function(int supplierId)? onViewSupplierPurchases;

  const _SuppliersView({this.onViewSupplierPurchases});

  @override
  State<_SuppliersView> createState() => _SuppliersViewState();
}

class _SuppliersViewState extends State<_SuppliersView> {
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
              Icon(Icons.local_shipping, color: AppColors.accent, size: 28),
              const SizedBox(width: 12),
              Text(
                AppStrings.navSuppliers,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Spacer(),
              SearchField(
                hintText: AppStrings.searchSupplier,
                controller: _searchCtrl,
                onChanged: (q) => context.read<SupplierCubit>().loadSuppliers(query: q),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _addSupplier(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(AppStrings.addSupplier),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Table ───────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<SupplierCubit, SupplierState>(
              builder: (context, state) {
                if (state is SupplierLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SupplierError) {
                  return Center(child: Text(state.message));
                }
                if (state is SupplierLoaded) {
                  if (state.suppliers.isEmpty) {
                    return const EmptyState(
                      icon: Icons.local_shipping_outlined,
                      title: 'تأمین‌کننده‌ای یافت نشد',
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

  Widget _buildTable(BuildContext context, SupplierLoaded state) {
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
                DataColumn(label: Text(AppStrings.supplierCode)),
                DataColumn(label: Text(AppStrings.supplierName)),
                DataColumn(label: Text(AppStrings.supplierPhone)),
                DataColumn(label: Text(AppStrings.supplierAddress)),
                DataColumn(label: Text(AppStrings.supplierNotes)),
                DataColumn(label: Text('')),
              ],
              rows: List.generate(state.suppliers.length, (index) {
                final s = state.suppliers[index];
                return DataRow(
                  color: WidgetStateProperty.all(
                    index.isEven ? AppColors.tableRowEven : AppColors.tableRowOdd,
                  ),
                  cells: [
                    DataCell(Text(s.code ?? '')),
                    DataCell(Text(s.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(s.phone ?? '')),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          s.address ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(s.notes ?? '', overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onViewSupplierPurchases != null)
                          Tooltip(
                            message: 'فاکتورهای خرید',
                            child: IconButton(
                              icon: const Icon(Icons.receipt_long, size: 20, color: AppColors.accent),
                              onPressed: () {
                                widget.onViewSupplierPurchases!(s.id!);
                              },
                              splashRadius: 20,
                            ),
                          ),
                        Tooltip(
                          message: 'ویرایش',
                          child: IconButton(
                            icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                            onPressed: () => _editSupplier(context, s),
                            splashRadius: 20,
                          ),
                        ),
                        Tooltip(
                          message: 'حذف',
                          child: IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
                            onPressed: () => _deleteSupplier(context, s),
                            splashRadius: 20,
                          ),
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

  Future<void> _addSupplier(BuildContext context) async {
    final nextCode = await SupplierRepository().nextCode();
    if (!context.mounted) return;

    final result = await SupplierFormDialog.show(
      context,
      nextCode: nextCode,
    );

    if (result != null && context.mounted) {
      context.read<SupplierCubit>().addSupplier(result);
    }
  }

  Future<void> _editSupplier(BuildContext context, dynamic s) async {
    final result = await SupplierFormDialog.show(
      context,
      nextCode: '',
      supplier: s,
    );

    if (result != null && context.mounted) {
      context.read<SupplierCubit>().updateSupplier(result);
    }
  }

  Future<void> _deleteSupplier(BuildContext context, dynamic s) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: AppStrings.deleteSupplier,
      message: 'آیا از حذف تأمین‌کننده «${s.name}» اطمینان دارید؟',
      confirmLabel: AppStrings.delete,
    );

    if (confirm == true && context.mounted) {
      context.read<SupplierCubit>().deleteSupplier(s.id!);
    }
  }
}
