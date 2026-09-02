import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/search_field.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';
import 'widgets/customer_form_dialog.dart';

/// Customers management page.
class CustomersPage extends StatelessWidget {
  final void Function(int customerId)? onViewCustomerInvoices;

  const CustomersPage({super.key, this.onViewCustomerInvoices});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerCubit()..loadCustomers(),
      child: _CustomersView(onViewCustomerInvoices: onViewCustomerInvoices),
    );
  }
}

class _CustomersView extends StatefulWidget {
  final void Function(int customerId)? onViewCustomerInvoices;

  const _CustomersView({this.onViewCustomerInvoices});

  @override
  State<_CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<_CustomersView> {
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
              Icon(Icons.people, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                AppStrings.navCustomers,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Spacer(),
              SearchField(
                hintText: AppStrings.searchCustomer,
                controller: _searchCtrl,
                onChanged: (q) => context.read<CustomerCubit>().loadCustomers(query: q),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _addCustomer(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(AppStrings.addCustomer),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Table ───────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<CustomerCubit, CustomerState>(
              builder: (context, state) {
                if (state is CustomerLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CustomerError) {
                  return Center(child: Text(state.message));
                }
                if (state is CustomerLoaded) {
                  if (state.customers.isEmpty) {
                    return const EmptyState(
                      icon: Icons.people_outline,
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

  Widget _buildTable(BuildContext context, CustomerLoaded state) {
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
                DataColumn(label: Text(AppStrings.customerCode)),
                DataColumn(label: Text(AppStrings.customerName)),
                DataColumn(label: Text(AppStrings.customerPhone)),
                DataColumn(label: Text(AppStrings.customerAddress)),
                DataColumn(label: Text(AppStrings.customerNotes)),
                DataColumn(label: Text('')),
              ],
              rows: List.generate(state.customers.length, (index) {
                final c = state.customers[index];
                return DataRow(
                  color: WidgetStateProperty.all(
                    index.isEven ? AppColors.tableRowEven : AppColors.tableRowOdd,
                  ),
                  cells: [
                    DataCell(Text(c.code ?? '')),
                    DataCell(Text(c.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(c.phone ?? '')),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          c.address ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(c.notes ?? '', overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onViewCustomerInvoices != null)
                          IconButton(
                            icon: const Icon(Icons.receipt_long_outlined, size: 18),
                            color: AppColors.accent,
                            tooltip: AppStrings.viewInvoices,
                            onPressed: () => widget.onViewCustomerInvoices!(c.id!),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: AppColors.info,
                          tooltip: AppStrings.edit,
                          onPressed: () => _editCustomer(context, c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: AppColors.error,
                          tooltip: AppStrings.delete,
                          onPressed: () => _deleteCustomer(context, c.id!),
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

  Future<void> _addCustomer(BuildContext context) async {
    final cubit = context.read<CustomerCubit>();
    final nextCode = await cubit.getNextCode();
    if (!context.mounted) return;
    final customer = await CustomerFormDialog.show(context, nextCode: nextCode);
    if (customer != null) {
      cubit.addCustomer(customer);
    }
  }

  Future<void> _editCustomer(BuildContext context, customer) async {
    final result = await CustomerFormDialog.show(context, customer: customer);
    if (result != null && context.mounted) {
      context.read<CustomerCubit>().updateCustomer(result);
    }
  }

  Future<void> _deleteCustomer(BuildContext context, int id) async {
    final confirmed = await ConfirmDialog.show(context);
    if (confirmed && context.mounted) {
      context.read<CustomerCubit>().deleteCustomer(id);
    }
  }
}
